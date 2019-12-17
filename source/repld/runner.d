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

    private Result success() {
        return Result(true);
    }

    private Result fail(string msg) {
        return Result(false, msg);
    }
}

string getType(VariableDeclaration decl) {
    // TODO: resolve non-builtin type
    return str(decl.type.type2.builtinType);
}

string toLiteral(FunctionDeclaration decl) {
    auto returnType = decl.hasAuto ? "auto" : conv(decl.returnType.tokens);
    auto attributes = (decl.hasRef ? "ref" : "")
        ~ decl.memberFunctionAttributes.map!(a => conv(a.tokens)).join(" ")
        ~ decl.attributes.map!(a => conv(a.tokens)).join(" ")
        ~ decl.storageClasses.map!(c => conv(c.tokens)).join(" ");
    auto parameters = conv(decl.parameters.tokens);
    auto functionBody = conv(decl.functionBody.tokens);

    return format!"function %s %s %s %s"(attributes, returnType, parameters,  functionBody);
}

string conv(const Token[] tokens) {
    return tokens.map!(t => t.text ? t.text : str(t.type)).join(" ");
}

unittest {
    auto runner = new REPLRunner();
    shouldSuccess(runner.run(q{ int x = 3; }));
    shouldSuccess(runner.run(q{ double y = 3.1415; }));
    shouldSuccess(runner.run(q{ import std; }));
    shouldSuccess(runner.run(q{ auto z = x * y; }));
    shouldSuccess(runner.run(q{ writeln(z); }));
    shouldSuccess(runner.run(q{ iota(x).map!(a => a * 2).writeln; }));
    shouldSuccess(runner.run(q{ 1+2 }));
    shouldSuccess(runner.run(q{ void po() { writeln("po"); } }));
    shouldSuccess(runner.run(q{ po(); }));
    shouldFailure(runner.run(q{ auto a = 8 }), "Primary expression expected");
    // shouldFailure(runner.run(q{ void func() { writeln("func"); } }), "Function declaration not allowed.");
}

version (unittest) {
    void shouldSuccess(REPLRunner.Result result) {
        assert(result.success && result.message is null, result.message);
    }

    void shouldFailure(REPLRunner.Result result, string errorMessage) {
        assert(!result.success && result.message == errorMessage, result.message);
    }
}
