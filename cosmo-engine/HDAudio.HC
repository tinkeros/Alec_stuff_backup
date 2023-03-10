Bool audio_sync_begin = FALSE;

class AudioStream
{
    I64 rate;
    I64 channels;
    I64 bits;
    U32 *buf;
    I64 size;
};

U8 *Mem2MegAlloc(I64 *_pages2Meg,CBlkPool *bp=NULL)
{/*Alloc 2Meg pages from BlkPool. Don't link to task.
(Linking to a task means they will be freed when the task dies.)
It might give you more than you asked for
so a ptr to a page count is passed.

Return: NULL if out of memory.
*/
  I64 i,j,*pte,num=*_pages2Meg;
  CMemBlk *res=NULL,*m,*m1;

  if (!bp) bp=sys_code_bp;
  PUSHFD
  CLI
  while (LBts(&bp->locked_flags,BPlf_LOCKED))
    PAUSE
  num<<=21-MEM_PAG_BITS;

  m=&bp->mem_free_2meg_lst;
  while (TRUE) {
    if (!(res=m->next))
      break;
    if (res->pags<num)
      m=res;
    else {
      if (res->pags==num) {
	m->next=res->next;
	goto am_done;
      } else {
	res->pags-=num;
	res(U8 *)+=res->pags<<MEM_PAG_BITS;
	res->pags=num;
	goto am_done;
      }
    }
  }

  m=&bp->mem_free_lst;
  while (TRUE) {
    if (!(res=m->next)) {
      num=0;
      res=NULL; //Out of memory
      goto am_done;
    }
    if (res->pags<num)
      m=res;
    else {
      if (res->pags==num) {
	if (res(U8 *)&0x1FFFFF)
	  m=res;
	else {
	  m->next=res->next;
	  goto am_done;
	}
      } else {
	if (i=(res(U8 *)&0x1FFFFF)>>MEM_PAG_BITS) {
	  j=1<<(21-MEM_PAG_BITS)-i;
	  if (res->pags<num+j)
	    m=res;
	  else if (res->pags==num+j) {
	    res->pags-=num;
	    res(U8 *)+=res->pags<<MEM_PAG_BITS;
	    res->pags=num;
	    goto am_done;
	  } else {
	    m1=res;
	    res(U8 *)+=j<<MEM_PAG_BITS;
	    res->pags=num;
	    m=res(U8 *)+num<<MEM_PAG_BITS;
	    m->pags=m1->pags-num-j;
	    m1->pags=j;
	    m->next=m1->next;
	    m1->next=m;
	    m->mb_signature=MBS_UNUSED_SIGNATURE_VAL;
	    goto am_done;
	  }
	} else {
	  m=m->next=res(U8 *)+num<<MEM_PAG_BITS;
	  m->next=res->next;
	  m->pags=res->pags-num;
	  m->mb_signature=MBS_UNUSED_SIGNATURE_VAL;
	  res->pags=num;
	  goto am_done;
	}
      }
    }
  }
am_done:
  i=num<<MEM_PAG_BITS;
  bp->used_u8s+=i;
  num>>=21-MEM_PAG_BITS;
  *_pages2Meg=num;
  m=res;
  m1=m(U8 *)+i;
  while (m<m1) {
    pte=MemPageTable(m);
    *pte &= ~0x18;
    InvlPg(m);
    m(U8 *)+=0x200000;
  }
  LBtr(&bp->locked_flags,BPlf_LOCKED);
  POPFD
  return res;
}

U8 *Mem2MegUncachedAlloc(I64 *_pages2Meg,CBlkPool *bp=NULL)
{/*Alloc 2Meg pages from BlkPool. Don't link to task.
(Linking to a task means they will be freed when the task dies.)
It will be marked uncached. It might give you more than you asked for
so a ptr to a page count is passed.

Return: NULL if out of memory.
*/
  CMemBlk *res,*m,*m1;
  I64 num=*_pages2Meg,*pte;
  if (res=Mem2MegAlloc(_pages2Meg,bp)) {
    num=*_pages2Meg;
    m=res;
    m1=m(U8 *)+num<<21;
    while (m<m1) {
      pte=MemPageTable(m);
      *pte= *pte& ~0x18 |0x10;
      InvlPg(m);
      m(U8 *)+=0x200000;
    }
  }
  return res;
}

CHeapCtrl *HeapCtrlBPInit(CBlkPool *bp,I64 pags)
{//Make mem chunk into HeapCtrl and BlkPool.
  I64 num;
  CMemBlk *m;
  CHeapCtrl *hc;
  MemSet(bp,0,sizeof(CBlkPool)+sizeof(CHeapCtrl));
  hc=HeapCtrlInit(bp(U8 *)+sizeof(CBlkPool),,bp);
  m=(bp(U8 *)+sizeof(CBlkPool)+sizeof(CHeapCtrl)+MEM_PAG_SIZE-1)&
	~(MEM_PAG_SIZE-1);
  num=(bp(U8 *)+pags<<MEM_PAG_BITS-m(U8 *))>>MEM_PAG_BITS;
  bp->alloced_u8s=(pags-num)<<MEM_PAG_BITS;
  BlkPoolAdd(bp,m,num);
  return hc;
}

