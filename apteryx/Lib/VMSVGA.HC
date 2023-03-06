class @vmsvga_info {
  U16 io_base;
  U32 *fifo;
  U16 width;
  U16 height;
  U16 bpp;
  U64 fb;
  U32 capabilities;
};

#define VMWGFX_FIFO_STATIC_SIZE (1024 * 1024)

#define VMSVGA_MAGIC 0x900000
#define VMSVGA_ID_2 (VMSVGA_MAGIC << 8 | 2)
#define VMSVGA_MOUSE_ID 1

#define VMSVGA_CAP_GMR 0x00100000

#define VMSVGA_CMD_INVALID_CMD 0
#define VMSVGA_CMD_UPDATE 1
#define VMSVGA_CMD_RECT_COPY 3
#define VMSVGA_CMD_DEFINE_CURSOR 19
#define VMSVGA_CMD_DEFINE_ALPHA_CURSOR 22
#define VMSVGA_CMD_UPDATE_VERBOSE 25
#define VMSVGA_CMD_FRONT_ROP_FILL 29
#define VMSVGA_CMD_FENCE 30
#define VMSVGA_CMD_ESCAPE 33
#define VMSVGA_CMD_DEFINE_SCREEN 34
#define VMSVGA_CMD_DESTROY_SCREEN 35
#define VMSVGA_CMD_DEFINE_GMRFB 36
#define VMSVGA_CMD_BLIT_GMRFB_TO_SCREEN 37
#define VMSVGA_CMD_BLIT_SCREEN_TO_GMRFB 38
#define VMSVGA_CMD_ANNOTATION_FILL 39
#define VMSVGA_CMD_ANNOTATION_COPY 40
#define VMSVGA_CMD_DEFINE_GMR2 41
#define VMSVGA_CMD_REMAP_GMR2 42

#define VMSVGA_REG_ID 0
#define VMSVGA_REG_ENABLE 1
#define VMSVGA_REG_WIDTH 2
#define VMSVGA_REG_HEIGHT 3
#define VMSVGA_REG_MAX_WIDTH 4
#define VMSVGA_REG_MAX_HEIGHT 5
#define VMSVGA_REG_DEPTH 6
#define VMSVGA_REG_BITS_PER_PIXEL 7 /* Current bpp in the guest */
#define VMSVGA_REG_PSEUDOCOLOR 8
#define VMSVGA_REG_RED_MASK 9
#define VMSVGA_REG_GREEN_MASK 10
#define VMSVGA_REG_BLUE_MASK 11
#define VMSVGA_REG_BYTES_PER_LINE 12
#define VMSVGA_REG_FB_START 13 /* (Deprecated) */
#define VMSVGA_REG_FB_OFFSET 14
#define VMSVGA_REG_VRAM_SIZE 15
#define VMSVGA_REG_FB_SIZE 16

/* ID 0 implementation only had the above registers  then the palette */
#define VMSVGA_REG_CAPABILITIES 17
#define VMSVGA_REG_MEM_START 18 /* (Deprecated) */
#define VMSVGA_REG_MEM_SIZE 19
#define VMSVGA_REG_CONFIG_DONE 20 /* Set when memory area configured */
#define VMSVGA_REG_SYNC 21        /* See "FIFO Synchronization Registers" */
#define VMSVGA_REG_BUSY 22        /* See "FIFO Synchronization Registers" */
#define VMSVGA_REG_GUEST_ID 23    /* Set guest OS identifier */
#define VMSVGA_REG_CURSOR_ID 24   /* (Deprecated) */
#define VMSVGA_REG_CURSOR_X 25    /* (Deprecated) */
#define VMSVGA_REG_CURSOR_Y 26    /* (Deprecated) */
#define VMSVGA_REG_CURSOR_ON 27   /* (Deprecated) */
#define VMSVGA_REG_HOST_BITS_PER_PIXEL 28 /* (Deprecated) */
#define VMSVGA_REG_SCRATCH_SIZE 29        /* Number of scratch registers */
#define VMSVGA_REG_MEM_REGS 30            /* Number of FIFO registers */
#define VMSVGA_REG_NUM_DISPLAYS 31        /* (Deprecated) */
#define VMSVGA_REG_PITCHLOCK 32           /* Fixed pitch for all modes */
#define VMSVGA_REG_IRQMASK 33             /* Interrupt mask */

/* Legacy multi-monitor support */
#define VMSVGA_REG_NUM_GUEST_DISPLAYS                                          \
  34 /* Number of guest displays in X/Y direction */
#define VMSVGA_REG_DISPLAY_ID                                                  \
  35 /* Display ID for the following display attributes */
#define VMSVGA_REG_DISPLAY_IS_PRIMARY                                          \
  36                                     /* Whether this is a primary display  \
                                          */
