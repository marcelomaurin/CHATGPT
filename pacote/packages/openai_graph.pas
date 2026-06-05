{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_graph;

{$warn 5023 off : no warning about unused units}
interface

uses
  aigraphmap, aitrainingexporter, aidatasetanalyzer, aitrainingreport, 
  aigraphvisualizer, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aigraphmap', @aigraphmap.Register);
  RegisterUnit('aitrainingexporter', @aitrainingexporter.Register);
  RegisterUnit('aidatasetanalyzer', @aidatasetanalyzer.Register);
  RegisterUnit('aitrainingreport', @aitrainingreport.Register);
  RegisterUnit('aigraphvisualizer', @aigraphvisualizer.Register);
end;

initialization
  RegisterPackage('openai_graph', @Register);
end.
