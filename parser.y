%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <map>

void yyerror(const char *s, int line);
void yyerror(const char *s);
int yylex(void);

using namespace std;

FILE *outfile;

struct VectorInfo {
    std::string type;
    int length;
};
std::map<std::string, VectorInfo> symbol_table;

extern int lineNum;

int temp_count = 0;
bool is_i_declared = false;
%}

%union {
    int ival;
    double rval;
    char cval;
    char *sval;
    char *str;
    struct {
        char *code;
        char *type;
        char *process;
    } expr_val;
    struct {
        char *code;
        int length;
    } expr_list_val;
}


%token <ival> INTEGER_LITERAL
%token <rval> REAL_LITERAL
%token <cval> CHAR_LITERAL
%token <sval> STRING_LITERAL
%token <str> IDENTIFIER
%token FUN VAR VAL BOOL CHAR INT REAL STRING TRUE FALSE CLASS IF ELSE FOR WHILE DO SWITCH CASE RET PRINTLN PRINT
%token EQ NE LE GE AND OR

%type <expr_val> expr
%type <expr_list_val> expr_list

%type <str> functions
%type <str> function
%type <str> statements
%type <str> variable_declaration
%type <str> type
%type <str> statement

%left '+' '-'
%left '*' '/'
%left '#'
%nonassoc UMINUS

%%

program:
    functions
    {
        fprintf(outfile, "#include <stdio.h>\n#include <stdlib.h>\n#include <stdbool.h>\n\n%s\n", $1);
        fclose(outfile);
    }
;

functions:
    /* Define your functions rule here */
    function
    {
        $$ = new char[strlen($1) + 1];
        strcpy($$, $1);
    }
    | functions function
    {
        $$ = new char[strlen($1) + strlen($2) + 1];
        strcpy($$, $1);
        strcat($$, $2);
    }
;

