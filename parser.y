%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <cstring>
#include <cstdlib>
#include <cstdio>
#include <map>

void yyerror(const char *s);
int yylex(void);

using namespace std;

FILE *outputFile;

struct VInfo {
    std::string type;
    int length;
};
std::map<std::string, VInfo> symbolMap;

int tmpCounter = 0;
bool i_flag = false;

// 用於生成數組打印代碼的函數
char* generateArrayPrintCode(const char* codeString, const char* typeString, int length, bool newLine) {
    char* loopStatement = new char[200];
    char* printStatement;
    if (!i_flag) {
        i_flag = true;
        sprintf(loopStatement, "int i;\nprintf(\"{\");\nfor (i = 0; i < %d; ++i) {\n    if (i != 0) printf(\", \");\n    printf(\"", length);
    } else {
        sprintf(loopStatement, "printf(\"{\");\nfor (i = 0; i < %d; ++i) {\n    if (i != 0) printf(\", \");\n    printf(\"", length);
    }

    if (strcmp(typeString, "int") == 0) {
        strcat(loopStatement, "%%d\", %s[i]);\n}\nprintf(\"}\");\n");
    } else if (strcmp(typeString, "double") == 0) {
        strcat(loopStatement, "%%f\", %s[i]);\n}\nprintf(\"}\");\n");
    } else if (strcmp(typeString, "char") == 0) {
        strcat(loopStatement, "%%c\", %s[i]);\n}\nprintf(\"}\");\n");
    } else {
        strcat(loopStatement, "%%s\", %s[i]);\n}\nprintf(\"}\");\n");
    }

    char* newLineString;
    if (newLine) {
        newLineString = "\\n";
    } else {
        newLineString = "";
    }
    printStatement = new char[strlen(loopStatement) + strlen(codeString) * 2 + strlen(newLineString) + 1];
    sprintf(printStatement, loopStatement, codeString, newLineString);

    return printStatement;
}

// 用於生成標量打印代碼的函數
char* generateScalarPrintCode(const char* codeString, const char* typeString, bool newLine) {
    char* printStatement = new char[strlen(codeString) + 50];
    char* formatString;
    if (strcmp(typeString, "int") == 0) {
        formatString = "%d";
    } else if (strcmp(typeString, "double") == 0) {
        formatString = "%f";
    } else if (strcmp(typeString, "char") == 0) {
        formatString = "%c";
    } else {
        formatString = "%s";
    }

    char* newLineString;
    if (newLine) {
        newLineString = "\\n";
    } else {
        newLineString = "";
    }
    sprintf(printStatement, "printf(\"%s%s\", %s);\n", formatString, newLineString, codeString);

    return printStatement;
}

char* handleAssignment(const char* lhsCode, const char* lhsType, const char* rhsCode, const char* rhsType) {
    auto it1 = symbolMap.find(lhsCode);
    auto it2 = symbolMap.find(rhsCode);

    if (it1 != symbolMap.end() && it1->second.length > 0) { // 左邊是數組
        if (it2 != symbolMap.end() && it2->second.length > 0) { // 右邊也是數組
            if (strcmp(lhsType, rhsType) == 0 && it1->second.length == it2->second.length) {
                // 數組類型和大小匹配
                char* arrayAssignment = new char[300];
                sprintf(arrayAssignment, "for (int i = 0; i < %d; ++i) %s[i] = %s[i];\n", it1->second.length, lhsCode, rhsCode);
                char* result = new char[strlen(arrayAssignment) + 1];
                strcpy(result, arrayAssignment);
                return result;
            } else {
                yyerror("數組賦值類型或長度不匹配");
            }
        } else {
            yyerror("數組賦值右邊必須是數組");
        }
    } else {
        // 標量賦值
        char* result = new char[strlen(lhsCode) + strlen(rhsCode) + 5];
        sprintf(result, "%s = %s;\n", lhsCode, rhsCode);
        return result;
    }
    return NULL;
}

