
%{
#include <stdio.h>
#include <stdlib.h>

int yylex(void);
int yyerror(const char *s);
extern int yylineno;
%}

%token IF ELSE WHILE
%token EQ NE LE GE LT GT
%token ASSIGN PLUS MINUS MUL DIV
%token SEMICOLON LPAREN RPAREN LBRACE RBRACE
%token NUMBER IDENTIFIER

%left PLUS MINUS
%left MUL DIV

%%

program:
      statements
      ;

statements:
      /* empty */
    | statements statement
    ;

statement:
      IDENTIFIER ASSIGN expression SEMICOLON
    | WHILE LPAREN condition RPAREN LBRACE statements RBRACE
    | IF LPAREN condition RPAREN LBRACE statements RBRACE
    | IF LPAREN condition RPAREN LBRACE statements RBRACE
      ELSE LBRACE statements RBRACE
    ;

condition:
      expression LT expression
    | expression GT expression
    | expression LE expression
    | expression GE expression
    | expression EQ expression
    | expression NE expression
    ;

expression:
      NUMBER
    | IDENTIFIER
    | expression PLUS expression
    | expression MINUS expression
    | expression MUL expression
    | expression DIV expression
    | LPAREN expression RPAREN
    ;

%%

int yyerror(const char *s)
{
    printf("Syntax error near line %d: %s\n", yylineno, s);
    return 0;
}

int main(void)
{
    if (yyparse() == 0)
        printf("Syntax accepted!\n");

    return 0;
}
