unit fmain;

{$mode objfpc}{$H+}

interface

uses
  Windows, LCLType,lazutf8, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Menus, LCLIntf, Registry,
  ExtCtrls, Buttons, setting, about, DateUtils, ComObj, ActiveX;

type
  { action data group }
  TAckData = record
    adtpname: string;
    ackway: Boolean;
  end;
  AckData = ^TAckData;

  { TApp }

  TApp = class(TForm)
    BtnExit: TButton;
    BtnTopMenu: TButton;
    Image1: TImage;
    ImageList1: TImageList;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem9: TMenuItem;
    Panel1: TPanel;
    Separator2: TMenuItem;
    Timer1: TTimer;
    Nowmenu: TPopupMenu;
    Topmenu: TPopupMenu;
    Traymenu: TPopupMenu;
    Trayicon: TTrayIcon;
    procedure BtnAbtClick(Sender: TObject);
    procedure BtnowdisableClick(Sender: TObject);
    procedure BtnSetClick(Sender: TObject);
    procedure BtnExitClick(Sender: TObject);
    procedure BtnMintotrayClick(Sender: TObject);
    procedure BtntrayClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BtnowenableClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure AlwaysTopClick(Sender: TObject);
    procedure BtnNowMenuMouseDown(Sender: TObject; Button: TMouseButton;  Shift: TShiftState; X, Y: Integer);
    procedure BtnTopMenuMouseDown(Sender: TObject; Button: TMouseButton;  Shift: TShiftState; X, Y: Integer);
    procedure Fmdown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure TrayiconMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    function Clearegistry: Boolean;
    function Loadsetting: Boolean;
    procedure Loadregistry(Data: PtrInt);
    procedure CheckTimeAndToggleAdapters;
    procedure EnableDisableAdapter(Data: PtrInt);
    procedure Saveposition;
    procedure Loadplace;
    procedure Loadadapter(Data: PtrInt);
  public
    procedure SetrayBallhint(const Title, Msg: String);
    procedure ShowSettings;
    procedure ShowAbout;
  end;

var
  App: TApp;
  Trayshow: bool;
  opentime, closetime: TDateTime;
  adapter, langs: String;
  renow: Integer;
  ennow, dsnow: Boolean;
  Menuxy: TPoint;

implementation

{$R *.lfm}

{ TApp }

procedure TApp.BtntrayClick(Sender: TObject);
begin
 if WindowState = wsMinimized then begin
    WindowState:=wsNormal;
    Show;
    ShowWindow(WM_SYSCOMMAND, SW_HIDE);
    Application.Showmainform := false;
    ShowWindow(Application.Handle, SW_HIDE);
    { reload the menu place }
    Loadplace;
  end;
end;

procedure TApp.TrayiconMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
th:integer;
begin
 if Win32MajorVersion<=6 then th:=51
 else th:=61;
   if button = mbleft then
     //fixed height point baseon screen.height
      Trayshow:= not Trayshow;
    if Trayshow then begin
      Traymenu.Popup(X-th,Screen.Height-th);
      Trayshow := False;
    end
    else begin
     Traymenu.Close;
    end;
end;

procedure TApp.FormCreate(Sender: TObject);
begin
  ennow:=False;
  dsnow:=False;
  Trayshow:=false;
  TrayIcon.Hint:= 'Network Switch';
  Application.QueueAsyncCall(@Loadregistry,1);
end;

procedure TApp.BtnowenableClick(Sender: TObject);
var
PData: AckData;
begin
  ennow:=False;
  Trayicon.BalloonTitle:= 'Network Adapter Message';
  Trayicon.BalloonHint:= 'The ' + adapter + ' has been enabled';
  TrayIcon.ShowBalloonHint;
  New(PData);
  PData^.adtpname:= adapter;
  PData^.ackway:= True;
  Application.QueueAsyncCall(@EnableDisableAdapter,PtrInt(PData));
  Image1.ImageIndex:=2;
end;


procedure TApp.BtnowdisableClick(Sender: TObject);
var
PData: AckData;
begin
  dsnow:=False;
  Trayicon.BalloonTitle:= 'Network Adapter Message';
  Trayicon.BalloonHint:= 'The ' + adapter + ' has been disabled';
  TrayIcon.ShowBalloonHint;
  New(PData);
  PData^.adtpname:= adapter;
  PData^.ackway:= False;
  Application.QueueAsyncCall(@EnableDisableAdapter,PtrInt(PData));
  Image1.ImageIndex:=1;
end;

procedure TApp.Timer1Timer(Sender: TObject);
begin
  CheckTimeAndToggleAdapters;
end;

