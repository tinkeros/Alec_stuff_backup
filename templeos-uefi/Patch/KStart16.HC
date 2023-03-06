asm {/* See $LK,"::/Doc/Boot.DD"$.
TempleOS starts in real, calls some BIOS
routines, switches to 32 bit, and 64 bit mode
and continues in $LK,"HolyC",A="FI:::/Doc/HolyC.DD"$ at $LK,"KMain",A="MN:KMain"$().

The boot loader jumps here in real-mode (16-bit).
It actually jumps to the $LK,"CBinFile",A="MN:CBinFile"$ header which is
placed just before this by $LK,"the compiler",A="FF:::/Compiler/CMain.HC,16 ALIGN"$.
The header begins with a short jmp to
the start of this file's code which begins
with the following small jump past some data.

This file is first in the Kernel image
because it is #included first.$LK,"Kernel.PRJ",A="FF:::/Kernel/Kernel.PRJ,KStart16:1"$
*/
USE64
SYS_KERNEL:: //This must match $LK,"CKernel",A="MN:CKernel"$.
	JMP	I32 CORE0_32BIT_INIT

//************************************
//  ASM Global vars required for 16-bit start-up
	ALIGN	4,OC_NOP
SYS_BOOT_SRC::			DU32	BOOT_SRC_NULL;
SYS_BOOT_BLK::			DU32	0;
SYS_BOOT_PATCH_TABLE_BASE::	DU32	0;
SYS_RUN_LEVEL::			DU32	0;
#exe {StreamPrint("SYS_COMPILE_TIME:: DU64 0x%X;",Now);} //See $LK,"BootDVDProbe",A="MN:BootDVDProbe"$
#assert SYS_COMPILE_TIME+sizeof(CDate)+sizeof(CBinFile)<DVD_BLK_SIZE

MEM_BOOT_BASE::		DU32	0;	//Offset from start used by reboot
MEM_E801::		DU16	0,0;
MEM_E820::		DU8	MEM_E820_ENTRIES_NUM*sizeof(CMemE820) DUP (0);
MEM_PHYSICAL_SPACE::	DU64	0;
SYS_GDT_PTR::		DU16	sizeof(CGDT)-1;
			DU64	0;
SYS_PCI_BUSES::		DU16	0;

	ALIGN	16,OC_NOP
SYS_GDT:: //See $LK,"CGDT",A="MN:CGDT"$
GDT_NULL:	DU64	0,0;
GDT_BOOT_DS:	DU64	0x00CF92000000FFFF,0; //Gets patched.
GDT_BOOT_CS:	DU64	0x00CF9A000000FFFF,0; //Gets patched.
GDT_CS32:	DU64	0x00CF9A000000FFFF,0;
GDT_CS64:	DU64	0x00209A0000000000,0; //The $LK,"Charter",A="FI:::/Doc/Charter.DD"$ says just ring0.
GDT_CS64_RING3:	DU64	0x0020FA0000000000,0; //$LK,"Ring3",A="FI:::/Demo/Lectures/Ring3.HC"$, so you can play with.
GDT_DS:		DU64	0x00CF92000000FFFF,0;
GDT_DS_RING3:	DU64	0x00CFF2000000FFFF,0;
GDT_TR:		DU8	MP_PROCESSORS_NUM*16 DUP(0);
GDT_TR_RING3:	DU8	MP_PROCESSORS_NUM*16 DUP(0);

//************************************
}
