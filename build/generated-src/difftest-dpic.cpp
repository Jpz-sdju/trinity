#ifndef CONFIG_NO_DIFFTEST

#include "difftest.h"
#include "difftest-dpic.h"


DiffStateBuffer** diffstate_buffer = nullptr;
#define DUT_BUF(core_id, zone, index) (diffstate_buffer[core_id]->get(zone, index))

void diffstate_buffer_init() {
  diffstate_buffer = new DiffStateBuffer*[NUM_CORES];
  for (int i = 0; i < NUM_CORES; i++) {
    diffstate_buffer[i] = new DPICBuffer;
  }
}

void diffstate_buffer_free() {
  for (int i = 0; i < NUM_CORES; i++) {
    delete diffstate_buffer[i];
  }
  delete[] diffstate_buffer;
  diffstate_buffer = nullptr;
}
      

#ifdef CONFIG_DIFFTEST_PERFCNT
void diffstate_perfcnt_init() {
  for (int i = 0; i < DIFFSTATE_PERF_NUM; i++) {
    dpic_calls[i] = 0;
    dpic_bytes[i] = 0;
  }
}
void diffstate_perfcnt_finish(long long msec) {
  long long calls_sum = 0, bytes_sum = 0;
  const char *dpic_name[DIFFSTATE_PERF_NUM] = {
    "v_difftest_ArchEvent",
    "v_difftest_InstrCommit",
    "v_difftest_TrapEvent",
    "v_difftest_CSRState",
    "v_difftest_HCSRState",
    "v_difftest_DebugMode",
    "v_difftest_TriggerCSRState",
    "v_difftest_ArchVecRegState",
    "v_difftest_VecCSRState",
    "v_difftest_FpCSRState",
    "v_difftest_IntWriteback",
    "v_difftest_FpWriteback",
    "v_difftest_VecWriteback",
    "v_difftest_ArchIntRegState",
    "v_difftest_ArchFpRegState",
    "v_difftest_SbufferEvent",
    "v_difftest_StoreEvent",
    "v_difftest_LoadEvent",
    "v_difftest_AtomicEvent",
    "v_difftest_L1TLBEvent",
    "v_difftest_L2TLBEvent",
    "v_difftest_RefillEvent",
    "v_difftest_LrScEvent",
    "v_difftest_RunaheadEvent",
    "v_difftest_RunaheadCommitEvent",
    "v_difftest_RunaheadRedirectEvent"
  };
  for (int i = 0; i < DIFFSTATE_PERF_NUM; i++) {
    calls_sum += dpic_calls[i];
    bytes_sum += dpic_bytes[i];
    difftest_perfcnt_print(dpic_name[i], dpic_calls[i], dpic_bytes[i], msec);
  }
  difftest_perfcnt_print("DIFFSTATE_SUM", calls_sum, bytes_sum, msec);
}
#endif // CONFIG_DIFFTEST_PERFCNT



extern "C" void v_difftest_ArchEvent (
  uint32_t io_interrupt,
  uint32_t io_exception,
  uint64_t io_exceptionPC,
  uint32_t io_exceptionInst,
  uint8_t  io_hasNMI,
  uint8_t  io_virtualInterruptIsHvictlInject,
  uint8_t  io_coreid
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_ArchEvent] ++;
  dpic_bytes[perf_v_difftest_ArchEvent] += 21;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->event);
  packet->valid = true;
  packet->interrupt = io_interrupt;
  packet->exception = io_exception;
  packet->exceptionPC = io_exceptionPC;
  packet->exceptionInst = io_exceptionInst;
  packet->hasNMI = io_hasNMI;
  packet->virtualInterruptIsHvictlInject = io_virtualInterruptIsHvictlInject;
  
}


extern "C" void v_difftest_InstrCommit (
  uint8_t  io_skip,
  uint8_t  io_isRVC,
  uint8_t  io_rfwen,
  uint8_t  io_fpwen,
  uint8_t  io_vecwen,
  uint8_t  io_wpdest,
  uint8_t  io_wdest,
  uint64_t io_pc,
  uint32_t io_instr,
  uint32_t io_robIdx,
  uint8_t  io_lqIdx,
  uint8_t  io_sqIdx,
  uint8_t  io_isLoad,
  uint8_t  io_isStore,
  uint8_t  io_nFused,
  uint8_t  io_special,
  uint8_t  io_coreid,
  uint8_t  io_index
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_InstrCommit] ++;
  dpic_bytes[perf_v_difftest_InstrCommit] += 18;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->commit[io_index]);
  packet->valid = true;
  packet->skip = io_skip;
  packet->isRVC = io_isRVC;
  packet->rfwen = io_rfwen;
  packet->fpwen = io_fpwen;
  packet->vecwen = io_vecwen;
  packet->wpdest = io_wpdest;
  packet->wdest = io_wdest;
  packet->pc = io_pc;
  packet->instr = io_instr;
  packet->robIdx = io_robIdx;
  packet->lqIdx = io_lqIdx;
  packet->sqIdx = io_sqIdx;
  packet->isLoad = io_isLoad;
  packet->isStore = io_isStore;
  packet->nFused = io_nFused;
  packet->special = io_special;
  
}


