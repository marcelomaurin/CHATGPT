{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_input;

{$warn 5023 off : no warning about unused units}
interface

uses
  aiinput, aiaudio, aicapturesource, aiwebserver, aisockets, aiserial, 
  ailistserialdevices, aiserialfingerprint, aiemail, aimessenger, 
  aichromiumbrowser, aiusb, aiusb_register, aikinect_types, aikinect_backend, 
  aikinect_freenect, aikinect_sdk10, aikinectsensor, aikinectcolor, 
  aikinectdepth, aikinectskeleton, aikinectaudio, LazarusPackageIntf;

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
  RegisterUnit('aiusb_register', @aiusb_register.Register);
  RegisterUnit('aikinectsensor', @aikinectsensor.Register);
  RegisterUnit('aikinectcolor', @aikinectcolor.Register);
  RegisterUnit('aikinectdepth', @aikinectdepth.Register);
  RegisterUnit('aikinectskeleton', @aikinectskeleton.Register);
  RegisterUnit('aikinectaudio', @aikinectaudio.Register);
end;

initialization
  RegisterPackage('openai_input', @Register);
end.
