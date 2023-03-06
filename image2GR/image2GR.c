#define RED 4
#define GREEN 2
#define BLUE 1
#define COLORS_NUM 16
#define STB_IMAGE_IMPLEMENTATION
#define STBI_NO_HDR
#define STBI_NO_LINEAR

#include "stb_image.h"
#include <math.h>
#include <unistd.h>

struct CDC {
  uint64_t cdt;
  int32_t x0, y0, width, width_internal, height, flags;
  unsigned char *body;
};

char rgba_to_4_bit(int r, int g, int b, int a) {
  if (a < 0xFF)
    return 0xFF;
  char res = 0;
  if (sqrt(r) + sqrt(g) + sqrt(b) >= sqrt(0x80)) {
    res = 8;
    if (r >= 0xC0)
      res |= RED;
    if (g >= 0xC0)
      res |= GREEN;
    if (b >= 0xC0)
      res |= BLUE;
  } else {
    if (r >= 0x40)
      res |= RED;
    if (g >= 0x40)
      res |= GREEN;
    if (b >= 0x40)
      res |= BLUE;
  }
  return res;
}

char *output_filename(char *newfn, char *oldfn) {
  int len = strlen(oldfn);
  while (oldfn[len] != '.')
    len--;
  memcpy(newfn, oldfn, len);
  strcpy(newfn + len, ".GR");
  return newfn;
}

int image2GR(char *filename) {
  if (access(filename, F_OK) != 0) {
    printf("File not found: %s\n", filename);
    return -1;
  }
  FILE *f = fopen(filename, "rb");
  int w = 0, h = 0;
  int x = 0, y = 0;
  int channels = 0;
  int i = 0;
  unsigned char *buffer = stbi_load_from_file(f, &w, &h, &channels, 4);
  fclose(f);
  struct CDC *dc = calloc(sizeof(struct CDC), 1);
  dc->width = w;
  dc->height = h;
  dc->width_internal = (w + 7) & (-8);
  dc->body = calloc(dc->width_internal * dc->height, 1);
  for (y = 0; y < h; y++)
    for (x = 0; x < w; x++) {
      dc->body[(y * dc->width_internal) + x] =
          rgba_to_4_bit(buffer[i], buffer[i + 1], buffer[i + 2], buffer[i + 3]);
      i += 4;
    }
  free(buffer);
  char outfile[512];
  f = fopen(output_filename((char *)&outfile, filename), "wb");
  fwrite(dc, sizeof(struct CDC) - sizeof(unsigned char *), 1, f);
  fwrite(dc->body, dc->height * dc->width_internal, 1, f);
  fclose(f);
  free(dc->body);
  free(dc);
  return 0;
}

int main(int argc, char **argv) {
  if (argc < 2) {
    printf("Usage: image2GR file\n");
    exit(0);
  }
  return image2GR(argv[1]);
}