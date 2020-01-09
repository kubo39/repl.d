module repld.dll;

import std;
import core.runtime;
import core.thread;
import libloading;

class DLL {
    private Library lib;

    this(string dllname) {
        enforce(dllname.exists, format!"Shared library '%s' does not exist"(dllname));

        this.lib = loadLibrary(dllname);
    }

    void unload() {
        dispose(this.lib);
    }

    auto loadFunction(FunctionType)(string functionName) {
        return getSymbol!(FunctionType)(this.lib, functionName);
    }
}
