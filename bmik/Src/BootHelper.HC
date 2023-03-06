// This script will clean up non-existent removable drives when booting in QEMU

U0 BootHelper() {
  I64 i;
  Bool is_qemu = FALSE;
  U8 *drv_model = DrvModelNum(':');
  if (!MemCmp("QEMU", drv_model, 4))
    is_qemu = TRUE;
  Free(drv_model);
  if (is_qemu) {
    // Remove non-existent removable drives
    for (i = 'T'; i < 'X'; i++) {
      if (Let2Drv(i, 0))
        DrvDel(Let2Drv(i));
    }
    // Add default QEMU CDROM
    CBlkDev *bd = CAlloc(sizeof(CBlkDev));
    bd = BlkDevNextFreeSlot('T', 5);
    bd->unit = 0;
    bd->base0 = 0x170;
    bd->base1 = 0x374;
    BlkDevAdd(bd, , 0, 0);
  }
}

BootHelper;
