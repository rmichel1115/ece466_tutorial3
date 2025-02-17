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
Value *regs[8] = {nullptr};

// Global declarations for LLVM context and builder
extern FILE *yyin;
int yylex();
void yyerror(const char*);

// Helper function for formatting strings
template<typename ... Args>
std::string format(const std::string& format, Args ... args) {
    size_t size = snprintf(nullptr, 0, format.c_str(), args ...) + 1;
    if(size <= 0) {
        fprintf(stderr, "Error during formatting.\n");
        exit(1);
    }
    std::unique_ptr<char[]> buf(new char[size]);
    snprintf(buf.get(), size, format.c_str(), args ...);
    return std::string(buf.get(), buf.get() + size - 1);
}

// Create a unique register number
int getReg() {
    static int cnt = 8;
    return cnt++;
}
%}

%verbose
%define parse.trace

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
    | expr MINUS expr {
        $$ = Builder.CreateSub($1, $3, "subtmp");
    }
    | LPAREN expr RPAREN {
        $$ = $2;
    }
    | MINUS expr {
        $$ = Builder.CreateNeg($2, "negtmp");
    }
    | LBRACKET expr RBRACKET {
        Value *ptr = Builder.CreateIntToPtr($2, PointerType::get(Builder.getInt32Ty(), 0));
        $$ = Builder.CreateLoad(Builder.getInt32Ty(), ptr);
    }
;

%%

// Error handling function
void yyerror(const char* msg) {
    printf("%s\n", msg);
}

int main(int argc, char *argv[]) {
    // Create a new LLVM Module
    Type *i32 = Builder.getInt32Ty();
    std::vector<Type*> args = {i32, i32, i32, i32};
    FunctionType *FunType = FunctionType::get(Builder.getInt32Ty(), args, false);
    Function *Function = Function::Create(FunType, GlobalValue::ExternalLinkage, "main", M);

    // Create basic block for the function
    BasicBlock *BB = BasicBlock::Create(TheContext, "entry", Function);
    Builder.SetInsertPoint(BB);

    // Start the parsing process
    yyin = stdin; // Input from standard input

    // Parse input using yyparse() from Bison
    if (yyparse() == 0) {
        // Write bitcode to file
        std::error_code EC;
        raw_fd_ostream OS("main.bc", EC, sys::fs::OF_None);
        WriteBitcodeToFile(*M, OS);

        // Output the LLVM IR to the console for debugging
        M->print(errs(), nullptr, false, true);
    } else {
        printf("There was a problem! Read error messages above.\n");
    }
    return 0;
}