char* handleArrayInitialization(const char* lhsCode, const char* lhsType, const char* initListCode, int initListLength) {
    auto it = symbolMap.find(lhsCode);
    if (it != symbolMap.end() && it->second.length > 0) { // 左邊是數組
        if (it->second.length >= initListLength) { // 初始化列表適合數組
            char* tempArrayName = new char[20];
            sprintf(tempArrayName, "tmp_arr%d", tmpCounter);
            tmpCounter++;
            char* declareTempArray = new char[30];
            char* arrayInitialization = new char[300 + strlen(initListCode)];
            sprintf(declareTempArray, "%s %s[%d] = {%s};\n", lhsType, tempArrayName, it->second.length, initListCode);
            sprintf(arrayInitialization, "for (int i = 0; i < %d; ++i) %s[i] = %s[i];\n", it->second.length, lhsCode, tempArrayName);
            char* result = new char[strlen(declareTempArray) + strlen(arrayInitialization) + 1];
            sprintf(result, "%s%s", declareTempArray, arrayInitialization);
            return result;
        } else {
            yyerror("初始化列表對數組來說太長");
        }
    } else {
        yyerror("數組賦值左邊必須是數組");
    }
    return NULL;
}
%}

%union {
    int intValue;
    double doubleValue;
    char charValue;
    char *stringValue;
    char *string;
    struct {
        char *codeString;
        char *typeString;
        char *processString;
    } expressionValue;
    struct {
        char *codeString;
        int length;
    } expressionListValue;
}

%token <stringValue> STRING_LITERAL
%token <intValue> INTEGER_LITERAL
%token <doubleValue> REAL_LITERAL
%token <charValue> CHAR_LITERAL
%token <string> IDENTIFIER
%token TRUE FALSE IF ELSE WHILE RET PRINTLN PRINT FUN VAR BOOL CHAR INT REAL STRING
%token LE GE EQ NE

%type <expressionValue> expression
%type <expressionListValue> expression_list

%type <string> function
%type <string> statements
%type <string> declaration
%type <string> type
%type <string> statement

%left '+' '-'
%left '*' '/'
%left '^'
%nonassoc UMINUS

%%

file:
    function
    {
        // 將生成的C代碼寫入輸出文件，並添加必要的頭文件
        fprintf(outputFile, "#include <stdio.h>\n#include <stdlib.h>\n#include <stdbool.h>\n\n%s\n", $1);
        fclose(outputFile);
    }
;

function:
    FUN IDENTIFIER '(' ')' '{' statements '}' 
    {
        // 構造main函數的代碼
        $$ = new char[strlen($2) + strlen($6) + 100];
        sprintf($$, "int %s() {\n%s}\n\n", $2, $6);
    }
;

statements:
    statement
    {
        $$ = new char[strlen($1) + 1];
        strcpy($$, $1);
    }
    | statements statement
    {
        $$ = new char[strlen($1) + strlen($2) + 1];
        strcpy($$, $1);
        strcat($$, $2);
    }
;

