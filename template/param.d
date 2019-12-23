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
            }
            static if (!(isCallable!(${type}) && Parameters!(${type}).length == 0)) {
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

version (Windows) {
    import core.sys.windows.windows;
    import core.sys.windows.dll;
    import core.stdc.stdio;
    
    __gshared HINSTANCE g_hInst;
    
    extern (Windows)
    BOOL DllMain(HINSTANCE hInstance, ULONG ulReason, LPVOID pvReserved)
    {
        switch (ulReason)
        {
    	case DLL_PROCESS_ATTACH:
    	    g_hInst = hInstance;
    	    dll_process_attach( hInstance, true );
    	    break;
    
    	case DLL_PROCESS_DETACH:
    	    dll_process_detach( hInstance, true );
    	    break;
    
    	case DLL_THREAD_ATTACH:
    	    dll_thread_attach( true, true );
    	    break;
    
    	case DLL_THREAD_DETACH:
    	    dll_thread_detach( true, true );
    	    break;
    
            default:
        }
        return true;
    }
}
