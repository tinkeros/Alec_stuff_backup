CBlkDev *BlkDevChk2(CBlkDev *bd,Bool except=TRUE)
{//Check for valid BlkDev. Throw exception.
  if (bd->type==BDT_VIRTIO_BLK) return bd;
  if (!bd || bd->bd_signature!=BD_SIGNATURE_VAL ||
	!(BDT_NULL<bd->type<BDT_TYPES_NUM)) {
    if (except)
      throw('BlkDev');
    else
      return NULL;
  } else
    return bd;
}

PatchJmpRel32(&BlkDevChk, &BlkDevChk2);