statement:
    declaration
    {
        $$ = new char[strlen($1) + 1];
        strcpy($$, $1);
    }
    | PRINTLN '(' expression ')' ';'
    {
        char* printStatement;  // 打印語句
        auto it = symbolMap.find($3.codeString);
        if (it != symbolMap.end() && it->second.length > 0) {
            // 數組打印邏輯
            printStatement = generateArrayPrintCode($3.codeString, $3.typeString, it->second.length, true);
        } else {
            // 標量打印邏輯
            printStatement = generateScalarPrintCode($3.codeString, $3.typeString, true);
        }

        if ($3.processString != NULL) {
            $$ = new char[strlen($3.processString) + strlen(printStatement) + 2];
            sprintf($$, "%s\n%s", $3.processString, printStatement);
        } else {
            $$ = new char[strlen(printStatement) + 1];
            sprintf($$, "%s", printStatement);
        }
    }
    | PRINT '(' expression ')' ';'
    {
        char* printStatement;  // 打印語句
        auto it = symbolMap.find($3.codeString);
        if (it != symbolMap.end() && it->second.length > 0) {
            // 數組打印邏輯
            printStatement = generateArrayPrintCode($3.codeString, $3.typeString, it->second.length, false);
        } else {
            // 標量打印邏輯
            printStatement = generateScalarPrintCode($3.codeString, $3.typeString, false);
        }

        if ($3.processString != NULL) {
            $$ = new char[strlen($3.processString) + strlen(printStatement) + 2];
            sprintf($$, "%s\n%s", $3.processString, printStatement);
        } else {
            $$ = new char[strlen(printStatement) + 1];
            sprintf($$, "%s", printStatement);
        }
    }
    | expression '=' expression ';'
    {
        $$ = handleAssignment($1.codeString, $1.typeString, $3.codeString, $3.typeString);
    }
    | expression '=' '{' expression_list '}' ';'
    {
        $$ = handleArrayInitialization($1.codeString, $1.typeString, $4.codeString, $4.length);
    }
    | IF '(' expression ')' '{' statements '}' %prec UMINUS
    {
        // 構造if語句
        char* ifStatement = new char[strlen($3.codeString) + strlen($6) + 20];
        sprintf(ifStatement, "if (%s) {\n%s}\n", $3.codeString, $6);
        $$ = ifStatement;
    }
    | IF '(' expression ')' '{' statements '}' ELSE '{' statements '}' %prec UMINUS
    {
        // 構造if-else語句
        char* ifElseStatement = new char[strlen($3.codeString) + strlen($6) + strlen($10) + 30];
        sprintf(ifElseStatement, "if (%s) {\n%s} else {\n%s}\n", $3.codeString, $6, $10);
        $$ = ifElseStatement;
    }
    | WHILE '(' expression ')' '{' statements '}'
    {
        // 構造while語句
        char* whileStatement = new char[strlen($3.codeString) + strlen($6) + 20];
        sprintf(whileStatement, "while (%s) {\n%s}\n", $3.codeString, $6);
        $$ = whileStatement;
    }
    | IDENTIFIER '(' ')' ';'
    {
        // 標識符函數調用
        $$ = new char[strlen($1) + 5];
        sprintf($$, "%s();\n", $1);
    }
;

type:
    BOOL { $$ = new char[strlen("bool") + 1]; strcpy($$, "bool"); }
    | CHAR { $$ = new char[strlen("char") + 1]; strcpy($$, "char"); }
    | INT { $$ = new char[strlen("int") + 1]; strcpy($$, "int"); }
    | REAL { $$ = new char[strlen("double") + 1]; strcpy($$, "double"); }
    | STRING { $$ = new char[strlen("string") + 1]; strcpy($$, "string"); }
;