class CSndWaveCtrl
{
  I64 sample_rate,sample_bits,channels;
  F64 freq_multiplier,amp_multiplier;
  F64 phase,last_y,last_dydt,next_y;
};

#define WF_NULL                 0
#define WF_SQUARE               1
#define WF_SINE                 2
#define WF_TRI                  3
#define WF_SAWTOOTH             4
#define WF_NOISE                5
#define WF_WAVEFORMS_NUM        6

//snd devs
#define SD_PC_SPEAKER		0
#define SD_HD_AUDIO		1

#define SND_SAMPLE_RATE		48000
#define SND_SAMPLE_BITS		16
#define SND_OCHANNELS		2
#define SND_ICHANNELS		2
#define SND_OUT_CONTAINER	U32
#define SND_IN_CONTAINER	I16
#define SND_BUF_LEN		0x400
#define SND_BUF_TIME_mS		(SND_BUF_LEN/SND_OCHANNELS*1000.0/\
				SND_SAMPLE_RATE)

F64 snd_freq=0;
I64 snd_dev=SD_PC_SPEAKER;
Bool snd_record=FALSE;
F64 snd_vol=0.1;
U0 (*fp_snd)(F64 freq,I64 waveform,F64 amp)=NULL;
U0 (*fp_snd_record)(F64 freq,I64 waveform,F64 amp)=NULL;
U0 (*fp_snd_fill_buf)(SND_OUT_CONTAINER *buf,I64 buf_num)=NULL;
U0 (*fp_snd_copy_buf)(SND_IN_CONTAINER *buf,I64 buf_num)=NULL;

I64 snd_obuf_num,snd_ibuf_num;

#define Sf_FILLING_OUT		0
I64 snd_flags;

#define HD_1_CHAN	0
#define HD_2_CHAN	1
#define HD_3_CHAN	2
#define HD_4_CHAN	3

#define HD_8_BIT	0
#define HD_16_BIT	1
#define HD_20_BIT	2
#define HD_24_BIT	3
#define HD_32_BIT	4

#define HD_48kHz	0

#define HD_DFT_OUT_FMT	(HD_2_CHAN+HD_16_BIT<<4+HD_48kHz<<8)
#define HD_DFT_IN_FMT	(HD_2_CHAN+HD_16_BIT<<4+HD_48kHz<<8)

#define HD_POS_BUF_MULTIPLES	0x1000

#define HD_CORB_ENTRIES	256
#define HD_RIRB_ENTRIES	256
#define HD_BDL_ENTRIES	256

#define HD_GCTL		0x08
#define HD_STATESTS	0x0E
#define HD_GSTS		0x10
#define HD_CORBLBASE	0x40
#define HD_CORBUBASE	0x44
#define HD_CORBWP	0x48
#define HD_CORBRP	0x4A
#define HD_CORBCTL	0x4C
#define HD_CORBST	0x4D
#define HD_RIRBLBASE	0x50
#define HD_RIRBUBASE	0x54
#define HD_RIRBWP	0x58
#define HD_RIRBCTL	0x5C
#define HD_RIRBSTS	0x5D

#define STRCTL		0x00
#define STRSTS		0x03
#define STRLPIB		0x04
#define STRCBL		0x08
#define STRLVI		0x0C
#define STRFIFOW	0x0E
#define STRFIFOS	0x10
#define STRFMT		0x12
#define STRBDPL		0x18
#define STRBDPU		0x1C

#define ISTR0		0x080
#define ISTR1		0x0A0
#define ISTR2		0x0C0
#define ISTR3		0x0E0
#define OSTR0		0x100
#define OSTR1		0x120
#define OSTR2		0x140
#define OSTR3		0x160

