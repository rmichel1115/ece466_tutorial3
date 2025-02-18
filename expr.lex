
// Just wanted to make note that I specifically used AI to help with some of the token definitions. I was able to understand why some of my register inputs were incorrect (example: why R1 would work and r1 would not). expr.lex remained very similar to the one I constructed in Tutorial 2.

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
[A-Za-z][0-9]+     { yylval.reg = atoi(yytext+1); return IMMEDIATE; } 
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

//int yywrap(void) {
    //return 1;
//}
