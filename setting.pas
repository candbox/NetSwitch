unit setting;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ActiveX, Registry,
  ComObj, Variants, Spin, ExtCtrls, CheckLst, DateUtils;

type

  { TSetForm }

  TSetForm = class(TForm)
    BtnDisable: TButton;
    BtnEnable: TButton;
    Btnsetsave: TButton;
    AdapList: TCheckListBox;
    CheckBox1: TCheckBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Spinentimehour: TSpinEdit;
    Spindistimehour: TSpinEdit;
    Spinentimemins: TSpinEdit;
    Spindistimemins: TSpinEdit;
    procedure BtnsetsaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BtnEnableClick(Sender: TObject);
    procedure BtnDisableClick(Sender: TObject);
    procedure CheckListBoxHandler(Sender: TObject; Index: integer);
    procedure SaveTimeToReg(const KeyName: string; const TimeValue: TDateTime);
    procedure SaveStrToReg(const KeyName: string; const Values: String);
    procedure SaveRepartToReg(const KeyName: string; const Renow: Integer);
  private
    procedure ListNetworkAdapters;
    procedure ManageNetworkAdapter(const AdapterName: string; Enable: Boolean);
    procedure EnableAdapter(AdapterName: string);
    procedure DisableAdapter(AdapterName: string);
  public

  end;

var
  SetForm: TSetForm;

implementation
uses fmain;

{$R *.lfm}

{ TSetForm }

procedure TSetForm.FormCreate(Sender: TObject);
begin
   ListNetworkAdapters;
   Spinentimehour.Value := HourOf(fmain.opentime);
   Spinentimemins.Value := MinuteOf(fmain.opentime);
   Spindistimehour.Value := HourOf(fmain.closetime);
   Spindistimemins.Value := MinuteOf(fmain.closetime);
   if fmain.renow > 0 then CheckBox1.checked:= True else CheckBox1.checked:= False;
   if Adaplist.Items.IndexOf(fmain.adapter) <> -1 then
     begin
        Adaplist.Checked[Adaplist.Items.IndexOf(fmain.adapter)] := True;
     end;
end;

procedure TSetForm.CheckListBoxHandler(Sender: TObject; Index: integer);
var
   clb: TCheckListBox;
   i: Integer;
begin
   if not(Sender is TCheckListBox) then exit;
   clb := TCheckListBox(sender);
    for i:= 0 to clb.Items.Count-1 do begin
    if i=Index then begin
     continue;
    end;
    if clb.Checked[i] then
     clb.Checked[i] := not clb.Checked[i];
    end;
end;

procedure TSetForm.BtnsetsaveClick(Sender: TObject);
var
  onh,onm,ofh,ofm: String;
  ontime,oftime: TTime;
  isrepart: Integer;
begin
   isrepart:=0;
   if CheckBox1.Checked then isrepart:=1;

   {setting enabled timer}
   onh := IntToStr(Spinentimehour.value);
   if length(onh) < 2 then onh := '0' + onh;
   onm := IntToStr(Spinentimemins.value);
   if length(onm) < 2 then onm := '0' + onm;
   ontime := StrToDateTime(onh + ':' + onm);
   ontime := ScanDateTime('yyyy-mm-dd hh:nn:ss',FormatDateTime('YYYY-MM-DD',now) + ' ' + FormatDateTime('hh:nn:ss',ontime));
   {setting disabled timer}
   ofh := IntToStr(Spindistimehour.value);
   if length(ofh) < 2 then ofh := '0' + ofh;
   ofm := IntToStr(Spindistimemins.value);
   if length(ofm) < 2 then ofm := '0' + ofm;
   oftime := StrToDateTime(ofh + ':' + ofm);
   oftime := ScanDateTime('yyyy-mm-dd hh:nn:ss',FormatDateTime('YYYY-MM-DD',now)+' '+FormatDateTime('hh:nn:ss',oftime));
   { reset the action state }
   if not(ontime = fmain.opentime) then fmain.ennow:=False;
   if not(oftime = fmain.closetime) then fmain.dsnow:=False;

   {two timer can not equal}

   if (ontime = oftime) then begin
     ShowMessage('The timer can not setting same');
     exit;
   end
   else begin
     {wirte to reg }
     SaveTimeToReg('Opentime',ontime);
     SaveTimeToReg('Closetime',oftime);
     SaveRepartToReg('Repeat', isrepart);
     fmain.opentime:=ontime;
     fmain.closetime:=oftime;
     fmain.renow:=isrepart;
   if AdapList.ItemIndex >= 0 then
      if AdapList.Checked[AdapList.ItemIndex] then begin
        SaveStrToReg('Adapter',AdapList.Items[AdapList.ItemIndex]);
        fmain.adapter:=AdapList.Items[AdapList.ItemIndex];
        end
       else begin
          ShowMessage('Not checked the adapters ✔︎');
          exit;
       end;
   end;
   close;
end;

{datetime type reg save}
procedure TSetForm.SaveTimeToReg(const KeyName: string; const TimeValue: TDateTime);
var
  key        : String;
  reg        : TRegistry;
begin
  reg := TRegistry.Create(KEY_READ);
  reg.RootKey := HKEY_CURRENT_USER;
  key := 'Software\CandBox\Netswitch\';
  if (not reg.KeyExists(key)) then begin
      reg.Access := KEY_WRITE;
      reg.OpenKey(key,True);
      reg.WriteDateTime(KeyName,TimeValue);
    end
  else begin
       if reg.KeyExists(key) then begin
        reg.Access := KEY_WRITE;
        reg.OpenKey(key,True);
        reg.WriteDateTime(KeyName,TimeValue);
       end;
  end;
  reg.CloseKey();
  reg.Free;