declaration:
    VAR IDENTIFIER ':' type ';'
    {
        // 檢查變量是否已經聲明
        auto iter = symbolMap.find($2);
        if (iter != symbolMap.end()) {
            char* errorMessage = new char[strlen($2) + 30];
            sprintf(errorMessage, "變數 %s 已經被聲明", $2);
            yyerror(errorMessage);
            YYERROR;
        }

        if (strcmp($4, "string") == 0) { 
            yyerror("字符串變量必須初始化");
            YYERROR;
        }

        symbolMap[$2] = { $4, -1 };
        $$ = new char[strlen($2) + strlen($4) + 10];
        sprintf($$, "%s %s;\n", $4, $2);
    }
    | VAR IDENTIFIER ':' type '=' expression ';'
    {
        // 檢查變量是否已經聲明
        auto iter = symbolMap.find($2);
        if (iter != symbolMap.end()) {
            char* errorMessage = new char[strlen($2) + 30];
            sprintf(errorMessage, "變數 %s 已經被聲明", $2);
            yyerror(errorMessage);
            YYERROR;
        }

        symbolMap[$2] = { $4, -1 };

        if (strcmp($4, "string") == 0) {
            $$ = new char[strlen($2) + strlen($6.codeString) + 15];
            sprintf($$, "char %s[] = %s;\n", $2, $6.codeString);
        } else {
            $$ = new char[strlen($2) + strlen($4) + strlen($6.codeString) + 15];
            sprintf($$, "%s %s = %s;\n", $4, $2, $6.codeString);
        }
    }
    | VAR IDENTIFIER ':' type '[' INTEGER_LITERAL ']' ';'
    {
        // 檢查變量是否已經聲明
        auto iter = symbolMap.find($2);
        if (iter != symbolMap.end()) {
            char* errorMessage = new char[strlen($2) + 30];
            sprintf(errorMessage, "變數 %s 已經被聲明", $2);
            yyerror(errorMessage);
            YYERROR;
        }

        // 將變量插入符號表，帶有數組信息
        symbolMap[$2] = { $4, $6 };
        $$ = new char[strlen($2) + strlen($4) + 40];
        sprintf($$, "%s %s[%d];\n", $4, $2, $6);
    }
    | VAR IDENTIFIER ':' type '[' INTEGER_LITERAL ']' '=' '{' expression_list '}' ';'
    {
        // 檢查變量是否已經聲明
        auto iter = symbolMap.find($2);
        if (iter != symbolMap.end()) {
            char* errorMessage = new char[strlen($2) + 30];
            sprintf(errorMessage, "變數 %s 已經被聲明", $2);
            yyerror(errorMessage);
            YYERROR;
        }

        if ($6 < $10.length) {
            char* errorMessage = new char[strlen($2) + 30];
            sprintf(errorMessage, "對於 %s 元素太多", $2);
            yyerror(errorMessage);
            YYERROR;
        }
        // 將變量插入符號表，帶有數組信息
        symbolMap[$2] = { $4, $6 };
        $$ = new char[strlen($2) + strlen($4) + strlen($10.codeString) + 40];
        sprintf($$, "%s %s[%d] = {%s};\n", $4, $2, $6, $10.codeString);
    }
;

expression_list:
    expression
    {
        // 單個表達式
        $$.codeString = new char[strlen($1.codeString) + 1];
        sprintf($$.codeString, "%s", $1.codeString);
        $$.length = 1;  // 初始化長度為1
    }
    | expression_list ',' expression
    {
        // 表達式列表
        $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 4];
        sprintf($$.codeString, "%s, %s", $1.codeString, $3.codeString);
        $$.length = $1.length + 1;  // 更新列表長度
    }
;

