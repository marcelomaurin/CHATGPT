unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, ai3dmodelviewer, aimodel3d;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    btnOpenModel: TButton;
    btnCube: TButton;
    btnPyramid: TButton;
    btnCylinder: TButton;
    lblRenderMode: TLabel;
    cmbRenderMode: TComboBox;
    btnZoomIn: TButton;
    btnZoomOut: TButton;
    btnResetCam: TButton;
    btnExport: TButton;
    pnlMain: TPanel;
    pnlViewerHost: TPanel;
    pnlRight: TPanel;
    grpStats: TGroupBox;
    lblStats: TLabel;
    grpControls: TGroupBox;
    btnRotX: TButton;
    btnRotY: TButton;
    btnRotZ: TButton;
    lblDragHint: TLabel;
    grpLog: TGroupBox;
    memoLog: TMemo;
    AIModel3D1: TAIModel3D;
    AI3DModelViewer1: TAI3DModelViewer;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnOpenModelClick(Sender: TObject);
    procedure btnCubeClick(Sender: TObject);
    procedure btnPyramidClick(Sender: TObject);
    procedure btnCylinderClick(Sender: TObject);
    procedure cmbRenderModeChange(Sender: TObject);
    procedure btnZoomInClick(Sender: TObject);
    procedure btnZoomOutClick(Sender: TObject);
    procedure btnResetCamClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure btnRotXClick(Sender: TObject);
    procedure btnRotYClick(Sender: TObject);
    procedure btnRotZClick(Sender: TObject);
    procedure OnModelLoadedHandler(Sender: TObject);
    procedure OnModelErrorHandler(Sender: TObject);
  private
    procedure AddLog(const AMsg: string);
    procedure UpdateModelStats;
    procedure GenerateCubeMesh;
    procedure GeneratePyramidMesh;
    procedure GenerateCylinderMesh;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  AddLog('Inicializando Model3D Viewer Demo (TAI3DModelViewer & TAIModel3D)...');
  
  // Gera cubo 3D inicial para visualização imediata
  GenerateCubeMesh;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Componentes limpos pelo LCL Owner
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(FormatDateTime('[hh:nn:ss] ', Now) + AMsg);
end;

procedure TfrmMain.UpdateModelStats;
begin
  if (AIModel3D1 = nil) or (AIModel3D1.FacesCount = 0) then
  begin
    lblStats.Caption := 'Nenhum modelo carregado.';
    Exit;
  end;

  lblStats.Caption := Format(
    'Arquivo: %s' + LineEnding +
    'Faces (Triângulos): %d' + LineEnding +
    'Vértices Calculados: %d' + LineEnding + LineEnding +
    'Dimensões da Malha:' + LineEnding +
    '  X: [%.2f .. %.2f]' + LineEnding +
    '  Y: [%.2f .. %.2f]' + LineEnding +
    '  Z: [%.2f .. %.2f]' + LineEnding + LineEnding +
    'Centro (Mid): (%.2f, %.2f, %.2f)' + LineEnding +
    'Raio Esférico: %.2f',
    [ExtractFileName(AIModel3D1.FilePath),
     AIModel3D1.FacesCount,
     AIModel3D1.VerticesCount,
     AIModel3D1.MinX, AIModel3D1.MaxX,
     AIModel3D1.MinY, AIModel3D1.MaxY,
     AIModel3D1.MinZ, AIModel3D1.MaxZ,
     AIModel3D1.MidX, AIModel3D1.MidY, AIModel3D1.MidZ,
     AIModel3D1.ModelRadius]
  );
end;

procedure TfrmMain.OnModelLoadedHandler(Sender: TObject);
begin
  AddLog('Evento OnModelLoaded: Modelo 3D carregado com sucesso!');
  UpdateModelStats;
end;

procedure TfrmMain.OnModelErrorHandler(Sender: TObject);
begin
  AddLog('Evento OnModelError: Erro ao carregar modelo.');
end;

