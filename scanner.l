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

"fun"           { return FUN; }  // 函數關鍵字
"var"           { return VAR; }  // 變量關鍵字
"bool"          { return BOOL; }  // 布林型
"char"          { return CHAR; }  // 字元型
"int"           { return INT; }  // 整數型
"real"          { return REAL; }  // 實數型
"string"        { return STRING; }  // 字串型
"true"          { return TRUE; }  // 真值
"false"         { return FALSE; }  // 假值
"if"            { return IF; }  // if關鍵字
"else"          { return ELSE; }  // else關鍵字
"while"         { return WHILE; }  // while關鍵字
"ret"           { return RET; }  // 返回關鍵字
"println"       { return PRINTLN; }  // 打印行
"print"         { return PRINT; }  // 打印
"{"             { return '{'; }  // 左大括號
"}"             { return '}'; }  // 右大括號
"["             { return '['; }  // 左中括號
"]"             { return ']'; }  // 右中括號
"("             { return '('; }  // 左小括號
")"             { return ')'; }  // 右小括號
";"             { return ';'; }  // 分號
":"             { return ':'; }  // 冒號
","             { return ','; }  // 逗號
"="             { return '='; }  // 等號
"=="            { return EQ; }  // 相等運算符
"!="            { return NE; }  // 不等運算符
"<"             { return '<'; }  // 小於運算符
"<="            { return LE; }  // 小於等於運算符
">"             { return '>'; }  // 大於運算符
">="            { return GE; }  // 大於等於運算符
"+"             { return '+'; }  // 加號
"-"             { return '-'; }  // 減號
"*"             { return '*'; }  // 乘號
"/"             { return '/'; }  // 除號
"^"             { return '^'; }  // 取內積運算符
"%"             { return '%'; }  // 取餘運算符
"!"             { return '!'; }  // 非運算符

{identifier}    { yylval.string = strdup(yytext); return IDENTIFIER; }  // 標識符
{integer}       { yylval.intValue = atoi(yytext); return INTEGER_LITERAL; }  // 整數字面值
{real}          { yylval.doubleValue = atof(yytext); return REAL_LITERAL; }  // 實數字面值
"'"{letter}"'"  { yylval.charValue = yytext[1]; return CHAR_LITERAL; }  // 字元字面值
\"(\\.|[^\"])*\" { yylval.stringValue = strdup(yytext); return STRING_LITERAL; }  // 字串字面值

[ \t\r]+        { ; }  // 忽略空白字元
\n              { ; }  // 忽略換行符

"/*"                    { BEGIN(C_COMMENT); }  // 開始C註釋
<C_COMMENT>"*/"         { BEGIN(INITIAL); }  // 結束C註釋
<C_COMMENT>\n           { ; }  // 忽略C註釋內的換行符
<C_COMMENT>.            { ; }  // 忽略C註釋內的其他字元
<C_COMMENT><<EOF>>      { fprintf(stderr, "Error: 未閉合的註解\n");
                          yyterminate(); }  // 未閉合的註釋錯誤
"//"                    { BEGIN(CPP_COMMENT); }  // 開始C++註釋
<CPP_COMMENT>\n         { BEGIN(INITIAL); }  // 結束C++註釋
<CPP_COMMENT>.          { ; }  // 忽略C++註釋內的其他字元

%%

int yywrap() {
    return 1;
}
