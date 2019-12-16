module repld.dll;

import std;
import core.runtime;
import core.thread;
import core.sys.posix.dlfcn;

class DLL {

    private void* lib;
    private string dllname;

    this(string dllname) {
        this.dllname = dllname;
        enforce(dllname.exists, format!"Shared library '%s' does not exist"(dllname));

        this.lib = Runtime.loadLibrary(dllname);
        version (Posix) {
            enforce(lib, dlerror().fromStringz.format!"Could not load shared library: %s");
        } else {
            enforce(lib, format!"Could not load shared library: %s"(dllname));
        }
    }

    void unload() {
        Runtime.unloadLibrary(this.lib);
    }

    auto loadFunction(FunctionType)(string functionName) {
        const f = dlsym(lib, functionName.toStringz);
        enforce(f, format!"Could not load function '%s' from %s"(functionName, dllname));

        auto func = cast(FunctionType)f;
        enforce(func, format!"The type of '%s' is not '%s'"(functionName, FunctionType.stringof));

        return func;
    }

}
