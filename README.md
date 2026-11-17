# If-While Language to Three-Address Code (3AC)

## 1. Project Overview
This project implements a simple compiler for an integer-based If-While language. It uses Flex for lexical analysis and Bison for syntax analysis. The compiler generates Three-Address Code (3AC) for assignment statements, arithmetic expressions, if statements, if-else statements, and while loops.

## 2. Technologies Used
- C programming language
- Flex lexical analyzer
- GNU Bison parser generator
- GCC compiler
- Windows Command Prompt (CMD)

## 3. Main Features
- Token recognition
- Syntax analysis
- Arithmetic expression handling
- If, if-else, and while statement support
- Three-Address Code generation
- Temporary variables and labels
- Symbol table output
- Basic semantic error checking
- Constant folding optimization

## 4. Build Instructions
Open CMD in the project folder and run these commands one at a time:

`"C:\MinGW\msys\1.0\bin\bison.exe" -y -d parser.y`

`flex lexer.l`

`gcc y.tab.c lex.yy.c -o compiler.exe`

## 5. Running the Compiler
To compile a source file:

`compiler.exe input.txt`

To display tokens:

`compiler.exe -tokens input.txt`

## 6. Limitations
This is an educational mini-compiler. It supports a limited integer-based language and has not been verified for every possible input or nested control-flow case. The symbol table is a simplified compile-time representation and does not simulate actual loop execution.

## 7. Future Improvements
- Improve error reporting and recovery
- Expand semantic analysis
- Add more optimization techniques
- Improve symbol table handling
- Add more test cases

## 8. Acknowledgment
The project was developed for the Compiler Design Lab course. Any AI assistance used during development or documentation should be disclosed according to the course requirements.