#define VMSVGA_REG_DISPLAY_POSITION_X 37 /* The display position x */
#define VMSVGA_REG_DISPLAY_POSITION_Y 38 /* The display position y */
#define VMSVGA_REG_DISPLAY_WIDTH 39      /* The display's width */
#define VMSVGA_REG_DISPLAY_HEIGHT 40     /* The display's height */

/* See "Guest memory regions" below. */
#define VMSVGA_REG_GMR_ID 41
#define VMSVGA_REG_GMR_DESCRIPTOR 42
#define VMSVGA_REG_GMR_MAX_IDS 43
#define VMSVGA_REG_GMR_MAX_DESCRIPTOR_LENGTH 44
#define VMSVGA_REG_TRACES                                                      \
  45 /* Enable trace-based updates even when FIFO is on */
#define VMSVGA_REG_GMRS_MAX_PAGES                                              \
  46 /* Maximum number of 4KB pages for all GMRs */
#define VMSVGA_REG_MEMORY_SIZE                                                 \
  47                      /* Total dedicated device memory excluding FIFO */
#define VMSVGA_REG_TOP 48 /* Must be 1 more than the last register */

#define VMSVGA_FIFO_MIN 0
#define VMSVGA_FIFO_MAX 1
#define VMSVGA_FIFO_NEXT_CMD 2
#define VMSVGA_FIFO_STOP 3
#define VMSVGA_FIFO_CAPABILITIES 4
#define VMSVGA_FIFO_FLAGS 5
#define VMSVGA_FIFO_FENCE 6
#define VMSVGA_FIFO_3D_HWVERSION 7
#define VMSVGA_FIFO_PITCHLOCK 8
#define VMSVGA_FIFO_CURSOR_ON 9
#define VMSVGA_FIFO_CURSOR_X 10
#define VMSVGA_FIFO_CURSOR_Y 11
#define VMSVGA_FIFO_CURSOR_COUNT 12
#define VMSVGA_FIFO_CURSOR_LAST_UPDATED 13
#define VMSVGA_FIFO_RESERVED 14
#define VMSVGA_FIFO_CURSOR_SCREEN_ID 15
#define VMSVGA_FIFO_DEAD 16
#define VMSVGA_FIFO_3D_HWVERSION_REVISED 17
#define VMSVGA_FIFO_3D_CAPS 18
#define VMSVGA_FIFO_3D_CAPS_LAST = 19
#define VMSVGA_FIFO_GUEST_3D_HWVERSION 20
#define VMSVGA_FIFO_FENCE_GOAL 21
#define VMSVGA_FIFO_BUSY 22
#define VMSVGA_FIFO_NUM_REGS 23

#define VMSVGA_FIFO_CAP_NONE 0
#define VMSVGA_FIFO_CAP_FENCE (1 << 0)
#define VMSVGA_FIFO_CAP_ACCELFRONT (1 << 1)
#define VMSVGA_FIFO_CAP_PITCHLOCK (1 << 2)
#define VMSVGA_FIFO_CAP_VIDEO (1 << 3)
#define VMSVGA_FIFO_CAP_CURSOR_BYPASS_3 (1 << 4)
#define VMSVGA_FIFO_CAP_ESCAPE (1 << 5)
#define VMSVGA_FIFO_CAP_RESERVE (1 << 6)
#define VMSVGA_FIFO_CAP_SCREEN_OBJECT (1 << 7)
#define VMSVGA_FIFO_CAP_GMR2 (1 << 8)
//#define VMSVGA_FIFO_CAP_3D_HWVERSION_REVISED  VMSVGA_FIFO_CAP_GMR2
#define VMSVGA_FIFO_CAP_SCREEN_OBJECT_2 (1 << 9)
#define VMSVGA_FIFO_CAP_DEAD (1 << 10)

@vmsvga_info vmsvga;
MemSet(&vmsvga, 0, sizeof(@vmsvga_info));

U32 @vmsvga_reg_read(I64 index) {
  OutU32(vmsvga.io_base, index);
  return InU32(vmsvga.io_base + 1);
}

U0 @vmsvga_reg_write(I64 index, U32 val) {
  OutU32(vmsvga.io_base, index);
  OutU32(vmsvga.io_base + 1, val);
}

U0 @vmsvga_fifo_write(U32 value) {
  /* Need to sync? */
  if ((vmsvga.fifo[VMSVGA_FIFO_NEXT_CMD] + sizeof(U32) ==
       vmsvga.fifo[VMSVGA_FIFO_STOP]) ||
      (vmsvga.fifo[VMSVGA_FIFO_NEXT_CMD] ==
           vmsvga.fifo[VMSVGA_FIFO_MAX] - sizeof(U32) &&
       vmsvga.fifo[VMSVGA_FIFO_STOP] == vmsvga.fifo[VMSVGA_FIFO_MIN])) {
    //"Syncing because of full fifo\n";
    // vmwareWaitForFB(pVMWARE);
  }
  vmsvga.fifo[vmsvga.fifo[VMSVGA_FIFO_NEXT_CMD] / sizeof(U32)] = value;
  if (vmsvga.fifo[VMSVGA_FIFO_NEXT_CMD] ==
      vmsvga.fifo[VMSVGA_FIFO_MAX] - sizeof(U32)) {
    vmsvga.fifo[VMSVGA_FIFO_NEXT_CMD] = vmsvga.fifo[VMSVGA_FIFO_MIN];
  } else {
    vmsvga.fifo[VMSVGA_FIFO_NEXT_CMD] += sizeof(U32);
  }
}

