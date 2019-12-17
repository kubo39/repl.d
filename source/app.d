import std;
import repld;

void main() {
    auto runner = new REPLRunner();
    string input;

    while (true) {
        write(input ? "| " : "> ");
        input ~= readln;

        if (input.stripRight.endsWith("|")) continue;

        auto result = runner.run(input.split("\n").map!(line => line.stripRight(" |")).join("\n"));

        scope (exit) input = null;
        if (!result.success)
            writeln(result.message);
    }
}
