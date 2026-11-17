
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
int yyerror(const char *s);
extern int yylineno;
extern FILE *yyin;
extern int tokens_mode;
extern int lexical_errors;

int tempCount = 0;
int labelCount = 0;
int semantic_errors = 0;
struct Expr {
    char *place;
    int is_const;
    long value;
};
typedef struct Expr Expr;

typedef struct {
    char name[128];
    int has_value;
    long value;
} Symbol;

Symbol symbols[500];
int symbol_count = 0;

int lookupSymbol(const char *name)
{
    int i;
    for (i = 0; i < symbol_count; i++)
        if (strcmp(symbols[i].name, name) == 0)
            return i;
    return -1;
}

void checkVariable(const char *name)
{
    if (lookupSymbol(name) < 0) {
        fprintf(stderr,
                "Semantic error at line %d: variable '%s' used before assignment\n",
                yylineno, name);
        semantic_errors++;
    }
}

void assignSymbol(const char *name, Expr *e)
{
    int i = lookupSymbol(name);

    if (i < 0) {
        if (symbol_count >= 500) {
            fprintf(stderr, "Symbol table is full\n");
            semantic_errors++;
            return;
        }
        i = symbol_count++;
        strncpy(symbols[i].name, name, sizeof(symbols[i].name) - 1);
        symbols[i].name[sizeof(symbols[i].name) - 1] = '\0';
    }

    symbols[i].has_value = e->is_const;
    if (e->is_const)
        symbols[i].value = e->value;
}

void printSymbolTable(void)
{
    int i;
    printf("\nSymbol Table\n");
    printf("------------------------------\n");
    printf("%-18s %-8s %s\n", "Name", "Type", "Value");
    for (i = 0; i < symbol_count; i++) {
        if (symbols[i].has_value)
            printf("%-18s %-8s %ld\n",
                   symbols[i].name, "int", symbols[i].value);
        else
            printf("%-18s %-8s %s\n",
                   symbols[i].name, "int", "unknown");
    }
}

char *copyText(const char *s)
{
    char *p = (char *)malloc(strlen(s) + 1);
    if (!p) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(1);
    }
    strcpy(p, s);
    return p;
}

char *newTemp(void)
{
    char *s = (char *)malloc(32);
    if (!s) exit(1);
    sprintf(s, "t%d", ++tempCount);
    return s;
}

char *newLabel(void)
{
    char *s = (char *)malloc(32);
    if (!s) exit(1);
    sprintf(s, "L%d", ++labelCount);
    return s;
}

Expr *makeExpr(char *place, int is_const, long value)
{
    Expr *e = (Expr *)malloc(sizeof(Expr));
    if (!e) exit(1);
    e->place = place;
    e->is_const = is_const;
    e->value = value;
    return e;
}

char *makeCondition(char *a, char *op, char *b)
{
    char *s = (char *)malloc(strlen(a) + strlen(op) + strlen(b) + 4);
    if (!s) exit(1);
    sprintf(s, "%s %s %s", a, op, b);
    return s;
}

char *makePair(char *a, char *b)
{
    char *s = (char *)malloc(strlen(a) + strlen(b) + 2);
    if (!s) exit(1);
    sprintf(s, "%s,%s", a, b);
    return s;
}

char *emitCondition(char *condition)
{
    char *t = newTemp();
    printf("%s = %s\n", t, condition);
    return t;
}

Expr *makeArithmetic(Expr *a, char op, Expr *b)
{
    char text[64];
    long value = 0;

    if (a->is_const && b->is_const) {
        if (op == '+') value = a->value + b->value;
        else if (op == '-') value = a->value - b->value;
        else if (op == '*') value = a->value * b->value;
        else {
            if (b->value == 0) {
                fprintf(stderr,
                        "Semantic error at line %d: division by zero\n",
                        yylineno);
                semantic_errors++;
                return makeExpr(copyText("0"), 1, 0);
            }
            value = a->value / b->value;
        }

        sprintf(text, "%ld", value);
        return makeExpr(copyText(text), 1, value);
    }

    if (op == '/' && b->is_const && b->value == 0) {
        fprintf(stderr,
                "Semantic error at line %d: division by zero\n",
                yylineno);
        semantic_errors++;
    }

    {
        char *t = newTemp();
        printf("%s = %s %c %s\n", t, a->place, op, b->place);
        return makeExpr(t, 0, 0);
    }
}
%}

