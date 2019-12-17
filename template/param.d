struct __Param__ {
    import std : Tuple, Variant, isCallable, ReturnType, Parameters, replace;

    private Tuple!(Variant, string)[string] __vals__;
    static foreach (decl; __decls__) {
        mixin(q{
            static if (isCallable!(${type})) {
                ReturnType!(${type}) ${name}(Parameters!(${type}) p) {
                    if (auto val = "${name}" in __vals__) {
                        if (auto result = (*val)[0].peek!(${type})) {
                            return (*result)(p);
                        }
                    }
                    assert(false);
                }
            } else {
                ref ${type} ${name}() {
                    if (auto val = "${name}" in __vals__) {
                        if (auto result = (*val)[0].peek!(${type})) {
                            return *result;
                        }
                    }
                    assert(false);
                }
            }
        }.replace("${type}", decl.type)
        .replace("${name}", decl.name));
    }
}