#define VERB_GET_PARAM		0xF0000
#define VERB_CONNECT_SEL_GET	0xF0100
#define VERB_CONNECT_SEL_SET	0x70100
#define VERB_GET_CONNECT_LST	0xF0200
#define VERB_PROCESS_STATE_GET	0xF0300
#define VERB_PROCESS_STATE_SET	0x70300
#define VERB_COEFF_IDX_GET	0xD0000
#define VERB_COEFF_IDX_SET	0x50000
#define VERB_PROCESS_COEFF_GET	0xC0000
#define VERB_PROCESS_COEFF_SET	0x40000
#define VERB_AMPLIFIER_GAIN_GET	0xB0000
#define VERB_AMPLIFIER_GAIN_SET	0x30000
#define VERB_STREAM_FMT_GET	0xA0000
#define VERB_STREAM_FMT_SET	0x20000
#define VERB_DIGIT_CONVERT1_GET	0xF0D00
#define VERB_DIGIT_CONVERT1_SET	0x70D00
#define VERB_DIGIT_CONVERT2_GET	0xF0D00
#define VERB_DIGIT_CONVERT2_SET	0x70E00
#define VERB_POWER_STATE_GET	0xF0500
#define VERB_POWER_STATE_SET	0x70500
#define VERB_CHAN_STREAM_ID_GET	0xF0600
#define VERB_CHAN_STREAM_ID_SET	0x70600
#define VERB_SDI_SEL_GET	0xF0400
#define VERB_SDI_SEL_SET	0x70400
#define VERB_PIN_WIDGET_CTL_GET	0xF0700
#define VERB_PIN_WIDGET_CTL_SET	0x70700
#define VERB_UNSOL_ENABLE_GET	0xF0800
#define VERB_UNSOL_ENABLE_SET	0x70800
#define VERB_PIN_SENSE_GET	0xF0900
#define VERB_PIN_SENSE_SET	0x70900
#define VERB_EAPDBTL_ENABLE_GET 0xF0C00
#define VERB_EAPDBTL_ENABLE_SET 0x70C00
#define VERB_BEEP_CTL_GET	0xF0A00
#define VERB_BEEP_CTL_SET	0x70A00
#define VERB_GPI_CTRL0_GET	0xF1000
#define VERB_GPI_CTRL0_SET	0x71000
#define VERB_GPI_CTRL1_GET	0xF1100
#define VERB_GPI_CTRL1_SET	0x71100
#define VERB_GPI_CTRL2_GET	0xF1200
#define VERB_GPI_CTRL2_SET	0x71200
#define VERB_GPI_CTRL3_GET	0xF1300
#define VERB_GPI_CTRL3_SET	0x71300
#define VERB_GPI_CTRL4_GET	0xF1400
#define VERB_GPI_CTRL4_SET	0x71400
#define VERB_GPI_CTRL5_GET	0xF1500
#define VERB_GPI_CTRL5_SET	0x71500
#define VERB_GPI_CTRL6_GET	0xF1600
#define VERB_GPI_CTRL6_SET	0x71600
#define VERB_GPI_CTRL7_GET	0xF1700
#define VERB_GPI_CTRL7_SET	0x71700
#define VERB_GPI_CTRL8_GET	0xF1800
#define VERB_GPI_CTRL8_SET	0x71800
#define VERB_GPI_CTRL9_GET	0xF1900
#define VERB_GPI_CTRL9_SET	0x71900
#define VERB_GPI_CTRLA_GET	0xF1A00
#define VERB_GPI_CTRLA_SET	0x71A00
#define VERB_VOL_CTL_GET	0xF0F00
#define VERB_VOL_CTL_SET	0x70F00
#define VERB_SUB_SYS_ID0_GET	0xF2000
#define VERB_SUB_SYS_ID0_SET	0x72000
#define VERB_SUB_SYS_ID1_GET	0xF2000
#define VERB_SUB_SYS_ID1_SET	0x72100
#define VERB_SUB_SYS_ID2_GET	0xF2000
#define VERB_SUB_SYS_ID2_SET	0x72200
#define VERB_SUB_SYS_ID3_GET	0xF2000
#define VERB_SUB_SYS_ID3_SET	0x72300
#define VERB_CFG_DFT0_GET	0xF1C00
#define VERB_CFG_DFT0_SET	0x71C00
#define VERB_CFG_DFT1_GET	0xF1C00
#define VERB_CFG_DFT1_SET	0x71D00
#define VERB_CFG_DFT2_GET	0xF1C00
#define VERB_CFG_DFT2_SET	0x71E00
#define VERB_CFG_DFT3_GET	0xF1C00
#define VERB_CFG_DFT3_SET	0x71F00
#define VERB_STRIPE_CTL_GET	0xF2400
#define VERB_STRIPE_CTL_SET	0x72400
#define VERB_RST		0x7FF00

//Parameters
#define P_VENDOR_ID		0x00
#define P_REVISION_ID		0x02
#define P_SUBNODE_CNT		0x04
#define P_FUN_GRP_TYPE		0x05
#define P_AUDIO_FUN_CAP		0x08
#define P_AUDIO_WIDGET_CAP	0x09
#define P_SAMPLE_SIZE_RATE_CAP	0x0A
#define P_STREAM_FMTS		0x0B
#define P_PIN_CAP		0x0C
#define P_INPUT_AMP_CAP		0x0D
#define P_OUTPUT_AMP_CAP	0x12
#define P_CONNECT_LST_LEN	0x0E
#define P_POWER_STATES		0x0F
#define P_PROCESSING_CAP	0x10
#define P_GPIO_CNT		0x11
#define P_VOL_KNOB_CAP	0x13

