Tile *cartoon_tiles;
Sprite *sprites;

U0 load_cartoon_images()
{
    U16 num_tile_info_records;
    U16 num_tiles;
    cartoon_tiles = load_tiles("CARTOON.MNI", TRANSPARENT, &num_tiles);
    "Loading %d cartoon tiles.\n", num_tiles;

    sprites = load_tile_info("CARTINFO.MNI", &num_tile_info_records);
    "Loading %d, cartoon tile info records.\n", num_tile_info_records;
}

U0 display_cartoon_sequence(U16 frame_num, U16 x_pos, U16 y_pos)
{
    TileInfo *info = &sprites[0].frames[frame_num];
    Tile *tile = &cartoon_tiles[info->tile_num];
    I64 x, y;

    for(y=0; y < info->height; y++)
    {
        for(x=0; x < info->width; x++)
        {
            video_draw_tile(tile, (x_pos + x) * 8, (y_pos + y - info->height + 1) * 8);
            tile++;
        }
    }
}