//
// PCI virtio status register bits
//

#define VIRTIO_CONFIG_S_ACKNOWLEDGE 1
#define VIRTIO_CONFIG_S_DRIVER 2
#define VIRTIO_CONFIG_S_DRIVER_OK 4
#define VIRTIO_CONFIG_S_FAILED 0x80

//
// Ring descriptor flags
//

#define VRING_DESC_F_NEXT 1     // Buffer continues via the next field
#define VRING_DESC_F_WRITE 2    // Buffer is write-only (otherwise read-only)
#define VRING_DESC_F_INDIRECT 4 // Buffer contains a list of buffer descriptors

#define VIRTIO_PCI_VRING_ALIGN 4096

class @virtio_tablet_queue_buf {
  U64 address;
  U32 length;
  U16 flags;
  U16 next;
};
class @virtio_tablet_avail {
  U16 flags;
  U16 index;
  U16 ring[64];
  U16 int_index;
};
class @virtio_tablet_used_item {
  U32 index;
  U32 length;
};
class @virtio_tablet_used {
  U16 flags;
  U16 index;
  @virtio_tablet_used_item ring[64];
  U16 int_index;
};

class @virtio_tablet_queue {
  @virtio_tablet_queue_buf buffers[64];
  @virtio_tablet_avail available;
  U8 padding[2938];
  @virtio_tablet_used used;
};

/* Common configuration */
#define VIRTIO_PCI_CAP_COMMON_CFG 1
/* Notifications */
#define VIRTIO_PCI_CAP_NOTIFY_CFG 2
/* ISR Status */
#define VIRTIO_PCI_CAP_ISR_CFG 3
/* Device specific configuration */
#define VIRTIO_PCI_CAP_DEVICE_CFG 4
/* PCI configuration access */
#define VIRTIO_PCI_CAP_PCI_CFG 5

/* Fields in VIRTIO_PCI_CAP_COMMON_CFG: */
class @virtio_tablet_pci_common_cfg {
  /* About the whole device. */
  U32 device_feature_select; /* read-write */
  U32 device_feature;        /* read-only */
  U32 guest_feature_select;  /* read-write */
  U32 guest_feature;         /* read-write */
  U16 msix_config;           /* read-write */
  U16 num_queues;            /* read-only */
  U8 device_status;          /* read-write */
  U8 config_generation;      /* read-only */

  /* About a specific virtqueue. */
  U16 queue_select;                     /* read-write */
  U16 queue_size;                       /* read-write, power of 2. */
  U16 queue_msix_vector;                /* read-write */
  U16 queue_enable;                     /* read-write */
  U16 queue_notify_off;                 /* read-only */
  @virtio_tablet_queue_buf *queue_desc; /* read-write */
  @virtio_tablet_avail *queue_avail;    /* read-write */
  @virtio_tablet_used *queue_used;      /* read-write */
};

class @virtio_tablet_pci_notify_cap {
  @pci_cap cap;
  U32 notify_off_multiplier; /* Multiplier for queue_notify_off. */
};
#define VIRTIO_INPUT_CFG_UNSET 0x00
#define VIRTIO_INPUT_CFG_ID_NAME 0x01
#define VIRTIO_INPUT_CFG_ID_SERIAL 0x02
#define VIRTIO_INPUT_CFG_ID_DEVIDS 0x03
#define VIRTIO_INPUT_CFG_PROP_BITS 0x10
#define VIRTIO_INPUT_CFG_EV_BITS 0x11
#define VIRTIO_INPUT_CFG_ABS_INFO 0x12

#define ABS_X 0x00
#define ABS_Y 0x01

  /*
   * Event types
   */

#define EV_SYN 0x00
#define EV_KEY 0x01
#define EV_REL 0x02
#define EV_ABS 0x03
#define EV_MSC 0x04
#define EV_SW 0x05
#define EV_LED 0x11
#define EV_SND 0x12
#define EV_REP 0x14
#define EV_FF 0x15
#define EV_PWR 0x16
#define EV_FF_STATUS 0x17
#define EV_MAX 0x1f
#define EV_CNT (EV_MAX + 1)

#define MS_BTN_LEFT 0x0110
#define MS_BTN_RIGHT 0x0111
#define MS_BTN_MIDDLE 0x0112

#define MS_WHEEL_UP 0x0151
#define MS_WHEEL_DN 0x0150

#define BTN_DOWN 1
#define BTN_UP 0

class @virtio_tablet_input_event {
  U16 type;
  U16 code;
  U32 value;
};

class @virtio_tablet_input_absinfo {
  U32 min;
  U32 max;
  U32 fuzz;
  U32 flat;
  U32 res;
};

class @virtio_tablet_input_devids {
  U16 bustype;
  U16 vendor;
  U16 product;
  U16 version;
};

class @virtio_tablet_input_config {
  U8 select;
  U8 subsel;
  U8 size;
  U8 reserved[5];
  union {
    U8 string[128];
    U8 bitmap[128];
    @virtio_tablet_input_absinfo abs;
    @virtio_tablet_input_devids ids;
  };
};

class @virtio_tablet_ms {
  I64 x;
  I64 y;
  I64 z;
  Bool lb;
  Bool cb;
  Bool rb;
  U16 abs_x_max;
  U16 abs_y_max;
};

class @virtio_tablet_pci {
  @pci_info pci;
  @virtio_tablet_pci_common_cfg *common;
  @virtio_tablet_input_config *cfg;
  @virtio_tablet_ms ms;
  I16 idx;
  I64 queue_size;
  U0 (*Init)();
};

@virtio_tablet_pci VirtioTablet;

I64 lerp(U32 val, U32 mx1, U32 mx2) {
  F64 r = (val & mx1) / ToF64(mx1);
  return ToI64(r * mx2);
}

