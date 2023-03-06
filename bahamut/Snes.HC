extern I64 mem_read(I64 adr, Bool dma=FALSE);
extern U0 mem_write(I64 adr, I64 value, Bool dma = FALSE);
extern I64 readBBus(I64 adr);
extern U0 writeBBus(I64 adr, I64 value);
extern U0 cpu_cycle();
extern U0 renderLine(I32 line);

class ROMHeader
{
    U8 *name;
    I64 type;
    I64 speed;
    I64 chips;
    I64 romSize;
    I64 ramSize;
    Bool hasSram;
    I64 banks;
    I64 sramSize;
};
ROMHeader header;

    U8 *ram = MAlloc(0x20000);
    U8 *sram;
    U8 *rom;


  // ppu variables
  I64 cgramAdr;
  Bool cgramSecond;
  I64 cgramBuffer = 0;
  I64 vramInc;
  I64 vramRemap;
  Bool vramIncOnHigh;
  I64 vramAdr;
  I64 vramReadBuffer;
  Bool tilemapWider[4];
  Bool tilemapHigher[4];
  I64 tilemapAdr[4];
  I64 tileAdr[4];
  I64 bgHoff[5];
  I64 bgVoff[5];
  I64 offPrev1;
  I64 offPrev2;
  I64 mode;
  Bool layer3Prio;
  Bool bigTiles[4];
  Bool mosaicEnabled[5];
  I64 mosaicSize;
  I64 mosaicStartLine;
  Bool mainScreenEnabled[5];
  Bool subScreenEnabled[5];
  Bool forcedBlank;
  I64 brightness;
  I64 oamAdr;
  I64 oamRegAdr;
  Bool oamInHigh;
  Bool oamRegInHigh;
  Bool objPriority;
  Bool oamSecond;
  U16 oamBuffer;
  I64 sprAdr1;
  I64 sprAdr2;
  I64 objSize;
  Bool rangeOver;
  Bool timeOver;
  Bool mode7ExBg;
  Bool pseudoHires;
  Bool overscan;
  Bool objInterlace;
  Bool interlace;
  Bool frameOverscan;
  Bool frameInterlace;
  Bool evenFrame;
  I64 latchedHpos;
  I64 latchedVpos;
  Bool latchHsecond;
  Bool latchVsecond;
  Bool countersLatched;
  I64 mode7Hoff;
  I64 mode7Voff;
  I64 mode7A;
  I64 mode7B;
  I64 mode7C;
  I64 mode7D;
  I64 mode7X;
  I64 mode7Y;
  I64 mode7Prev;
  I64 multResult;
  Bool mode7LargeField;
  Bool mode7Char0fill;
  Bool mode7FlipX;
  Bool mode7FlipY;
  Bool window1Inversed[6];
  Bool window1Enabled[6];
  Bool window2Inversed[6];
  Bool window2Enabled[6];
  I64 windowMaskLogic[6];
  I64 window1Left;
  I64 window1Right;
  I64 window2Left;
  I64 window2Right;
  Bool mainScreenWindow[6];
  Bool subScreenWindow[6];
  I64 colorClip;
  I64 preventMath;
  Bool addSub;
  Bool directColor;
  Bool subtractColors;
  Bool halfColors;
  Bool mathEnabled[6];
  I64 fixedColorB;
  I64 fixedColorG;
  I64 fixedColorR;
  I64 tilemapBuffer[4];
  I64 tileBufferP1[4];
  I64 tileBufferP2[4];
  I64 tileBufferP3[4];
  I64 tileBufferP4[4];
  I64 lastTileFetchedX[4];
  I64 lastTileFetchedY[4];
  I64 optHorBuffer[2];
  I64 optVerBuffer[2];
  I64 lastOrigTileX[2];

  I64 dmaOffs[32] = {
    0, 0, 0, 0,
    0, 1, 0, 1,
    0, 0, 0, 0,
    0, 0, 1, 1,
    0, 1, 2, 3,
    0, 1, 0, 1,
    0, 0, 0, 0,
    0, 0, 1, 1
  };

  I64 dmaOffLengths[8] = {1, 2, 2, 4, 4, 4, 2, 4};

  I64 apuCyclesPerMaster = (32040 * 32) / (1364 * 262 * 60);

  U8 spcWritePorts[4];
  U8 spcReadPorts[6];

  // for dma
  U8 dmaBadr[8];
  U16 dmaAadr[8];
  U8 dmaAadrBank[8];
  U16 dmaSize[8];
  U8 hdmaIndBank[8];
  U16 hdmaTableAdr[8];
  U8 hdmaRepCount[8];

    I64 xPos = 0;
    I64 yPos = 0;
    I64 frames = 0;

    I64 cpuCyclesLeft = 5 * 8 + 12; // reset: 5 read cycles + 2 IO cycles
    I64 cpuMemOps = 0;
    I64 apuCatchCycles = 0;

    I64 cyclesLeft; // moved from CPU.HC
    Bool irqWanted; // moved from CPU.HC
    Bool nmiWanted; // moved from CPU.HC

    // for cpu-ports
    I64 ramAdr = 0;

    Bool hIrqEnabled = FALSE;
    Bool vIrqEnabled = FALSE;
    Bool nmiEnabled = FALSE;
    I64 hTimer = 0x1ff;
    I64 vTimer = 0x1ff;
    Bool inNmi = FALSE;
    Bool inIrq = FALSE;
    Bool inHblank = FALSE;
    Bool inVblank = FALSE;

    Bool autoJoyRead = FALSE;
    Bool autoJoyBusy = FALSE;
    I64 autoJoyTimer = 0;
    Bool ppuLatch = FALSE;

    I64 joypad1Val = 0;
    I64 joypad2Val = 0;
    I64 joypad1AutoRead = 0;
    I64 joypad2AutoRead = 0;
    Bool joypadStrobe = FALSE;
    I64 joypad1State = 0; // current button state
    I64 joypad2State = 0; // current button state

    I64 multiplyA = 0xff;
    I64 divA = 0xffff;
    I64 divResult = 0x101;
    I64 mulResult = 0xfe01;

    Bool fastMem = FALSE;

    // dma and hdma
    I64 dmaTimer = 0;
    I64 hdmaTimer = 0;
    Bool dmaBusy = FALSE;
    Bool dmaActive[8] = {FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE};
    Bool hdmaActive[8] = {FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE};

    I64 dmaMode[8] = {0, 0, 0, 0, 0, 0, 0, 0};
    Bool dmaFixed[8] = {FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE};
    Bool dmaDec[8] = {FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE};
    Bool hdmaInd[8] = {FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE};
    Bool dmaFromB[8] = {FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE};

    Bool hdmaDoTransfer[8] = {
      FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE
    };
    Bool hdmaTerminated[8] = {
      FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE
    };
    I64 dmaOffIndex = 0;

    I64 openBus = 0;

    I64 getAccessTime(I64 adr) {
    adr &= 0xffffff;
    I64 bank = adr >> 16;
    adr &= 0xffff;
    if(bank >= 0x40 && bank < 0x80) {
      // banks 0x40-0x7f, all slow
      return 8;
    }
    if(bank >= 0xc0) {
      // banks 0xc0-0xff, depends on speed
      return cond(fastMem, 6, 8);
    }
    // banks 0x00-0x3f and 0x80-0xbf
    if(adr < 0x2000) {
      return 8; // slow
    }
    if(adr < 0x4000) {
      return 6; // fast
    }
    if(adr < 0x4200) {
      return 12; // extra slow
    }
    if(adr < 0x6000) {
      return 6; // fast
    }
    if(adr < 0x8000) {
      return 8; // slow
    }
    // 0x8000-0xffff, depends on fastrom setting if in banks 0x80+
    return cond((fastMem && bank >= 0x80), 6, 8);

  }


