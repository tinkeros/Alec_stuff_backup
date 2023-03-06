U16 htons(U16 h) {
    return ((h >> 8) | (h << 8)) & 0xffff;
}

U16 ntohs(U16 h) {
    return ((h >> 8) | (h << 8)) & 0xffff;
}

U32 htonl(U32 h) {
    return ((h >> 24) | ((h & 0x00ff0000) >> 8) | ((h & 0x0000ff00) << 8) | (h << 24)) & 0xffffffff;
}

U32 ntohl(U32 h) {
    return ((h >> 24) | ((h & 0x00ff0000) >> 8) | ((h & 0x0000ff00) << 8) | (h << 24)) & 0xffffffff;
}
