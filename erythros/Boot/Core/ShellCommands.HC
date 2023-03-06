extern I64 @systemstarter_open(@shell *sh, I64 argc, U8 **argv);

CDirEntry *sc_de = FilesFind("/Shell/Commands/*.HC");
CDirEntry *sc_de2 = sc_de;
while (sc_de2) {
  if (!(!StrCmp(sc_de2->name, ".") && !StrCmp(sc_de2->name, ".."))) {
    ExeDoc(DocRead(sc_de2->full_name));
  }
  sc_de2 = sc_de2->next;
}
DirTreeDel(sc_de);

"shellcommands ";