extern U16 br[6];

extern I32 ppu_read(I32 adr);
extern U0 ppu_write(I32 adr, I32 value);

I64 cart_read(I64 bank, I64 adr)
{
  //"bank: %d, addr: %08X\n", bank, adr;
    if(adr < 0x8000) {
      if(bank >= 0x70 && bank < 0x7e && header.hasSram) {
        // sram
        return sram[
          (((bank - 0x70) << 15) | (adr & 0x7fff)) & (header.sramSize - 1)
        ];
        return NULL;
      }
    }

    return rom[((bank & (header.banks - 1)) << 15) | (adr & 0x7fff)];
}

U0 cart_write(I64 bank, I64 adr, I64 value)
{
    if(adr < 0x8000 && bank >= 0x70 && bank < 0x7e && header.hasSram) {
      sram[
        (((bank - 0x70) << 15) | (adr & 0x7fff)) & (header.sramSize - 1)
      ] = value;
    }
}

I64 readReg(I64 adr)
{ 
    I64 val;   
    switch(adr) {
      case 0x4210: {
        val = 0x1;
        val |= cond(inNmi, 0x80, 0);
        val |= openBus & 0x70;
        inNmi = FALSE;
        return val;
      }
      case 0x4211: {
        val = cond(inIrq, 0x80, 0);
        val |= openBus & 0x7f;
        inIrq = FALSE;
        irqWanted = FALSE;
        return val;
      }
      case 0x4212: {
        val = cond(autoJoyBusy, 0x1, 0);
        val |= cond(inHblank, 0x40, 0);
        val |= cond(inVblank, 0x80, 0);
        val |= openBus & 0x3e;
        return val;
      }
      case 0x4213: {
        // IO read register
        return cond(ppuLatch, 0x80, 0);
      }
      case 0x4214: {
        return divResult & 0xff;
      }
      case 0x4215: {
        return (divResult & 0xff00) >> 8;
      }
      case 0x4216: {
        return mulResult & 0xff;
      }
      case 0x4217: {
        return (mulResult & 0xff00) >> 8;
      }
      case 0x4218: {
        return joypad1AutoRead & 0xff;
      }
      case 0x4219: {
        return (joypad1AutoRead & 0xff00) >> 8;
      }
      case 0x421a: {
        return joypad2AutoRead & 0xff;
      }
      case 0x421b: {
        return (joypad2AutoRead & 0xff00) >> 8;
      }
      case 0x421c:
      case 0x421d:
      case 0x421e:
      case 0x421f: {
        // joypads 3 and 4 not emulated
        return 0;
      }
    }

    if(adr >= 0x4300 && adr < 0x4380) {
      I64 channel = (adr & 0xf0) >> 4;
      switch(adr & 0xff0f) {
        case 0x4300: {
          val = dmaMode[channel];
          val |= cond(dmaFixed[channel], 0x8, 0);
          val |= cond(dmaDec[channel], 0x10, 0);
          val |= cond(hdmaInd[channel], 0x40, 0);
          val |= cond(dmaFromB[channel], 0x80, 0);
          return val;
        }
        case 0x4301: {
          return dmaBadr[channel];
        }
        case 0x4302: {
          return dmaAadr[channel] & 0xff;
        }
        case 0x4303: {
          return (dmaAadr[channel] & 0xff00) >> 8;
        }
        case 0x4304: {
          return dmaAadrBank[channel];
        }
        case 0x4305: {
          return dmaSize[channel] & 0xff;
        }
        case 0x4306: {
          return (dmaSize[channel] & 0xff00) >> 8;
        }
        case 0x4307: {
          return hdmaIndBank[channel];
        }
        case 0x4308: {
          return hdmaTableAdr[channel] & 0xff;
        }
        case 0x4309: {
          return (hdmaTableAdr[channel] & 0xff00) >> 8;
        }
        case 0x430a: {
          return hdmaRepCount[channel];
        }
      }
    }

    return openBus;
}

