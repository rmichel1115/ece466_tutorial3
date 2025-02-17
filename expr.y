%{
#include <cstdio>
#include <cstdlib>
#include <llvm/IR/IRBuilder.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/Type.h>
#include <llvm/IR/Value.h>

using namespace llvm;

LLVMContext TheContext;
IRBuilder<> Builder(TheContext);
Module *M = new Module("tutorial3", TheContext);
Value *regs[8] = {nullptr};  // Register storage
%}

%union {
    int reg;
    int imm;
    Value *val;
}

%token RETURN
%token ASSIGN SEMI PLUS MINUS MUL DIV LBRACKET RBRACKET
%token <reg> REG
%token <imm> IMMEDIATE
%type <val> expr

%%
program:
    REG ASSIGN expr SEMI { regs[$1] = $3; }
    | program REG ASSIGN expr SEMI { regs[$2] = $4; }
    | program RETURN REG SEMI { Builder.CreateRet(regs[$3]); return 0; }
    ;

expr:
    IMMEDIATE { $$ = Builder.getInt32($1); }
    | REG { $$ = regs[$1]; }
    | expr PLUS expr { $$ = Builder.CreateAdd($1, $3, "addtmp"); }
    | expr MINUS expr { $$ = Builder.CreateSub($1, $3, "subtmp"); }
    | expr MUL expr { $$ = Builder.CreateMul($1, $3, "multmp"); }
    | expr DIV expr { $$ = Builder.CreateSDiv($1, $3, "divtmp"); }
    | LBRACKET expr RBRACKET { 
        Value *ptr = Builder.CreateIntToPtr($2, PointerType::get(Builder.getInt32Ty(), 0));
        $$ = Builder.CreateLoad(Builder.getInt32Ty(), ptr);
    }
    ;
%%
