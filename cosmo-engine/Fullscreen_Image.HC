extern U0 video_draw_fullscreen_image(U8 *pixels);

U8 filename_ep1_tbl[6][13] = {
        "PRETITLE.MNI",
        "TITLE1.MNI",
        "CREDIT.MNI",
        "BONUS.MNI",
        "END1.MNI",
        "ONEMOMNT.MNI"
};
U8 filename_ep2_tbl[6][13] = {
        "PRETITLE.MNI",
        "TITLE2.MNI",
        "CREDIT.MNI",
        "BONUS.MNI",
        "END2.MNI",
        "ONEMOMNT.MNI"
};
U8 filename_ep3_tbl[6][13] = {
        "PRETITLE.MNI",
        "TITLE3.MNI",
        "CREDIT.MNI",
        "BONUS.MNI",
        "END3.MNI",
        "ONEMOMNT.MNI"
};

#define NUM_PIXELS (320 * 200)

U8 *get_filename(U8 image_number)
{
    switch(get_episode_number())
    {
        case 1 : return filename_ep1_tbl[image_number];
        case 2 : return filename_ep2_tbl[image_number];
        case 3 : return filename_ep3_tbl[image_number];
        default : break;
    }
    return NULL;
}

U8 *load_image(U8 *filename)
{
    U8 *pixels = MAlloc(320*200);
    I64 c, i, j;

    File image;
    if(!open_file(filename, &image)) {
		"failed to open %s\n", filename;
    }

    for(c=0;c<4;c++) {

        for (i = 0; i < NUM_PIXELS / 8; i++) {
            U8 data = file_read1(&image);
            for (j = 0; j < 8; j++) {
                if(c==0)
                {
                    pixels[i * 8 + j] = (data >> (7 - j)) & 1;
                }
                else
                {
                    pixels[i * 8 + j] |= ((data >> (7 - j)) & 1) << c;
                }
            }
        }
    }
    file_close(&image);

    return pixels;
}

U0 display_fullscreen_image(U8 image_number)
{
    //assert(image_number < 6);

    if(image_number != 1 && image_number != 2)
    {
        stop_music();
    }

    fade_to_black_speed_3();

    U8 *image = load_image(get_filename(image_number));
    video_draw_fullscreen_image(image);
    Free(image);

    fade_in_from_black_with_delay_3();

}