end;

{string type reg save}
procedure TSetForm.SaveStrToReg(const KeyName: string; const Values: String);
var
  key        : String;
  reg        : TRegistry;
begin
  reg := TRegistry.Create(KEY_READ);
  reg.RootKey := HKEY_CURRENT_USER;
  key := 'Software\CandBox\Netswitch\';
  if (not reg.KeyExists(key)) then begin
      reg.Access := KEY_WRITE;
      reg.OpenKey(key,True);
      reg.WriteString(KeyName,Values);
    end
  else begin
       if reg.KeyExists(key) then begin
        reg.Access := KEY_WRITE;
        reg.OpenKey(key,True);
        reg.WriteString(KeyName,Values);
       end;
  end;
  reg.CloseKey();
  reg.Free;
end;

{integer type reg save}
procedure TSetForm.SaveRepartToReg(const KeyName: string; const Renow: Integer);
var
  key        : String;
  reg        : TRegistry;
begin
  reg := TRegistry.Create(KEY_READ);
  reg.RootKey := HKEY_CURRENT_USER;
  key := 'Software\CandBox\Netswitch\';
  if (not reg.KeyExists(key)) then begin
      reg.Access := KEY_WRITE;
      reg.OpenKey(key,True);
      reg.WriteInteger(KeyName,Renow);
    end
  else begin
       if reg.KeyExists(key) then begin
        reg.Access := KEY_WRITE;
        reg.OpenKey(key,True);
        reg.WriteInteger(KeyName,Renow);
       end;
  end;
  reg.CloseKey();
  reg.Free;
end;

procedure TSetForm.BtnEnableClick(Sender: TObject);
begin
  if (AdapList.ItemIndex >= 0) then
    if AdapList.Checked[AdapList.ItemIndex] then
      EnableAdapter(AdapList.Items[AdapList.ItemIndex])
    else begin
          ShowMessage('Not checked the adapters ✔︎');
          exit;
       end;
end;

procedure TSetForm.BtnDisableClick(Sender: TObject);
begin
  if (AdapList.ItemIndex >= 0) then
    if AdapList.Checked[AdapList.ItemIndex] then
       DisableAdapter(AdapList.Items[AdapList.ItemIndex])
     else begin
          ShowMessage('Not checked the adapters ✔︎');
          exit;
       end;
end;

procedure TSetForm.ListNetworkAdapters;
var
  Locator: Variant;
  WMIService: Variant;
  colWMI: Variant;
  oEnumWMI      : IEnumvariant;
  objWMI        : OLEVariant;
  nrValue       : LongWord;
  nr            : LongWord absolute nrValue;
begin
   CoInitialize(nil);
  try
    // Create WMI locator
    Locator := CreateOleObject('WbemScripting.SWbemLocator');
    // Connect to WMI service
    WMIService   := Locator.ConnectServer('localhost', 'root\CIMV2');
    colWMI := WMIService.ExecQuery('SELECT * FROM Win32_NetworkAdapter WHERE PhysicalAdapter = TRUE');
    oEnumWMI := IUnknown(colWMI._NewEnum) as IEnumVariant;
    AdapList.Clear;
     while oEnumWMI.Next(1, objWMI, nr) = 0 do
     begin
        AdapList.Items.Add(objWMI.NetConnectionID);
     end;
  finally
     CoUninitialize;
  end;
end;

procedure TSetForm.ManageNetworkAdapter(const AdapterName: string; Enable: Boolean);
var
  Locator: Variant;
  WMIService: Variant;
  colWMI: Variant;
  oEnumWMI      : IEnumvariant;
  objWMI        : OLEVariant;
  nrValue       : LongWord;
  nr            : LongWord absolute nrValue;
begin
   CoInitialize(nil);
  try
    // Create WMI locator
    Locator := CreateOleObject('WbemScripting.SWbemLocator');
    // Connect to WMI service
    WMIService   := Locator.ConnectServer('localhost', 'root\CIMV2');
    colWMI := WMIService.ExecQuery('SELECT * FROM Win32_NetworkAdapter WHERE NetConnectionID = "' + AdapterName + '"');
    oEnumWMI := IUnknown(colWMI._NewEnum) as IEnumVariant;
     while oEnumWMI.Next(1, objWMI, nr) = 0 do
        begin
        if Enable then
          begin
           objWMI.Enable();
           fmain.App.Image1.ImageIndex:= 2;
           end
        else
         begin
           objWMI.Disable();
           fmain.App.Image1.ImageIndex:= 1;
         end;
     end;
  finally
     CoUninitialize;
  end;
end;

procedure TSetForm.EnableAdapter(AdapterName: string);
begin
  ManageNetworkAdapter(AdapterName,TRUE);
  fmain.App.Trayicon.BalloonTitle:= 'Network Adapter Message';
  fmain.App.Trayicon.BalloonHint:= 'The ' + AdapterName + ' has been enabled';
  fmain.App.TrayIcon.ShowBalloonHint;
end;

procedure TSetForm.DisableAdapter(AdapterName: string);
begin
  ManageNetworkAdapter(AdapterName,FALSE);
  fmain.App.Trayicon.BalloonTitle:= 'Network Adapter Message';
  fmain.App.Trayicon.BalloonHint:= 'The ' + AdapterName + ' has been disabled';
  fmain.App.TrayIcon.ShowBalloonHint;
end;

end.

