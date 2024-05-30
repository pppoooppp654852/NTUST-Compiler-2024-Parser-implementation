%{
#include <iostream>
#include <stdio.h>

using namespace std;

void yyerror(const char *s);
extern int yylex();
extern int yyparse();

%}

%union {
    float   floatNum;
    int     intNum;
}

%token <intNum>   INTEGER
%token <floatNum> FLOAT

%type <floatNum> value expr

%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%%

func:
      expr '='              { printf("Result: %f\n", $1); }
    ;

expr:
      value                { $$ = $1; }
    | expr '+' expr         { $$ = $1 + $3; }
    | expr '-' expr         { $$ = $1 - $3; }
    | expr '*' expr         { $$ = $1 * $3; }
    | expr '/' expr         { $$ = $1 / $3; }
    | '-' expr %prec UMINUS { $$ = -$2; }
    | '(' expr ')'          { $$ = $2; }
    ;

value:
      FLOAT                 { $$ = $1; }
    | INTEGER               { $$ = (float)$1; }
    ;

%%

extern FILE* yyin;

void yyerror(const char *s) {
    cerr << s << endl;
}

int main()
{
    const char* sFile = "file.txt";
    FILE* fp = fopen(sFile, "r");
    if (fp == NULL) {
        printf("cannot open %s\n", sFile);
        return -1;
    }
    
    yyin = fp;

    yyparse();

    fclose(fp);

    return 0;
}