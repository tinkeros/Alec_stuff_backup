#define BDT_VIRTIO_BLK 10

U0 PatchJmpRel32(U32 from, U32 to)
{
    *(from(U8*)) = 0xE9;
    *((from+1)(I32*)) = to-from-5;
}