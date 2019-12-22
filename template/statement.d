${imports}

${param}
${decls}

export void __func__(__Param__ __param__) {
    with (__param__) {
        ${statement}
    }
}

export extern(C) string __funcName__() { return __func__.mangleof; }