//Function Group Types
//00 reserved
#define FGT_AUDIO		1
#define FGT_VENDOR_MODEM	2
//03-7F reserved
//80-FF vendor function group

//Audio Widget Types
#define AWT_OUTPUT		0x0
#define AWT_INPUT		0x1
#define AWT_MIXER		0x2
#define AWT_SELECTOR		0x3
#define AWT_PIN_COMPLEX		0x4
#define AWT_POWER_WIDGET	0x5
#define AWT_VOL_KNOB_WIDGET	0x6
#define AWT_BEEP_GEN_WIDGET	0x7
#define AWT_VENDOR		0xF
#define AWT_NODE		0x10
DefineLstLoad("ST_AUDIO_WIDGET_TYPES",
"Output\0Input\0Mixer\0Sellector\0Pin Complex\0"
"Power Widget\0Vol Knob\0Beep Gen\0\0\0\0\0\0\0\0Vendor\0Node\0");

class CHDBufDesc
{
  I32 *buf;
  U32 len;
  U32 ctrl;
};

#define HD_TONES	8

class CHDAudioCtrl
{
  U8 *bar;
  CBlkPool *bp;
  CHeapCtrl *hc;
  I64 cad;
  U32 *corb;
  I64 *rirb;
  CHDBufDesc *ostr0_bdl,*istr0_bdl;
  SND_OUT_CONTAINER *ostr0_buf[2],*o_tmp_buf;
  SND_IN_CONTAINER  *istr0_buf[2];
  CTask *task;
  I64 waveform;
  F64 freq,amp;
  CSndWaveCtrl *tone_swcs[HD_TONES];
  U8 rirb_rp,corb_wp;
  Bool audio_task_started,in_running,out_running;
} hda;
MemSet(&hda,0,sizeof(CHDAudioCtrl));

F64 SinPhaseCont(F64 last_y,F64 last_dydt,
		    F64 current_amp,F64 phase_offset)
{//Next sample of sin waveform.
  F64 phase;
  phase=last_y/current_amp;
  if (phase>1.0) phase=1.0;
  if (phase<-1.0) phase=-1.0;
  if (last_dydt<0)
    phase=pi-ASin(phase);
  else
    phase=ASin(phase);
  return phase-phase_offset;
}

public CSndWaveCtrl *SndWaveCtrlNew(I64 sample_rate=8000,I64 sample_bits=24,
  I64 channels=2,CTask *mem_task=NULL)
{//MAlloc ctrl struct for generating waveforms.
  CSndWaveCtrl *swc=CAlloc(sizeof(CSndWaveCtrl),mem_task);
  swc->freq_multiplier=1.0;
  swc->amp_multiplier=1.0;
  swc->sample_rate=sample_rate;
  swc->sample_bits=sample_bits;
  swc->channels=channels;
  swc->last_dydt=1.0;
  return swc;
}

public U0 SndWaveCtrlDel(CSndWaveCtrl *swc)
{//Free waveform ctrl.
  Free(swc);
}

public U0 SndWaveAddBuf(CSndWaveCtrl *swc,U8 *buf,I64 num_samples,
  F64 _freq,I64 _waveform=WF_SQUARE,F64 _amp=1.0,F64 _left=1.0, F64 _right=1.0)
{//Add waveform to buffer.
//num_samples is multiplied by channels to get buf_len.
  //left,right range from 0.0-1.0
  //Supports 16,24 and 32 bits
  I64 reg i,reg j,reg k;
  F64 a,f,amp,reg phase;
  if (!swc) return;
  _freq*=swc->freq_multiplier;
  _amp*=swc->amp_multiplier;
  if (!_freq||!_amp) {
    swc->last_y=swc->phase=0;
    swc->last_dydt=1.0;
  } else {
    phase=swc->phase;
    i=0;
    amp=Min(I32_MAX,I32_MAX*_amp);
    f=2*pi/swc->sample_rate*_freq;
    switch (_waveform) {
      case WF_NOISE:
	a=2.0/pi*amp;
	break;
      case WF_SAWTOOTH:
	a=amp/pi;
	break;
      case WF_SINE:
	phase=SinPhaseCont(swc->last_y,swc->last_dydt,amp,0.0);
	break;
    }
    while (phase<0)
      phase+=2*pi;
    while (phase>=2*pi)
      phase-=2*pi;
    num_samples*=swc->channels;
    while (i<num_samples) {
      switch (_waveform) {
	case WF_SQUARE:
	  if (phase>=pi)
	    j=-amp;
	  else
	    j=amp;
	  break;
	case WF_SINE:
	  j=amp*Sin(phase);
	  break;
	case WF_TRI:
	  if (phase>=pi) {
	    swc->last_y=swc->next_y;
	    swc->next_y=-amp*Sign(swc->last_y)+.00001;
	    phase-=pi;
	  }
	  j=(swc->last_y*(pi-phase)+swc->next_y*phase)/pi;
	  break;
	case WF_SAWTOOTH:
	  j=a*(phase-pi);
	  break;
	case WF_NOISE:
	  if (phase<pi) {
	    if (phase<f) {
	      swc->last_y=swc->next_y;
	      swc->next_y=a*RandI16/U16_MAX;
	    }
	    j=swc->last_y*(pi-phase)+swc->next_y*phase;
	  } else {
	    if (phase-pi<f) {
	      swc->last_y=swc->next_y;
	      swc->next_y=a*RandI16/U16_MAX;
	    }
	    j=swc->last_y*(2.0*pi-phase)+swc->next_y*(phase-pi);
	  }
	  break;
      }
//left channel
      k=j*_left;
      if (swc->sample_bits==16) {
	k>>=16;
	buf(I16 *)[i++]+=k;
      } else {
	if (swc->sample_bits==24)
	  k&=0xFFFFFF00;
	buf(I32 *)[i++]+=k;
      }
//right channel
      if (swc->channels==2) {
	k=j*_right;
	if (swc->sample_bits==16) {
	  k>>=16;
	  buf(I16 *)[i++]+=k;
	} else {
	  if (swc->sample_bits==24)
	    k&=0xFFFFFF00;
	  buf(I32 *)[i++]+=k;
	}
      }
      phase+=f;
      while (phase>=2*pi)
	phase-=2*pi;
    }
    if (_waveform==WF_SINE) {
      swc->last_y=amp*Sin(phase);
      swc->last_dydt=Cos(phase);
    }
    swc->phase=phase;
  }
}

