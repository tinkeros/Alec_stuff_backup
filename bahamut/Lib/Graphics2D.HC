class Context2D
{
I64 width;
I64 height;
I64 bpp;
I64 alpha_color;
U8 *fb;
};

Context2D *NewContext2D(I64 width, I64 height, I64 bpp=display.bpp)
{ //Create new Context2D.
	switch (bpp)
	{
	case 32:
	case 24:
		break;
	default:
		return NULL;
		break;
	}
	Context2D *ctx = CAlloc(sizeof(Context2D));
	ctx->width = width;
	ctx->height = height;
	ctx->bpp = bpp;
	ctx->alpha_color = 0x00FF0000;
	ctx->fb = CAlloc((width*height)*bpp/8);
	return ctx;
}

U0 DelContext2D(Context2D *ctx)
{
	if (!ctx)
	{
		return;
	}
	Free(ctx->fb);
	Free(ctx);
}

U0 Fill2D(Context2D *ctx, U32 color=U32_MAX)
{ //Fill a Context2D with color.
	if (color==U32_MAX) color=ctx->alpha_color;
	U64 i = ctx->fb;
	I64 pos = 0;
	while (pos<(ctx->width*ctx->height)*ctx->bpp/8)
	{
		(i+pos)(U8*)[0]=color.u8[1];
		(i+pos)(U8*)[1]=color.u8[2];
		(i+pos)(U8*)[2]=color.u8[3];
		switch (ctx->bpp)
		{
		case 32:
			pos+=4;
			break;
		case 24:
			pos+=3;
			break;
		default:
			break;
		}
	}
}

U32 Peek2D(Context2D *ctx, I64 x, I64 y)
{ //Return RGB value for pixel.
	U32 color=0;
	if (x<0 || x>ctx->width-1 || y<0 || y>ctx->height-1)
	{
		return 0xFFFFFFFF;
	}
	U64 i = ctx->fb;
	I64 pos = (ctx->width*y)*(ctx->bpp/8);
	pos += x*(ctx->bpp/8);
	color.u8[1]=(i+pos)(U8*)[0];
	color.u8[2]=(i+pos)(U8*)[1];
	color.u8[3]=(i+pos)(U8*)[2];
	return color;
}

U0 Plot2D(Context2D *ctx, I64 x, I64 y, U32 color)
{ //Plot a pixel.
	if (x<0 || x>ctx->width-1 || y<0 || y>ctx->height-1)
	{
		return;
	}
	U64 i = ctx->fb;
	I64 pos = (ctx->width*y)*(ctx->bpp/8);
	pos += x*(ctx->bpp/8);
	(i+pos)(U8*)[0]=color.u8[1];
	(i+pos)(U8*)[1]=color.u8[2];
	(i+pos)(U8*)[2]=color.u8[3];
}

U0 HLine2D(Context2D *ctx, I64 x, I64 y, I64 x2, U32 color)
{ //Draw a horizontal line.
	if (x2<x)
	{
		return;
	}
	while (x<x2+1)
	{
		Plot2D(ctx, x, y, color);
		x++;
	}
}

U0 VLine2D(Context2D *ctx, I64 x, I64 y, I64 y2, U32 color)
{ //Draw a vertical line.
	if (y2<y)
	{
		return;
	}
	while (y<y2+1)
	{
		Plot2D(ctx, x, y, color);
		y++;
	}
}

