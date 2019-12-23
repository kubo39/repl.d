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
    private string[2][] dependencies;

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
        createDLL(expr);
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

    ref T get(T)(string name) {
        return globalVariables.get!T(name);
    }

    void addDependency(string packageName, string versionName) {
        dependencies ~= [packageName, versionName];
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
        auto sourceFileName = createSourceFileName();
        auto name = sourceFileName.baseName.stripExtension;
        auto dependencies = dependencyText();
        auto dllOption = dllOption;
        auto picOption = picOption;
        sourceCode = expand!("dubsetting.d", name, dependencies, dllOption, picOption) ~ sourceCode;

        sourceFileName.fwrite(sourceCode);
        scope (exit) sourceFileName.fremove();
        
        auto dllName = sourceFileName.stripExtension;

        const result = executeShell(format!"dub build %s --quiet --single --compiler=%s --build=debug"(sourceFileName, compiler));
        enforce!SemanticException(result.status == 0,
            result.output.split("\n")[0..$-2].join("\n")); // cut unnecessary line

        return new DLL(dllName);
    }

    private string createSourceFileName() {
        scope (exit) dllSeed++;
        auto sourceFileName = tempDir.buildPath(format!"test%d.d"(dllSeed));
        return sourceFileName;
    }

    private string dependencyText() {
        return dependencies.map!(d => format!q{dependency "%s" version="%s"}(d[0], d[1])).join("\n");
    }

    version (Posix) {
        private enum dllExtension = ".so";
        private enum objExtension = ".o";
        private enum dllOption = "-shared";
    } else version (Windows) {
        private enum dllExtension = ".dll";
        private enum objExtension = ".obj";
        private enum dllOption = "";
    } else {
        static assert(false, "This platform is not supported.");
    }

    version (DigitalMars) {
        private enum compiler = "dmd";
        private enum picOption = "-fPIC";
    } else version (LDC) {
        private enum compiler = "ldc2";
        private enum picOption = "--relocation-model=pic";
    } else {
        static assert(false, "This compiler is not supported.");
    }
}

private string expand(string templateFileName, Args...)() {
    auto result  = import(templateFileName);
    static foreach (arg; Args) {
        result = result.replace(format!"${%s}"(arg.stringof), arg);
    }
    return result;
}

