%{
#include <stdio.h>
#include <stdlib.h>
#include "expr.tab.h"

%}

%%
[ \t\n]+               /* Ignore whitespace */;
"return"               { return RETURN; }
"R[0-7]"               { yylval.reg = atoi(yytext + 1); return REG; }
[0-9]+                 { yylval.imm = atoi(yytext); return IMMEDIATE; }
"+"                    { return PLUS; }
"-"                    { return MINUS; }
"*"                    { return MUL; }
"/"                    { return DIV; }
"["                    { return LBRACKET; }
"]"                    { return RBRACKET; }
"="                    { return ASSIGN; }
";"                    { return SEMI; }
%%

int yywrap() {
    return 1;
}
