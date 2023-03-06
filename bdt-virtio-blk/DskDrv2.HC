DefineLstLoad("ST_BLKDEV_TYPES2",
    "NULL\0RAM\0ATA\0FILE_READ\0FILE_WRITE\0ATAPI\0NULL\0NULL\0NULL\0NULL\0VIRTIO\0");

U8 DrvTextAttrGet2(U8 drv_let=0)
{//Get color of drive.
  U8 *blkdev_text_attr2 = blkdev_text_attr;
  U8 *drv_text_attr2 = drv_text_attr;
  I64 dta_size = 3;
  drv_let=Let2Let(drv_let);
  if (drv_let=='A') return BLACK<<4|WHITE;
  if ('A'<=drv_let<='Z')
    return blkdev_text_attr2[Let2BlkDevType(drv_let)]<<4|
	  drv_text_attr2[drv_let%dta_size];
  else
    return BLACK<<4|WHITE;
}

U0 DrvRep2()
{//Drive report.
  CDrv *dv;
  CBlkDev *bd;
  I64 ch,i,drv_let,attr;
  U8 *st;
  "\nDefined Drives:\n";
  for (i=0,dv=blkdev.drvs;i<DRVS_NUM;i++,dv++) {
    if (dv->dv_signature==DRV_SIGNATURE_VAL) {
      bd=dv->bd;
      drv_let=Drv2Let(dv);
      if (Bt(&dv->fs_type,FStf_DISABLE))
	ch='-';
      else if (drv_let==blkdev.boot_drv_let)
	ch=':';
      else
	ch='+';
      attr=DrvTextAttrGet(drv_let);
      "$$FG,%d$$$$BG,%d$$%C %-8Z %-10Z %04X %04X %02X\n",
	    attr&15,attr>>4,drv_let,dv->fs_type&FSG_TYPE_MASK,"ST_DRV_TYPES",
	    bd->type,"ST_BLKDEV_TYPES2",bd->base0,bd->base1,bd->unit;
      if (st=DrvModelNum(drv_let)) {
	"Model#:%s\n",st;
	Free(st);
      }
      if (st=DrvSerialNum(drv_let)) {
	"Serial#:%s\n",st;
	Free(st);
      }
      if (bd->type==BDT_ISO_FILE_READ || bd->type==BDT_ISO_FILE_WRITE)
	"File=\"%s\"\n",bd->file_dsk_name;
      "%016X-%016X\n$$FG$$$$BG$$",dv->drv_offset,dv->drv_offset+dv->size-1;
    }
  }
  "Home Dir:\"%s\"\n",blkdev.home_dir;
}

PatchJmpRel32(&DrvTextAttrGet, &DrvTextAttrGet2);
PatchJmpRel32(&DrvRep, &DrvRep2);