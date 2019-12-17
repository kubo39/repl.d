module repld.parse;

import std;
import dparse.ast;
import dparse.lexer;
import dparse.parser : Parser;
import dparse.rollback_allocator : RollbackAllocator;

ParseResult parse(string sourceCode) {
    static ReplParser parser;
    if (parser is null)
        parser = new ReplParser();
    return parser.parse(sourceCode);
}

private class ReplParser {

    LexerConfig config;
    StringCache cache;

    this() {
        this.cache = StringCache(StringCache.defaultBucketCount);
    }

    ParseResult parse(string sourceCode) {
        auto tokens = getTokensForParser(sourceCode, config, &cache);

        static foreach (target; ParseTarget) {
            if (canParse!target(tokens)) {
                auto result = parse!target(tokens);
                if (result[1]) return ParseResult(result[1]);
                return ParseResult(result[0]);
            }
        }

        // TODO: more smart solution
        Message[][] result;
        static foreach (target; ParseTarget) {
            result ~= parse!target(tokens)[1];
        }
        return ParseResult(result.reduce!((a,b) => a.length < b.length ? a : b));
    }

    private auto parse(Target)(const Token[] tokens) {
        auto parser = new Parser;
        Message[] messages;
        RollbackAllocator rba;
        parser.fileName = "temp.d";
        parser.tokens = tokens.dup;
        parser.allocator = &rba;
        parser.messageDelegate = (string fileName , size_t line, size_t column, string message, bool isError) {
            if (isError) {
                messages ~= Message(ErrorMessage(message));
            } else {
                messages ~= Message(WarningMessage(message));
            }
        };
        return tuple(mixin("parser.parse", Target.stringof), messages);
    }

    private bool canParse(Target)(const Token[] tokens) {
        auto parser = new Parser;
        bool result = true;
        RollbackAllocator rba;
        parser.fileName = "temp.d";
        parser.tokens = tokens.dup;
        parser.allocator = &rba;
        parser.messageDelegate = (string fileName , size_t line, size_t column, string message, bool isError) {
            result = false;
        };
        mixin("parser.parse", Target.stringof, ";");
        return result;
    }
}

private alias ParseTarget = AliasSeq!(VariableDeclaration, AutoDeclaration, ImportDeclaration, Statement, Expression);
alias ErrorMessage = Typedef!string;
alias WarningMessage = Typedef!string;
alias Message = Algebraic!(ErrorMessage, WarningMessage);
alias ParseResult = Algebraic!(ParseTarget, Message[]);
