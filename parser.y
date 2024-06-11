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
std::map<std::string, VInfo> symbol_table;

int tmpCounter = 0;
bool i_flag = false;
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

%type <expressionValue> expr
%type <expressionListValue> expr_list

%type <string> function
%type <string> statements
%type <string> variable_declaration
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
        fprintf(outputFile, "#include <stdio.h>\n#include <stdlib.h>\n#include <stdbool.h>\n\n%s\n", $1);
        fclose(outputFile);
    }
;

function:
    FUN IDENTIFIER '(' ')' '{' statements '}' 
    {
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
    variable_declaration
    {
        $$ = new char[strlen($1) + 1];
        strcpy($$, $1);
    }
    | PRINTLN '(' expr ')' ';'
    {
        char* print_stmt;
        auto it = symbol_table.find($3.codeString);
        if (it != symbol_table.end() && it->second.length > 0) {
            // Array printing logic
            int length = it->second.length;
            print_stmt = new char[200];
            char* for_loop = new char[200];
            if (!i_flag) {
                i_flag = true;
                sprintf(for_loop, "int i;\nprintf(\"{\");\nfor (i = 0; i < %d; ++i) {\n    if (i != 0) printf(\", \");\n    printf(\"", length);
            } else {
                sprintf(for_loop, "printf(\"{\");\nfor (i = 0; i < %d; ++i) {\n    if (i != 0) printf(\", \");\n    printf(\"", length);
            }

            if (strcmp($3.typeString, "int") == 0) {
                strcat(for_loop, "%%d\", %s[i]);\n}\nprintf(\"}\\n\");\n");
            } else if (strcmp($3.typeString, "double") == 0) {
                strcat(for_loop, "%%f\", %s[i]);\n}\nprintf(\"}\\n\");\n");
            } else if (strcmp($3.typeString, "char") == 0) {
                strcat(for_loop, "%%c\", %s[i]);\n}\nprintf(\"}\\n\");\n");
            } else {
                strcat(for_loop, "%%s\", %s[i]);\n}\nprintf(\"}\\n\");\n");
            }

            print_stmt = new char[strlen(for_loop) + strlen($3.codeString) * 2 + 1];
            sprintf(print_stmt, for_loop, $3.codeString, $3.codeString);
        } else {
             // Scalar printing logic
            print_stmt = new char[strlen($3.codeString) + 50];
            if (strcmp($3.typeString, "int") == 0) {
                sprintf(print_stmt, "printf(\"%%d\\n\", %s);\n", $3.codeString);
            } else if (strcmp($3.typeString, "double") == 0) {
                sprintf(print_stmt, "printf(\"%%f\\n\", %s);\n", $3.codeString);
            } else if (strcmp($3.typeString, "char") == 0) {
                sprintf(print_stmt, "printf(\"%%c\\n\", %s);\n", $3.codeString);
            } else if (strcmp($3.typeString, "string") == 0) {
                sprintf(print_stmt, "printf(\"%%s\\n\", %s);\n", $3.codeString);
            } else {
                sprintf(print_stmt, "printf(\"%%s\\n\", %s);\n", $3.codeString);
            }
        }

        if ($3.processString != NULL) {
            $$ = new char[strlen($3.processString) + strlen(print_stmt) + 2];
            sprintf($$, "%s\n%s", $3.processString, print_stmt);
        } else {
            $$ = new char[strlen(print_stmt) + 1];
            sprintf($$, "%s", print_stmt);
        }
    }
    | PRINT '(' expr ')' ';'
    {
        char* print_stmt;
        auto it = symbol_table.find($3.codeString);
        if (it != symbol_table.end() && it->second.length > 0) {
            // Array printing logic
            int length = it->second.length;
            print_stmt = new char[200];
            char* for_loop = new char[200];
            if (!i_flag) {
                i_flag = true;
                sprintf(for_loop, "int i;\nprintf(\"{\");\nfor (i = 0; i < %d; ++i) {\n    if (i != 0) printf(\", \");\n    printf(\"", length);
            } else {
                sprintf(for_loop, "printf(\"{\");\nfor (i = 0; i < %d; ++i) {\n    if (i != 0) printf(\", \");\n    printf(\"", length);
            }

            if (strcmp($3.typeString, "int") == 0) {
                strcat(for_loop, "%%d\", %s[i]);\n}\nprintf(\"}\");\n");
            } else if (strcmp($3.typeString, "double") == 0) {
                strcat(for_loop, "%%f\", %s[i]);\n}\nprintf(\"}\");\n");
            } else if (strcmp($3.typeString, "char") == 0) {
                strcat(for_loop, "%%c\", %s[i]);\n}\nprintf(\"}\");\n");
            } else {
                strcat(for_loop, "%%s\", %s[i]);\n}\nprintf(\"}\");\n");
            }

            print_stmt = new char[strlen(for_loop) + strlen($3.codeString) * 2 + 1];
            sprintf(print_stmt, for_loop, $3.codeString, $3.codeString);
        } else {
             // Scalar printing logic
            print_stmt = new char[strlen($3.codeString) + 50];
            if (strcmp($3.typeString, "int") == 0) {
                sprintf(print_stmt, "printf(\"%%d\", %s);\n", $3.codeString);
            } else if (strcmp($3.typeString, "double") == 0) {
                sprintf(print_stmt, "printf(\"%%f\", %s);\n", $3.codeString);
            } else if (strcmp($3.typeString, "char") == 0) {
                sprintf(print_stmt, "printf(\"%%c\", %s);\n", $3.codeString);
            } else if (strcmp($3.typeString, "string") == 0) {
                sprintf(print_stmt, "printf(\"%%s\", %s);\n", $3.codeString);
            } else {
                sprintf(print_stmt, "printf(\"%%s\", %s);\n", $3.codeString);
            }
        }

        if ($3.processString != NULL) {
            $$ = new char[strlen($3.processString) + strlen(print_stmt) + 2];
            sprintf($$, "%s\n%s", $3.processString, print_stmt);
        } else {
            $$ = new char[strlen(print_stmt) + 1];
            sprintf($$, "%s", print_stmt);
        }
    }
    | expr '=' expr ';'
    {
        auto it1 = symbol_table.find($1.codeString);
        auto it2 = symbol_table.find($3.codeString);

        if (it1 != symbol_table.end() && it1->second.length > 0) { // The left-hand side is an array
            if (it2 != symbol_table.end() && it2->second.length > 0) { // The right-hand side is also an array
                if (strcmp($1.typeString, $3.typeString) == 0 && it1->second.length == it2->second.length) {
                    // Arrays match in type and size
                    char* process = new char[300];
                    sprintf(process, "for (int i = 0; i < %d; ++i) %s[i] = %s[i];\n", it1->second.length, $1.codeString, $3.codeString);
                    $$ = new char[strlen(process) + 1];
                    strcpy($$, process);
                } else {
                    yyerror("Mismatched types or lengths in array assignment");
                    YYABORT;
                }
            } else {
                yyerror("Right-hand side must be an array in array assignment");
                YYABORT;
            }
        } else {
            // Scalar assignment
            $$ = new char[strlen($1.codeString) + strlen($3.codeString) + 5];
            sprintf($$, "%s = %s;\n", $1.codeString, $3.codeString);
        }
    }
    | expr '=' '{' expr_list '}' ';'
    {
        auto it = symbol_table.find($1.codeString);
        if (it != symbol_table.end() && it->second.length > 0) { // The left-hand side is an array
            if (it->second.length >= $4.length) { // The initializer list fits in the array
                char* temp = new char[20];
                sprintf(temp, "tmp_arr%d", tmpCounter);
                tmpCounter++;
                char* declare_temp = new char[30];
                char* process = new char[300 + strlen($4.codeString)];
                sprintf(declare_temp, "%s %s[%d] = {%s};\n", $1.typeString, temp, it->second.length, $4.codeString);
                sprintf(process, "for (int i = 0; i < %d; ++i) %s[i] = %s[i];\n", it->second.length, $1.codeString, temp);
                $$ = new char[strlen(declare_temp) + strlen(process) + 1];
                sprintf($$, "%s%s", declare_temp, process);
            } else {
                yyerror("Initializer list too long for array");
                YYABORT;
            }
        } else {
            yyerror("Left-hand side must be an array in array assignment");
            YYABORT;
        }
    }
    | IF '(' expr ')' '{' statements '}' %prec UMINUS
    {
        char* if_stmt = new char[strlen($3.codeString) + strlen($6) + 20];
        sprintf(if_stmt, "if (%s) {\n%s}\n", $3.codeString, $6);
        $$ = if_stmt;
    }
    | IF '(' expr ')' '{' statements '}' ELSE '{' statements '}' %prec UMINUS
    {
        char* if_else_stmt = new char[strlen($3.codeString) + strlen($6) + strlen($10) + 30];
        sprintf(if_else_stmt, "if (%s) {\n%s} else {\n%s}\n", $3.codeString, $6, $10);
        $$ = if_else_stmt;
    }
    | WHILE '(' expr ')' '{' statements '}'
    {
        char* while_stmt = new char[strlen($3.codeString) + strlen($6) + 20];
        sprintf(while_stmt, "while (%s) {\n%s}\n", $3.codeString, $6);
        $$ = while_stmt;
    }
    | IDENTIFIER '(' ')' ';'
    {
        $$ = new char[strlen($1) + 5];
        sprintf($$, "%s();\n", $1);
    }
    | RET ';'
    {
        $$ = new char[8];
        strcpy($$, "return;\n");
    }
;



variable_declaration:
    VAR IDENTIFIER ':' type ';'
    {
        // Check if the variable has already been declared
        auto it = symbol_table.find($2);
        if (it != symbol_table.end()) {
            char* error = new char[strlen($2) + 30];
            sprintf(error, "Variable %s already declared", $2);
            yyerror(error);
            YYABORT;
        }

        if (strcmp($4, "string") == 0) { 
            yyerror("String variables must be initialized");
            YYABORT;
        }

        symbol_table[$2] = { $4, -1 };
        $$ = new char[strlen($2) + strlen($4) + 10];
        sprintf($$, "%s %s;\n", $4, $2);
    }
    | VAR IDENTIFIER ':' type '=' expr ';'
    {
        // Check if the variable has already been declared
        auto it = symbol_table.find($2);
        if (it != symbol_table.end()) {
            char* error = new char[strlen($2) + 30];
            sprintf(error, "Variable %s already declared", $2);
            yyerror(error);
            YYABORT;
        }

        symbol_table[$2] = { $4, -1 };

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
        // Check if the variable has already been declared
        auto it = symbol_table.find($2);
        if (it != symbol_table.end()) {
            char* error = new char[strlen($2) + 30];
            sprintf(error, "Variable %s already declared", $2);
            yyerror(error);
            YYABORT;
        }

        // Insert into symbol table with vector info
        symbol_table[$2] = { $4, $6 };
        $$ = new char[strlen($2) + strlen($4) + 40];
        sprintf($$, "%s %s[%d];\n", $4, $2, $6);
    }
    | VAR IDENTIFIER ':' type '[' INTEGER_LITERAL ']' '=' '{' expr_list '}' ';'
    {
        // Check if the variable has already been declared
        auto it = symbol_table.find($2);
        if (it != symbol_table.end()) {
            char* error = new char[strlen($2) + 30];
            sprintf(error, "Variable %s already declared", $2);
            yyerror(error);
            YYABORT;
        }

        if ($6 < $10.length) {
            char* error = new char[strlen($2) + 30];
            sprintf(error, "Too many elements for %s", $2);
            yyerror(error);
            YYABORT;
        }
        // Insert into symbol table with vector info
        symbol_table[$2] = { $4, $6 };
        $$ = new char[strlen($2) + strlen($4) + strlen($10.codeString) + strlen($10.codeString) + 40];
        sprintf($$, "%s %s[%d] = {%s};\n", $4, $2, $6, $10.codeString);
    }
;

type:
    BOOL { $$ = new char[strlen("bool") + 1]; strcpy($$, "bool"); }
    | CHAR { $$ = new char[strlen("char") + 1]; strcpy($$, "char"); }
    | INT { $$ = new char[strlen("int") + 1]; strcpy($$, "int"); }
    | REAL { $$ = new char[strlen("double") + 1]; strcpy($$, "double"); }
    | STRING { $$ = new char[strlen("string") + 1]; strcpy($$, "string"); }
;

expr_list:
    expr
    {
        $$.codeString = new char[strlen($1.codeString) + 1];
        sprintf($$.codeString, "%s", $1.codeString);
        $$.length = 1;
    }
    | expr_list ',' expr
    {
        $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 4];
        sprintf($$.codeString, "%s, %s", $1.codeString, $3.codeString);
        $$.length = $1.length + 1;
    }
