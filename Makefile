V_FLAG = --cc --exe --build -Wall
INCDIR = -I./tb/ \
	-I./vsrc/\
	-I./vsrc/pipereg\
	-I./vsrc/backend\
	-I./vsrc/backend/decode\
	-I./vsrc/backend/rename\
	-I./vsrc/backend/issue\
	-I./vsrc/backend/fu\
	-I./vsrc/backend/dispatch\
	-I./vsrc/frontend\
	-I./vsrc/include/\
	-I./build/rtl
SIM_CPP = ./csrc/sim.cpp
CSRC = ./csrc/dpic.cpp
# REF = $(NOOP_HOME)/r2r/riscv64-nemu-interpreter-so
REF = $(NOOP_HOME)/r2r/tri-riscv64-nemu-interpreter-so

BIN = $(NOOP_HOME)/r2r/cmark/coremark-riscv64-nutshell-2.bin
WAVE_PATH = $(NOOP_HOME)/dump/sim.vcd

B ?= 0
E ?= 241022
sim-verilog:
	echo NULL



test_sim:
	verilator $(V_FLAG) -j 32 $(SIM_CPP) $(CSRC) tb_top.v $(INCDIR) --trace

test_run: test_sim
	./obj_dir/Vtb_top

vcd:
	gtkwave ./dump/sim.vcd

diff: 
	cd difftest_trinity && make emu WITH_CHISELDB=0 WITH_CONSTANTIN=0 -j 32 EMU_TRACE=fst RELEASE=1

run_diff: diff
	./build/emu --diff=$(REF)  --dump-wave-full --wave-path=$(WAVE_PATH) -b $(B) -e $(E) --image=$(BIN)

strace:
	strace -e trace=open ./build/emu --diff=$(REF)  --dump-wave-full --wave-path=$(WAVE_PATH) -b 0 -e 5120 --image=$(BIN)

clean:
	rm -rf build/emu-compile build/emu time.log obj_dir/**