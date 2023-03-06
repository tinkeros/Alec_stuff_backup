U0 parseHeader(U8 *rom, ROMHeader *header)
{
    I64 i;
    header->name = CAlloc(24);
    MemCpy(header->name, rom+0x7FC0, 20);
    i = StrLen(header->name)-1;
    while (header->name[i]==' ') { header->name[i]=NULL; i--; }
    header->type = rom[0x7fd5] & 0xf;
    header->speed = rom[0x7fd5] >> 4;
    header->chips = rom[0x7fd6];
    header->romSize = 0x400 << rom[0x7fd7];
    header->ramSize = 0x400 << rom[0x7fd8];
    header->hasSram = header->chips > 0;
    header->banks = header->romSize / 0x8000;
    header->sramSize = cond(header->hasSram, header->ramSize, 0);
    if (header->hasSram) sram = MAlloc(header->ramSize);
}

U0 LoROM(U8 *filename)
{

    // LoROM loader
    MemSet(&header, NULL, sizeof(ROMHeader));
    I64 rom_length;
    rom = FileRead(filename, &rom_length);

    // skip copier header
    if (rom_length%1024)
    {
        rom += 512;
        rom_length -= 512;        
    }

    parseHeader(rom, &header);

    if (header.romSize < rom_length)
    {
        "Incorrect romSize?\n";
        return;
    }

}