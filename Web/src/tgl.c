#define DR_MP3_IMPLEMENTATION
#define DR_MP3_NO_STDIO
#define DR_MP3_NO_SIMD

#define STB_IMAGE_IMPLEMENTATION
#define STBI_NO_LINEAR
#define STBI_NO_STDIO
#define STBI_NO_SIMD
#define STBI_NO_HDR

#include "dr_mp3.h"
#include "stb_image.h"

int main() {
    return 0;
}

STBIDEF stbi_uc *tgl_load_gif_from_memory(stbi_uc const *buffer, int len, int **delays, int *x, int *y, int *z) {
    int comp;
    return stbi_load_gif_from_memory(buffer, len, delays, x, y, z, &comp, 4);
}