extern "C" void v_difftest_TrapEvent (
  uint8_t  io_hasTrap,
  uint64_t io_cycleCnt,
  uint64_t io_instrCnt,
  uint8_t  io_hasWFI,
  uint32_t io_code,
  uint64_t io_pc,
  uint8_t  io_coreid
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_TrapEvent] ++;
  dpic_bytes[perf_v_difftest_TrapEvent] += 29;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->trap);
  packet->hasTrap = io_hasTrap;
  packet->cycleCnt = io_cycleCnt;
  packet->instrCnt = io_instrCnt;
  packet->hasWFI = io_hasWFI;
  packet->code = io_code;
  packet->pc = io_pc;
  
}


extern "C" void v_difftest_CSRState (
  uint64_t io_privilegeMode,
  uint64_t io_mstatus,
  uint64_t io_sstatus,
  uint64_t io_mepc,
  uint64_t io_sepc,
  uint64_t io_mtval,
  uint64_t io_stval,
  uint64_t io_mtvec,
  uint64_t io_stvec,
  uint64_t io_mcause,
  uint64_t io_scause,
  uint64_t io_satp,
  uint64_t io_mip,
  uint64_t io_mie,
  uint64_t io_mscratch,
  uint64_t io_sscratch,
  uint64_t io_mideleg,
  uint64_t io_medeleg,
  uint8_t  io_coreid
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_CSRState] ++;
  dpic_bytes[perf_v_difftest_CSRState] += 145;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->csr);
  packet->privilegeMode = io_privilegeMode;
  packet->mstatus = io_mstatus;
  packet->sstatus = io_sstatus;
  packet->mepc = io_mepc;
  packet->sepc = io_sepc;
  packet->mtval = io_mtval;
  packet->stval = io_stval;
  packet->mtvec = io_mtvec;
  packet->stvec = io_stvec;
  packet->mcause = io_mcause;
  packet->scause = io_scause;
  packet->satp = io_satp;
  packet->mip = io_mip;
  packet->mie = io_mie;
  packet->mscratch = io_mscratch;
  packet->sscratch = io_sscratch;
  packet->mideleg = io_mideleg;
  packet->medeleg = io_medeleg;
  
}


extern "C" void v_difftest_HCSRState (
  uint64_t io_virtMode,
  uint64_t io_mtval2,
  uint64_t io_mtinst,
  uint64_t io_hstatus,
  uint64_t io_hideleg,
  uint64_t io_hedeleg,
  uint64_t io_hcounteren,
  uint64_t io_htval,
  uint64_t io_htinst,
  uint64_t io_hgatp,
  uint64_t io_vsstatus,
  uint64_t io_vstvec,
  uint64_t io_vsepc,
  uint64_t io_vscause,
  uint64_t io_vstval,
  uint64_t io_vsatp,
  uint64_t io_vsscratch,
  uint8_t  io_coreid
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_HCSRState] ++;
  dpic_bytes[perf_v_difftest_HCSRState] += 137;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->hcsr);
  packet->virtMode = io_virtMode;
  packet->mtval2 = io_mtval2;
  packet->mtinst = io_mtinst;
  packet->hstatus = io_hstatus;
  packet->hideleg = io_hideleg;
  packet->hedeleg = io_hedeleg;
  packet->hcounteren = io_hcounteren;
  packet->htval = io_htval;
  packet->htinst = io_htinst;
  packet->hgatp = io_hgatp;
  packet->vsstatus = io_vsstatus;
  packet->vstvec = io_vstvec;
  packet->vsepc = io_vsepc;
  packet->vscause = io_vscause;
  packet->vstval = io_vstval;
  packet->vsatp = io_vsatp;
  packet->vsscratch = io_vsscratch;
  
}


