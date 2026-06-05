{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_image;

{$warn 5023 off : no warning about unused units}
interface

uses
  imagefilters, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('imagefilters', @imagefilters.Register);
end;

initialization
  RegisterPackage('openai_image', @Register);
end.