U0 Blot2D(Context2D *dst, I64 x, I64 y, Context2D *src, U32 color=NULL)
{
	if (src==NULL || dst==NULL)
	{
		return;
	}
	U8 *chk_alpha_ptr;
	U32 chk_alpha;
	U64 i=dst->fb;
	U64 j=src->fb;
	I64 xx,yy;
	I64 dx,sx;
	i+=(x*dst->bpp/8)+((dst->width*y)*dst->bpp/8);
	for (yy=0; yy<src->height; yy++)
	{
		dx=0;
		sx=0;
		for (xx=0; xx<src->width; xx++)
		{
			chk_alpha_ptr=j+dx+((src->width*yy)*src->bpp/8);
			chk_alpha=0;
			chk_alpha.u8[1]=chk_alpha_ptr[0];
			chk_alpha.u8[2]=chk_alpha_ptr[1];
			chk_alpha.u8[3]=chk_alpha_ptr[2];

			if ((chk_alpha!=src->alpha_color || src->alpha_color==-1) &&
			    x+xx>-1 && y+yy>-1 &&
			    x+xx<dst->width && y+yy<dst->height)
			{
				if (!color)
				{
					MemCpy(i+sx+((dst->width*yy)*dst->bpp/8), j+dx+((src->width*yy)*src->bpp/8), 3);
				}
				else
				{
					MemSet(i+sx+((dst->width*yy)*dst->bpp/8), color.u8[1], 1);
					MemSet(i+sx+((dst->width*yy)*dst->bpp/8)+1, color.u8[2], 1);
					MemSet(i+sx+((dst->width*yy)*dst->bpp/8)+2, color.u8[3], 1);					
				}
			}
			switch (dst->bpp)
			{
			case 32:
				dx+=4;
				break;
			case 24:
				dx+=3;
				break;
			default:
				break;
			}
			switch (src->bpp)
			{
			case 32:
				sx+=4;
				break;
			case 24:
				sx+=3;
				break;
			default:
				break;
			}
		}
	}
}

U0 CopyRect2D(Context2D *ctx, I64 x, I64 y, Context2D *rect)
{//Copy rect with clipping.

  U8 *ctx_pos=ctx->fb;
  U8 *rect_pos=rect->fb;
  I64 rect_row=0;  
  I64 rect_y_ofs=0;
  I64 rect_x_ofs=0;
  I64 clip_y=0;
  U8 *rect_line;

  //Handle horizontal clipping left
  while (x<0) { rect_x_ofs++; x++; }

  //Handle vertical clipping top
  while (y<0)
  {
    rect_pos+=(rect->width)*(display.bpp/8);
    rect_y_ofs++; y++;
  }

  // default, clip line to copy as width-left off screen
  rect_line=rect->width-rect_x_ofs;

  if (-rect_x_ofs+x+rect->width>=ctx->width)
  {
    rect_line-=((-rect_x_ofs+x+rect->width)-ctx->width);
  }  

  rect_pos+=(rect_x_ofs)*(display.bpp/8);
  clip_y = y;
  while (rect_row<(rect->height-rect_y_ofs) && clip_y<ctx->height) 
  {    
    MemCpy(ctx_pos+(y*((ctx->width)*(display.bpp/8)))+x*(display.bpp/8),rect_pos,(rect_line)*(display.bpp/8));
    ctx_pos+=(ctx->width)*(display.bpp/8);
    rect_pos+=(rect->width)*(display.bpp/8);
	clip_y++;
    rect_row++;
  }
}

U0 Rect2D(Context2D *ctx, I64 x, I64 y, I64 w, I64 h, U32 color)
{ //Draw a rectangle fill.
	Context2D *tmpctx=NewContext2D(Max(4, w), Max(4, h), display.bpp);
	Fill2D(tmpctx, color);
	//Blot2D(ctx, x, y, tmpctx);
	CopyRect2D(ctx, x, y, tmpctx);
	DelContext2D(tmpctx);
}

Context2D *sys_fb = CAlloc(sizeof(Context2D));

U0 SysFrameBufferInit()
{ //Init values for Context2D alias to system framebuffer.
	sys_fb->width = display.width;
	sys_fb->height = display.height;
	sys_fb->bpp = display.bpp;
	sys_fb->alpha_color = -1;
	sys_fb->fb = svga.fb;
}

U0 Flip2D(Context2D *ctx)
{
	MemCpy(sys_fb->fb, ctx->fb, (display.width*display.height)*display.bpp/8);
}