U0 HDSyncCORB()
{
  U16 *wp,*rp;
  wp =hda.bar+HD_CORBWP;
  *wp=hda.corb_wp;
  rp =hda.bar+HD_CORBRP;
  while (*rp&255!=hda.corb_wp)
    Yield;
}

U0 HDWriteCORB(I64 cad,I64 nid,U32 val)
{
  val|=cad<<28+nid<<20;
  hda.corb[++hda.corb_wp]=val;
}

I64 HDSyncRIRB()
{
  U16 *_w;
  I64 wp,res=0;
  _w=hda.bar+HD_RIRBWP;
  wp=*_w;
  while (hda.rirb_rp!=wp)
    res=hda.rirb[++hda.rirb_rp];
  return res;
}

I64 HDReadRIRB()
{
  U16 *_w;
  I64 wp,res=0;
  _w=hda.bar+HD_RIRBWP;
  do {
    Yield;
    wp=*_w;
  } while (wp==hda.rirb_rp);
  res=hda.rirb[++hda.rirb_rp];
  return res;
}

I64 HDWriteCORBSync(I64 cad,I64 nid,U32 val)
{
  HDSyncCORB;
  HDSyncRIRB;
  HDWriteCORB(cad,nid,val);
  HDSyncCORB;
  return HDReadRIRB;
}

Bool HDTestCORBSync(I64 cad,I64 nid,U32 val)
{ //Checks for a response
  U16 *_w;
  I64 wp;

  HDSyncCORB;
  HDSyncRIRB;
  HDWriteCORB(cad,nid,val);
  HDSyncCORB;

  Sleep(1);
  _w=hda.bar+HD_RIRBWP;
  wp=*_w;
  if (wp==hda.rirb_rp)
    return FALSE;
  HDReadRIRB;
  return TRUE;
}

U0 HDTraverse(I64 cad,I64 nid)
{
  I64 i,len,aud_cap,type;
  HDWriteCORBSync(cad,nid,VERB_POWER_STATE_SET+0x00); //0 is on
  HDWriteCORBSync(cad,nid,VERB_EAPDBTL_ENABLE_SET+0x02);
  HDWriteCORBSync(cad,nid,VERB_PROCESS_STATE_SET+0x02);
  HDWriteCORBSync(cad,nid,VERB_CONNECT_SEL_SET+0x00);
  aud_cap=HDWriteCORBSync(cad,nid,VERB_GET_PARAM+P_SUBNODE_CNT);
  if (aud_cap.u16[0]) {
    for (i=aud_cap.u16[1];i<aud_cap.u16[1]+aud_cap.u16[0];i++)
      HDTraverse(cad,i);
  } else {
    aud_cap=HDWriteCORBSync(cad,nid,VERB_GET_PARAM+P_AUDIO_WIDGET_CAP);
    type=aud_cap>>20&15;
    if (Bt(&aud_cap,8))
      len=HDWriteCORBSync(cad,nid,VERB_GET_PARAM+P_CONNECT_LST_LEN)&127;
    else
      len=0;
    HDWriteCORBSync(cad,nid,VERB_AMPLIFIER_GAIN_SET+0xF07F); //set I/O amp #0
    for (i=1;i<len;i++)
//Set IN amps to mute
      HDWriteCORBSync(cad,nid,VERB_AMPLIFIER_GAIN_SET+0x7080+i<<8);
    switch (type) {
      case AWT_OUTPUT:
	if (FALSE) //if disabled
	  HDWriteCORBSync(cad,nid,VERB_CHAN_STREAM_ID_SET+0x00);
	else
	  HDWriteCORBSync(cad,nid,VERB_CHAN_STREAM_ID_SET+0x10);
	HDWriteCORBSync(cad,nid,VERB_STREAM_FMT_SET+HD_DFT_OUT_FMT);
	HDWriteCORBSync(cad,nid,VERB_PROCESS_STATE_SET+0x01);
	break;
      case AWT_INPUT:
	if (TRUE) //if disabled
	  HDWriteCORBSync(cad,nid,VERB_CHAN_STREAM_ID_SET+0x00);
	else
	  HDWriteCORBSync(cad,nid,VERB_CHAN_STREAM_ID_SET+0x20);
	HDWriteCORBSync(cad,nid,VERB_STREAM_FMT_SET+HD_DFT_IN_FMT);
	HDWriteCORBSync(cad,nid,VERB_PROCESS_STATE_SET+0x01);
	break;
      case AWT_PIN_COMPLEX:
	HDWriteCORBSync(cad,nid,VERB_PIN_WIDGET_CTL_SET+0xE2);
	break;
    }
  }
}

