unit about;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TAbtform }

  TAbtform = class(TForm)
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  Abtform: TAbtform;

implementation

{$R *.lfm}

{ TAbtform }


procedure TAbtform.FormCreate(Sender: TObject);
begin

end;

end.

