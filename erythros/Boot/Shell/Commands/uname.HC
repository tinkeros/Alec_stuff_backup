#define @shell_cmd_uname_opt_s 0
#define @shell_cmd_uname_opt_n 1
#define @shell_cmd_uname_opt_r 2
#define @shell_cmd_uname_opt_v 3
#define @shell_cmd_uname_opt_m 4
#define @shell_cmd_uname_opt_p 5
#define @shell_cmd_uname_opt_i 6
#define @shell_cmd_uname_opt_o 7
#define @shell_cmd_uname_opt_a 8

I64 @shell_cmd_uname(@shell *sh, I64 argc, U8 **argv) {
  I64 i;
  CDateStruct *ds = CAlloc(sizeof(CDateStruct));
  Date2Struct(ds, sys_compile_time);
  U8 *options_list = "snrvmpioa";
  U64 options_err = NULL;
  U8 *ds_m = "JanFebMarAprMayJunJulAugSepOctNovDec";
  U8 *ds_d = "SunMonTueWedThuFriSat";
  U8 *ds_mm = "   ";
  U8 *ds_dd = "   ";
  U8 buf[512];
  I64 flags = NULL;
  StrCpy(&buf, "");
  if (argc < 2)
    flags |= 1 << @shell_cmd_uname_opt_s;
  switch (
      @shell_parse_opts(sh, options_list, argc, argv, &flags, &options_err)) {
  case SHELL_OPTS_ERR_INVALID_OPT:
    StrPrint(&buf, "uname: invalid option -- '%s'\n", options_err);
    Stdio.WriteLine(sh, &buf);
    break;
  case SHELL_OPTS_ERR_EXTRA_OPD:
    StrPrint(&buf, "uname: extra operand '%s'\n", options_err);
    Stdio.WriteLine(sh, &buf);
    break;
  default:
    break;
  }
  if (options_err) {
    Free(options_err);
    Free(ds);
    return 1;
  }
  if (flags & 1 << @shell_cmd_uname_opt_a)
    flags = 0x01FF; // Set all options.
  for (i = 0; i < 8; i++) {
    switch (flags & 1 << i) {
    case 1 << @shell_cmd_uname_opt_s:
      String.Append(&buf, Define("DD_OS_NAME_VERSION"));
      *StrLastOcc(&buf, "V") = NULL;
      break;
    case 1 << @shell_cmd_uname_opt_n:
      String.Append(&buf, "%s ", &sh->session->hostname);
      break;
    case 1 << @shell_cmd_uname_opt_r:
      String.Append(&buf, "%1.2f ", sys_os_version);
      break;
    case 1 << @shell_cmd_uname_opt_v:
      MemCpy(ds_mm, ds_m + ((ds->mon - 1) * 3), 3);
      MemCpy(ds_dd, ds_d + (ds->day_of_week * 3), 3);
      String.Append(&buf, "%s %s %d %02d:%02d:%02d UTC %d ", ds_dd, ds_mm,
                    ds->day_of_mon, ds->hour, ds->min, ds->sec, ds->year);
      break;
    case 1 << @shell_cmd_uname_opt_m:
    case 1 << @shell_cmd_uname_opt_p:
    case 1 << @shell_cmd_uname_opt_i:
      String.Append(&buf, "x86_64 ");
      break;
    case 1 << @shell_cmd_uname_opt_o:
      String.Append(&buf, "Erythros ");
      break;
    default:
      break;
    }
  }
  Stdio.WriteLine(sh, &buf);
  Stdio.WriteLine(sh, "\n");
  Free(ds);
  return 0;
}