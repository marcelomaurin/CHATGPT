{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_output;

{$warn 5023 off : no warning about unused units}
interface

uses
  aioutput, aioutput_docs, aiwordtypes, aiwordunits, aiwordpackage, aiwordxml, 
  aiwordrelationships, aiwordstyles, aiwordobjects, aiworddocument, aiwordviewer, 
  aiprinter_types, aiprinter_bytebuilder, aiprinter_profile, aiprinter_transport, 
  aiprinter_transport_tcp, aiprinter_transport_serial, aiprinter_transport_file, 
  aiprinter_language_base, aiprinter_language_escpos, aiprinter_language_zpl, 
  aiprinter_language_tspl, aiprinter_language_epl, 
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
