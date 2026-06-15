{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_output;

{$warn 5023 off : no warning about unused units}
interface

uses
  aioutput, aioutput_docs, aiwordtypes, aiwordunits, aiwordpackage, aiwordxml, 
  aiwordrelationships, aiwordstyles, aiwordobjects, aiworddocument, aiwordviewer, 
  LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aioutput', @aioutput.Register);
  RegisterUnit('aioutput_docs', @aioutput_docs.Register);
  RegisterUnit('aiworddocument', @aiworddocument.Register);
  RegisterUnit('aiwordviewer', @aiwordviewer.Register);
end;

initialization
  RegisterPackage('openai_output', @Register);
end.