%union {
    char *str;
    Expr *expr;
}

%token IF ELSE WHILE
%token EQ NE LE GE LT GT
%token ASSIGN PLUS MINUS MUL DIV
%token SEMICOLON LPAREN RPAREN LBRACE RBRACE
%token INVALID
%token <str> NUMBER IDENTIFIER

%type <expr> expression
%type <str> condition if_prefix if_else_start while_prefix

%left PLUS MINUS
%left MUL DIV

%%

program:
    statements
    {
        if (lexical_errors == 0 && semantic_errors == 0) {
            printf("\nSyntax accepted!\n");
            printSymbolTable();
        } else {
            fprintf(stderr,
                    "\nCompilation failed: %d lexical error(s), %d semantic error(s).\n",
                    lexical_errors, semantic_errors);
        }
    }
    ;

statements:
      /* empty */
    | statements statement
    ;

statement:
      IDENTIFIER ASSIGN expression SEMICOLON
      {
          printf("%s = %s\n", $1, $3->place);
          assignSymbol($1, $3);
      }
    | while_statement
    | if_statement
    ;

block:
    LBRACE statements RBRACE
    ;

while_prefix:
    WHILE LPAREN condition RPAREN
    {
        char *start = newLabel();
        char *end = newLabel();
        char *test;

        printf("%s:\n", start);
        test = emitCondition($3);
        printf("ifFalse %s goto %s\n", test, end);

        $$ = makePair(start, end);
    }
    ;

while_statement:
    while_prefix block
    {
        char *comma = strchr($1, ',');
        if (comma != NULL) {
            *comma = '\0';
            printf("goto %s\n", $1);
            printf("%s:\n", comma + 1);
        }
    }
    ;

if_prefix:
    IF LPAREN condition RPAREN
    {
        char *test = emitCondition($3);
        $$ = newLabel();
        printf("ifFalse %s goto %s\n", test, $$);
    }
    ;

if_else_start:
    if_prefix block ELSE
    {
        char *end = newLabel();
        printf("goto %s\n", end);
        printf("%s:\n", $1);
        $$ = end;
    }
    ;

if_statement:
      if_prefix block
      {
          printf("%s:\n", $1);
      }
    | if_else_start block
      {
          printf("%s:\n", $1);
      }
    ;

condition:
      expression LT expression
      { $$ = makeCondition($1->place, "<", $3->place); }
    | expression GT expression
      { $$ = makeCondition($1->place, ">", $3->place); }
    | expression LE expression
      { $$ = makeCondition($1->place, "<=", $3->place); }
    | expression GE expression
      { $$ = makeCondition($1->place, ">=", $3->place); }
    | expression EQ expression
      { $$ = makeCondition($1->place, "==", $3->place); }
    | expression NE expression
      { $$ = makeCondition($1->place, "!=", $3->place); }
    ;

expression:
      NUMBER
      {
          $$ = makeExpr(copyText($1), 1, atol($1));
      }
    | IDENTIFIER
      {
          checkVariable($1);
          $$ = makeExpr(copyText($1), 0, 0);
      }
    | expression PLUS expression
      { $$ = makeArithmetic($1, '+', $3); }
    | expression MINUS expression
      { $$ = makeArithmetic($1, '-', $3); }
    | expression MUL expression
      { $$ = makeArithmetic($1, '*', $3); }
    | expression DIV expression
      { $$ = makeArithmetic($1, '/', $3); }
    | LPAREN expression RPAREN
      { $$ = $2; }
    ;

%%

int yyerror(const char *s)
{
    fprintf(stderr, "Syntax error near line %d: %s\n", yylineno, s);
    return 0;
}

int main(int argc, char *argv[])
{
    int i;
    int result;

    for (i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-tokens") == 0) {
            tokens_mode = 1;
        } else {
            yyin = fopen(argv[i], "r");
            if (!yyin) {
                perror(argv[i]);
                return 1;
            }
        }
    }

    if (tokens_mode) {
        while (yylex() != 0) { }
        if (yyin && yyin != stdin)
            fclose(yyin);
        return lexical_errors ? 1 : 0;
    }

    result = yyparse();

    if (yyin && yyin != stdin)
        fclose(yyin);

    if (result != 0 || lexical_errors != 0 || semantic_errors != 0)
        return 1;

    return 0;
}