U0 writeReg(I64 adr, I64 value) {
  I64 channel;
    switch(adr) {
      case 0x4200: {
        autoJoyRead = (value & 0x1) > 0;
        hIrqEnabled = (value & 0x10) > 0;
        vIrqEnabled = (value & 0x20) > 0;
        nmiEnabled = (value & 0x80) > 0;
        return;
      }
      case 0x4201: {
        // IO port
        if(ppuLatch && (value & 0x80) == 0) {
          latchedHpos = xPos >> 2;
          latchedVpos = yPos;
          countersLatched = TRUE;
        }
        ppuLatch = (value & 0x80) > 0;
        return;
      }
      case 0x4202: {
        multiplyA = value;
        return;
      }
      case 0x4203: {
        mulResult = multiplyA * value;
        return;
      }
      case 0x4204: {
        divA = (divA & 0xff00) | value;
        return;
      }
      case 0x4205: {
        divA = (divA & 0xff) | (value << 8);
        return;
      }
      case 0x4206: {
        divResult = 0xffff;
        mulResult = divA;
        if(value != 0) {
          divResult = (divA / value) & 0xffff;
          mulResult = divA % value;
        }
        return;
      }
      case 0x4207: {
        hTimer = (hTimer & 0x100) | value;
        return;
      }
      case 0x4208: {
        hTimer = (hTimer & 0xff) | ((value & 0x1) << 8);
        return;
      }
      case 0x4209: {
        vTimer = (vTimer & 0x100) | value;
        return;
      }
      case 0x420a: {
        vTimer = (vTimer & 0xff) | ((value & 0x1) << 8);
        return;
      }
      case 0x420b: {
        // enable dma
        dmaActive[0] = (value & 0x1) > 0;
        dmaActive[1] = (value & 0x2) > 0;
        dmaActive[2] = (value & 0x4) > 0;
        dmaActive[3] = (value & 0x8) > 0;
        dmaActive[4] = (value & 0x10) > 0;
        dmaActive[5] = (value & 0x20) > 0;
        dmaActive[6] = (value & 0x40) > 0;
        dmaActive[7] = (value & 0x80) > 0;
        dmaBusy = value > 0;
        dmaTimer += cond(dmaBusy, 8, 0);
        return;
      }
      case 0x420c: {
        hdmaActive[0] = (value & 0x1) > 0;
        hdmaActive[1] = (value & 0x2) > 0;
        hdmaActive[2] = (value & 0x4) > 0;
        hdmaActive[3] = (value & 0x8) > 0;
        hdmaActive[4] = (value & 0x10) > 0;
        hdmaActive[5] = (value & 0x20) > 0;
        hdmaActive[6] = (value & 0x40) > 0;
        hdmaActive[7] = (value & 0x80) > 0;
        return;
      }
      case 0x420d: {
        fastMem = (value & 0x1) > 0;
        return;
      }
    }

    if(adr >= 0x4300 && adr < 0x4380) {
      channel = (adr & 0xf0) >> 4;
      switch(adr & 0xff0f) {
        case 0x4300: {
          dmaMode[channel] = value & 0x7;
          dmaFixed[channel] = (value & 0x08) > 0;
          dmaDec[channel] = (value & 0x10) > 0;
          hdmaInd[channel] = (value & 0x40) > 0;
          dmaFromB[channel] = (value & 0x80) > 0;
          return;
        }
        case 0x4301: {
          dmaBadr[channel] = value;
          return;
        }
        case 0x4302: {
          dmaAadr[channel] = (dmaAadr[channel] & 0xff00) | value;
          return;
        }
        case 0x4303: {
          dmaAadr[channel] = (dmaAadr[channel] & 0xff) | (value << 8);
          return;
        }
        case 0x4304: {
          dmaAadrBank[channel] = value;
          return;
        }
        case 0x4305: {
          dmaSize[channel] = (dmaSize[channel] & 0xff00) | value;
          return;
        }
        case 0x4306: {
          dmaSize[channel] = (dmaSize[channel] & 0xff) | (value << 8);
          return;
        }
        case 0x4307: {
          hdmaIndBank[channel] = value;
          return;
        }
        case 0x4308: {
          hdmaTableAdr[channel] = (
            hdmaTableAdr[channel] & 0xff00
          ) | value;
          return;
        }
        case 0x4309: {
          hdmaTableAdr[channel] = (
            hdmaTableAdr[channel] & 0xff
          ) | (value << 8);
          return;
        }
        case 0x430a: {
          hdmaRepCount[channel] = value;
          return;
        }
      }
    }
}