U0 @virtio_tablet_update() {
  @virtio_tablet_input_event *evt;
  @virtio_tablet_queue *eventq = VirtioTablet.common->queue_desc;
  VirtioTablet.common->queue_avail->index += 6;
  if (VirtioTablet.common->queue_used->index == VirtioTablet.idx)
    return;
  for (; VirtioTablet.idx < VirtioTablet.common->queue_used->index;
       VirtioTablet.idx++) {
    evt = eventq->buffers[VirtioTablet.idx % VirtioTablet.queue_size].address;
    switch (evt->type) {
    case EV_KEY:
      switch (evt->code) {
      case MS_BTN_LEFT:
        VirtioTablet.ms.lb = evt->value;
        break;
      case MS_BTN_RIGHT:
        VirtioTablet.ms.rb = evt->value;
        break;
      case MS_WHEEL_UP:
        VirtioTablet.ms.z--;
        break;
      case MS_WHEEL_DN:
        VirtioTablet.ms.z++;
        break;
      }
      break;
    case EV_ABS:
      switch (evt->code) {
      case ABS_X:
        VirtioTablet.ms.x =
            lerp(evt->value, VirtioTablet.ms.abs_x_max, Display.Width());
        break;
      case ABS_Y:
        VirtioTablet.ms.y =
            lerp(evt->value, VirtioTablet.ms.abs_y_max, Display.Height());
        break;
      }
      break;
    case EV_SYN:
      Mouse.x = VirtioTablet.ms.x;
      Mouse.y = VirtioTablet.ms.y;
      Mouse.left = VirtioTablet.ms.lb;
      Mouse.right = VirtioTablet.ms.rb;
      ms.lb = Mouse.left;
      ms.rb = Mouse.right;
      ms.pos.z = VirtioTablet.ms.z;
      break;
    }
  }
}

I64 @virtio_tablet_init() {
  I64 i;
  I64 j;
  U64 cap_addr;

  VirtioTablet.idx = 0;
  VirtioTablet.ms.x = 0;
  VirtioTablet.ms.y = 0;
  VirtioTablet.ms.z = 0;
  VirtioTablet.ms.lb = 0;
  VirtioTablet.ms.cb = 0;
  VirtioTablet.ms.rb = 0;

  // Scan for device
  j = PCIClassFind(0x098000, 0);
  if (j < 0) {
  device_not_found:
    // AdamLog("\n[Virtio-tablet-pci] Device not found\n");
    return -1;
  }

  @get_pci_info(j, &VirtioTablet.pci);

  if (VirtioTablet.pci.vendor_id != 0x1AF4 ||
      VirtioTablet.pci.device_id != 0x1052)
    goto device_not_found;

  @pci_cap cap;
  for (i = 0; i < 4; i++) {
    @get_pci_cap(j, &cap, i);
    cap_addr = (VirtioTablet.pci.bar[cap.bar] & 0xFFFFFFF0) + cap.offset;
    switch (cap.cfg_type) {
    case VIRTIO_PCI_CAP_COMMON_CFG:
      VirtioTablet.common = cap_addr;
      break;
    case VIRTIO_PCI_CAP_DEVICE_CFG:
      VirtioTablet.cfg = cap_addr;
      break;
    }
  }

  // Display device name
  VirtioTablet.cfg->select = VIRTIO_INPUT_CFG_ID_NAME;
  VirtioTablet.cfg->subsel = 0;
  // AdamLog("\n[Virtio-tablet-pci] Device found: %s\n",
  // VirtioTablet.cfg->string);

  // Get absolute x/y max values
  VirtioTablet.cfg->select = VIRTIO_INPUT_CFG_ABS_INFO;
  VirtioTablet.cfg->subsel = ABS_X;
  VirtioTablet.ms.abs_x_max = VirtioTablet.cfg->abs.max;
  VirtioTablet.cfg->subsel = ABS_Y;
  VirtioTablet.ms.abs_y_max = VirtioTablet.cfg->abs.max;

  // Unset config query
  VirtioTablet.cfg->select = VIRTIO_INPUT_CFG_UNSET;
  VirtioTablet.cfg->subsel = 0;

  // Reset device
  VirtioTablet.common->device_status = 0;

  VirtioTablet.queue_size = VirtioTablet.common->queue_size;

  // Set up eventq
  @virtio_tablet_queue *eventq = CAllocAligned(
      sizeof(@virtio_tablet_queue), VIRTIO_PCI_VRING_ALIGN, Fs->code_heap);
  VirtioTablet.common->queue_select = 0;
  VirtioTablet.common->queue_desc = eventq;
  VirtioTablet.common->queue_avail = &eventq->available;
  VirtioTablet.common->queue_used = &eventq->used;
  for (i = 0; i < VirtioTablet.queue_size; i++) {
    VirtioTablet.common->queue_desc[i].address =
        CAlloc(sizeof(@virtio_tablet_input_event));
    VirtioTablet.common->queue_desc[i].length =
        sizeof(@virtio_tablet_input_event);
    VirtioTablet.common->queue_desc[i].flags = VRING_DESC_F_WRITE;
    VirtioTablet.common->queue_desc[i].next = 0;
    VirtioTablet.common->queue_avail->ring[i] = i;
  }
  VirtioTablet.common->queue_avail->index = 0;
  VirtioTablet.common->queue_enable = 1;

  // Enable device
  VirtioTablet.common->device_status = VIRTIO_CONFIG_S_DRIVER_OK;

  Mouse.Update = &@virtio_tablet_update;
  @mouse_integration_type_set(MI_QEMU);
  "\x1b[33mVirtio-tablet-pci device detected, enabling mouse "
  "integration\x1b[0m\n";
}

VirtioTablet.Init = &@virtio_tablet_init;

"virtio-tablet ";