%{
#include "parser.tab.h"
#include <stdio.h>
%}

digit       [0-9]
letter      [a-zA-Z_]
identifier  {letter}({letter}|{digit})*
integer     {digit}+
real        {digit}+"."{digit}*

%x C_COMMENT
%x CPP_COMMENT

%%

"fun"           { return FUN; }
"var"           { return VAR; }
"bool"          { return BOOL; }
"char"          { return CHAR; }
"int"           { return INT; }
"real"          { return REAL; }
"string"        { return STRING; }
"true"          { return TRUE; }
"false"         { return FALSE; }
"if"            { return IF; }
"else"          { return ELSE; }
"while"         { return WHILE; }
"ret"           { return RET; }
"println"       { return PRINTLN; }
"print"         { return PRINT; }
"{"             { return '{'; }
"}"             { return '}'; }
"["             { return '['; }
"]"             { return ']'; }
"("             { return '('; }
")"             { return ')'; }
";"             { return ';'; }
":"             { return ':'; }
","             { return ','; }
"="             { return '='; }
"=="            { return EQ; }
"!="            { return NE; }
"<"             { return '<'; }
"<="            { return LE; }
">"             { return '>'; }
">="            { return GE; }
"+"             { return '+'; }
"-"             { return '-'; }
"*"             { return '*'; }
"/"             { return '/'; }
"^"             { return '^'; }
"%"             { return '%'; }
"!"             { return '!'; }

{identifier}    { yylval.str = strdup(yytext); return IDENTIFIER; }
{integer}       { yylval.ival = atoi(yytext); return INTEGER_LITERAL; }
{real}          { yylval.rval = atof(yytext); return REAL_LITERAL; }
"'"{letter}"'"  { yylval.cval = yytext[1]; return CHAR_LITERAL; }
\"(\\.|[^\"])*\" { yylval.sval = strdup(yytext); return STRING_LITERAL; }

[ \t\r]+        { ; }
\n              { ; }

"/*"                    { BEGIN(C_COMMENT); }
<C_COMMENT>"*/"         { BEGIN(INITIAL); }
<C_COMMENT>\n           { ; }
<C_COMMENT>.            { ; }
<C_COMMENT><<EOF>>      { fprintf(stderr, "Error: Unclosed comment\n");
                          yyterminate(); }
"//"                    { BEGIN(CPP_COMMENT); }
<CPP_COMMENT>\n         { BEGIN(INITIAL); }
<CPP_COMMENT>.          { ; }

%%

int yywrap() {
    return 1;
}
