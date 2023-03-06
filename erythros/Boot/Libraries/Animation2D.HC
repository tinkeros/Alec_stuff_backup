class AnimationContext2D {
  U64 signature;
  I64 duration;      // in jiffies
  I64 index;         // current frame
  I64 length;        // length in frames
  I64 timer;         // timer + cnts.jiffies = current ticks
  Context2D **frame; // Context2D*, ...
};

AnimationContext2D *@animation2d_new_from_frames(Context2D **frames, I64 length,
                                                 I64 duration = 250) {
  if (!frames || !length)
    return NULL;
  AnimationContext2D *actx = CAlloc(sizeof(AnimationContext2D));
  actx->signature = 'animated';
  actx->frame = frames;
  actx->length = length;
  actx->duration = duration;
  return actx;
}

Context2D *@animation2d_frame(AnimationContext2D *actx) {
  I64 ticks = cnts.jiffies;
  if (!actx)
    return NULL;
  if (!actx->length)
    return NULL;
  if (actx->index > actx->length - 1)
    actx->index = 0;
  if (!actx->index && !actx->timer)
    actx->timer = ticks;
  while (ticks >= actx->timer + actx->duration) {
    actx->timer += actx->duration;
    actx->index++;
    if (actx->index > actx->length - 1)
      actx->index = 0;
  }
  return actx->frame[actx->index];
}

Bool @animation2d_is_animation(AnimationContext2D *actx) {
  return T(actx->signature == 'animated', TRUE, FALSE);
}

U0 @animation2d_reset(AnimationContext2D *actx) { actx->index = 0; }

class @animation2d {
  Context2D *(*Frame)(AnimationContext2D * actx);
  U0 (*Reset)(AnimationContext2D * actx);
  Bool (*IsAnimation)(AnimationContext2D * actx);
  AnimationContext2D *(*NewFromFrames)(Context2D * *frames, I64 length,
                                       I64 duration = 250);
};

@animation2d Animation2D;
Animation2D.IsAnimation = &@animation2d_is_animation;
Animation2D.NewFromFrames = &@animation2d_new_from_frames;
Animation2D.Frame = &@animation2d_frame;
Animation2D.Reset = &@animation2d_reset;

"animation2d ";
