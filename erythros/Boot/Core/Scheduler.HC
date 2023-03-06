/* clang-format off */

U0 @scheduler_restore_page_table(U64 i) {
  U64 reg R15 _pt = i.u32[1];
  if (_pt) { // Use CTask's page table entries
    asm {
      MOV RAX, R15
      MOV_CR3_RAX
    }
  } else { // Use identity mapping
    asm {
      MOV EAX, [MEM_PML4]
      MOV_CR3_RAX
    }
  }
}

asm {
ERYTHROS_TASK_CONTEXT_RESTORE_START::
        XOR     RAX,RAX
        INC     U64 GS:CCPU.swap_cnter[RAX]
        MOV     RSI,FS:CTask.addr[RAX]
        BT      U32 CTask.rflags[RSI],RFLAGf_INT
        JNC     @@05
        BTS     U32 GS:CCPU.cpu_flags[RAX],CPUf_RAN_A_TASK
@@05:   BT      U64 CTask.task_flags[RSI],TASKf_DISABLE_BPTS
        JC      @@15
        MOV     RDX,U64 CTask.bpt_lst[RSI]
@@10:   TEST    RDX,RDX
        JZ      @@15
        MOV     RDI,U64 CBpt.addr[RDX]
        MOV     U8 [RDI],OC_BPT
        MOV     RDX,U64 CBpt.next[RDX]
        JMP     @@10

@@15:   INC     U64 CTask.swap_cnter[RSI]

        MOV     RAX, U64 CTask.user_data[RSI]
        PUSH    RAX
        CALL I32 &@scheduler_restore_page_table

        MOV     RAX,U64 CTask.fpu_mmx[RSI]
        FXRSTOR U64 [RAX]

        MOV     RAX,RSP
        LEA     RSP,U64 CTask.rcx[RSI]
        POP     RCX
        POP     RDX
        POP     RBX
        POP     RBP
        POP     RDI
        POP     R8
        POP     R9
        POP     R10
        POP     R11
        POP     R12
        POP     R13
        POP     R14
        POP     R15
        MOV     RSP,RAX

        MOV     RAX,U64 CTask.rax[RSI]
        PUSH    CGDT.ds
        PUSH    U64 CTask.rsp[RSI]
        PUSH    U64 CTask.rflags[RSI]
        PUSH    CGDT.cs64
        PUSH    U64 CTask.rip[RSI]
        MOV     RSI,U64 CTask.rsi[RSI]
        IRET
  ERYTHROS_TASK_CONTEXT_RESTORE_END::
        NOP
  //************************************
}

/* clang-format on */

Function.Patch(_TASK_CONTEXT_RESTORE, ERYTHROS_TASK_CONTEXT_RESTORE_START);

"scheduler ";