procedure TApp.CheckTimeAndToggleAdapters;
var
PData: AckData;
begin
  Label1.Caption := FormatDateTime('hh:nn:ss',Now);
  Label2.Caption := 'Enable';
  Label3.caption := FormatDateTime('hh:nn:ss',opentime);
  Label4.Caption := 'Disable';
  Label5.caption := FormatDateTime('hh:nn:ss',closetime);
  { toggle enabled }
  if (HourOf(now) = HourOf(opentime)) and (MinuteOf(now) = MinuteOf(opentime)) then begin
    New(PData);
    PData^.adtpname:= adapter;
    PData^.ackway:= True;
    if (fmain.renow > 0) then begin
      if not(DayOf(opentime) = DayOf(now)) then ennow:= False;
    end;
    Application.QueueAsyncCall(@EnableDisableAdapter,PtrInt(PData));
  end;
  { toggle disabled }
  if (HourOf(now) = HourOf(closetime)) and (MinuteOf(now) = MinuteOf(closetime)) then begin
    New(PData);
    PData^.adtpname:= adapter;
    PData^.ackway:= False;
    if (fmain.renow > 0) then begin
       if not(DayOf(closetime) = DayOf(now)) then dsnow:= False;
    end;
    Application.QueueAsyncCall(@EnableDisableAdapter,PtrInt(PData));
  end;
end;

procedure TApp.EnableDisableAdapter(Data: PtrInt);
var
  Command: string;
  PData: TAckData;
  ballhit: string;
begin
  PData := AckData(Data)^;
  { check is double action }
  if PData.ackway then begin
     if ennow then exit;
    end
  else begin
       if dsnow then exit;
  end;
  { generate the command }
  if PData.ackway then
    Command := 'interface set interface "' + PData.adtpname + '" enabled'
  else
    Command := 'interface set interface "' + PData.adtpname + '" disabled';

  { runing the command }
  if ShellExecute(0, 'open', 'netsh', PChar(Command), nil, SW_HIDE) <= 32 then
    ShowMessage('Failed to change the state of the adapter: ' + PData.adtpname)
    else begin
      {--balloon-hit--}
      Traymenu.Close;
      TrayIcon.hint:='Netswitch Switch Message';
      TrayIcon.BalloonTitle:= 'Network Adapter Message';
      ballhit:= 'The ' + PData.adtpname + ' has been disabled';
      if PData.ackway then ballhit:= 'The ' + PData.adtpname + ' has been enabled';

      TrayIcon.BalloonHint:= ballhit;
      TrayIcon.ShowBalloonHint;

      { rest state tags }
      if PData.ackway then ennow := True
      else dsnow := True;
    end;
end;

procedure TApp.BtnExitClick(Sender: TObject);
begin
  Saveposition;
  Application.Showmainform := true;
  ShowWindow(WM_SYSCOMMAND, SW_SHOW);
  ShowWindow(Application.Handle, SW_SHOW);
  Application.ProcessMessages;
  Trayicon.Visible:=false;
  Application.Terminate;
end;

{ here is left side button }
procedure TApp.BtnNowMenuMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  pt: TPoint;
  sidewidht: integer;
  sidehight: integer;
begin
   GetCursorPos(pt);
   sidewidht:=80;
   sidehight:=35;
   if not(Win32MajorVersion<=6) then begin
     sidewidht:=90;
     sidehight:=35;
     end;
   Nowmenu.Popup(pt.X-x-2,pt.Y-y+sidehight);
end;

{ show main menu }
procedure TApp.BtnTopMenuMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  pt: TPoint;
  sidewidht: integer;
  sidehight: integer;
begin
   GetCursorPos(pt);
   sidewidht:=80;
   sidehight:=35;
   if (Win32MajorVersion = 10) then begin
     sidewidht:=90;
     sidehight:=35;
     end;
   Topmenu.Popup(pt.X-x-sidewidht,pt.Y-y+sidehight);
end;

procedure TApp.BtnSetClick(Sender: TObject);
begin
 ShowSettings;
end;

procedure TApp.BtnAbtClick(Sender: TObject);
begin
 ShowAbout;
end;

procedure TApp.BtnMintotrayClick(Sender: TObject);
begin
  WindowState:=wsMinimized;
  Hide;
  Saveposition;
end;

procedure TApp.SetrayBallhint(const Title, Msg: String);
begin
   TrayIcon.BalloonTitle:= Title;
   TrayIcon.BalloonHint:= Msg;
end;

