%{
#include <cstdio>
#include <list>
#include <map>
#include <iostream>
#include <string>
#include <memory>
#include <stdexcept>
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

static LLVMContext TheContext;
static IRBuilder<> Builder(TheContext);
Module *M = new Module("Tutorial3", TheContext);
Value *regs[16] = {nullptr}; // Support R0-R7 and A0-A3

extern FILE *yyin;
int yylex();
void yyerror(const char*);

%}

%union {
  int reg;
  int imm;
  Value *val;
}

%token RETURN
%token <reg> REG
%token <imm> IMMEDIATE
%token ASSIGN SEMI PLUS MINUS LPAREN RPAREN LBRACKET RBRACKET
%type <val> expr

%left PLUS MINUS

%%

program:
    REG ASSIGN expr SEMI {
        regs[$1] = $3;
    }
    | program REG ASSIGN expr SEMI {
        regs[$2] = $4;
    }
    | program RETURN REG SEMI {
        Builder.CreateRet(regs[$3]); return 0;
    }
;

expr:
    IMMEDIATE {
        $$ = Builder.getInt32($1);
    }
    | REG {
        $$ = regs[$1];
    }
    | expr PLUS expr {
        $$ = Builder.CreateAdd($1, $3, "addtmp");
    }
    | expr PLUS IMMEDIATE {
        $$ = Builder.CreateAdd($1, Builder.getInt($3), "addtmp");
    }
    | expr MINUS IMMEDIATE {
        $$ = Builder.CreateSub($1, Builder.getInt32($3), "subtmp");
    }
    | expr MINUS expr {
        $$ = Builder.CreateSub($1, $3, "subtmp");
    }
    | MINUS expr {
      $$ = Builder.CreateNeg($2, "negtmp");
    }
    | LPAREN expr RPAREN {
        $$ = $2; // Parentheses just return the enclosed expression
    }
    | LBRACKET expr RBRACKET {
      if ($2->getType()->isIntegerTy()) {
          Value *ptr = Builder.CreateIntToPtr($2, PointerType::get(Builder.getInt32Ty(), 0));
          $$ = Builder.CreateLoad(Builder.getInt32Ty(), ptr);
      } else {
        yyerror("Expected integer for pointer");
      }
        //Value *ptr = Builder.CreateIntToPtr($2, PointerType::get(Builder.getInt32Ty(), 0), "ptrtmp");
       //$$ = Builder.CreateLoad(Builder.getInt32Ty(), ptr);
    }
    
;

%%

// Error handling
void yyerror(const char* msg) {
    printf("%s\n", msg);
}

int main(int argc, char *argv[]) {
    Type *i32 = Builder.getInt32Ty();
    std::vector<Type*> args = {i32, i32, i32, i32};
    FunctionType *FunType = FunctionType::get(Builder.getInt32Ty(), args, false);
    Function *Function = Function::Create(FunType, GlobalValue::ExternalLinkage, "main", M);

    BasicBlock *BB = BasicBlock::Create(TheContext, "entry", Function);
    Builder.SetInsertPoint(BB);

    yyin = stdin;

    if (yyparse() == 0) {
        std::error_code EC;
        raw_fd_ostream OS("main.bc", EC, sys::fs::OF_None);
        WriteBitcodeToFile(*M, OS);
        M->print(errs(), nullptr, false, true);
    } else {
        printf("There was a problem! Read error messages above.\n");
    }
    return 0;
}
