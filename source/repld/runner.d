module repld.runner;

import std;
import repld.parse;
import repld.evaluator;
import dparse.ast;
import dparse.lexer;

class REPLRunner {

    static struct Result {
        bool success;
        string message;
    }

    private Evaluator evaluator;
    
    this() {
        this.evaluator = new Evaluator;
    }

    Result run(string line) {
        if (line.chomp == "") return success; // accept empty line

        auto parseResult = parse(line);

        try {
            if (auto decl = parseResult.peek!(VariableDeclaration)) {
                foreach (d; decl.declarators) {
                    evaluator.evalVarDecl(getType(*decl), d.name.text, conv(d.initializer.tokens));
                }
                return success;
            }
            if (auto decl = parseResult.peek!(AutoDeclaration)) {
                foreach (p; decl.parts) {
                    evaluator.evalVarDecl("auto", p.identifier.text, conv(p.initializer.tokens));
                }
                return success;
            }
            if (auto decl = parseResult.peek!(FunctionDeclaration)) {
                if (decl.templateParameters) {
                    return fail("Template function is not allowed.");
                }
                if (decl.constraint) {
                    return fail("Template constraint is not allowed.");
                }
                evaluator.evalVarDecl("auto", decl.name.text, toLiteral(*decl));
                return success;
            }
            if (auto decl = parseResult.peek!(ImportDeclaration)) {
                evaluator.evalImport(conv(decl.tokens));
                return success;
            }
            if (auto st = parseResult.peek!(Statement)) {
                evaluator.evalStatement(conv(st.tokens));
                return success;
            }
            if (auto expr = parseResult.peek!(Expression)) {
                evaluator.evalExpression(conv(expr.tokens));
                return success;
            }
            if (auto msgs = parseResult.peek!(Message[])) {
                return fail((*msgs).map!(msg => msg.toString()).join("\n"));
            }
        } catch (SemanticException e) {
            return fail(e.msg);
        }

        return success;
    }

    ref T get(T)(string name) {
        return evaluator.get!T(name);
    }

    void set(T)(string name, T v) {
        evaluator.set(name, v);
    }

    void opIndexAssign(T)(T value, string name) {
        set(name, value);
    }

    ref string[] importSearchPaths() {
        return evaluator.importSearchPaths;
    }

    private Result success() {
        return Result(true);
    }

    private Result fail(string msg) {
        return Result(false, msg);
    }
}

string getType(VariableDeclaration decl) {
    return conv(decl.type.tokens);
}

string toLiteral(FunctionDeclaration decl) {
    auto returnType = decl.hasAuto ? "auto" : conv(decl.returnType.tokens);
    auto attributes = (decl.hasRef ? "ref" : "")
        ~ decl.memberFunctionAttributes.map!(a => conv(a.tokens)).join(" ")
        ~ decl.attributes.map!(a => conv(a.tokens)).join(" ")
        ~ decl.storageClasses.map!(c => conv(c.tokens)).join(" ");
    auto parameters = conv(decl.parameters.tokens);
    auto functionBody = conv(decl.functionBody.tokens);

    return format!"function %s %s %s %s"(attributes, returnType, parameters, functionBody);
}

string conv(const Token[] tokens) {
    return tokens.map!(t => t.text ? t.text : str(t.type)).join(" ");
}

unittest {
    auto runner = new REPLRunner();
    shouldSuccess(runner.run(q{ int x = 3; }));
    shouldSuccess(runner.run(q{ double y = 3.1415; }));
    shouldSuccess(runner.run(q{ import std; }));
    shouldFailure(runner.run(q{ import unknownPackage; }));
    shouldSuccess(runner.run(q{ auto z = x * y; }));
    shouldSuccess(runner.run(q{ auto t = 3.seconds; }));
    shouldSuccess(runner.run(q{ writeln(z); }));
    shouldFailure(runner.run(q{ writeln(a); }), "Error: undefined identifier `a`");
    shouldSuccess(runner.run(q{ iota(x).map!(a => a * 2).writeln; }));
    shouldSuccess(runner.run(q{ 1+2 }));
    shouldSuccess(runner.run(q{ void po() { writeln("po"); } }));
    shouldSuccess(runner.run(q{ po(); }));
    shouldSuccess(runner.run(q{ auto doubleX = { return x *= 2; }; }));
    shouldSuccess(runner.run(q{ doubleX(); }));
    shouldSuccess(runner.run(q{ assert(x == 6); }));
    shouldFailure(runner.run(q{ auto a = 8 }), "Primary expression expected");
}

version (unittest) {
    void shouldSuccess(REPLRunner.Result result) {
        assert(result.success && result.message is null, result.message);
    }

    void shouldFailure(REPLRunner.Result result, string errorMessage) {
        assert(!result.success && result.message.stripRight == errorMessage);
    }

    void shouldFailure(REPLRunner.Result result) {
        assert(!result.success);
    }
}
