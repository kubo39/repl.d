${imports}

import std : replace, Tuple, Variant;

${decls}

struct Param {
    Tuple!(Variant, string)[string] vals;

    static foreach (decl; decls) {
        mixin(q{
            ${type} ${name}() {
                if (auto val = "${name}" in vals) {
                    if (auto result = (*val)[0].peek!(${type})) {
                        return *result;
                    }
                }
                assert(false);
            }
        }.replace("${type}", decl.type)
        .replace("${name}", decl.name));
    }
}

void func(Param p) {
    import std : writeln;
    with (p) {
        writeln(${expression});
    }
}

extern(C) string funcName() { return func.mangleof; }
