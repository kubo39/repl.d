module repld.parse;

import std;
import dparse.ast;
import dparse.lexer;
import dparse.parser : parseModule;
import dparse.rollback_allocator : RollbackAllocator;

ParseResult parse(string sourceCode) {
    static Parser parser;
    if (parser is null)
        parser = new Parser();
    return parser.parse(sourceCode);
}

private class Parser {

    LexerConfig config;
    StringCache cache;
    ParseVisitor visitor;

    this() {
        this.cache = StringCache(StringCache.defaultBucketCount);
        this.visitor = new ParseVisitor();
    }

    ParseResult parse(string sourceCode) {
        sourceCode = format!q{ void __func__() { %s } }(sourceCode);
        auto tokens = getTokensForParser(sourceCode, config, &cache);

        Message[] messages;
        auto callback = (string fileName , size_t line, size_t column, string message, bool isError) {
            if (isError) {
                messages ~= Message(ErrorMessage(message));
            } else {
                messages ~= Message(WarningMessage(message));
            }
        };
        RollbackAllocator rba;
        auto m = parseModule(tokens, "test.d", &rba, callback);

        if (messages) return ParseResult(messages);

        visitor.visit(m);
        scope (exit) visitor.result = ParseResult.init;

        return visitor.result;
    }
}

private class ParseVisitor : ASTVisitor {
    alias visit = ASTVisitor.visit;

    ParseResult result;

    override void visit(const VariableDeclaration decl) {
        result = decl;
    }

    override void visit(const ImportDeclaration decl) {
        result = decl;
    }

    override void visit(const Statement st) {
        result = st;
    }
}

alias ErrorMessage = Typedef!string;
alias WarningMessage = Typedef!string;
alias Message = Algebraic!(ErrorMessage, WarningMessage);
alias ParseResult = Algebraic!(const VariableDeclaration, const ImportDeclaration, const Statement, Message[]);
