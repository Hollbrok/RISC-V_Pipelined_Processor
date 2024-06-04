#include "VPipeline_CPU.h"

#include "VPipeline_CPU_PipelineCPU.h"

#include "VPipeline_CPU_RegStage.h"
#include "VPipeline_CPU_regfile.h"
#include "VPipeline_CPU_main_pipeline.h"
#include "VPipeline_CPU_datapath.h"
#include "VPipeline_CPU_imem.h"


#include <verilated_vcd_c.h>
#include </home/hollbrok/prog/elfio-3.12/elfio/elfio.hpp>
#include <array>
#include <iostream>

void RegfileStr(const uint32_t *registers)
{
    constexpr std::size_t lineNum = 8;

    for (std::size_t i = 0; i < lineNum; ++i)
    {
        for (std::size_t j = 0; j < 32 / lineNum; ++j)
        {
            auto regIdx = j * lineNum + i;
            auto &reg = registers[regIdx];
            std::cout << "  [" << std::dec << regIdx << "] ";
            std::cout << "0x" << std::hex << reg;
        }
        std::cout << std::endl;
    }
}

vluint64_t sim_time = 0;

void tick(VPipeline_CPU *core, VerilatedVcdC *trace)
{
    core->clk ^= 1;
    core->eval();

    sim_time += 1;
    trace->dump(sim_time);
}

void cycle(VPipeline_CPU *core, VerilatedVcdC *trace)
{
    tick(core, trace);
    tick(core, trace);
}

void run_test(VPipeline_CPU *top_module, VerilatedVcdC *trace)
{
    int pc = (int)top_module->PipelineCPU->PCF;
    while (pc <= 0x100e8) {
        cycle(top_module, trace);
        int rs_1_index = (int)top_module->PipelineCPU->main_pipeline->dp->Rs1D;
        int rs_2_index = (int)top_module->PipelineCPU->main_pipeline->dp->Rs2D;
        int rd_index = (int)top_module->PipelineCPU->main_pipeline->dp->RdD;
        int op = (int)top_module->PipelineCPU->main_pipeline->dp->opD;
        pc = (int)top_module->PipelineCPU->PCF;

        int InstrF = (int)top_module->PipelineCPU->main_pipeline->dp->InstrF;

        int* reg_file = (int*)top_module->PipelineCPU->main_pipeline->dp->rf->rf;

        if (0x10094 < pc) {
            std::cout << std::hex << "INSTR: 0x" << InstrF << std::endl;
            std::cout << "PC: " << std::hex << pc << std::endl;
            std::cout << "rf[" << rs_1_index << "](rs1): "<< reg_file[rs_1_index] << std::endl;
            std::cout << "rf[" << rs_2_index << "](rs2): "<< reg_file[rs_2_index] << std::endl;
            std::cout << "rf[" << rd_index << "](rd): "<< reg_file[rd_index] << std::endl;
            std::cout << "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$" << std::endl;
        }
    }
}

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);

    if (argc < 2)
    {
        std::cerr << "Required filename argument with binary file" << std::endl;
        exit(EXIT_FAILURE);
    }

    VPipeline_CPU * top_module = new VPipeline_CPU;

    Verilated::traceEverOn(true);
    VerilatedVcdC * vcd = new VerilatedVcdC;
    top_module->trace(vcd, 5);
    vcd->open("out.vcd");


    ELFIO::elfio m_reader{};
    if (!m_reader.load(argv[1]))
        throw std::invalid_argument("Bad ELF filename");
    if (m_reader.get_class() != ELFIO::ELFCLASS32)
    {
        throw std::runtime_error("Wrong ELF file class.");
    }

    // Check for little-endian
    if (m_reader.get_encoding() != ELFIO::ELFDATA2LSB)
    {
        throw std::runtime_error("Wrong ELF encoding.");
    }
    ELFIO::Elf_Half seg_num = m_reader.segments.size();

    for (size_t seg_i = 0; seg_i < seg_num; ++seg_i)
    {
        const ELFIO::segment *segment = m_reader.segments[seg_i];
        if (segment->get_type() != ELFIO::PT_LOAD)
        {
            continue;
        }
        uint32_t address = segment->get_virtual_address();
 

        size_t filesz = static_cast<size_t>(segment->get_file_size());
        size_t memsz = static_cast<size_t>(segment->get_memory_size());
        if (filesz)
        {
            const auto *begin =
                reinterpret_cast<const uint8_t *>(segment->get_data());
            uint8_t *dst =
                reinterpret_cast<uint8_t *>(top_module->PipelineCPU->instr_memory->RAM);
            std::copy(begin, begin + filesz, dst + address);
        }
    }

    //top_module->PipelineCPU->main_pipeline->dp->rf->rf[0x02] = 0x100000; // stack pointer

    top_module->PipelineCPU->PCF = m_reader.get_entry();
    printf("PC: %d %ld\n", top_module->PipelineCPU->PCF, m_reader.get_entry());

    run_test(top_module, vcd);

    printf("Success!\n");

    return 0;
}