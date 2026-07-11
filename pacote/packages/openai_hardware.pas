{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_hardware;

{$warn 5023 off : no warning about unused units}
interface

uses
  aicpu, aimemory, aigpu, aidisk, aiso, ai_tasks, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aicpu', @aicpu.Register);
  RegisterUnit('aimemory', @aimemory.Register);
  RegisterUnit('aigpu', @aigpu.Register);
  RegisterUnit('aidisk', @aidisk.Register);
  RegisterUnit('aiso', @aiso.Register);
  RegisterUnit('ai_tasks', @ai_tasks.Register);
end;

initialization
  RegisterPackage('openai_hardware', @Register);
end.
