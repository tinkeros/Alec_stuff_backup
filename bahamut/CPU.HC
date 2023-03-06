extern I32 getAdr(I32 opcode, I32 mode);
extern U0 cpu_opcode(I32 instr, I32 adr, I32 adrh);

  // indexes in register arrays
#define DBR 0 // data bank register
#define K   1 // program bank

#define A   0
#define X   1
#define Y   2
#define SP  3
#define PC  4
#define DPR 5 // direct page register

  // addressing modes
#define IMP     0 // or ACC
#define IMM     1 // always 8 bit
#define IMMm    2 // size depends on m flag
#define IMMx    3 // size depends on x flag
#define IMMl    4 // always 16 bit
#define DP      5
#define DPX     6
#define DPY     7
#define IDP     8
#define IDX     9
#define IDY     10 // for RMW and writes
#define IDYr    11 // for reads
#define IDL     12
#define ILY     13
#define SR      14
#define ISY     15
#define ABS     16
#define ABX     17// for RMW and writes
#define ABXr    18// for reads
#define ABY     19// for RMW and writes
#define ABYr    20// for reads
#define ABL     21
#define ALX     22
#define IND     23
#define IAX     24
#define IAL     25
#define REL     26
#define RLL     27
#define BM      28// block move

    // memory handler
    //mem = mem;

    // registers
    U16 r[2];
    U16 br[6];

    // flags
    Bool n;
    Bool v;
    Bool m;
    Bool x;
    Bool d;
    Bool i;
    Bool z;
    Bool c;
    Bool e;

    //Bool irqWanted;
    //Bool nmiWanted;
    Bool aboWanted;
    
    Bool stopped;
    Bool waiting;
    
    //I32 cyclesLeft;

    
    // modes for each instruction
    I32 modes[259] = {
      IMP, IDX, IMM, SR , DP , DP , DP , IDL, IMP, IMMm,IMP, IMP, ABS, ABS, ABS, ABL,
      REL, IDYr,IDP, ISY, DP , DPX, DPX, ILY, IMP, ABYr,IMP, IMP, ABS, ABXr,ABX, ALX,
      ABS, IDX, ABL, SR , DP , DP , DP , IDL, IMP, IMMm,IMP, IMP, ABS, ABS, ABS, ABL,
      REL, IDYr,IDP, ISY, DPX, DPX, DPX, ILY, IMP, ABYr,IMP, IMP, ABXr,ABXr,ABX, ALX,
      IMP, IDX, IMM, SR , BM , DP , DP , IDL, IMP, IMMm,IMP, IMP, ABS, ABS, ABS, ABL,
      REL, IDYr,IDP, ISY, BM , DPX, DPX, ILY, IMP, ABYr,IMP, IMP, ABL, ABXr,ABX, ALX,
      IMP, IDX, RLL, SR , DP , DP , DP , IDL, IMP, IMMm,IMP, IMP, IND, ABS, ABS, ABL,
      REL, IDYr,IDP, ISY, DPX, DPX, DPX, ILY, IMP, ABYr,IMP, IMP, IAX, ABXr,ABX, ALX,
      REL, IDX, RLL, SR , DP , DP , DP , IDL, IMP, IMMm,IMP, IMP, ABS, ABS, ABS, ABL,
      REL, IDY, IDP, ISY, DPX, DPX, DPY, ILY, IMP, ABY, IMP, IMP, ABS, ABX, ABX, ALX,
      IMMx,IDX, IMMx,SR , DP , DP , DP , IDL, IMP, IMMm,IMP, IMP, ABS, ABS, ABS, ABL,
      REL, IDYr,IDP, ISY, DPX, DPX, DPY, ILY, IMP, ABYr,IMP, IMP, ABXr,ABXr,ABYr,ALX,
      IMMx,IDX, IMM, SR , DP , DP , DP , IDL, IMP, IMMm,IMP, IMP, ABS, ABS, ABS, ABL,
      REL, IDYr,IDP, ISY, DP , DPX, DPX, ILY, IMP, ABYr,IMP, IMP, IAL, ABXr,ABX, ALX,
      IMMx,IDX, IMM, SR , DP , DP , DP , IDL, IMP, IMMm,IMP, IMP, ABS, ABS, ABS, ABL,
      REL, IDYr,IDP, ISY, IMMl,DPX, DPX, ILY, IMP, ABYr,IMP, IMP, IAX, ABXr,ABX, ALX,
      IMP, IMP, IMP // abo, nmi, irq
    };

    // cycles for each instruction
    I32 cycles[259] = {
      7, 6, 7, 4, 5, 3, 5, 6, 3, 2, 2, 4, 6, 4, 6, 5,
      2, 5, 5, 7, 5, 4, 6, 6, 2, 4, 2, 2, 6, 4, 7, 5,
      6, 6, 8, 4, 3, 3, 5, 6, 4, 2, 2, 5, 4, 4, 6, 5,
      2, 5, 5, 7, 4, 4, 6, 6, 2, 4, 2, 2, 4, 4, 7, 5,
      6, 6, 2, 4, 7, 3, 5, 6, 3, 2, 2, 3, 3, 4, 6, 5,
      2, 5, 5, 7, 7, 4, 6, 6, 2, 4, 3, 2, 4, 4, 7, 5,
      6, 6, 6, 4, 3, 3, 5, 6, 4, 2, 2, 6, 5, 4, 6, 5,
      2, 5, 5, 7, 4, 4, 6, 6, 2, 4, 4, 2, 6, 4, 7, 5,
      3, 6, 4, 4, 3, 3, 3, 6, 2, 2, 2, 3, 4, 4, 4, 5,
      2, 6, 5, 7, 4, 4, 4, 6, 2, 5, 2, 2, 4, 5, 5, 5,
      2, 6, 2, 4, 3, 3, 3, 6, 2, 2, 2, 4, 4, 4, 4, 5,
      2, 5, 5, 7, 4, 4, 4, 6, 2, 4, 2, 2, 4, 4, 4, 5,
      2, 6, 3, 4, 3, 3, 5, 6, 2, 2, 2, 3, 4, 4, 6, 5,
      2, 5, 5, 7, 6, 4, 6, 6, 2, 4, 3, 3, 6, 4, 7, 5,
      2, 6, 3, 4, 3, 3, 5, 6, 2, 2, 2, 3, 4, 4, 6, 5,
      2, 5, 5, 7, 5, 4, 6, 6, 2, 4, 4, 2, 8, 4, 7, 5,
      7, 7, 7 // abo, nmi, irq
    };

    // function table is at bottom

    U0 cpu_reset() {

      r[DBR] = 0;
      r[K] = 0;

      br[A] = 0;
      br[X] = 0;
      br[Y] = 0;
      br[SP] = 0;
      br[DPR] = 0;

      //if(mem_read) {
        // read emulation mode reset vector
        br[PC] = mem_read(0xfffc) | (mem_read(0xfffd) << 8);
      //} else {
        // if read function is not defined yet
      //  br[PC] = 0;
      //}

      // flags
      n = FALSE;
      v = FALSE;
      m = TRUE;
      x = TRUE;
      d = FALSE;
      i = FALSE;
      z = FALSE;
      c = FALSE;
      e = TRUE;

      // interrupts wanted
      irqWanted = FALSE;
      nmiWanted = FALSE;
      aboWanted = FALSE;

      // power state
      stopped = FALSE;
      waiting = FALSE;

      // cycles left
      cyclesLeft = 7;

    }
    cpu_reset;

    U0 cpu_cycle() {
        I32 instr;
        I32 mode;
        I64 adrs;
      if(cyclesLeft == 0) {
        if(stopped) {
          // stopped
          cyclesLeft = 1;
        } else if(!waiting) {
          // read opcode byte
          instr = mem_read((r[K] << 16) | br[PC]++);
          cyclesLeft = cycles[instr];
          mode = modes[instr];
          // test for interrupt
          if((irqWanted && !i) || nmiWanted || aboWanted) {
            br[PC]--;
            if(aboWanted) {
              aboWanted = FALSE;
              instr = 0x100;
            } else if(nmiWanted) {
              nmiWanted = FALSE;
              instr = 0x101;
            } else {
              // irq (level sensitive instead of edge sensitive)
              instr = 0x102;
            }
            cyclesLeft = cycles[instr];
            mode = modes[instr];
          }
          // execute the instruction
          adrs = getAdr(instr, mode);
          // TEMP: log unknown instruction
          /*
          if(functions[instr] == undefined) {
            uni(adrs.u8[0], adrs.u8[1], instr);
          } else {
            functions[instr].call(this, adrs.u8[0], adrs.u8[1]);
          }
          */
          cpu_opcode(instr, adrs.i32[0], adrs.i32[1]);
        } else {
          // waiting on interrupt
          if(aboWanted || irqWanted || nmiWanted) {
            waiting = FALSE;
            // on next cycle, find the nmi or abort and start executing it,
            // or continue on as a fast irq if i is 1
          }
          cyclesLeft = 1;
        }
      }
      cyclesLeft--;
    }

    I32 cpu_getP() {
      I32 val = 0;
      val |= cond(n, 0x80, 0);
      val |= cond(v, 0x40, 0);
      val |= cond(m, 0x20, 0);
      val |= cond(x, 0x10, 0);
      val |= cond(d, 0x08, 0);
      val |= cond(i, 0x04, 0);
      val |= cond(z, 0x02, 0);
      val |= cond(c, 0x01, 0);
      return val;
    }

    U0 cpu_setP(I32 value) {
      n = (value & 0x80) > 0;
      v = (value & 0x40) > 0;
      m = (value & 0x20) > 0;
      x = (value & 0x10) > 0;
      d = (value & 0x08) > 0;
      i = (value & 0x04) > 0;
      z = (value & 0x02) > 0;
      c = (value & 0x01) > 0;
      if(x) {
        br[X] &= 0xff;
        br[Y] &= 0xff;
      }
    }

    U0 setZandN(I32 value, Bool byte) {
      // sets Zero and Negative depending on 8-bit or 16-bit value
      if(byte) {
        z = (value & 0xff) == 0;
        n = (value & 0x80) > 0;
        return;
      }
      z = (value & 0xffff) == 0;
      n = (value & 0x8000) > 0;
    }

    I16 getSigned(I32 value, Bool byte) {
      // turns unsinged value 0 - 255 or 0 - 65536
      // to signed -128 - 127 or -32768 - 32767
      if(byte) {
        return cond((value & 0xff) > 127, -(256 - (value & 0xff)), (value & 0xff));
      }
      return cond(value > 32767, -(65536 - value), value);
    }

    U0 doBranch(Bool check, I32 rel) {
      if(check) {
        // taken branch: 1 extra cycle
        cyclesLeft++;
        br[PC] += rel;
      }
    }

    U0 pushByte(I32 value) {
      mem_write(br[SP], value);
      br[SP]--;
    }

    U8 pullByte() {
      br[SP]++;
      return mem_read(br[SP]);
    }

    U0 pushWord(I32 value) {
      pushByte((value & 0xff00) >> 8);
      pushByte(value & 0xff);
    }

    U16 pullWord() {
      I32 value = pullByte();
      value |= pullByte() << 8;
      return value;
    }

    U16 readWord(I32 adr, I32 adrh) {
      U16 value = mem_read(adr);
      value |= mem_read(adrh) << 8;
      return value;
    }

    U0 writeWord(I32 adr, I32 adrh, I32 result, Bool reversed = FALSE) {
      if(reversed) {
        // RMW opcodes write the high byte first
        mem_write(adrh, (result & 0xff00) >> 8);
        mem_write(adr, result & 0xff);
      } else {
        mem_write(adr, result & 0xff);
        mem_write(adrh, (result & 0xff00) >> 8);
      }
    }

    I32 getAdr(I32 opcode, I32 mode) {
        no_warn opcode;
        I64 retval;
        I32 low;
        I32 adr;
        I32 rel;
        I32 dest;
        I32 src;
        I32 pointer;
      // gets the effective address (low and high), for the given adressing mode
      switch(mode) {
        case IMP: {
          // implied
          //return [0, 0];
          retval = 0;
          return retval;
        }

        case IMM: {
          // immediate, always 8 bit
          //return [(r[K] << 16) | br[PC]++, 0];
          retval.i32[0] = (r[K] << 16) | br[PC]++;
          retval.i32[1] = 0;
          return retval;
        }

        case IMMm: {
          // immediate, depending on m
          if(m) {
            //return [(r[K] << 16) | br[PC]++, 0];
            retval.i32[0] = (r[K] << 16) | br[PC]++;
            retval.i32[1] = 0;
            return retval;
          } else {
            low = (r[K] << 16) | br[PC]++;
            //return [low, (r[K] << 16) | br[PC]++];
            retval.i32[0] = low;
            retval.i32[1] = (r[K] << 16) | br[PC]++;
            return retval;
          }
        }

        case IMMx: {
          // immediate, depending on x
          if(x) {
            //return [(r[K] << 16) | br[PC]++, 0];
            retval.i32[0] = (r[K] << 16) | br[PC]++;
            retval.i32[1] = 0;
            return retval;

          } else {
            low = (r[K] << 16) | br[PC]++;
            //return [low, (r[K] << 16) | br[PC]++];
            retval.i32[0] = low;
            retval.i32[1] = (r[K] << 16) | br[PC]++;
            return retval;
          }
        }

        case IMMl: {
          // immediate, always 16 bit
          low = (r[K] << 16) | br[PC]++;
          //return [low, (r[K] << 16) | br[PC]++];
          retval.i32[0] = low;
          retval.i32[1] = (r[K] << 16) | br[PC]++;
          return retval;
        }

        case DP: {
          // direct page
          adr = mem_read((r[K] << 16) | br[PC]++);
          if((br[DPR] & 0xff) != 0) {
            // DPRl not 0: 1 extra cycle
            cyclesLeft++;
          }
          /*
          return [
            (br[DPR] + adr) & 0xffff,
            (br[DPR] + adr + 1) & 0xffff
          ];
          */
          retval.i32[0] = (br[DPR] + adr) & 0xffff;
          retval.i32[1] = (br[DPR] + adr + 1) & 0xffff;
          return retval;
        }

        case DPX: {
          // direct page indexed on X
          adr = mem_read((r[K] << 16) | br[PC]++);
          if((br[DPR] & 0xff) != 0) {
            // DPRl not 0: 1 extra cycle
            cyclesLeft++;
          }
          /*
          return [
            (br[DPR] + adr + br[X]) & 0xffff,
            (br[DPR] + adr + br[X] + 1) & 0xffff
          ];
          */
          retval.i32[0] = (br[DPR] + adr + br[X]) & 0xffff;
          retval.i32[1] = (br[DPR] + adr + br[X] + 1) & 0xffff;
          return retval;
        }

        case DPY: {
          // direct page indexed on Y
          adr = mem_read((r[K] << 16) | br[PC]++);
          if((br[DPR] & 0xff) != 0) {
            // DPRl not 0: 1 extra cycle
            cyclesLeft++;
          }
          /*
          return [
            (br[DPR] + adr + br[Y]) & 0xffff,
            (br[DPR] + adr + br[Y] + 1) & 0xffff
          ];
          */
          retval.i32[0] = (br[DPR] + adr + br[Y]) & 0xffff;
          retval.i32[1] = (br[DPR] + adr + br[Y] + 1) & 0xffff;
          return retval;
        }

        case IDP: {
          // direct indirect
          adr = mem_read((r[K] << 16) | br[PC]++);
          if((br[DPR] & 0xff) != 0) {
            // DPRl not 0: 1 extra cycle
            cyclesLeft++;
          }
          pointer = mem_read((br[DPR] + adr) & 0xffff);
          pointer |= (
            mem_read((br[DPR] + adr + 1) & 0xffff)
          ) << 8;
          /*
          return [
            (r[DBR] << 16) + pointer,
            (r[DBR] << 16) + pointer + 1
          ];
          */
          retval.i32[0] = (r[DBR] << 16) + pointer;
          retval.i32[1] = (r[DBR] << 16) + pointer + 1;
          return retval;

        }

        case IDX: {
          // direct indirect indexed
          adr = mem_read((r[K] << 16) | br[PC]++);
          if((br[DPR] & 0xff) != 0) {
            // DPRl not 0: 1 extra cycle
            cyclesLeft++;
          }
          pointer = mem_read(
            (br[DPR] + adr + br[X]) & 0xffff
          );
          pointer |= (
            mem_read((br[DPR] + adr + br[X] + 1) & 0xffff)
          ) << 8;
          /*
          return [
            (r[DBR] << 16) + pointer,
            (r[DBR] << 16) + pointer + 1
          ];
          */
          retval.i32[0] = (r[DBR] << 16) + pointer;
          retval.i32[1] = (r[DBR] << 16) + pointer + 1;
          return retval;

        }

        case IDY: {
          // indirect direct indexed, for RMW and writes
          adr = mem_read((r[K] << 16) | br[PC]++);
          if((br[DPR] & 0xff) != 0) {
            // DPRl not 0: 1 extra cycle
            cyclesLeft++;
          }
          pointer = mem_read((br[DPR] + adr) & 0xffff);
          pointer |= (
            mem_read((br[DPR] + adr + 1) & 0xffff)
          ) << 8;
          /*
          return [
            (r[DBR] << 16) + pointer + br[Y],
            (r[DBR] << 16) + pointer + br[Y] + 1
          ];
          */
          retval.i32[0] = (r[DBR] << 16) + pointer + br[Y];
          retval.i32[1] = (r[DBR] << 16) + pointer + br[Y] + 1;
          return retval;

        }

        case IDYr: {
          // indirect direct indexed, for reads (possible extra cycle)
          adr = mem_read((r[K] << 16) | br[PC]++);
          if((br[DPR] & 0xff) != 0) {
            // DPRl not 0: 1 extra cycle
            cyclesLeft++;
          }
          pointer = mem_read((br[DPR] + adr) & 0xffff);
          pointer |= (
            mem_read((br[DPR] + adr + 1) & 0xffff)
          ) << 8;
          if(((pointer >> 8) != ((pointer + br[Y]) >> 8)) || !x) {
            // if page is crossed, or x is 0: 1 extra cycle
            cyclesLeft++;
          }
          /*
          return [
            (r[DBR] << 16) + pointer + br[Y],
            (r[DBR] << 16) + pointer + br[Y] + 1
          ];
          */
          retval.i32[0] = (r[DBR] << 16) + pointer + br[Y];
          retval.i32[1] = (r[DBR] << 16) + pointer + br[Y] + 1;
          return retval;

        }

        case IDL: {
          // indirect direct long
          adr = mem_read((r[K] << 16) | br[PC]++);
          if((br[DPR] & 0xff) != 0) {
            // DPRl not 0: 1 extra cycle
            cyclesLeft++;
          }
          pointer = mem_read((br[DPR] + adr) & 0xffff);
          pointer |= (
            mem_read((br[DPR] + adr + 1) & 0xffff)
          ) << 8;
          pointer |= (
            mem_read((br[DPR] + adr + 2) & 0xffff)
          ) << 16;
          //return [pointer, pointer + 1];
          retval.i32[0] = pointer;
          retval.i32[1] = pointer + 1;
          return retval;

        }

        case ILY: {
          // indirect direct long indexed
          adr = mem_read((r[K] << 16) | br[PC]++);
          if((br[DPR] & 0xff) != 0) {
            // DPRl not 0: 1 extra cycle
            cyclesLeft++;
          }
          pointer = mem_read((br[DPR] + adr) & 0xffff);
          pointer |= (
            mem_read((br[DPR] + adr + 1) & 0xffff)
          ) << 8;
          pointer |= (
            mem_read((br[DPR] + adr + 2) & 0xffff)
          ) << 16;
          //return [pointer + br[Y], pointer + br[Y] + 1];
          retval.i32[0] = pointer + br[Y];
          retval.i32[1] = pointer + br[Y] + 1;
          return retval;

        }

        case SR: {
          // stack relative
          adr = mem_read((r[K] << 16) | br[PC]++);
          /*
          return [
            (br[SP] + adr) & 0xffff,
            (br[SP] + adr + 1) & 0xffff,
          ];
          */
          retval.i32[0] = (br[SP] + adr) & 0xffff;
          retval.i32[1] = (br[SP] + adr + 1) & 0xffff;
          return retval;

        }

        case ISY: {
          // stack relative indexed
          adr = mem_read((r[K] << 16) | br[PC]++);
          pointer = mem_read((br[SP] + adr) & 0xffff);
          pointer |= (
            mem_read((br[SP] + adr + 1) & 0xffff)
          ) << 8;
          /*
          return [
            (r[DBR] << 16) + pointer + br[Y],
            (r[DBR] << 16) + pointer + br[Y] + 1,
          ];
          */
          retval.i32[0] = (r[DBR] << 16) + pointer + br[Y];
          retval.i32[1] = (r[DBR] << 16) + pointer + br[Y] + 1;
          return retval;

        }

        case ABS: {
          // absolute
          adr = mem_read((r[K] << 16) | br[PC]++);
          adr |= mem_read((r[K] << 16) | br[PC]++) << 8;
          //return [(r[DBR] << 16) + adr, (r[DBR] << 16) + adr + 1];
          retval.i32[0] = (r[DBR] << 16) + adr;
          retval.i32[1] = (r[DBR] << 16) + adr + 1;
          return retval;

        }

        case ABX: {
          // absolute, indexed by X for RMW and writes
          adr = mem_read((r[K] << 16) | br[PC]++);
          adr |= mem_read((r[K] << 16) | br[PC]++) << 8;
          /*
          return [
            (r[DBR] << 16) + adr + br[X],
            (r[DBR] << 16) + adr + br[X] + 1
          ];
          */
          retval.i32[0] = (r[DBR] << 16) + adr + br[X];
          retval.i32[1] = (r[DBR] << 16) + adr + br[X] + 1;
          return retval;

        }

        case ABXr: {
          // absolute, indexed by X for reads (possible extra cycle)
          adr = mem_read((r[K] << 16) | br[PC]++);
          adr |= mem_read((r[K] << 16) | br[PC]++) << 8;
          if(((adr >> 8) != ((adr + br[X]) >> 8)) || !x) {
            // if page crossed or x is 0: 1 extra cycle
            cyclesLeft++;
          }
          /*
          return [
            (r[DBR] << 16) + adr + br[X],
            (r[DBR] << 16) + adr + br[X] + 1
          ];
          */
          retval.i32[0] = (r[DBR] << 16) + adr + br[X];
          retval.i32[1] = (r[DBR] << 16) + adr + br[X] + 1;
          return retval;

        }

        case ABY: {
          // absolute, indexed by Y for RMW and writes
          adr = mem_read((r[K] << 16) | br[PC]++);
          adr |= mem_read((r[K] << 16) | br[PC]++) << 8;
          /*
          return [
            (r[DBR] << 16) + adr + br[Y],
            (r[DBR] << 16) + adr + br[Y] + 1
          ];
          */
          retval.i32[0] = (r[DBR] << 16) + adr + br[Y];
          retval.i32[1] = (r[DBR] << 16) + adr + br[Y] + 1;
          return retval;

        }

        case ABYr: {
          // absolute, indexed by Y for reads (possible extra cycle)
          adr = mem_read((r[K] << 16) | br[PC]++);
          adr |= mem_read((r[K] << 16) | br[PC]++) << 8;
          if(((adr >> 8) != ((adr + br[Y]) >> 8)) || !x) {
            // if page crossed or x is 0: 1 extra cycle
            cyclesLeft++;
          }
          /*
          return [
            (r[DBR] << 16) + adr + br[Y],
            (r[DBR] << 16) + adr + br[Y] + 1
          ];
          */
          retval.i32[0] = (r[DBR] << 16) + adr + br[Y];
          retval.i32[1] = (r[DBR] << 16) + adr + br[Y] + 1;
          return retval;

        }

        case ABL: {
          // absoulte long
          adr = mem_read((r[K] << 16) | br[PC]++);
          adr |= mem_read((r[K] << 16) | br[PC]++) << 8;
          adr |= mem_read((r[K] << 16) | br[PC]++) << 16;
          //return [adr, adr + 1];
          retval.i32[0] = adr;
          retval.i32[1] = adr + 1;
          return retval;

        }

        case ALX: {
          // absoulte long indexed
          adr = mem_read((r[K] << 16) | br[PC]++);
          adr |= mem_read((r[K] << 16) | br[PC]++) << 8;
          adr |= mem_read((r[K] << 16) | br[PC]++) << 16;
          //return [adr + br[X], adr + br[X] + 1];
          retval.i32[0] = adr + br[X];
          retval.i32[1] = adr + br[X] + 1;
          return retval;

        }

        case IND: {
          // indirect
          adr = mem_read((r[K] << 16) | br[PC]++);
          adr |= mem_read((r[K] << 16) | br[PC]++) << 8;
          pointer = mem_read(adr);
          pointer |= mem_read((adr + 1) & 0xffff) << 8;
          //return [(r[K] << 16) + pointer, 0];
          retval.i32[0] = (r[K] << 16) + pointer;
          retval.i32[1] = 0;
          return retval;

        }

        case IAX: {
          // indirect indexed
          adr = mem_read((r[K] << 16) | br[PC]++);
          adr |= mem_read((r[K] << 16) | br[PC]++) << 8;
          pointer = mem_read(
            (r[K] << 16) | ((adr + br[X]) & 0xffff)
          );
          pointer |= mem_read(
            (r[K] << 16) | ((adr + br[X] + 1) & 0xffff)
          ) << 8;
          //return [(r[K] << 16) + pointer, 0];
          retval.i32[0] = (r[K] << 16) + pointer;
          retval.i32[1] = 0;
          return retval;

        }

        case IAL: {
          // indirect long
          adr = mem_read((r[K] << 16) | br[PC]++);
          adr |= mem_read((r[K] << 16) | br[PC]++) << 8;
          pointer = mem_read(adr);
          pointer |= mem_read((adr + 1) & 0xffff) << 8;
          pointer |= mem_read((adr + 2) & 0xffff) << 16;
          //return [pointer, 0];
          retval.i32[0] = pointer;
          retval.i32[1] = 0;
          return retval;

        }

        case REL: {
          // relative
          rel = mem_read((r[K] << 16) | br[PC]++);
          //return [getSigned(rel, TRUE), 0];
          retval.i32[0] = getSigned(rel, TRUE);
          retval.i32[1] = 0;
          return retval;

        }

        case RLL: {
          // relative long
          rel = mem_read((r[K] << 16) | br[PC]++);
          rel |= mem_read((r[K] << 16) | br[PC]++) << 8;
          //return [getSigned(rel, FALSE), 0];
          retval.i32[0] = getSigned(rel, FALSE);
          retval.i32[1] = 0;
          return retval;

        }

        case BM: {
          // block move
          dest = mem_read((r[K] << 16) | br[PC]++);
          src = mem_read((r[K] << 16) | br[PC]++);
          //return [dest, src];
          retval.i32[0] = dest;
          retval.i32[1] = src;
          return retval;

        }
      }
    }

    // instruction functions

    U0 uni(I32 adr, I32 adrh, I32 instr) {
        no_warn adr, adrh, instr;
      // unimplemented
      /*
      console.log(
        "Uninplemented instruction: " + instr.toString(16) +
        " reading at adrl " + adr.toString(16) +
        " and adrh " + adrh.toString(16)
      );
      */
    }

    U0 adc (I32 adr, I32 adrh) {
        I32 value, result;
      if(m) {
        value = mem_read(adr);
        if(d) {
          result = (br[A] & 0xf) + (value & 0xf) + cond(c, 1, 0);
          result += cond(result > 9, 6, 0);
          result = (
            (br[A] & 0xf0) + (value & 0xf0) +
            cond(result > 0xf, 0x10, 0) + (result & 0xf)
          );
        } else {
          result = (br[A] & 0xff) + value + cond(c, 1, 0);
        }
        v = (
          (br[A] & 0x80) == (value & 0x80) &&
          (value & 0x80) != (result & 0x80)
        );
        result += cond((d && result > 0x9f), 0x60, 0);
        c = result > 0xff;
        setZandN(result, m);
        br[A] = (br[A] & 0xff00) | (result & 0xff);
      } else {
        value = readWord(adr, adrh);
        cyclesLeft++; // 1 extra cycle if m = 0
        if(d) {
          result = (br[A] & 0xf) + (value & 0xf) + cond(c, 1, 0);
          result += cond(result > 9, 6, 0);
          result = (
            (br[A] & 0xf0) + (value & 0xf0) +
            cond(result > 0xf, 0x10, 0) + (result & 0xf)
          );
          result += cond(result > 0x9f, 0x60, 0);
          result = (
            (br[A] & 0xf00) + (value & 0xf00) +
            cond(result > 0xff, 0x100, 0) + (result & 0xff)
          );
          result += cond(result > 0x9ff, 0x600, 0);
          result = (
            (br[A] & 0xf000) + (value & 0xf000) +
            cond(result > 0xfff, 0x1000, 0) + (result & 0xfff)
          );
        } else {
          result = br[A] + value + cond(c, 1, 0);
        }
        v = (
          (br[A] & 0x8000) == (value & 0x8000) &&
          (value & 0x8000) != (result & 0x8000)
        );
        result += cond((d && result > 0x9fff), 0x6000, 0);
        c = result > 0xffff;
        setZandN(result, m);
        br[A] = result;
      }
    }

    U0 sbc (I32 adr, I32 adrh) {
        I32 value, result;
      if(m) {
        value = mem_read(adr) ^ 0xff;
        if(d) {
          result = (br[A] & 0xf) + (value & 0xf) + cond(c, 1, 0);
          result -= cond(result <= 0xf, 6, 0);
          result = (
            (br[A] & 0xf0) + (value & 0xf0) +
            cond(result > 0xf, 0x10, 0) + (result & 0xf)
          );
        } else {
          result = (br[A] & 0xff) + value + cond(c, 1, 0);
        }
        v = (
          (br[A] & 0x80) == (value & 0x80) &&
          (value & 0x80) != (result & 0x80)
        );
        result -= cond((d && result <= 0xff), 0x60, 0);
        c = result > 0xff;
        setZandN(result, m);
        br[A] = (br[A] & 0xff00) | (result & 0xff);
      } else {
        value = readWord(adr, adrh) ^ 0xffff;
        cyclesLeft++; // 1 extra cycle if m = 0
        if(d) {
          result = (br[A] & 0xf) + (value & 0xf) + cond(c, 1, 0);
          result -= cond(result <= 0x0f, 6, 0);
          result = (
            (br[A] & 0xf0) + (value & 0xf0) +
            cond(result > 0xf, 0x10, 0) + (result & 0xf)
          );
          result -= cond(result <= 0xff, 0x60, 0);
          result = (
            (br[A] & 0xf00) + (value & 0xf00) +
            cond(result > 0xff, 0x100, 0) + (result & 0xff)
          );
          result -= cond(result <= 0xfff, 0x600, 0);
          result = (
            (br[A] & 0xf000) + (value & 0xf000) +
            cond(result > 0xfff, 0x1000, 0) + (result & 0xfff)
          );
        } else {
          result = br[A] + value + cond(c, 1, 0);
        }
        v = (
          (br[A] & 0x8000) == (value & 0x8000) &&
          (value & 0x8000) != (result & 0x8000)
        );
        result -= cond((d && result <= 0xffff), 0x6000, 0);
        c = result > 0xffff;
        setZandN(result, m);
        br[A] = result;
      }
    }

    U0 cmp (I32 adr, I32 adrh) {
        I32 value, result;
      if(m) {
        value = mem_read(adr) ^ 0xff;
        result = (br[A] & 0xff) + value + 1;
        c = result > 0xff;
        setZandN(result, m);
      } else {
        value = readWord(adr, adrh) ^ 0xffff;
        cyclesLeft++; // 1 extra cycle if m = 0
        result = br[A] + value + 1;
        c = result > 0xffff;
        setZandN(result, m);
      }
    }

    U0 cpx(I32 adr, I32 adrh) {
        I32 value, result;
      if(x) {
        value = mem_read(adr) ^ 0xff;
        result = (br[X] & 0xff) + value + 1;
        c = result > 0xff;
        setZandN(result, x);
      } else {
        value = readWord(adr, adrh) ^ 0xffff;
        cyclesLeft++; // 1 extra cycle if x = 0
        result = br[X] + value + 1;
        c = result > 0xffff;
        setZandN(result, x);
      }
    }

    U0 cpy(I32 adr, I32 adrh) {
        I32 value, result;
      if(x) {
        value = mem_read(adr) ^ 0xff;
        result = (br[Y] & 0xff) + value + 1;
        c = result > 0xff;
        setZandN(result, x);
      } else {
        value = readWord(adr, adrh) ^ 0xffff;
        cyclesLeft++; // 1 extra cycle if x = 0
        result = br[Y] + value + 1;
        c = result > 0xffff;
        setZandN(result, x);
      }
    }

    U0 dec(I32 adr, I32 adrh) {
        I32 value, result;
      if(m) {
        result = (mem_read(adr) - 1) & 0xff;
        setZandN(result, m);
        mem_write(adr, result);
      } else {
        value = readWord(adr, adrh);
        cyclesLeft += 2; // 2 extra cycles if m = 0
        result = (value - 1) & 0xffff;
        setZandN(result, m);
        writeWord(adr, adrh, result, TRUE);
      }
    }

    U0 deca(I32 adr, I32 adrh) {
        no_warn adr, adrh;
        I32 result;
      if(m) {
        result = ((br[A] & 0xff) - 1) & 0xff;
        setZandN(result, m);
        br[A] = br[A] & 0xff00 | result;
      } else {
        br[A]--;
        setZandN(br[A], m);
      }
    }

    U0 dex(I32 adr, I32 adrh) {
        no_warn adr, adrh;
        I32 result;
      if(x) {
        result = ((br[X] & 0xff) - 1) & 0xff;
        setZandN(result, x);
        br[X] = result;
      } else {
        br[X]--;
        setZandN(br[X], x);
      }
    }

    U0 dey(I32 adr, I32 adrh) {
        no_warn adr, adrh;
        I32 result;
      if(x) {
        result = ((br[Y] & 0xff) - 1) & 0xff;
        setZandN(result, x);
        br[Y] = result;
      } else {
        br[Y]--;
        setZandN(br[Y], x);
      }
    }

    U0 inc(I32 adr, I32 adrh) {
        I32 value, result;
      if(m) {
        result = (mem_read(adr) + 1) & 0xff;
        setZandN(result, m);
        mem_write(adr, result);
      } else {
        value = readWord(adr, adrh);
        cyclesLeft += 2; // 2 extra cycles if m = 0
        result = (value + 1) & 0xffff;
        setZandN(result, m);
        writeWord(adr, adrh, result, TRUE);
      }
    }

    U0 inca(I32 adr, I32 adrh) {
        no_warn adr, adrh;
        I32 result;
      if(m) {
        result = ((br[A] & 0xff) + 1) & 0xff;
        setZandN(result, m);
        br[A] = br[A] & 0xff00 | result;
      } else {
        br[A]++;
        setZandN(br[A], m);
      }
    }

    U0 inx(I32 adr, I32 adrh) {
        no_warn adr, adrh;
        I32 result;
      if(x) {
        result = ((br[X] & 0xff) + 1) & 0xff;
        setZandN(result, x);
        br[X] = result;
      } else {
        br[X]++;
        setZandN(br[X], x);
      }
    }

    U0 iny(I32 adr, I32 adrh) {
        no_warn adr, adrh;
        I32 result;
      if(x) {
        result = ((br[Y] & 0xff) + 1) & 0xff;
        setZandN(result, x);
        br[Y] = result;
      } else {
        br[Y]++;
        setZandN(br[Y], x);
      }
    }

    U0 and(I32 adr, I32 adrh) {
        I32 value;
      if(m) {
        value = mem_read(adr);
        br[A] = (br[A] & 0xff00) | ((br[A] & value) & 0xff);
        setZandN(br[A], m);
      } else {
        value = readWord(adr, adrh);
        cyclesLeft++; // 1 extra cycle if m = 0
        br[A] &= value;
        setZandN(br[A], m);
      }
    }

    U0 eor(I32 adr, I32 adrh) {
        I32 value;
      if(m) {
        value = mem_read(adr);
        br[A] = (br[A] & 0xff00) | ((br[A] ^ value) & 0xff);
        setZandN(br[A], m);
      } else {
        value = readWord(adr, adrh);
        cyclesLeft++; // 1 extra cycle if m = 0
        br[A] ^= value;
        setZandN(br[A], m);
      }
    }

    U0 ora(I32 adr, I32 adrh) {
        I32 value;
      if(m) {
        value = mem_read(adr);
        br[A] = (br[A] & 0xff00) | ((br[A] | value) & 0xff);
        setZandN(br[A], m);
      } else {
        value = readWord(adr, adrh);
        cyclesLeft++; // 1 extra cycle if m = 0
        br[A] |= value;
        setZandN(br[A], m);
      }
    }

    U0 bit(I32 adr, I32 adrh) {
        I32 value, result;
      if(m) {
        value = mem_read(adr);
        result = (br[A] & 0xff) & value;
        z = result == 0;
        n = (value & 0x80) > 0;
        v = (value & 0x40) > 0;
      } else {
        value = readWord(adr, adrh);
        cyclesLeft++; // 1 extra cycle if m = 0
        result = br[A] & value;
        z = result == 0;
        n = (value & 0x8000) > 0;
        v = (value & 0x4000) > 0;
      }
    }

    U0 biti(I32 adr, I32 adrh) {
        I32 value, result;
      if(m) {
        value = mem_read(adr);
        result = (br[A] & 0xff) & value;
        z = result == 0;
      } else {
        value = readWord(adr, adrh);
        cyclesLeft++; // 1 extra cycle if m = 0
        result = br[A] & value;
        z = result == 0;
      }
    }

    U0 trb(I32 adr, I32 adrh) {
        I32 value, result;
      if(m) {
        value = mem_read(adr);
        result = (br[A] & 0xff) & value;
        value = (value & ~(br[A] & 0xff)) & 0xff;
        z = result == 0;
        mem_write(adr, value);
      } else {
        value = readWord(adr, adrh);
        cyclesLeft += 2; // 2 extra cycles if m = 0
        result = br[A] & value;
        value = (value & ~br[A]) & 0xffff;
        z = result == 0;
        writeWord(adr, adrh, value, TRUE);
      }
    }

    U0 tsb(I32 adr, I32 adrh) {
        I32 value, result;
      if(m) {
        value = mem_read(adr);
        result = (br[A] & 0xff) & value;
        value = (value | (br[A] & 0xff)) & 0xff;
        z = result == 0;
        mem_write(adr, value);
      } else {
        value = readWord(adr, adrh);
        cyclesLeft += 2; // 2 extra cycles if m = 0
        result = br[A] & value;
        value = (value | br[A]) & 0xffff;
        z = result == 0;
        writeWord(adr, adrh, value, TRUE);
      }
    }

    U0 asl(I32 adr, I32 adrh) {
        I32 value;
      if(m) {
        value = mem_read(adr);
        c = (value & 0x80) > 0;
        value <<= 1;
        setZandN(value, m);
        mem_write(adr, value);
      } else {
        value = readWord(adr, adrh);
        cyclesLeft += 2; // 2 extra cycles if m = 0
        c = (value & 0x8000) > 0;
        value <<= 1;
        setZandN(value, m);
        writeWord(adr, adrh, value, TRUE);
      }
    }

    U0 asla(I32 adr, I32 adrh) {
        no_warn adr, adrh;
        I32 value;
      if(m) {
        value = br[A] & 0xff;
        c = (value & 0x80) > 0;
        value <<= 1;
        setZandN(value, m);
        br[A] = (br[A] & 0xff00) | (value & 0xff);
      } else {
        c = (br[A] & 0x8000) > 0;
        cyclesLeft += 2; // 2 extra cycles if m = 0
        br[A] <<= 1;
        setZandN(br[A], m);
      }
    }

    U0 lsr(I32 adr, I32 adrh) {
        I32 value;
      if(m) {
        value = mem_read(adr);
        c = (value & 0x1) > 0;
        value >>= 1;
        setZandN(value, m);
        mem_write(adr, value);
      } else {
        value = readWord(adr, adrh);
        cyclesLeft += 2; // 2 extra cycles if m = 0
        c = (value & 0x1) > 0;
        value >>= 1;
        setZandN(value, m);
        writeWord(adr, adrh, value, TRUE);
      }
    }

    U0 lsra(I32 adr, I32 adrh) {
        no_warn adr, adrh;
        I32 value;
      if(m) {
        value = br[A] & 0xff;
        c = (value & 0x1) > 0;
        value >>= 1;
        setZandN(value, m);
        br[A] = (br[A] & 0xff00) | (value & 0xff);
      } else {
        c = (br[A] & 0x1) > 0;
        cyclesLeft += 2; // 2 extra cycles if m = 0
        br[A] >>= 1;
        setZandN(br[A], m);
      }
    }

    U0 rol(I32 adr, I32 adrh) {
        I32 value;
      if(m) {
        value = mem_read(adr);
        value = (value << 1) | cond(c, 1, 0);
        c = (value & 0x100) > 0;
        setZandN(value, m);
        mem_write(adr, value);
      } else {
        value = readWord(adr, adrh);
        cyclesLeft += 2; // 2 extra cycles if m = 0
        value = (value << 1) | cond(c, 1, 0);
        c = (value & 0x10000) > 0;
        setZandN(value, m);
        writeWord(adr, adrh, value, TRUE);
      }
    }

    U0 rola(I32 adr, I32 adrh) {
        no_warn adr, adrh;
        I32 value;
      if(m) {
        value = br[A] & 0xff;
        value = (value << 1) | cond(c, 1, 0);
        c = (value & 0x100) > 0;
        setZandN(value, m);
        br[A] = (br[A] & 0xff00) | (value & 0xff);
      } else {
        cyclesLeft += 2; // 2 extra cycles if m = 0
        value = (br[A] << 1) | cond(c, 1, 0);
        c = (value & 0x10000) > 0;
        setZandN(value, m);
        br[A] = value;
      }
    }

    U0 ror(I32 adr, I32 adrh) {
        I32 value, carry;
      if(m) {
        value = mem_read(adr);
        carry = value & 0x1;
        value = (value >> 1) | cond(c, 0x80, 0);
        c = carry > 0;
        setZandN(value, m);
        mem_write(adr, value);
      } else {
        value = readWord(adr, adrh);
        cyclesLeft += 2; // 2 extra cycles if m = 0
        carry = value & 0x1;
        value = (value >> 1) | cond(c, 0x8000, 0);
        c = carry > 0;
        setZandN(value, m);
        writeWord(adr, adrh, value, TRUE);
      }
    }

    U0 rora(I32 adr, I32 adrh) {
        no_warn adr, adrh;
        I32 value, carry;
      if(m) {
        value = br[A] & 0xff;
        carry = value & 0x1;
        value = (value >> 1) | cond(c, 0x80, 0);
        c = carry > 0;
        setZandN(value, m);
        br[A] = (br[A] & 0xff00) | (value & 0xff);
      } else {
        cyclesLeft += 2; // 2 extra cycles if m = 0
        carry = br[A] & 0x1;
        value = (br[A] >> 1) | cond(c, 0x8000, 0);
        c = carry > 0;
        setZandN(value, m);
        br[A] = value;
      }
    }

    U0 bcc(I32 adr, I32 adrh) {
        no_warn adrh;
      doBranch(!c, adr);
    }

    U0 bcs(I32 adr, I32 adrh) {
        no_warn adrh;
      doBranch(c, adr);
    }

    U0 beq(I32 adr, I32 adrh) {
        no_warn adrh;
      doBranch(z, adr);
    }

    U0 bmi(I32 adr, I32 adrh) {
        no_warn adrh;
      doBranch(n, adr);
    }

    U0 bne(I32 adr, I32 adrh) {
        no_warn adrh;
      doBranch(!z, adr);
    }

    U0 bpl(I32 adr, I32 adrh) {
        no_warn adrh;
      doBranch(!n, adr);
    }

    U0 bra(I32 adr, I32 adrh) {
        no_warn adrh;
      br[PC] += adr;
    }

    U0 bvc(I32 adr, I32 adrh) {
        no_warn adrh;
      doBranch(!v, adr);
    }

    U0 bvs(I32 adr, I32 adrh) {
        no_warn adrh;
      doBranch(v, adr);
    }

    U0 brl(I32 adr, I32 adrh) {
        no_warn adrh;
      br[PC] += adr;
    }

    U0 jmp(I32 adr, I32 adrh) {
        no_warn adrh;
      br[PC] = adr & 0xffff;
    }

    U0 jml(I32 adr, I32 adrh) {
        no_warn adrh;
      r[K] = (adr & 0xff0000) >> 16;
      br[PC] = adr & 0xffff;
    }

    U0 jsl(I32 adr, I32 adrh) {
        no_warn adrh;
      I32 pushPc = (br[PC] - 1) & 0xffff;
      pushByte(r[K]);
      pushWord(pushPc);
      r[K] = (adr & 0xff0000) >> 16;
      br[PC] = adr & 0xffff;
    }

    U0 jsr(I32 adr, I32 adrh) {
        no_warn adrh;
      I32 pushPc = (br[PC] - 1) & 0xffff;
      pushWord(pushPc);
      br[PC] = adr & 0xffff;
    }

    U0 rtl(I32 adr, I32 adrh) {
        no_warn adr, adrh;
      I32 pullPc = pullWord();
      r[K] = pullByte();
      br[PC] = pullPc + 1;
    }

    U0 rts(I32 adr, I32 adrh) {
        no_warn adr, adrh;
      I32 pullPc = pullWord();
      br[PC] = pullPc + 1;
    }

    U0 brk(I32 adr, I32 adrh) {
        no_warn adr, adrh;
      I32 pushPc = (br[PC] + 1) & 0xffff;
      pushByte(r[K]);
      pushWord(pushPc);
      pushByte(cpu_getP());
      cyclesLeft++; // native mode: 1 extra cycle
      i = TRUE;
      d = FALSE;
      r[K] = 0;
      br[PC] = mem_read(0xffe6) | (mem_read(0xffe7) << 8);
    }

    U0 cop(I32 adr, I32 adrh) {
        no_warn adr, adrh;
      pushByte(r[K]);
      pushWord(br[PC]);
      pushByte(cpu_getP());
      cyclesLeft++; // native mode: 1 extra cycle
      i = TRUE;
      d = FALSE;
      r[K] = 0;
      br[PC] = mem_read(0xffe4) | (mem_read(0xffe5) << 8);
    }

    U0 abo(I32 adr, I32 adrh) {
        no_warn adr, adrh;
      pushByte(r[K]);
      pushWord(br[PC]);
      pushByte(cpu_getP());
      cyclesLeft++; // native mode: 1 extra cycle
      i = TRUE;
      d = FALSE;
      r[K] = 0;
      br[PC] = mem_read(0xffe8) | (mem_read(0xffe9) << 8);
    }

    U0 nmi(I32 adr, I32 adrh) {
        no_warn adr, adrh;
      pushByte(r[K]);
      pushWord(br[PC]);
      pushByte(cpu_getP());
      cyclesLeft++; // native mode: 1 extra cycle
      i = TRUE;
      d = FALSE;
      r[K] = 0;
      br[PC] = mem_read(0xffea) | (mem_read(0xffeb) << 8);
    }

    U0 irq(I32 adr, I32 adrh) {
        no_warn adr, adrh;
      pushByte(r[K]);
      pushWord(br[PC]);
      pushByte(cpu_getP());
      cyclesLeft++; // native mode: 1 extra cycle
      i = TRUE;
      d = FALSE;
      r[K] = 0;
      br[PC] = mem_read(0xffee) | (mem_read(0xffef) << 8);
    }

    U0 rti(I32 adr, I32 adrh) {
        no_warn adr, adrh;
      cpu_setP(pullByte());
      cyclesLeft++; // native mode: 1 extra cycle
      I32 pullPc = pullWord();
      r[K] = pullByte();
      br[PC] = pullPc;
    }

    U0 clc(I32 adr, I32 adrh) {
        no_warn adr, adrh;
      c = FALSE;
    }

    U0 cld(I32 adr, I32 adrh) {
        no_warn adr, adrh;
      d = FALSE;
    }

    U0 cli(I32 adr, I32 adrh) {
        no_warn adr, adrh;
      i = FALSE;
    }

    U0 clv(I32 adr, I32 adrh) {
        no_warn adr, adrh;
      v = FALSE;
    }

    U0 sec(I32 adr, I32 adrh) {
        no_warn adr, adrh;
      c = TRUE;
    }

    U0 sed(I32 adr, I32 adrh) {
        no_warn adr, adrh;
      d = TRUE;
    }

    U0 sei(I32 adr, I32 adrh) {
        no_warn adr, adrh;
      i = TRUE;
    }

    U0 rep(I32 adr, I32 adrh) {
        no_warn adrh;
      I32 value = mem_read(adr);
      cpu_setP(cpu_getP() & ~value);
    }

    U0 sep(I32 adr, I32 adrh) {
        no_warn adrh;
      I32 value = mem_read(adr);
      cpu_setP(cpu_getP() | value);
    }

    U0 lda(I32 adr, I32 adrh) {
      if(m) {
        I32 value = mem_read(adr);
        br[A] = (br[A] & 0xff00) | (value & 0xff);
        setZandN(value, m);
      } else {
        cyclesLeft++; // m = 0: 1 extra cycle
        br[A] = readWord(adr, adrh);
        setZandN(br[A], m);
      }
    }

    U0 ldx (I32 adr, I32 adrh) {
      if(x) {
        br[X] = mem_read(adr);
        setZandN(br[X], x);
      } else {
        cyclesLeft++; // x = 0: 1 extra cycle
        br[X] = readWord(adr, adrh);
        setZandN(br[X], x);
      }
    }

    U0 ldy (I32 adr, I32 adrh) {
      if(x) {
        br[Y] = mem_read(adr);
        setZandN(br[Y], x);
      } else {
        cyclesLeft++; // x = 0: 1 extra cycle
        br[Y] = readWord(adr, adrh);
        setZandN(br[Y], x);
      }
    }

    U0 sta (I32 adr, I32 adrh) {
      if(m) {
        mem_write(adr, br[A] & 0xff);
      } else {
        cyclesLeft++; // m = 0: 1 extra cycle
        writeWord(adr, adrh, br[A]);
      }
    }

    U0 stx (I32 adr, I32 adrh) {
      if(x) {
        mem_write(adr, br[X] & 0xff);
      } else {
        cyclesLeft++; // x = 0: 1 extra cycle
        writeWord(adr, adrh, br[X]);
      }
    }

    U0 sty (I32 adr, I32 adrh) {
      if(x) {
        mem_write(adr, br[Y] & 0xff);
      } else {
        cyclesLeft++; // x = 0: 1 extra cycle
        writeWord(adr, adrh, br[Y]);
      }
    }

    U0 stz (I32 adr, I32 adrh) {
      if(m) {
        mem_write(adr, 0);
      } else {
        cyclesLeft++; // m = 0: 1 extra cycle
        writeWord(adr, adrh, 0);
      }
    }

    U0 mvn (I32 adr, I32 adrh) {
      r[DBR] = adr;
      mem_write(
        (adr << 16) | br[Y],
        mem_read((adrh << 16) | br[X])
      );
      br[A]--;
      br[X]++;
      br[Y]++;
      if(br[A] != 0xffff) {
        br[PC] -= 3;
      }
      if(x) {
        br[X] &= 0xff;
        br[Y] &= 0xff;
      }
    }

    U0 mvp (I32 adr, I32 adrh) {
      r[DBR] = adr;
      mem_write(
        (adr << 16) | br[Y],
        mem_read((adrh << 16) | br[X])
      );
      br[A]--;
      br[X]--;
      br[Y]--;
      if(br[A] != 0xffff) {
        br[PC] -= 3;
      }
      if(x) {
        br[X] &= 0xff;
        br[Y] &= 0xff;
      }
    }

    U0 nop (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      // no operation
    }

    U0 wdm (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      // no operation
    }

    U0 pea (I32 adr, I32 adrh) {
      pushWord(readWord(adr, adrh));
    }

    U0 pei (I32 adr, I32 adrh) {
      pushWord(readWord(adr, adrh));
    }

    U0 per (I32 adr, I32 adrh) {
        no_warn adrh;
      pushWord((br[PC] + adr) & 0xffff);
    }

    U0 pha (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      if(m) {
        pushByte(br[A] & 0xff);
      } else {
        cyclesLeft++; // m = 0: 1 extra cycle
        pushWord(br[A]);
      }
    }

    U0 phx (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      if(x) {
        pushByte(br[X] & 0xff);
      } else {
        cyclesLeft++; // x = 0: 1 extra cycle
        pushWord(br[X]);
      }
    }

    U0 phy (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      if(x) {
        pushByte(br[Y] & 0xff);
      } else {
        cyclesLeft++; // x = 0: 1 extra cycle
        pushWord(br[Y]);
      }
    }

    U0 pla (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      if(m) {
        br[A] = (br[A] & 0xff00) | (pullByte() & 0xff);
        setZandN(br[A], m);
      } else {
        cyclesLeft++; // m = 0: 1 extra cycle
        br[A] = pullWord();
        setZandN(br[A], m);
      }
    }

    U0 plx (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      if(x) {
        br[X] = pullByte();
        setZandN(br[X], m);
      } else {
        cyclesLeft++; // x = 0: 1 extra cycle
        br[X] = pullWord();
        setZandN(br[X], m);
      }
    }

    U0 ply (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      if(x) {
        br[Y] = pullByte();
        setZandN(br[Y], m);
      } else {
        cyclesLeft++; // x = 0: 1 extra cycle
        br[Y] = pullWord();
        setZandN(br[Y], m);
      }
    }

    U0 phb (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      pushByte(r[DBR]);
    }

    U0 phd (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      pushWord(br[DPR]);
    }

    U0 phk (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      pushByte(r[K]);
    }

    U0 php (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      pushByte(cpu_getP());
    }

    U0 plb (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      r[DBR] = pullByte();
      setZandN(r[DBR], TRUE);
    }

    U0 pld (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      br[DPR] = pullWord();
      setZandN(br[DPR], FALSE);
    }

    U0 plp (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      cpu_setP(pullByte());
    }

    U0 stp (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      stopped = TRUE;
    }

    U0 wai (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      waiting = TRUE;
    }

    U0 tax (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      if(x) {
        br[X] = br[A] & 0xff;
        setZandN(br[X], x);
      } else {
        br[X] = br[A];
        setZandN(br[X], x);
      }
    }

    U0 tay (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      if(x) {
        br[Y] = br[A] & 0xff;
        setZandN(br[Y], x);
      } else {
        br[Y] = br[A];
        setZandN(br[Y], x);
      }
    }

    U0 tsx (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      if(x) {
        br[X] = br[SP] & 0xff;
        setZandN(br[X], x);
      } else {
        br[X] = br[SP];
        setZandN(br[X], x);
      }
    }

    U0 txa (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      if(m) {
        br[A] = (br[A] & 0xff00) | (br[X] & 0xff);
        setZandN(br[A], m);
      } else {
        br[A] = br[X];
        setZandN(br[A], m);
      }
    }

    U0 txs (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      br[SP] = br[X];
    }

    U0 txy (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      if(x) {
        br[Y] = br[X] & 0xff;
        setZandN(br[Y], x);
      } else {
        br[Y] = br[X];
        setZandN(br[Y], x);
      }
    }

    U0 tya (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      if(m) {
        br[A] = (br[A] & 0xff00) | (br[Y] & 0xff);
        setZandN(br[A], m);
      } else {
        br[A] = br[Y];
        setZandN(br[A], m);
      }
    }

    U0 tyx (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      if(x) {
        br[X] = br[Y] & 0xff;
        setZandN(br[X], x);
      } else {
        br[X] = br[Y];
        setZandN(br[X], x);
      }
    }

    U0 tcd (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      br[DPR] = br[A];
      setZandN(br[DPR], FALSE);
    }

    U0 tcs (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      br[SP] = br[A];
    }

    U0 tdc (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      br[A] = br[DPR];
      setZandN(br[A], FALSE);
    }

    U0 tsc (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      br[A] = br[SP];
      setZandN(br[A], FALSE);
    }

    U0 xba (I32 adr, I32 adrh) {
        no_warn adr, adrh;
        I32 low, high;
      low = br[A] & 0xff;
      high = (br[A] & 0xff00) >> 8;
      br[A] = (low << 8) | high;
      setZandN(br[A], TRUE);
    }

    U0 xce (I32 adr, I32 adrh) {
        no_warn adr, adrh;
      I32 temp = c;
      c = e;
      e = temp;
      if(e) {
        m = TRUE;
        x = TRUE;
      }
      if(x) {
        br[X] &= 0xff;
        br[Y] &= 0xff;
      }
    }

    // function table
    U64 functions[259] = {
      &brk, &ora, &cop, &ora, &tsb, &ora, &asl, &ora, &php, &ora, &asla,&phd, &tsb, &ora, &asl, &ora,
      &bpl, &ora, &ora, &ora, &trb, &ora, &asl, &ora, &clc, &ora, &inca,&tcs, &trb, &ora, &asl, &ora,
      &jsr, &and, &jsl, &and, &bit, &and, &rol, &and, &plp, &and, &rola,&pld, &bit, &and, &rol, &and,
      &bmi, &and, &and, &and, &bit, &and, &rol, &and, &sec, &and, &deca,&tsc, &bit, &and, &rol, &and,
      &rti, &eor, &wdm, &eor, &mvp, &eor, &lsr, &eor, &pha, &eor, &lsra,&phk, &jmp, &eor, &lsr, &eor,
      &bvc, &eor, &eor, &eor, &mvn, &eor, &lsr, &eor, &cli, &eor, &phy, &tcd, &jml, &eor, &lsr, &eor,
      &rts, &adc, &per, &adc, &stz, &adc, &ror, &adc, &pla, &adc, &rora,&rtl, &jmp, &adc, &ror, &adc,
      &bvs, &adc, &adc, &adc, &stz, &adc, &ror, &adc, &sei, &adc, &ply, &tdc, &jmp, &adc, &ror, &adc,
      &bra, &sta, &brl, &sta, &sty, &sta, &stx, &sta, &dey, &biti,&txa, &phb, &sty, &sta, &stx, &sta,
      &bcc, &sta, &sta, &sta, &sty, &sta, &stx, &sta, &tya, &sta, &txs, &txy, &stz, &sta, &stz, &sta,
      &ldy, &lda, &ldx, &lda, &ldy, &lda, &ldx, &lda, &tay, &lda, &tax, &plb, &ldy, &lda, &ldx, &lda,
      &bcs, &lda, &lda, &lda, &ldy, &lda, &ldx, &lda, &clv, &lda, &tsx, &tyx, &ldy, &lda, &ldx, &lda,
      &cpy, &cmp, &rep, &cmp, &cpy, &cmp, &dec, &cmp, &iny, &cmp, &dex, &wai, &cpy, &cmp, &dec, &cmp,
      &bne, &cmp, &cmp, &cmp, &pei, &cmp, &dec, &cmp, &cld, &cmp, &phx, &stp, &jml, &cmp, &dec, &cmp,
      &cpx, &sbc, &sep, &sbc, &cpx, &sbc, &inc, &sbc, &inx, &sbc, &nop, &xba, &cpx, &sbc, &inc, &sbc,
      &beq, &sbc, &sbc, &sbc, &pea, &sbc, &inc, &sbc, &sed, &sbc, &plx, &xce, &jsr, &sbc, &inc, &sbc,
      &abo, &nmi, &irq // abo, nmi, irq
    };

    U0 cpu_opcode(I32 instr, I32 adr, I32 adrh)
    {
        switch (instr)
        {

            case 0:
                brk(adr, adrh);
                break; 
            case 1:
                ora(adr, adrh);
                break; 
            case 2:
                cop(adr, adrh);
                break; 
            case 3:
                ora(adr, adrh);
                break; 
            case 4:
                tsb(adr, adrh);
                break; 
            case 5:
                ora(adr, adrh);
                break; 
            case 6:
                asl(adr, adrh);
                break; 
            case 7:
                ora(adr, adrh);
                break; 
            case 8:
                php(adr, adrh);
                break; 
            case 9:
                ora(adr, adrh);
                break; 
            case 10:
                asla(adr, adrh);
                break;
            case 11:
                phd(adr, adrh);
                break; 
            case 12:
                tsb(adr, adrh);
                break; 
            case 13:
                ora(adr, adrh);
                break; 
            case 14:
                asl(adr, adrh);
                break; 
            case 15:
                ora(adr, adrh);
                break;
            case 16:
                bpl(adr, adrh);
                break; 
            case 17:
                ora(adr, adrh);
                break; 
            case 18:
                ora(adr, adrh);
                break; 
            case 19:
                ora(adr, adrh);
                break; 
            case 20:
                trb(adr, adrh);
                break; 
            case 21:
                ora(adr, adrh);
                break; 
            case 22:
                asl(adr, adrh);
                break; 
            case 23:
                ora(adr, adrh);
                break; 
            case 24:
                clc(adr, adrh);
                break; 
            case 25:
                ora(adr, adrh);
                break; 
            case 26:
                inca(adr, adrh);
                break;
            case 27:
                tcs(adr, adrh);
                break; 
            case 28:
                trb(adr, adrh);
                break; 
            case 29:
                ora(adr, adrh);
                break; 
            case 30:
                asl(adr, adrh);
                break; 
            case 31:
                ora(adr, adrh);
                break;
            case 32:
                jsr(adr, adrh);
                break; 
            case 33:
                and(adr, adrh);
                break; 
            case 34:
                jsl(adr, adrh);
                break; 
            case 35:
                and(adr, adrh);
                break; 
            case 36:
                bit(adr, adrh);
                break; 
            case 37:
                and(adr, adrh);
                break; 
            case 38:
                rol(adr, adrh);
                break; 
            case 39:
                and(adr, adrh);
                break; 
            case 40:
                plp(adr, adrh);
                break; 
            case 41:
                and(adr, adrh);
                break; 
            case 42:
                rola(adr, adrh);
                break;
            case 43:
                pld(adr, adrh);
                break; 
            case 44:
                bit(adr, adrh);
                break; 
            case 45:
                and(adr, adrh);
                break; 
            case 46:
                rol(adr, adrh);
                break; 
            case 47:
                and(adr, adrh);
                break;
            case 48:
                bmi(adr, adrh);
                break; 
            case 49:
                and(adr, adrh);
                break; 
            case 50:
                and(adr, adrh);
                break; 
            case 51:
                and(adr, adrh);
                break; 
            case 52:
                bit(adr, adrh);
                break; 
            case 53:
                and(adr, adrh);
                break; 
            case 54:
                rol(adr, adrh);
                break; 
            case 55:
                and(adr, adrh);
                break; 
            case 56:
                sec(adr, adrh);
                break; 
            case 57:
                and(adr, adrh);
                break; 
            case 58:
                deca(adr, adrh);
                break;
            case 59:
                tsc(adr, adrh);
                break; 
            case 60:
                bit(adr, adrh);
                break; 
            case 61:
                and(adr, adrh);
                break; 
            case 62:
                rol(adr, adrh);
                break; 
            case 63:
                and(adr, adrh);
                break;
            case 64:
                rti(adr, adrh);
                break; 
            case 65:
                eor(adr, adrh);
                break; 
            case 66:
                wdm(adr, adrh);
                break; 
            case 67:
                eor(adr, adrh);
                break; 
            case 68:
                mvp(adr, adrh);
                break; 
            case 69:
                eor(adr, adrh);
                break; 
            case 70:
                lsr(adr, adrh);
                break; 
            case 71:
                eor(adr, adrh);
                break; 
            case 72:
                pha(adr, adrh);
                break; 
            case 73:
                eor(adr, adrh);
                break; 
            case 74:
                lsra(adr, adrh);
                break;
            case 75:
                phk(adr, adrh);
                break; 
            case 76:
                jmp(adr, adrh);
                break; 
            case 77:
                eor(adr, adrh);
                break; 
            case 78:
                lsr(adr, adrh);
                break; 
            case 79:
                eor(adr, adrh);
                break;
            case 80:
                bvc(adr, adrh);
                break; 
            case 81:
                eor(adr, adrh);
                break; 
            case 82:
                eor(adr, adrh);
                break; 
            case 83:
                eor(adr, adrh);
                break; 
            case 84:
                mvn(adr, adrh);
                break; 
            case 85:
                eor(adr, adrh);
                break; 
            case 86:
                lsr(adr, adrh);
                break; 
            case 87:
                eor(adr, adrh);
                break; 
            case 88:
                cli(adr, adrh);
                break; 
            case 89:
                eor(adr, adrh);
                break; 
            case 90:
                phy(adr, adrh);
                break; 
            case 91:
                tcd(adr, adrh);
                break; 
            case 92:
                jml(adr, adrh);
                break; 
            case 93:
                eor(adr, adrh);
                break; 
            case 94:
                lsr(adr, adrh);
                break; 
            case 95:
                eor(adr, adrh);
                break;
            case 96:
                rts(adr, adrh);
                break; 
            case 97:
                adc(adr, adrh);
                break; 
            case 98:
                per(adr, adrh);
                break; 
            case 99:
                adc(adr, adrh);
                break; 
            case 100:
                stz(adr, adrh);
                break; 
            case 101:
                adc(adr, adrh);
                break; 
            case 102:
                ror(adr, adrh);
                break; 
            case 103:
                adc(adr, adrh);
                break; 
            case 104:
                pla(adr, adrh);
                break; 
            case 105:
                adc(adr, adrh);
                break; 
            case 106:
                rora(adr, adrh);
                break;
            case 107:
                rtl(adr, adrh);
                break; 
            case 108:
                jmp(adr, adrh);
                break; 
            case 109:
                adc(adr, adrh);
                break; 
            case 110:
                ror(adr, adrh);
                break; 
            case 111:
                adc(adr, adrh);
                break;
            case 112:
                bvs(adr, adrh);
                break; 
            case 113:
                adc(adr, adrh);
                break; 
            case 114:
                adc(adr, adrh);
                break; 
            case 115:
                adc(adr, adrh);
                break; 
            case 116:
                stz(adr, adrh);
                break; 
            case 117:
                adc(adr, adrh);
                break; 
            case 118:
                ror(adr, adrh);
                break; 
            case 119:
                adc(adr, adrh);
                break; 
            case 120:
                sei(adr, adrh);
                break; 
            case 121:
                adc(adr, adrh);
                break; 
            case 122:
                ply(adr, adrh);
                break; 
            case 123:
                tdc(adr, adrh);
                break; 
            case 124:
                jmp(adr, adrh);
                break; 
            case 125:
                adc(adr, adrh);
                break; 
            case 126:
                ror(adr, adrh);
                break; 
            case 127:
                adc(adr, adrh);
                break;
            case 128:
                bra(adr, adrh);
                break; 
            case 129:
                sta(adr, adrh);
                break; 
            case 130:
                brl(adr, adrh);
                break; 
            case 131:
                sta(adr, adrh);
                break; 
            case 132:
                sty(adr, adrh);
                break; 
            case 133:
                sta(adr, adrh);
                break; 
            case 134:
                stx(adr, adrh);
                break; 
            case 135:
                sta(adr, adrh);
                break; 
            case 136:
                dey(adr, adrh);
                break; 
            case 137:
                biti(adr, adrh);
                break;
            case 138:
                txa(adr, adrh);
                break; 
            case 139:
                phb(adr, adrh);
                break; 
            case 140:
                sty(adr, adrh);
                break; 
            case 141:
                sta(adr, adrh);
                break; 
            case 142:
                stx(adr, adrh);
                break; 
            case 143:
                sta(adr, adrh);
                break;
            case 144:
                bcc(adr, adrh);
                break; 
            case 145:
                sta(adr, adrh);
                break; 
            case 146:
                sta(adr, adrh);
                break; 
            case 147:
                sta(adr, adrh);
                break; 
            case 148:
                sty(adr, adrh);
                break; 
            case 149:
                sta(adr, adrh);
                break; 
            case 150:
                stx(adr, adrh);
                break; 
            case 151:
                sta(adr, adrh);
                break; 
            case 152:
                tya(adr, adrh);
                break; 
            case 153:
                sta(adr, adrh);
                break; 
            case 154:
                txs(adr, adrh);
                break; 
            case 155:
                txy(adr, adrh);
                break; 
            case 156:
                stz(adr, adrh);
                break; 
            case 157:
                sta(adr, adrh);
                break; 
            case 158:
                stz(adr, adrh);
                break; 
            case 159:
                sta(adr, adrh);
                break;
            case 160:
                ldy(adr, adrh);
                break; 
            case 161:
                lda(adr, adrh);
                break; 
            case 162:
                ldx(adr, adrh);
                break; 
            case 163:
                lda(adr, adrh);
                break; 
            case 164:
                ldy(adr, adrh);
                break; 
            case 165:
                lda(adr, adrh);
                break; 
            case 166:
                ldx(adr, adrh);
                break; 
            case 167:
                lda(adr, adrh);
                break; 
            case 168:
                tay(adr, adrh);
                break; 
            case 169:
                lda(adr, adrh);
                break; 
            case 170:
                tax(adr, adrh);
                break; 
            case 171:
                plb(adr, adrh);
                break; 
            case 172:
                ldy(adr, adrh);
                break; 
            case 173:
                lda(adr, adrh);
                break; 
            case 174:
                ldx(adr, adrh);
                break; 
            case 175:
                lda(adr, adrh);
                break;
            case 176:
                bcs(adr, adrh);
                break; 
            case 177:
                lda(adr, adrh);
                break; 
            case 178:
                lda(adr, adrh);
                break; 
            case 179:
                lda(adr, adrh);
                break; 
            case 180:
                ldy(adr, adrh);
                break; 
            case 181:
                lda(adr, adrh);
                break; 
            case 182:
                ldx(adr, adrh);
                break; 
            case 183:
                lda(adr, adrh);
                break; 
            case 184:
                clv(adr, adrh);
                break; 
            case 185:
                lda(adr, adrh);
                break; 
            case 186:
                tsx(adr, adrh);
                break; 
            case 187:
                tyx(adr, adrh);
                break; 
            case 188:
                ldy(adr, adrh);
                break; 
            case 189:
                lda(adr, adrh);
                break; 
            case 190:
                ldx(adr, adrh);
                break; 
            case 191:
                lda(adr, adrh);
                break;
            case 192:
                cpy(adr, adrh);
                break; 
            case 193:
                cmp(adr, adrh);
                break; 
            case 194:
                rep(adr, adrh);
                break; 
            case 195:
                cmp(adr, adrh);
                break; 
            case 196:
                cpy(adr, adrh);
                break; 
            case 197:
                cmp(adr, adrh);
                break; 
            case 198:
                dec(adr, adrh);
                break; 
            case 199:
                cmp(adr, adrh);
                break; 
            case 200:
                iny(adr, adrh);
                break; 
            case 201:
                cmp(adr, adrh);
                break; 
            case 202:
                dex(adr, adrh);
                break; 
            case 203:
                wai(adr, adrh);
                break; 
            case 204:
                cpy(adr, adrh);
                break; 
            case 205:
                cmp(adr, adrh);
                break; 
            case 206:
                dec(adr, adrh);
                break; 
            case 207:
                cmp(adr, adrh);
                break;
            case 208:
                bne(adr, adrh);
                break; 
            case 209:
                cmp(adr, adrh);
                break; 
            case 210:
                cmp(adr, adrh);
                break; 
            case 211:
                cmp(adr, adrh);
                break; 
            case 212:
                pei(adr, adrh);
                break; 
            case 213:
                cmp(adr, adrh);
                break; 
            case 214:
                dec(adr, adrh);
                break; 
            case 215:
                cmp(adr, adrh);
                break; 
            case 216:
                cld(adr, adrh);
                break; 
            case 217:
                cmp(adr, adrh);
                break; 
            case 218:
                phx(adr, adrh);
                break; 
            case 219:
                stp(adr, adrh);
                break; 
            case 220:
                jml(adr, adrh);
                break; 
            case 221:
                cmp(adr, adrh);
                break; 
            case 222:
                dec(adr, adrh);
                break; 
            case 223:
                cmp(adr, adrh);
                break;
            case 224:
                cpx(adr, adrh);
                break; 
            case 225:
                sbc(adr, adrh);
                break; 
            case 226:
                sep(adr, adrh);
                break; 
            case 227:
                sbc(adr, adrh);
                break; 
            case 228:
                cpx(adr, adrh);
                break; 
            case 229:
                sbc(adr, adrh);
                break; 
            case 230:
                inc(adr, adrh);
                break; 
            case 231:
                sbc(adr, adrh);
                break; 
            case 232:
                inx(adr, adrh);
                break; 
            case 233:
                sbc(adr, adrh);
                break; 
            case 234:
                nop(adr, adrh);
                break; 
            case 235:
                xba(adr, adrh);
                break; 
            case 236:
                cpx(adr, adrh);
                break; 
            case 237:
                sbc(adr, adrh);
                break; 
            case 238:
                inc(adr, adrh);
                break; 
            case 239:
                sbc(adr, adrh);
                break;
            case 240:
                beq(adr, adrh);
                break; 
            case 241:
                sbc(adr, adrh);
                break; 
            case 242:
                sbc(adr, adrh);
                break; 
            case 243:
                sbc(adr, adrh);
                break; 
            case 244:
                pea(adr, adrh);
                break; 
            case 245:
                sbc(adr, adrh);
                break; 
            case 246:
                inc(adr, adrh);
                break; 
            case 247:
                sbc(adr, adrh);
                break; 
            case 248:
                sed(adr, adrh);
                break; 
            case 249:
                sbc(adr, adrh);
                break; 
            case 250:
                plx(adr, adrh);
                break; 
            case 251:
                xce(adr, adrh);
                break; 
            case 252:
                jsr(adr, adrh);
                break; 
            case 253:
                sbc(adr, adrh);
                break; 
            case 254:
                inc(adr, adrh);
                break; 
            case 255:
                sbc(adr, adrh);
                break;
            case 256:
                abo(adr, adrh);
                break; 
            case 257:
                nmi(adr, adrh);
                break; 
            case 258:
                irq(adr, adrh);
                break;
            default:
                PressAKey;
                break;


        }
        
    }

U0 regs()
{
	"PC: 0x%04X\tSP: 0x%04X\tA: 0x%04X\tX: 0x%04X\tY: 0x%04X\n", br[PC], br[SP], br[A], br[X], br[Y];
	"\n";
}