// WAV header spec information:
// https://web.archive.org/web/20140327141505/https://ccrma.stanford.edu/courses/422/projects/WaveFormat/
// http://www.topherlee.com/software/pcm-tut-wavformat.html

class @sound_file_wav_header {
  // RIFF Header
  U8 riff_header[4]; // Contains "RIFF"
  I32 wav_size; // Size of the wav portion of the file, which follows the first
                // 8 bytes. File size - 8
  U8 wave_header[4]; // Contains "WAVE"

  // Format Header
  U8 fmt_header[4];   // Contains "fmt " (includes trailing space)
  I32 fmt_chunk_size; // Should be 16 for PCM
  I16 audio_format;   // Should be 1 for PCM. 3 for IEEE Float
  I16 num_channels;
  I32 sample_rate;
  I32 byte_rate; // Number of bytes per second. sample_rate * num_channels *
                 // Bytes Per Sample
  I16 sample_alignment; // num_channels * Bytes Per Sample
  I16 bit_depth;        // Number of bits per sample

  // Data
  U8 data_header[4]; // Contains "data"
  I32 data_bytes; // Number of bytes in data. Number of samples * num_channels *
                  // sample byte size
  U8 bytes[0];    // Remainder of wave file is bytes
};

I64 @audio_get_available_output_stream() {
  I64 stream = 0;
  while (FifoI64Cnt(Audio.output[stream].data))
    stream++;
  if (stream > AUDIO_MAX_STREAMS - 1)
    return -1;
  return stream;
}

Bool @audio_buffer_is_wav(@sound_file_wav_header *wav, I64 size) {
  if (!MemCmp(&wav->riff_header, "RIFF", 4) &&
      !MemCmp(&wav->wave_header, "WAVE", 4))
    return TRUE;
  return FALSE;
}

U0 @audio_free_sound(Sound *snd) {
  if (!snd)
    return;
  if (snd->data)
    Free(snd->data);
  Free(snd);
}

I64 @audio_play_sound(Sound *snd) {
  I64 i;
  I64 stream = @audio_get_available_output_stream;
  if (stream < 0)
    return stream;
  if (!snd->data || !snd->length)
    return stream;
  for (i = 0; i < snd->length; i++)
    FifoI64Ins(Audio.output[stream].data, snd->data[i]);
  return stream;
}

Sound *@audio_sound_from_buffer(U32 *buf, I64 length) {
  if (!buf || !length)
    return NULL;
  Sound *snd = CAlloc(sizeof(Sound));
  snd->rate = 44100;
  snd->channels = 2;
  snd->bits = 16;
  snd->data = buf;
  snd->length = length;
  return snd;
}

U32 *@audio_buffer_mono_to_stereo(U16 *buf, I64 size) {
  U32 *out = CAlloc(size * 2);
  I64 i;
  for (i = 0; i < size / 2; i++) {
    out[i].u16[0] = buf[i];
    out[i].u16[1] = buf[i];
  }
  return out;
}

Sound *@audio_sound_from_file(U8 *filename) {
  if (!FileFind(filename))
    return NULL;
  I64 length = 0;
  U32 *buf = NULL;
  U32 *buf2 = NULL;
  I64 size = 0;
  U8 *data = FileRead(filename, &size);
  if (@audio_buffer_is_wav(data, size)) {
    @sound_file_wav_header *wav = data;
    if (wav->fmt_chunk_size == 16 && wav->audio_format == 1 &&
        wav->sample_rate == 48000) {
      switch (wav->num_channels) {
      case 1:
        buf2 = @audio_buffer_mono_to_stereo(&wav->bytes, wav->data_bytes);
        Free(buf);
        buf = buf2;
        length = wav->data_bytes / 2;
        break;
      case 2:
        buf = &wav->bytes;
        length = wav->data_bytes / 4;
        break;
      }
    }
  }
  return @audio_sound_from_buffer(buf, length);
}

U0 @audio_snd(I8 ona = 0) { Audio.wavegen.frequency = Ona2Freq(ona); }

Audio.SoundFromFile = &@audio_sound_from_file;
Audio.FreeSound = &@audio_free_sound;
Audio.PlaySound = &@audio_play_sound;

Sound *@snd_beep = Audio.SoundFromFile("T:/Media/Sounds/Beep.wav");

U0 @audio_beep() { Audio.PlaySound(@snd_beep); }

Audio.Beep = &@audio_beep;
Function.Patch(&Snd, &@audio_snd);

"audio ";