CDC *SPR_Evilman;
CDC *SPR_Items;
CDC *SPR_Logo;
CDC *SPR_Megaman;
CDC *SPR_MegamanB;
CDC *SPR_Tiles;
CDC *SprClip;

CDC *IX_WND;
CDC *IX_BORDER;

U0 LoadSprites() {
	SPR_Evilman = GRRead("Graphics/Spr1");
	SPR_Items = GRRead("Graphics/Items");
	SPR_Logo = GRRead("Graphics/Logo");
	SPR_Megaman = GRRead("Graphics/Spr1");
	SPR_MegamanB = GRRead("Graphics/Spr2");
	SPR_Tiles = GRRead("Graphics/Tiles");
	IX_BORDER = DCExt(SPR_Items,506,13,542,45);
	IX_WND = DCExt(SPR_Items,72,18,96,44);
        DCFill(IX_WND,BLACK);
	DCColorChg(SPR_Evilman, BLUE, RED);
	DCColorChg(SPR_Evilman, LTCYAN, LTRED);
};

U0 FreeSprites() {
	DCDel(SPR_Evilman);
	DCDel(SPR_Items);
	DCDel(SPR_Logo);
	DCDel(SPR_Megaman);
	DCDel(SPR_MegamanB);
	DCDel(SPR_Tiles);
	DCDel(IX_WND);
	DCDel(IX_BORDER);
};

U0 MMSprite(CDC *SprDC, I64 InvSpr, I64 ScrOffsetX, I64 ScrOffsetY, I64 SprOffsetX, I64 SprOffsetY, I64 SprClipX, I64 SprClipY, I64 SprDir) {
	if (InvSpr==0) {
		SprClip = DCExt(SprDC, SprOffsetX, SprOffsetY, SprClipX, SprClipY);
		if (SprDir==0) { GrBlot(Buffer, ScrOffsetX, ScrOffsetY, SprClip); };
    	//if (SprDir==1) { GrBlotR(Buffer, ScrOffsetX, ScrOffsetY, SprClip); };
        if (SprDir==1)
        {
          CSprite *s=DC2Sprite(SprClip);
          Sprite3YB(Buffer, 96+ScrOffsetX, ScrOffsetY, 0, s, 179);
          Free(s);
        };

    	DCDel(SprClip);
    };
};
