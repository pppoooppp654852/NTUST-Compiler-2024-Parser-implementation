%{
#include "parser.tab.h"
%}

integer     (-?([0-9]+))
float       (-?([0-9]*\.?[0-9]+))
blank_chars ([ \f\r\t\v]+)
expressions ([-+*/()])

%%

{integer}       { sscanf(yytext, "%d", &(yylval.intNum)); return INTEGER; }
{float}         { sscanf(yytext, "%f", &(yylval.floatNum)); return FLOAT; }
{expressions}   { return yytext[0]; }
{blank_chars}   { ; }
"="             { return yytext[0]; }
\n              { ; }

%%

int yywrap(void) {
    return 1;
}