Bool flip_fake_spc = FALSE; // FIXME: Implement sound emulation

I64 readBBus(I64 adr) {
  I64 val;
    if(adr > 0x33 && adr < 0x40) {
      return ppu_read(adr);
    }
    if(adr >= 0x40 && adr < 0x80) {
      // catch up the apu, then do the read      
      catchUpApu;
      // FIXME: Implement sound emulation
      if (flip_fake_spc) return br[0];
      flip_fake_spc = !flip_fake_spc;
      return 0xBBAA;
      //return spcWritePorts[adr & 0x3];
    }
    if(adr == 0x80) {
      val = ram[ramAdr++];
      ramAdr &= 0x1ffff;
      return val;
    }
    return openBus; // rest not readable
}

U0 writeBBus(I64 adr, I64 value) {
    if(adr < 0x34) {
      ppu_write(adr, value);
      return;
    }
    if(adr >= 0x40 && adr < 0x80) {
      // catch up the apu, then do the write
      catchUpApu;
      spcReadPorts[adr & 0x3] = value;
      return;
    }
    switch(adr) {
      case 0x80: {
        ram[ramAdr++] = value;
        ramAdr &= 0x1ffff;
        return;
      }
      case 0x81: {
        ramAdr = (ramAdr & 0x1ff00) | value;
        return;
      }
      case 0x82: {
        ramAdr = (ramAdr & 0x100ff) | (value << 8);
        return;
      }
      case 0x83: {
        ramAdr = (ramAdr & 0x0ffff) | ((value & 1) << 16);
        return;
      }
    }
    return;
}

I64 mem_rread(I64 adr)
{
  I64 val;
    adr &= 0xffffff;
    I64 bank = adr >> 16;
    adr &= 0xffff;

    if(bank == 0x7e || bank == 0x7f) {
      // banks 7e and 7f
      return ram[((bank & 0x1) << 16) | adr];
      return NULL;
    }
    if(adr < 0x8000 && (bank < 0x40 || (bank >= 0x80 && bank < 0xc0))) {
      // banks 00-3f, 80-bf, $0000-$7fff
      if(adr < 0x2000) {
        return ram[adr & 0x1fff];
        return NULL;
      }
      if(adr >= 0x2100 && adr < 0x2200) {
        return readBBus(adr & 0xff);
        return NULL;
      }
      // old-style controller reads
      if(adr == 0x4016) {
        val = joypad1Val & 0x1;
        joypad1Val >>= 1;
        joypad1Val |= 0x8000;
        return val;
      }
      if(adr == 0x4017) {
        val = joypad2Val & 0x1;
        joypad2Val >>= 1;
        joypad2Val |= 0x8000;
        return val;
      }
      if(adr >= 0x4200 && adr < 0x4400) {
        return readReg(adr);
      }

      return openBus; // not readable
    }
    return cart_read(bank, adr);
}

I64 mem_read(I64 adr, Bool dma=FALSE)
{
    if(!dma) {
      cpuMemOps++;
      cpuCyclesLeft += getAccessTime(adr);
    }

    I64 val = mem_rread(adr);
    openBus = val;
    return val;
}

U0 mem_write(I64 adr, I64 value, Bool dma = FALSE) {
    if(!dma) {
      cpuMemOps++;
      cpuCyclesLeft += getAccessTime(adr);
    }

    openBus = value;
    adr &= 0xffffff;
    //log("Written $" + getByteRep(value) + " to $" + getLongRep(adr));
    I64 bank = adr >> 16;
    adr &= 0xffff;
    if(bank == 0x7e || bank == 0x7f) {
      // banks 7e and 7f
      ram[((bank & 0x1) << 16) | adr] = value;
    }
    if(adr < 0x8000 && (bank < 0x40 || (bank >= 0x80 && bank < 0xc0))) {
      // banks 00-3f, 80-bf, $0000-$7fff
      if(adr < 0x2000) {
        ram[adr & 0x1fff] = value;
      }
      if(adr >= 0x2100 && adr < 0x2200) {
        writeBBus(adr & 0xff, value);
      }
      if(adr == 0x4016) {
        joypadStrobe = (value & 0x1) > 0;
      }
      if(adr >= 0x4200 && adr < 0x4400) {
        writeReg(adr, value);
      }

    }
    cart_write(bank, adr, value);
}