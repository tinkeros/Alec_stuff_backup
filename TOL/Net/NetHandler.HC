U0 @virtio_net_handle_net_fifo_entry(CNetFifoEntry *e) {
  CEthFrame l2_frame;

  if (EthernetFrameParse(&l2_frame, e->frame, e->length) < 0)
    return;

  CL3Protocol *l3 = l3_protocols;

  while (l3) {
    if (l3->ethertype == l2_frame.ethertype) {
      l3->handler(&l2_frame);
      break;
    }
    l3 = l3->next;
  }
}

U0 @virtio_net_handler_task() {
  I64 idx_used, idx_rec;
  I64 i, j;
  @virtio_used_item *item;
  U8 *buffer;
  I64 length;
  while (1) {
    idx_rec = VirtioNet.rq_index;
    idx_used = VirtioNet.rq->used.index;

    if (idx_used < idx_rec) {
      idx_used += 0x10000;
    }

    if (idx_rec != idx_used && idx_used) {

      j = 0;
      for (i = idx_rec; i < idx_used; i++) {
        item = VirtioNet.rq->used.ring;
        buffer = VirtioNet.rq->buffers[item[i % 256].index + 1];
        length = item[i % 256].length;
        NetFifoPushCopy(buffer, length - 10);
        j++;
        VirtioNet.rx_packets++;
        VirtioNet.rx_bytes += length - 10;
      }
      VirtioNet.rq_index = idx_used % 0x10000;
      VirtioNet.rq->available.index += j;
      OutU16(VirtioNet.port + VIRTIO_PCI_QUEUE_NOTIFY, 0);
    }
    CNetFifoEntry *e = NetFifoPull;
    if (e) {
      @virtio_net_handle_net_fifo_entry(e);
    }
    Busy(200);
  }
}

Spawn(&@virtio_net_handler_task, NULL, "NetHandlerTask", 2);

"[OK] NetHandler \n";