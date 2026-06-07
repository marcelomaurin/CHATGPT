{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_input;

{$warn 5023 off : no warning about unused units}
interface

uses
  aiinput, aicapturesource, aiwebserver, aisockets, aiserial, aiemail, 
  aimessenger, aichromiumbrowser, aiaudio, aimodbus, aimqtt, aiindustrial, 
  aiposprinter, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aiinput', @aiinput.Register);
  RegisterUnit('aicapturesource', @aicapturesource.Register);
  RegisterUnit('aiwebserver', @aiwebserver.Register);
  RegisterUnit('aisockets', @aisockets.Register);
  RegisterUnit('aiserial', @aiserial.Register);
  RegisterUnit('aiemail', @aiemail.Register);
  RegisterUnit('aimessenger', @aimessenger.Register);
  RegisterUnit('aichromiumbrowser', @aichromiumbrowser.Register);
  RegisterUnit('aiaudio', @aiaudio.Register);
  RegisterUnit('aimodbus', @aimodbus.Register);
  RegisterUnit('aimqtt', @aimqtt.Register);
  RegisterUnit('aiindustrial', @aiindustrial.Register);
  RegisterUnit('aiposprinter', @aiposprinter.Register);
end;

initialization
  RegisterPackage('openai_input', @Register);
end.