U0 HDRun(Bool in,Bool out)
{
  U32 *_d;
  if (hda.bar) {
    if (out) {
      _d=hda.bar+OSTR0+STRCTL;
      *_d=0x100002;
      hda.out_running=TRUE;
    }
    if (in) {
      _d=hda.bar+ISTR0+STRCTL;
      *_d=0x200002;
      hda.in_running=TRUE;
    }
  }
}

U0 HDStop(Bool in,Bool out)
{
  U32 *_d;
  if (hda.bar) {
    if (out) {
      _d=hda.bar+OSTR0+STRCTL;
      *_d=0;
      hda.out_running=FALSE;
    }
    if (in) {
      _d=hda.bar+ISTR0+STRCTL;
      *_d=0;
      hda.in_running=FALSE;
    }
  }
}

U0 HDSnd(F64 freq,I64 waveform=WF_SQUARE,F64 amp=1.0)
{
  hda.waveform=waveform;
  hda.amp=amp;
  hda.freq=freq;
}

U32 *hd_buf=NULL;
I64 hd_buf_pos=0;
I64 hd_buf_size=0;

U0 HDFillBuf(SND_OUT_CONTAINER *buf,I64)
{
    I64 i;
    for (i=0;i<SND_BUF_LEN;i++)
    {
        buf[i]=0;
    }
}

U0 SetAudioStream(AudioStream *stream)
{
    hd_buf_pos=0;
    hd_buf_size=stream->size;
    hd_buf = stream->buf;
}

U0 HDAudioTaskEndCB()
{
  I64 i;
  HDStop(FALSE,TRUE);
  fp_snd=NULL;
  for (i=0;i<HD_TONES;i++) {
    SndWaveCtrlDel(hda.tone_swcs[i]);
    hda.tone_swcs[i]=NULL;
  }
  Exit;
}

public U0 HDTonesInit()
{
  I64 i;
  if (hda.bar) {
    for (i=0;i<HD_TONES;i++) {
      hda.tone_swcs[i]->freq_multiplier=1.0;
      hda.tone_swcs[i]->amp_multiplier=0;
    }
    hda.tone_swcs[0]->amp_multiplier=1.0;
  }
}

