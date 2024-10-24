#ifndef __DIFFTEST_DPIC_H__
#define __DIFFTEST_DPIC_H__

#include <cstdint>
#include "diffstate.h"
#ifdef CONFIG_DIFFTEST_BATCH
#include "svdpi.h"
#endif // CONFIG_DIFFTEST_BATCH
#ifdef CONFIG_DIFFTEST_PERFCNT
#include "perf.h"
#endif // CONFIG_DIFFTEST_PERFCNT


class DPICBuffer : public DiffStateBuffer {
private:
  DiffTestState buffer[CONFIG_DIFFTEST_ZONESIZE][CONFIG_DIFFTEST_BUFLEN];
  int read_ptr = 0;
  int zone_ptr = 0;
  bool init = true;
public:
  DPICBuffer() {
    memset(buffer, 0, sizeof(buffer));
  }
  inline DiffTestState* get(int zone, int index) {
    return buffer[zone] + index;
  }
  inline DiffTestState* next() {
    DiffTestState* ret = buffer[zone_ptr] + read_ptr;
    read_ptr = read_ptr + 1;
    return ret;
  }
  inline void switch_zone() {
    if (init) {
      init = false;
      return;
    }
    zone_ptr = (zone_ptr + 1) % CONFIG_DIFFTEST_ZONESIZE;
    read_ptr = 0;
  }
};


#ifdef CONFIG_DIFFTEST_PERFCNT
enum DIFFSTATE_PERF {
  perf_v_difftest_ArchEvent,
  perf_v_difftest_InstrCommit,
  perf_v_difftest_TrapEvent,
  perf_v_difftest_CSRState,
  perf_v_difftest_HCSRState,
  perf_v_difftest_DebugMode,
  perf_v_difftest_TriggerCSRState,
  perf_v_difftest_ArchVecRegState,
  perf_v_difftest_VecCSRState,
  perf_v_difftest_FpCSRState,
  perf_v_difftest_IntWriteback,
  perf_v_difftest_FpWriteback,
  perf_v_difftest_VecWriteback,
  perf_v_difftest_ArchIntRegState,
  perf_v_difftest_ArchFpRegState,
  perf_v_difftest_SbufferEvent,
  perf_v_difftest_StoreEvent,
  perf_v_difftest_LoadEvent,
  perf_v_difftest_AtomicEvent,
  perf_v_difftest_L1TLBEvent,
  perf_v_difftest_L2TLBEvent,
  perf_v_difftest_RefillEvent,
  perf_v_difftest_LrScEvent,
  perf_v_difftest_RunaheadEvent,
  perf_v_difftest_RunaheadCommitEvent,
  perf_v_difftest_RunaheadRedirectEvent,
  DIFFSTATE_PERF_NUM
};
long long dpic_calls[DIFFSTATE_PERF_NUM] = {0}, dpic_bytes[DIFFSTATE_PERF_NUM] = {0};
#endif // CONFIG_DIFFTEST_PERFCNT


extern "C" void v_difftest_ArchEvent (
  uint32_t io_interrupt,
  uint32_t io_exception,
  uint64_t io_exceptionPC,
  uint32_t io_exceptionInst,
  uint8_t  io_hasNMI,
  uint8_t  io_virtualInterruptIsHvictlInject,
  uint8_t  io_coreid
);

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
);

extern "C" void v_difftest_TrapEvent (
  uint8_t  io_hasTrap,
  uint64_t io_cycleCnt,
  uint64_t io_instrCnt,
  uint8_t  io_hasWFI,
  uint32_t io_code,
  uint64_t io_pc,
  uint8_t  io_coreid
);

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
);

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
);

extern "C" void v_difftest_DebugMode (
  uint8_t  io_debugMode,
  uint64_t io_dcsr,
  uint64_t io_dpc,
  uint64_t io_dscratch0,
  uint64_t io_dscratch1,
  uint8_t  io_coreid
);

extern "C" void v_difftest_TriggerCSRState (
  uint64_t io_tselect,
  uint64_t io_tdata1,
  uint64_t io_tinfo,
  uint64_t io_tcontrol,
  uint8_t  io_coreid
);

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
);

extern "C" void v_difftest_VecCSRState (
  uint64_t io_vstart,
  uint64_t io_vxsat,
  uint64_t io_vxrm,
  uint64_t io_vcsr,
  uint64_t io_vl,
  uint64_t io_vtype,
  uint64_t io_vlenb,
  uint8_t  io_coreid
);

extern "C" void v_difftest_FpCSRState (
  uint64_t io_fcsr,
  uint8_t  io_coreid
);

extern "C" void v_difftest_IntWriteback (
  uint8_t  io_address,
  uint64_t io_data,
  uint8_t  io_coreid
);

extern "C" void v_difftest_FpWriteback (
  uint8_t  io_address,
  uint64_t io_data,
  uint8_t  io_coreid
);

extern "C" void v_difftest_VecWriteback (
  uint8_t  io_address,
  uint64_t io_data,
  uint8_t  io_coreid
);

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
);

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
);

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
);

extern "C" void v_difftest_StoreEvent (
  uint64_t io_addr,
  uint64_t io_data,
  uint8_t  io_mask,
  uint8_t  io_coreid,
  uint8_t  io_index
);

extern "C" void v_difftest_LoadEvent (
  uint64_t io_paddr,
  uint8_t  io_opType,
  uint8_t  io_isAtomic,
  uint8_t  io_isLoad,
  uint8_t  io_coreid,
  uint8_t  io_index
);

extern "C" void v_difftest_AtomicEvent (
  uint64_t io_addr,
  uint64_t io_data,
  uint8_t  io_mask,
  uint8_t  io_fuop,
  uint64_t io_out,
  uint8_t  io_coreid
);

extern "C" void v_difftest_L1TLBEvent (
  uint64_t io_satp,
  uint64_t io_vpn,
  uint64_t io_ppn,
  uint64_t io_vsatp,
  uint64_t io_hgatp,
  uint8_t  io_s2xlate,
  uint8_t  io_coreid,
  uint8_t  io_index
);

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
);

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
);

extern "C" void v_difftest_LrScEvent (
  uint8_t  io_success,
  uint8_t  io_coreid
);

extern "C" void v_difftest_RunaheadEvent (
  uint8_t  io_branch,
  uint8_t  io_may_replay,
  uint64_t io_pc,
  uint64_t io_checkpoint_id,
  uint8_t  io_coreid,
  uint8_t  io_index
);

extern "C" void v_difftest_RunaheadCommitEvent (
  uint8_t  io_branch,
  uint8_t  io_may_replay,
  uint64_t io_pc,
  uint64_t io_checkpoint_id,
  uint8_t  io_coreid,
  uint8_t  io_index
);

extern "C" void v_difftest_RunaheadRedirectEvent (
  uint64_t io_pc,
  uint64_t io_target_pc,
  uint64_t io_checkpoint_id,
  uint8_t  io_coreid
);

#endif // __DIFFTEST_DPIC_H__

