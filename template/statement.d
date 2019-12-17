${imports}

${param}
${decls}

void __func__(__Param__ __param__) {
    with (__param__) {
        ${statement}
    }
}

extern(C) string __funcName__() { return __func__.mangleof; }
