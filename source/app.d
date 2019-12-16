import std;
import repld;

void main() {
    auto runner = new REPLRunner();
    while (true) {
        write("> ");
        auto input = readln;
        auto result = runner.run(input);
        if (!result.success)
            writeln(result.message);
    }
}