expression:
    IDENTIFIER
    {
        // 變量標識符
        $$.codeString = new char[strlen($1) + 1];
        strcpy($$.codeString, $1);

        // 在符號表中查找變量
        auto iter = symbolMap.find($1);
        if (iter != symbolMap.end()) {
            const VInfo &varInfo = iter->second;
            $$.typeString = new char[varInfo.type.length() + 1];
            strcpy($$.typeString, varInfo.type.c_str());
        } else {
            // 變量未聲明錯誤
            char* errorMessage = new char[strlen($1) + 20];
            sprintf(errorMessage, "未聲明的變量 %s", $1);
            yyerror(errorMessage);
            YYERROR;
        }
    }
    | IDENTIFIER '[' expression ']'
    {
        // 數組變量標識符
        $$.codeString = new char[strlen($1) + strlen($3.codeString) + 4];
        sprintf($$.codeString, "%s[%s]", $1, $3.codeString);

        // 在符號表中查找變量
        auto iter = symbolMap.find($1);
        if (iter != symbolMap.end()) {
            const VInfo &varInfo = iter->second;
            $$.typeString = new char[varInfo.type.length() + 1];
            strcpy($$.typeString, varInfo.type.c_str());
        } else {
            // 變量未聲明錯誤
            char* errorMessage = new char[strlen($1) + 20];
            sprintf(errorMessage, "未聲明的變量 %s", $1);
            yyerror(errorMessage);
            YYERROR;
        }
    }
    | TRUE
    {
        $$.codeString = new char[6];
        strcpy($$.codeString, "true");
        $$.typeString = new char[5];
        strcpy($$.typeString, "bool");
    }
    | FALSE
    {
        $$.codeString = new char[6];
        strcpy($$.codeString, "false");
        $$.typeString = new char[5];
        strcpy($$.typeString, "bool");
    }
    | INTEGER_LITERAL
    {
        $$.codeString = new char[20];
        sprintf($$.codeString, "%d", $1);
        $$.typeString = new char[4];
        strcpy($$.typeString, "int");
    }
    | REAL_LITERAL
    {
        $$.codeString = new char[30];
        sprintf($$.codeString, "%.20f", $1);
        $$.typeString = new char[7];
        strcpy($$.typeString, "double");
    }
    | CHAR_LITERAL
    {
        $$.codeString = new char[4];
        sprintf($$.codeString, "'%c'", $1);
        $$.typeString = new char[5];
        strcpy($$.typeString, "char");
    }
    | STRING_LITERAL
    {
        $$.codeString = new char[strlen($1) + 1];
        strcpy($$.codeString, $1);
        $$.typeString = new char[7];
        strcpy($$.typeString, "string");
    }
    | expression EQ expression
    {
        $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 5];
        sprintf($$.codeString, "%s == %s", $1.codeString, $3.codeString);
        $$.typeString = new char[5];
        strcpy($$.typeString, "bool");
    }
    | expression NE expression
    {
        $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 5];
        sprintf($$.codeString, "%s != %s", $1.codeString, $3.codeString);
        $$.typeString = new char[5];
        strcpy($$.typeString, "bool");
    }
    | expression LE expression
    {
        $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 5];
        sprintf($$.codeString, "%s <= %s", $1.codeString, $3.codeString);
        $$.typeString = new char[5];
        strcpy($$.typeString, "bool");
    }
    | expression GE expression
    {
        $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 5];
        sprintf($$.codeString, "%s >= %s", $1.codeString, $3.codeString);
        $$.typeString = new char[5];
        strcpy($$.typeString, "bool");
    }
    | expression '<' expression
    {
        $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 4];
        sprintf($$.codeString, "%s < %s", $1.codeString, $3.codeString);
        $$.typeString = new char[5];
        strcpy($$.typeString, "bool");
    }
    | expression '>' expression
    {
        $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 4];
        sprintf($$.codeString, "%s > %s", $1.codeString, $3.codeString);
        $$.typeString = new char[5];
        strcpy($$.typeString, "bool");
    }
    
    | expression '^' expression
    {
        // 內積計算
        auto iter1 = symbolMap.find($1.codeString);
        auto iter2 = symbolMap.find($3.codeString);
        if (iter1 != symbolMap.end() && iter2 != symbolMap.end() && iter1->second.length > 0 && iter2->second.length > 0) {
            if (strcmp($1.typeString, $3.typeString) == 0 && iter1->second.length == iter2->second.length) {
                int vecLength = symbolMap[$1.codeString].length;
                char* tempVar = new char[10];
                sprintf(tempVar, "tmp%d", tmpCounter);
                char* innerProductCode = new char[200];
                if (!i_flag) {
                    i_flag = true;
                    sprintf(innerProductCode, "int i;\n%s %s = 0;\nfor (i = 0; i < %d; i++) %s += %s[i] * %s[i];", $1.typeString, tempVar, vecLength, tempVar, $1.codeString, $3.codeString);
                } else {
                    sprintf(innerProductCode, "%s %s = 0;\nfor (i = 0; i < %d; i++) %s += %s[i] * %s[i];", $1.typeString, tempVar, vecLength, tempVar, $1.codeString, $3.codeString);
                }
                tmpCounter++;

                $$.codeString = new char[strlen(tempVar) + 1];
                strcpy($$.codeString, tempVar);
                $$.typeString = new char[strlen($1.typeString) + 1];
                strcpy($$.typeString, $1.typeString);
                $$.processString = new char[strlen(innerProductCode) + 1];
                strcpy($$.processString, innerProductCode);
            } else {
                yyerror("向量加法類型或長度不匹配");
                YYERROR;
            }
        } else {
            yyerror("內積運算對象不是數組");
            YYERROR;
        }
    }
    | expression '+' expression
    {
        // 向量加法
        auto iter1 = symbolMap.find($1.codeString);
        auto iter2 = symbolMap.find($3.codeString);
        if (iter1 != symbolMap.end() && iter2 != symbolMap.end() && iter1->second.length > 0 && iter2->second.length > 0) {
            if (strcmp($1.typeString, $3.typeString) == 0 && iter1->second.length == iter2->second.length) {
                int vecLength = iter1->second.length;
                char* tempVar = new char[20];
                sprintf(tempVar, "tmp_arr%d", tmpCounter);
                tmpCounter++;

                // 生成加法的過程代碼
                char* additionProcess = new char[300 + 20 * vecLength];
                if (!i_flag) {
                    i_flag = true;
                    sprintf(additionProcess, "int i;\n%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] + %s[i];", $1.typeString, tempVar, vecLength, vecLength, tempVar, $1.codeString, $3.codeString);
                } else {
                    sprintf(additionProcess, "%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] + %s[i];", $1.typeString, tempVar, vecLength, vecLength, tempVar, $1.codeString, $3.codeString);
                }

                // 將臨時數組添加到符號表
                symbolMap[tempVar] = { $1.typeString, vecLength };

                $$.codeString = new char[strlen(tempVar) + 1];
                strcpy($$.codeString, tempVar);
                $$.typeString = new char[strlen($1.typeString) + 1];
                strcpy($$.typeString, $1.typeString);
                $$.processString = new char[strlen(additionProcess) + 1];
                strcpy($$.processString, additionProcess);
            } else {
                yyerror("向量加法類型或長度不匹配");
                YYERROR;
            }
        } else {
            // 標量加法
            $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 4];
            sprintf($$.codeString, "%s + %s", $1.codeString, $3.codeString);

            // 類型檢查邏輯來確定結果類型
            if (strcmp($1.typeString, "int") == 0 && strcmp($3.typeString, "int") == 0) {
                $$.typeString = new char[4];
                strcpy($$.typeString, "int");
            } else if ((strcmp($1.typeString, "int") == 0 || strcmp($1.typeString, "double") == 0) && (strcmp($3.typeString, "int") == 0 || strcmp($3.typeString, "double") == 0)) {
                $$.typeString = new char[7];
                strcpy($$.typeString, "double");
            }
        }
    }
    | expression '-' expression
    {
        // 向量減法
        auto iter1 = symbolMap.find($1.codeString);
        auto iter2 = symbolMap.find($3.codeString);
        if (iter1 != symbolMap.end() && iter2 != symbolMap.end() && iter1->second.length > 0 && iter2->second.length > 0) {
            if (strcmp($1.typeString, $3.typeString) == 0 && iter1->second.length == iter2->second.length) {
                int vecLength = iter1->second.length;
                char* tempVar = new char[20];
                sprintf(tempVar, "tmp_arr%d", tmpCounter);
                tmpCounter++;

                // 生成減法的過程代碼
                char* subtractionProcess = new char[300 + 20 * vecLength];
                if (!i_flag) {
                    i_flag = true;
                    sprintf(subtractionProcess, "int i;\n%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] - %s[i];", $1.typeString, tempVar, vecLength, vecLength, tempVar, $1.codeString, $3.codeString);
                } else {
                    sprintf(subtractionProcess, "%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] - %s[i];", $1.typeString, tempVar, vecLength, vecLength, tempVar, $1.codeString, $3.codeString);
                }

                // 將臨時數組添加到符號表
                symbolMap[tempVar] = { $1.typeString, vecLength };

                $$.codeString = new char[strlen(tempVar) + 1];
                strcpy($$.codeString, tempVar);
                $$.typeString = new char[strlen($1.typeString) + 1];
                strcpy($$.typeString, $1.typeString);
                $$.processString = new char[strlen(subtractionProcess) + 1];
                strcpy($$.processString, subtractionProcess);
            } else {
                yyerror("向量減法類型或長度不匹配");
                YYERROR;
            }
        } else {
            // 標量減法
            $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 4];
            sprintf($$.codeString, "%s - %s", $1.codeString, $3.codeString);

            // 類型檢查邏輯來確定結果類型
            if (strcmp($1.typeString, "int") == 0 && strcmp($3.typeString, "int") == 0) {
                $$.typeString = new char[4];
                strcpy($$.typeString, "int");
            } else if ((strcmp($1.typeString, "int") == 0 || strcmp($1.typeString, "double") == 0) && (strcmp($3.typeString, "int") == 0 || strcmp($3.typeString, "double") == 0)) {
                $$.typeString = new char[7];
                strcpy($$.typeString, "double");
            }
        }
    }
    | expression '*' expression
    {
        // 向量乘法
        auto iter1 = symbolMap.find($1.codeString);
        auto iter2 = symbolMap.find($3.codeString);
        if (iter1 != symbolMap.end() && iter2 != symbolMap.end() && iter1->second.length > 0 && iter2->second.length > 0) {
            if (strcmp($1.typeString, $3.typeString) == 0 && iter1->second.length == iter2->second.length) {
                int vecLength = iter1->second.length;
                char* tempVar = new char[20];
                sprintf(tempVar, "tmp_arr%d", tmpCounter);
                tmpCounter++;

                // 生成乘法的過程代碼
                char* multiplicationProcess = new char[300 + 20 * vecLength];
                if (!i_flag) {
                    i_flag = true;
                    sprintf(multiplicationProcess, "int i;\n%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] * %s[i];", $1.typeString, tempVar, vecLength, vecLength, tempVar, $1.codeString, $3.codeString);
                } else {
                    sprintf(multiplicationProcess, "%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] * %s[i];", $1.typeString, tempVar, vecLength, vecLength, tempVar, $1.codeString, $3.codeString);
                }

                // 將臨時數組添加到符號表
                symbolMap[tempVar] = { $1.typeString, vecLength };

                $$.codeString = new char[strlen(tempVar) + 1];
                strcpy($$.codeString, tempVar);
                $$.typeString = new char[strlen($1.typeString) + 1];
                strcpy($$.typeString, $1.typeString);
                $$.processString = new char[strlen(multiplicationProcess) + 1];
                strcpy($$.processString, multiplicationProcess);
            } else {
                yyerror("向量乘法類型或長度不匹配");
                YYERROR;
            }
        } else {
            // 標量乘法
            $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 4];
            sprintf($$.codeString, "%s * %s", $1.codeString, $3.codeString);

            // 類型檢查邏輯來確定結果類型
            if (strcmp($1.typeString, "int") == 0 && strcmp($3.typeString, "int") == 0) {
                $$.typeString = new char[4];
                strcpy($$.typeString, "int");
            } else if ((strcmp($1.typeString, "int") == 0 || strcmp($1.typeString, "double") == 0) && (strcmp($3.typeString, "int") == 0 || strcmp($3.typeString, "double") == 0)) {
                $$.typeString = new char[7];
                strcpy($$.typeString, "double");
            }
        }
    }
    | expression '/' expression
    {
        // 向量除法
        auto iter1 = symbolMap.find($1.codeString);
        auto iter2 = symbolMap.find($3.codeString);
        if (iter1 != symbolMap.end() && iter2 != symbolMap.end() && iter1->second.length > 0 && iter2->second.length > 0) {
            if (strcmp($1.typeString, $3.typeString) == 0 && iter1->second.length == iter2->second.length) {
                int vecLength = iter1->second.length;
                char* tempVar = new char[20];
                sprintf(tempVar, "tmp_arr%d", tmpCounter);
                tmpCounter++;

                // 生成除法的過程代碼
                char* divisionProcess = new char[300 + 20 * vecLength];
                if (!i_flag) {
                    i_flag = true;
                    sprintf(divisionProcess, "int i;\n%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] / %s[i];", $1.typeString, tempVar, vecLength, vecLength, tempVar, $1.codeString, $3.codeString);
                } else {
                    sprintf(divisionProcess, "%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] / %s[i];", $1.typeString, tempVar, vecLength, vecLength, tempVar, $1.codeString, $3.codeString);
                }

                // 將臨時數組添加到符號表
                symbolMap[tempVar] = { $1.typeString, vecLength };

                $$.codeString = new char[strlen(tempVar) + 1];
                strcpy($$.codeString, tempVar);
                $$.typeString = new char[strlen($1.typeString) + 1];
                strcpy($$.typeString, $1.typeString);
                $$.processString = new char[strlen(divisionProcess) + 1];
                strcpy($$.processString, divisionProcess);
            } else {
                yyerror("向量除法類型或長度不匹配");
                YYERROR;
            }
        } else {
            // 標量除法
            if ($3.codeString[0] == '0') {
                yyerror("除以零錯誤");
                YYERROR;
            }
            $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 4];
            sprintf($$.codeString, "%s / %s", $1.codeString, $3.codeString);

            // 類型檢查邏輯來確定結果類型
            if (strcmp($1.typeString, "int") == 0 && strcmp($3.typeString, "int") == 0) {
                $$.typeString = new char[4];
                strcpy($$.typeString, "int");
            } else if ((strcmp($1.typeString, "int") == 0 || strcmp($1.typeString, "double") == 0) && (strcmp($3.typeString, "int") == 0 || strcmp($3.typeString, "double") == 0)) {
                $$.typeString = new char[7];
                strcpy($$.typeString, "double");
            }
        }
    }
    | '-' expression %prec UMINUS
    {
        $$.codeString = new char[strlen($2.codeString) + 2];
        sprintf($$.codeString, "-%s", $2.codeString);
        $$.typeString = new char[strlen($2.typeString) + 1];
        strcpy($$.typeString, $2.typeString);
    }
    | '(' expression ')'
    {
        $$.codeString = new char[strlen($2.codeString) + 3];
        sprintf($$.codeString, "(%s)", $2.codeString);
        $$.typeString = new char[strlen($2.typeString) + 1];
        strcpy($$.typeString, $2.typeString);
    }