function:
    FUN IDENTIFIER '(' ')' '{' statements '}' 
    {
        if (strcmp($2, "main") == 0) {
            $$ = new char[strlen($2) + strlen($6) + 20];
            sprintf($$, "int %s() {\n%s}\n\n", $2, $6);
        } else {
            $$ = new char[strlen($2) + strlen($6) + 20];
            sprintf($$, "void %s() {\n%s}\n\n", $2, $6);
        }
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
        auto it = symbol_table.find($3.code);
        if (it != symbol_table.end() && it->second.length > 0) {
            // Array printing logic
            int length = it->second.length;
            print_stmt = new char[200];
            char* for_loop = new char[200];
            if (!is_i_declared) {
                is_i_declared = true;
                sprintf(for_loop, "int i;\nprintf(\"{\");\nfor (i = 0; i < %d; ++i) {\n    if (i != 0) printf(\", \");\n    printf(\"", length);
            } else {
                sprintf(for_loop, "printf(\"{\");\nfor (i = 0; i < %d; ++i) {\n    if (i != 0) printf(\", \");\n    printf(\"", length);
            }

            if (strcmp($3.type, "int") == 0) {
                strcat(for_loop, "%%d\", %s[i]);\n}\nprintf(\"}\\n\");\n");
            } else if (strcmp($3.type, "double") == 0) {
                strcat(for_loop, "%%f\", %s[i]);\n}\nprintf(\"}\\n\");\n");
            } else if (strcmp($3.type, "char") == 0) {
                strcat(for_loop, "%%c\", %s[i]);\n}\nprintf(\"}\\n\");\n");
            } else {
                strcat(for_loop, "%%s\", %s[i]);\n}\nprintf(\"}\\n\");\n");
            }

            print_stmt = new char[strlen(for_loop) + strlen($3.code) * 2 + 1];
            sprintf(print_stmt, for_loop, $3.code, $3.code);
        } else {
             // Scalar printing logic
            print_stmt = new char[strlen($3.code) + 50];
            if (strcmp($3.type, "int") == 0) {
                sprintf(print_stmt, "printf(\"%%d\\n\", %s);\n", $3.code);
            } else if (strcmp($3.type, "double") == 0) {
                sprintf(print_stmt, "printf(\"%%f\\n\", %s);\n", $3.code);
            } else if (strcmp($3.type, "char") == 0) {
                sprintf(print_stmt, "printf(\"%%c\\n\", %s);\n", $3.code);
            } else if (strcmp($3.type, "string") == 0) {
                sprintf(print_stmt, "printf(\"%%s\\n\", %s);\n", $3.code);
            } else {
                sprintf(print_stmt, "printf(\"%%s\\n\", %s);\n", $3.code);
            }
        }

        if ($3.process != NULL) {
            $$ = new char[strlen($3.process) + strlen(print_stmt) + 2];
            sprintf($$, "%s\n%s", $3.process, print_stmt);
        } else {
            $$ = new char[strlen(print_stmt) + 1];
            sprintf($$, "%s", print_stmt);
        }
    }
    | PRINT '(' expr ')' ';'
    {
        char* print_stmt;
        auto it = symbol_table.find($3.code);
        if (it != symbol_table.end() && it->second.length > 0) {
            // Array printing logic
            int length = it->second.length;
            print_stmt = new char[200];
            char* for_loop = new char[200];
            if (!is_i_declared) {
                is_i_declared = true;
                sprintf(for_loop, "int i;\nprintf(\"{\");\nfor (i = 0; i < %d; ++i) {\n    if (i != 0) printf(\", \");\n    printf(\"", length);
            } else {
                sprintf(for_loop, "printf(\"{\");\nfor (i = 0; i < %d; ++i) {\n    if (i != 0) printf(\", \");\n    printf(\"", length);
            }

            if (strcmp($3.type, "int") == 0) {
                strcat(for_loop, "%%d\", %s[i]);\n}\nprintf(\"}\");\n");
            } else if (strcmp($3.type, "double") == 0) {
                strcat(for_loop, "%%f\", %s[i]);\n}\nprintf(\"}\");\n");
            } else if (strcmp($3.type, "char") == 0) {
                strcat(for_loop, "%%c\", %s[i]);\n}\nprintf(\"}\");\n");
            } else {
                strcat(for_loop, "%%s\", %s[i]);\n}\nprintf(\"}\");\n");
            }

            print_stmt = new char[strlen(for_loop) + strlen($3.code) * 2 + 1];
            sprintf(print_stmt, for_loop, $3.code, $3.code);
        } else {
             // Scalar printing logic
            print_stmt = new char[strlen($3.code) + 50];
            if (strcmp($3.type, "int") == 0) {
                sprintf(print_stmt, "printf(\"%%d\", %s);\n", $3.code);
            } else if (strcmp($3.type, "double") == 0) {
                sprintf(print_stmt, "printf(\"%%f\", %s);\n", $3.code);
            } else if (strcmp($3.type, "char") == 0) {
                sprintf(print_stmt, "printf(\"%%c\", %s);\n", $3.code);
            } else if (strcmp($3.type, "string") == 0) {
                sprintf(print_stmt, "printf(\"%%s\", %s);\n", $3.code);
            } else {
                sprintf(print_stmt, "printf(\"%%s\", %s);\n", $3.code);
            }
        }

        if ($3.process != NULL) {
            $$ = new char[strlen($3.process) + strlen(print_stmt) + 2];
            sprintf($$, "%s\n%s", $3.process, print_stmt);
        } else {
            $$ = new char[strlen(print_stmt) + 1];
            sprintf($$, "%s", print_stmt);
        }
    }
    | expr '=' expr ';'
    {
        auto it1 = symbol_table.find($1.code);
        auto it2 = symbol_table.find($3.code);

        if (it1 != symbol_table.end() && it1->second.length > 0) { // The left-hand side is an array
            if (it2 != symbol_table.end() && it2->second.length > 0) { // The right-hand side is also an array
                if (strcmp($1.type, $3.type) == 0 && it1->second.length == it2->second.length) {
                    // Arrays match in type and size
                    char* process = new char[300];
                    sprintf(process, "for (int i = 0; i < %d; ++i) %s[i] = %s[i];\n", it1->second.length, $1.code, $3.code);
                    $$ = new char[strlen(process) + 1];
                    strcpy($$, process);
                } else {
                    yyerror("Mismatched types or lengths in array assignment", lineNum);
                    YYABORT;
                }
            } else {
                yyerror("Right-hand side must be an array in array assignment", lineNum);
                YYABORT;
            }
        } else {
            // Scalar assignment
            $$ = new char[strlen($1.code) + strlen($3.code) + 5];
            sprintf($$, "%s = %s;\n", $1.code, $3.code);
        }
    }
    | expr '=' '{' expr_list '}' ';'
    {
        auto it = symbol_table.find($1.code);
        if (it != symbol_table.end() && it->second.length > 0) { // The left-hand side is an array
            if (it->second.length >= $4.length) { // The initializer list fits in the array
                char* temp = new char[20];
                sprintf(temp, "tmp_arr%d", temp_count);
                temp_count++;
                char* declare_temp = new char[30];
                char* process = new char[300 + strlen($4.code)];
                sprintf(declare_temp, "%s %s[%d] = {%s};\n", $1.type, temp, it->second.length, $4.code);
                sprintf(process, "for (int i = 0; i < %d; ++i) %s[i] = %s[i];\n", it->second.length, $1.code, temp);
                $$ = new char[strlen(declare_temp) + strlen(process) + 1];
                sprintf($$, "%s%s", declare_temp, process);
            } else {
                yyerror("Initializer list too long for array", lineNum);
                YYABORT;
            }
        } else {
            yyerror("Left-hand side must be an array in array assignment", lineNum);
            YYABORT;
        }
    }
    | IF '(' expr ')' '{' statements '}' %prec UMINUS
    {
        char* if_stmt = new char[strlen($3.code) + strlen($6) + 20];
        sprintf(if_stmt, "if (%s) {\n%s}\n", $3.code, $6);
        $$ = if_stmt;
    }
    | IF '(' expr ')' '{' statements '}' ELSE '{' statements '}' %prec UMINUS
    {
        char* if_else_stmt = new char[strlen($3.code) + strlen($6) + strlen($10) + 30];
        sprintf(if_else_stmt, "if (%s) {\n%s} else {\n%s}\n", $3.code, $6, $10);
        $$ = if_else_stmt;
    }
    | WHILE '(' expr ')' '{' statements '}'
    {
        char* while_stmt = new char[strlen($3.code) + strlen($6) + 20];
        sprintf(while_stmt, "while (%s) {\n%s}\n", $3.code, $6);
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
            yyerror(error, lineNum);
            YYABORT;
        }

        if (strcmp($4, "string") == 0) { 
            yyerror("String variables must be initialized", lineNum);
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
            yyerror(error, lineNum);
            YYABORT;
        }

        symbol_table[$2] = { $4, -1 };

        if (strcmp($4, "string") == 0) {
            $$ = new char[strlen($2) + strlen($6.code) + 15];
            sprintf($$, "char %s[] = %s;\n", $2, $6.code);
        } else {
            $$ = new char[strlen($2) + strlen($4) + strlen($6.code) + 15];
            sprintf($$, "%s %s = %s;\n", $4, $2, $6.code);
        }
    }
    | VAR IDENTIFIER ':' type '[' INTEGER_LITERAL ']' ';'
    {
        // Check if the variable has already been declared
        auto it = symbol_table.find($2);
        if (it != symbol_table.end()) {
            char* error = new char[strlen($2) + 30];
            sprintf(error, "Variable %s already declared", $2);
            yyerror(error, lineNum);
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
            yyerror(error, lineNum);
            YYABORT;
        }

        if ($6 < $10.length) {
            char* error = new char[strlen($2) + 30];
            sprintf(error, "Too many elements for %s", $2);
            yyerror(error, lineNum);
            YYABORT;
        }
        // Insert into symbol table with vector info
        symbol_table[$2] = { $4, $6 };
        $$ = new char[strlen($2) + strlen($4) + strlen($10.code) + strlen($10.code) + 40];
        sprintf($$, "%s %s[%d] = {%s};\n", $4, $2, $6, $10.code);
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
        $$.code = new char[strlen($1.code) + 1];
        sprintf($$.code, "%s", $1.code);
        $$.length = 1;
    }
    | expr_list ',' expr
    {
        $$.code = new char[strlen($1.code) + strlen($3.code) + 4];
        sprintf($$.code, "%s, %s", $1.code, $3.code);
        $$.length = $1.length + 1;
    }
