{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_webrtc;

{$warn 5023 off : no warning about unused units}
interface

uses
  aiwebrtc_libdatachannel, aiwebrtc_client, openai_webrtc_paletteicons,
  LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aiwebrtc_client', @aiwebrtc_client.Register);
end;

initialization
  RegisterPackage('openai_webrtc', @Register);
end.
