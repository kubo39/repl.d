import std : Variant;
${imports}

${decls}
${param}

export Variant __func__(__Param__ __param__) {
    with (__param__) {
        ${type} __value__ = ${expr};
        return Variant(__value__);
    }
}

export extern(C) string __funcName__() { return __func__.mangleof; }
export extern(C) string __typeName__() { 
    with (__Param__.init) {
        return typeof({
            return ${expr};
        }()).stringof;
    }
}
