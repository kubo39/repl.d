import std : Variant, replace, Tuple, tuple;

${imports}


${decls}

struct Param {
    Tuple!(Variant, string)[string] vals;

    static foreach (decl; decls) {
        mixin(q{
            ${decl.type} ${decl.name}() {
                if (auto val = "${decl.name}" in vals) {
                    if (auto result = (*val)[0].peek!(${decl.type})) {
                        return *result;
                    }
                }
                assert(false);
            }
        }.replace("${decl.type}", decl.type)
        .replace("${decl.name}", decl.name));
    }
}

Tuple!(Variant,string) func(Param p) {
    with (p) {
        ${type} v = ${expr};
        return tuple(Variant(v), typeof(${expr}).stringof);
    }
}

extern(C) string funcName() { return func.mangleof; }
