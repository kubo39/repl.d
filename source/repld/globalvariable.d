module repld.globalvariable;

import std;
import dparse.ast;

class GlobalVariables {

    private Tuple!(Variant, string)[string] vs;

    ref T get(T)(string name) {
        return *vs[name].peek!T;
    }

    void set(string type, string name, Variant v) {
        vs[name] = tuple(v, type);
    }

    void set(T)(string name, T v) {
        set(T.stringof, name, Variant(v));
    }

    auto asParams() {
        return Param(vs);
    }

    string getDeclarations() {
        return format!q{
            struct Declaration {
                string name;
                string type;
            }

            enum decls = [%s];
        }(vs.byKeyValue.map!(p => format!q{Declaration("%s", "%s")}(p.key, p.value[1])).join(", "));
    }
}

struct Param {
    Tuple!(Variant, string)[string] vs;
}