U0 catchUpApu() {
  I64 i;
    I64 catchUpCycles = apuCatchCycles & 0xffffffff;
    for(i = 0; i < catchUpCycles; i++) {
      //apu_cycle;
    }
    apuCatchCycles -= catchUpCycles;
}

U0 handleDma() {
    I64 i, tableOff;
    if(dmaTimer > 0) {
      dmaTimer -= 2;
      return;
    }
    // loop over each dma channel to find the first active one
    for(i = 0; i < 8; i++) {
      if(dmaActive[i]) {
        break;
      }
    }
    if(i == 8) {
      // no active channel left, dma is done
      dmaBusy = FALSE;
      dmaOffIndex = 0;
      //log("Finished DMA");
      return;
    }
    tableOff = dmaMode[i] * 4 + dmaOffIndex++;
    dmaOffIndex &= 0x3;
    if(dmaFromB[i]) {
      mem_write(
        (dmaAadrBank[i] << 16) | dmaAadr[i],
        readBBus(
          (dmaBadr[i] + dmaOffs[tableOff]) & 0xff
        ), TRUE
      );
    } else {
      writeBBus(
        (dmaBadr[i] + dmaOffs[tableOff]) & 0xff,
        mem_read((dmaAadrBank[i] << 16) | dmaAadr[i], TRUE)
      );
    }
    dmaTimer += 6;
    // because this run through the function itself also costs 2 master cycles,
    // we have to wait 6 more to get to 8 per byte transferred
    if(!dmaFixed[i]) {
      if(dmaDec[i]) {
        dmaAadr[i]--;
      } else {
        dmaAadr[i]++;
      }
    }
    dmaSize[i]--;
    if(dmaSize[i] == 0) {
      dmaOffIndex = 0;
      dmaActive[i] = FALSE;
      dmaTimer += 8; // 8 extra cycles overhead per channel
    }
  }

  U0 initHdma() {
    hdmaTimer = 18;
    I64 i;
    for(i = 0; i < 8; i++) {
      if(hdmaActive[i]) {
        // terminate DMA if it was busy for this channel
        dmaActive[i] = FALSE;

        hdmaTableAdr[i] = dmaAadr[i];
        hdmaRepCount[i] = mem_read(
          (dmaAadrBank[i] << 16) | hdmaTableAdr[i]++, TRUE
        );
        hdmaTimer += 8;
        if(hdmaInd[i]) {
          dmaSize[i] = mem_read(
            (dmaAadrBank[i] << 16) | hdmaTableAdr[i]++, TRUE
          );
          dmaSize[i] |= mem_read(
            (dmaAadrBank[i] << 16) | hdmaTableAdr[i]++, TRUE
          ) << 8;
          hdmaTimer += 16;
        }
        hdmaDoTransfer[i] = TRUE;
      } else {
        hdmaDoTransfer[i] = FALSE;
      }
      hdmaTerminated[i] = FALSE;
    }
  }

  U0 handleHdma() {
    I64 i, j, tableOff;
    hdmaTimer = 18;
    for(i = 0; i < 8; i++) {
      if(hdmaActive[i] && !hdmaTerminated[i]) {
        // terminate dma if it is busy on this channel
        dmaActive[i] = FALSE;
        hdmaTimer += 8;
        if(hdmaDoTransfer[i]) {
          for(j = 0; j < dmaOffLengths[dmaMode[i]]; j++) {
            tableOff = dmaMode[i] * 4 + j;
            hdmaTimer += 8;
            if(hdmaInd[i]) {
              if(dmaFromB[i]) {
                mem_write(
                  (hdmaIndBank[i] << 16) | dmaSize[i],
                  readBBus(
                    (dmaBadr[i] + dmaOffs[tableOff]) & 0xff
                  ), TRUE
                );
              } else {
                writeBBus(
                  (dmaBadr[i] + dmaOffs[tableOff]) & 0xff,
                  mem_read((hdmaIndBank[i] << 16) | dmaSize[i], TRUE)
                );
              }
              dmaSize[i]++;
            } else {
              if(dmaFromB[i]) {
                mem_write(
                  (dmaAadrBank[i] << 16) | hdmaTableAdr[i],
                  readBBus(
                    (dmaBadr[i] + dmaOffs[tableOff]) & 0xff
                  ), TRUE
                );
              } else {
                writeBBus(
                  (dmaBadr[i] + dmaOffs[tableOff]) & 0xff,
                  mem_read(
                    (dmaAadrBank[i] << 16) | hdmaTableAdr[i], TRUE
                  )
                );
              }
              hdmaTableAdr[i]++;
            }
          }
        }
        hdmaRepCount[i]--;
        hdmaDoTransfer[i] = (hdmaRepCount[i] & 0x80) > 0;
        if((hdmaRepCount[i] & 0x7f) == 0) {
          hdmaRepCount[i] = mem_read(
            (dmaAadrBank[i] << 16) | hdmaTableAdr[i]++, TRUE
          );
          if(hdmaInd[i]) {
            dmaSize[i] = mem_read(
              (dmaAadrBank[i] << 16) | hdmaTableAdr[i]++, TRUE
            );
            dmaSize[i] |= mem_read(
              (dmaAadrBank[i] << 16) | hdmaTableAdr[i]++, TRUE
            ) << 8;
            hdmaTimer += 16;
          }
          if(hdmaRepCount[i] == 0) {
            hdmaTerminated[i] = TRUE;
          }
          hdmaDoTransfer[i] = TRUE;
        }
      }
    }
  }

