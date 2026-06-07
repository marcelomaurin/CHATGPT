unit aiframebuffer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, Graphics, contnrs, LResources;

type
  { TAIFrameBuffer }

  TAIFrameBuffer = class(TAIBaseComponent)
  private
    FMaxFrames: Integer;
    FList: TObjectList;
    function GetCount: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear;
    function AddFrame(ABitmap: TBitmap): Boolean;
    function AddFrameFromFile(const AFileName: string): Boolean;
    function GetFrame(AIndex: Integer): TBitmap;
    function GetLastFrame: TBitmap;
    function GetPreviousFrame: TBitmap;
  published
    property MaxFrames: Integer read FMaxFrames write FMaxFrames default 2;
    property Count: Integer read GetCount;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Native Vision', [TAIFrameBuffer]);
end;

{ TAIFrameBuffer }

constructor TAIFrameBuffer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIFrameBuffer manages in-memory bitmap circular buffers for video processing.';
  FMaxFrames := 2;
  FList := TObjectList.Create(True); // OwnsObjects := True
  ClearError;
end;

destructor TAIFrameBuffer.Destroy;
begin
  FList.Free;
  inherited Destroy;
end;

procedure TAIFrameBuffer.Clear;
begin
  FList.Clear;
  ClearError;
end;

function TAIFrameBuffer.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TAIFrameBuffer.AddFrame(ABitmap: TBitmap): Boolean;
var
  LCopy: TBitmap;
begin
  Result := False;
  ClearError;

  if not Assigned(ABitmap) then
  begin
    SetError('Bitmap parameter is nil.');
    Exit;
  end;

  if FMaxFrames <= 0 then
  begin
    SetError('MaxFrames must be greater than 0.');
    Exit;
  end;

  try
    LCopy := TBitmap.Create;
    try
      LCopy.Assign(ABitmap);
      FList.Add(LCopy);
      Result := True;
    except
      on E: Exception do
      begin
        LCopy.Free;
        SetError('Failed to copy frame: ' + E.Message);
        Exit;
      end;
    end;

    // Rescale list down to MaxFrames
    while FList.Count > FMaxFrames do
    begin
      FList.Delete(0); // This automatically frees the object at index 0 because OwnsObjects is True
    end;

    FLastSuccess := True;
  except
    on E: Exception do
    begin
      SetError('Exception in AddFrame: ' + E.Message);
    end;
  end;
end;

function TAIFrameBuffer.AddFrameFromFile(const AFileName: string): Boolean;
var
  LTempBmp: TBitmap;
  LPic: TPicture;
begin
  Result := False;
  ClearError;

  if AFileName = '' then
  begin
    SetError('Filename is empty.');
    Exit;
  end;

  if not FileExists(AFileName) then
  begin
    SetError('File does not exist: ' + AFileName);
    Exit;
  end;

  LPic := TPicture.Create;
  LTempBmp := TBitmap.Create;
  try
    try
      LPic.LoadFromFile(AFileName);
      LTempBmp.Assign(LPic.Graphic);
      Result := AddFrame(LTempBmp);
    except
      on E: Exception do
      begin
        SetError('Failed to load frame from file: ' + E.Message);
      end;
    end;
  finally
    LPic.Free;
    LTempBmp.Free;
  end;
end;

function TAIFrameBuffer.GetFrame(AIndex: Integer): TBitmap;
begin
  Result := nil;
  ClearError;

  if (AIndex < 0) or (AIndex >= FList.Count) then
  begin
    SetError('Frame index out of bounds.');
    Exit;
  end;

  Result := TBitmap(FList[AIndex]);
end;

function TAIFrameBuffer.GetLastFrame: TBitmap;
begin
  Result := nil;
  if FList.Count > 0 then
    Result := TBitmap(FList[FList.Count - 1])
  else
    SetError('Buffer is empty.');
end;

function TAIFrameBuffer.GetPreviousFrame: TBitmap;
begin
  Result := nil;
  if FList.Count > 1 then
    Result := TBitmap(FList[FList.Count - 2])
  else
    SetError('Buffer does not contain a previous frame.');
end;

initialization
  {$I aiframebuffer_icon.lrs}

end.
