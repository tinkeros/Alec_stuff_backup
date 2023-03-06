extern U8 *load_file_in_new_buf(U8 *filename, U32 *file_size);

#define MUSIC_INSTRUCTION_RATE 560 //Hz
#define ADLIB_OP_SIZE 4

//Data
I64 music_index = -1;

U8 *music_data;
U32 music_data_length;

U32 adlib_instruction_position = 0;
U32 delay_counter = 0;

U8 music_on_flag = 1;

U8 music_filename_tbl[19][13] = {
        "MCAVES.MNI",
        "MSCARRY.MNI",
        "MBOSS.MNI",
        "MRUNAWAY.MNI",
        "MCIRCUS.MNI",
        "MTEKWRD.MNI",
        "MEASYLEV.MNI",
        "MROCKIT.MNI",
        "MHAPPY.MNI",
        "MDEVO.MNI",
        "MDADODA.MNI",
        "MBELLS.MNI",
        "MDRUMS.MNI",
        "MBANJO.MNI",
        "MEASY2.MNI",
        "MTECK2.MNI",
        "MTECK3.MNI",
        "MTECK4.MNI",
        "MZZTOP.MNI"
};

//Get delay between adlib commands. Measured in audio samples.
U32 get_delay(U32 instruction_num)
{
    return (SND_SAMPLE_RATE / MUSIC_INSTRUCTION_RATE) * (music_data[instruction_num*ADLIB_OP_SIZE+2] + (music_data[instruction_num*ADLIB_OP_SIZE+3] << 8));
}

hd_buf = MAlloc(4096);

U0 music_callback(SND_OUT_CONTAINER *buf,I64)
{
    U8 *stream = buf;
    I64 num_samples = SND_BUF_LEN;
    U8 is_stereo = Cond(SND_OCHANNELS == 2, 1, 0);
    I64 i;

    for(i=num_samples;i > 0;)
    {
        if(delay_counter == 0)
        {
            adlib_write(music_data[adlib_instruction_position*ADLIB_OP_SIZE], music_data[adlib_instruction_position*ADLIB_OP_SIZE+1]);
            delay_counter = get_delay(adlib_instruction_position);
            adlib_instruction_position++;
            if(adlib_instruction_position * ADLIB_OP_SIZE >= music_data_length)
            {
                adlib_instruction_position = 0;
            }
        }
        if(delay_counter > i)
        {
            delay_counter -= i;
            adlib_getsample(stream, i, is_stereo);
            //mix_sfx(stream, i);
            mix_sfx(buf);
            return;
        }
        if(delay_counter <= i)
        {
            i -= delay_counter;
            adlib_getsample(stream, delay_counter, is_stereo);
            //mix_sfx(stream, delay_counter);
            stream += delay_counter * SND_OCHANNELS * SND_SAMPLE_BITS/8;
            delay_counter = 0;
        }
    }

    mix_sfx(buf);

}

U0 play_music()
{
    fp_snd_fill_buf=&music_callback;
}

U0 stop_music()
{
    fp_snd_fill_buf=&sfx_callback;
}

U0 load_music(U16 new_music_index)
{
    adlib_instruction_position = 0;
    delay_counter = 0;

    if(music_index == new_music_index)
    {
        play_music();
        return;
    }

    if(music_index != -1)
    {
        Free(music_data);
    }

    music_index = new_music_index;
    music_data = load_file_in_new_buf(music_filename_tbl[music_index], &music_data_length);

    play_music();
}

U0 music_init()
{
    adlib_init(SND_SAMPLE_RATE);
}
 