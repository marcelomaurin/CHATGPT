program AIChromiumBrowser_Test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, aichromiumbrowser_test_main, uCEFApplication, aichromiumbrowser;

{$R *.res}

begin
  GlobalCEFApp := TCefApplication.Create;

  if GlobalCEFApp.StartMainProcess then
  begin
    RequireDerivedFormResource:=True;
    Application.Scaled:=True;
    Application.Initialize;
    Application.CreateForm(TfrmMain, frmMain);
    Application.Run;
  end;

  GlobalCEFApp.Free;
end.
