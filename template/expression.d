${imports}

${decls}
${param}

void __func__(__Param__ __param__) {
    with (__param__) {
        static if (is(typeof(${expression}) == void)) {
            ${expression};
        } else static if (is(typeof(${expression}) __V__ == return) && is(__V__ == void)) {
            ${expression};
        } else {
            import std : __writeln__ = writeln;
            __writeln__(${expression});
        }
    }
}

extern(C) string __funcName__() { return __func__.mangleof; }