U0 HDAudioTask(I64)
{
//I didn't feel like messing around with PCI interrupts
  //so this task polls every millisecond to know when to
  //switch buffers.
  I64 i,next_obuf_trigger=SND_BUF_LEN*sizeof(SND_OUT_CONTAINER)/2,
	obuf_rollover=0,
	next_ibuf_trigger=SND_BUF_LEN*sizeof(SND_IN_CONTAINER),
	ibuf_rollover=0;
  U32 *pos_in_obuf=hda.bar+OSTR0+STRLPIB,
	*pos_in_ibuf=hda.bar+ISTR0+STRLPIB;
  Fs->task_end_cb=&HDAudioTaskEndCB;
  for (i=0;i<HD_TONES;i++)
    hda.tone_swcs[i]=SndWaveCtrlNew;
  HDTonesInit;
  hda.freq=0;
  Snd;
  fp_snd=&HDSnd;
  fp_snd_fill_buf=&HDFillBuf;
  fp_snd_copy_buf=NULL;
  snd_obuf_num=1;
  snd_ibuf_num=1;
  HDRun(FALSE,TRUE);
  hda.audio_task_started=TRUE; //This flag is probably not necessary
  while (TRUE) {
    if (next_obuf_trigger-obuf_rollover<=*pos_in_obuf<
	  next_obuf_trigger-obuf_rollover+
	  (HD_POS_BUF_MULTIPLES-1)*SND_BUF_LEN*sizeof(SND_OUT_CONTAINER)) {
      next_obuf_trigger+=SND_BUF_LEN*sizeof(SND_OUT_CONTAINER);
      if (next_obuf_trigger-obuf_rollover>=
	    HD_POS_BUF_MULTIPLES*SND_BUF_LEN*sizeof(SND_OUT_CONTAINER))
	obuf_rollover+=HD_POS_BUF_MULTIPLES*SND_BUF_LEN
	      *sizeof(SND_OUT_CONTAINER);
      if (fp_snd_fill_buf) {
	LBts(&snd_flags,Sf_FILLING_OUT);
	(*fp_snd_fill_buf)(hda.ostr0_buf[snd_obuf_num&1],snd_obuf_num);
  audio_sync_begin = TRUE;
	if (IsMute)
	  MemSet(hda.ostr0_buf[snd_obuf_num&1],0,
		SND_BUF_LEN*sizeof(SND_OUT_CONTAINER));
	LBtr(&snd_flags,Sf_FILLING_OUT);
      }
      snd_obuf_num++;
    }
    if (next_ibuf_trigger-ibuf_rollover<=*pos_in_ibuf<
	  next_ibuf_trigger-ibuf_rollover+(HD_POS_BUF_MULTIPLES-1)
	  *SND_BUF_LEN*sizeof(SND_IN_CONTAINER)) {
      next_ibuf_trigger+=SND_BUF_LEN*sizeof(SND_IN_CONTAINER);
      if (next_ibuf_trigger-ibuf_rollover>=
	    HD_POS_BUF_MULTIPLES*SND_BUF_LEN*sizeof(SND_IN_CONTAINER))
	ibuf_rollover+=HD_POS_BUF_MULTIPLES*SND_BUF_LEN
	      *sizeof(SND_IN_CONTAINER);
      if (fp_snd_copy_buf)
	(*fp_snd_copy_buf)(hda.istr0_buf[snd_obuf_num&1],snd_ibuf_num);
      snd_ibuf_num++;
    }
    Sleep(1);
  }
}

U0 HDRst()
{
  U32 d,*_d;
  HDStop(TRUE,TRUE);
  _d=hda.bar+HD_GCTL;
  *_d=0;  //rst
  do {
    Sleep(1);
    d=*_d;
  } while (d & 1);
  *_d=1;
  do {
    Sleep(1);
    d=*_d;
  } while (!(d & 1));
  Sleep(1);
}

public U0 HDAudioEnd(Bool rst=TRUE)
{
  snd_dev=SD_PC_SPEAKER;
  if (hda.bar) {
    Kill(hda.task);
    hda.task=NULL;
    if (rst)
      HDRst;
    Free(hda.corb);
    Free(hda.rirb);
    Free(hda.o_tmp_buf);
    Free(hda.ostr0_buf[0]);
    Free(hda.ostr0_buf[1]);
    Free(hda.istr0_buf[0]);
    Free(hda.istr0_buf[1]);
    Free(hda.ostr0_bdl);
    Free(hda.istr0_bdl);
    Mem32DevFree(hda.bar);
    hda.bar=NULL;
  }
}

U0 HDAudioUncachedInit()
{
  I64 shared_blks=1;
  hda.bp=Mem2MegUncachedAlloc(&shared_blks);
  hda.hc=HeapCtrlBPInit(hda.bp,shared_blks<<12);
}

