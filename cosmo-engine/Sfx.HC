#define MAX_SAMPLES_PER_FILE 23 //the game only reads the first 23 sfx in each file.
#define SFX_SAMPLE_RATE 140
#define PC_PIT_RATE 1193181
#define WAVE_AMPLITUDE_VALUE 3500

class Mix_Chunk {
    I64 allocated;
    U8 *abuf;
    U32 alen;
    U8 volume;     /* Per-sample volume, 0-128 */
};

class Sfx {
    U8 priority;
    Mix_Chunk *sample;
};

Sfx *sfxs;
I64 num_sfx = 0;
I64 currently_playing_priority=0;
U8 sfx_on_flag = 1;
U32 sfx_pos = 0;
I64 sfx_num = -1;

U0 mix_sfx(U32 *buf)
{
    I64 i;
    I64 j;
    Mix_Chunk *sample;
    U32 *raw;
    
    if (sfx_num < 0) return;

    sample = sfxs[sfx_num-1].sample;
    j = Min(SND_BUF_LEN * 4, sample->alen - sfx_pos);
    j /= 4;

    raw = sample->abuf + sfx_pos;

    for (i=0;i<j;i++)
    {
        buf[i] += raw[i];
    }
    sfx_pos += j * 4;
    if (sfx_pos >= sample->alen)
    {
        sfx_pos = 0;
        sfx_num = -1;
        currently_playing_priority=0;
    }

}

U0 sfx_callback(SND_OUT_CONTAINER *buf,I64)
{
    I64 i;
    for (i=0;i<SND_BUF_LEN;i++)
    {
        buf[i]=0;
    }
    mix_sfx(buf);
}

I64 get_num_sfx(U8 *filename)
{
    File file;
    open_file(filename, &file);
    file_seek(&file, 6);
    I64 count = file_read2(&file);
    file_close(&file);
    return count;
}

I64 get_num_samples(File *file, I64 offset, I64 index, I64 total)
{
    if(index < total - 1)
    {
        file_seek(file, (index+2)*16);
        I64 next_offset = file_read2(file);
        return ((next_offset - offset) / 2) - 1;
    }

    return ((file_get_filesize(file) - offset) / 2) - 1;
}

U0 writeSample(U8 *buf, U16 index, I16 sample) {
        (buf + index * SND_OCHANNELS * SND_SAMPLE_BITS/8)(U16*)[0] = sample;
        if (SND_OCHANNELS == 2) {
            (buf + index * SND_OCHANNELS * SND_SAMPLE_BITS/8 + SND_SAMPLE_BITS/8)(U16*)[0] = sample;
        }
}

Mix_Chunk *convert_sfx_to_wave(File *file, I64 offset, I64 num_samples)
{
    I64 sample_length = (SND_SAMPLE_RATE / SFX_SAMPLE_RATE);
    Mix_Chunk *chunk = MAlloc(sizeof(Mix_Chunk));
    chunk->alen = (num_samples * sample_length * SND_OCHANNELS * SND_SAMPLE_BITS/8);
    chunk->abuf = MAlloc(chunk->alen);
    chunk->allocated = 0;
    chunk->volume = 128;
    I64 i;
    I64 sampleCounter;

    file_seek(file, offset);

    I16 *wave_data = chunk->abuf;

    I16 beepWaveVal = WAVE_AMPLITUDE_VALUE;
//    sint16 velocity = -4;
//    sint16 desiredAmplitude = -WAVE_AMPLITUDE_VALUE;
    U16 beepHalfCycleCounter = 0;
    for(i=0; i < num_samples; i++)
    {
        U16 sample = file_read2(file);
        if (sample)
        {
            F64 freq = PC_PIT_RATE / ToF64(sample);
            I64 half_cycle_length = (SND_SAMPLE_RATE / (freq * 2));
            //printf("sample %d, freq=%f, half_cycle_len = %d\n", i, freq, half_cycle_length);
            for (sampleCounter = 0; sampleCounter < sample_length; sampleCounter++) {
                writeSample(chunk->abuf, i*sample_length+sampleCounter, beepWaveVal);

//                beepWaveVal += velocity;
//                if((velocity < 0 && beepWaveVal < desiredAmplitude) || (velocity > 0 && beepWaveVal > desiredAmplitude))
//                {
//                    beepWaveVal = desiredAmplitude;
//                    velocity = 0;
//                }
//                velocity *= 2;

                beepHalfCycleCounter++;
                if (beepHalfCycleCounter >= half_cycle_length) {
                    beepHalfCycleCounter = Cond(half_cycle_length != 0, (beepHalfCycleCounter % half_cycle_length), 0);
                    beepWaveVal = -beepWaveVal;
//                    desiredAmplitude = -desiredAmplitude;
//                    if(desiredAmplitude < 0)
//                    {
//                        velocity = -4;
//                    }
//                    else
//                    {
//                        velocity = 4;
//                    }
                }
            }
        }
        else
        {
            MemSet(&wave_data[i*sample_length*SND_OCHANNELS], 0, sample_length * SND_OCHANNELS * SND_SAMPLE_BITS/8); //silence
        }
    }

    return chunk;
}

I64 load_sfx_file(U8 *filename, I64 sfx_offset)
{
    File file;
    open_file(filename, &file);
    file_seek(&file, 6);
    I64 count = file_read2(&file);
    I64 i;
    I64 num_samples;
    I64 offset;
    Sfx *sfx;
    "%s, %d, %d\n", filename, count, sfx_offset;
    for(i=0; i < MAX_SAMPLES_PER_FILE; i++)
    {
        file_seek(&file, (i+1) * 16); //+1 to skip header.
        offset = file_read2(&file);
        sfx = &sfxs[sfx_offset + i];
        sfx->priority = file_read1(&file);
        num_samples = get_num_samples(&file, offset, i, count);
//        printf("sfx[%d] samples = %d\n", i+sfx_offset, num_samples);
        sfx->sample = convert_sfx_to_wave(&file, offset, num_samples);
    }
    return MAX_SAMPLES_PER_FILE;
}

U0 load_sfx()
{
    num_sfx = 0;
    num_sfx += get_num_sfx("SOUNDS.MNI");
    num_sfx += get_num_sfx("SOUNDS2.MNI");
    num_sfx += get_num_sfx("SOUNDS3.MNI");

    "Total Sfx %d\n", num_sfx;

    sfxs = MAlloc(sizeof(Sfx) * num_sfx);

    I64 sfx_offset = load_sfx_file("SOUNDS.MNI", 0);
    sfx_offset += load_sfx_file("SOUNDS2.MNI", sfx_offset);
    load_sfx_file("SOUNDS3.MNI", sfx_offset);
}

U0 play_sfx(I64 sfx_number)
{
    if(sfxs[sfx_number-1].priority < currently_playing_priority)
        return;
    currently_playing_priority = sfxs[sfx_number-1].priority;
    sfx_pos = 0;
    sfx_num = sfx_number;
}
