  U16 *vram = MAlloc(0x8000*2);

  U16 *cgram = MAlloc(0x100*2);

  U16 *oam = MAlloc(0x100*2);
  U16 *highOam = MAlloc(0x10*2);

  U8 *spriteLineBuffer = MAlloc(256);
  U8 *spritePrioBuffer = MAlloc(256);

  I32 *mode7Xcoords = MAlloc(256*4);
  I32 *mode7Ycoords = MAlloc(256*4);

  U16 *pixelOutput = MAlloc((512*3*240)*2);

  I32 layersPerMode[120] = {
    4, 0, 1, 4, 0, 1, 4, 2, 3, 4, 2, 3,
    4, 0, 1, 4, 0, 1, 4, 2, 4, 2, 5, 5,
    4, 0, 4, 1, 4, 0, 4, 1, 5, 5, 5, 5,
    4, 0, 4, 1, 4, 0, 4, 1, 5, 5, 5, 5,
    4, 0, 4, 1, 4, 0, 4, 1, 5, 5, 5, 5,
    4, 0, 4, 1, 4, 0, 4, 1, 5, 5, 5, 5,
    4, 0, 4, 4, 0, 4, 5, 5, 5, 5, 5, 5,
    4, 4, 4, 0, 4, 5, 5, 5, 5, 5, 5, 5,
    2, 4, 0, 1, 4, 0, 1, 4, 2, 4, 5, 5,
    4, 4, 1, 4, 0, 4, 1, 5, 5, 5, 5, 5
  };

  I32 prioPerMode[120] = {
    3, 1, 1, 2, 0, 0, 1, 1, 1, 0, 0, 0,
    3, 1, 1, 2, 0, 0, 1, 1, 0, 0, 5, 5,
    3, 1, 2, 1, 1, 0, 0, 0, 5, 5, 5, 5,
    3, 1, 2, 1, 1, 0, 0, 0, 5, 5, 5, 5,
    3, 1, 2, 1, 1, 0, 0, 0, 5, 5, 5, 5,
    3, 1, 2, 1, 1, 0, 0, 0, 5, 5, 5, 5,
    3, 1, 2, 1, 0, 0, 5, 5, 5, 5, 5, 5,
    3, 2, 1, 0, 0, 5, 5, 5, 5, 5, 5, 5,
    1, 3, 1, 1, 2, 0, 0, 1, 0, 0, 5, 5,
    3, 2, 1, 1, 0, 0, 0, 5, 5, 5, 5, 5
  };

  I32 bitPerMode[40] = {
    2, 2, 2, 2,
    4, 4, 2, 5,
    4, 4, 5, 5,
    8, 4, 5, 5,
    8, 2, 5, 5,
    4, 2, 5, 5,
    4, 5, 5, 5,
    8, 5, 5, 5,
    4, 4, 2, 5,
    8, 7, 5, 5
  };

  I32 layercountPerMode[10] = {12, 10, 8, 8, 8, 8, 6, 5, 10, 7};

  F64 brightnessMults[16] = {
    0.1, 0.5, 1.1, 1.6, 2.2, 2.7, 3.3, 3.8, 4.4, 4.9, 5.5, 6, 6.6, 7.1, 7.6, 8.2
  ;

  I32 spriteTileOffsets[64] = {
    0, 1, 2, 3, 4, 5, 6, 7,
    16, 17, 18, 19, 20, 21, 22, 23,
    32, 33, 34, 35, 36, 37, 38, 39,
    48, 49, 50, 51, 52, 53, 54, 55,
    64, 65, 66, 67, 68, 69, 70, 71,
    80, 81, 82, 83, 84, 85, 86, 87,
    96, 97, 98, 99, 100, 101, 102, 103,
    112, 113, 114, 115, 116, 117, 118, 119
  };

  I32 spriteSizes[16] = {
    1, 1, 1, 2, 2, 4, 2, 2,
    2, 4, 8, 4, 8, 8, 4, 4
  };


U0 ppu_reset()
{
    I32 ii;
    /*
    clearArray(vram);
    clearArray(cgram);
    clearArray(oam);
    clearArray(highOam);

    clearArray(spriteLineBuffer);
    clearArray(spritePrioBuffer);

    clearArray(pixelOutput);

    clearArray(mode7Xcoords);
    clearArray(mode7Ycoords);
    */

  MemSet(vram, NULL, 0x8000*2);
  MemSet(cgram, NULL, 0x100*2);
  MemSet(oam, NULL, 0x100*2);
  MemSet(highOam, NULL,0x10*2);
  MemSet(spriteLineBuffer, NULL, 256);
  MemSet(spritePrioBuffer, NULL, 256);

  MemSet(mode7Xcoords, NULL, 256*4);
  MemSet(mode7Ycoords, NULL, 256*4);

  MemSet(pixelOutput, NULL, ((512*3*240)*2));

    cgramAdr = 0;
    cgramSecond = FALSE;
    cgramBuffer = 0;

    vramInc = 0;
    vramRemap = 0;
    vramIncOnHigh = FALSE;
    vramAdr = 0;
    vramReadBuffer = 0;

    for (ii=0;ii<4;ii++)
    {
        tilemapWider[ii]=FALSE;
        tilemapHigher[ii]=FALSE;
        tilemapAdr[ii]=0;
        tileAdr[ii]=0;
    }

    for (ii=0;ii<5;ii++)
    {
        bgHoff[ii]=0;
        bgVoff[ii]=0;
    }
    offPrev1 = 0;
    offPrev2 = 0;

    mode = 0;
    layer3Prio = FALSE;
    for (ii=0;ii<4;ii++)
    {
        bigTiles[ii]=FALSE;
    }

    for (ii=0;ii<5;ii++)
    {
        mosaicEnabled[ii]=FALSE;
    }
    mosaicSize = 1;
    mosaicStartLine = 1;

    for (ii=0;ii<5;ii++)
    {
        mainScreenEnabled[ii]=FALSE;
        subScreenEnabled[ii]=FALSE;
    }

    forcedBlank = TRUE;
    brightness = 0;

    oamAdr = 0;
    oamRegAdr = 0;
    oamInHigh = FALSE;
    oamRegInHigh = FALSE;
    objPriority = FALSE;
    oamSecond = FALSE;
    oamBuffer = FALSE;

    sprAdr1 = 0;
    sprAdr2 = 0;
    objSize = 0;

    rangeOver = FALSE;
    timeOver = FALSE;

    mode7ExBg = FALSE;
    pseudoHires = FALSE;
    overscan = FALSE;
    objInterlace = FALSE;
    interlace = FALSE;

    frameOverscan = FALSE;
    frameInterlace = FALSE;
    evenFrame = FALSE;

    latchedHpos = 0;
    latchedVpos = 0;
    latchHsecond = FALSE;
    latchVsecond = FALSE;
    countersLatched = FALSE;

    mode7Hoff = 0;
    mode7Voff = 0;
    mode7A = 0;
    mode7B = 0;
    mode7C = 0;
    mode7D = 0;
    mode7X = 0;
    mode7Y = 0;
    mode7Prev = 0;
    multResult = 0;

    mode7LargeField = FALSE;
    mode7Char0fill = FALSE;
    mode7FlipX = FALSE;
    mode7FlipY = FALSE;

    for (ii=0;ii<6;ii++)
    {
        window1Inversed[ii]=FALSE;
        window1Enabled[ii]=FALSE;
        window2Inversed[ii]=FALSE;
        window2Enabled[ii]=FALSE;
        windowMaskLogic[ii]=0;
    }

    window1Left = 0;
    window1Right = 0;
    window2Left = 0;
    window2Right = 0;

    for (ii=0;ii<5;ii++)
    {
        mainScreenWindow[ii]=FALSE;
        subScreenWindow[ii]=FALSE;
    }

    colorClip = 0;
    preventMath = 0;
    addSub = FALSE;
    directColor = FALSE;

    subtractColors = FALSE;
    halfColors = FALSE;

    for (ii=0;ii<6;ii++)
    {
        mathEnabled[ii]=FALSE;
    }
    fixedColorB = 0;
    fixedColorG = 0;
    fixedColorR = 0;

    for (ii=0;ii<4;ii++)
    {
        tilemapBuffer[ii]=0;
        tileBufferP1[ii]=0;
        tileBufferP2[ii]=0;
        tileBufferP3[ii]=0;
        tileBufferP4[ii]=0;
        lastTileFetchedX[ii]=-1;
        lastTileFetchedY[ii]=-1;
    }
    optHorBuffer[0] = 0;
    optHorBuffer[1] = 0;
    optVerBuffer[0] = 0;
    optVerBuffer[1] = 0;
    lastOrigTileX[0] = -1;
    lastOrigTileX[1] = -1;
}

ppu_reset;

  // TODO: better mode 2/4/6 offset-per-tile (especially mode 6), color math
  // when subscreen is visible (especially how to handle the subscreen pixels),
  // mosaic with hires/interlace, mosaic on mode 7, rectangular sprites,
  // oddities with sprite X-position being -256, mosaic with offset-per-tile,
  // offset-per-tile with interlace

  U0 setPixels(U8 *arr) {
      // arr = 32bpp framebuffer
      I32 i, x, y, ind, r, g, b, addY;

    /*
    if(!frameOverscan) {
      // clear the top 8 and bottom 8 lines to transarent
      for(i = 0; i < 512*16; i++) {
        x = i % 512;
        y = (i >> 9);
        ind = (y * 512 + x) * 4;
        arr[ind + 3] = 0;
      }
      for(i = 0; i < 512*16; i++) {
        x = i % 512;
        y = (i >> 9);
        ind = ((y + 464) * 512 + x) * 4;
        arr[ind + 3] = 0;
      }
    }
    */

    addY = cond(frameOverscan, 0, 14);

    for(i = 512; i < 512 * cond(frameOverscan, 240, 225); i++) {
      x = i % 512;
      y = (i >> 9) * 2;
      ind = ((y + addY) * 512 + x) * 4;
      r = pixelOutput[i * 3];
      g = pixelOutput[i * 3 + 1];
      b = pixelOutput[i * 3 + 2];
      if(!frameInterlace || evenFrame) {
        arr[ind] = b;
        arr[ind + 1] = g;
        arr[ind + 2] = r;
        arr[ind + 3] = 255;
      }
      ind += 512 * 4;
      if(!frameInterlace || !evenFrame) {
        arr[ind] = b;
        arr[ind + 1] = g;
        arr[ind + 2] = r;
        arr[ind + 3] = 255;
      }
    }

}

U0 evaluateSprites(I32 line) {
    I32 spriteCount, sliverCount, index, i, j, k, x, y, tile, ex, big, size, sprRow;
    I32 adr, tileRow, tileColumn, tileNum, tileP1, tileP2, shift, tileData, color, xInd;
    spriteCount = 0;
    sliverCount = 0;
    // search through oam, backwards
    index = cond(objPriority, ((oamAdr & 0xfe) - 2) & 0xff, 254);
    for(i = 0; i < 128; i++) {
      x = oam[index] & 0xff;
      y = (oam[index] & 0xff00) >> 8;
      tile = oam[index + 1] & 0xff;
      ex = (oam[index + 1] & 0xff00) >> 8;
      x |= (highOam[index >> 4] >> (index & 0xf) & 0x1) << 8;
      big = (highOam[index >> 4] >> (index & 0xf) & 0x2) > 0;
      x = cond(x > 255, -(512 - x), x);
      
      // check for being on this line
      size = spriteSizes[objSize + (cond(big, 8, 0))];
      sprRow = line - y;
      if(sprRow < 0 || sprRow >= size * (cond(objInterlace, 4, 8))) {
        // check if it is a sprite from the top of the screen
        sprRow = line + (256 - y);
      }
      if(
        sprRow >= 0 && sprRow < size * (cond(objInterlace, 4, 8)) &&
        x > -(size * 8)
      ) {
        // in range, show it
        if(spriteCount == 32) {
          // this would be the 33th sprite, exit the loop
          rangeOver = TRUE;
          break;
        }
        sprRow = cond(objInterlace, sprRow * 2 + (
          cond(evenFrame, 1, 0)
        ), sprRow);
        // fetch the tile(s)
        adr = sprAdr1 + (cond((ex & 0x1) > 0, sprAdr2, 0));
        sprRow = cond(((ex & 0x80) > 0), (size * 8) - 1 - sprRow, sprRow);
        tileRow = sprRow >> 3;
        sprRow &= 0x7;
        for(k = 0; k < size; k++) {
          if((x + k * 8) > -7 && (x + k * 8) < 256) {
            if(sliverCount == 34) {
              sliverCount = 35;
              break; // exit tile fetch loop, maximum slivers
            }
            tileColumn = cond(((ex & 0x40) > 0), size - 1 - k, k);
            tileNum = tile + spriteTileOffsets[
              tileRow * 8 + tileColumn
            ];
            tileNum &= 0xff;
            tileP1 = vram[
              (adr + tileNum * 16 + sprRow) & 0x7fff
            ];
            tileP2 = vram[
              (adr + tileNum * 16 + sprRow + 8) & 0x7fff
            ];
            // and draw it in the line buffer
            for(j = 0; j < 8; j++) {
              shift = cond(((ex & 0x40) > 0), j, 7 - j);
              tileData = (tileP1 >> shift) & 0x1;
              tileData |= ((tileP1 >> (8 + shift)) & 0x1) << 1;
              tileData |= ((tileP2 >> shift) & 0x1) << 2;
              tileData |= ((tileP2 >> (8 + shift)) & 0x1) << 3;
              color = tileData + 16 * ((ex & 0xe) >> 1);
              xInd = x + k * 8 + j;
              if(tileData > 0 && xInd < 256 && xInd >= 0) {
                spriteLineBuffer[xInd] = 0x80 + color;
                spritePrioBuffer[xInd] = (ex & 0x30) >> 4;
              }
            }
            sliverCount++;
          }
        }
        if(sliverCount == 35) {
          // we exited the tile fetch loop because we reached max slivers
          // se we can stop evaluating sprites
          timeOver = TRUE;
          break;
        }

        spriteCount++;
      }

      index = (index - 2) & 0xff;
    }
  }

U0 generateMode7Coords(I32 y) {
    I32 i, rY, clippedH, clippedV, lineStartX, lineStartY;
    rY = cond(mode7FlipY, 255 - y, y);

    clippedH = mode7Hoff - mode7X;
    clippedH = cond((clippedH & 0x2000) > 0, (clippedH | ~0x3ff), (clippedH & 0x3ff));
    clippedV = mode7Voff - mode7Y;
    clippedV = cond((clippedV & 0x2000) > 0, (clippedV | ~0x3ff), (clippedV & 0x3ff));

    lineStartX = (
      ((mode7A * clippedH) & ~63) +
      ((mode7B * rY) & ~63) + ((mode7B * clippedV) & ~63) +
      (mode7X << 8)
    );
    lineStartY = (
      ((mode7C * clippedH) & ~63) +
      ((mode7D * rY) & ~63) + ((mode7D * clippedV) & ~63) +
      (mode7Y << 8)
    );

    mode7Xcoords[0] = lineStartX;
    mode7Ycoords[0] = lineStartY;

    for(i = 1; i < 256; i++) {
      mode7Xcoords[i] = mode7Xcoords[i - 1] + mode7A;
      mode7Ycoords[i] = mode7Ycoords[i - 1] + mode7C;
    }
  }

Bool getWindowState(I32 x, I32 l) {
    Bool test, w1test, w2test;
    if(!window1Enabled[l] && !window2Enabled[l]) {
      return FALSE;
    }
    if(window1Enabled[l] && !window2Enabled[l]) {
      test = x >= window1Left && x <= window1Right;
      return cond(window1Inversed[l], !test, test);
    }
    if(!window1Enabled[l] && window2Enabled[l]) {
      test = x >= window2Left && x <= window2Right;
      return cond(window2Inversed[l], !test, test);
    }
    // both window enabled
    w1test = x >= window1Left && x <= window1Right;
    w1test = cond(window1Inversed[l], !w1test, w1test);
    w2test = x >= window2Left && x <= window2Right;
    w2test = cond(window2Inversed[l], !w2test, w2test);
    switch(windowMaskLogic[l]) {
      case 0: {
        return w1test || w2test;
      }
      case 1: {
        return w1test && w2test;
      }
      case 2: {
        return w1test != w2test;
      }
      case 3: {
        return w1test == w2test;
      }
    }
}

Bool getMathEnabled(I32 x, I32 l, I32 pal) {
    if(
      preventMath == 3 ||
      (preventMath == 2 && getWindowState(x, 5)) ||
      (preventMath == 1 && !getWindowState(x, 5))
    ) {
      return FALSE;
    }
    if(mathEnabled[l] && (l != 4 || pal >= 0xc0)) {
      return TRUE;
    }
    return FALSE;
}

U0 fetchTileInBuffer(I32 x, I32 y, I32 l, I32 offset) {
    I32 rx, ry, adr, yFlip, xFlip, yRow, tileNum, bits;
    Bool useXbig;
    rx = x;
    ry = y;
    useXbig = bigTiles[l] | mode == 5 | mode == 6;
    x >>= cond(useXbig, 1, 0);
    y >>= cond(bigTiles[l], 1, 0);

    adr = tilemapAdr[l] + (
      ((y & 0xff) >> 3) << 5 | ((x & 0xff) >> 3)
    );
    adr += cond(((x & 0x100) > 0 && tilemapWider[l]), 1024, 0);
    adr += cond(((y & 0x100) > 0 && tilemapHigher[l]), (
      cond(tilemapWider[l], 2048, 1024)
    ), 0);
    tilemapBuffer[l] = vram[adr & 0x7fff];
    if(offset) {
      // for offset-per-tile, we only nees the tilemap byte,
      // don't fetch the tiles themselves
      return;
    }
    yFlip = (tilemapBuffer[l] & 0x8000) > 0;
    xFlip = (tilemapBuffer[l] & 0x4000) > 0;
    yRow = cond(yFlip, 7 - (ry & 0x7), (ry & 0x7));
    tileNum = tilemapBuffer[l] & 0x3ff;

    tileNum += cond(useXbig && (rx & 0x8) == cond(xFlip, 0, 8), 1, 0);
    tileNum += cond(bigTiles[l] && (ry & 0x8) == cond(yFlip, 0, 8), 0x10, 0);

    bits = bitPerMode[mode * 4 + l];

    tileBufferP1[l] = vram[
      (tileAdr[l] + tileNum * 4 * bits + yRow) & 0x7fff
    ];
    if(bits > 2) {
      tileBufferP2[l] = vram[
        (tileAdr[l] + tileNum * 4 * bits + yRow + 8) & 0x7fff
      ];
    }
    if(bits > 4) {
      tileBufferP3[l] = vram[
        (tileAdr[l] + tileNum * 4 * bits + yRow + 16) & 0x7fff
      ];
      tileBufferP4[l] = vram[
        (tileAdr[l] + tileNum * 4 * bits + yRow + 24) & 0x7fff
      ];
    }
}

I32 getMode7Pixel(I32 x, I32 y, I32 l, I32 p) {
    I32 pixelData, rX, px, py, tileX, tileY, tileByte;
    Bool pixelIsTransparent;
    pixelData = tilemapBuffer[0];
    if(x != lastTileFetchedX[0] || y != lastTileFetchedY[0]) {
      rX = cond(mode7FlipX, 255 - x, x);

      px = mode7Xcoords[rX] >> 8;
      py = mode7Ycoords[rX] >> 8;

      pixelIsTransparent = FALSE;

      if(mode7LargeField && (px < 0 || px >= 1024 || py < 0 || py >= 1024)) {
        if(mode7Char0fill) {
          // always use tile 0
          px &= 0x7;
          py &= 0x7;
        } else {
          // act as transparent
          pixelIsTransparent = TRUE;
        }
      }
      // fetch the right tilemap byte
      tileX = (px & 0x3f8) >> 3;
      tileY = (py & 0x3f8) >> 3;

      tileByte = vram[(tileY * 128 + tileX)] & 0xff;
      // fetch the tile
      pixelData = vram[tileByte * 64 + (py & 0x7) * 8 + (px & 0x7)];
      pixelData >>= 8;
      pixelData = cond(pixelIsTransparent, 0, pixelData);
      tilemapBuffer[0] = pixelData;
      lastTileFetchedX[0] = x;
      lastTileFetchedY[0] = y;
    }

    if(l == 1 && (pixelData >> 7) != p) {
      // wrong priority
      return 0;
    } else if(l == 1) {
      return pixelData & 0x7f;
    }

    return pixelData;
  }



  I32 getPixelForLayer(I32 x, I32 y, I32 l, I32 p) {
      I32 mapWord, paletteNum, xShift, bits, mul, tileData;
    if(l > 3) {
      if(spritePrioBuffer[x] != p) {
        return 0;
      }
      return spriteLineBuffer[x];
    }

    if(mode == 7) {
      return getMode7Pixel(x, y, l, p);
    }

    if(
      (x >> 3) != lastTileFetchedX[l] ||
      y != lastTileFetchedY[l]
    ) {
      fetchTileInBuffer(x, y, l, FALSE);
      lastTileFetchedX[l] = (x >> 3);
      lastTileFetchedY[l] = y;
    }

    mapWord = tilemapBuffer[l];
    if(((mapWord & 0x2000) >> 13) != p) {
      // not the right priority
      return 0;
    }
    paletteNum = (mapWord & 0x1c00) >> 10;
    xShift = cond((mapWord & 0x4000) > 0, (x & 0x7), 7 - (x & 0x7));

    paletteNum += cond(mode == 0, l * 8, 0);

    bits = bitPerMode[mode * 4 + l];
    mul = 4;
    tileData = (tileBufferP1[l] >> xShift) & 0x1;
    tileData |= ((tileBufferP1[l] >> (8 + xShift)) & 0x1) << 1;

    if(bits > 2) {
      mul = 16;
      tileData |= ((tileBufferP2[l] >> xShift) & 0x1) << 2;
      tileData |= ((tileBufferP2[l] >> (8 + xShift)) & 0x1) << 3;
    }

    if(bits > 4) {
      mul = 256;
      tileData |= ((tileBufferP3[l] >> xShift) & 0x1) << 4;
      tileData |= ((tileBufferP3[l] >> (8 + xShift)) & 0x1) << 5;
      tileData |= ((tileBufferP4[l] >> xShift) & 0x1) << 6;
      tileData |= ((tileBufferP4[l] >> (8 + xShift)) & 0x1) << 7;
    }

    return cond(tileData > 0, (paletteNum * mul + tileData), 0);
}

U0 getColor(Bool sub, I32 x, I32 y, I32* lay) {
    I32 modeIndex, count, j, pixel, layer, lx, ly, optX, andVal, tileStartX, add, color, r, g, b;

     modeIndex = cond(layer3Prio && mode == 1, 96, 12 * mode);
    modeIndex = cond(mode7ExBg && mode == 7, 108, modeIndex);
     count = layercountPerMode[mode];

     pixel = 0;
     layer = 5;
    if(interlace && (mode == 5 || mode == 6)) {
      y = y * 2 + cond(evenFrame, 1, 0);
    }
    for(j = 0; j < count; j++) {
       lx = x;
       ly = y;
      layer = layersPerMode[modeIndex + j];
      if(
        (
          !sub && mainScreenEnabled[layer] &&
          (!mainScreenWindow[layer] || !getWindowState(lx, layer))
        ) || (
          sub && subScreenEnabled[layer] &&
          (!subScreenWindow[layer] || !getWindowState(lx, layer))
        )
      ) {
        if(mosaicEnabled[layer]) {
          lx -= lx % mosaicSize;
          ly -= (ly - mosaicStartLine) % mosaicSize;
        }
        lx += cond(mode == 7, 0, bgHoff[layer]);
        ly += cond(mode == 7, 0, bgVoff[layer]);
         optX = lx - bgHoff[layer];
        if((mode == 5 || mode == 6) && layer < 4) {
          lx = lx * 2 + cond(sub, 0, 1);
          optX = optX * 2 + cond(sub, 0, 1);
        }

        // origLx = lx;

        if((mode == 2 || mode == 4 || mode == 6) && layer < 2) {
           andVal = cond(layer == 0, 0x2000, 0x4000);
          if(x == 0) {
            lastOrigTileX[layer] = lx >> 3;
          }
          // where the relevant tile started
          // TODO: lx can be above 0xffff (e.g. if scroll is 0xffff, and x > 0)
           tileStartX = optX - (lx - (lx & 0xfff8));
          if((lx >> 3) != lastOrigTileX[layer] && x > 0) {
            // we are fetching a new tile for the layer, get a new OPT-tile
            // if(logging && y == 32 && (mode == 2 || mode == 4 || mode == 6) && layer == 0) {
            //   log("at X = " + x + ", lx: " + getWordRep(lx) + ", fetched new tile for OPT");
            // }
            fetchTileInBuffer(
              bgHoff[2] + ((tileStartX - 1) & 0x1f8),
              bgVoff[2], 2, TRUE
            );
            optHorBuffer[layer] = tilemapBuffer[2];
            if(mode == 4) {
              if((optHorBuffer[layer] & 0x8000) > 0) {
                optVerBuffer[layer] = optHorBuffer[layer];
                optHorBuffer[layer] = 0;
              } else {
                optVerBuffer[layer] = 0;
              }
            } else {
              fetchTileInBuffer(
                bgHoff[2] + ((tileStartX - 1) & 0x1f8),
                bgVoff[2] + 8, 2, TRUE
              );
              optVerBuffer[layer] = tilemapBuffer[2];
            }
            lastOrigTileX[layer] = lx >> 3;
          }
          if((optHorBuffer[layer] & andVal) > 0) {
            //origLx = lx;
             add = ((tileStartX + 7) & 0x1f8);
            lx = (lx & 0x7) + ((optHorBuffer[layer] + add) & 0x1ff8);
          }
          if((optVerBuffer[layer] & andVal) > 0) {
            ly = (optVerBuffer[layer] & 0x1fff) + (ly - bgVoff[layer]);
          }
        }
        // if(logging && y == 32 && (mode == 2 || mode == 4 || mode == 6) && layer == 0) {
        //   log("at X = " + x + ", lx: " + getWordRep(lx) + ", ly: " + getWordRep(ly) + ", optHB: " + getWordRep(optHorBuffer[layer]) + ", orig lx: " + getWordRep(origLx));
        // }

        pixel = getPixelForLayer(
          lx, ly,
          layer,
          prioPerMode[modeIndex + j]
        );
      }
      if((pixel & 0xff) > 0) {
        break;
      }
    }
    layer = cond(j == count, 5, layer);
     color = cgram[pixel & 0xff];
    if(
      directColor && layer < 4 &&
      bitPerMode[mode * 4 + layer] == 8
    ) {
       r = ((pixel & 0x7) << 2) | ((pixel & 0x100) >> 7);
       g = ((pixel & 0x38) >> 1) | ((pixel & 0x200) >> 8);
       b = ((pixel & 0xc0) >> 3) | ((pixel & 0x400) >> 8);
      color = (b << 10) | (g << 5) | r;
    }

    lay[0] = color;
    lay[1] = layer;
    lay[2] = pixel;
}

  U0 renderLine(I32 line) {
      I32 r1, g1, b1, r2, g2, b2, i, bMult, color;
      I32 colLay[3];
      I32 secondLay[3];
    if(line == 225 && overscan) {
      frameOverscan = TRUE;
    }
    if(line == 0) {
      // pre-render line
      rangeOver = FALSE;
      timeOver = FALSE;
      frameOverscan = FALSE;
      frameInterlace = FALSE;
      MemSet(spriteLineBuffer, NULL, 256);
      if(!forcedBlank) {
        evaluateSprites(0);
      }
    } else if(line == (cond(frameOverscan,240, 225))) {
      // beginning of Vblank
      if(!forcedBlank) {
        oamAdr = oamRegAdr;
        oamInHigh = oamRegInHigh;
      }
      frameInterlace = interlace;
      evenFrame = !evenFrame;
    } else if(line > 0 && line < (cond(frameOverscan, 240, 225))) {
      // visible line
      if(line == 1) {
        mosaicStartLine = 1;
      }
      if(mode == 7) {
        generateMode7Coords(line);
      }
      
      lastTileFetchedX[0] = -1;
      lastTileFetchedX[1] = -1;
      lastTileFetchedX[2] = -1;
      lastTileFetchedX[3] = -1;
      lastTileFetchedY[0] = -1;
      lastTileFetchedY[1] = -1;
      lastTileFetchedY[2] = -1;
      lastTileFetchedY[3] = -1;
      optHorBuffer[0] = 0;
      optHorBuffer[1] = 0;
      optVerBuffer[0] = 0;
      optVerBuffer[1] = 0;
      lastOrigTileX[0] = -1;
      lastOrigTileX[1] = -1;
      bMult = brightnessMults[brightness];
      i = 0;
      while(i < 256) {
        // for each pixel

        r1 = 0;
        g1 = 0;
        b1 = 0;
        r2 = 0;
        g2 = 0;
        b2 = 0;

        if(!forcedBlank) {

          getColor(FALSE, i, line, &colLay);
          color = colLay[0];

          r2 = color & 0x1f;
          g2 = (color & 0x3e0) >> 5;
          b2 = (color & 0x7c00) >> 10;

          // TODO: docs day that this clips before math, but it seems to simply
          // always clip the pixels to black?
          if(
            colorClip == 3 ||
            (colorClip == 2 && getWindowState(i, 5)) ||
            (colorClip == 1 && !getWindowState(i, 5))
          ) {
            r2 = 0;
            g2 = 0;
            b2 = 0;
          }

          secondLay[0] = 0;
          secondLay[1] = 5;
          secondLay[2] = 0;
          if(
            mode == 5 || mode == 6 || pseudoHires ||
            (getMathEnabled(i, colLay[1], colLay[2]) && addSub)
          ) {
            getColor(TRUE, i, line, &secondLay);
            r1 = secondLay[0] & 0x1f;
            g1 = (secondLay[0] & 0x3e0) >> 5;
            b1 = (secondLay[0] & 0x7c00) >> 10;
          }

          if(getMathEnabled(i, colLay[1], colLay[2])) {
            if(subtractColors) {
              r2 -= cond((addSub && secondLay[1] < 5), r1, fixedColorR);
              g2 -= cond((addSub && secondLay[1] < 5), g1, fixedColorG);
              b2 -= cond((addSub && secondLay[1] < 5), b1, fixedColorB);
            } else {
              r2 += cond((addSub && secondLay[1] < 5), r1, fixedColorR);
              g2 += cond((addSub && secondLay[1] < 5), g1, fixedColorG);
              b2 += cond((addSub && secondLay[1] < 5), b1, fixedColorB);
            }
            // TODO: docs say that halfing should not happen if adding the
            // direct color, but that makes some effects in the SNES character
            // test look wrong
            if(halfColors && (secondLay[1] < 5 || !addSub)) {
              r2 >>= 1;
              g2 >>= 1;
              b2 >>= 1;
            }
            r2 = cond(r2 > 31, 31, r2);
            r2 = cond(r2 < 0, 0, r2);
            g2 = cond(g2 > 31, 31, g2);
            g2 = cond(g2 < 0, 0, g2);
            b2 = cond(b2 > 31, 31, b2);
            b2 = cond(b2 < 0, 0, b2);
          }

          if(!(mode == 5 || mode == 6 || pseudoHires)) {
            r1 = r2;
            g1 = g2;
            b1 = b2;
          }

        }
        pixelOutput[line * 1536 + 6 * i] = (r1 * bMult) & 0xff;
        pixelOutput[line * 1536 + 6 * i + 1] = (g1 * bMult) & 0xff;
        pixelOutput[line * 1536 + 6 * i + 2] = (b1 * bMult) & 0xff;
        pixelOutput[line * 1536 + 6 * i + 3] = (r2 * bMult) & 0xff;
        pixelOutput[line * 1536 + 6 * i + 4] = (g2 * bMult) & 0xff;
        pixelOutput[line * 1536 + 6 * i + 5] = (b2 * bMult) & 0xff;

        i++;

      }
      MemSet(spriteLineBuffer, NULL, 256);
      if(!forcedBlank) {
        evaluateSprites(line);
      }
    }
  }

  I32 getVramRemap() {
      I32 adr;
    adr = vramAdr & 0x7fff;
    if(vramRemap == 1) {
      adr = (adr & 0xff00) | ((adr & 0xe0) >> 5) | ((adr & 0x1f) << 3);
    } else if(vramRemap == 2) {
      adr = (adr & 0xfe00) | ((adr & 0x1c0) >> 6) | ((adr & 0x3f) << 3);
    } else if(vramRemap == 3) {
      adr = (adr & 0xfc00) | ((adr & 0x380) >> 7) | ((adr & 0x7f) << 3);
    }
    return adr;
  }

I32 get13Signed(I32 val) {
    if((val & 0x1000) > 0) {
      return -(8192 - (val & 0xfff));
    }
    return (val & 0xfff);
  }

I32 get16Signed(I32 val) {
    if((val & 0x8000) > 0) {
      return -(65536 - val);
    }
    return val;
  }

I32 getMultResult(I32 a, I32 b) {
    b = cond(b < 0, 65536 + b, b);
    b >>= 8;
    b = cond(((b & 0x80) > 0), -(256 - b), b);
    I32 _ans = a * b;
    if(_ans < 0) {
      return 16777216 + _ans;
    }
    return _ans;
  }  

I32 ppu_read(I32 adr) {
    I32 val;
    switch(adr) {
      case 0x34: {
        return multResult & 0xff;
      }
      case 0x35: {
        return (multResult & 0xff00) >> 8;
      }
      case 0x36: {
        return (multResult & 0xff0000) >> 16;
      }
      case 0x37: {
        // TODO: docs say this should only happen if bit 7 of the IO port is
        // set, but always doing it makes The Legend of Zelda: A Link to the
        // Past work
        //if(ppuLatch) {
        latchedHpos = xPos >> 2;
        latchedVpos = yPos;
        //}
        countersLatched = TRUE;
        return openBus;
      }
      case 0x38: {
        if(!oamSecond) {
          if(oamInHigh) {
            val = highOam[oamAdr & 0xf] & 0xff;
          } else {
            val = oam[oamAdr] & 0xff;
          }
          oamSecond = TRUE;
        } else {
          if(oamInHigh) {
            val = highOam[oamAdr & 0xf] >> 8;
          } else {
            val = oam[oamAdr] >> 8;
          }
          oamAdr++;
          oamAdr &= 0xff;
          oamInHigh = cond((
            oamAdr == 0
          ), !oamInHigh, oamInHigh);
          oamSecond = FALSE;
        }
        return val;
      }
      case 0x39: {
        val = vramReadBuffer;
        vramReadBuffer = vram[getVramRemap()];
        if(!vramIncOnHigh) {
          vramAdr += vramInc;
          vramAdr &= 0xffff;
        }
        return val & 0xff;
      }
      case 0x3a: {
        val = vramReadBuffer;
        vramReadBuffer = vram[getVramRemap()];
        if(vramIncOnHigh) {
          vramAdr += vramInc;
          vramAdr &= 0xffff;
        }
        return (val & 0xff00) >> 8;
      }
      case 0x3b: {

        if(!cgramSecond) {
          val = cgram[cgramAdr] & 0xff;
          cgramSecond = TRUE;
        } else {
          val = cgram[cgramAdr++] >> 8;
          cgramAdr &= 0xff;
          cgramSecond = FALSE;
        }
        return val;
      }
      case 0x3c: {
        
        if(!latchHsecond) {
          val = latchedHpos & 0xff;
          latchHsecond = TRUE;
        } else {
          val = (latchedHpos & 0xff00) >> 8;
          latchHsecond = FALSE;
        }
        return val;
      }
      case 0x3d: {
        
        if(!latchVsecond) {
          val = latchedVpos & 0xff;
          latchVsecond = TRUE;
        } else {
          val = (latchedVpos & 0xff00) >> 8;
          latchVsecond = FALSE;
        }
        return val;
      }
      case 0x3e: {
        val = cond(timeOver, 0x80, 0);
        val |= cond(rangeOver, 0x40, 0);
        return val | 0x1;
      }
      case 0x3f: {
        val = cond(evenFrame, 0x80, 0);
        val |= cond(countersLatched, 0x40, 0);
        if(ppuLatch) {
          countersLatched = FALSE;
        }
        latchHsecond = FALSE;
        latchVsecond = FALSE;
        /* PAL: val |= 0x10; */
        return val | 0x2;
      }
    }
    return openBus;
}

U0 ppu_write(I32 adr, I32 value) {
    I32 incVal, _adr;
    switch(adr) {
      case 0x00: {
        forcedBlank = (value & 0x80) > 0;
        brightness = value & 0xf;
        return;
      }
      case 0x01: {
        sprAdr1 = (value & 0x7) << 13;
        sprAdr2 = ((value & 0x18) + 8) << 9;
        objSize = (value & 0xe0) >> 5;
        return;
      }
      case 0x02: {
        oamAdr = value;
        oamRegAdr = oamAdr;
        oamInHigh = oamRegInHigh;
        oamSecond = FALSE;
        return;
      }
      case 0x03: {
        oamInHigh = (value & 0x1) > 0;
        objPriority = (value & 0x80) > 0;
        oamAdr = oamRegAdr;
        oamRegInHigh = oamInHigh;
        oamSecond = FALSE;
        return;
      }
      case 0x04: {
        if(!oamSecond) {
          if(oamInHigh) {
            highOam[
              oamAdr & 0xf
            ] = (highOam[oamAdr & 0xf] & 0xff00) | value;
          } else {
            oamBuffer = (oamBuffer & 0xff00) | value;
          }
          oamSecond = TRUE;
        } else {
          if(oamInHigh) {
            highOam[
              oamAdr & 0xf
            ] = (highOam[oamAdr & 0xf] & 0xff) | (value << 8);
          } else {
            oamBuffer = (oamBuffer & 0xff) | (value << 8);
            oam[oamAdr] = oamBuffer;
          }
          oamAdr++;
          oamAdr &= 0xff;
          oamInHigh = cond((
            oamAdr == 0
          ), !oamInHigh, oamInHigh);
          oamSecond = FALSE;
        }
        return;
      }
      case 0x05: {
        mode = value & 0x7;
        layer3Prio = (value & 0x08) > 0;
        bigTiles[0] = (value & 0x10) > 0;
        bigTiles[1] = (value & 0x20) > 0;
        bigTiles[2] = (value & 0x40) > 0;
        bigTiles[3] = (value & 0x80) > 0;
        return;
      }
      case 0x06: {
        mosaicEnabled[0] = (value & 0x1) > 0;
        mosaicEnabled[1] = (value & 0x2) > 0;
        mosaicEnabled[2] = (value & 0x4) > 0;
        mosaicEnabled[3] = (value & 0x8) > 0;
        mosaicSize = ((value & 0xf0) >> 4) + 1;
        mosaicStartLine = yPos;
        return;
      }
      case 0x07:
      case 0x08:
      case 0x09:
      case 0x0a: {
        tilemapWider[adr - 7] = (value & 0x1) > 0;
        tilemapHigher[adr - 7] = (value & 0x2) > 0;
        tilemapAdr[adr - 7] = (value & 0xfc) << 8;
        return;
      }
      case 0x0b: {
        tileAdr[0] = (value & 0xf) << 12;
        tileAdr[1] = (value & 0xf0) << 8;
        return;
      }
      case 0x0c: {
        tileAdr[2] = (value & 0xf) << 12;
        tileAdr[3] = (value & 0xf0) << 8;
        return;
      }
      case 0x0d: {
        mode7Hoff = get13Signed((value << 8) | mode7Prev);
        mode7Prev = value;
        // fall through to also set normal layer bgHoff
      }
      case 0x0f:
      case 0x11:
      case 0x13: {
        bgHoff[
          (adr - 0xd) >> 1
        ] = (value << 8) | (offPrev1 & 0xf8) | (offPrev2 & 0x7);
        offPrev1 = value;
        offPrev2 = value;
        return;
      }
      case 0x0e: {
        mode7Voff = get13Signed((value << 8) | mode7Prev);
        mode7Prev = value;
        // fall through to also set normal layer bgVoff
      }
      case 0x10:
      case 0x12:
      case 0x14: {
        bgVoff[
          (adr - 0xe) >> 1
        ] = (value << 8) | (offPrev1 & 0xff);
        offPrev1 = value;
        return;
      }
      case 0x15: {
        incVal = value & 0x3;
        if(incVal == 0) {
          vramInc = 1;
        } else if(incVal == 1) {
          vramInc = 32;
        } else {
          vramInc = 128;
        }
        vramRemap = (value & 0xc0) >> 2;
        vramIncOnHigh = (value & 0x80) > 0;
        return;
      }
      case 0x16: {
        vramAdr = (vramAdr & 0xff00) | value;
        vramReadBuffer = vram[getVramRemap()];
        return;
      }
      case 0x17: {
        vramAdr = (vramAdr & 0xff) | (value << 8);
        vramReadBuffer = vram[getVramRemap()];
        return;
      }
      case 0x18: {
        _adr = getVramRemap();
        vram[_adr] = (vram[_adr] & 0xff00) | value;
        if(!vramIncOnHigh) {
          vramAdr += vramInc;
          vramAdr &= 0xffff;
        }
        return;
      }
      case 0x19: {
        _adr = getVramRemap();
        vram[_adr] = (vram[_adr] & 0xff) | (value << 8);
        if(vramIncOnHigh) {
          vramAdr += vramInc;
          vramAdr &= 0xffff;
        }
        return;
      }
      case 0x1a: {
        mode7LargeField = (value & 0x80) > 0;
        mode7Char0fill = (value & 0x40) > 0;
        mode7FlipY = (value & 0x2) > 0;
        mode7FlipX = (value & 0x1) > 0;
        return;
      }
      case 0x1b: {
        mode7A = get16Signed((value << 8) | mode7Prev);
        mode7Prev = value;
        multResult = getMultResult(mode7A, mode7B);
        return;
      }
      case 0x1c: {
        mode7B = get16Signed((value << 8) | mode7Prev);
        mode7Prev = value;
        multResult = getMultResult(mode7A, mode7B);
        return;
      }
      case 0x1d: {
        mode7C = get16Signed((value << 8) | mode7Prev);
        mode7Prev = value;
        return;
      }
      case 0x1e: {
        mode7D = get16Signed((value << 8) | mode7Prev);
        mode7Prev = value;
        return;
      }
      case 0x1f: {
        mode7X = get13Signed((value << 8) | mode7Prev);
        mode7Prev = value;
        return;
      }
      case 0x20: {
        mode7Y = get13Signed((value << 8) | mode7Prev);
        mode7Prev = value;
        return;
      }
      case 0x21: {
        cgramAdr = value;
        cgramSecond = FALSE;
        return;
      }
      case 0x22: {
        if(!cgramSecond) {
          cgramBuffer = (cgramBuffer & 0xff00) | value;
          cgramSecond = TRUE;
        } else {
          cgramBuffer = (cgramBuffer & 0xff) | (value << 8);
          cgram[cgramAdr++] = cgramBuffer;
          cgramAdr &= 0xff;
          cgramSecond = FALSE;
        }
        return;
      }
      case 0x23: {
        window1Inversed[0] = (value & 0x01) > 0;
        window1Enabled[0] = (value & 0x02) > 0;
        window2Inversed[0] = (value & 0x04) > 0;
        window2Enabled[0] = (value & 0x08) > 0;
        window1Inversed[1] = (value & 0x10) > 0;
        window1Enabled[1] = (value & 0x20) > 0;
        window2Inversed[1] = (value & 0x40) > 0;
        window2Enabled[1] = (value & 0x80) > 0;
        return;
      }
      case 0x24: {
        window1Inversed[2] = (value & 0x01) > 0;
        window1Enabled[2] = (value & 0x02) > 0;
        window2Inversed[2] = (value & 0x04) > 0;
        window2Enabled[2] = (value & 0x08) > 0;
        window1Inversed[3] = (value & 0x10) > 0;
        window1Enabled[3] = (value & 0x20) > 0;
        window2Inversed[3] = (value & 0x40) > 0;
        window2Enabled[3] = (value & 0x80) > 0;
        return;
      }
      case 0x25: {
        window1Inversed[4] = (value & 0x01) > 0;
        window1Enabled[4] = (value & 0x02) > 0;
        window2Inversed[4] = (value & 0x04) > 0;
        window2Enabled[4] = (value & 0x08) > 0;
        window1Inversed[5] = (value & 0x10) > 0;
        window1Enabled[5] = (value & 0x20) > 0;
        window2Inversed[5] = (value & 0x40) > 0;
        window2Enabled[5] = (value & 0x80) > 0;
        return;
      }
      case 0x26: {
        window1Left = value;
        return;
      }
      case 0x27: {
        window1Right = value;
        return;
      }
      case 0x28: {
        window2Left = value;
        return;
      }
      case 0x29: {
        window2Right = value;
        return;
      }
      case 0x2a: {
        windowMaskLogic[0] = value & 0x3;
        windowMaskLogic[1] = (value & 0xc) >> 2;
        windowMaskLogic[2] = (value & 0x30) >> 4;
        windowMaskLogic[3] = (value & 0xc0) >> 6;
        return;
      }
      case 0x2b: {
        windowMaskLogic[4] = value & 0x3;
        windowMaskLogic[5] = (value & 0xc) >> 2;
        return;
      }
      case 0x2c: {
        mainScreenEnabled[0] = (value & 0x1) > 0;
        mainScreenEnabled[1] = (value & 0x2) > 0;
        mainScreenEnabled[2] = (value & 0x4) > 0;
        mainScreenEnabled[3] = (value & 0x8) > 0;
        mainScreenEnabled[4] = (value & 0x10) > 0;
        return;
      }
      case 0x2d: {
        subScreenEnabled[0] = (value & 0x1) > 0;
        subScreenEnabled[1] = (value & 0x2) > 0;
        subScreenEnabled[2] = (value & 0x4) > 0;
        subScreenEnabled[3] = (value & 0x8) > 0;
        subScreenEnabled[4] = (value & 0x10) > 0;
        return;
      }
      case 0x2e: {
        mainScreenWindow[0] = (value & 0x1) > 0;
        mainScreenWindow[1] = (value & 0x2) > 0;
        mainScreenWindow[2] = (value & 0x4) > 0;
        mainScreenWindow[3] = (value & 0x8) > 0;
        mainScreenWindow[4] = (value & 0x10) > 0;
        return;
      }
      case 0x2f: {
        subScreenWindow[0] = (value & 0x1) > 0;
        subScreenWindow[1] = (value & 0x2) > 0;
        subScreenWindow[2] = (value & 0x4) > 0;
        subScreenWindow[3] = (value & 0x8) > 0;
        subScreenWindow[4] = (value & 0x10) > 0;
        return;
      }
      case 0x30: {
        colorClip = (value & 0xc0) >> 6;
        preventMath = (value & 0x30) >> 4;
        addSub = (value & 0x2) > 0;
        directColor = (value & 0x1) > 0;
        return;
      }
      case 0x31: {
        subtractColors = (value & 0x80) > 0;
        halfColors = (value & 0x40) > 0;
        mathEnabled[0] = (value & 0x1) > 0;
        mathEnabled[1] = (value & 0x2) > 0;
        mathEnabled[2] = (value & 0x4) > 0;
        mathEnabled[3] = (value & 0x8) > 0;
        mathEnabled[4] = (value & 0x10) > 0;
        mathEnabled[5] = (value & 0x20) > 0;
        return;
      }
      case 0x32: {
        if((value & 0x80) > 0) {
          fixedColorB = value & 0x1f;
        }
        if((value & 0x40) > 0) {
          fixedColorG = value & 0x1f;
        }
        if((value & 0x20) > 0) {
          fixedColorR = value & 0x1f;
        }
        return;
      }
      case 0x33: {
        mode7ExBg = (value & 0x40) > 0;
        pseudoHires = (value & 0x08) > 0;
        overscan = (value & 0x04) > 0;
        objInterlace = (value & 0x02) > 0;
        interlace = (value & 0x01) > 0;
        return;
      }
    }
  }