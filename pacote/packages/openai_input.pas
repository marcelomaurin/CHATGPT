{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_input;

{$warn 5023 off : no warning about unused units}
interface

uses
  aiinput, aicamera, aiwebserver, aisockets, aiserial, aicftvip, aiemail, 
  aimessenger, aichromiumbrowser, aioscapture, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aiinput', @aiinput.Register);
  RegisterUnit('aicamera', @aicamera.Register);
  RegisterUnit('aiwebserver', @aiwebserver.Register);
  RegisterUnit('aisockets', @aisockets.Register);
  RegisterUnit('aiserial', @aiserial.Register);
  RegisterUnit('aicftvip', @aicftvip.Register);
  RegisterUnit('aiemail', @aiemail.Register);
  RegisterUnit('aimessenger', @aimessenger.Register);
  RegisterUnit('aichromiumbrowser', @aichromiumbrowser.Register);
  RegisterUnit('aioscapture', @aioscapture.Register);
end;

initialization
  RegisterPackage('openai_input', @Register);
end.
