import std : Variant, replace, Tuple, tuple;
${imports}

${param}
${decls}
alias Param = ParamTemp!(decls);

Tuple!(Variant,string) func(Param p) {
    with (p) {
        ${type} v = ${expr};
        return tuple(Variant(v), typeof(${expr}).stringof);
    }
}

extern(C) string funcName() { return func.mangleof; }
