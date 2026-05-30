unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Math, sommap;

type

  { TfrmSOMDemo }

  TfrmSOMDemo = class(TForm)
    pnlConfig: TPanel;
    lblLearningRate: TLabel;
    edLearningRate: TEdit;
    lblEpochs: TLabel;
    edEpochs: TEdit;
    btnInitialize: TButton;
    btnTrain: TButton;
    btnStop: TButton;
    
    pnlGridArea: TPanel;
    imgGrid: TImage;
    lblGridTitle: TLabel;
    
    pnlSave: TPanel;
    lblSaveTitle: TLabel;
    btnSaveModel: TButton;
    btnLoadModel: TButton;
    
    meLogs: TMemo;
    lblLogs: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnInitializeClick(Sender: TObject);
    procedure btnTrainClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnSaveModelClick(Sender: TObject);
    procedure btnLoadModelClick(Sender: TObject);
  private
    FSOM: TSOMMap;
    FTrainingActive: Boolean;
    FColorsDataset: array[0..7] of TDoubleArray;
    procedure LogMsg(const AMsg: string);
    procedure DrawSOMGrid;
    procedure SetupDataset;
  public

  end;

var
  frmSOMDemo: TfrmSOMDemo;

implementation

{$R *.lfm}

{ TfrmSOMDemo }

procedure TfrmSOMDemo.FormCreate(Sender: TObject);
begin
  FSOM := TSOMMap.Create(Self);
  FTrainingActive := False;
  SetupDataset;
  
  LogMsg('Rede de Kohonen (SOM) carregada e pronta.');
  LogMsg('1. Clique em "Inicializar Grade" para gerar cores aleatórias.');
  LogMsg('2. Clique em "Iniciar Auto-Organização" para ver a convergência topológica em tempo real!');
  
  btnInitializeClick(nil);
end;

procedure TfrmSOMDemo.FormDestroy(Sender: TObject);
begin
  FTrainingActive := False;
  // FSOM é autoliberado pelo Owner
end;

procedure TfrmSOMDemo.LogMsg(const AMsg: string);
begin
  meLogs.Lines.Append('[' + FormatDateTime('hh:nn:ss', Now) + '] ' + AMsg);
end;

procedure TfrmSOMDemo.SetupDataset;
var
  I: Integer;
begin
  // Criando as cores primárias e secundárias do dataset normalizadas (0.0 a 1.0)
  for I := 0 to 7 do
    SetLength(FColorsDataset[I], 3);

  // Red
  FColorsDataset[0][0] := 1.0; FColorsDataset[0][1] := 0.0; FColorsDataset[0][2] := 0.0;
  // Green
  FColorsDataset[1][0] := 0.0; FColorsDataset[1][1] := 1.0; FColorsDataset[1][2] := 0.0;
  // Blue
  FColorsDataset[2][0] := 0.0; FColorsDataset[2][1] := 0.0; FColorsDataset[2][2] := 1.0;
  // Yellow
  FColorsDataset[3][0] := 1.0; FColorsDataset[3][1] := 1.0; FColorsDataset[3][2] := 0.0;
  // Cyan
  FColorsDataset[4][0] := 0.0; FColorsDataset[4][1] := 1.0; FColorsDataset[4][2] := 1.0;
  // Magenta
  FColorsDataset[5][0] := 1.0; FColorsDataset[5][1] := 0.0; FColorsDataset[5][2] := 1.0;
  // White
  FColorsDataset[6][0] := 1.0; FColorsDataset[6][1] := 1.0; FColorsDataset[6][2] := 1.0;
  // Black
  FColorsDataset[7][0] := 0.0; FColorsDataset[7][1] := 0.0; FColorsDataset[7][2] := 0.0;
end;

procedure TfrmSOMDemo.DrawSOMGrid;
var
  X, Y: Integer;
  CellW, CellH: Integer;
  R, G, B: Byte;
begin
  if FSOM.GridWidth = 0 then Exit;

  CellW := imgGrid.Width div FSOM.GridWidth;
  CellH := imgGrid.Height div FSOM.GridHeight;

  imgGrid.Canvas.Brush.Color := clBlack;
  imgGrid.Canvas.FillRect(imgGrid.ClientRect);

  for X := 0 to FSOM.GridWidth - 1 do
  begin
    for Y := 0 to FSOM.GridHeight - 1 do
    begin
      R := Round(FSOM.Weights[X, Y, 0] * 255);
      G := Round(FSOM.Weights[X, Y, 1] * 255);
      B := Round(FSOM.Weights[X, Y, 2] * 255);

      imgGrid.Canvas.Brush.Color := RGBToColor(R, G, B);
      imgGrid.Canvas.Pen.Style := psClear;
      imgGrid.Canvas.Rectangle(X * CellW, Y * CellH, (X + 1) * CellW + 1, (Y + 1) * CellH + 1);
    end;
  end;
