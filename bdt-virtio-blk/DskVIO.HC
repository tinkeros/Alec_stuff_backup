U0 VIOFlush()
{ 
  I64 j;
  I64 vq_idx;
  CVirtioBlkRequest *brq = CAlloc(sizeof(CVirtioBlkRequest));
  brq->type = VIRTIO_BLK_T_FLUSH;
  brq->sector = NULL;
  vq_idx = virtio_blk.vq->available.index % 128;
  virtio_blk.vq->buffers[virtio_blk.vq_index%128].address = brq;
  virtio_blk.vq->buffers[virtio_blk.vq_index%128].length = sizeof(CVirtioBlkRequest);
  virtio_blk.vq->buffers[virtio_blk.vq_index%128].flags = VRING_DESC_F_NEXT;
  virtio_blk.vq->buffers[virtio_blk.vq_index%128].next = (virtio_blk.vq_index+1)%128;
  virtio_blk.vq->buffers[(virtio_blk.vq_index+1)%128].address = &virtio_blk.status;
  virtio_blk.vq->buffers[(virtio_blk.vq_index+1)%128].length = 1;
  virtio_blk.vq->buffers[(virtio_blk.vq_index+1)%128].flags = VRING_DESC_F_WRITE;
  virtio_blk.vq->buffers[(virtio_blk.vq_index+1)%128].next = 0;
  virtio_blk.vq->available.ring[vq_idx] = virtio_blk.vq_index%128;
  virtio_blk.vq_index += 2;
  j = virtio_blk.vq->used.index;
  virtio_blk.vq->available.index++;
  OutU16(virtio_blk.port + VIRTIO_PCI_QUEUE_NOTIFY, 0);
  while (j==virtio_blk.vq->used.index){Yield;}
  Free(brq);
}

Bool VIORBlks(CDrv *dv, U8 *buf, I64 blk, I64 cnt)
{ 
  I64 i, j;
  I64 vq_idx;
  U64 addr;
  CVirtioBlkRequest *brq = CAlloc(sizeof(CVirtioBlkRequest));
  for (i=0; i<cnt; i++)
  {
    brq->type = VIRTIO_BLK_T_IN;
    brq->sector = blk + i;
    vq_idx = virtio_blk.vq->available.index % 128;
    addr = buf + (BLK_SIZE*i);
    virtio_blk.vq->buffers[virtio_blk.vq_index%128].address = brq;
    virtio_blk.vq->buffers[virtio_blk.vq_index%128].length = sizeof(CVirtioBlkRequest);
    virtio_blk.vq->buffers[virtio_blk.vq_index%128].flags = VRING_DESC_F_NEXT;
    virtio_blk.vq->buffers[virtio_blk.vq_index%128].next = (virtio_blk.vq_index+1)%128;
    virtio_blk.vq->buffers[(virtio_blk.vq_index+1)%128].address = addr;
    virtio_blk.vq->buffers[(virtio_blk.vq_index+1)%128].length = BLK_SIZE;
    virtio_blk.vq->buffers[(virtio_blk.vq_index+1)%128].flags = VRING_DESC_F_WRITE | VRING_DESC_F_NEXT;
    virtio_blk.vq->buffers[(virtio_blk.vq_index+1)%128].next = (virtio_blk.vq_index+2)%128;
    virtio_blk.vq->buffers[(virtio_blk.vq_index+2)%128].address = &virtio_blk.status;
    virtio_blk.vq->buffers[(virtio_blk.vq_index+2)%128].length = 1;
    virtio_blk.vq->buffers[(virtio_blk.vq_index+2)%128].flags = VRING_DESC_F_WRITE;
    virtio_blk.vq->buffers[(virtio_blk.vq_index+2)%128].next = 0;
    virtio_blk.vq->available.ring[vq_idx] = virtio_blk.vq_index%128;
    virtio_blk.vq_index += 3;
    j = virtio_blk.vq->used.index;
    virtio_blk.vq->available.index++;
    OutU16(virtio_blk.port + VIRTIO_PCI_QUEUE_NOTIFY, 0);
    while (j==virtio_blk.vq->used.index){Yield;}
  }
  Free(brq);
  return TRUE;
}

Bool VIOWBlks(CDrv *dv, U8 *buf, I64 blk, I64 cnt)
{ 
  I64 i, j;
  I64 vq_idx;
  U64 addr;
  CVirtioBlkRequest *brq = CAlloc(sizeof(CVirtioBlkRequest));
  for (i=0; i<cnt; i++)
  {
    brq->type = VIRTIO_BLK_T_OUT;
    brq->sector = blk + i;
    vq_idx = virtio_blk.vq->available.index % 128;
    addr = buf + (BLK_SIZE*i);
    virtio_blk.vq->buffers[virtio_blk.vq_index%128].address = brq;
    virtio_blk.vq->buffers[virtio_blk.vq_index%128].length = sizeof(CVirtioBlkRequest);
    virtio_blk.vq->buffers[virtio_blk.vq_index%128].flags = VRING_DESC_F_NEXT;
    virtio_blk.vq->buffers[virtio_blk.vq_index%128].next = (virtio_blk.vq_index+1)%128;
    virtio_blk.vq->buffers[(virtio_blk.vq_index+1)%128].address = addr;
    virtio_blk.vq->buffers[(virtio_blk.vq_index+1)%128].length = BLK_SIZE;
    virtio_blk.vq->buffers[(virtio_blk.vq_index+1)%128].flags = VRING_DESC_F_NEXT;
    virtio_blk.vq->buffers[(virtio_blk.vq_index+1)%128].next = (virtio_blk.vq_index+2)%128;
    virtio_blk.vq->buffers[(virtio_blk.vq_index+2)%128].address = &virtio_blk.status;
    virtio_blk.vq->buffers[(virtio_blk.vq_index+2)%128].length = 1;
    virtio_blk.vq->buffers[(virtio_blk.vq_index+2)%128].flags = VRING_DESC_F_WRITE;
    virtio_blk.vq->buffers[(virtio_blk.vq_index+2)%128].next = 0;
    virtio_blk.vq->available.ring[vq_idx] = virtio_blk.vq_index%128;
    virtio_blk.vq_index += 3;
    j = virtio_blk.vq->used.index;
    virtio_blk.vq->available.index++;
    OutU16(virtio_blk.port + VIRTIO_PCI_QUEUE_NOTIFY, 0);
    while (j==virtio_blk.vq->used.index){Yield;}
  }
  Free(brq);
  VIOFlush;
  return TRUE;
}

U8 MountVirtioBlk()
{//Mount Virtio-blk device
  CDrv *dv=DrvMakeFreeSlot(DrvNextFreeLet('A'));
  CBlkDev *bd=BlkDevNextFreeSlot(dv->drv_let,BDT_RAM);
  CRedSeaBoot *bs=CAlloc(BLK_SIZE);
  bd->max_blk = 512;
  BlkDevAdd(bd,,TRUE,TRUE);
  bd->type = BDT_VIRTIO_BLK;
  if (VIRTIO_BLK_MAX_BLK)
  {
    bd->max_blk = Min(VIRTIO_BLK_MAX_BLK, virtio_blk.blks);
  }
  else
  {
    bd->max_blk = virtio_blk.blks;
  }
  Free(bd->RAM_dsk);
  dv->size=bd->max_blk+1-bd->drv_offset;
  VIORBlks(dv,bs,0,1);
  dv->root_clus = bs->root_clus;
  dv->data_area = bs->bitmap_sects;
  Free(bs);
  return dv->drv_let;
}
