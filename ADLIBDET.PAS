{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/CODER/ADLIBLIB-TP)
  @abstract(Target: Turbo Pascal 7)
}

Unit ADLIBDET;

INTERFACE

Function DetectIsAdlib:Boolean;

IMPLEMENTATION

Uses Crt;

Procedure SetAdlib(Address,Data:Byte);
Var X,I:Byte;
Begin
 Port[$388]:=Address;
 For I:=1 to 6 do X:=Port[$388];
 Port[$389]:=Data;
 For I:=1 to 35 do X:=Port[$388];
End;

Function DetectIsAdlib:Boolean;
Var
 X,X2:Byte;
Begin
 SetAdlib($4,$60);
 SetAdlib($4,$80);
 Delay(10);
 X:=Port[$388];
 SetAdlib($2,$FF);
 SetAdlib($4,$21);
 Delay(10);
 X2:=Port[$388];
 SetAdlib($4,$60);
 SetAdlib($4,$80);
 X:=X and $E0;
 X2:=X2 and $E0;
 If(X=$0)and(X2=$C0)Then DetectIsAdlib:=True
                    Else DetectIsAdlib:=False;
End;

END.