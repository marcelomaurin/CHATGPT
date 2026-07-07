unit aiusb_register;

{$mode objfpc}{$H+}

interface

uses
  Classes, aiusb;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Input', [TAIUSB]);
end;

end.
