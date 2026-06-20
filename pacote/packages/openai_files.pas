{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_files;

{$warn 5023 off : no warning about unused units}
interface

uses
  aidiskitem, aidisktreescanner, ai_docfilesmanager, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aidisktreescanner', @aidisktreescanner.Register);
  RegisterUnit('ai_docfilesmanager', @ai_docfilesmanager.Register);
end;

initialization
  RegisterPackage('openai_files', @Register);
end.
