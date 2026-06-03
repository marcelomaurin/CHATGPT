unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aiscene2d3d, ai3dmodelviewer, aimodel3d, aibase;

type

  { TfrmOpenGLGraphicDemo }

  TfrmOpenGLGraphicDemo = class(TForm)
    pnlLeft: TPanel;
    pnlScene: TPanel;
    lblSceneTitle: TLabel;
    btnPlay: TButton;
    btnPause: TButton;
    btnClearScene: TButton;
    chkGrid: TCheckBox;
    chkAxes: TCheckBox;
    cbSceneMode: TComboBox;
    btnExportJSON: TButton;
    
    pnlViewerOpts: TPanel;
    lblViewerTitle: TLabel;
    btnZoomIn: TButton;
    btnZoomOut: TButton;
    btnResetCamera: TButton;
    btnLoadModel: TButton;
    cbRenderMode: TComboBox;
    btnCreateTestSTL: TButton;
    
    meLogs: TMemo;
    lblLogs: TLabel;
    pnlViewClient: TPanel;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnPlayClick(Sender: TObject);
    procedure btnPauseClick(Sender: TObject);
    procedure btnClearSceneClick(Sender: TObject);
    procedure chkGridChange(Sender: TObject);
    procedure chkAxesChange(Sender: TObject);
    procedure cbSceneModeChange(Sender: TObject);
    procedure btnExportJSONClick(Sender: TObject);
    
    procedure btnZoomInClick(Sender: TObject);
    procedure btnZoomOutClick(Sender: TObject);
    procedure btnResetCameraClick(Sender: TObject);
    procedure btnLoadModelClick(Sender: TObject);
    procedure btnCreateTestSTLClick(Sender: TObject);
    procedure cbRenderModeChange(Sender: TObject);
    
    procedure ComponentLog(Sender: TObject; ALevel: TAILogLevel; const AMsg: string);
  private
    FScene: TAIScene2D3D;
    FViewer: TAI3DModelViewer;
    FModel: TAIModel3D;
    
    procedure LogMsg(const AMsg: string);
  public

  end;

var
  frmOpenGLGraphicDemo: TfrmOpenGLGraphicDemo;

implementation

{$R *.lfm}

{ TfrmOpenGLGraphicDemo }

procedure TfrmOpenGLGraphicDemo.FormCreate(Sender: TObject);
begin
  // 1. Instantiate components
  FScene := TAIScene2D3D.Create(Self);
  FModel := TAIModel3D.Create(Self);
  
  // 2. Create the TAI3DModelViewer dynamically on the client panel
  FViewer := TAI3DModelViewer.Create(Self);
  FViewer.Parent := pnlViewClient;
  FViewer.Align := alClient;
  FViewer.Model := FModel;

  // 3. Setup logs
  FScene.OnLog := @ComponentLog;
  FViewer.OnLog := @ComponentLog;
  FModel.OnLog := @ComponentLog;

  // Populate ComboBoxes
  cbSceneMode.Items.Clear;
  cbSceneMode.Items.Add('2D Mode');
  cbSceneMode.Items.Add('3D Mode');
  cbSceneMode.ItemIndex := 1;

  cbRenderMode.Items.Clear;
  cbRenderMode.Items.Add('Solid Rendering');
  cbRenderMode.Items.Add('Wireframe');
  cbRenderMode.Items.Add('Points');
  cbRenderMode.ItemIndex := 0;

  LogMsg('OpenGL Graphics Showcase initialized.');
end;

procedure TfrmOpenGLGraphicDemo.FormDestroy(Sender: TObject);
begin
  // Components are freed automatically by Owner (Self)
end;

procedure TfrmOpenGLGraphicDemo.ComponentLog(Sender: TObject; ALevel: TAILogLevel; const AMsg: string);
var
  Prefix: string;
begin
  case ALevel of
    llDebug: Prefix := '[DEBUG] ';
    llInfo: Prefix := '[INFO] ';
    llWarning: Prefix := '[WARNING] ';
    llError: Prefix := '[ERROR] ';
  end;
  LogMsg(Prefix + Sender.ClassName + ': ' + AMsg);
end;

procedure TfrmOpenGLGraphicDemo.LogMsg(const AMsg: string);
begin
  meLogs.Lines.Append('[' + FormatDateTime('hh:nn:ss.zzz', Now) + '] ' + AMsg);
end;

procedure TfrmOpenGLGraphicDemo.btnPlayClick(Sender: TObject);
begin
  LogMsg('Playing scene simulation...');
  FScene.Play;
end;

procedure TfrmOpenGLGraphicDemo.btnPauseClick(Sender: TObject);
begin
  LogMsg('Pausing scene simulation...');
  FScene.Pause;
end;

procedure TfrmOpenGLGraphicDemo.btnClearSceneClick(Sender: TObject);
begin
  LogMsg('Clearing scene objects...');
  FScene.Clear;
end;

procedure TfrmOpenGLGraphicDemo.chkGridChange(Sender: TObject);
begin
  FScene.GridVisible := chkGrid.Checked;
  LogMsg('Grid visibility set to: ' + BoolToStr(chkGrid.Checked, True));
end;

procedure TfrmOpenGLGraphicDemo.chkAxesChange(Sender: TObject);
begin
  FScene.AxesVisible := chkAxes.Checked;
  LogMsg('Axes visibility set to: ' + BoolToStr(chkAxes.Checked, True));
end;

