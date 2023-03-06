class @pml {
  U32 pml2;
  U32 pml3;
  U32 pml4;
};

/* clang-format off */

@pml *@memory_init_page_tables_for_task(CTask *task) {

U32 reg R11 _pml2 = MAllocAligned(MEM_2MEG_NUM * 8, 4096, task->code_heap);
U32 reg R14 _pml3 = MAllocAligned(MEM_1GIG_NUM * 8, 4096, task->code_heap);
U32 reg R15 _pml4 = MAllocAligned(MEM_512GIG_NUM * 8, 4096, task->code_heap);

asm {
        PUSH_REGS
//PML2: Use 2Meg Pages
        MOV     EAX,0x87 //bit 7 is page size (2Meg)
        XOR     EDX,EDX
        MOV     RDI,R11
        MOV     ECX,[MEM_2MEG_NUM]
@@20:   MOV     U32 [EDI],EAX
        ADD     EDI,4
        MOV     U32 [EDI],EDX
        ADD     EDI,4
        ADD     EAX,0x200000
        ADC     EDX,0
        LOOP    @@20
//PML3: Use 2Meg Pages
        MOV     RAX,R11
        OR      EAX,7
        XOR     EDX,EDX
        MOV     RDI,R14
        MOV     ECX,[MEM_1GIG_NUM]
@@25:   MOV     U32 [EDI],EAX
        ADD     EDI,4
        MOV     U32 [EDI],EDX
        ADD     EDI,4
        ADD     EAX,0x1000
        ADC     EDX,0
        LOOP    @@25
        JMP     @@40

//PML3: Use 1Gig Pages
@@30:   MOV     EAX,0x87 //bit 7 is page size (1Gig)
        XOR     EDX,EDX
        MOV     RDI,R14
        MOV     ECX,[MEM_1GIG_NUM]
@@35:   MOV     U32 [EDI],EAX
        ADD     EDI,4
        MOV     U32 [EDI],EDX
        ADD     EDI,4
        ADD     EAX,0x40000000
        ADC     EDX,0
        LOOP    @@35

//PML4
@@40:   MOV     RAX,R14
        OR      EAX,7
        XOR     EDX,EDX
        MOV     RDI,R15
        MOV     ECX,[MEM_512GIG_NUM]
@@45:   MOV     U32 [EDI],EAX
        ADD     EDI,4
        MOV     U32 [EDI],EDX
        ADD     EDI,4
        ADD     EAX,0x1000
        ADC     EDX,0
        LOOP    @@45
        POP_REGS
}
  task->user_data.u32[1] = _pml4;
  @pml *pml = CAlloc(sizeof(@pml));
  pml->pml2 = _pml2;
  pml->pml3 = _pml3;
  pml->pml4 = _pml4;
  return pml;
}

/* clang-format on */

U64 @page_table_entry_ptr(U64 ptr, U8 *a) {
  U64 entry_ptr = MemPageTable(a);
  entry_ptr -= MemPageTable(0);
  entry_ptr += ptr;
  return entry_ptr;
}

U8 *@memory_malloc_2meg_pages(CTask *task, I64 count) {
  return MAllocAligned(0x200000 * count, 0x200000, task->code_heap);
}

U0 @memory_map_address(U8 *ptr, U64 vaddr, U64 paddr) {
  MemCpyU64(@page_table_entry_ptr(ptr, vaddr), MemPageTable(paddr), 1);
  Yield;
}

class @memory {
  @pml *(*InitPageTablesForTask)(CTask * task);
  U8 *(*MAlloc2MegPages)(CTask * task, I64 count);
  U0 (*MapAddress)(U8 * ptr, U64 vaddr, U64 paddr);
};

@memory Memory;
Memory.InitPageTablesForTask = &@memory_init_page_tables_for_task;
Memory.MAlloc2MegPages = &@memory_malloc_2meg_pages;
Memory.MapAddress = &@memory_map_address;

"memory ";