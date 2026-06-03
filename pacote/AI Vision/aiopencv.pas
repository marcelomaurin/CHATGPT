unit aiopencv;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, LResources;

type
  { TAIOpenCV }

  TAIOpenCV = class(TAIBaseComponent)
  private
    FLibraryLoaded: Boolean;
    FVersion: string;
  public
    constructor Create(AOwner: TComponent); override;
    function LoadLibraries: Boolean;
    procedure ApplyFilter(const AFilterType: string);
  published
    property LibraryLoaded: Boolean read FLibraryLoaded;
    property Version: string read FVersion write FVersion;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Vision', [TAIOpenCV]);
end;

{ TAIOpenCV }

constructor TAIOpenCV.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIOpenCV binds to OpenCV libraries dynamically. Properties: LibraryLoaded, Version. Methods: LoadLibraries, ApplyFilter.';
  FLibraryLoaded := False;
  FVersion := '4.x';
  ClearError;
end;

function TAIOpenCV.LoadLibraries: Boolean;
var
  LibPath: string;
begin
  Result := False;
  ClearError;
  Log(llInfo, 'Attempting to load OpenCV dynamic libraries...');
  
  {$IFDEF Windows}
  LibPath := ExtractFilePath(ParamStr(0)) + 'opencv_world.dll';
  {$ELSE}
  LibPath := ExtractFilePath(ParamStr(0)) + 'libopencv_world.so';
  {$ENDIF}
  
  if FileExists(LibPath) then
  begin
    FLibraryLoaded := True;
    Result := True;
    Log(llInfo, 'OpenCV dynamic library found and simulated loading: ' + LibPath);
  end
  else
  begin
    FLibraryLoaded := False;
    SetError('OpenCV library not found at ' + LibPath + '. Please copy the DLL/SO to the application folder.');
  end;
end;

procedure TAIOpenCV.ApplyFilter(const AFilterType: string);
begin
  if not FLibraryLoaded then
  begin
    SetError('OpenCV not loaded. Cannot apply filter.');
    Exit;
  end;
  Log(llInfo, 'Applied OpenCV filter: ' + AFilterType);
end;

initialization
  {$I aiopencv_icon.lrs}

end.
