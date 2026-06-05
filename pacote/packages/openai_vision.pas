{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_vision;

{$warn 5023 off : no warning about unused units}
interface

uses
  aiopencv, aicamera_backend, aicamera_vfw, aicamera_v4l2, aicameracapture, 
  aiframeprocessor, aifacetracker, aimotiontracker, aiimageinfo, 
  aiframebuffer, ainativeimagefilter, aiframediff, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aiopencv', @aiopencv.Register);
  RegisterUnit('aicameracapture', @aicameracapture.Register);
  RegisterUnit('aiframeprocessor', @aiframeprocessor.Register);
  RegisterUnit('aifacetracker', @aifacetracker.Register);
  RegisterUnit('aimotiontracker', @aimotiontracker.Register);
  RegisterUnit('aiimageinfo', @aiimageinfo.Register);
  RegisterUnit('aiframebuffer', @aiframebuffer.Register);
  RegisterUnit('ainativeimagefilter', @ainativeimagefilter.Register);
  RegisterUnit('aiframediff', @aiframediff.Register);
end;

initialization
  RegisterPackage('openai_vision', @Register);
end.
