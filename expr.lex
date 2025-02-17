%{
#include <stdio.h>
#include <iostream>
#include <math.h>
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Value.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/Bitcode/BitcodeReader.h"
#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/Support/SystemUtils.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/Support/FileSystem.h"
using namespace llvm;
#include "expr.y.hpp"
%}

%option noyywrap

%% // Token definitions

[ \t\r\n]+    ; // Ignore whitespace

[Rr][0-9]+    { yylval.reg = atoi(yytext+1); return REG; }
[Aa][0-3]     { yylval.reg = atoi(yytext+1) + 8; return REG; } // Handle a0-a3
"return"      { return RETURN; }
[0-9]+        { yylval.imm = atoi(yytext); return IMMEDIATE; }
"="           { return ASSIGN; }
";"           { return SEMI; }
"("           { return LPAREN; }
")"           { return RPAREN; }
"["           { return LBRACKET; }
"]"           { return RBRACKET; }
"-"           { return MINUS; }
"+"           { return PLUS; }
"//".*\n      ; // Ignore comments

.             { printf("syntax error!\n"); exit(1); }

%% // End of tokens

int yywrap(void) {
    return 1;
}
