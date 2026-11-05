{ This file is used to compile and install the openai_webrtc package. }
unit openai_webrtc;

{$warn 5023 off : no warning about unused units}

interface

uses
  aiwebrtc_libdatachannel, aiwebrtc_client, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aiwebrtc_client', @aiwebrtc_client.Register);
end;

initialization
  RegisterPackage('openai_webrtc', @Register);
end.
