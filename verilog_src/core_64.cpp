#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <vector>



#include </home/hollbrok/prog/elfio-3.12/elfio/elfio.hpp>
#include <vector>
#include <iostream>
#include <cstdint>

namespace elf64_parser {

struct Elf64Seg {
    size_t start_addr;
    std::vector<uint32_t> data;
};

struct Elf64Data {
    size_t entry;
    std::vector<Elf64Seg> segs;
};

ELFIO::elfio get_riscv64_elf_reader(const std::string& filename)
{
    ELFIO::elfio reader;
    reader.load(filename);

    if (reader.get_class() != ELFIO::ELFCLASS64) {
        std::cerr << "Executable must be ELF64 class" << std::endl;
    }

    if (reader.get_machine() != ELFIO::EM_RISCV) {
        std::cerr << "Machine must be RISC-V" << std::endl;
    }

    return reader;
}

ELFIO::Elf64_Addr load_riscv64_elf(const std::string &filename, void *dst_data)
{
    ELFIO::elfio reader = get_riscv64_elf_reader(filename);

    ELFIO::Elf_Half n_segments = reader.segments.size();
    for (size_t i = 0; i < n_segments; ++i) {
        const ELFIO::segment *pseg = reader.segments[i];
        const void *seg_data = pseg->get_data();
        size_t file_size = pseg->get_file_size();
        size_t start_addr = pseg->get_virtual_address();

        std::memcpy(static_cast<uint8_t *>(dst_data) + start_addr, seg_data, file_size);
    }

    return reader.get_entry();
}

Elf64Data get_riscv64_elf_data(const std::string &filename)
{
    ELFIO::elfio reader = get_riscv64_elf_reader(filename);
    Elf64Data elf_data;

    elf_data.entry = reader.get_entry();

    ELFIO::Elf_Half n_segments = reader.segments.size();
    for (size_t i = 0; i < n_segments; ++i) {
        const ELFIO::segment* pseg = reader.segments[i];
        const void *seg_data = pseg->get_data();
        uint32_t file_size = pseg->get_file_size();
        uint32_t start_addr = pseg->get_virtual_address();

        std::vector<uint32_t> seg_data_v(file_size / sizeof(uint32_t));
        std::memcpy(seg_data_v.data(), seg_data, file_size);

        Elf64Seg seg_info { start_addr, std::move(seg_data_v) };
        elf_data.segs.push_back(std::move(seg_info));
    }

    return elf_data;
}

} // namespace elf64_parser












#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VPipeline_CPU.h"
// #include "VPipeline_CPU_PipelineCPU.h"
// #include "VPipeline_CPU_memory.h"
// #include "VPipeline_CPU_pc.h"
// #include "VPipeline_CPU_reg_file.h"

vluint64_t sim_time = 0;

void run_test(VPipeline_CPU *core, VerilatedVcdC *trace, elf64_parser::Elf64Data *elf_data);

int main(int argc, char *argv[])
{
    if (argc < 2) {
        std::cerr << "Required filename argument with binary file" << std::endl;
        exit(EXIT_FAILURE);
    }

    VPipeline_CPU *core = new VPipeline_CPU;

    Verilated::traceEverOn(true);
    VerilatedVcdC *trace = new VerilatedVcdC;
    core->trace(trace, 5);
    trace->open("waveform.vcd");

    elf64_parser::Elf64Data elf_data = elf64_parser::get_riscv64_elf_data(argv[1]);
    run_test(core, trace, &elf_data);

    trace->close();
    delete core;
    exit(EXIT_SUCCESS);
}

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

void n_cycles(VPipeline_CPU *core, VerilatedVcdC *trace, size_t n_cycles)
{
    for (size_t i = 0; i < n_cycles; ++i) {
        cycle(core, trace);
    }
}

size_t get_segment_by_addr(const elf64_parser::Elf64Data &elf_data, size_t entry_point)
{
    for (size_t i = 0; i < elf_data.segs.size(); ++i) {
        if (entry_point >= elf_data.segs[i].start_addr &&
            entry_point < (elf_data.segs[i].start_addr +
                           elf_data.segs[i].data.size() * sizeof(uint32_t)))
            return i;
    }

    return -1;
}

void run_test(VPipeline_CPU *core, VerilatedVcdC *trace, elf64_parser::Elf64Data *elf_data)
{
    size_t code_segment = get_segment_by_addr(*elf_data, elf_data->entry);
    std::memcpy(reinterpret_cast<uint8_t *>(&core->core->instr_memory->buffer.m_storage) +
                elf_data->segs[code_segment].start_addr,
                elf_data->segs[code_segment].data.data(),
                elf_data->segs[code_segment].data.size() * sizeof(uint32_t));

    core->core->reg_file->file[0x02] = 0x100000; // stack pointer
    core->core->pc->pc_val = elf_data->entry;

    //do {
    //    cycle(core, trace);
    //} while (core->core->exception_execute == 0);
}
