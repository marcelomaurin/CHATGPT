{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_graph;

{$warn 5023 off : no warning about unused units}
interface

uses
  aidependencygraph, aigraphmap, aigraphstructuraladapter, aitrainingexporter, 
  aidatasetanalyzer, aitrainingreport, aigraphvisualizer, airoutegraph_types, 
  airoutegraph_utils, airoutegraph, airoutespeedprofile, airoutecityindex, 
  airoutecalculator, aigeojsonrouteimporter, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aidependencygraph', @aidependencygraph.Register);
  RegisterUnit('aigraphmap', @aigraphmap.Register);
  RegisterUnit('aigraphstructuraladapter', @aigraphstructuraladapter.Register);
  RegisterUnit('aitrainingexporter', @aitrainingexporter.Register);
  RegisterUnit('aidatasetanalyzer', @aidatasetanalyzer.Register);
  RegisterUnit('aitrainingreport', @aitrainingreport.Register);
  RegisterUnit('aigraphvisualizer', @aigraphvisualizer.Register);
  RegisterUnit('airoutegraph', @airoutegraph.Register);
  RegisterUnit('airoutespeedprofile', @airoutespeedprofile.Register);
  RegisterUnit('airoutecityindex', @airoutecityindex.Register);
  RegisterUnit('airoutecalculator', @airoutecalculator.Register);
  RegisterUnit('aigeojsonrouteimporter', @aigeojsonrouteimporter.Register);
end;

initialization
  RegisterPackage('openai_graph', @Register);
end.
