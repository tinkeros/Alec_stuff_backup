extern I64 frames;

Context2D *font_ctx = LoadPNG("font.png",,,2);
Context2D *font_ch = NewContext2D(16, 16, display.bpp);

U0 FontChar2D(Context2D *ctx, I64 ch, I64 x, I64 y)
{
    ch-=32;
    Fill2D(font_ch, font_ch->alpha_color);
    Blot2D(font_ch, -(16*(ch%8)), -(16*(ch/8)), font_ctx);
    Blot2D(ctx, x, y, font_ch);
}

U0 Font2D(Context2D *ctx, I64 x, I64 y, U8 *fmt,...)
{
	U8 *buf;
	if (argc)
	{
		buf=StrPrintJoin(NULL, fmt, argc, argv);
	}
	else
	{
		buf=StrNew(fmt);
	}
	U8 *str=buf;    
    while (*str)
    {
        FontChar2D(ctx, *str++, x, y);
        x += 16;
    }
    Free(buf);
}

U0 PrintPlot2D(Context2D *ctx, I64 x, I64 y, U32 color)
{
	U64 i = ctx->fb;
	I64 pos = (svga.width*y)*svga.bpp/8;
	pos += x*svga.bpp/8;
	(i+pos)(U8*)[0]=color.u8[1];
	(i+pos)(U8*)[1]=color.u8[2];
	(i+pos)(U8*)[2]=color.u8[3];
}

U0 PrintChar2D(Context2D *ctx, I64 x, I64 y, I64 ch, U32 fg=0xFFFFFF00, U32 bg=BLACK)
{
	U64 *char=sys_font_std;
	I64 xx,yy;
	I64 ii=0;
	for (yy=0; yy<8; yy++)
	{
		xx=0;
		for (xx=0; xx<8; xx++)
		{
			if (char[ch].u8[ii] & 1<<xx)
			{
				PrintPlot2D(ctx, x+xx, y+yy, fg);
			}
			else
			{
				PrintPlot2D(ctx, x+xx, y+yy, bg);
			}
		}
		ii++;
		if (ii>8)
		{
			ch++;
			ii=0;
		}
	}
}

U0 Print2D(Context2D *ctx, I64 x, I64 y, U32 fg=0xFFFFFFFF, U32 bg=0, U8 *fmt,...)
{
	U8 *buf;
	if (argc)
	{
		buf=StrPrintJoin(NULL, fmt, argc, argv);
	}
	else
	{
		buf=StrNew(fmt);
	}
	U8 *str=buf;    
    while (*str)
    {
        PrintChar2D(ctx, x, y, *str++, fg, bg);
        x += 8;
    }
    Free(buf);
}