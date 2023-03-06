/*
 * Megadrive VDP emulation
 */

#define T_VRAM 0
#define T_CRAM 1
#define T_VSRAM 2

I64 line;

U8 VRAM[0x10000];
U16 CRAM[0x40];
U16 VSRAM[0x40];
U8 vdp_reg[0x20];

U8 *screen = MAlloc(320 * 240 * 4);
U8 *scaled_screen = CAlloc(320 * 240 * 4);

I64 control_code = 0;
U32 control_address = 0;
I64 control_pending = 0;
U32 vdp_status = 0x3400;

I64 screen_width;
I64 screen_height;

I64 dma_length;
U32 dma_source;
I64 dma_fill = 0;

/* Set a pixel on the screen using the Color RAM */
U0 set_pixel(U8 *scr, I64 x, I64 y, I64 index) {
  I64 pixel =
      ((240 - screen_height) / 2 + (y)) * 320 + (x) + (320 - screen_width) / 2;
  scr[pixel * 4 + 0] = (CRAM[index] >> 4) & 0xe0;
  scr[pixel * 4 + 1] = (CRAM[index]) & 0xe0;
  scr[pixel * 4 + 2] = (CRAM[index] << 4) & 0xe0;
}

/*
 * Draw a single pixel of a cell
 */
U0 draw_cell_pixel(U32 cell, I64 cell_x, I64 cell_y, I64 x, I64 y) {
  U8 *pattern = &VRAM[0x20 * (cell & 0x7ff)];

  I64 pattern_index = 0;
  if (cell & 0x1000) /* v flip */
    pattern_index = (7 - (cell_y & 7)) << 2;
  else
    pattern_index = (cell_y & 7) << 2;

  if (cell & 0x800) // h flip
    pattern_index += (7 - (cell_x & 7)) >> 1;
  else
    pattern_index += (cell_x & 7) >> 1;

  U8 color_index = pattern[pattern_index];
  if ((cell_x & 1) ^ ((cell >> 11) & 1))
    color_index &= 0xf;
  else
    color_index >>= 4;

  if (color_index) {
    color_index += (cell & 0x6000) >> 9;
    set_pixel(screen, x, y, color_index);
  }
}

/*
 * Render the scroll layers (plane A and B)
 */
U0 vdp_render_bg(I64 line, I64 priority) {
  I64 h_cells = 32, v_cells = 32;

  switch (vdp_reg[16] & 3) {
  case 0:
    h_cells = 32;
    break;
  case 1:
    h_cells = 64;
    break;
  case 3:
    h_cells = 128;
    break;
  }
  switch ((vdp_reg[16] >> 4) & 3) {
  case 0:
    v_cells = 32;
    break;
  case 1:
    v_cells = 64;
    break;
  case 3:
    v_cells = 128;
    break;
  }

  I64 hscroll_type = vdp_reg[11] & 3;
  U8 *hscroll_table = &VRAM[vdp_reg[13] << 10];
  U32 hscroll_mask;
  switch (hscroll_type) {
  case 0x00:
    hscroll_mask = 0x0000;
    break;
  case 0x01:
    hscroll_mask = 0x0007;
    break;
  case 0x02:
    hscroll_mask = 0xfff8;
    break;
  case 0x03:
    hscroll_mask = 0xffff;
    break;
  }

  U16 vscroll_mask;
  if (vdp_reg[11] & 4)
    vscroll_mask = 0xfff0;
  else
    vscroll_mask = 0x0000;

  I64 scroll_i;
  I64 column;
  I16 hscroll;
  I16 vscroll;

  for (scroll_i = 0; scroll_i < 2; scroll_i++) {
    U8 *scroll;
    if (scroll_i == 0)
      scroll = &VRAM[vdp_reg[4] << 13];
    else
      scroll = &VRAM[vdp_reg[2] << 10];

    hscroll =
        (hscroll_table[((line & hscroll_mask)) * 4 + (scroll_i ^ 1) * 2] << 8) |
        hscroll_table[((line & hscroll_mask)) * 4 + (scroll_i ^ 1) * 2 + 1];
    for (column = 0; column < screen_width; column++) {
      vscroll = VSRAM[(column & vscroll_mask) / 4 + (scroll_i ^ 1)] & 0x3ff;
      I64 e_line = (line + vscroll) & (v_cells * 8 - 1);
      I64 cell_line = e_line >> 3;
      I64 e_column = (column - hscroll) & (h_cells * 8 - 1);
      I64 cell_column = e_column >> 3;
      U32 cell = (scroll[(cell_line * h_cells + cell_column) * 2] << 8) |
                 scroll[(cell_line * h_cells + cell_column) * 2 + 1];

      if (((cell & 0x8000) && priority) ||
          ((cell & 0x8000) == 0 && priority == 0))
        draw_cell_pixel(cell, e_column, e_line, column, line);
    }
  }
}

