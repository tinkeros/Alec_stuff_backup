/*
Quick 'n Dirty TrueType Rasterizer by Alec Murphy
TrueType File Format Parser based on FontReaderCs by Iain Ballard, converted to
HolyC by Alec Murphy

https://github.com/i-e-b/FontReaderCs

BSD 3-Clause License

Copyright (c) 2018, Iain Ballard
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the copyright holder nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

U32 @truetype_Seek(U8 *data, U32 *pos, U32 newPos) {
  I64 oldPos = pos[0];
  pos[0] = newPos;
  return oldPos;
}

U8 @truetype_GetUint8(U64 data, U32 *pos) {
  U8 byte = *(data + pos[0])(U8 *)&0xFF;
  pos[0]++;
  return byte;
}
U16 @truetype_GetUint16(U64 data, U32 *pos) {
  U16 word = *(data + pos[0])(U16 *)&0xFFFF;
  pos[0] += 2;
  return EndianU16(word);
}
I16 @truetype_GetInt16(U64 data, U32 *pos) {
  return @truetype_GetUint16(data, pos)(I16);
}
U32 @truetype_GetUint32(U64 data, U32 *pos) {
  U32 dword = *(data + pos[0])(U32 *)&0xFFFFFFFF;
  pos[0] += 4;
  return EndianU32(dword);
}
I32 @truetype_GetInt32(U64 data, U32 *pos) {
  return @truetype_GetUint32(data, pos);
}
I16 @truetype_GetFWord(U8 *data, U32 *pos) {
  return @truetype_GetInt16(data, pos);
}
F64 @truetype_GetFixed(U8 *data, U32 *pos) { // TODO: fixed to float conversion
  return ToF64(@truetype_GetInt32(data, pos) / (1 << 16));
}
U8 *@truetype_GetString(U8 *data, U32 *pos, I64 length) {
  U8 *result = CAlloc(length + 1);
  I64 i;
  for (i = 0; i < length; i++) {
    result[i] = @truetype_GetUint8(data, pos);
  }
  return result;
}
CDate @truetype_GetDate(U8 *data, U32 *pos) { // TODO: implement this
  U32 i = @truetype_GetUint32(data, pos);
  i = @truetype_GetUint32(data, pos);
  return NULL;
}
U0 @truetype_Skip(U8 *data, U32 *pos, I64 dist) { pos[0] += dist; }
U16 @truetype_PickUint16(U8 *data, I64 baseAddr, I32 index) {
  I64 i = index * 2;
  U16 a = data[baseAddr + i];
  U16 b = data[baseAddr + i + 1];
  return ((a << 8) + b) & 0xFFFF;
}
I16 @truetype_PickInt16(U8 *data, I64 baseAddr, I32 index) {
  I64 i = index * 2;
  I16 a = data[baseAddr + i];
  I16 b = data[baseAddr + i + 1];
  return ((a << 8) + b) & 0xFFFF;
}

#define @truetype_HEADER_MAGIC 0x5f0f3cf5

#define GLYF_ON_CURVE 1
#define GLYF_X_IS_BYTE 2
#define GLYF_Y_IS_BYTE 4
#define GLYF_REPEAT 8
#define GLYF_X_DELTA 16
#define GLYF_Y_DELTA 32

class @truetype_OffsetEntry {
  U32 Checksum;
  U32 Offset;
  U32 Length;
};

class @truetype_FontHeader {
  F64 Version;
  F64 Revision;
  U32 ChecksumAdjustment;
  U32 MagicNumber;
  U16 Flags;
  U16 UnitsPerEm;
  CDate Created;
  CDate Modified;
  I16 xMin;
  I16 yMin;
  I16 xMax;
  I16 yMax;
  U16 MacStyle;
  U16 LowestRecPPEM;
  I16 FontDirectionHint;
  I16 IndexToLocFormat;
  I16 GlyphDataFormat;
};

  // enum GlyphTypes

#define glyf_Simple 0
#define glyf_Compound 1
#define glyf_Empty 2

  // enum CompoundGlyphFlags

#define GLYF_ARG_1_AND_2_ARE_WORDS 1
#define GLYF_ARGS_ARE_XY_VALUES 2
#define GLYF_ROUND_XY_TO_GRID 4
#define GLYF_WE_HAVE_A_SCALE 8
#define GLYF_RESERVED1 16
#define GLYF_MORE_COMPONENTS 32
#define GLYF_WE_HAVE_AN_X_AND_Y_SCALE 64
#define GLYF_WE_HAVE_A_TWO_BY_TWO 128
#define GLYF_WE_HAVE_INSTRUCTIONS 256
#define GLYF_USE_MY_METRICS 512
#define GLYF_OVERLAP_COMPONENT 1024

class @truetype_CompoundComponent {
  I32 GlyphIndex;
  F64 **Matrix; // variable sized
  I32 DestPointIndex;
  I32 SrcPointIndex;
};

class @truetype_End {
  @truetype_End *next;
  U16 value;
}

class @truetype_SimpleGlyphFlag {
  @truetype_SimpleGlyphFlag *next;
  U8 flag;
};

class @truetype_GlyphPoint {
  @truetype_GlyphPoint *next;
  Bool OnCurve;
  F64 X;
  F64 Y;
};

class @truetype_Glyph {
  I32 GlyphType;
  I32 NumberOfContours;
  F64 xMin, xMax, yMin, yMax;
  @truetype_CompoundComponent **Components;
  U8 SourceCharacter;
  U8 *SourceFont;
  @truetype_SimpleGlyphFlag *Flags;
  @truetype_GlyphPoint *Points;
  @truetype_End *ContourEnds;
  CDC *dc;
};

class @truetype_tablesList {
  @truetype_tablesList *next;
  U8 *string;
  @truetype_OffsetEntry *offsetEntry;
};

class @truetype_unicodeIndexesList {
  @truetype_unicodeIndexesList *next;
  U8 ch;
  I32 idx;
};

class @truetype_glyphCacheList {
  @truetype_glyphCacheList *next;
  I32 idx;
  @truetype_Glyph *glyph;
};

class @truetype_TrueTypeFont {
  @truetype_TrueTypeFont *prev;
  @truetype_TrueTypeFont *next;
  U64 data;
  I64 size;
  U32 pos;
  U8 *_filename;
  @truetype_tablesList *_tables;
  @truetype_unicodeIndexesList *_unicodeIndexes;
  @truetype_glyphCacheList *_glyphCache;
  @truetype_FontHeader *_header;
  U32 _scalarType;
  U16 _searchRange;
  U16 _entrySelector;
  U16 _rangeShift;
  U16 _length;
};

U0 @truetype_tablesListAdd(@truetype_tablesList *tables, U8 *tag,
                           @truetype_OffsetEntry *entry) {
  @truetype_tablesList *new = CAlloc(sizeof(@truetype_tablesList));
  while (tables->next) {
    tables = tables->next;
  }
  new->string = tag;
  new->offsetEntry = entry;
  tables->next = new;
}

U0 @truetype_unicodeIndexesListAdd(@truetype_unicodeIndexesList *indexes, U8 ch,
                                   I32 idx) {
  @truetype_unicodeIndexesList *new =
      CAlloc(sizeof(@truetype_unicodeIndexesList));
  while (indexes->next) {
    indexes = indexes->next;
  }
  new->ch = ch;
  new->idx = idx;
  indexes->next = new;
}

U0 @truetype_glyphCacheListAdd(@truetype_glyphCacheList *glyphs, I32 idx,
                               @truetype_Glyph *glyph) {
  @truetype_glyphCacheList *new = CAlloc(sizeof(@truetype_glyphCacheList));
  while (glyphs->next) {
    glyphs = glyphs->next;
  }
  new->idx = idx;
  new->glyph = glyph;
  glyphs->next = new;
}

@truetype_tablesList *@truetype_ReadOffsetTables(@truetype_TrueTypeFont *ttf) {
  I64 i;
  U8 *tag;
  @truetype_OffsetEntry *entry;
  @truetype_tablesList *tables = CAlloc(sizeof(@truetype_tablesList));

  // DO NOT REARRANGE CALLS!
  ttf->_scalarType = @truetype_GetUint32(ttf->data, &ttf->pos);
  I64 numTables = @truetype_GetUint16(ttf->data, &ttf->pos) & 0xFFFF;
  ttf->_searchRange = @truetype_GetUint16(ttf->data, &ttf->pos);
  ttf->_entrySelector = @truetype_GetUint16(ttf->data, &ttf->pos);
  ttf->_rangeShift = @truetype_GetUint16(ttf->data, &ttf->pos);
  for (i = 0; i < numTables; i++) {
    tag = @truetype_GetString(ttf->data, &ttf->pos, 4);
    entry = CAlloc(sizeof(@truetype_OffsetEntry));
    entry->Checksum = @truetype_GetUint32(ttf->data, &ttf->pos);
    entry->Offset = @truetype_GetUint32(ttf->data, &ttf->pos);
    entry->Length = @truetype_GetUint32(ttf->data, &ttf->pos);
    @truetype_tablesListAdd(tables, tag, entry);
  }
  return tables;
}

Bool @truetype_OffsetTablesContainsKey(@truetype_TrueTypeFont *ttf, U8 *key) {
  @truetype_tablesList *tables = ttf->_tables;
  while (tables) {
    if (tables->string) {
      if (!StrCmp(tables->string, key)) {
        return TRUE;
      };
    }
    tables = tables->next;
  }
  return FALSE;
}

@truetype_tablesList *@truetype_OffsetTablesGetKey(@truetype_TrueTypeFont *ttf,
                                                   U8 *key) {
  @truetype_tablesList *tables = ttf->_tables;
  while (tables) {
    if (tables->string) {
      if (!StrCmp(tables->string, key)) {
        return tables;
      };
    }
    tables = tables->next;
  }
  return NULL;
}

Bool @truetype_UnicodeIndexesContainsKey(@truetype_TrueTypeFont *ttf, U8 key) {
  @truetype_unicodeIndexesList *indexes = ttf->_unicodeIndexes;
  while (indexes) {
    if (indexes->ch) {
      if (indexes->ch == key) {
        return TRUE;
      };
    }
    indexes = indexes->next;
  }
  return FALSE;
}

@truetype_unicodeIndexesList *@truetype_UnicodeIndexesGetKey(
    @truetype_TrueTypeFont *ttf, U8 key) {
  @truetype_unicodeIndexesList *indexes = ttf->_unicodeIndexes;
  while (indexes) {
    if (indexes->ch) {
      if (indexes->ch == key) {
        return indexes;
      };
    }
    indexes = indexes->next;
  }
  return NULL;
}

Bool @truetype_GlyphCacheContainsKey(@truetype_TrueTypeFont *ttf, I32 key) {
  @truetype_glyphCacheList *cache = ttf->_glyphCache;
  while (cache) {
    if (cache->idx) {
      if (cache->idx == key) {
        return TRUE;
      };
    }
    cache = cache->next;
  }
  return FALSE;
}

@truetype_glyphCacheList *@truetype_GlyphCacheGetKey(
    @truetype_TrueTypeFont *ttf, I32 key) {
  @truetype_glyphCacheList *cache = ttf->_glyphCache;
  while (cache) {
    if (cache->idx) {
      if (cache->idx == key) {
        return cache;
      };
    }
    cache = cache->next;
  }
  return NULL;
}

U16 @truetype_GlyphCount(@truetype_TrueTypeFont *ttf) {
  if (!@truetype_OffsetTablesContainsKey(ttf, "maxp")) {
    Panic("Bad font: maxp table missing (no glyph count)");
  }
  @truetype_tablesList *maxp = @truetype_OffsetTablesGetKey(ttf, "maxp");
  U32 old = @truetype_Seek(ttf->data, &ttf->pos, maxp->offsetEntry->Offset + 4);
  U16 count = @truetype_GetUint16(ttf->data, &ttf->pos);
  @truetype_Seek(ttf->data, &ttf->pos, old);
  return count;
}

@truetype_FontHeader *@truetype_ReadHeadTable(@truetype_TrueTypeFont *ttf) {
  if (!@truetype_OffsetTablesContainsKey(ttf, "head")) {
    Panic("Bad font: Header table missing!");
  }
  @truetype_tablesList *head = @truetype_OffsetTablesGetKey(ttf, "head");
  @truetype_Seek(ttf->data, &ttf->pos, head->offsetEntry->Offset);

  @truetype_FontHeader *h = CAlloc(sizeof(@truetype_FontHeader));

  // DO NOT REARRANGE CALLS!
  h->Version = @truetype_GetFixed(ttf->data, &ttf->pos);
  h->Revision = @truetype_GetFixed(ttf->data, &ttf->pos);
  h->ChecksumAdjustment = @truetype_GetUint32(ttf->data, &ttf->pos);
  h->MagicNumber = @truetype_GetUint32(ttf->data, &ttf->pos);

  if (h->MagicNumber != @truetype_HEADER_MAGIC) {
    Panic("Bad font: incorrect identifier in header table");
  }

  h->Flags = @truetype_GetUint16(ttf->data, &ttf->pos);
  h->UnitsPerEm = @truetype_GetUint16(ttf->data, &ttf->pos);
  h->Created = @truetype_GetDate(ttf->data, &ttf->pos);
  h->Modified = @truetype_GetDate(ttf->data, &ttf->pos);

  h->xMin = @truetype_GetFWord(ttf->data, &ttf->pos);
  h->yMin = @truetype_GetFWord(ttf->data, &ttf->pos);
  h->xMax = @truetype_GetFWord(ttf->data, &ttf->pos);
  h->yMax = @truetype_GetFWord(ttf->data, &ttf->pos);

  h->MacStyle = @truetype_GetUint16(ttf->data, &ttf->pos);
  h->LowestRecPPEM = @truetype_GetUint16(ttf->data, &ttf->pos);
  h->FontDirectionHint = @truetype_GetInt16(ttf->data, &ttf->pos);
  h->IndexToLocFormat = @truetype_GetInt16(ttf->data, &ttf->pos);
  h->GlyphDataFormat = @truetype_GetInt16(ttf->data, &ttf->pos);

  return h;
}

@truetype_TrueTypeFont *TrueTypeFont(U8 *filename) {
  @truetype_TrueTypeFont *ttf = CAlloc(sizeof(@truetype_TrueTypeFont));
  ttf->_filename = StrNew(StrLastOcc(filename, "/") + 1);
  *StrLastOcc(ttf->_filename, ".") = NULL;
  ttf->data = FileRead(filename, &ttf->size);

  ttf->_unicodeIndexes = CAlloc(sizeof(@truetype_unicodeIndexesList));
  ttf->_glyphCache = CAlloc(sizeof(@truetype_glyphCacheList));

  // The order that things are read below is important
  // DO NOT REARRANGE CALLS!
  ttf->_tables = @truetype_ReadOffsetTables(ttf);
  ttf->_header = @truetype_ReadHeadTable(ttf);
  ttf->_length = @truetype_GlyphCount(ttf);

  if (!@truetype_OffsetTablesContainsKey(ttf, "glyf")) {
    Panic("Bad font: glyf table missing");
  }
  if (!@truetype_OffsetTablesContainsKey(ttf, "loca")) {
    Panic("Bad font: loca table missing");
  }

  return ttf;
}

I16 @truetype_GlyphIndexForChar(@truetype_TrueTypeFont *ttf, U8 wantedChar) {
  // read cmap table if possible,
  // then call down to the index based ReadGlyph.

  if (!@truetype_OffsetTablesContainsKey(ttf, "cmap")) {
    Panic("Can't translate character: cmap table missing");
  }
  @truetype_tablesList *cmap = @truetype_OffsetTablesGetKey(ttf, "cmap");
  @truetype_Seek(ttf->data, &ttf->pos, cmap->offsetEntry->Offset);

  I64 i;
  U16 vers = @truetype_GetUint16(ttf->data, &ttf->pos);
  U16 numTables = @truetype_GetUint16(ttf->data, &ttf->pos);
  U32 offset = 0;
  Bool found = FALSE;

  for (i = 0; i < numTables; i++) {
    U16 platform = @truetype_GetUint16(ttf->data, &ttf->pos);
    U16 encoding = @truetype_GetUint16(ttf->data, &ttf->pos);
    offset = @truetype_GetUint32(ttf->data, &ttf->pos);

    if (platform == 3 &&
        encoding == 1) // Unicode 2 byte encoding for Basic Multilingual Plane
    {
      found = TRUE;
      break;
    }
  }

  if (!found) {
    return 0; // the specific 'missing' glyph
  }

  // format 4 table
  if (offset < ttf->pos) {
    @truetype_Seek(ttf->data, &ttf->pos, cmap->offsetEntry->Offset + offset);
  } // guessing
  else {
    @truetype_Seek(ttf->data, &ttf->pos, offset);
  }

  U16 subtableFmt = @truetype_GetUint16(ttf->data, &ttf->pos);

  U16 byteLength = @truetype_GetUint16(ttf->data, &ttf->pos);
  U16 res1 = @truetype_GetUint16(ttf->data, &ttf->pos); // should be 0
  U16 segCountX2 = @truetype_GetUint16(ttf->data, &ttf->pos);
  U16 searchRange = @truetype_GetUint16(ttf->data, &ttf->pos);
  U16 entrySelector = @truetype_GetUint16(ttf->data, &ttf->pos);
  U16 rangeShift = @truetype_GetUint16(ttf->data, &ttf->pos);

  if (subtableFmt != 4) {
    Panic("Invalid font: Unicode BMP table with non- format 4 subtable");
  }

  // read the parallel arrays
  I32 segs = segCountX2 / 2;
  I32 endsBase = ttf->pos;
  I32 startsBase = endsBase + segCountX2 + 2;
  I32 idDeltaBase = startsBase + segCountX2;
  I32 idRangeOffsetBase = idDeltaBase + segCountX2;

  I32 targetSegment = -1;

  I32 c = wantedChar & 0xFF;

  for (i = 0; i < segs; i++) {
    I32 end = @truetype_PickUint16(ttf->data, endsBase, i);
    I32 start = @truetype_PickUint16(ttf->data, startsBase, i);
    if (end >= c && start <= c) {
      targetSegment = i;
      break;
    }
  }

  if (targetSegment < 0)
    return 0; // the specific 'missing' glyph

  U16 rangeOffset =
      @truetype_PickUint16(ttf->data, idRangeOffsetBase, targetSegment);
  if (rangeOffset == 0) {
    // direct lookup:
    U16 lu = @truetype_PickInt16(
        ttf->data, idDeltaBase,
        targetSegment); // this can represent a negative by way of the modulo
    I32 glyphIdx = (lu + c) % 65536;
    return glyphIdx;
  }

  // Complex case. The TrueType spec expects us to have mapped the font into
  // memory, then do some nasty pointer arithmetic. "This obscure indexing trick
  // works because glyphIdArray immediately follows idRangeOffset in the font
  // file"

  // https://docs.microsoft.com/en-us/typography/opentype/spec/cmap
  // https://github.com/LayoutFarm/Typography/wiki/How-To-Translate-Unicode-Character-Codes-to-TrueType-Glyph-Indices-in-Windows-95
  // https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6cmap.html
  //
  U16 ros = @truetype_PickUint16(ttf->data, idRangeOffsetBase, targetSegment);
  U16 startc = @truetype_PickUint16(ttf->data, startsBase, targetSegment);
  I32 offsro = idRangeOffsetBase + (targetSegment * 2);
  I32 glyphIndexAddress = ros + 2 * (c - startc) + offsro;
  U16 res = @truetype_PickInt16(ttf->data, glyphIndexAddress, 0);

  return res;
}

U0 @truetype_EndsAdd(@truetype_End *ends, U16 value) {
  @truetype_End *new = CAlloc(sizeof(@truetype_End));
  while (ends->next) {
    ends = ends->next;
  }
  new->value = value;
  ends->next = new;
}

U16 @truetype_EndsMax(@truetype_End *ends) {
  U16 res = 0;
  while (ends) {
    res = Max(res, ends->value);
    ends = ends->next;
  }
  return res & 0xFFFF;
}

U0 @truetype_FlagsAdd(@truetype_SimpleGlyphFlag *flags, U8 flag) {
  @truetype_SimpleGlyphFlag *new = CAlloc(sizeof(@truetype_SimpleGlyphFlag));
  while (flags->next) {
    flags = flags->next;
  }
  new->flag = flag;
  flags->next = new;
}

U0 @truetype_PointsAdd(@truetype_GlyphPoint *points, Bool onCurve) {
  @truetype_GlyphPoint *new = CAlloc(sizeof(@truetype_GlyphPoint));
  while (points->next) {
    points = points->next;
  }
  new->OnCurve = onCurve;
  points->next = new;
}

U0 @truetype_ElaborateCoordsX(@truetype_TrueTypeFont *ttf,
                              @truetype_SimpleGlyphFlag *flags,
                              @truetype_GlyphPoint *points) {
  F64 value = 0.0;
  if (!flags || !points) {
    return;
  }
  flags = flags->next;
  points = points->next;
  while (flags) {
    if (flags->flag & GLYF_X_IS_BYTE) {
      if (flags->flag & GLYF_X_DELTA) {
        value += ToF64(@truetype_GetUint8(ttf->data, &ttf->pos));
      } else {
        value -= ToF64(@truetype_GetUint8(ttf->data, &ttf->pos));
      }

    } else if (!(flags->flag & GLYF_X_DELTA)) {
      value += ToF64(@truetype_GetInt16(ttf->data, &ttf->pos));
    } else {
      // value not changed
      // this is why X and Y are separate
    }
    points->X = value;
    while (points->X > 32767) {
      points->X -= 65536;
    }
    flags = flags->next;
    points = points->next;
  }
}

U0 @truetype_ElaborateCoordsY(@truetype_TrueTypeFont *ttf,
                              @truetype_SimpleGlyphFlag *flags,
                              @truetype_GlyphPoint *points) {
  F64 value = 0.0;
  if (!flags || !points) {
    return;
  }
  flags = flags->next;
  points = points->next;
  while (flags) {
    if (flags->flag & GLYF_Y_IS_BYTE) {
      if (flags->flag & GLYF_Y_DELTA) {
        value += ToF64(@truetype_GetUint8(ttf->data, &ttf->pos));
      } else {
        value -= ToF64(@truetype_GetUint8(ttf->data, &ttf->pos));
      }

    } else if (!(flags->flag & GLYF_Y_DELTA)) {
      value += ToF64(@truetype_GetInt16(ttf->data, &ttf->pos));
    } else {
      // value not changed
      // this is why X and Y are separate
    }
    points->Y = value;
    while (points->Y > 32767) {
      points->Y -= 65536;
    }
    flags = flags->next;
    points = points->next;
  }
}

U0 @truetype_ReadSimpleGlyph(@truetype_TrueTypeFont *ttf, @truetype_Glyph *g) {
  I64 i;
  U8 flag;
  U8 repeatCount;
  @truetype_GlyphPoint *point;
  g->GlyphType = glyf_Simple;
  g->ContourEnds = CAlloc(sizeof(@truetype_End));

  for (i = 0; i < g->NumberOfContours; i++) {
    @truetype_EndsAdd(g->ContourEnds,
                      @truetype_GetUint16(ttf->data, &ttf->pos));
  }

  // Skip past hinting instructions
  @truetype_Skip(ttf->data, &ttf->pos,
                 @truetype_GetUint16(ttf->data, &ttf->pos));

  U16 numPoints = @truetype_EndsMax(g->ContourEnds) + 1;

  // Flags and points match up
  g->Flags = CAlloc(sizeof(@truetype_SimpleGlyphFlag));
  g->Points = CAlloc(sizeof(@truetype_GlyphPoint));

  // Read point flags, creating base entries
  for (i = 0; i < numPoints; i++) {
    flag = @truetype_GetUint8(ttf->data, &ttf->pos);
    @truetype_FlagsAdd(g->Flags, flag);
    @truetype_PointsAdd(g->Points, flag & GLYF_ON_CURVE);

    if (flag & GLYF_REPEAT) {
      repeatCount = @truetype_GetUint8(ttf->data, &ttf->pos);
      i += (repeatCount & 0xFF);
      while (repeatCount-- > 0) {
        @truetype_FlagsAdd(g->Flags, flag);
        @truetype_PointsAdd(g->Points, flag & GLYF_ON_CURVE);
      }
    }
  }

  // Fill out point data
  @truetype_ElaborateCoordsX(ttf, g->Flags, g->Points);
  @truetype_ElaborateCoordsY(ttf, g->Flags, g->Points);
}

U32 @truetype_GetGlyphOffset(@truetype_TrueTypeFont *ttf, I32 index) {
  @truetype_tablesList *loca = @truetype_OffsetTablesGetKey(ttf, "loca");
  @truetype_tablesList *glyf = @truetype_OffsetTablesGetKey(ttf, "glyf");
  U32 size = loca->offsetEntry->Offset + loca->offsetEntry->Length;
  U32 offset, old, target;

  if (ttf->_header->IndexToLocFormat == 1) {
    target = loca->offsetEntry->Offset + index * 4;
    if (target + 4 > size) {
      Panic("Glyph index out of range");
    }
    old = @truetype_Seek(ttf->data, &ttf->pos, target);
    offset = @truetype_GetUint32(ttf->data, &ttf->pos);
  } else {
    target = loca->offsetEntry->Offset + index * 2;
    if (target + 2 > size) {
      Panic("Glyph index out of range");
    }
    old = @truetype_Seek(ttf->data, &ttf->pos, target);
    offset = @truetype_GetUint16(ttf->data, &ttf->pos) * 2;
  }
  @truetype_Seek(ttf->data, &ttf->pos, old);
  return offset + glyf->offsetEntry->Offset;
}

@truetype_Glyph *@truetype_ReadGlyphByIndex(@truetype_TrueTypeFont *ttf,
                                            I32 index, Bool forceEmpty) {
  @truetype_tablesList *glyf = @truetype_OffsetTablesGetKey(ttf, "glyf");
  U32 offset = @truetype_GetGlyphOffset(ttf, index);

  if (offset >= glyf->offsetEntry->Offset + glyf->offsetEntry->Length) {
    Panic("Bad font: Invalid glyph offset (too high) at index");
  }
  if (offset < glyf->offsetEntry->Offset) {
    Panic("Bad font: Invalid glyph offset (too low) at index");
  }

  @truetype_Seek(ttf->data, &ttf->pos, offset);
  @truetype_Glyph *g = CAlloc(sizeof(@truetype_Glyph));
  g->NumberOfContours = @truetype_GetInt16(ttf->data, &ttf->pos);
  g->xMin = @truetype_GetFWord(ttf->data, &ttf->pos);
  g->yMin = @truetype_GetFWord(ttf->data, &ttf->pos);
  g->xMax = @truetype_GetFWord(ttf->data, &ttf->pos);
  g->yMax = @truetype_GetFWord(ttf->data, &ttf->pos);

  if (g->NumberOfContours < -1) {
    Panic("Bad font: Invalid contour count at index");
  }
  U32 baseOffset = ttf->pos;
  if (forceEmpty || g->NumberOfContours == 0) {
    g->GlyphType = glyf_Empty;
    return g;
  }
  if (g->NumberOfContours == -1) {
    // Compounds not yet supported
    g->GlyphType = glyf_Empty;
    return g;
  }
  @truetype_ReadSimpleGlyph(ttf, g);
  return g;
}

@truetype_Glyph *@truetype_ReadGlyph(@truetype_TrueTypeFont *ttf, U8 ch) {
  if (!@truetype_UnicodeIndexesContainsKey(ttf, ch)) {
    @truetype_unicodeIndexesListAdd(ttf->_unicodeIndexes, ch,
                                    @truetype_GlyphIndexForChar(ttf, ch));
  }
  U32 offset = @truetype_UnicodeIndexesGetKey(ttf, ch)->idx;

  if (!@truetype_GlyphCacheContainsKey(ttf, offset)) {
    @truetype_Glyph *g =
        @truetype_ReadGlyphByIndex(ttf, offset, T(ch == ' ', 1, 0));
    g->SourceCharacter = ch;
    g->SourceFont = ttf->_filename;
    @truetype_glyphCacheListAdd(ttf->_glyphCache, offset, g);
  }
  return @truetype_GlyphCacheGetKey(ttf, offset)->glyph;
}

I64 @truetype_FindX1(CDC *dc) {
  I64 x = 0;
  I64 y = 0;
  while (x < dc->width) {
    y = 0;
    while (y < dc->height) {
      if (GrPeek(dc, x, y) != TRANSPARENT) {
        return x;
      }
      y++;
    }
    x++;
  }
  return -1;
}
I64 @truetype_FindX2(CDC *dc) {
  I64 x = dc->width - 1;
  I64 y = dc->height - 1;
  while (x > -1) {
    y = dc->height - 1;
    while (y > -1) {
      if (GrPeek(dc, x, y) != TRANSPARENT) {
        return x;
      }
      y--;
    }
    x--;
  }
  return -1;
}

I64 @truetype_FindY2(CDC *dc) {

  I64 x = dc->width - 1;
  I64 y = dc->height - 1;
  while (y > -1) {
    x = dc->width - 1;
    while (x > -1) {
      if (GrPeek(dc, x, y) != TRANSPARENT) {
        return y;
      }
      x--;
    }
    y--;
  }
  return -1;
}

U0 @truetype_RenderGlyph(@truetype_Glyph *g) {
  I64 xofs = 128;
  I64 yofs = 128;

  F64 xx = 0, yy = 0;
  F64 fx = 0, fy = 0;

  I64 scale = 5;
  if (!g->Points) {
    return;
  };

  Bool first = TRUE;
  CDC *dc = DCNew(512, 512);
  CDC *dc2 = DCNew(512, 512);

  DCFill(dc);
  DCFill(dc2);
  dc->color = BLACK;

  I64 p = 0;
  @truetype_End *ends = g->ContourEnds->next;
  @truetype_GlyphPoint *point = g->Points->next;

  while (point) {
    if (first) {
      xx = ToI64(point->X / scale);
      yy = ToI64(point->Y / scale);
      fx = xx;
      fy = yy;
      first = FALSE;
    } else {
      GrLine(dc, xx + xofs, yy + yofs, ToI64(point->X / scale) + xofs,
             ToI64(point->Y / scale) + yofs);
      xx = ToI64(point->X / scale);
      yy = ToI64(point->Y / scale);
    }

    if (p == ends->value) {
      GrLine(dc, xx + xofs, yy + yofs, fx + xofs, fy + yofs);
      ends = ends->next;
      first = TRUE;
    }
    p++;
    point = point->next;
  }

  GrBlot(dc2, 0, 0, dc);

  dc->color = 1;
  GrFloodFill(dc, 0, 0);
  DCColorChg(dc, TRANSPARENT, 0);

  dc2->color = 0;
  GrFloodFill(dc2, 0, 0);
  dc2->color = TRANSPARENT;
  GrFloodFill(dc2, 0, 0);
  dc2->color = 0;
  GrFloodFill(dc2, 0, 0);

  DCColorChg(dc2, TRANSPARENT, 1);
  DCColorChg(dc2, 0, TRANSPARENT);
  GrBlot(dc, 0, 0, dc2);
  DCDel(dc2);
  DCColorChg(dc, 1, TRANSPARENT);

  g->dc = DCExt(dc, @truetype_FindX1(dc), 0, @truetype_FindX2(dc) + 8, 512);
  DCDel(dc);
}

I64 @truetype_DrawGlyph(Context2D *ctx, I64 x, I64 y, F64 size, U32 color,
                        U32 bgcolor, @truetype_Glyph *g, Bool draw = TRUE) {
  I64 xx, yy, width;
  if (!g->dc) {
    @truetype_RenderGlyph(g);
    if (!draw)
      return NULL;
  }
  Context2D *glyph_ctx = NewContext2D(g->dc->width, g->dc->height);
  //"w: %d, h: %d\n", g->dc->width, g->dc->height;
  Fill2D(glyph_ctx, bgcolor);
  for (yy = g->dc->height - 1; yy > -1; yy--) {
    for (xx = 0; xx < glyph_ctx->width; xx++) {
      if (!GrPeek(g->dc, xx, yy))
        Plot2D(glyph_ctx, xx, g->dc->height - yy, color);
    }
  }
  Context2D *blur_ctx = FastBoxBlur2D(glyph_ctx, 24);
  DelContext2D(glyph_ctx);
  Context2D *scale_ctx = Scale2D(blur_ctx, size, size);
  Free(blur_ctx->fb);
  // DelContext2D(blur_ctx); // FIXME: Why are we getting bad free here?!?
  if (draw)
    Blot2D(ctx, x, y, scale_ctx);
  width = X2Pos2D(scale_ctx) - X1Pos2D(scale_ctx);
  DelContext2D(scale_ctx);
  return width;
}

I64 @truetype_RenderText2D(Context2D *ctx, I64 x, I64 y, F64 size = 0.045,
                           I64 space = 2, @truetype_TrueTypeFont *ttf,
                           U8 *@truetype_name, U8 *text, U32 color, U32 bgcolor,
                           Bool draw = TRUE) {
  I64 ox = x;
  I64 oy = y;
  while (ttf) {
    if (!StrCmp(ttf->_filename, @truetype_name)) {
      break;
    }
    ttf = ttf->next;
  }
  if (!ttf) {
    return FALSE;
  }
  @truetype_Glyph *g;
  I64 i, width;
  for (i = 0; i < StrLen(text); i++) {
    if (text[i] == ' ') {
      g = @truetype_ReadGlyph(ttf, 't');
      width = @truetype_DrawGlyph(ctx, x, y, size, color, bgcolor, g, FALSE);
      x += width + space;
    } else {
      g = @truetype_ReadGlyph(ttf, text[i]);
      width = @truetype_DrawGlyph(ctx, x, y, size, color, bgcolor, g, draw);
      x += width + space;
    }
  }
  return (x - ox) - space;
}

Context2D *@truetype_TextRect2D(I64 w, F64 size = 0.045, I64 space = 2,
                                @truetype_TrueTypeFont *ttf, U8 *@truetype_name,
                                U8 *text, U32 color = Color(0, 0, 0),
                                U32 bgcolor = Color(204, 204, 204)) {
  I64 x_offset = 0;
  I64 y_offset = 0;
  I64 x1, y1, x2, y2;

  Context2D *ctx = NewContext2D(w, 256);
  Context2D *rect = NULL;

  Fill2D(ctx, 0);
  @truetype_RenderText2D(ctx, x_offset, y_offset, size, space, ttf,
                         @truetype_name, "Iy", color, bgcolor);
  y1 = Y1Pos2D(ctx) - 4;
  y2 = Y2Pos2D(ctx) + 4;

  Fill2D(ctx, 0);
  @truetype_RenderText2D(ctx, x_offset, y_offset, size, space, ttf,
                         @truetype_name, text, color, bgcolor);
  x1 = X1Pos2D(ctx);
  x2 = X2Pos2D(ctx) + 4;

  rect = NewContext2D(x2 - x1, y2 - y1);
  Fill2D(rect, bgcolor);
  Blot2D(rect, -x1, -y1, ctx);
  DelContext2D(ctx);
  return rect;
}

@truetype_TrueTypeFont *truetype_fonts = CAlloc(sizeof(@truetype_TrueTypeFont));

F64 @truetype_point_to_size(I64 size) {
  F64 ttf_point_to_size;
  switch (size) {
  case 10:
    ttf_point_to_size = 0.03;
    break;
  case 12:
    ttf_point_to_size = 0.04;
    break;
  case 14:
    ttf_point_to_size = 0.046;
    break;
  case 18:
    ttf_point_to_size = 0.056;
    break;
  case 24:
    ttf_point_to_size = 0.076;
    break;
  case 36:
    ttf_point_to_size = 0.096;
    break;
  default:
    ttf_point_to_size = 0.046; // default 14pt
    break;
  }
  return ttf_point_to_size;
}

U0 @truetype_load_ttf(U8 *filename) {
  if (!FileFind(filename)) {
    return;
  }
  @truetype_TrueTypeFont *fonts = truetype_fonts;
  while (fonts->next) {
    fonts = fonts->next;
  }
  @truetype_TrueTypeFont *new = TrueTypeFont(filename);
  fonts->next = new;
}

@truetype_load_ttf("T:/Fonts/Times.ttf");
@truetype_load_ttf("T:/Fonts/TimesBold.ttf");
@truetype_load_ttf("T:/Fonts/JosefinSans.ttf");
@truetype_load_ttf("T:/Fonts/AlatsiRegular.ttf");
@truetype_load_ttf("T:/Fonts/CalistogaRegular.ttf");
@truetype_load_ttf("T:/Fonts/PermanentMarker.ttf");

"truetype ";