module repld.dll;

import std;
import core.runtime;
import core.thread;

class DLL {

    private void* lib;
    private string dllname;

    this(string dllname) {
        this.dllname = dllname;
        enforce(dllname.exists, format!"Shared library '%s' does not exist"(dllname));

        this.lib = Runtime.loadLibrary(dllname);
        version (Posix) {
            import core.sys.posix.dlfcn : dlerror;
            enforce(lib, dlerror().fromStringz.format!"Could not load shared library: %s");
        } else version (Windows) {
            enforce(lib, format!"Could not load shared library: %s"(dllname));
        } else {
            static assert(false, "This platform is not supported.");
        }
    }

    void unload() {
        Runtime.unloadLibrary(this.lib);
    }

    auto loadFunction(FunctionType)(string functionName) {
        const f = loadSymbol(functionName);
        enforce(f, format!"Could not load function '%s' from %s"(functionName, dllname));

        auto func = cast(FunctionType)f;
        enforce(func, format!"The type of '%s' is not '%s'"(functionName, FunctionType.stringof));

        return func;
    }

    private void* loadSymbol(string functionName) {
        version (Posix) {
            import core.sys.posix.dlfcn : dlsym;
            return dlsym(lib, functionName.toStringz);
        } else version (Windows) {
            import core.sys.windows.windows : GetProcAddress;
            return GetProcAddress(lib, functionName.toStringz);
        } else {
            static assert(false, "This platform is not supported.");
        }
    }
}