/*
 * Render part of a sprite on a given line.
 */
U0 vdp_render_sprite(I64 sprite_index, I64 line) {
  U8 *sprite = &VRAM[(vdp_reg[5] << 9) + sprite_index * 8];

  U16 y_pos = ((sprite[0] << 8) | sprite[1]) & 0x3ff;
  I64 h_size = ((sprite[2] >> 2) & 0x3) + 1;
  I64 v_size = (sprite[2] & 0x3) + 1;
  U32 cell = (sprite[4] << 8) | sprite[5];
  U16 x_pos = ((sprite[6] << 8) | sprite[7]) & 0x3ff;

  I64 y = (128 - y_pos + line) & 7;
  I64 cell_y = (128 - y_pos + line) >> 3;

  I64 cell_x;
  I64 e_x;
  I64 e_cell;
  I64 x;

  for (cell_x = 0; cell_x < h_size; cell_x++) {
    for (x = 0; x < 8; x++) {
      e_x = cell_x * 8 + x + x_pos - 128;
      e_cell = cell;

      if (cell & 0x1000)
        e_cell += v_size - cell_y - 1;
      else
        e_cell += cell_y;

      if (cell & 0x800)
        e_cell += (h_size - cell_x - 1) * v_size;
      else
        e_cell += cell_x * v_size;
      if (e_x >= 0 && e_x < screen_width) {
        draw_cell_pixel(e_cell, x, y, e_x, line);
      }
    }
  }
}

/*
 * Render the sprite layer.
 */
U0 vdp_render_sprites(I64 line, I64 priority) {
  U8 *sprite_table = &VRAM[vdp_reg[5] << 9];

  I64 sprite_queue[80];
  I64 i = 0;
  I64 cur_sprite = 0;
  while (1) {
    U8 *sprite = &VRAM[(vdp_reg[5] << 9) + cur_sprite * 8];
    U16 y_pos = (sprite[0] << 8) | sprite[1];
    I64 v_size = (sprite[2] & 0x3) + 1;
    U32 cell = (sprite[4] << 8) | sprite[5];

    I64 y_min = y_pos - 128;
    I64 y_max = (v_size - 1) * 8 + 7 + y_min;

    if (line >= y_min && line <= y_max) {
      if ((cell >> 15) == priority)
        sprite_queue[i++] = cur_sprite;
    }

    cur_sprite = sprite_table[cur_sprite * 8 + 3];
    if (!cur_sprite)
      break;

    if (i >= 80)
      break;
  }
  while (i > 0) {
    vdp_render_sprite(sprite_queue[--i], line);
  }
}

/*
 * Render a single line.
 */
U0 vdp_render_line(I64 line) {
  /* Fill the screen with the backdrop color set in register 7 */
  I64 i;
  for (i = 0; i < screen_width; i++) {
    set_pixel(screen, i, line, vdp_reg[7] & 0x3f);
  }

  vdp_render_bg(line, 0);
  vdp_render_sprites(line, 0);
  vdp_render_bg(line, 1);
  vdp_render_sprites(line, 1);
}

U0 vdp_set_buffers(U8 *screen_buffer, U8 *scaled_buffer) {
  screen = screen_buffer;
  scaled_screen = scaled_buffer;
}

U0 vdp_debug_status(U8 *s) {
  /*
I64 i = 0;
s[0] = 0;
s += sprintf(s, "VDP: ");
s += sprintf(s, "%04x ", vdp_status);
for (i = 0; i < 0x20; i++) {
  if (!(i % 16))
    s += sprintf(s, "\n");
  s += sprintf(s, "%02x ", vdp_reg[i]);
}
*/
}

U0 vdp_data_write(U32 value, I64 type, I64 dma) {
  if (type == T_VRAM) /* VRAM write */
  {
    VRAM[control_address] = (value >> 8) & 0xff;
    VRAM[control_address + 1] = (value)&0xff;
  } else if (type == T_CRAM) /* CRAM write */
  {
    CRAM[(control_address & 0x7f) >> 1] = value;
  } else if (type == T_VSRAM) /* VSRAM write */
  {
    VSRAM[(control_address & 0x7f) >> 1] = value;
  }
}

