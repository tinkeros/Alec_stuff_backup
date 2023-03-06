# rtl8139

RTL8139 Ethernet driver for TempleOS

# Usage

`rtl8139_rx_packet(U8 *data, I64 *len)` : `*len` will be set to `-1` if no unread packets, otherwise `*len` will be set to length of data. `data` can be any pointer to a physical address large enough to hold `*len` bytes. 

`rtl8139_tx_packet(U8 *data, I64 len)` : `data` must be a pointer to a 32-bit physical address. 
