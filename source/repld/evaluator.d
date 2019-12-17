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
    private string[] importPaths;
    private string[] libPaths;
    private string[] libs;

    this() {
        this.globalVariables = new GlobalVariables;
        this.imports = new Imports;
    }

    void set(T)(string name, T v) {
        this.globalVariables.set(name, v);
    }

    void evalVarDecl(string type, string name, string expr) {
        auto params = globalVariables.asParams();
        auto decls = globalVariables.getDeclarations;
        auto imports = imports.toString();
        auto param = import("param.d");
        auto sourceCode = expand!("variableDeclaration.d", type, expr, imports, param, decls);

        auto result = executeDeclare(sourceCode, params);
        if (type == "auto") {
            type = result[1];
        }
        globalVariables.set(type, name, result[0]);
    }

    void evalImport(string expr) {
        auto sourceFileName = createFile(expr);
        auto result = executeShell(format!"dmd -c -o- %s %s"(sourceFileName, args));
        enforce!SemanticException(result.status == 0, result.output);
        imports.push(expr);
    }

    void evalStatement(string statement) {
        auto params = globalVariables.asParams();
        auto decls = globalVariables.getDeclarations;
        auto imports = imports.toString();
        auto param = import("param.d");
        auto sourceCode = expand!("statement.d", statement, imports, param, decls);

        execute(sourceCode, params);
    }

    void evalExpression(string expression) {
        auto params = globalVariables.asParams();
        auto decls = globalVariables.getDeclarations;
        auto imports = imports.toString();
        auto param = import("param.d");
        auto sourceCode = expand!("expression.d", expression, imports, param, decls);

        execute(sourceCode, params);
    }

    void buildDependency(string packageName, string versionName) {
        auto sourceCode = expand!("forBuildDependency.d", packageName, versionName);
        auto sourceFileName = createFile(sourceCode);
        scope (exit) sourceFileName.fremove();
        auto result = executeShell("dub run --single " ~ sourceFileName);
        enforce(result.status == 0, result.output);
    }

    ref T get(T)(string name) {
        return globalVariables.get!T(name);
    }

    alias addImportPath = add!importPaths;
    alias addLibPath = add!libPaths;
    alias addLibrary = add!libs;

    private void add(alias mem)(string[] paths) {
        mem ~= paths;
        mem = mem.sort.uniq.array;
    }

    private string expand(string templateFileName, Args...)() {
        auto result  = import(templateFileName);
        static foreach (arg; Args) {
            result = result.replace(format!"${%s}"(arg.stringof), arg);
        }
        return result;
    }

    private void execute(string sourceCode, Param param) {
        auto dll = createDLL(sourceCode);
        auto funcName = dll.loadFunction!(string function())("__funcName__")();
        dll.loadFunction!(void function(Param))(funcName)(param);
    }

    private Tuple!(Variant, string) executeDeclare(string sourceCode, Param param) {
        auto dll = createDLL(sourceCode);
        auto funcName = dll.loadFunction!(string function())("__funcName__")();
        auto typeName = dll.loadFunction!(string function())("__typeName__")();
        auto variable = dll.loadFunction!(Variant function(Param))(funcName)(param);
        return tuple(variable, typeName);
    }

    private DLL createDLL(string sourceCode) {
        auto sourceFileName = createFile(sourceCode);
        scope (exit) sourceFileName.fremove();
        
        auto dllName = sourceFileName.setExtension(".so");

        const result = executeShell(format!"dmd %s -g -shared -of=%s %s"(sourceFileName, dllName, args));
        enforce!SemanticException(result.status == 0, result.output);
        scope (exit) dllName.fremove();
        scope (exit) fremove(dllName.setExtension(".o"));

        return new DLL(dllName);
    }

    private string createFile(string sourceCode) {
        scope (exit) dllSeed++;
        auto sourceFileName = tempDir.buildPath(format!"test%d.d"(dllSeed));
        sourceFileName.fwrite(sourceCode);
        return sourceFileName;
    }

    private string args() {
        return [importSearchArgs, libArgs, libSearchArgs].join(" ");
    }

    private string importSearchArgs() {
        return importPaths.map!(s => "-I"~s).join(" ");
    }

    private string libSearchArgs() {
        return libPaths.map!(s => "-L-L"~s).join(" ");
    }

    private string libArgs() {
        return libs.map!(s => "-L-l"~s).join(" ");
    }
}
