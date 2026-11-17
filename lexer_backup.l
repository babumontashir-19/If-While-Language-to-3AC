
%{
#include <stdio.h>
#include "y.tab.h"
%}

%option noyywrap yylineno

DIGIT   [0-9]
LETTER  [a-zA-Z_]
ID      {LETTER}({LETTER}|{DIGIT})*

%%

"if"        { return IF; }
"else"      { return ELSE; }
"while"     { return WHILE; }

"=="        { return EQ; }
"!="        { return NE; }
"<="        { return LE; }
">="        { return GE; }
"<"         { return LT; }
">"         { return GT; }

"="         { return ASSIGN; }
"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return MUL; }
"/"         { return DIV; }

";"         { return SEMICOLON; }
"("         { return LPAREN; }
")"         { return RPAREN; }
"{"         { return LBRACE; }
"}"         { return RBRACE; }

{DIGIT}+    { return NUMBER; }
{ID}        { return IDENTIFIER; }

[ \t\r\n]+  { /* Ignore whitespace */ }

.           { printf("Unknown character: %s at line %d\n", yytext, yylineno); }

%%
