{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit ai_files;

{$warn 5023 off : no warning about unused units}
interface

uses
  aidiskitem, aidisktreescanner, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aidisktreescanner', @aidisktreescanner.Register);
end;

initialization
  RegisterPackage('ai_files', @Register);
end.
