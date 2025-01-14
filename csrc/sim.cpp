#include "Vtb_top.h"
#include "verilated.h"
#include <stdio.h>
#include "verilated_vcd_c.h"
Vtb_top *top = NULL;
VerilatedContext *contextp = NULL;
VerilatedVcdC *vcd = NULL;
void init(int argc, char **argv)
{
    contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    top = new Vtb_top{contextp};
    vcd = new VerilatedVcdC;

    // trace relevent
    Verilated::traceEverOn(true);

    // dump level
    top->trace(vcd, 99);
    vcd->open("dump/sim.vcd");

    top->clock = 0;

}
void reset()
{
    int rst_cnt = 5;
    while (rst_cnt != 0)
    {
        contextp->timeInc(1);
        top->reset_n = 0;
        top->clock = !top->clock;
        top->eval();

        vcd->dump(contextp->time());
        rst_cnt -= 1;
    }
    top->reset_n = 1;
    top->eval();
}
int main(int argc, char **argv)
{


    init(argc, argv);
    reset();
    int cnt = 0;
    while (/*!contextp->gotFinish() ||*/ cnt <= 20)
    {
        contextp->timeInc(1);
        top->a = 4;
        top->clock = !top->clock;
        top->eval();
        vcd->dump(contextp->time());
        cnt += 1;
    }
    delete top;
    delete contextp;
    vcd->close();
    return 0;
}