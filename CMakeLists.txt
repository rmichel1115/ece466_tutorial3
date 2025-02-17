cmake_minimum_required(VERSION 3.0)
project("tutorial3")

set(CMAKE_CXX_STANDARD 17)
#set(CMAKE_VERBOSE_MAKEFILE ON)

find_package(BISON)
find_package(FLEX)

find_package(LLVM REQUIRED CONFIG)

list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddLLVM)

add_definitions(${LLVM_DEFINITIONS})
include_directories(${LLVM_INCLUDE_DIRS})

llvm_map_components_to_libnames(llvm_libs analysis bitreader bitwriter codegen core asmparser irreader instcombine instrumentation mc objcarcopts scalarlaropts support ipo target transformutils vectorize)  

BISON_TARGET(Parser expr.y ${CMAKE_CURRENT_BINARY_DIR}/expr.y.cpp)
FLEX_TARGET(Scanner expr.lex ${CMAKE_CURRENT_BINARY_DIR}/expr.lex.cpp)
ADD_FLEX_BISON_DEPENDENCY(Scanner Parser)

SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-exceptions")

include_directories(.)

add_executable(t3 ${BISON_Parser_OUTPUTS} ${FLEX_Scanner_OUTPUTS})
target_link_libraries(t3 y ${llvm_libs})
