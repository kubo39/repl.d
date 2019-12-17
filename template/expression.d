import std : replace, Tuple, Variant, writeln;
${imports}

${param}
${decls}
alias Param = ParamTemp!(decls);

void func(Param p) {
    with (p) {
        writeln(${expression});
    }
}

extern(C) string funcName() { return func.mangleof; }
