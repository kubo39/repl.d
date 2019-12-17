import std : replace, Tuple, Variant;
${imports}

${param}
${decls}
alias Param = ParamTemp!(decls);

void func(Param p) {
    with (p) {
        ${statement}
    }
}

extern(C) string funcName() { return func.mangleof; }