;

expr:
    INTEGER_LITERAL
    {
        $$.codeString = new char[20];
        sprintf($$.codeString, "%d", $1);
        $$.typeString = new char[4];
        strcpy($$.typeString, "int");
    }
    | REAL_LITERAL
    {
        $$.codeString = new char[30];
        sprintf($$.codeString, "%.17f", $1);
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
    | expr '<' expr
    {
        $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 4];
        sprintf($$.codeString, "%s < %s", $1.codeString, $3.codeString);
        $$.typeString = new char[5];
        strcpy($$.typeString, "bool");
    }
    | expr '>' expr
    {
        $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 4];
        sprintf($$.codeString, "%s > %s", $1.codeString, $3.codeString);
        $$.typeString = new char[5];
        strcpy($$.typeString, "bool");
    }
    | expr EQ expr
    {
        $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 5];
        sprintf($$.codeString, "%s == %s", $1.codeString, $3.codeString);
        $$.typeString = new char[5];
        strcpy($$.typeString, "bool");
    }
    | expr NE expr
    {
        $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 5];
        sprintf($$.codeString, "%s != %s", $1.codeString, $3.codeString);
        $$.typeString = new char[5];
        strcpy($$.typeString, "bool");
    }
    | expr LE expr
    {
        $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 5];
        sprintf($$.codeString, "%s <= %s", $1.codeString, $3.codeString);
        $$.typeString = new char[5];
        strcpy($$.typeString, "bool");
    }
    | expr GE expr
    {
        $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 5];
        sprintf($$.codeString, "%s >= %s", $1.codeString, $3.codeString);
        $$.typeString = new char[5];
        strcpy($$.typeString, "bool");
    }
    | IDENTIFIER
    {
        $$.codeString = new char[strlen($1) + 1];
        strcpy($$.codeString, $1);
        auto it = symbol_table.find($1);
        if (it != symbol_table.end()) {
            const VInfo &vec_info = it->second;
            $$.typeString = new char[vec_info.type.length() + 1];
            strcpy($$.typeString, vec_info.type.c_str());
        } else {
            char* error = new char[strlen($1) + 20];
            sprintf(error, "Undeclared variable %s", $1);
            yyerror(error);
            YYABORT;
        }
    }
    | IDENTIFIER '[' expr ']'
    {
        $$.codeString = new char[strlen($1) + strlen($3.codeString) + 4];
        sprintf($$.codeString, "%s[%s]", $1, $3.codeString);

        auto it = symbol_table.find($1);
        if (it != symbol_table.end()) {
            const VInfo &vec_info = it->second;
            $$.typeString = new char[vec_info.type.length() + 1];
            strcpy($$.typeString, vec_info.type.c_str());
        } else {
            char* error = new char[strlen($1) + 20];
            sprintf(error, "Undeclared variable %s", $1);
            yyerror(error);
            YYABORT;
        }
    }
    | expr '^' expr
    {
        // Inner product
        auto it1 = symbol_table.find($1.codeString);
        auto it2 = symbol_table.find($3.codeString);
        if (it1 != symbol_table.end() && it2 != symbol_table.end() && it1->second.length > 0 && it2->second.length > 0) {
            if (strcmp($1.typeString, $3.typeString) == 0 && it1->second.length == it2->second.length) {
                int length = symbol_table[$1.codeString].length;
                char* temp = new char[10];
                sprintf(temp, "tmp%d", tmpCounter);
                char* process = new char[200];
                if (!i_flag) {
                    i_flag = true;
                    sprintf(process, "int i;\n%s %s = 0;\nfor (i = 0; i < %d; i++) %s += %s[i] * %s[i];", $1.typeString, temp, length, temp, $1.codeString, $3.codeString);
                } else {
                    sprintf(process, "%s %s = 0;\nfor (i = 0; i < %d; i++) %s += %s[i] * %s[i];", $1.typeString, temp, length, temp, $1.codeString, $3.codeString);
                }
                tmpCounter++;

                $$.codeString = new char[strlen(temp) + 1];
                strcpy($$.codeString, temp);
                $$.typeString = new char[strlen($1.typeString) + 1];
                strcpy($$.typeString, $1.typeString);
                $$.processString = new char[strlen(process) + 1];
                $$.processString = process;
            } else {
                yyerror("Mismatched types or lengths in vector addition");
                YYABORT;
            }
        } else {
            yyerror("Inner product on non-array object");
            YYABORT;
        }
    }
    | expr '+' expr
    {
        auto it1 = symbol_table.find($1.codeString);
        auto it2 = symbol_table.find($3.codeString);
        if (it1 != symbol_table.end() && it2 != symbol_table.end() && it1->second.length > 0 && it2->second.length > 0) {
            if (strcmp($1.typeString, $3.typeString) == 0 && it1->second.length == it2->second.length) {
                int length = it1->second.length;
                char* temp = new char[20];
                sprintf(temp, "tmp_arr%d", tmpCounter);
                tmpCounter++;

                // Generate the addition process codeString
                char* process = new char[300 + 20 * length];
                if (!i_flag) {
                    i_flag = true;
                    sprintf(process, "int i;\n%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] + %s[i];", $1.typeString, temp, length, length, temp, $1.codeString, $3.codeString);
                } else {
                    sprintf(process, "%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] + %s[i];", $1.typeString, temp, length, length, temp, $1.codeString, $3.codeString);
                }

                // Add the temporary array to the symbol table
                symbol_table[temp] = { $1.typeString, length };

                $$.codeString = new char[strlen(temp) + 1];
                strcpy($$.codeString, temp);
                $$.typeString = new char[strlen($1.typeString) + 1];
                strcpy($$.typeString, $1.typeString);
                $$.processString = new char[strlen(process) + 1];
                strcpy($$.processString, process);
            } else {
                yyerror("Mismatched types or lengths in vector addition");
                YYABORT;
            }
            
        } else {
            $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 4];
            sprintf($$.codeString, "%s + %s", $1.codeString, $3.codeString);
            // Type checking logic to determine the result type
            if (strcmp($1.typeString, "int") == 0 && strcmp($3.typeString, "int") == 0) {
                $$.typeString = new char[4];
                strcpy($$.typeString, "int");
            } else if ((strcmp($1.typeString, "int") == 0 || strcmp($1.typeString, "double") == 0) && (strcmp($3.typeString, "int") == 0 || strcmp($3.typeString, "double") == 0)) {
                $$.typeString = new char[7];
                strcpy($$.typeString, "double");
            }
        }
    }

    | expr '-' expr
    {
        auto it1 = symbol_table.find($1.codeString);
        auto it2 = symbol_table.find($3.codeString);
        if (it1 != symbol_table.end() && it2 != symbol_table.end() && it1->second.length > 0 && it2->second.length > 0) {
            if (strcmp($1.typeString, $3.typeString) == 0 && it1->second.length == it2->second.length) {
                int length = it1->second.length;
                char* temp = new char[20];
                sprintf(temp, "tmp_arr%d", tmpCounter);
                tmpCounter++;

                // Generate the addition process codeString
                char* process = new char[300 + 20 * length];
                if (!i_flag) {
                    i_flag = true;
                    sprintf(process, "int i;\n%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] - %s[i];", $1.typeString, temp, length, length, temp, $1.codeString, $3.codeString);
                } else {
                    sprintf(process, "%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] - %s[i];", $1.typeString, temp, length, length, temp, $1.codeString, $3.codeString);
                }

                // Add the temporary array to the symbol table
                symbol_table[temp] = { $1.typeString, length };

                $$.codeString = new char[strlen(temp) + 1];
                strcpy($$.codeString, temp);
                $$.typeString = new char[strlen($1.typeString) + 1];
                strcpy($$.typeString, $1.typeString);
                $$.processString = new char[strlen(process) + 1];
                strcpy($$.processString, process);
            } else {
                yyerror("Mismatched types or lengths in vector addition");
                YYABORT;
            }
            
        } else {
            $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 4];
            sprintf($$.codeString, "%s - %s", $1.codeString, $3.codeString);
            // Type checking logic to determine the result type
            if (strcmp($1.typeString, "int") == 0 && strcmp($3.typeString, "int") == 0) {
                $$.typeString = new char[4];
                strcpy($$.typeString, "int");
            } else if ((strcmp($1.typeString, "int") == 0 || strcmp($1.typeString, "double") == 0) && (strcmp($3.typeString, "int") == 0 || strcmp($3.typeString, "double") == 0)) {
                $$.typeString = new char[7];
                strcpy($$.typeString, "double");
            }
        }
    }
    | expr '*' expr
    {
        auto it1 = symbol_table.find($1.codeString);
        auto it2 = symbol_table.find($3.codeString);
        if (it1 != symbol_table.end() && it2 != symbol_table.end() && it1->second.length > 0 && it2->second.length > 0) {
            if (strcmp($1.typeString, $3.typeString) == 0 && it1->second.length == it2->second.length) {
                int length = it1->second.length;
                char* temp = new char[20];
                sprintf(temp, "tmp_arr%d", tmpCounter);
                tmpCounter++;

                // Generate the addition process codeString
                char* process = new char[300 + 20 * length];
                if (!i_flag) {
                    i_flag = true;
                    sprintf(process, "int i;\n%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] * %s[i];", $1.typeString, temp, length, length, temp, $1.codeString, $3.codeString);
                } else {
                    sprintf(process, "%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] * %s[i];", $1.typeString, temp, length, length, temp, $1.codeString, $3.codeString);
                }

                // Add the temporary array to the symbol table
                symbol_table[temp] = { $1.typeString, length };

                $$.codeString = new char[strlen(temp) + 1];
                strcpy($$.codeString, temp);
                $$.typeString = new char[strlen($1.typeString) + 1];
                strcpy($$.typeString, $1.typeString);
                $$.processString = new char[strlen(process) + 1];
                strcpy($$.processString, process);
            } else {
                yyerror("Mismatched types or lengths in vector addition");
                YYABORT;
            }
            
        } else {
            $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 4];
            sprintf($$.codeString, "%s * %s", $1.codeString, $3.codeString);
            // Type checking logic to determine the result type
            if (strcmp($1.typeString, "int") == 0 && strcmp($3.typeString, "int") == 0) {
                $$.typeString = new char[4];
                strcpy($$.typeString, "int");
            } else if ((strcmp($1.typeString, "int") == 0 || strcmp($1.typeString, "double") == 0) && (strcmp($3.typeString, "int") == 0 || strcmp($3.typeString, "double") == 0)) {
                $$.typeString = new char[7];
                strcpy($$.typeString, "double");
            }
        }
    }
    | expr '/' expr
    {
        auto it1 = symbol_table.find($1.codeString);
        auto it2 = symbol_table.find($3.codeString);
        if (it1 != symbol_table.end() && it2 != symbol_table.end() && it1->second.length > 0 && it2->second.length > 0) {
            if (strcmp($1.typeString, $3.typeString) == 0 && it1->second.length == it2->second.length) {
                int length = it1->second.length;
                char* temp = new char[20];
                sprintf(temp, "tmp_arr%d", tmpCounter);
                tmpCounter++;

                // Generate the addition process codeString
                char* process = new char[300 + 20 * length];
                if (!i_flag) {
                    i_flag = true;
                    sprintf(process, "int i;\n%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] / %s[i];", $1.typeString, temp, length, length, temp, $1.codeString, $3.codeString);
                } else {
                    sprintf(process, "%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] / %s[i];", $1.typeString, temp, length, length, temp, $1.codeString, $3.codeString);
                }

                // Add the temporary array to the symbol table
                symbol_table[temp] = { $1.typeString, length };

                $$.codeString = new char[strlen(temp) + 1];
                strcpy($$.codeString, temp);
                $$.typeString = new char[strlen($1.typeString) + 1];
                strcpy($$.typeString, $1.typeString);
                $$.processString = new char[strlen(process) + 1];
                strcpy($$.processString, process);
            } else {
                yyerror("Mismatched types or lengths in vector addition");
                YYABORT;
            }
            
        } else {
            if ($3.codeString[0] == '0') {
                yyerror("Division by zero");
                YYABORT;
            }
            $$.codeString = new char[strlen($1.codeString) + strlen($3.codeString) + 4];
            sprintf($$.codeString, "%s / %s", $1.codeString, $3.codeString);
            // Type checking logic to determine the result type
            if (strcmp($1.typeString, "int") == 0 && strcmp($3.typeString, "int") == 0) {
                $$.typeString = new char[4];
                strcpy($$.typeString, "int");
            } else if ((strcmp($1.typeString, "int") == 0 || strcmp($1.typeString, "double") == 0) && (strcmp($3.typeString, "int") == 0 || strcmp($3.typeString, "double") == 0)) {
                $$.typeString = new char[7];
                strcpy($$.typeString, "double");
            }
        }
    }
    | '-' expr %prec UMINUS
    {
        $$.codeString = new char[strlen($2.codeString) + 2];
        sprintf($$.codeString, "-%s", $2.codeString);
        $$.typeString = new char[strlen($2.typeString) + 1];
        strcpy($$.typeString, $2.typeString);
    }
    | '(' expr ')'
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