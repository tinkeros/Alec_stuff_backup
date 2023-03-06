#define include_noreindex #include

include_noreindex "Lib/Debug";
include_noreindex "Lib/TOSGame";
include_noreindex "Lib/Misc";
include_noreindex "Lib/LibC";
include_noreindex "Lib/SDL2";
include_noreindex "Lib/SDL2_net";
include_noreindex "Lib/ELF64";

DocMax;
WinMax;

load_elf("chocolate-doom", "-mmap", "-nomouse", "-nosound", "-iwad",
         "doom1.wad");