U0 @vmsvga_fifo_get_cap(U8 *s, I64 cap) {
  "%32s:", s;
  if ((vmsvga.fifo[VMSVGA_FIFO_CAPABILITIES] & cap) == cap)
    "%s\n", "True";
  else
    "%s\n", "False";
}

I64 @vmsvga_init(I64 w, I64 h, I64 bpp, U64 driver) {
  no_warn driver;
  I64 j;
  j = PCIClassFind(DISPLAY_DRIVER_VMSVGA, 0);
  if (j < 0) {
    //"VMSVGA device not found.\n";
    return -1;
  }
  vmsvga.io_base = PCIReadU16(j.u8[2], j.u8[1], j.u8[0], 0x10) & ~(0x0F);
  @vmsvga_reg_write(VMSVGA_REG_ID, VMSVGA_ID_2);
  if (@vmsvga_reg_read(VMSVGA_REG_ID) == VMSVGA_ID_2) {
    //"VMSVGA driver version 2 supported.\n";
  } else {
    //"VMSVGA device not supported.\n";
    return -1;
  }
  vmsvga.width = w;
  vmsvga.height = h;
  vmsvga.bpp = bpp;
  vmsvga.fb = @vmsvga_reg_read(VMSVGA_REG_FB_START);
  vmsvga.fifo = @vmsvga_reg_read(VMSVGA_REG_MEM_START);
  //"FIFO @ 0x%08X (%d bytes)\n", vmsvga.fifo,
  //    @vmsvga_reg_read(VMSVGA_REG_MEM_SIZE);
  @vmsvga_reg_write(VMSVGA_REG_WIDTH, vmsvga.width);
  @vmsvga_reg_write(VMSVGA_REG_HEIGHT, vmsvga.height);
  @vmsvga_reg_write(VMSVGA_REG_BITS_PER_PIXEL, vmsvga.bpp);
  @vmsvga_reg_write(VMSVGA_REG_ENABLE, 1);
  vmsvga.fifo[VMSVGA_FIFO_MIN] = 16;
  vmsvga.fifo[VMSVGA_FIFO_MAX] = 16 + (10 * 1024);
  vmsvga.fifo[VMSVGA_FIFO_NEXT_CMD] = 16;
  vmsvga.fifo[VMSVGA_FIFO_STOP] = 16;
  @vmsvga_reg_write(VMSVGA_REG_CONFIG_DONE, 0);
  @vmsvga_fifo_write(VMSVGA_CMD_UPDATE);
  @vmsvga_fifo_write(0);
  @vmsvga_fifo_write(0);
  @vmsvga_fifo_write(0);
  @vmsvga_fifo_write(0);
  @vmsvga_reg_write(VMSVGA_REG_CONFIG_DONE, 1);
  Display.width = vmsvga.width;
  Display.height = vmsvga.height;
  Display.bpp = vmsvga.bpp;
  Display.fb = vmsvga.fb;
  return 0;
}

U0 @vmsvga_mouse_pointer_set(U32 *pointer, I64 width, I64 height) {
  @vmsvga_reg_write(VMSVGA_REG_CONFIG_DONE, 0);
  @vmsvga_fifo_write(VMSVGA_CMD_DEFINE_ALPHA_CURSOR);
  @vmsvga_fifo_write(VMSVGA_MOUSE_ID);
  @vmsvga_fifo_write(0);
  @vmsvga_fifo_write(0);
  @vmsvga_fifo_write(width);
  @vmsvga_fifo_write(height);
  I64 x, y;
  for (y = 0; y < height; y++) {
    for (x = 0; x < width; x++) {
      @vmsvga_fifo_write(pointer[(y * width) + x]);
    }
  }
  @vmsvga_reg_write(VMSVGA_REG_CONFIG_DONE, 1);
}

U64 @vmsvga_get_framebuffer() { return vmsvga.fb; }

U0 @vmsvga_display_update() { @vmsvga_reg_write(VMSVGA_REG_ENABLE, 1); }

class @vmsvga {
  U0(*Init)
  (I64 w, I64 h, I64 bpp);
  U64(*FrameBuffer)
  ();
};

@vmsvga VMSVGA;
VMSVGA.FrameBuffer = &@vmsvga_get_framebuffer;
VMSVGA.Init = &@vmsvga_init;

Display.Init = &@vmsvga_init;