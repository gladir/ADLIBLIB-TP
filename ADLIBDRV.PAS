{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/CODER/ADLIBLIB-TP)
  @abstract(Target: Turbo Pascal 7)
}

Unit ADLIBDRV;

INTERFACE

Const
 { Constante de la carte AdLib }
 AdLibGTMin=0;
 AdLibGTMax=10;

Type
 AdLibInstrum=Array[1..26]of Integer;

Var
 AdLibGActVoice:Word;
 AdLibGT:Array[AdLibGTMin..AdLibGTMax]of AdLibInstrum;

Procedure ADLIB_DirectNoteOn(Voice:Word;Pitch:Integer);
Procedure ADLIB_DirectNoteOff(Voice:Word);
Procedure ADLIB_DirectTimbre;
Function  ADLIB_GetState:Boolean;
Procedure ADLIB_InitDriver;
Procedure ADLIB_LoadInstrument(FileSpec:String);
Function  ADLIB_LoadSong(FileSpec:String):Boolean;
Function  ADLIB_PlayNote(Pitch:Integer;LengthNum,LengthDen:Word):Boolean;
Function  ADLIB_PlayNoteDel(Pitch:Integer;LengthNum,LengthDen,DelayNum,DelayDen:Word):Boolean;
Procedure ADLIB_RelTimeStart(TimeNum,TimeDen:Integer);
Procedure ADLIB_SetActVoice(Var Voice:Word);
Procedure ADLIB_SetMode(PercussionMode:Integer);
Function  ADLIB_SetPitch(DeltaOctave,DeltaNum,DeltaDen:Integer;TimeNum,TimeDen:Word):Boolean;
Procedure ADLIB_SetState(Var State:Integer);
Procedure ADLIB_SetTickBeat(Var TickBeat:Integer);
Function  ADLIB_SetTempo(Tempo,TimeNum,TimeDen:Integer):Boolean;
Function  ADLIB_SetTimbre(TimeNum,TimeDen:Word):Boolean;
Function  ADLIB_SetVolume(VolNum,VolDen,TimeNum,TimeDen:Integer):Boolean;

IMPLEMENTATION

Uses DOS;

Function FileExist(Name:String):Boolean;
Var
 Rec:SearchRec;
Begin
 FindFirst(Name,AnyFile,Rec);
 FileExist:=DosError=0;
End;

{@description: Cette proc‚dure permet d'arrˆter une note directe dans
               la voix de la carte de son AdLib en utilisant le pilote
               branch‚ sur l'interruption.
}

Procedure ADLIB_DirectNoteOff(Voice:Word);Assembler;ASM
 MOV SI,20
 PUSH SS
 POP ES
 MOV BX,Offset Voice
 INT $65
END;

{@description: Cette proc‚dure permet d'envoyer une note directe dans
               la voix de la variable de param‚trage ®Voice¯ … la
               carte de son AdLib.
}

Procedure ADLIB_DirectNoteOn;Assembler;
Var
 T:Record
  Pitch:Integer;
  Voice:Word;
 End;
ASM
 MOV AX,Voice
 MOV T.Voice,AX
 MOV AX,Pitch
 MOV T.Pitch,AX
 MOV SI,19
 LES BX,T
 INC BX
 INC BX
 PUSH BP
  INT $65
 POP BP
END;

{@description: Cette proc‚dure envoye un timbre directement sur la
               carte de son AdLib.
}

Procedure ADLIB_DirectTimbre;
Var
 T:^Integer;
 V:Word;
Begin
 V:=AdLibGActVoice;T:=@AdLibGT[V];
 ASM
  MOV SI,21
  PUSH SS
  POP ES
  MOV BX,Offset V
  PUSH BP
   INT $65
  POP BP
 END;
End;