extern "C" void v_difftest_DebugMode (
  uint8_t  io_debugMode,
  uint64_t io_dcsr,
  uint64_t io_dpc,
  uint64_t io_dscratch0,
  uint64_t io_dscratch1,
  uint8_t  io_coreid
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_DebugMode] ++;
  dpic_bytes[perf_v_difftest_DebugMode] += 33;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->dmregs);
  packet->debugMode = io_debugMode;
  packet->dcsr = io_dcsr;
  packet->dpc = io_dpc;
  packet->dscratch0 = io_dscratch0;
  packet->dscratch1 = io_dscratch1;
  
}


extern "C" void v_difftest_TriggerCSRState (
  uint64_t io_tselect,
  uint64_t io_tdata1,
  uint64_t io_tinfo,
  uint64_t io_tcontrol,
  uint8_t  io_coreid
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_TriggerCSRState] ++;
  dpic_bytes[perf_v_difftest_TriggerCSRState] += 33;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->triggercsr);
  packet->tselect = io_tselect;
  packet->tdata1 = io_tdata1;
  packet->tinfo = io_tinfo;
  packet->tcontrol = io_tcontrol;
  
}


extern "C" void v_difftest_ArchVecRegState (
  uint64_t io_value_0,
  uint64_t io_value_1,
  uint64_t io_value_2,
  uint64_t io_value_3,
  uint64_t io_value_4,
  uint64_t io_value_5,
  uint64_t io_value_6,
  uint64_t io_value_7,
  uint64_t io_value_8,
  uint64_t io_value_9,
  uint64_t io_value_10,
  uint64_t io_value_11,
  uint64_t io_value_12,
  uint64_t io_value_13,
  uint64_t io_value_14,
  uint64_t io_value_15,
  uint64_t io_value_16,
  uint64_t io_value_17,
  uint64_t io_value_18,
  uint64_t io_value_19,
  uint64_t io_value_20,
  uint64_t io_value_21,
  uint64_t io_value_22,
  uint64_t io_value_23,
  uint64_t io_value_24,
  uint64_t io_value_25,
  uint64_t io_value_26,
  uint64_t io_value_27,
  uint64_t io_value_28,
  uint64_t io_value_29,
  uint64_t io_value_30,
  uint64_t io_value_31,
  uint64_t io_value_32,
  uint64_t io_value_33,
  uint64_t io_value_34,
  uint64_t io_value_35,
  uint64_t io_value_36,
  uint64_t io_value_37,
  uint64_t io_value_38,
  uint64_t io_value_39,
  uint64_t io_value_40,
  uint64_t io_value_41,
  uint64_t io_value_42,
  uint64_t io_value_43,
  uint64_t io_value_44,
  uint64_t io_value_45,
  uint64_t io_value_46,
  uint64_t io_value_47,
  uint64_t io_value_48,
  uint64_t io_value_49,
  uint64_t io_value_50,
  uint64_t io_value_51,
  uint64_t io_value_52,
  uint64_t io_value_53,
  uint64_t io_value_54,
  uint64_t io_value_55,
  uint64_t io_value_56,
  uint64_t io_value_57,
  uint64_t io_value_58,
  uint64_t io_value_59,
  uint64_t io_value_60,
  uint64_t io_value_61,
  uint64_t io_value_62,
  uint64_t io_value_63,
  uint8_t  io_coreid
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_ArchVecRegState] ++;
  dpic_bytes[perf_v_difftest_ArchVecRegState] += 513;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->regs_vec);
  packet->value[0] = io_value_0;
  packet->value[1] = io_value_1;
  packet->value[2] = io_value_2;
  packet->value[3] = io_value_3;
  packet->value[4] = io_value_4;
  packet->value[5] = io_value_5;
  packet->value[6] = io_value_6;
  packet->value[7] = io_value_7;
  packet->value[8] = io_value_8;
  packet->value[9] = io_value_9;
  packet->value[10] = io_value_10;
  packet->value[11] = io_value_11;
  packet->value[12] = io_value_12;
  packet->value[13] = io_value_13;
  packet->value[14] = io_value_14;
  packet->value[15] = io_value_15;
  packet->value[16] = io_value_16;
  packet->value[17] = io_value_17;
  packet->value[18] = io_value_18;
  packet->value[19] = io_value_19;
  packet->value[20] = io_value_20;
  packet->value[21] = io_value_21;
  packet->value[22] = io_value_22;
  packet->value[23] = io_value_23;
  packet->value[24] = io_value_24;
  packet->value[25] = io_value_25;
  packet->value[26] = io_value_26;
  packet->value[27] = io_value_27;
  packet->value[28] = io_value_28;
  packet->value[29] = io_value_29;
  packet->value[30] = io_value_30;
  packet->value[31] = io_value_31;
  packet->value[32] = io_value_32;
  packet->value[33] = io_value_33;
  packet->value[34] = io_value_34;
  packet->value[35] = io_value_35;
  packet->value[36] = io_value_36;
  packet->value[37] = io_value_37;
  packet->value[38] = io_value_38;
  packet->value[39] = io_value_39;
  packet->value[40] = io_value_40;
  packet->value[41] = io_value_41;
  packet->value[42] = io_value_42;
  packet->value[43] = io_value_43;
  packet->value[44] = io_value_44;
  packet->value[45] = io_value_45;
  packet->value[46] = io_value_46;
  packet->value[47] = io_value_47;
  packet->value[48] = io_value_48;
  packet->value[49] = io_value_49;
  packet->value[50] = io_value_50;
  packet->value[51] = io_value_51;
  packet->value[52] = io_value_52;
  packet->value[53] = io_value_53;
  packet->value[54] = io_value_54;
  packet->value[55] = io_value_55;
  packet->value[56] = io_value_56;
  packet->value[57] = io_value_57;
  packet->value[58] = io_value_58;
  packet->value[59] = io_value_59;
  packet->value[60] = io_value_60;
  packet->value[61] = io_value_61;
  packet->value[62] = io_value_62;
  packet->value[63] = io_value_63;
  
}