end;

procedure TfrmSOMDemo.btnInitializeClick(Sender: TObject);
begin
  LogMsg('Inicializando Grade SOM 20x20 com pesos de cores aleatórias...');
  FSOM.Initialize(20, 20, 3);
  DrawSOMGrid;
  LogMsg('Grade inicializada. Pronto para treinamento.');
end;

procedure TfrmSOMDemo.btnTrainClick(Sender: TObject);
var
  Epoch, EpochsCount, I, TargetIdx: Integer;
  LR, StartRadius, TimeConstant, CurrentRadius, CurrentLR: Double;
begin
  if FSOM.GridWidth = 0 then
  begin
    ShowMessage('Por favor, inicialize a grade primeiro.');
    Exit;
  end;

  if FTrainingActive then Exit;

  LR := StrToFloatDef(edLearningRate.Text, 0.1);
  EpochsCount := StrToIntDef(edEpochs.Text, 500);

  FTrainingActive := True;
  btnTrain.Enabled := False;
  btnInitialize.Enabled := False;
  btnStop.Enabled := True;

  LogMsg(Format('Iniciando auto-organização topológica por %d épocas...', [EpochsCount]));

  StartRadius := Max(FSOM.GridWidth, FSOM.GridHeight) / 2.0;
  TimeConstant := EpochsCount / LogN(2.718281828459, StartRadius);

  for Epoch := 1 to EpochsCount do
  begin
    if not FTrainingActive then Break;

    // Decaimento exponencial do raio de vizinhança e taxa de aprendizado
    CurrentRadius := StartRadius * Exp(-Epoch / TimeConstant);
    CurrentLR := LR * Exp(-Epoch / EpochsCount);

    // Embaralha estocasticamente a seleção de cores do dataset
    for I := 0 to 20 do // 20 iterações por época para suavidade
    begin
      TargetIdx := Random(8);
      FSOM.TrainStep(FColorsDataset[TargetIdx], CurrentLR, Max(CurrentRadius, 0.1));
    end;

    // Atualiza o canvas a cada época para animação fluida
    if Epoch mod 2 = 0 then
    begin
      DrawSOMGrid;
      Application.ProcessMessages;
      Sleep(5); // Pequeno atraso para suavizar visualização
    end;
  end;

  FTrainingActive := False;
  btnTrain.Enabled := True;
  btnInitialize.Enabled := True;
  btnStop.Enabled := False;

  DrawSOMGrid;
  LogMsg('Auto-organização de Kohonen concluída com sucesso!');
  ShowMessage('Treinamento SOM concluído!');
end;

procedure TfrmSOMDemo.btnStopClick(Sender: TObject);
begin
  if FTrainingActive then
  begin
    FTrainingActive := False;
    LogMsg('Interrupção solicitada pelo usuário.');
  end;
end;

procedure TfrmSOMDemo.btnSaveModelClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
begin
  if FSOM.GridWidth = 0 then
  begin
    ShowMessage('Nenhuma grade carregada para salvar.');
    Exit;
  end;

  SaveDlg := TSaveDialog.Create(nil);
  try
    SaveDlg.Title := 'Salvar pesos da Grade SOM';
    SaveDlg.Filter := 'Modelos SOM (*.som)|*.som';
    SaveDlg.DefaultExt := 'som';
    if SaveDlg.Execute then
    begin
      FSOM.SaveToFile(SaveDlg.FileName);
      LogMsg('Modelo salvo com sucesso no arquivo: ' + SaveDlg.FileName);
      ShowMessage('Modelo salvo!');
    end;
  finally
    SaveDlg.Free;
  end;
end;

procedure TfrmSOMDemo.btnLoadModelClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(nil);
  try
    OpenDlg.Title := 'Carregar pesos da Grade SOM';
    OpenDlg.Filter := 'Modelos SOM (*.som)|*.som';
    if OpenDlg.Execute then
    begin
      if FileExists(OpenDlg.FileName) then
      begin
        FSOM.LoadFromFile(OpenDlg.FileName);
        LogMsg('Grade SOM carregada com sucesso do arquivo: ' + OpenDlg.FileName);
        DrawSOMGrid;
        ShowMessage('Modelo carregado com sucesso!');
      end
      else
        ShowMessage('Arquivo não encontrado.');
    end;
  finally
    OpenDlg.Free;
  end;
end;

end.
