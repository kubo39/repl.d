import std;
import repld;

void main() {
    auto runner = new REPLRunner();
    bool shouldExit = false;
    runner["exit"] = { shouldExit = true; };
    runner["addDependency"] = (string packageName) => runner.addDependency(packageName);

    string input;
    while (!shouldExit) {
        write(input ? "| " : "> ");
        input ~= readln;

        if (input.stripRight.endsWith("|")) continue;

        auto result = runner.run(input.split("\n").map!(line => line.stripRight(" |")).join("\n"));

        scope (exit) input = null;
        if (!result.success)
            writeln(result.message);
    }
}
