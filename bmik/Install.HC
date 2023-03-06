U0 Install() {
  "Primary IDE base0 (0x01F0): ";
  U8 *pri_base0 = GetStr;
  if (!StrCmp(pri_base0, ""))
    pri_base0 = "0x01F0";
  "Primary IDE base1 (0x03F6): ";
  U8 *pri_base1 = GetStr;
  if (!StrCmp(pri_base1, ""))
    pri_base1 = "0x03F6";
  "Secondary IDE base0 (0x0170): ";
  U8 *sec_base0 = GetStr;
  if (!StrCmp(sec_base0, ""))
    sec_base0 = "0x0170";
  "Secondary IDE base1 (0x0376): ";
  U8 *sec_base1 = GetStr;
  if (!StrCmp(sec_base1, ""))
    sec_base1 = "0x0376";
  Copy("T:/KMain.HC", "::/Kernel/KMain.HC");
  Copy("T:/Src/DskAddDev.HC", "::/Kernel/BlkDev/DskAddDev.HC.Z");
  Copy("T:/Src/DskATA.HC", "::/Kernel/BlkDev/DskATA.HC.Z");
  Copy("T:/Src/BootHelper.HC", "::/Home/BootHelper.HC.Z");
  CDoc *doc1 = DocNew("::/Kernel/BlkDev/DskATAId.HC.Z");
  CDoc *doc2 = DocRead("T:/Src/DskATAId.HC");
  DocPrint(doc1, "#define BMIK_PRI_BASE0 %s\n", pri_base0);
  DocPrint(doc1, "#define BMIK_PRI_BASE1 %s\n", pri_base1);
  DocPrint(doc1, "#define BMIK_SEC_BASE0 %s\n", sec_base0);
  DocPrint(doc1, "#define BMIK_SEC_BASE1 %s\n", sec_base1);
  DocInsDoc(doc1, doc2);
  DocDel(doc2);
  DocWrite(doc1);
  DocDel(doc1);
  doc1 = DocNew("::/Home/Once.HC.Z");
  doc2 = DocRead("::/Home/Once.HC.Z");
  DocPrint(doc1, "#include \"BootHelper\"\n\n");
  DocInsDoc(doc1, doc2);
  DocDel(doc2);
  DocWrite(doc1);
  DocDel(doc1);
  XTalkWait(Fs, "Cd;\n");
  XTalkWait(Fs, "BootHDIns;\n");
  XTalkWait(Fs, "\n");
  XTalkWait(Fs, "C\ns");
  XTalkWait(Fs, "0x01F0\n");
  XTalkWait(Fs, "0x03F6\n");
  XTalkWait(Fs, "0\n\n\n");
}

Install;