extern "C" void v_difftest_VecCSRState (
  uint64_t io_vstart,
  uint64_t io_vxsat,
  uint64_t io_vxrm,
  uint64_t io_vcsr,
  uint64_t io_vl,
  uint64_t io_vtype,
  uint64_t io_vlenb,
  uint8_t  io_coreid
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_VecCSRState] ++;
  dpic_bytes[perf_v_difftest_VecCSRState] += 57;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->vcsr);
  packet->vstart = io_vstart;
  packet->vxsat = io_vxsat;
  packet->vxrm = io_vxrm;
  packet->vcsr = io_vcsr;
  packet->vl = io_vl;
  packet->vtype = io_vtype;
  packet->vlenb = io_vlenb;
  
}


extern "C" void v_difftest_FpCSRState (
  uint64_t io_fcsr,
  uint8_t  io_coreid
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_FpCSRState] ++;
  dpic_bytes[perf_v_difftest_FpCSRState] += 9;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->fcsr);
  packet->fcsr = io_fcsr;
  
}


extern "C" void v_difftest_IntWriteback (
  uint8_t  io_address,
  uint64_t io_data,
  uint8_t  io_coreid
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_IntWriteback] ++;
  dpic_bytes[perf_v_difftest_IntWriteback] += 9;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->wb_int[io_address]);
  packet->data = io_data;
  
}


extern "C" void v_difftest_FpWriteback (
  uint8_t  io_address,
  uint64_t io_data,
  uint8_t  io_coreid
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_FpWriteback] ++;
  dpic_bytes[perf_v_difftest_FpWriteback] += 9;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->wb_fp[io_address]);
  packet->data = io_data;
  
}


extern "C" void v_difftest_VecWriteback (
  uint8_t  io_address,
  uint64_t io_data,
  uint8_t  io_coreid
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_VecWriteback] ++;
  dpic_bytes[perf_v_difftest_VecWriteback] += 9;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->wb_vec[io_address]);
  packet->data = io_data;
  
}


extern "C" void v_difftest_ArchIntRegState (
  uint64_t io_value_0,
  uint64_t io_value_1,
  uint64_t io_value_2,
  uint64_t io_value_3,
  uint64_t io_value_4,
  uint64_t io_value_5,
  uint64_t io_value_6,
  uint64_t io_value_7,
  uint64_t io_value_8,
  uint64_t io_value_9,
  uint64_t io_value_10,
  uint64_t io_value_11,
  uint64_t io_value_12,
  uint64_t io_value_13,
  uint64_t io_value_14,
  uint64_t io_value_15,
  uint64_t io_value_16,
  uint64_t io_value_17,
  uint64_t io_value_18,
  uint64_t io_value_19,
  uint64_t io_value_20,
  uint64_t io_value_21,
  uint64_t io_value_22,
  uint64_t io_value_23,
  uint64_t io_value_24,
  uint64_t io_value_25,
  uint64_t io_value_26,
  uint64_t io_value_27,
  uint64_t io_value_28,
  uint64_t io_value_29,
  uint64_t io_value_30,
  uint64_t io_value_31,
  uint8_t  io_coreid
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_ArchIntRegState] ++;
  dpic_bytes[perf_v_difftest_ArchIntRegState] += 257;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->regs_int);
  packet->value[0] = io_value_0;
  packet->value[1] = io_value_1;
  packet->value[2] = io_value_2;
  packet->value[3] = io_value_3;
  packet->value[4] = io_value_4;
  packet->value[5] = io_value_5;
  packet->value[6] = io_value_6;
  packet->value[7] = io_value_7;
  packet->value[8] = io_value_8;
  packet->value[9] = io_value_9;
  packet->value[10] = io_value_10;
  packet->value[11] = io_value_11;
  packet->value[12] = io_value_12;
  packet->value[13] = io_value_13;
  packet->value[14] = io_value_14;
  packet->value[15] = io_value_15;
  packet->value[16] = io_value_16;
  packet->value[17] = io_value_17;
  packet->value[18] = io_value_18;
  packet->value[19] = io_value_19;
  packet->value[20] = io_value_20;
  packet->value[21] = io_value_21;
  packet->value[22] = io_value_22;
  packet->value[23] = io_value_23;
  packet->value[24] = io_value_24;
  packet->value[25] = io_value_25;
  packet->value[26] = io_value_26;
  packet->value[27] = io_value_27;
  packet->value[28] = io_value_28;
  packet->value[29] = io_value_29;
  packet->value[30] = io_value_30;
  packet->value[31] = io_value_31;
  
}