procedure TApp.Fmdown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  pt: TPoint;
begin
 if Button = mbLeft then
    begin
     ReleaseCapture;
     SendMessage(Self.Handle, WM_SYSCOMMAND, 61458, 0);
     GetCursorPos(pt);
	 
     if pt.X < 50 then begin
        if pt.Y-Y<0 then
          SetBounds(-(width-70),pt.Y,width,height)
         else
          SetBounds(-(width-70),pt.Y-Y,width,height);
     end;

     if (pt.X+50) > screen.Width then begin
        if pt.Y-Y<0 then
        SetBounds(screen.Width-65,pt.Y,width,height)
        else
        SetBounds(screen.Width-65,pt.Y-Y,width,height);
      end;

      if (pt.Y+90) > screen.Height then begin
          SetBounds(pt.X-X,screen.Height-90,width,height);
      end;
      Menuxy:=Panel1.ClientOrigin;
    end;
end;

{ save the menu position }
procedure TApp.Saveposition;
var
  key: String;
  reg: TRegistry;
begin
  reg := TRegistry.Create(KEY_READ);
  reg.RootKey := HKEY_CURRENT_USER;
  key := 'Software\CandBox\Netswitch\';
  if (not reg.KeyExists(key)) then begin
      reg.Access := KEY_WRITE;
      reg.OpenKey(key,True);
      reg.WriteInteger('Xpos',Menuxy.x);
      reg.WriteInteger('Ypos',Menuxy.y);
    end
  else begin
       if reg.KeyExists(key) then begin
        reg.Access := KEY_WRITE;
        reg.OpenKey(key,True);
        reg.WriteInteger('Xpos',Menuxy.x);
        reg.WriteInteger('Ypos',Menuxy.y);
       end;
  end;
  reg.CloseKey();
  reg.Free;
end;

procedure TApp.Loadplace;
begin
   if ((Menuxy.x>0) and (Menuxy.x < screen.Width)) and ((Menuxy.y>0) and (Menuxy.y<Screen.Height)) then
    self.SetBounds(Menuxy.x,Menuxy.y,width,height)
   else
    self.SetBounds((Screen.Width div 2)-(self.Width div 2),0,width,height);
end;

procedure TApp.Loadregistry(Data: PtrInt);
var
  key        : String;
  reg        : TRegistry;
  openResult : Boolean;
begin
  reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  reg.RootKey := HKEY_CURRENT_USER;
  key := 'Software\CandBox\Netswitch\';
  openResult := False;
  if not(reg.KeyExists(key)) then begin
      //reg.Access := KEY_WRITE;
      openResult := reg.OpenKey(key,True);
      if not(openResult = True) then Exit();
      if not(reg.KeyExists('Opentime')) then
        reg.WriteDateTime('Opentime',ScanDateTime('yyyy-mm-dd hh:nn:ss',FormatDateTime('YYYY-MM-DD',now)+' 09:05:00'));
      if not(reg.KeyExists('Closetime')) then
        reg.WriteDateTime('Closetime',ScanDateTime('yyyy-mm-dd hh:nn:ss',FormatDateTime('YYYY-MM-DD',now)+' 16:35:00'));
      if not(reg.KeyExists('Adapter')) then
        reg.WriteString('Adapter','');
      if not reg.KeyExists('Langs') then
        reg.WriteString('Langs','en');
      if not reg.KeyExists('Xpos') then
        reg.WriteInteger('Xpos',0);
      if not reg.KeyExists('Ypos') then
        reg.WriteInteger('Ypos',0);
      if not reg.KeyExists('Repeat') then
        reg.WriteInteger('Repeat',0);
  end;
    { here mean is Exists key path }
  if reg.OpenKey(key,False) then begin
        if not(reg.ValueExists('Opentime')) then
        reg.WriteDateTime('Opentime',ScanDateTime('yyyy-mm-dd hh:nn:ss',FormatDateTime('YYYY-MM-DD',now)+' 09:05:00'));
        if not(reg.ValueExists('Closetime')) then
        reg.WriteDateTime('Closetime',ScanDateTime('yyyy-mm-dd hh:nn:ss',FormatDateTime('YYYY-MM-DD',now)+' 16:35:00'));
        if not(reg.ValueExists('Adapter')) then
        reg.WriteString('Adapter','');
        if not(reg.ValueExists('Langs')) then
        reg.WriteString('Langs','en');
        if not(reg.ValueExists('Xpos')) then
        reg.WriteInteger('Xpos',0);
        if not(reg.ValueExists('Ypos')) then
        reg.WriteInteger('Ypos',0);
        if not reg.ValueExists('Repeat') then
        reg.WriteInteger('Repeat',0);
  end;
  reg.CloseKey();
  reg.Free;
  { here load setting value }
  Menuxy:=Panel1.ClientOrigin;
  Loadsetting;
end;

function TApp.Loadsetting:Boolean;
var
  reg : TRegistry;
  key : String;
  x,y: Integer;