procedure TfrmMain.btnOpenModelClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    AddLog('Carregando arquivo 3D: ' + OpenDialog1.FileName);
    try
      AIModel3D1.LoadFromFile(OpenDialog1.FileName);
      AI3DModelViewer1.ResetCamera;
      AI3DModelViewer1.Invalidate;
      UpdateModelStats;
      AddLog(Format('Sucesso: %d triângulos carregados.', [AIModel3D1.FacesCount]));
    except
      on E: Exception do
        AddLog('Erro ao carregar arquivo: ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.GenerateCubeMesh;
var
  TempFile: string;
  SL: TStringList;
begin
  AddLog('Gerando malha procedural: Cubo 3D...');
  TempFile := IncludeTrailingPathDelimiter(GetTempDir) + 'model3d_cube.obj';
  SL := TStringList.Create;
  try
    SL.Add('# Wavefront OBJ - 3D Cube');
    SL.Add('v -1.0 -1.0  1.0');
    SL.Add('v  1.0 -1.0  1.0');
    SL.Add('v  1.0  1.0  1.0');
    SL.Add('v -1.0  1.0  1.0');
    SL.Add('v -1.0 -1.0 -1.0');
    SL.Add('v  1.0 -1.0 -1.0');
    SL.Add('v  1.0  1.0 -1.0');
    SL.Add('v -1.0  1.0 -1.0');
    // Front face
    SL.Add('f 1 2 3');
    SL.Add('f 1 3 4');
    // Back face
    SL.Add('f 6 5 8');
    SL.Add('f 6 8 7');
    // Top face
    SL.Add('f 4 3 7');
    SL.Add('f 4 7 8');
    // Bottom face
    SL.Add('f 5 6 2');
    SL.Add('f 5 2 1');
    // Right face
    SL.Add('f 2 6 7');
    SL.Add('f 2 7 3');
    // Left face
    SL.Add('f 5 1 4');
    SL.Add('f 5 4 8');
    SL.SaveToFile(TempFile);
  finally
    SL.Free;
  end;

  AIModel3D1.LoadFromFile(TempFile);
  AIModel3D1.FilePath := 'Cubo_Procedural.obj';
  AI3DModelViewer1.ResetCamera;
  AI3DModelViewer1.Invalidate;
  UpdateModelStats;
  AddLog('Cubo 3D pronto para visualização e rotação interativa.');
end;

procedure TfrmMain.GeneratePyramidMesh;
var
  TempFile: string;
  SL: TStringList;
begin
  AddLog('Gerando malha procedural: Pirâmide 3D...');
  TempFile := IncludeTrailingPathDelimiter(GetTempDir) + 'model3d_pyramid.obj';
  SL := TStringList.Create;
  try
    SL.Add('# Wavefront OBJ - 3D Pyramid');
    SL.Add('v  0.0  1.5  0.0'); // Apex (1)
    SL.Add('v -1.0 -1.0  1.0'); // Base FL (2)
    SL.Add('v  1.0 -1.0  1.0'); // Base FR (3)
    SL.Add('v  1.0 -1.0 -1.0'); // Base BR (4)
    SL.Add('v -1.0 -1.0 -1.0'); // Base BL (5)
    // Front
    SL.Add('f 1 2 3');
    // Right
    SL.Add('f 1 3 4');
    // Back
    SL.Add('f 1 4 5');
    // Left
    SL.Add('f 1 5 2');
    // Base
    SL.Add('f 2 5 4');
    SL.Add('f 2 4 3');
    SL.SaveToFile(TempFile);
  finally
    SL.Free;
  end;

  AIModel3D1.LoadFromFile(TempFile);
  AIModel3D1.FilePath := 'Piramide_Procedural.obj';
  AI3DModelViewer1.ResetCamera;
  AI3DModelViewer1.Invalidate;
  UpdateModelStats;
  AddLog('Pirâmide 3D pronta para visualização.');
end;

procedure TfrmMain.GenerateCylinderMesh;
var
  TempFile: string;
  SL: TStringList;
  I, Segments: Integer;
  Angle, R, H, X, Z: Double;
begin
  AddLog('Gerando malha procedural: Cilindro 3D...');
  TempFile := IncludeTrailingPathDelimiter(GetTempDir) + 'model3d_cylinder.obj';
  SL := TStringList.Create;
  try
    Segments := 16;
    R := 1.0;
    H := 2.0;
    SL.Add('# Wavefront OBJ - 3D Cylinder');
    // Top center = 1, Bottom center = 2
    SL.Add(Format('v 0.0 %.4f 0.0', [H / 2.0]));
    SL.Add(Format('v 0.0 %.4f 0.0', [-H / 2.0]));
    
    // Top ring: 3 .. Segments + 2
    for I := 0 to Segments - 1 do
    begin
      Angle := (2.0 * Pi * I) / Segments;
      X := R * Cos(Angle);
      Z := R * Sin(Angle);
      SL.Add(Format('v %.4f %.4f %.4f', [X, H / 2.0, Z]));
    end;
    
    // Bottom ring: Segments + 3 .. 2 * Segments + 2
    for I := 0 to Segments - 1 do
    begin
      Angle := (2.0 * Pi * I) / Segments;
      X := R * Cos(Angle);
      Z := R * Sin(Angle);
      SL.Add(Format('v %.4f %.4f %.4f', [X, -H / 2.0, Z]));
    end;
    
    // Faces
    for I := 0 to Segments - 1 do
    begin
      // Top fan
      SL.Add(Format('f 1 %d %d', [3 + I, 3 + ((I + 1) mod Segments)]));
      // Bottom fan
      SL.Add(Format('f 2 %d %d', [3 + Segments + ((I + 1) mod Segments), 3 + Segments + I]));
      // Side quad (2 triangles)
      SL.Add(Format('f %d %d %d', [3 + I, 3 + Segments + I, 3 + Segments + ((I + 1) mod Segments)]));
      SL.Add(Format('f %d %d %d', [3 + I, 3 + Segments + ((I + 1) mod Segments), 3 + ((I + 1) mod Segments)]));
    end;
    SL.SaveToFile(TempFile);
  finally
    SL.Free;
  end;

  AIModel3D1.LoadFromFile(TempFile);
  AIModel3D1.FilePath := 'Cilindro_Procedural.obj';
  AI3DModelViewer1.ResetCamera;
  AI3DModelViewer1.Invalidate;
  UpdateModelStats;
  AddLog('Cilindro 3D pronto para visualização.');
end;

procedure TfrmMain.btnCubeClick(Sender: TObject);
begin
  GenerateCubeMesh;
end;

procedure TfrmMain.btnPyramidClick(Sender: TObject);
begin
  GeneratePyramidMesh;
end;

procedure TfrmMain.btnCylinderClick(Sender: TObject);
begin
  GenerateCylinderMesh;
end;

procedure TfrmMain.cmbRenderModeChange(Sender: TObject);
begin
  case cmbRenderMode.ItemIndex of
    0: AI3DModelViewer1.RenderMode := rmSolid;
    1: AI3DModelViewer1.RenderMode := rmWireframe;
    2: AI3DModelViewer1.RenderMode := rmPoints;
  end;
  AI3DModelViewer1.Invalidate;
  AddLog('Modo de renderização alterado para: ' + cmbRenderMode.Text);
end;

procedure TfrmMain.btnZoomInClick(Sender: TObject);
begin
  AI3DModelViewer1.ZoomIn;
  AddLog('Zoom aumentado.');
end;

procedure TfrmMain.btnZoomOutClick(Sender: TObject);
begin
  AI3DModelViewer1.ZoomOut;
  AddLog('Zoom reduzido.');
end;

procedure TfrmMain.btnResetCamClick(Sender: TObject);
begin
  AI3DModelViewer1.ResetCamera;
  AI3DModelViewer1.Invalidate;
  AddLog('Câmera resetada para posição padrão.');
end;

procedure TfrmMain.btnExportClick(Sender: TObject);
begin
  if SaveDialog1.Execute then
  begin
    try
      AI3DModelViewer1.ExportScreenshot(SaveDialog1.FileName);
      AddLog('Captura 3D exportada com sucesso para: ' + SaveDialog1.FileName);
    except
      on E: Exception do
        AddLog('Erro ao exportar imagem: ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.btnRotXClick(Sender: TObject);
begin
  if AIModel3D1 <> nil then
  begin
    AIModel3D1.Rotate(15, 0, 0);
    AI3DModelViewer1.Invalidate;
    UpdateModelStats;
    AddLog('Rotacionado X +15 graus na malha.');
  end;
end;

procedure TfrmMain.btnRotYClick(Sender: TObject);
begin
  if AIModel3D1 <> nil then
  begin
    AIModel3D1.Rotate(0, 15, 0);
    AI3DModelViewer1.Invalidate;
    UpdateModelStats;
    AddLog('Rotacionado Y +15 graus na malha.');
  end;
end;

procedure TfrmMain.btnRotZClick(Sender: TObject);
begin
  if AIModel3D1 <> nil then
  begin
    AIModel3D1.Rotate(0, 0, 15);
    AI3DModelViewer1.Invalidate;
    UpdateModelStats;
    AddLog('Rotacionado Z +15 graus na malha.');
  end;
end;

end.
