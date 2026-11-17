
%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
typedef struct Expr Expr;
#include "y.tab.h"

int tokens_mode = 0;
int lexical_errors = 0;

static void showToken(const char *name)
{
    if (tokens_mode)
        printf("Line %-4d %-14s %s\n", yylineno, name, yytext);
}
%}

%option noyywrap yylineno

DIGIT   [0-9]
LETTER  [a-zA-Z_]
ID      {LETTER}({LETTER}|{DIGIT})*

%%

"if"        { showToken("IF"); return IF; }
"else"      { showToken("ELSE"); return ELSE; }
"while"     { showToken("WHILE"); return WHILE; }

"=="        { showToken("EQ"); return EQ; }
"!="        { showToken("NE"); return NE; }
"<="        { showToken("LE"); return LE; }
">="        { showToken("GE"); return GE; }
"<"         { showToken("LT"); return LT; }
">"         { showToken("GT"); return GT; }

"="         { showToken("ASSIGN"); return ASSIGN; }
"+"         { showToken("PLUS"); return PLUS; }
"-"         { showToken("MINUS"); return MINUS; }
"*"         { showToken("MUL"); return MUL; }
"/"         { showToken("DIV"); return DIV; }

";"         { showToken("SEMICOLON"); return SEMICOLON; }
"("         { showToken("LPAREN"); return LPAREN; }
")"         { showToken("RPAREN"); return RPAREN; }
"{"         { showToken("LBRACE"); return LBRACE; }
"}"         { showToken("RBRACE"); return RBRACE; }

{DIGIT}+    {
                yylval.str = strdup(yytext);
                showToken("NUMBER");
                return NUMBER;
            }

{ID}        {
                yylval.str = strdup(yytext);
                showToken("IDENTIFIER");
                return IDENTIFIER;
            }

[ \t\r\n]+  { /* Ignore whitespace */ }

.           {
                fprintf(stderr,
                        "Lexical error: unknown character '%s' at line %d\n",
                        yytext, yylineno);
                lexical_errors++;
                showToken("INVALID");
                return INVALID;
            }

%%