extern "C" void v_difftest_ArchFpRegState (
  uint64_t io_value_0,
  uint64_t io_value_1,
  uint64_t io_value_2,
  uint64_t io_value_3,
  uint64_t io_value_4,
  uint64_t io_value_5,
  uint64_t io_value_6,
  uint64_t io_value_7,
  uint64_t io_value_8,
  uint64_t io_value_9,
  uint64_t io_value_10,
  uint64_t io_value_11,
  uint64_t io_value_12,
  uint64_t io_value_13,
  uint64_t io_value_14,
  uint64_t io_value_15,
  uint64_t io_value_16,
  uint64_t io_value_17,
  uint64_t io_value_18,
  uint64_t io_value_19,
  uint64_t io_value_20,
  uint64_t io_value_21,
  uint64_t io_value_22,
  uint64_t io_value_23,
  uint64_t io_value_24,
  uint64_t io_value_25,
  uint64_t io_value_26,
  uint64_t io_value_27,
  uint64_t io_value_28,
  uint64_t io_value_29,
  uint64_t io_value_30,
  uint64_t io_value_31,
  uint8_t  io_coreid
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_ArchFpRegState] ++;
  dpic_bytes[perf_v_difftest_ArchFpRegState] += 257;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->regs_fp);
  packet->value[0] = io_value_0;
  packet->value[1] = io_value_1;
  packet->value[2] = io_value_2;
  packet->value[3] = io_value_3;
  packet->value[4] = io_value_4;
  packet->value[5] = io_value_5;
  packet->value[6] = io_value_6;
  packet->value[7] = io_value_7;
  packet->value[8] = io_value_8;
  packet->value[9] = io_value_9;
  packet->value[10] = io_value_10;
  packet->value[11] = io_value_11;
  packet->value[12] = io_value_12;
  packet->value[13] = io_value_13;
  packet->value[14] = io_value_14;
  packet->value[15] = io_value_15;
  packet->value[16] = io_value_16;
  packet->value[17] = io_value_17;
  packet->value[18] = io_value_18;
  packet->value[19] = io_value_19;
  packet->value[20] = io_value_20;
  packet->value[21] = io_value_21;
  packet->value[22] = io_value_22;
  packet->value[23] = io_value_23;
  packet->value[24] = io_value_24;
  packet->value[25] = io_value_25;
  packet->value[26] = io_value_26;
  packet->value[27] = io_value_27;
  packet->value[28] = io_value_28;
  packet->value[29] = io_value_29;
  packet->value[30] = io_value_30;
  packet->value[31] = io_value_31;
  
}