;

%%

extern FILE* yyin;
void yyerror(const char *s) {
    fprintf(stderr, "Error : %s\n", s);
    fprintf(outputFile, "// Error : %s\n", s);
}

int main(int argc, char *argv[]) {
    char *inputFileName;
    if (argc > 1) {
        FILE *inputFile = fopen(argv[1], "r");  // 打開輸入檔案
        inputFileName = argv[1];
        if (!inputFile) {
            perror(argv[1]);  // 如果無法打開輸入檔案，輸出錯誤訊息
            return 1;
        }
        yyin = inputFile;
    } else {
        cout << "沒有輸入檔案" << endl;  // 如果沒有提供輸入檔案，輸出錯誤訊息
        return 1;
    }

    const char *prefix = "out_";  // 設定輸出檔案的前綴字串
    const char *postfix = ".c";  // 設定輸出檔案的後綴字串
    size_t prefixLength = strlen(prefix);
    size_t inputFileNameLength = strlen(inputFileName);
    size_t postfixLength = strlen(postfix);
    size_t outputFileNameLength = prefixLength + inputFileNameLength + postfixLength + 1;

    char* outputFileName = (char *)malloc(outputFileNameLength * sizeof(char));  // 為輸出檔案名稱分配記憶體
    strcpy(outputFileName, prefix);
    strcat(outputFileName, inputFileName);  // 組合輸出檔案名稱
    strcat(outputFileName, postfix);  // 添加後綴字串
    outputFile = fopen(outputFileName, "w");  // 打開輸出檔案
    if (!outputFile) {
        perror(outputFileName);  // 如果無法打開輸出檔案，輸出錯誤訊息
        exit(1);
    }
    free(outputFileName);  // 釋放分配的記憶體

    return yyparse();  // 開始解析
}