begin
   x:=0;
   y:=0;
   reg := TRegistry.Create(KEY_READ);
   reg.RootKey := HKEY_CURRENT_USER;
   key := 'Software\CandBox\Netswitch\';
   if reg.openKey(key,false) then begin
     if reg.ValueExists('Langs') then langs:= reg.ReadString('Langs');
     if reg.ValueExists('Opentime') then opentime:= reg.ReadDateTime('Opentime');
     if reg.ValueExists('Closetime') then closetime:= reg.ReadDateTime('Closetime');
     if reg.ValueExists('Adapter') then adapter:= reg.ReadString('Adapter');
     if reg.ValueExists('Xpos') then x:= reg.ReadInteger('Xpos');
     if reg.ValueExists('Ypos') then y:= reg.ReadInteger('Ypos');
     if reg.ValueExists('Repeat') then renow:= reg.ReadInteger('Repeat');
     if Length(adapter) > 50 then adapter:= Copy(adapter,1,50);
     if Length(langs) > 5 then langs:= Copy(langs,1,5);
     if ((x>0) and (x < screen.Width)) and ((y>0) and (y<Screen.Height)) then begin
         Menuxy.x:=x;
         Menuxy.y:=y;
     end;
   end;
   result:= True;
   reg.CloseKey();
   reg.Free;
   { Start the timer }
   Loadplace;
   Timer1.Enabled := True;
   Application.QueueAsyncCall(@Loadadapter,0);
end;

//NetConnectionStatus:0 = Diconnected
//NetConnectionStatus:1 = Connecting
//NetConnectionStatus:2 = Connected
//NetConnectionStatus:3 = Diconnecting

procedure TApp.Loadadapter(Data: PtrInt);
var
  state: Integer;
  Locator: Variant;
  WMIService: Variant;
  colWMI: Variant;
  oEnumWMI : IEnumvariant;
  objWMI        : OLEVariant;
  nrValue       : LongWord;
  nr            : LongWord absolute nrValue;
begin
  state:=0;
  CoInitialize(nil);
 if length(adapter) > 0 then begin
   try
     // Create WMI locator
    Locator := CreateOleObject('WbemScripting.SWbemLocator');
    // Connect to WMI service
    WMIService := Locator.ConnectServer('localhost', 'root\CIMV2');
    colWMI := WMIService.ExecQuery('SELECT * FROM Win32_NetworkAdapter WHERE PhysicalAdapter = TRUE');
    oEnumWMI := IUnknown(colWMI._NewEnum) as IEnumVariant;
    while oEnumWMI.Next(1, objWMI, nr) = 0 do
     if objWMI.NetConnectionID = adapter then begin
         if ((objWMI.NetConnectionStatus = '0') or (objWMI.NetConnectionStatus = '3')) then begin
           state:=1;
         end
         else begin
           state:=2;
         end;
       end;
   finally
     CoUninitialize;
   end;
   Image1.ImageIndex:= state;
 end;
end;

function TApp.Clearegistry:Boolean;
var
  reg : TRegistry;
begin
  reg := TRegistry.Create(KEY_WRITE);
  reg.RootKey := HKEY_CURRENT_USER;
  reg.DeleteKey('Software\CandBox\Netswitch');
  reg.DeleteKey('Software\CandBox');
  reg.CloseKey();
  reg.Free;
  result:= True;
end;

procedure TApp.ShowSettings;
var
 SetForm: TSetForm;
 widthset: Integer;
 sidewidht: Integer;
begin
 SetForm:=TSetForm.Create(self);
 widthset:=304;
 sidewidht:=5;
 if not(Win32MajorVersion<=6) then begin
   widthset:=318;
   sidewidht:=-2;
 end;
 Setform.SetBounds(App.Left+sidewidht,App.Top+42,widthset,190);
 try
   SetForm.ShowModal;
 finally
   SetForm.Free;
 end;
end;

procedure TApp.ShowAbout;
var
 AbtForm: TAbtform;
 widthset: integer;
 sidewidht: integer;
begin
 AbtForm:=TAbtform.Create(self);
 widthset:=304;
 sidewidht:=5;
 if not(Win32MajorVersion<=6) then begin
   widthset:=318;
   sidewidht:=-2;
 end;
 AbtForm.SetBounds(App.Left+sidewidht,App.Top+42,widthset,190);
 try
   AbtForm.ShowModal;
 finally
   AbtForm.Free;
 end;
end;

procedure TApp.AlwaysTopClick(Sender: TObject);
begin
   if Formstyle = fsSystemStayOnTop then Formstyle:=fsNormal
   else Formstyle:=fsSystemStayOnTop;
end;
end.

