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
        auto parseResult = parse(line);

        try {
            if (auto decl = parseResult.peek!(const VariableDeclaration)) {
                if (decl.declarators.length > 0) {
                    foreach (d; decl.declarators) {
                        evaluator.evalVarDecl(getType(*decl), getName(d), getInitializer(d));
                    }
                } else if (decl.autoDeclaration) {
                    foreach (p; decl.autoDeclaration.parts) {
                        evaluator.evalVarDecl(getType(*decl), getName(p), getInitializer(p));
                    }
                }
                return success;
            }
            if (auto decl = parseResult.peek!(const ImportDeclaration)) {
                evaluator.evalImport(conv(decl.tokens));
                return success;
            }
            if (auto st = parseResult.peek!(const Statement)) {
                evaluator.evalStatement(conv(st.tokens));
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

string getType(const VariableDeclaration decl) {
    if (auto type = decl.type) {
        if (auto res = str(type.type2.builtinType)) {
            return res;
        }
    }
    return "auto"; // get later
}

string getName(const Declarator decl) {
    return decl.name.text;
}

string getInitializer(const Declarator decl) {
    assert(decl.initializer.tokens.length == 1);
    return decl.initializer.tokens[0].text;
}

string getName(const AutoDeclarationPart decl) {
    return decl.identifier.text;
}

string getInitializer(const AutoDeclarationPart decl) {
    return conv(decl.initializer.tokens);
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
    shouldFailure(runner.run(q{ auto a = 8 }), "Primary expression expected");
    shouldFailure(runner.run(q{ void func() { writeln("func"); } }), "Function declaration not allowed.");
}

version (unittest) {
    void shouldSuccess(REPLRunner.Result result) {
        assert(result.success && result.message is null, result.message);
    }

    void shouldFailure(REPLRunner.Result result, string errorMessage) {
        assert(!result.success && result.message == errorMessage);
    }
}
