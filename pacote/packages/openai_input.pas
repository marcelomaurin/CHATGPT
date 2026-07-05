{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_input;

{$warn 5023 off : no warning about unused units}
interface

uses
  aiinput, aiaudio, aicapturesource, aiwebserver, aisockets, aiserial, 
  ailistserialdevices, aiemail, aimessenger, aichromiumbrowser, 
  LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aiinput', @aiinput.Register);
  RegisterUnit('aiaudio', @aiaudio.Register);
  RegisterUnit('aicapturesource', @aicapturesource.Register);
  RegisterUnit('aiwebserver', @aiwebserver.Register);
  RegisterUnit('aisockets', @aisockets.Register);
  RegisterUnit('aiserial', @aiserial.Register);
  RegisterUnit('ailistserialdevices', @ailistserialdevices.Register);
  RegisterUnit('aiemail', @aiemail.Register);
  RegisterUnit('aimessenger', @aimessenger.Register);
  RegisterUnit('aichromiumbrowser', @aichromiumbrowser.Register);
end;

initialization
  RegisterPackage('openai_input', @Register);
end.