extern "C" void v_difftest_SbufferEvent (
  uint64_t io_addr,
  uint8_t  io_data_0,
  uint8_t  io_data_1,
  uint8_t  io_data_2,
  uint8_t  io_data_3,
  uint8_t  io_data_4,
  uint8_t  io_data_5,
  uint8_t  io_data_6,
  uint8_t  io_data_7,
  uint8_t  io_data_8,
  uint8_t  io_data_9,
  uint8_t  io_data_10,
  uint8_t  io_data_11,
  uint8_t  io_data_12,
  uint8_t  io_data_13,
  uint8_t  io_data_14,
  uint8_t  io_data_15,
  uint8_t  io_data_16,
  uint8_t  io_data_17,
  uint8_t  io_data_18,
  uint8_t  io_data_19,
  uint8_t  io_data_20,
  uint8_t  io_data_21,
  uint8_t  io_data_22,
  uint8_t  io_data_23,
  uint8_t  io_data_24,
  uint8_t  io_data_25,
  uint8_t  io_data_26,
  uint8_t  io_data_27,
  uint8_t  io_data_28,
  uint8_t  io_data_29,
  uint8_t  io_data_30,
  uint8_t  io_data_31,
  uint8_t  io_data_32,
  uint8_t  io_data_33,
  uint8_t  io_data_34,
  uint8_t  io_data_35,
  uint8_t  io_data_36,
  uint8_t  io_data_37,
  uint8_t  io_data_38,
  uint8_t  io_data_39,
  uint8_t  io_data_40,
  uint8_t  io_data_41,
  uint8_t  io_data_42,
  uint8_t  io_data_43,
  uint8_t  io_data_44,
  uint8_t  io_data_45,
  uint8_t  io_data_46,
  uint8_t  io_data_47,
  uint8_t  io_data_48,
  uint8_t  io_data_49,
  uint8_t  io_data_50,
  uint8_t  io_data_51,
  uint8_t  io_data_52,
  uint8_t  io_data_53,
  uint8_t  io_data_54,
  uint8_t  io_data_55,
  uint8_t  io_data_56,
  uint8_t  io_data_57,
  uint8_t  io_data_58,
  uint8_t  io_data_59,
  uint8_t  io_data_60,
  uint8_t  io_data_61,
  uint8_t  io_data_62,
  uint8_t  io_data_63,
  uint64_t io_mask,
  uint8_t  io_coreid,
  uint8_t  io_index
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_SbufferEvent] ++;
  dpic_bytes[perf_v_difftest_SbufferEvent] += 82;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->sbuffer[io_index]);
  packet->valid = true;
  packet->addr = io_addr;
  packet->data[0] = io_data_0;
  packet->data[1] = io_data_1;
  packet->data[2] = io_data_2;
  packet->data[3] = io_data_3;
  packet->data[4] = io_data_4;
  packet->data[5] = io_data_5;
  packet->data[6] = io_data_6;
  packet->data[7] = io_data_7;
  packet->data[8] = io_data_8;
  packet->data[9] = io_data_9;
  packet->data[10] = io_data_10;
  packet->data[11] = io_data_11;
  packet->data[12] = io_data_12;
  packet->data[13] = io_data_13;
  packet->data[14] = io_data_14;
  packet->data[15] = io_data_15;
  packet->data[16] = io_data_16;
  packet->data[17] = io_data_17;
  packet->data[18] = io_data_18;
  packet->data[19] = io_data_19;
  packet->data[20] = io_data_20;
  packet->data[21] = io_data_21;
  packet->data[22] = io_data_22;
  packet->data[23] = io_data_23;
  packet->data[24] = io_data_24;
  packet->data[25] = io_data_25;
  packet->data[26] = io_data_26;
  packet->data[27] = io_data_27;
  packet->data[28] = io_data_28;
  packet->data[29] = io_data_29;
  packet->data[30] = io_data_30;
  packet->data[31] = io_data_31;
  packet->data[32] = io_data_32;
  packet->data[33] = io_data_33;
  packet->data[34] = io_data_34;
  packet->data[35] = io_data_35;
  packet->data[36] = io_data_36;
  packet->data[37] = io_data_37;
  packet->data[38] = io_data_38;
  packet->data[39] = io_data_39;
  packet->data[40] = io_data_40;
  packet->data[41] = io_data_41;
  packet->data[42] = io_data_42;
  packet->data[43] = io_data_43;
  packet->data[44] = io_data_44;
  packet->data[45] = io_data_45;
  packet->data[46] = io_data_46;
  packet->data[47] = io_data_47;
  packet->data[48] = io_data_48;
  packet->data[49] = io_data_49;
  packet->data[50] = io_data_50;
  packet->data[51] = io_data_51;
  packet->data[52] = io_data_52;
  packet->data[53] = io_data_53;
  packet->data[54] = io_data_54;
  packet->data[55] = io_data_55;
  packet->data[56] = io_data_56;
  packet->data[57] = io_data_57;
  packet->data[58] = io_data_58;
  packet->data[59] = io_data_59;
  packet->data[60] = io_data_60;
  packet->data[61] = io_data_61;
  packet->data[62] = io_data_62;
  packet->data[63] = io_data_63;
  packet->mask = io_mask;
  
}


extern "C" void v_difftest_StoreEvent (
  uint64_t io_addr,
  uint64_t io_data,
  uint8_t  io_mask,
  uint8_t  io_coreid,
  uint8_t  io_index
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_StoreEvent] ++;
  dpic_bytes[perf_v_difftest_StoreEvent] += 19;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->store[io_index]);
  packet->valid = true;
  packet->addr = io_addr;
  packet->data = io_data;
  packet->mask = io_mask;
  
}


