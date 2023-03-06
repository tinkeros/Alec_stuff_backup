CDoc *@scratch_doldoc_ptr;
CDoc *@restore_doldoc_ptr;

U0 @disable_doldoc_output() {
  @scratch_doldoc_ptr = DocNew;
  @restore_doldoc_ptr = Fs->put_doc;
  Fs->put_doc = @scratch_doldoc_ptr;
}

U0 @enable_doldoc_output() {
  CDoc *tmp_doldoc = Fs->put_doc;
  Fs->put_doc = @restore_doldoc_ptr;
  DocDel(tmp_doldoc);
}

U64 EndianU64(U64 d) { // Swap big<-->little endian.
  I64 res = 0;
  res.u8[7] = d.u8[0];
  res.u8[6] = d.u8[1];
  res.u8[5] = d.u8[2];
  res.u8[4] = d.u8[3];
  res.u8[3] = d.u8[4];
  res.u8[2] = d.u8[5];
  res.u8[1] = d.u8[6];
  res.u8[0] = d.u8[7];
  return res;
}