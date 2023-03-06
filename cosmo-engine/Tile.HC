extern U8 *load_file(U8 *filename, U8 *buf, U32 buf_size);
extern Bool open_file(U8 *filename, File *file);

// Tiletype
#define SOLID           0
#define TRANSPARENT     1
#define FONT            2

// TileAttr
#define BLOCK_DOWN      0x1
#define BLOCK_UP        0x2
#define BLOCK_LEFT      0x4
#define BLOCK_RIGHT     0x8
#define SLIPPERY        0x10
#define IN_FRONT        0x20
#define SLOPED          0x40
#define CAN_GRAB_WALL   0x80

class Tile {
    I64 type;
    U8 pixels[64];
};

class TileInfo {
    U16 height;
    U16 width;
    U16 tile_num;
};

class Sprite {
    U16 num_frames;
    TileInfo *frames;
};

#define TILE_ATTR_BLOCK_DOWN      0x1
#define TILE_ATTR_BLOCK_UP        0x2
#define TILE_ATTR_BLOCK_LEFT      0x4
#define TILE_ATTR_BLOCK_RIGHT     0x8
#define TILE_ATTR_SLIPPERY       0x10
#define TILE_ATTR_IN_FRONT       0x20
#define TILE_ATTR_SLOPED         0x40
#define TILE_ATTR_CAN_GRAB_WALL  0x80

#define TILE_HEIGHT 8
#define TILE_WIDTH 8

#define TRANSPARENT_COLOR 255

U8 tileattr_mni_data[7000];

U0 tile_attr_load()
{
    load_file("TILEATTR.MNI", &tileattr_mni_data, 7000);
}
U8 get_tile_size(I64 type)
{
    return Cond(type == SOLID, 32, 40);
}
U16 get_number_of_tiles(File *file, I64 type)
{
    U8 tile_size = get_tile_size(type);

    U16 num_tiles = 0;
    U32 filesize = file->size;
    while(filesize > 0xffff)
    {
        num_tiles += 0xffff / tile_size;
        filesize -= 0xffff;
    }

    if(filesize > 0)
    {
        num_tiles += filesize / tile_size;
    }

    return num_tiles;
}

U8 getPixelAtColumnPosition(U8 *rowPtr, U8 column, I64 tileType)
{
    U8 color = 0;

    if (tileType == TRANSPARENT) {
        if (*rowPtr & (1 << (7 - column))) {
            return TRANSPARENT_COLOR;
        }
        rowPtr++;
    }

    if (tileType == FONT) //Font tiles have an inverted mask layer.
    {
        if ((*rowPtr & (1 << (7 - column))) == 0) {
            return TRANSPARENT_COLOR;
        }
        rowPtr++;
    }

    I64 i;
    for (i = 0; i < 4; i++, rowPtr++) {

        color |= (((*rowPtr >> (7 - column)) & 1) << (i));
    }

    return color;
}

U0 load_tile(U8 *planarData, I64 type, Tile *tile)
{
    tile->type = type;
    U8 *pixelPtr = tile->pixels;
    U8 x,y;
    for(y=0;y<TILE_HEIGHT;y++) {
        for(x=0;x<TILE_WIDTH;x++) {
            *pixelPtr = getPixelAtColumnPosition(planarData, x, type);
            pixelPtr++;
        }
        planarData += Cond(type == SOLID, 4, 5);
    }
}

Tile *load_tiles(U8 *filename, I64 type, U16 *num_tiles_loaded) {
    U8 planarData[40];

    File file;
    if(!open_file(filename, &file))
    {
        "Error: opening %s\n", filename;
        return NULL;
    }

    U8 tile_size = get_tile_size(type);

    U16 num_tiles = get_number_of_tiles(&file, type);
    Tile *tiles = MAlloc(sizeof(Tile) * num_tiles);

    I64 i;

    for(i=0;i<num_tiles;i++)
    {
        if(i != 0 && i % (0xffff / tile_size) == 0)
        {
            file_seek(&file, file.pos + (0xffff % tile_size)); //skip the last (unused) bytes from the block.
        }
        file_read_to_buffer(&file, planarData, tile_size);
        load_tile(planarData, type, &tiles[i]);
    }

    *num_tiles_loaded = num_tiles;
    file_close(&file);
    return tiles;
}

U16 get_number_of_sprite_frames(U16 current_frame_num, U16 offset, U16 num_total_sprites, File *file)
{
    U16 next_offset = (file->size / 2);
    if(current_frame_num < num_total_sprites - 1)
    {
        next_offset = file_read2(file);
    }

    return ((next_offset - offset) / 4);
}

Sprite *load_tile_info(U8 *filename, U16 *num_records_loaded)
{
    File file;
    if(!open_file(filename, &file))
    {
        "Error: opening tileinfo file %s\n", filename;
        return NULL;
    }

    *num_records_loaded = file_read2(&file);
    Sprite *sprites = MAlloc(*num_records_loaded * sizeof(Sprite));

    U16 sprite_index;
    I64 j, frame_num;

    for(sprite_index=0;sprite_index < *num_records_loaded; sprite_index++)
    {
        sprites[sprite_index].num_frames = 0;
        for(j=sprite_index; sprites[sprite_index].num_frames == 0 && j < *num_records_loaded; j++) //advance through the sprite info offsets until we find some frames
        {
            file_seek(&file, j * 2);
            sprites[sprite_index].num_frames = 0;

            U16 offset = file_read2(&file);
            sprites[sprite_index].num_frames = get_number_of_sprite_frames(j, offset, *num_records_loaded, &file);

            if (sprites[sprite_index].num_frames != 0)
            {
                file_seek(&file, offset * 2);

                sprites[sprite_index].frames = MAlloc(sprites[sprite_index].num_frames * sizeof(TileInfo));

                for (frame_num = 0; frame_num < sprites[sprite_index].num_frames; frame_num++)
                {
                    sprites[sprite_index].frames[frame_num].height = file_read2(&file);
                    sprites[sprite_index].frames[frame_num].width = file_read2(&file);
                    U32 frameOffset = file_read4(&file);
                    sprites[sprite_index].frames[frame_num].tile_num = ((frameOffset >> 16) * 1638 + (frameOffset & 0xffff) / 40);
                }
            }
        }
    }

    file_close(&file);

    return sprites;
}
