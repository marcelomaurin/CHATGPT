{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_python;

{$warn 5023 off : no warning about unused units}
interface

uses
  pythonconnector, aipythonruntime, facedetection, yolodetect, cnnclassifier, 
  lstmpredictor, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('pythonconnector', @pythonconnector.Register);
  RegisterUnit('aipythonruntime', @aipythonruntime.Register);
  RegisterUnit('facedetection', @facedetection.Register);
  RegisterUnit('yolodetect', @yolodetect.Register);
  RegisterUnit('cnnclassifier', @cnnclassifier.Register);
  RegisterUnit('lstmpredictor', @lstmpredictor.Register);
end;

initialization
  RegisterPackage('openai_python', @Register);
end.
