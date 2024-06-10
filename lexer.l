%{
#include "parser.tab.h"
#include <stdio.h>

int lineNum = 1;
%}

digit       [0-9]
letter      [a-zA-Z_]
identifier  {letter}({letter}|{digit})*
integer     {digit}+
real        {digit}+"."{digit}*

%x C_COMMENT
%x CPP_COMMENT

%%

 /* Comments */
"/*"                    { BEGIN(C_COMMENT); }
<C_COMMENT>"*/"         { BEGIN(INITIAL); }
<C_COMMENT>\n           { lineNum++; }
<C_COMMENT>.            { ; }
<C_COMMENT><<EOF>>      { fprintf(stderr, "Error on line %d: Unclosed comment\n", lineNum);
                          yyterminate(); }

"//"                    { BEGIN(CPP_COMMENT); }
<CPP_COMMENT>\n         { BEGIN(INITIAL); lineNum++; }
<CPP_COMMENT>.          { ; }

"fun"           { return FUN; }
"var"           { return VAR; }
"val"           { return VAL; }
"bool"          { return BOOL; }
"char"          { return CHAR; }
"int"           { return INT; }
"real"          { return REAL; }
"true"          { return TRUE; }
"false"         { return FALSE; }
"class"         { return CLASS; }
"if"            { return IF; }
"else"          { return ELSE; }
"for"           { return FOR; }
"while"         { return WHILE; }
"do"            { return DO; }
"switch"        { return SWITCH; }
"case"          { return CASE; }
"ret"           { return RET; }
"println"       { return PRINTLN; }
"print"         { return PRINT; }

{identifier}    { yylval.str = strdup(yytext); return IDENTIFIER; }
{integer}       { yylval.ival = atoi(yytext); return INTEGER_LITERAL; }
{real}          { yylval.rval = atof(yytext); return REAL_LITERAL; }
"'"{letter}"'"  { yylval.cval = yytext[1]; return CHAR_LITERAL; }
\"(\\.|[^\"])*\" { yylval.sval = strdup(yytext); return STRING_LITERAL; }

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
"#"             { return '#'; }
"%"             { return '%'; }
"&&"            { return AND; }
"||"            { return OR; }
"!"             { return '!'; }

[ \t\r]+      { /* ignore whitespace */ }
\n              { lineNum++; }

%%

int yywrap() {
    return 1;
}
