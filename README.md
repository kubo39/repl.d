# repl.d
[![DUB Package](https://img.shields.io/dub/v/repl-d.svg)](https://code.dlang.org/packages/repl-d)
[![CircleCI](https://circleci.com/gh/Sobaya007/repl.d.svg?style=svg)](https://circleci.com/gh/Sobaya007/repl.d)

This project is a REPL tool for D programming language.
This package can be used for both single application and library.

## Supported Features
:heavy_check_mark: Variable Declaration  
:heavy_check_mark: Function Declaration  
:heavy_check_mark: Expression Evaluation  
:heavy_check_mark: Module Import  
:heavy_check_mark: Statement Execution  
:heavy_check_mark: Add Dub Project Dependency  
:x: Template Function Declaration  
:x: Struct or Class Declaration  

## Application use
Just execute `dub` in the project root to start.
If you want to break the line while input, type `|`.

## Library use
Documentation is [here](https://sobaya007.github.io/repl.d/).

Simple REPL tools can be implemented like below:

```d
import std;
import repld;

void main() {
    auto runner = new REPLRunner(); // initialize runner
    runner.addDependency("sbylib", "~master"); // add dependent library

    /* Read-Eval-Print Loop */
    string input;
    while (true) {
        write("> ");
        input ~= readln;
        auto result = runner.run(input);
        if (!result.success)
            writeln(result.message);
    }
}
```
