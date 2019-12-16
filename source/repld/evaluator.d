module repld.evaluator;

import std;
import std.file : fwrite = write, fremove = remove;
import repld.globalvariable;
import repld.moduleimport;
import repld.dll;

class SemanticException : Exception {

    this(string str, string file = __FILE__, size_t line = __LINE__) {
        str = str.split("\n").map!(line => line.canFind(": ") ? line.split(": ")[1..$].join(": ") : line).join("\n");
        super(str);
    }
}

class Evaluator {
    private GlobalVariables globalVariables;
    private Imports imports;
    private int dllSeed;

    this() {
        this.globalVariables = new GlobalVariables;
        this.imports = new Imports;
    }

    void evalVarDecl(string type, string name, string expr) {
        auto params = globalVariables.asParams();
        auto decls = globalVariables.getDeclarations;
        auto imports = imports.toString();
        auto sourceCode = expand!("variableDeclaration.d", type, expr, imports, decls);

        auto result = execute!(Tuple!(Variant,string))(sourceCode, params);
        if (type == "auto") {
            type = result[1];
        }
        globalVariables.push(type, name, result[0]);
    }

    void evalImport(string expr) {
        imports.push(expr);
    }

    void evalStatement(string statement) {
        auto params = globalVariables.asParams();
        auto decls = globalVariables.getDeclarations;
        auto imports = imports.toString();
        auto sourceCode = expand!("statement.d", statement, imports, decls);

        execute!(void, Param)(sourceCode, params);
    }

    private string expand(string templateFileName, Args...)() {
        auto result  = import(templateFileName);
        static foreach (arg; Args) {
            result = result.replace(format!"${%s}"(arg.stringof), arg);
        }
        return result;
    }

    private RetType execute(RetType, Param...)(string sourceCode, Param param) {
        auto dllName = createDLL(sourceCode);
        scope (exit) dllName.fremove();

        auto dll = new DLL(dllName);

        auto funcName = dll.loadFunction!(string function())("funcName")();
        
        auto func = dll.loadFunction!(RetType function(Param))(funcName);

        return func(param);
    }

    private string createDLL(string sourceCode) {
        scope (exit) dllSeed++;
        auto sourceFileName = tempDir.buildPath(format!"test%d.d"(dllSeed));
        sourceFileName.fwrite(sourceCode);
        scope (exit) sourceFileName.fremove();
        
        auto dllName = tempDir.buildPath(format!"./test%d.so"(dllSeed));

        const result = executeShell(format!"dmd %s -g -shared -of=%s"(sourceFileName, dllName));
        enforce!SemanticException(result.status == 0, result.output);

        return dllName;
    }
}
