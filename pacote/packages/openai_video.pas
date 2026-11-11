{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_video;

{$warn 5023 off : no warning about unused units}
interface

uses
  aih264decoder, openai_video_paletteicons, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aih264decoder', @aih264decoder.Register);
end;

initialization
  RegisterPackage('openai_video', @Register);
end.
