U0 Install()
{
  "\nInstall to Hard Disk";
  if (YorN) {
    DirMk("::/Apps/tosdemo");
    CopyTree("./","::/Apps/tosdemo/");
    Cd("::/Apps/tosdemo");
  }
}

Install;