extern "C" void v_difftest_LoadEvent (
  uint64_t io_paddr,
  uint8_t  io_opType,
  uint8_t  io_isAtomic,
  uint8_t  io_isLoad,
  uint8_t  io_coreid,
  uint8_t  io_index
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_LoadEvent] ++;
  dpic_bytes[perf_v_difftest_LoadEvent] += 11;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->load[io_index]);
  packet->valid = true;
  packet->paddr = io_paddr;
  packet->opType = io_opType;
  packet->isAtomic = io_isAtomic;
  packet->isLoad = io_isLoad;
  
}


extern "C" void v_difftest_AtomicEvent (
  uint64_t io_addr,
  uint64_t io_data,
  uint8_t  io_mask,
  uint8_t  io_fuop,
  uint64_t io_out,
  uint8_t  io_coreid
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_AtomicEvent] ++;
  dpic_bytes[perf_v_difftest_AtomicEvent] += 27;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->atomic);
  packet->valid = true;
  packet->addr = io_addr;
  packet->data = io_data;
  packet->mask = io_mask;
  packet->fuop = io_fuop;
  packet->out = io_out;
  
}


extern "C" void v_difftest_L1TLBEvent (
  uint64_t io_satp,
  uint64_t io_vpn,
  uint64_t io_ppn,
  uint64_t io_vsatp,
  uint64_t io_hgatp,
  uint8_t  io_s2xlate,
  uint8_t  io_coreid,
  uint8_t  io_index
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_L1TLBEvent] ++;
  dpic_bytes[perf_v_difftest_L1TLBEvent] += 42;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->l1tlb[io_index]);
  packet->valid = true;
  packet->satp = io_satp;
  packet->vpn = io_vpn;
  packet->ppn = io_ppn;
  packet->vsatp = io_vsatp;
  packet->hgatp = io_hgatp;
  packet->s2xlate = io_s2xlate;
  
}


extern "C" void v_difftest_L2TLBEvent (
  uint8_t  io_valididx_0,
  uint8_t  io_valididx_1,
  uint8_t  io_valididx_2,
  uint8_t  io_valididx_3,
  uint8_t  io_valididx_4,
  uint8_t  io_valididx_5,
  uint8_t  io_valididx_6,
  uint8_t  io_valididx_7,
  uint64_t io_satp,
  uint64_t io_vpn,
  uint8_t  io_pbmt,
  uint8_t  io_g_pbmt,
  uint64_t io_ppn_0,
  uint64_t io_ppn_1,
  uint64_t io_ppn_2,
  uint64_t io_ppn_3,
  uint64_t io_ppn_4,
  uint64_t io_ppn_5,
  uint64_t io_ppn_6,
  uint64_t io_ppn_7,
  uint8_t  io_perm,
  uint8_t  io_level,
  uint8_t  io_pf,
  uint8_t  io_pteidx_0,
  uint8_t  io_pteidx_1,
  uint8_t  io_pteidx_2,
  uint8_t  io_pteidx_3,
  uint8_t  io_pteidx_4,
  uint8_t  io_pteidx_5,
  uint8_t  io_pteidx_6,
  uint8_t  io_pteidx_7,
  uint64_t io_vsatp,
  uint64_t io_hgatp,
  uint64_t io_gvpn,
  uint8_t  io_g_perm,
  uint8_t  io_g_level,
  uint64_t io_s2ppn,
  uint8_t  io_gpf,
  uint8_t  io_s2xlate,
  uint8_t  io_coreid,
  uint8_t  io_index
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_L2TLBEvent] ++;
  dpic_bytes[perf_v_difftest_L2TLBEvent] += 118;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->l2tlb[io_index]);
  packet->valid = true;
  packet->valididx[0] = io_valididx_0;
  packet->valididx[1] = io_valididx_1;
  packet->valididx[2] = io_valididx_2;
  packet->valididx[3] = io_valididx_3;
  packet->valididx[4] = io_valididx_4;
  packet->valididx[5] = io_valididx_5;
  packet->valididx[6] = io_valididx_6;
  packet->valididx[7] = io_valididx_7;
  packet->satp = io_satp;
  packet->vpn = io_vpn;
  packet->pbmt = io_pbmt;
  packet->g_pbmt = io_g_pbmt;
  packet->ppn[0] = io_ppn_0;
  packet->ppn[1] = io_ppn_1;
  packet->ppn[2] = io_ppn_2;
  packet->ppn[3] = io_ppn_3;
  packet->ppn[4] = io_ppn_4;
  packet->ppn[5] = io_ppn_5;
  packet->ppn[6] = io_ppn_6;
  packet->ppn[7] = io_ppn_7;
  packet->perm = io_perm;
  packet->level = io_level;
  packet->pf = io_pf;
  packet->pteidx[0] = io_pteidx_0;
  packet->pteidx[1] = io_pteidx_1;
  packet->pteidx[2] = io_pteidx_2;
  packet->pteidx[3] = io_pteidx_3;
  packet->pteidx[4] = io_pteidx_4;
  packet->pteidx[5] = io_pteidx_5;
  packet->pteidx[6] = io_pteidx_6;
  packet->pteidx[7] = io_pteidx_7;
  packet->vsatp = io_vsatp;
  packet->hgatp = io_hgatp;
  packet->gvpn = io_gvpn;
  packet->g_perm = io_g_perm;
  packet->g_level = io_g_level;
  packet->s2ppn = io_s2ppn;
  packet->gpf = io_gpf;
  packet->s2xlate = io_s2xlate;
  
}


