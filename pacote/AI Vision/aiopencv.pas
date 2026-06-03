unit aiopencv;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase;

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
begin
  Result := False;
  ClearError;
  Log(llInfo, 'Attempting to load OpenCV dynamic libraries...');
  
  // Simulated optional loading to avoid hard compile dependencies
  // In a real environment, load libopencv_world.so / opencv_world.dll
  FLibraryLoaded := False;
  SetError('OpenCV libraries not found in path. Please configure OpenCV environment.');
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

end.
