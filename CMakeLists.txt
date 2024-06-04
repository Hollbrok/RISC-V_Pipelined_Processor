cmake_minimum_required(VERSION 3.20)
project(riscv_pipeline)

set(RISCV_PIPELINE_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/verilog_src)

set(RISCV_PIPELINE_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${RISCV_PIPELINE_BINARY_DIR}/bin)

find_package(verilator)

if (NOT verilator_FOUND)
    message(
      FATAL_ERROR
      "Verilator was not found."
    )
endif()

add_executable(core verilog_src/core_32i.cpp)
target_compile_features(core PRIVATE cxx_std_17)
target_compile_options(core PRIVATE)

verilate(
    core
    SOURCES verilog_src/CPU/Pipeline_CPU.sv
    TRACE BUILD
    INCLUDE_DIRS  ${RISCV_PIPELINE_SRC_DIR}                  
                  ${RISCV_PIPELINE_SRC_DIR}/ADDITIONAL
                  ${RISCV_PIPELINE_SRC_DIR}/CPU
    VERILATOR_ARGS -cc --exe
)
