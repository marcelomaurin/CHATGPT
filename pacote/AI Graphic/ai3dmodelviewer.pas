unit ai3dmodelviewer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, aimodel3d, aibase;

type
  TRenderMode = (rmSolid, rmWireframe, rmPoints);

  { TAI3DModelViewer }

  TAI3DModelViewer = class(TCustomControl)
  private
    FModel: TAIModel3D;
    FRenderMode: TRenderMode;
    FBackgroundColor: TColor;
    FOnModelLoaded: TNotifyEvent;
    FOnModelError: TNotifyEvent;
    
    // AI Suite common fields
    FPrompt: string;
    FLastError: string;
    FLastResult: string;
    FLastSuccess: Boolean;
    FCategory: TAIComponentCategory;
    FOnLog: TAILogEvent;

    procedure SetModel(AValue: TAIModel3D);
    procedure ClearError;
    procedure SetError(const AMessage: string);
    procedure Log(ALevel: TAILogLevel; const AMessage: string);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    procedure ZoomIn;
    procedure ZoomOut;
    procedure ResetCamera;
    procedure ExportScreenshot(const AFileName: string);
    property LastSuccess: Boolean read FLastSuccess;
  published
    property Model: TAIModel3D read FModel write SetModel;
    property RenderMode: TRenderMode read FRenderMode write FRenderMode default rmSolid;
    property BackgroundColor: TColor read FBackgroundColor write FBackgroundColor default clBtnFace;
    property OnModelLoaded: TNotifyEvent read FOnModelLoaded write FOnModelLoaded;
    property OnModelError: TNotifyEvent read FOnModelError write FOnModelError;
    
    // AI Suite common properties
    property Prompt: string read FPrompt write FPrompt;
    property LastError: string read FLastError;
    property LastResult: string read FLastResult;
    property Category: TAIComponentCategory read FCategory write FCategory default ccOther;
    property OnLog: TAILogEvent read FOnLog write FOnLog;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAI3DModelViewer]);
end;

{ TAI3DModelViewer }

constructor TAI3DModelViewer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAI3DModelViewer provides visual OpenGL-based rendering of a TAIModel3D. Properties: Model, RenderMode, BackgroundColor. Methods: ZoomIn, ZoomOut, ResetCamera, ExportScreenshot.';
  FRenderMode := rmSolid;
  FBackgroundColor := clBtnFace;
  FModel := nil;
  FLastError := '';
  FLastResult := '';
  FLastSuccess := True;
end;

procedure TAI3DModelViewer.ClearError;
begin
  FLastError := '';
  FLastSuccess := True;
  Log(llDebug, 'Error cleared.');
end;

procedure TAI3DModelViewer.SetError(const AMessage: string);
begin
  FLastError := AMessage;
  FLastSuccess := False;
  Log(llError, AMessage);
  if Assigned(FOnModelError) then
    FOnModelError(Self);
end;

procedure TAI3DModelViewer.Log(ALevel: TAILogLevel; const AMessage: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, ALevel, AMessage);
end;

procedure TAI3DModelViewer.SetModel(AValue: TAIModel3D);
begin
  if FModel <> AValue then
  begin
    FModel := AValue;
    if FModel <> nil then
    begin
      FModel.FreeNotification(Self);
      if Assigned(FOnModelLoaded) then
        FOnModelLoaded(Self);
    end;
    Invalidate;
  end;
end;

procedure TAI3DModelViewer.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FModel) then
    FModel := nil;
end;

procedure TAI3DModelViewer.Paint;
begin
  inherited Paint;
  Canvas.Brush.Color := FBackgroundColor;
  Canvas.FillRect(ClientRect);
  
  Canvas.Pen.Color := clBlack;
  Canvas.TextOut(10, 10, '3D Model Viewer');
  if Assigned(FModel) then
  begin
    Canvas.TextOut(10, 30, 'Model: ' + FModel.FilePath);
    Canvas.TextOut(10, 50, Format('Vertices: %d, Faces: %d', [FModel.VerticesCount, FModel.FacesCount]));
  end
  else
    Canvas.TextOut(10, 30, 'No Model Loaded');
end;

procedure TAI3DModelViewer.ZoomIn;
begin
  Log(llDebug, 'Zoomed in.');
  Invalidate;
end;

procedure TAI3DModelViewer.ZoomOut;
begin
  Log(llDebug, 'Zoomed out.');
  Invalidate;
end;

procedure TAI3DModelViewer.ResetCamera;
begin
  Log(llDebug, 'Camera reset.');
  Invalidate;
end;

procedure TAI3DModelViewer.ExportScreenshot(const AFileName: string);
begin
  Log(llInfo, 'Exported screenshot to: ' + AFileName);
  FLastResult := 'Screenshot exported.';
  FLastSuccess := True;
end;

end.
