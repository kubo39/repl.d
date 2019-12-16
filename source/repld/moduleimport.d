module repld.moduleimport;

import std;

class Imports {

    string[] imports;

    void push(string expr) {
        imports ~= expr;
    }

    override string toString() const {
        return imports.join("\n");
    }
}