public Bool HDAudioInit(I64 hd_bus,I64 hd_dev,I64 hd_fun)
{
  I64 i;
  U32 *_d;
  U16 w,*_w;
  U8 *_b;
  if (hda.bar)
    HDAudioEnd;
  else
    HDAudioUncachedInit;
  if (PCIReadU16(hd_bus,hd_dev,hd_fun,0)==0x8086 &&
	(hda.bar=PCIReadU32(hd_bus,hd_dev,hd_fun,0x10) & ~(0x1F))) {
    PCIWriteU16(hd_bus,hd_dev,hd_fun,0x04,
	  PCIReadU16(hd_bus,hd_dev,hd_fun,0x04)|0x406);

    HDRst;

    hda.corb=CAllocAligned(HD_CORB_ENTRIES*sizeof(U32),128,hda.hc);
    _d=hda.bar+HD_CORBLBASE;
    *_d=hda.corb(I64).u32[0];
    _d=hda.bar+HD_CORBUBASE;
    *_d=hda.corb(I64).u32[1];

    hda.rirb=CAllocAligned(HD_RIRB_ENTRIES*sizeof(I64),128,hda.hc);
    _d=hda.bar+HD_RIRBLBASE;
    *_d=hda.rirb(I64).u32[0];
    _d=hda.bar+HD_RIRBUBASE;
    *_d=hda.rirb(I64).u32[1];

    _w=hda.bar+HD_CORBRP;
    /*
    *_w=0x8000; //Rst read ptr
    do {
      Yield;
      w=*_w;
      "%08X\n", w;
    } while (!(w&0x8000));
    */
    *_w=0x0000; //Rst read ptr
    do {
      Yield;
      w=*_w;
    } while (w&0x8000);

    _w=hda.bar+HD_RIRBWP;
    *_w=0x8000; //Rst write ptr

    _b=hda.bar+HD_CORBCTL;
    *_b=0x02; //Run
    _b=hda.bar+HD_RIRBCTL;
    *_b=0x02; //Run

    _w=hda.bar+HD_CORBWP;
    hda.corb_wp=*_w;
    _w=hda.bar+HD_RIRBWP;
    hda.rirb_rp=*_w;

    hda.ostr0_bdl =CAllocAligned(
	  HD_BDL_ENTRIES*sizeof(CHDBufDesc),128,hda.hc);
    _d=hda.bar+OSTR0+STRBDPL;
    *_d=hda.ostr0_bdl(I64).u32[0];
    _d=hda.bar+OSTR0+STRBDPU;
    *_d=hda.ostr0_bdl(I64).u32[1];
    for (i=0;i<2;i++) {
      hda.ostr0_bdl[i].buf=hda.ostr0_buf[i]=
	    CAllocAligned(
	    SND_BUF_LEN*sizeof(SND_OUT_CONTAINER),128,hda.hc);
      hda.ostr0_bdl[i].len=SND_BUF_LEN*sizeof(SND_OUT_CONTAINER);
      hda.ostr0_bdl[i].ctrl=1;
    }

    hda.istr0_bdl =CAllocAligned(
	  HD_BDL_ENTRIES*sizeof(CHDBufDesc),128,hda.hc);
    _d=hda.bar+ISTR0+STRBDPL;
    *_d=hda.istr0_bdl(I64).u32[0];
    _d=hda.bar+ISTR0+STRBDPU;
    *_d=hda.istr0_bdl(I64).u32[1];
    for (i=0;i<2;i++) {
      hda.istr0_bdl[i].buf=hda.istr0_buf[i]=CAllocAligned(
	    SND_BUF_LEN*sizeof(SND_IN_CONTAINER),128,hda.hc);
      hda.istr0_bdl[i].len=SND_BUF_LEN*sizeof(SND_IN_CONTAINER);
      hda.istr0_bdl[i].ctrl=1;
    }

    _w=hda.bar+HD_STATESTS;
    w=*_w;
    while (w) {
      hda.cad=Bsf(w);
      if (HDTestCORBSync(hda.cad,0,VERB_GET_PARAM+P_SUBNODE_CNT)) {
	HDTraverse(hda.cad,0);

	_d=hda.bar+OSTR0+STRLPIB;
	*_d=0;
	_d=hda.bar+OSTR0+STRCBL;
	*_d=HD_POS_BUF_MULTIPLES*SND_BUF_LEN*sizeof(SND_OUT_CONTAINER);
	_w=hda.bar+OSTR0+STRLVI;
	*_w=1;	//last valid idx
	_w=hda.bar+OSTR0+STRFMT;
	*_w=HD_DFT_OUT_FMT;

	_d=hda.bar+ISTR0+STRLPIB;
	*_d=0;
	_d=hda.bar+ISTR0+STRCBL;
	*_d=HD_POS_BUF_MULTIPLES*SND_BUF_LEN*sizeof(SND_IN_CONTAINER);
	_w=hda.bar+ISTR0+STRLVI;
	*_w=1;	//last valid idx
	_w=hda.bar+ISTR0+STRFMT;
	*_w=HD_DFT_IN_FMT;

	LBts(&sys_semas[SEMA_SND],0); //turn off until cfg completed
	LBtr(&snd_flags,Sf_FILLING_OUT);
	hda.audio_task_started=FALSE;
	if (mp_cnt>1)
	  hda.task=Spawn(&HDAudioTask,NULL,"HD Audio",mp_cnt-1);
	else
	  hda.task=Spawn(&HDAudioTask,NULL,"HD Audio");
	while (!hda.audio_task_started)
	  Yield;
	snd_dev=SD_HD_AUDIO;
	return TRUE;
      }
      Btr(&w,hda.cad);
    }
    HDAudioEnd(FALSE);
  } else
    hda.bar=NULL;
  return FALSE;
}

Bool HDAudioScan()
{
  I64 i=-1,j;
  while (TRUE) {
    j=PCIClassFind(0x040300,++i);
    if (j<0)
      return FALSE;

    if (HDAudioInit(j.u8[2],j.u8[1],j.u8[0]))
      return TRUE;
  }
}

HDAudioScan;
Kill(hda.task);
HDAudioScan;