U0 doAutoJoyRead() {
    I64 i, bit;
    joypad1AutoRead = 0;
    joypad2AutoRead = 0;
    joypad1Val = joypad1State;
    joypad2Val = joypad2State;
    for(i = 0; i < 16; i++) {
      bit = joypad1Val & 0x1;
      joypad1Val >>= 1;
      joypad1Val |= 0x8000;
      joypad1AutoRead |= (bit << (15 - i));
      bit = joypad2Val & 0x1;
      joypad2Val >>= 1;
      joypad2Val |= 0x8000;
      joypad2AutoRead |= (bit << (15 - i));
    }
}

U0 cpuCycle() {
  if(cpuCyclesLeft == 0) {
    cyclesLeft = 0;
    cpuMemOps = 0;
    cpu_cycle;
    cpuCyclesLeft += (cyclesLeft + 1 - cpuMemOps) * 6;
  }
  cpuCyclesLeft -= 2;
}


U0 cycle(Bool noPpu)
{
    apuCatchCycles += (apuCyclesPerMaster * 2);

    if(joypadStrobe) {
      joypad1Val = joypad1State;
      joypad2Val = joypad2State;
    }

    if(hdmaTimer > 0) {
      hdmaTimer -= 2;
    } else if(dmaBusy) {
      handleDma;
    } else if (xPos < 536 || xPos >= 576) {
      // the cpu is paused for 40 cycles starting around dot 536
      cpuCycle;
    }

    if(yPos == vTimer && vIrqEnabled) {
      if(!hIrqEnabled) {
        // only v irq enabed
        if(xPos == 0) {
          inIrq = TRUE;
          irqWanted = TRUE;
        }
      } else {
        // v and h irq enabled
        if(xPos == (hTimer * 4)) {
          inIrq = TRUE;
          irqWanted = TRUE;
        }
      }
    } else if (
      xPos == (hTimer * 4)
      && hIrqEnabled && !vIrqEnabled
    ) {
      // only h irq enabled
      inIrq = TRUE;
      irqWanted = TRUE;
    }

    if(xPos == 1024) {
      // start of hblank
      inHblank = TRUE;
      if(!inVblank) {
        handleHdma;
      }
    } else if(xPos == 0) {
      // end of hblank
      inHblank = FALSE;
    } else if(xPos == 512 && !noPpu) {
      // render line at cycle 512 for better support
      
      renderLine(yPos);
    }

    //renderLine(yPos);

    if(yPos == cond(frameOverscan, 240, 225) && xPos == 0) {
      // start of vblank
      inNmi = TRUE;
      inVblank = TRUE;
      if(autoJoyRead) {
        autoJoyBusy = TRUE;
        autoJoyTimer = 4224;
        doAutoJoyRead;
      }
      if(nmiEnabled) {
        nmiWanted = TRUE;
      }
    } else if(yPos == 0 && xPos == 0) {
      // end of vblank
      inNmi = FALSE;
      inVblank = FALSE;
      initHdma;
    }

    if(autoJoyBusy) {
      autoJoyTimer -= 2; // loop only runs every second master cycle
      if(autoJoyTimer == 0) {
        autoJoyBusy = FALSE;
      }
    }

    // TODO: in non-intelace mode, line 240 on every odd frame is 1360 cycles
    // and in interlace mode, every even frame is 263 lines
    xPos += 2;
    if(xPos == 1364) {
      xPos = 0;
      yPos++;
      if(yPos == 262) {
        // when finishing a frame, also catch up the apu
        catchUpApu;
        yPos = 0;
        frames++;
      }
    }
  }