;

expr:
    INTEGER_LITERAL
    {
        $$.code = new char[20];
        sprintf($$.code, "%d", $1);
        $$.type = new char[4];
        strcpy($$.type, "int");
    }
    | REAL_LITERAL
    {
        $$.code = new char[30];
        sprintf($$.code, "%.17f", $1);
        $$.type = new char[7];
        strcpy($$.type, "double");
    }
    | CHAR_LITERAL
    {
        $$.code = new char[4];
        sprintf($$.code, "'%c'", $1);
        $$.type = new char[5];
        strcpy($$.type, "char");
    }
    | STRING_LITERAL
    {
        $$.code = new char[strlen($1) + 1];
        strcpy($$.code, $1);
        $$.type = new char[7];
        strcpy($$.type, "string");
    }
    | TRUE
    {
        $$.code = new char[6];
        strcpy($$.code, "true");
        $$.type = new char[5];
        strcpy($$.type, "bool");
    }
    | FALSE
    {
        $$.code = new char[6];
        strcpy($$.code, "false");
        $$.type = new char[5];
        strcpy($$.type, "bool");
    }
    | expr '<' expr
    {
        $$.code = new char[strlen($1.code) + strlen($3.code) + 4];
        sprintf($$.code, "%s < %s", $1.code, $3.code);
        $$.type = new char[5];
        strcpy($$.type, "bool");
    }
    | expr '>' expr
    {
        $$.code = new char[strlen($1.code) + strlen($3.code) + 4];
        sprintf($$.code, "%s > %s", $1.code, $3.code);
        $$.type = new char[5];
        strcpy($$.type, "bool");
    }
    | expr EQ expr
    {
        $$.code = new char[strlen($1.code) + strlen($3.code) + 5];
        sprintf($$.code, "%s == %s", $1.code, $3.code);
        $$.type = new char[5];
        strcpy($$.type, "bool");
    }
    | expr NE expr
    {
        $$.code = new char[strlen($1.code) + strlen($3.code) + 5];
        sprintf($$.code, "%s != %s", $1.code, $3.code);
        $$.type = new char[5];
        strcpy($$.type, "bool");
    }
    | expr LE expr
    {
        $$.code = new char[strlen($1.code) + strlen($3.code) + 5];
        sprintf($$.code, "%s <= %s", $1.code, $3.code);
        $$.type = new char[5];
        strcpy($$.type, "bool");
    }
    | expr GE expr
    {
        $$.code = new char[strlen($1.code) + strlen($3.code) + 5];
        sprintf($$.code, "%s >= %s", $1.code, $3.code);
        $$.type = new char[5];
        strcpy($$.type, "bool");
    }
    | IDENTIFIER
    {
        $$.code = new char[strlen($1) + 1];
        strcpy($$.code, $1);
        auto it = symbol_table.find($1);
        if (it != symbol_table.end()) {
            const VectorInfo &vec_info = it->second;
            $$.type = new char[vec_info.type.length() + 1];
            strcpy($$.type, vec_info.type.c_str());
        } else {
            char* error = new char[strlen($1) + 20];
            sprintf(error, "Undeclared variable %s", $1);
            yyerror(error, lineNum);
            YYABORT;
        }
    }
    | IDENTIFIER '[' expr ']'
    {
        $$.code = new char[strlen($1) + strlen($3.code) + 4];
        sprintf($$.code, "%s[%s]", $1, $3.code);

        auto it = symbol_table.find($1);
        if (it != symbol_table.end()) {
            const VectorInfo &vec_info = it->second;
            $$.type = new char[vec_info.type.length() + 1];
            strcpy($$.type, vec_info.type.c_str());
        } else {
            char* error = new char[strlen($1) + 20];
            sprintf(error, "Undeclared variable %s", $1);
            yyerror(error, lineNum);
            YYABORT;
        }
    }
    | expr '#' expr
    {
        // Inner product
        auto it1 = symbol_table.find($1.code);
        auto it2 = symbol_table.find($3.code);
        if (it1 != symbol_table.end() && it2 != symbol_table.end() && it1->second.length > 0 && it2->second.length > 0) {
            if (strcmp($1.type, $3.type) == 0 && it1->second.length == it2->second.length) {
                int length = symbol_table[$1.code].length;
                char* temp = new char[10];
                sprintf(temp, "tmp%d", temp_count);
                char* process = new char[200];
                if (!is_i_declared) {
                    is_i_declared = true;
                    sprintf(process, "int i;\n%s %s = 0;\nfor (i = 0; i < %d; i++) %s += %s[i] * %s[i];", $1.type, temp, length, temp, $1.code, $3.code);
                } else {
                    sprintf(process, "%s %s = 0;\nfor (i = 0; i < %d; i++) %s += %s[i] * %s[i];", $1.type, temp, length, temp, $1.code, $3.code);
                }
                temp_count++;

                $$.code = new char[strlen(temp) + 1];
                strcpy($$.code, temp);
                $$.type = new char[strlen($1.type) + 1];
                strcpy($$.type, $1.type);
                $$.process = new char[strlen(process) + 1];
                $$.process = process;
            } else {
                yyerror("Mismatched types or lengths in vector addition", lineNum);
                YYABORT;
            }
        } else {
            yyerror("Inner product on non-array object", lineNum);
            YYABORT;
        }
    }
    | expr '+' expr
    {
        auto it1 = symbol_table.find($1.code);
        auto it2 = symbol_table.find($3.code);
        if (it1 != symbol_table.end() && it2 != symbol_table.end() && it1->second.length > 0 && it2->second.length > 0) {
            if (strcmp($1.type, $3.type) == 0 && it1->second.length == it2->second.length) {
                int length = it1->second.length;
                char* temp = new char[20];
                sprintf(temp, "tmp_arr%d", temp_count);
                temp_count++;

                // Generate the addition process code
                char* process = new char[300 + 20 * length];
                if (!is_i_declared) {
                    is_i_declared = true;
                    sprintf(process, "int i;\n%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] + %s[i];", $1.type, temp, length, length, temp, $1.code, $3.code);
                } else {
                    sprintf(process, "%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] + %s[i];", $1.type, temp, length, length, temp, $1.code, $3.code);
                }

                // Add the temporary array to the symbol table
                symbol_table[temp] = { $1.type, length };

                $$.code = new char[strlen(temp) + 1];
                strcpy($$.code, temp);
                $$.type = new char[strlen($1.type) + 1];
                strcpy($$.type, $1.type);
                $$.process = new char[strlen(process) + 1];
                strcpy($$.process, process);
            } else {
                yyerror("Mismatched types or lengths in vector addition", lineNum);
                YYABORT;
            }
            
        } else {
            $$.code = new char[strlen($1.code) + strlen($3.code) + 4];
            sprintf($$.code, "%s + %s", $1.code, $3.code);
            // Type checking logic to determine the result type
            if (strcmp($1.type, "int") == 0 && strcmp($3.type, "int") == 0) {
                $$.type = new char[4];
                strcpy($$.type, "int");
            } else if ((strcmp($1.type, "int") == 0 || strcmp($1.type, "double") == 0) && (strcmp($3.type, "int") == 0 || strcmp($3.type, "double") == 0)) {
                $$.type = new char[7];
                strcpy($$.type, "double");
            }
        }
    }

    | expr '-' expr
    {
        auto it1 = symbol_table.find($1.code);
        auto it2 = symbol_table.find($3.code);
        if (it1 != symbol_table.end() && it2 != symbol_table.end() && it1->second.length > 0 && it2->second.length > 0) {
            if (strcmp($1.type, $3.type) == 0 && it1->second.length == it2->second.length) {
                int length = it1->second.length;
                char* temp = new char[20];
                sprintf(temp, "tmp_arr%d", temp_count);
                temp_count++;

                // Generate the addition process code
                char* process = new char[300 + 20 * length];
                if (!is_i_declared) {
                    is_i_declared = true;
                    sprintf(process, "int i;\n%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] - %s[i];", $1.type, temp, length, length, temp, $1.code, $3.code);
                } else {
                    sprintf(process, "%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] - %s[i];", $1.type, temp, length, length, temp, $1.code, $3.code);
                }

                // Add the temporary array to the symbol table
                symbol_table[temp] = { $1.type, length };

                $$.code = new char[strlen(temp) + 1];
                strcpy($$.code, temp);
                $$.type = new char[strlen($1.type) + 1];
                strcpy($$.type, $1.type);
                $$.process = new char[strlen(process) + 1];
                strcpy($$.process, process);
            } else {
                yyerror("Mismatched types or lengths in vector addition", lineNum);
                YYABORT;
            }
            
        } else {
            $$.code = new char[strlen($1.code) + strlen($3.code) + 4];
            sprintf($$.code, "%s - %s", $1.code, $3.code);
            // Type checking logic to determine the result type
            if (strcmp($1.type, "int") == 0 && strcmp($3.type, "int") == 0) {
                $$.type = new char[4];
                strcpy($$.type, "int");
            } else if ((strcmp($1.type, "int") == 0 || strcmp($1.type, "double") == 0) && (strcmp($3.type, "int") == 0 || strcmp($3.type, "double") == 0)) {
                $$.type = new char[7];
                strcpy($$.type, "double");
            }
        }
    }
    | expr '*' expr
    {
        auto it1 = symbol_table.find($1.code);
        auto it2 = symbol_table.find($3.code);
        if (it1 != symbol_table.end() && it2 != symbol_table.end() && it1->second.length > 0 && it2->second.length > 0) {
            if (strcmp($1.type, $3.type) == 0 && it1->second.length == it2->second.length) {
                int length = it1->second.length;
                char* temp = new char[20];
                sprintf(temp, "tmp_arr%d", temp_count);
                temp_count++;

                // Generate the addition process code
                char* process = new char[300 + 20 * length];
                if (!is_i_declared) {
                    is_i_declared = true;
                    sprintf(process, "int i;\n%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] * %s[i];", $1.type, temp, length, length, temp, $1.code, $3.code);
                } else {
                    sprintf(process, "%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] * %s[i];", $1.type, temp, length, length, temp, $1.code, $3.code);
                }

                // Add the temporary array to the symbol table
                symbol_table[temp] = { $1.type, length };

                $$.code = new char[strlen(temp) + 1];
                strcpy($$.code, temp);
                $$.type = new char[strlen($1.type) + 1];
                strcpy($$.type, $1.type);
                $$.process = new char[strlen(process) + 1];
                strcpy($$.process, process);
            } else {
                yyerror("Mismatched types or lengths in vector addition", lineNum);
                YYABORT;
            }
            
        } else {
            $$.code = new char[strlen($1.code) + strlen($3.code) + 4];
            sprintf($$.code, "%s * %s", $1.code, $3.code);
            // Type checking logic to determine the result type
            if (strcmp($1.type, "int") == 0 && strcmp($3.type, "int") == 0) {
                $$.type = new char[4];
                strcpy($$.type, "int");
            } else if ((strcmp($1.type, "int") == 0 || strcmp($1.type, "double") == 0) && (strcmp($3.type, "int") == 0 || strcmp($3.type, "double") == 0)) {
                $$.type = new char[7];
                strcpy($$.type, "double");
            }
        }
    }
    | expr '/' expr
    {
        auto it1 = symbol_table.find($1.code);
        auto it2 = symbol_table.find($3.code);
        if (it1 != symbol_table.end() && it2 != symbol_table.end() && it1->second.length > 0 && it2->second.length > 0) {
            if (strcmp($1.type, $3.type) == 0 && it1->second.length == it2->second.length) {
                int length = it1->second.length;
                char* temp = new char[20];
                sprintf(temp, "tmp_arr%d", temp_count);
                temp_count++;

                // Generate the addition process code
                char* process = new char[300 + 20 * length];
                if (!is_i_declared) {
                    is_i_declared = true;
                    sprintf(process, "int i;\n%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] / %s[i];", $1.type, temp, length, length, temp, $1.code, $3.code);
                } else {
                    sprintf(process, "%s %s[%d];\nfor (i = 0; i < %d; ++i) %s[i] = %s[i] / %s[i];", $1.type, temp, length, length, temp, $1.code, $3.code);
                }

                // Add the temporary array to the symbol table
                symbol_table[temp] = { $1.type, length };

                $$.code = new char[strlen(temp) + 1];
                strcpy($$.code, temp);
                $$.type = new char[strlen($1.type) + 1];
                strcpy($$.type, $1.type);
                $$.process = new char[strlen(process) + 1];
                strcpy($$.process, process);
            } else {
                yyerror("Mismatched types or lengths in vector addition", lineNum);
                YYABORT;
            }
            
        } else {
            if ($3.code[0] == '0') {
                yyerror("Division by zero", lineNum);
                YYABORT;
            }
            $$.code = new char[strlen($1.code) + strlen($3.code) + 4];
            sprintf($$.code, "%s / %s", $1.code, $3.code);
            // Type checking logic to determine the result type
            if (strcmp($1.type, "int") == 0 && strcmp($3.type, "int") == 0) {
                $$.type = new char[4];
                strcpy($$.type, "int");
            } else if ((strcmp($1.type, "int") == 0 || strcmp($1.type, "double") == 0) && (strcmp($3.type, "int") == 0 || strcmp($3.type, "double") == 0)) {
                $$.type = new char[7];
                strcpy($$.type, "double");
            }
        }
    }
    | '-' expr %prec UMINUS
    {
        $$.code = new char[strlen($2.code) + 2];
        sprintf($$.code, "-%s", $2.code);
        $$.type = new char[strlen($2.type) + 1];
        strcpy($$.type, $2.type);
    }
    | '(' expr ')'
    {
        $$.code = new char[strlen($2.code) + 3];
        sprintf($$.code, "(%s)", $2.code);
        $$.type = new char[strlen($2.type) + 1];
        strcpy($$.type, $2.type);
    }
;






%%

extern FILE* yyin;

void yyerror(const char *s, int line) {
    fprintf(stderr, "Error on line %d: %s\n", line, s);
    fprintf(outfile, "Error on line %d: %s\n", line, s);
}

void yyerror(const char *s) {
    yyerror(s, lineNum);  // Call the other yyerror with the current line number
}

int main(int argc, char *argv[]) {
    char *input_name;
    if (argc > 1) {
        FILE *file = fopen(argv[1], "r");
        input_name = argv[1];
        if (!file) {
            perror(argv[1]);
            return 1;
        }
        yyin = file;
    } else {
        cout << "No input file" << endl;
        return 1;
    }

    char *suffix = "_out.c";
    size_t input_length = strlen(input_name);
    size_t suffix_length = strlen(suffix);
    size_t output_length = input_length + suffix_length + 1;

    char* output_name = (char *)malloc(output_length * sizeof(char));
    strcpy(output_name, input_name);
    strcat(output_name, suffix);
    outfile = fopen(output_name, "w");
    if (!outfile) {
        perror(output_name);
        exit(1);
    }
    free(output_name);

    return yyparse();
}
