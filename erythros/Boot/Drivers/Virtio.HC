//
// PCI virtio I/O registers.
//

#define VIRTIO_PCI_HOST_FEATURES 0  // Features supported by the host
#define VIRTIO_PCI_GUEST_FEATURES 4 // Features activated by the guest
#define VIRTIO_PCI_QUEUE_PFN 8      // PFN for the currently selected queue
#define VIRTIO_PCI_QUEUE_SIZE 12 // Queue size for the currently selected queue
#define VIRTIO_PCI_QUEUE_SEL 14  // Queue selector
#define VIRTIO_PCI_QUEUE_NOTIFY 16 // Queue notifier
#define VIRTIO_PCI_STATUS 18       // Device status register
#define VIRTIO_PCI_ISR 19          // Interrupt status register
#define VIRTIO_PCI_CONFIG 20       // Configuration data block

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

class @virtio_queue_buf {
  U64 address;
  U32 length;
  U16 flags;
  U16 next;
};
class @virtio_avail {
  U16 flags;
  U16 index;
  U16 ring[256];
  U16 int_index;
};
class @virtio_used_item {
  U32 index;
  U32 length;
};
class @virtio_used {
  U16 flags;
  U16 index;
  @virtio_used_item ring[256];
  U16 int_index;
};
class @virtio_queue {
  @virtio_queue_buf buffers[256];
  @virtio_avail available;
  U8 padding[3578];
  @virtio_used used;
};

class @virtio_avail_buf {
  U32 index;
  U64 address;
  U32 length;
};

class @virtio_buf_info {
  U8 *buffer;
  U64 size;
  U8 flags;

  // If the user wants to keep same buffer as passed in this struct, use "true".
  // otherwise, the supplied buffer will be copied in the queues' buffer
  Bool copy;
};

"virtio ";