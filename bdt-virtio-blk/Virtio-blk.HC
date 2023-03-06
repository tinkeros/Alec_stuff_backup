#define VIRTIO_BLK_T_IN     0
#define VIRTIO_BLK_T_OUT    1
#define VIRTIO_BLK_T_FLUSH  4

#define VIRTIO_BLK_MAX_BLK  0x400000 // Limit blkdev to 2G max, set to NULL to use entire disk (not recommended for RedSea)

class CVirtioBlk
{
U16 port;
U32 blks;
CVirtioQueue *vq;
I64 vq_size;
I64 vq_index;
U8 status;
};

class CVirtioBlkRequest
{
U32 type;
U32 priority;
U64 sector;
};

CVirtioBlk virtio_blk;
MemSet(&virtio_blk, 0, sizeof(CVirtioBlk));

I64 VirtioBlkInit()
{
	I64 i,j;
  U8 k;

	//Scan for device
	j=PCIClassFind(0x010000,0);
	if (j<0)
	{
		"\nVirtio-blk device not found.\n";
		return -1;
	}
	virtio_blk.port=PCIReadU32(j.u8[2],
	                     j.u8[1],j.u8[0],0x10) & 0xFFFFFFFC;

  virtio_blk.blks = InU32(virtio_blk.port + VIRTIO_PCI_CONFIG);

  // Reset Device
  OutU8(virtio_blk.port + VIRTIO_PCI_STATUS, 0);

  // Found Driver
  OutU8(virtio_blk.port + VIRTIO_PCI_STATUS, InU8(virtio_blk.port + VIRTIO_PCI_STATUS) | VIRTIO_CONFIG_S_ACKNOWLEDGE | VIRTIO_CONFIG_S_DRIVER);

  // Set up virt queue
  OutU16(virtio_blk.port + VIRTIO_PCI_QUEUE_SEL, 0);
  virtio_blk.vq_size = InU16(virtio_blk.port + VIRTIO_PCI_QUEUE_SIZE);//256
  virtio_blk.vq = CAllocAligned(sizeof(CVirtioQueue), 4096, Fs->code_heap);
  OutU32(virtio_blk.port + VIRTIO_PCI_QUEUE_PFN, virtio_blk.vq / 4096);

  // Init OK
  OutU8(virtio_blk.port + VIRTIO_PCI_STATUS, InU8(virtio_blk.port + VIRTIO_PCI_STATUS) | VIRTIO_CONFIG_S_DRIVER_OK);
  virtio_blk.vq_index = 0;
}