program Netswitch;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  AdvancedSingleInstance,
  Interfaces, // this includes the LCL widgetset
  Forms, fmain, setting, about
  { you can add units after this };

{$R *.res}

begin
  Application.Scaled:=True;
  Application.Initialize;
  Application.SingleInstanceEnabled := true;
  Application.SingleInstance.Start;
  if Application.SingleInstance.IsServer then begin
     Application.CreateForm(TApp, App);
     Application.CreateForm(TSetForm, SetForm);
	Application.CreateForm(TAbtform, Abtform);
     Application.Run;
  end;
end.

