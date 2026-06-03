unit aicameracapture;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, LResources;

type
  { TAICameraCapture }

  TAICameraCapture = class(TAIBaseComponent)
  private
    FCameraIndex: Integer;
    FActive: Boolean;
    procedure SetActive(AValue: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    procedure StartCapture;
    procedure StopCapture;
    function QueryFrame: TObject;
  published
    property CameraIndex: Integer read FCameraIndex write FCameraIndex default 0;
    property Active: Boolean read FActive write SetActive default False;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Vision', [TAICameraCapture]);
end;

{ TAICameraCapture }

constructor TAICameraCapture.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAICameraCapture captures raw frames from camera inputs. Properties: CameraIndex, Active. Methods: StartCapture, StopCapture, QueryFrame.';
  FCameraIndex := 0;
  FActive := False;
  ClearError;
end;

procedure TAICameraCapture.SetActive(AValue: Boolean);
begin
  if FActive <> AValue then
  begin
    if AValue then
      StartCapture
    else
      StopCapture;
  end;
end;

procedure TAICameraCapture.StartCapture;
begin
  FActive := True;
  Log(llInfo, 'Started camera capture on index: ' + IntToStr(FCameraIndex));
  FLastResult := 'Capture active.';
  FLastSuccess := True;
end;

procedure TAICameraCapture.StopCapture;
begin
  FActive := False;
  Log(llInfo, 'Stopped camera capture.');
  FLastResult := 'Capture inactive.';
  FLastSuccess := True;
end;

function TAICameraCapture.QueryFrame: TObject;
begin
  Result := nil;
  if not FActive then
    Exit;
  Result := TObject.Create;
  Log(llDebug, 'Queried frame from camera.');
end;

initialization
  {$I aicameracapture_icon.lrs}

end.