extern "C" void v_difftest_RefillEvent (
  uint64_t io_addr,
  uint64_t io_data_0,
  uint64_t io_data_1,
  uint64_t io_data_2,
  uint64_t io_data_3,
  uint64_t io_data_4,
  uint64_t io_data_5,
  uint64_t io_data_6,
  uint64_t io_data_7,
  uint8_t  io_idtfr,
  uint8_t  io_coreid,
  uint8_t  io_index
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_RefillEvent] ++;
  dpic_bytes[perf_v_difftest_RefillEvent] += 75;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->refill[io_index]);
  packet->valid = true;
  packet->addr = io_addr;
  packet->data[0] = io_data_0;
  packet->data[1] = io_data_1;
  packet->data[2] = io_data_2;
  packet->data[3] = io_data_3;
  packet->data[4] = io_data_4;
  packet->data[5] = io_data_5;
  packet->data[6] = io_data_6;
  packet->data[7] = io_data_7;
  packet->idtfr = io_idtfr;
  
}


extern "C" void v_difftest_LrScEvent (
  uint8_t  io_success,
  uint8_t  io_coreid
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_LrScEvent] ++;
  dpic_bytes[perf_v_difftest_LrScEvent] += 1;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->lrsc);
  packet->valid = true;
  packet->success = io_success;
  
}


extern "C" void v_difftest_RunaheadEvent (
  uint8_t  io_branch,
  uint8_t  io_may_replay,
  uint64_t io_pc,
  uint64_t io_checkpoint_id,
  uint8_t  io_coreid,
  uint8_t  io_index
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_RunaheadEvent] ++;
  dpic_bytes[perf_v_difftest_RunaheadEvent] += 18;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->runahead[io_index]);
  packet->valid = true;
  packet->branch = io_branch;
  packet->may_replay = io_may_replay;
  packet->pc = io_pc;
  packet->checkpoint_id = io_checkpoint_id;
  
}


extern "C" void v_difftest_RunaheadCommitEvent (
  uint8_t  io_branch,
  uint8_t  io_may_replay,
  uint64_t io_pc,
  uint64_t io_checkpoint_id,
  uint8_t  io_coreid,
  uint8_t  io_index
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_RunaheadCommitEvent] ++;
  dpic_bytes[perf_v_difftest_RunaheadCommitEvent] += 18;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->runahead_commit[io_index]);
  packet->valid = true;
  packet->branch = io_branch;
  packet->may_replay = io_may_replay;
  packet->pc = io_pc;
  packet->checkpoint_id = io_checkpoint_id;
  
}


extern "C" void v_difftest_RunaheadRedirectEvent (
  uint64_t io_pc,
  uint64_t io_target_pc,
  uint64_t io_checkpoint_id,
  uint8_t  io_coreid
) {
  if (!diffstate_buffer) return;

#ifdef CONFIG_DIFFTEST_PERFCNT
  dpic_calls[perf_v_difftest_RunaheadRedirectEvent] ++;
  dpic_bytes[perf_v_difftest_RunaheadRedirectEvent] += 25;
#endif // CONFIG_DIFFTEST_PERFCNT

  auto packet = &(DUT_BUF(io_coreid, 0, 0)->runahead_redirect);
  packet->valid = true;
  packet->pc = io_pc;
  packet->target_pc = io_target_pc;
  packet->checkpoint_id = io_checkpoint_id;
  
}


#endif // CONFIG_NO_DIFFTEST

