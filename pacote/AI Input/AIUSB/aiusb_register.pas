unit aiusb_register;

{$mode objfpc}{$H+}

interface

uses
  Classes, aiusb, LResources;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Input', [TAIUSB]);
end;

initialization
  {$I aiusb_register_icon.lrs}

end.
