asm {
//************************************
//See $LK,"::/Doc/Credits.DD"$.
//************************************
_MHEAP_CTRL::
	PUSH	RBP
	MOV	RBP,RSP
	MOV	RBX,U64 SF_ARG1[RBP]
	XOR	RAX,RAX
	TEST	RBX,RBX
	JZ	@@10
	MOV	RAX,U64 CMemUsed.size-CMemUsed.start[RBX]
	TEST	RAX,RAX
	JGE	@@05	//Aligned alloced chunks have neg size
	ADD	RBX,RAX
@@05:	MOV	RAX,U64 CMemUsed.hc-CMemUsed.start[RBX]
@@10:	POP	RBP
	RET1	8
}

_extern _MHEAP_CTRL CHeapCtrl *MHeapCtrl(U8 *src); //$LK,"CHeapCtrl",A="MN:CHeapCtrl"$ of object.
//Accepts a $LK,"CTask",A="MN:CTask"$ or $LK,"CHeapCtrl",A="MN:CHeapCtrl"$. NULL allocs off current task's heap.

U8 *MAlloc(I64 size, CTask *t=NULL)
{ 
  I64 *p = 0x3000;
  return CallUEFI(*p, size);
}

U0 Free(U8 *addr) {
  I64 *p = 0x3010;
  CallUEFI(*p, addr);
  p = NULL;
}

I64 MSize(U8 *addr)
{ 
  I64 *p = 0x3020;
  return CallUEFI(*p, addr);
}

I64 MSize2(U8 *addr)
{
  I64 *p = 0x3020;
  return CallUEFI(*p, addr);
}

U8 *AMAlloc(I64 size)
{//Alloc memory in Adam's heap.
  return MAlloc(size,adam_task);
}

U8 *CAlloc(I64 size,CTask *mem_task=NULL)
{//Accepts a $LK,"CTask",A="MN:CTask"$ or $LK,"CHeapCtrl",A="MN:CHeapCtrl"$.NULL allocs off current task's heap.
  U8 *res=MAlloc(size,mem_task);
  MemSet(res,0,size);
  return res;
}

U8 *ACAlloc(I64 size)
{//Alloc and set to zero memory in Adam's heap.
  return CAlloc(size,adam_task);
}

U8 *MAllocIdent(U8 *src,CTask *mem_task=NULL)
{//Accepts a $LK,"CTask",A="MN:CTask"$ or $LK,"CHeapCtrl",A="MN:CHeapCtrl"$.NULL allocs off current task's heap.
  U8 *res;
  I64 size;
  if (!src) return NULL;
  size=MSize(src);
  res=MAlloc(size,mem_task);
  MemCpy(res,src,size);
  return res;
}

U8 *AMAllocIdent(U8 *src)
{//Alloc in Adam's heap, ident copy of heap node.
  return MAllocIdent(src,adam_task);
}

U8 *MAllocAligned(I64 size,I64 alignment,
	CTask *mem_task=NULL,I64 misalignment=0)
{//Only powers of two alignment. This is awful.
  I64 mask=alignment-1;
  U8 *ptr=MAlloc(size+mask+sizeof(I64)+misalignment,mem_task),
	*res=(ptr+sizeof(I64)+mask)&~mask+misalignment;
  res(I64 *)[-1]=ptr-res;
  return res;
}

U8 *CAllocAligned(I64 size,I64 alignment,
	CTask *mem_task=NULL,I64 misalignment=0)
{//Only powers of two alignment. This is awful.
  I64 mask=alignment-1;
  U8 *ptr=MAlloc(size+mask+sizeof(I64)+misalignment,mem_task),
	*res=(ptr+sizeof(I64)+mask)&~mask+misalignment;
  res(I64 *)[-1]=ptr-res;
#assert offset(CMemUsed.size)==offset(CMemUsed.start)-sizeof(I64)
  MemSet(res,0,size);
  return res;
}

U8 *StrNew(U8 *buf,CTask *mem_task=NULL)
{//Accepts a $LK,"CTask",A="MN:CTask"$ or $LK,"CHeapCtrl",A="MN:CHeapCtrl"$.NULL allocs off current task's heap.
  U8 *res;
  I64 size;
  if (buf) {
    size=StrLen(buf)+1;
    res=MAlloc(size,mem_task);
    MemCpy(res,buf,size);
  } else {
    res=MAlloc(1,mem_task);
    *res=0;
  }
  return res;
}

U8 *AStrNew(U8 *buf)
{//Alloc copy of string in Adam's heap.
  return StrNew(buf,adam_task);
}