procedure TfrmOpenGLGraphicDemo.cbSceneModeChange(Sender: TObject);
begin
  if cbSceneMode.ItemIndex = 0 then
    FScene.SceneMode := sm2D
  else
    FScene.SceneMode := sm3D;
  LogMsg('Scene Mode set to index: ' + IntToStr(cbSceneMode.ItemIndex));
end;

procedure TfrmOpenGLGraphicDemo.btnExportJSONClick(Sender: TObject);
var
  JSONData: string;
begin
  JSONData := FScene.ExportStateJSON;
  LogMsg('Exported Scene JSON:');
  LogMsg(JSONData);
end;

procedure TfrmOpenGLGraphicDemo.btnZoomInClick(Sender: TObject);
begin
  LogMsg('Zooming in...');
  FViewer.ZoomIn;
end;

procedure TfrmOpenGLGraphicDemo.btnZoomOutClick(Sender: TObject);
begin
  LogMsg('Zooming out...');
  FViewer.ZoomOut;
end;

procedure TfrmOpenGLGraphicDemo.btnResetCameraClick(Sender: TObject);
begin
  LogMsg('Resetting camera perspective...');
  FViewer.ResetCamera;
end;

procedure TfrmOpenGLGraphicDemo.btnLoadModelClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(nil);
  try
    OpenDlg.Title := 'Open STL or OBJ 3D Model';
    OpenDlg.Filter := '3D Models (*.stl;*.obj)|*.stl;*.obj|All Files (*.*)|*.*';
    if OpenDlg.Execute then
    begin
      LogMsg('Loading 3D model: ' + OpenDlg.FileName);
      FModel.LoadFromFile(OpenDlg.FileName);
      // Trigger update on viewer
      FViewer.Invalidate;
      LogMsg(Format('Model loaded. Vertices: %d, Faces: %d', [FModel.VerticesCount, FModel.FacesCount]));
    end;
  finally
    OpenDlg.Free;
  end;
end;

procedure TfrmOpenGLGraphicDemo.btnCreateTestSTLClick(Sender: TObject);
var
  STLPath: string;
  F: TextFile;
begin
  STLPath := ExtractFilePath(Application.ExeName) + 'test_model.stl';
  LogMsg('Generating test STL file at: ' + STLPath);
  try
    AssignFile(F, STLPath);
    Rewrite(F);
    WriteLn(F, 'solid test_pyramid');
    
    // Face 1 (Base Triangle 1)
    WriteLn(F, '  facet normal 0 0 -1');
    WriteLn(F, '    outer loop');
    WriteLn(F, '      vertex -1 -1 0');
    WriteLn(F, '      vertex 1 -1 0');
    WriteLn(F, '      vertex 1 1 0');
    WriteLn(F, '    endloop');
    WriteLn(F, '  endfacet');
    
    // Face 2 (Base Triangle 2)
    WriteLn(F, '  facet normal 0 0 -1');
    WriteLn(F, '    outer loop');
    WriteLn(F, '      vertex -1 -1 0');
    WriteLn(F, '      vertex 1 1 0');
    WriteLn(F, '      vertex -1 1 0');
    WriteLn(F, '    endloop');
    WriteLn(F, '  endfacet');
    
    // Face 3 (Side 1)
    WriteLn(F, '  facet normal -0.7 0 0.7');
    WriteLn(F, '    outer loop');
    WriteLn(F, '      vertex -1 -1 0');
    WriteLn(F, '      vertex 0 0 1.5');
    WriteLn(F, '      vertex -1 1 0');
    WriteLn(F, '    endloop');
    WriteLn(F, '  endfacet');
    
    // Face 4 (Side 2)
    WriteLn(F, '  facet normal 0 -0.7 0.7');
    WriteLn(F, '    outer loop');
    WriteLn(F, '      vertex -1 -1 0');
    WriteLn(F, '      vertex 1 -1 0');
    WriteLn(F, '      vertex 0 0 1.5');
    WriteLn(F, '    endloop');
    WriteLn(F, '  endfacet');
    
    // Face 5 (Side 3)
    WriteLn(F, '  facet normal 0.7 0 0.7');
    WriteLn(F, '    outer loop');
    WriteLn(F, '      vertex 1 -1 0');
    WriteLn(F, '      vertex 1 1 0');
    WriteLn(F, '      vertex 0 0 1.5');
    WriteLn(F, '    endloop');
    WriteLn(F, '  endfacet');
    
    // Face 6 (Side 4)
    WriteLn(F, '  facet normal 0 0.7 0.7');
    WriteLn(F, '    outer loop');
    WriteLn(F, '      vertex 1 1 0');
    WriteLn(F, '      vertex -1 1 0');
    WriteLn(F, '      vertex 0 0 1.5');
    WriteLn(F, '    endloop');
    WriteLn(F, '  endfacet');
    
    WriteLn(F, 'endsolid test_pyramid');
    CloseFile(F);
    
    LogMsg('Test STL file created successfully.');
    
    // Load the newly created model
    FModel.LoadFromFile(STLPath);
    FViewer.Invalidate;
    LogMsg(Format('Model loaded. Vertices: %d, Faces: %d', [FModel.VerticesCount, FModel.FacesCount]));
  except
    on E: Exception do
      LogMsg('Error generating/loading test STL: ' + E.Message);
  end;
end;

procedure TfrmOpenGLGraphicDemo.cbRenderModeChange(Sender: TObject);
begin
  case cbRenderMode.ItemIndex of
    0: FViewer.RenderMode := rmSolid;
    1: FViewer.RenderMode := rmWireframe;
    2: FViewer.RenderMode := rmPoints;
  end;
  LogMsg('Render mode set to index: ' + IntToStr(cbRenderMode.ItemIndex));
end;

end.
