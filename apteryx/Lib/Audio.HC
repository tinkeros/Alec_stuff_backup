#define AUDIO_MAX_STREAMS 16

#define AUDIO_OUTPUT_BUFFER_SIZE 1024

#define AUDIO_STREAM_FIFO_SIZE 1048576
#define AUDIO_STREAM_TYPE_INPUT 0
#define AUDIO_STREAM_TYPE_OUTPUT 1

class Sound {
  // For simplicity, all samples will be converted to 44100 Hz, 2 channels, 16
  // bit when they are loaded.
  I64 rate;
  I64 channels;
  I64 bits;
  U32 *data;
  I64 length; // in samples
};

class @audio_device {
  Bool enabled;
};

class @audio_mixer {
  I64 left;
  I64 right;
};

class @audio_stream {
  I64 type;
  I64 rate;
  I64 channels;
  I64 bits;
  CFifoI64 *data;
};

class @audio_wave_generator {
  F64 duration;
  I64 frequency;
};

class @audio {
  I64 driver;
  @audio_device device;
  @audio_mixer mixer;
  @audio_stream output[AUDIO_MAX_STREAMS + 1];
  @audio_wave_generator wavegen;
  U0 (*Init)();
  U0 (*MixOutput)(U64 buf, I64);
  U0 (*FreeSound)(Sound * snd);
  I64 (*PlaySound)(Sound * snd);
};

@audio Audio;

U0 @audio_mix_output(U32 *buf, I64) {
  I64 i;
  I64 j;
  I64 acc_sample_L = 0;
  I64 acc_sample_R = 0;
  I64 acc_streams = 0;
  U32 sample;
  for (i = 0; i < AUDIO_OUTPUT_BUFFER_SIZE; i++) {
    acc_sample_L = 0;
    acc_sample_R = 0;
    acc_streams = 0;
    if (Audio.wavegen.frequency) {
      sample.i16[0] =
          T(Sin(Audio.wavegen.frequency * Audio.wavegen.duration) >= 0.0,
            I16_MAX / 8, I16_MIN / 8);
      sample.i16[1] = sample.i16[0];
      FifoI64Ins(Audio.output[AUDIO_MAX_STREAMS].data, sample);
      Audio.wavegen.duration += 6.4 / 48000.0;
    }
    for (j = 0; j < AUDIO_MAX_STREAMS + 1; j++) {
      if (FifoI64Cnt(Audio.output[j].data)) {
        FifoI64Rem(Audio.output[j].data, &sample);
        acc_streams++;
        acc_sample_L += sample.i16[0];
        acc_sample_R += sample.i16[1];
      }
    }
    buf[i].i16[0] =
        ToI64(acc_sample_L / Sqrt(acc_streams) * Audio.mixer.left / 100);
    buf[i].i16[1] =
        ToI64(acc_sample_R / Sqrt(acc_streams) * Audio.mixer.right / 100);
  }
}

U0 @audio_init() {
  I64 i = 0;
  for (i = 0; i < AUDIO_MAX_STREAMS + 1; i++)
    Audio.output[i].data = FifoI64New(AUDIO_STREAM_FIFO_SIZE);
  Audio.mixer.left = 100;
  Audio.mixer.right = 100;
  Audio.wavegen.duration = 0.0;
  Audio.wavegen.frequency = 0;
  Audio.device.enabled = TRUE;
}

Audio.driver = NULL;
Audio.Init = &@audio_init;
Audio.MixOutput = &@audio_mix_output;

I64 @audio_get_available_output_stream() {
  I64 stream = 0;
  while (FifoI64Cnt(Audio.output[stream].data))
    stream++;
  if (stream > AUDIO_MAX_STREAMS - 1)
    return -1;
  return stream;
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

U32 *@audio_buffer_copy(U32 *buf, I64 size) {
  U32 *out = MAlloc(size);
  MemCpyU32(out, buf, size / 4);
  return out;
}

U0 @audio_snd(I8 ona = 0) { Audio.wavegen.frequency = Ona2Freq(ona); }

Audio.FreeSound = &@audio_free_sound;
Audio.PlaySound = &@audio_play_sound;

Function.Patch(&Snd, &@audio_snd);

Audio.Init();