U0 vdp_data_port_write(U32 value) {
  if (control_code & 1) /* check if write is set */
  {
    I64 type;
    if ((control_code & 0xe) == 0) /* VRAM write */
    {
      type = T_VRAM;
    } else if ((control_code & 0xe) == 2) /* CRAM write */
    {
      type = T_CRAM;
    } else if ((control_code & 0xe) == 4) /* VSRAM write */
    {
      type = T_VSRAM;
    }
    vdp_data_write(value, type, 0);
  }
  control_address = (control_address + vdp_reg[15]) & 0xffff;
  control_pending = 0;

  /* if a DMA is scheduled, do it */
  if (dma_fill) {
    dma_fill = 0;
    dma_length = vdp_reg[19] | (vdp_reg[20] << 8);
    while (dma_length--) {
      VRAM[control_address] = value >> 8;
      control_address += vdp_reg[15];
      control_address &= 0xffff;
    }
  }
}

U0 vdp_set_reg(I64 _reg, U8 value) {
  if (vdp_reg[1] & 4 || _reg <= 10)
    vdp_reg[_reg] = value;

  control_code = 0;
}

U32 vdp_get_reg(I64 _reg) { return vdp_reg[_reg]; }

U0 vdp_control_write(U32 value) {
  if (!control_pending) {
    if ((value & 0xc000) == 0x8000) {
      I64 _reg = (value >> 8) & 0x1f;
      U8 reg_value = value & 0xff;

      vdp_set_reg(_reg, reg_value);
    } else {
      control_code = (control_code & 0x3c) | ((value >> 14) & 3);
      control_address = (control_address & 0xc000) | (value & 0x3fff);
      control_pending = 1;
    }
  } else {
    control_code = (control_code & 3) | ((value >> 2) & 0x3c);
    control_address = (control_address & 0x3fff) | ((value & 3) << 14);
    control_pending = 0;

    if ((control_code & 0x20) && (vdp_reg[1] & 0x10)) {
      if ((vdp_reg[23] >> 6) == 2 && (control_code & 7) == 1) {
        /* DMA fill */
        dma_fill = 1;
      } else if ((vdp_reg[23] >> 6) == 3) {
        /* DMA copy */
        // printf("DMA copy\n");
      } else {
        /* DMA 68k -> VDP */
        dma_length = vdp_reg[19] | (vdp_reg[20] << 8);
        dma_source =
            (vdp_reg[21] << 1) | (vdp_reg[22] << 9) | (vdp_reg[23] << 17);

        U32 word;
        I64 type;
        if ((control_code & 0x7) == 1) {
          type = T_VRAM;
        } else if ((control_code & 0x7) == 3) {
          type = T_CRAM;
        } else if ((control_code & 0x7) == 5) {
          type = T_VSRAM;
        }

        while (dma_length--) {
          word = m68k_read_memory_16(dma_source);
          dma_source += 2;
          vdp_data_write(word, type, 1);
          control_address += vdp_reg[15];
          control_address &= 0xffff;
        }
      }
    }
  }
}

U0 vdp_write(U32 address, U32 value) {
  address &= 0x1f;

  if (address < 0x04) {
    vdp_data_port_write(value);
  } else if (address >= 0x04 && address < 0x08) {
    vdp_control_write(value);
  } else {
    // printf("vdp_write(%x, %x)\n", address, value);
  }
}

U32 vdp_read(U32 address) {
  address &= 0x1f;

  if (0 && address < 0x04) {
  } else if (address >= 0x04 && address < 0x08) {
    /* VDP status */
    return vdp_status;
  } else if (address >= 0x08 && address < 0x10) {
    /* V/H counter */
    I64 vcounter, hcounter;

    vcounter = cycle_counter / MCYCLES_PER_LINE - 1;
    if (vcounter > T(vdp_reg[1] & 0x08, 262, 234)) {
      vcounter -= lines_per_frame;
    }

    if (vdp_reg[12] & 0x01) {
      hcounter = 0;
    } else {
      hcounter = ((cycle_counter + 10) % MCYCLES_PER_LINE) / 20;
      if (hcounter >= 12)
        hcounter += 0x56;
      hcounter += 0x85;
    }

    if (address & 1)
      return hcounter & 0xff;
    else
      return vcounter & 0xff;
  } else {
    // printf("vdp_read(%x)\n", address);
  }
  return 0;
}

U32 vdp_get_status() { return vdp_status; }

U16 vdp_get_cram(I64 index) { return CRAM[index & 0x3f]; }

U0 vdp_set_hblank() { vdp_status |= 4; }
U0 vdp_clear_hblank() { vdp_status &= ~4; }
U0 vdp_set_vblank() { vdp_status |= 8; }
U0 vdp_clear_vblank() { vdp_status &= ~8; }