#define JPAD_Y        0
#define JPAD_B        1
#define JPAD_SELECT   2
#define JPAD_START    3
#define JPAD_UP       4
#define JPAD_DOWN     5
#define JPAD_LEFT     6
#define JPAD_RIGHT    7
#define JPAD_A        8
#define JPAD_X        9
#define JPAD_L        10
#define JPAD_R        11

U0 setPad1Button(I64 num, I64 sc)
{
  switch (KeyDown(sc))
  {
    case 0:
      joypad1State &= (~(1 << num)) & 0xfff;
      break;
    case 1:
      joypad1State |= (1 << num);
      break;
  }
}

U0 Joypad1Update()
{
  setPad1Button(JPAD_Y,       Char2ScanCode('z'));
  setPad1Button(JPAD_B,       Char2ScanCode('a'));
  setPad1Button(JPAD_X,       Char2ScanCode('s'));
  setPad1Button(JPAD_A,       Char2ScanCode('x'));
  setPad1Button(JPAD_L,       Char2ScanCode('d'));
  setPad1Button(JPAD_R,       Char2ScanCode('c'));
  setPad1Button(JPAD_SELECT,  SC_SHIFT);
  setPad1Button(JPAD_START,   SC_ENTER);
  setPad1Button(JPAD_UP,      SC_CURSOR_UP);
  setPad1Button(JPAD_DOWN,    SC_CURSOR_DOWN);
  setPad1Button(JPAD_LEFT,    SC_CURSOR_LEFT);
  setPad1Button(JPAD_RIGHT,   SC_CURSOR_RIGHT);
}