{@description: Cette fonction retourne l'‚tat de la carte de son AdLib.}

Function ADLIB_GetState;Assembler;
Var
 Buf:Boolean;
ASM
 MOV DI,4
 PUSH SS
 POP ES
 MOV BX,Offset Buf
 PUSH BP
  INT $65
  MOV AX,BP
 POP BP
END;

{@description: Cette proc‚dure initialise le pilote de la carte de
               son AdLib.
}

Procedure ADLIB_InitDriver;Assembler;ASM
  XOR SI,SI
  PUSH BP
   INT $65
  POP BP
 END;

{@description: Cette proc‚dure charge le fichier ®FileSpec¯ contenant
               les instruments pour la carte de son AdLib dans celle-ci.
}

Procedure ADLIB_LoadInstrument(FileSpec:String);
Var
 Handle:File; {.INS}
 ByteReaded:Word;
Begin
 {$I-}Assign(Handle,FileSpec);
 Reset(Handle,1);{$I+}
 If IOResult<>0 Then Exit;
 Seek(Handle,2);
 BlockRead(Handle,AdLibGT,SizeOf(AdLibGT),ByteReaded);
 Close(Handle);
End;

{@description: Cette fonction charge un fichier son dans la carte
               de son AdLib.
}

Function ADLIB_LoadSong;
Var
 nb:Byte;
 ns:String;
 ni,ni2,ni3,ni4,BPM:Integer;
 c1,c2:Word;
 nr,nr2:Real;
 fl:Boolean;
 f:File;

 Procedure StringRead(Len:Word);
 Var
  nc:Char;
  c1:Word;
 Begin
  ns:='';
  For c1:=1 to len do Begin
   BlockRead(f,nc,1);
   ns:=Concat(ns,nc);
  End;
 End;

 Procedure TempoRead;
 Var
  b1,b2,b3,b4:Byte;
 Begin
  BlockRead(f,b1,1);
  BlockRead(f,b2,1);
  BlockRead(f,b3,1);
  BlockRead(f,b4,1);
  nb:=b3;
 End;

 Procedure VolumeRead;
 Var
  b1,b2,b3,b4 :byte;
 Begin
  BlockRead(f,b1,1);
  BlockRead(f,b2,1);
  BlockRead(f,b3,1);
  BlockRead(f,b4,1);
  nb:=51+Round(b3/2.5);
 End;

Begin
 ADLIB_LoadSong:=False;
 If Not(FileExist(FileSpec))Then Exit;
 ADLIB_InitDriver;
 ADLIB_RelTimeStart(0,1);
 {$I-}Assign(F,FileSpec);
 Reset(F,1);{$I+}
 If IOResult<>0 Then Exit;
 StringRead(44);
 BlockRead(F,ni,2);
 ADLIB_SetTickBeat(ni);
 BlockRead(F,ni,2);
 BPM:=ni;
 StringRead(5);
 BlockRead(F,nb,1);
 ADLIB_SetMode(1);
 StringRead(143);
 TempoRead;
 fl:=ADLIB_SetTempo(nb,0,1);
 BlockRead(F,ni,2);
 For c1:=1 to ni do Begin
  BlockRead(F,ni2,2);
  TempoRead;
  fl:=ADLIB_SetTempo(nb,ni2,1);
 End;
 For c1:=0 to 10 do Begin
  ADLIB_SetActVoice(c1);
  StringRead(15);
  BlockRead(f,ni2,2);
  c2:=0;
  While(c2<ni2)do Begin
   BlockRead(f,ni3,2);
   BlockRead(f,ni4,2);
   fl:=ADLIB_PlayNote(ni3-60,ni4,BPM);
   c2:=c2+ni4;
  End;
  StringRead(15);
  BlockRead(f,ni2,2);
  For c2:=1 to ni2 do Begin
   BlockRead(F,ni3,2);
   StringRead(9);
   nb:=Pos(#0,ns);
   Delete(ns,nb,Length(ns));
   ADLIB_LoadInstrument(Concat(ns,'.INS'));
   fl:=ADLIB_SetTimbre(ni3,1);
   StringRead(1);
   BlockRead(F,ni4,2);
  End;
  StringRead(15);
  BlockRead(F,ni2,2);
  nb:=1;
  For c2:=1 to ni2 do Begin
   BlockRead(f,ni3,2);
   fl:=ADLIB_SetVolume(100,nb,ni3,1);
   VolumeRead;
   fl:=ADLIB_SetVolume(nb,100,ni3,1);
  End;
  StringRead(15);
  BlockRead(F,ni2,2);
  For c2:=1 to ni2 do Begin
   BlockRead(F,ni3,2);
   BlockRead(F,nr,4);
   If(nr=0)Then nr2:=1
           Else nr2:=nr;
  End;
 End;
 Close(f);
 ADLIB_LoadSong:=True;
End;

{@description: Cette fonction entre un note manuellement dans la carte
               de son AdLib et retourne un ‚tat indiquant si l'op‚ration
               c'est correctement d‚roul‚e.
}

Function ADLIB_PlayNote;Assembler;ASM
 PUSH SS
 POP ES
 MOV BX,Offset Pitch
 MOV SI,15
 PUSH BP
  INT $65
  MOV AX,BP
 POP BP
END;

{@description: Cette fonction permet d'entrer une note manuellement
               avec un certain d‚lai dans la carte de son AdLib  et
               retourne un ‚tat indiquant si l'op‚ration c'est
               correctement d‚roul‚e.
}

Function ADLIB_PlayNoteDel;Assembler;ASM
 PUSH SS
 POP ES
 MOV BX,Offset Pitch
 MOV SI,14
 PUSH BP
  INT $65
  MOV AX,BP
 POP BP
END;

{@description: Cette proc‚dure permet de d‚buter le processus de la
               musique pour la carte de son AdLib.
 }

Procedure ADLIB_RelTimeStart;Assembler;ASM
 LES BX,TimeNum.DWord
 MOV SI,2
 PUSH BP
  INT $65
 POP BP
END;

{@description: Cette proc‚dure permet de fixer l'acte d'une voix de la
               carte de son AdLib.
}

Procedure ADLIB_SetActVoice;Assembler;ASM
 LES BX,Voice
 MOV AX,ES:[BX]
 MOV AdLibGActVoice,AX
 MOV SI,12
 INT $65
END;

Procedure ADLIB__SetMode(Var PercussionMode:Integer);Assembler;ASM
 MOV SI,6
 LES BX,PercussionMode
 INT $65
END;

{@description: Cette proc‚dure permet de fixer le mode de percussion
               de la carte de son AdLib.
}

Procedure ADLIB_SetMode(PercussionMode:Integer);Begin
 ADLIB__SetMode(PercussionMode);
End;

{@description: Cette fonction permet de fixer la fa‡on de sortir les
               octaves de la carte de son AdLib par l'entremise du
               pilote d'interruption.
}

Function ADLIB_SetPitch;Assembler;ASM
 PUSH SS
 POP ES
 MOV BX,Offset DeltaOctave
 MOV SI,16
 PUSH BP
  INT $65
  MOV AX,BP
 POP BP
END;

{@description: Cette proc‚dure permet de fixer l'‚tat de la carte de
               son AdLib par l'entremise de son pilote d'interruption.
}

Procedure ADLIB_SetState;Assembler;ASM
 MOV SI,3
 LES BX,State
 INT $65
END;

{@description: Cette fonction permet de fixer le ®Tempo¯ de la carte de
              son AdLib par l'entremise de son pilote d'interruption.
}

Function ADLIB_SetTempo;Assembler;ASM
 PUSH SS
 POP ES
 MOV BX,Offset Tempo
 MOV SI,9
 PUSH BP
  INT $65
  MOV AX,BP
 POP BP
END;

{@description: Cette proc‚dure permet de fixer l'espace des tics du
               rythme de la musique de la carte de son AdLib par
               l'entremise du pilote d'interruption.
}

Procedure ADLIB_SetTickBeat;Assembler;ASM
 MOV SI,18
 LES BX,TickBeat
 INT $65
END;

{@description: Cette fonction permet de fixer le timbre de la carte
               de son AdLib par l'entremise du pilote d'interruption.
}

Function ADLIB_SetTimbre;
Var
 TD,TN:Word;
 T:^Integer;
 c1,c2:Byte;
Begin
 T:=@AdLibGT[AdLibGActVoice];TN:=TimeNum;TD:=TimeDen;
 ASM
  MOV SI,16
  LES BX,T
  PUSH BP
   INT $65
   MOV AX,BP
  POP BP
  MOV @Result,AL
 END;
End;

{@description: Cette fonction fixe le volume de la carte de son AdLib
               par l'entremise du pilote d'interruption.
}

Function ADLIB_SetVolume;Assembler;ASM
 PUSH SS
 POP ES
 MOV BX,Offset VolNum
 MOV SI,8
 PUSH BP
  INT $65
  MOV AX,BP
 POP BP
END;

END.
