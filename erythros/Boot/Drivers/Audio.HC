extern U0 (*fp_snd_fill_buf)(U32 *buf, I64 buf_num);

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
  U0 (*Beep)();
  U0 (*Init)();
  U0 (*MixOutput)(U64 buf, I64);
  Sound (*SoundFromFile)(U8 * filename);
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
  if (HashFind("fp_snd_fill_buf", adam_task->hash_table, HTT_GLBL_VAR)) {
#exe {
    StreamPrint("fp_snd_fill_buf = Audio.MixOutput;\n");
  }
}
Audio.mixer.left = 12;
Audio.mixer.right = 12;
Audio.wavegen.duration = 0.0;
Audio.wavegen.frequency = 0;
Audio.device.enabled = TRUE;
}

Audio.driver = NULL;
Audio.Init = &@audio_init;
Audio.MixOutput = &@audio_mix_output;

"audio ";