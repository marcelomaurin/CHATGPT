unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, ExtDlgs, Math, LCLIntf, imagefilters;

type
  { TFormMain }
  TFormMain = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Panels and Controls }
    pnlLeft: TPanel;
    pnlClient: TPanel;
    pnlOriginal: TPanel;
    pnlProcessed: TPanel;
    
    imgOriginal: TImage;
    imgProcessed: TImage;
    
    btnLoad: TButton;
    btnSave: TButton;
    
    lblFilter: TLabel;
    cbFilter: TComboBox;
    
    { Sliders Group Box }
    gbParams: TGroupBox;
    
    lblBrightness: TLabel;
    tbBrightness: TTrackBar;
    lblBrightnessVal: TLabel;
    
    lblContrast: TLabel;
    tbContrast: TTrackBar;
    lblContrastVal: TLabel;
    
    lblThreshold: TLabel;
    tbThreshold: TTrackBar;
    lblThresholdVal: TLabel;
    
    lblRadius: TLabel;
    tbRadius: TTrackBar;
    lblRadiusVal: TLabel;
    
    lblPerf: TLabel;
    
    { Dialogs }
    dlgOpen: TOpenPictureDialog;
    dlgSave: TSavePictureDialog;
    
    { Image Processing Components (Dynamic creation for design safety) }
    FGrayscaleFilter: TGrayscaleFilter;
    FNegativeFilter: TNegativeFilter;
    FBrightnessContrastFilter: TBrightnessContrastFilter;
    FBinarizationFilter: TBinarizationFilter;
    FBlurFilter: TBlurFilter;
    FSharpenFilter: TSharpenFilter;
    FSobelFilter: TSobelFilter;
    FErosionDilationFilter: TErosionDilationFilter;
    
    procedure CreateLayout;
    procedure LoadImageClick(Sender: TObject);
    procedure SaveImageClick(Sender: TObject);
    procedure FilterChanged(Sender: TObject);
    procedure ParamChanged(Sender: TObject);
    procedure UpdateParamControls;
    procedure RunFilter;
  public
  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

{ TFormMain }

procedure TFormMain.FormCreate(Sender: TObject);
begin
  Caption := 'AI Image Processing Showcase Playground';
  Width := 950;
  Height := 650;
  Position := poScreenCenter;
  Color := $F3F4F6; // Modern soft light gray background
  
  CreateLayout;
  
  { Instancia dinamicamente os componentes da aba AI Image }
  FGrayscaleFilter := TGrayscaleFilter.Create(Self);
  FGrayscaleFilter.InputImage := imgOriginal;
  FGrayscaleFilter.OutputImage := imgProcessed;
  
  FNegativeFilter := TNegativeFilter.Create(Self);
  FNegativeFilter.InputImage := imgOriginal;
  FNegativeFilter.OutputImage := imgProcessed;
  
  FBrightnessContrastFilter := TBrightnessContrastFilter.Create(Self);
  FBrightnessContrastFilter.InputImage := imgOriginal;
  FBrightnessContrastFilter.OutputImage := imgProcessed;
  
  FBinarizationFilter := TBinarizationFilter.Create(Self);
  FBinarizationFilter.InputImage := imgOriginal;
  FBinarizationFilter.OutputImage := imgProcessed;
  
  FBlurFilter := TBlurFilter.Create(Self);
  FBlurFilter.InputImage := imgOriginal;
  FBlurFilter.OutputImage := imgProcessed;
  
  FSharpenFilter := TSharpenFilter.Create(Self);
  FSharpenFilter.InputImage := imgOriginal;
  FSharpenFilter.OutputImage := imgProcessed;
  
  FSobelFilter := TSobelFilter.Create(Self);
  FSobelFilter.InputImage := imgOriginal;
  FSobelFilter.OutputImage := imgProcessed;
  
  FErosionDilationFilter := TErosionDilationFilter.Create(Self);
  FErosionDilationFilter.InputImage := imgOriginal;
  FErosionDilationFilter.OutputImage := imgProcessed;
  
  { Inicializa controles }
  cbFilter.ItemIndex := 0;
  UpdateParamControls;
  
  { Gera uma imagem demo padrão para não abrir vazio }
  imgOriginal.Picture.Bitmap.SetSize(300, 300);
  with imgOriginal.Picture.Bitmap.Canvas do
  begin
    Brush.Color := clNavy;
    FillRect(0, 0, 300, 300);
    Pen.Color := clYellow;
    Pen.Width := 4;
    Brush.Color := clRed;
    Ellipse(50, 50, 250, 250);
    Brush.Color := clLime;
    Rectangle(100, 100, 200, 200);
    Font.Color := clWhite;
    Font.Size := 16;
    TextOut(70, 135, 'IA IMAGE');
  end;
  
  RunFilter;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  { Componentes criados com Self como Owner são destruídos automaticamente }
end;

procedure TFormMain.CreateLayout;
var
  lblTitleOrig, lblTitleProc: TLabel;
begin
  { Left Panel }
  pnlLeft := TPanel.Create(Self);
  pnlLeft.Parent := Self;
  pnlLeft.Align := alLeft;
  pnlLeft.Width := 250;
  pnlLeft.BevelOuter := bvNone;
  pnlLeft.Color := $FFFFFF; // Solid white background
  pnlLeft.BorderWidth := 10;
  
  btnLoad := TButton.Create(Self);
  btnLoad.Parent := pnlLeft;
  btnLoad.Align := alTop;
  btnLoad.Height := 38;
  btnLoad.Caption := '📂 Carregar Imagem';
  btnLoad.OnClick := @LoadImageClick;
  btnLoad.Cursor := crHandPoint;
  
  { Spacing }
  with TPanel.Create(Self) do
  begin
    Parent := pnlLeft;
    Align := alTop;
    Height := 10;
    BevelOuter := bvNone;
  end;
  
  btnSave := TButton.Create(Self);
  btnSave.Parent := pnlLeft;
  btnSave.Align := alTop;
  btnSave.Height := 38;
  btnSave.Caption := '💾 Salvar Resultado';
  btnSave.OnClick := @SaveImageClick;
  btnSave.Cursor := crHandPoint;
  
  { Spacing }
  with TPanel.Create(Self) do
  begin
    Parent := pnlLeft;
    Align := alTop;
    Height := 15;
    BevelOuter := bvNone;
  end;
  
  lblFilter := TLabel.Create(Self);
  lblFilter.Parent := pnlLeft;
  lblFilter.Align := alTop;
  lblFilter.Caption := 'Selecione o Filtro:';
  lblFilter.Font.Style := [fsBold];
  lblFilter.Font.Color := $374151;
  
  { Spacing }
  with TPanel.Create(Self) do
  begin
    Parent := pnlLeft;
    Align := alTop;
    Height := 5;
    BevelOuter := bvNone;
  end;
  
  cbFilter := TComboBox.Create(Self);
  cbFilter.Parent := pnlLeft;
  cbFilter.Align := alTop;
  cbFilter.Style := csDropDownList;
  cbFilter.Items.Add('Nenhum (Original)');
  cbFilter.Items.Add('Escala de Cinza');
  cbFilter.Items.Add('Negativo (Inverter)');
  cbFilter.Items.Add('Brilho & Contraste');
  cbFilter.Items.Add('Binarização');
  cbFilter.Items.Add('Desfoque (Blur)');
  cbFilter.Items.Add('Nitidez (Sharpen)');
  cbFilter.Items.Add('Bordas (Sobel)');
  cbFilter.Items.Add('Erosão Morfológica');
  cbFilter.Items.Add('Dilatação Morfológica');
  cbFilter.OnChange := @FilterChanged;
  
  { Spacing }
  with TPanel.Create(Self) do
  begin
    Parent := pnlLeft;
    Align := alTop;
    Height := 15;
    BevelOuter := bvNone;
  end;
  
  { GroupBox for Parameters }
  gbParams := TGroupBox.Create(Self);
  gbParams.Parent := pnlLeft;
  gbParams.Align := alTop;
  gbParams.Height := 300;
  gbParams.Caption := ' Parâmetros ';
  gbParams.Font.Style := [fsBold];
  gbParams.BorderWidth := 5;
  
  { Brightness Controls }
  lblBrightness := TLabel.Create(Self);
  lblBrightness.Parent := gbParams;
  lblBrightness.Align := alTop;
  lblBrightness.Caption := 'Brilho:';
  
  tbBrightness := TTrackBar.Create(Self);
  tbBrightness.Parent := gbParams;
  tbBrightness.Align := alTop;
  tbBrightness.Min := -255;
  tbBrightness.Max := 255;
  tbBrightness.Position := 0;
  tbBrightness.OnChange := @ParamChanged;
  
  lblBrightnessVal := TLabel.Create(Self);
  lblBrightnessVal.Parent := gbParams;
  lblBrightnessVal.Align := alTop;
  lblBrightnessVal.Alignment := taRightJustify;
  lblBrightnessVal.Caption := '0';
  
  { Contrast Controls }
  lblContrast := TLabel.Create(Self);
  lblContrast.Parent := gbParams;
  lblContrast.Align := alTop;
  lblContrast.Caption := 'Contraste:';
  
  tbContrast := TTrackBar.Create(Self);
  tbContrast.Parent := gbParams;
  tbContrast.Align := alTop;
  tbContrast.Min := 0;
  tbContrast.Max := 500; // 0.0 to 5.0
  tbContrast.Position := 100; // 1.0
  tbContrast.OnChange := @ParamChanged;
  
  lblContrastVal := TLabel.Create(Self);
  lblContrastVal.Parent := gbParams;
  lblContrastVal.Align := alTop;
  lblContrastVal.Alignment := taRightJustify;
  lblContrastVal.Caption := '1.0x';
  
  { Threshold Controls }
  lblThreshold := TLabel.Create(Self);
  lblThreshold.Parent := gbParams;
  lblThreshold.Align := alTop;
  lblThreshold.Caption := 'Limiar Binarização:';
  
  tbThreshold := TTrackBar.Create(Self);
  tbThreshold.Parent := gbParams;
  tbThreshold.Align := alTop;
  tbThreshold.Min := 0;
  tbThreshold.Max := 255;
  tbThreshold.Position := 128;
  tbThreshold.OnChange := @ParamChanged;
  
  lblThresholdVal := TLabel.Create(Self);
  lblThresholdVal.Parent := gbParams;
  lblThresholdVal.Align := alTop;
  lblThresholdVal.Alignment := taRightJustify;
  lblThresholdVal.Caption := '128';
  
  { Radius Controls }
  lblRadius := TLabel.Create(Self);
  lblRadius.Parent := gbParams;
  lblRadius.Align := alTop;
  lblRadius.Caption := 'Raio Morfológico:';
  
  tbRadius := TTrackBar.Create(Self);
  tbRadius.Parent := gbParams;
  tbRadius.Align := alTop;
  tbRadius.Min := 1;
  tbRadius.Max := 5;
  tbRadius.Position := 1;
  tbRadius.OnChange := @ParamChanged;
  
  lblRadiusVal := TLabel.Create(Self);
  lblRadiusVal.Parent := gbParams;
  lblRadiusVal.Align := alTop;
  lblRadiusVal.Alignment := taRightJustify;
  lblRadiusVal.Caption := '1 px';
  
  { Performance label at bottom of pnlLeft }
  lblPerf := TLabel.Create(Self);
  lblPerf.Parent := pnlLeft;
  lblPerf.Align := alBottom;
  lblPerf.Font.Color := clHighlight;
  lblPerf.Font.Style := [fsBold];
  lblPerf.Caption := 'Tempo de Processamento: 0 ms';
  lblPerf.Alignment := taCenter;
  
  { Client Panel }
  pnlClient := TPanel.Create(Self);
  pnlClient.Parent := Self;
  pnlClient.Align := alClient;
  pnlClient.BevelOuter := bvNone;
  pnlClient.BorderWidth := 10;
  
  { Original Image Panel (Left half of client) }
  pnlOriginal := TPanel.Create(Self);
  pnlOriginal.Parent := pnlClient;
  pnlOriginal.Align := alLeft;
  pnlOriginal.Width := 335; // Will be scaled/adjusted
  pnlOriginal.BevelOuter := bvNone;
  pnlOriginal.Color := clWhite;
  pnlOriginal.BorderWidth := 5;
  
  lblTitleOrig := TLabel.Create(Self);
  lblTitleOrig.Parent := pnlOriginal;
  lblTitleOrig.Align := alTop;
  lblTitleOrig.Caption := 'Imagem Original';
  lblTitleOrig.Alignment := taCenter;
  lblTitleOrig.Font.Style := [fsBold];
  lblTitleOrig.Font.Size := 11;
  
  imgOriginal := TImage.Create(Self);
  imgOriginal.Parent := pnlOriginal;
  imgOriginal.Align := alClient;
  imgOriginal.Proportional := True;
  imgOriginal.Center := True;
  
  { Processed Image Panel (Right half of client) }
  pnlProcessed := TPanel.Create(Self);
  pnlProcessed.Parent := pnlClient;
  pnlProcessed.Align := alClient;
  pnlProcessed.BevelOuter := bvNone;
  pnlProcessed.Color := clWhite;
  pnlProcessed.BorderWidth := 5;
  
  lblTitleProc := TLabel.Create(Self);
  lblTitleProc.Parent := pnlProcessed;
  lblTitleProc.Align := alTop;
  lblTitleProc.Caption := 'Resultado Filtrado';
  lblTitleProc.Alignment := taCenter;
  lblTitleProc.Font.Style := [fsBold];
  lblTitleProc.Font.Size := 11;
  lblTitleProc.Font.Color := clHighlight;
  
  imgProcessed := TImage.Create(Self);
  imgProcessed.Parent := pnlProcessed;
  imgProcessed.Align := alClient;
  imgProcessed.Proportional := True;
  imgProcessed.Center := True;
  
  { Adjust Width splits evenly }
  pnlOriginal.Width := (950 - 250 - 20) div 2;
  
  { Dialogs }
  dlgOpen := TOpenPictureDialog.Create(Self);
  dlgOpen.Filter := 'Imagens (*.png;*.jpg;*.jpeg;*.bmp)|*.png;*.jpg;*.jpeg;*.bmp|Todos os arquivos (*.*)|*.*';
  
  dlgSave := TSavePictureDialog.Create(Self);
  dlgSave.Filter := 'Imagens (*.png;*.jpg;*.jpeg;*.bmp)|*.png;*.jpg;*.jpeg;*.bmp';
end;

procedure TFormMain.LoadImageClick(Sender: TObject);
begin
  if dlgOpen.Execute then
  begin
    imgOriginal.Picture.LoadFromFile(dlgOpen.FileName);
    RunFilter;
  end;
end;

procedure TFormMain.SaveImageClick(Sender: TObject);
begin
  if dlgSave.Execute then
  begin
    imgProcessed.Picture.SaveToFile(dlgSave.FileName);
    ShowMessage('Imagem salva com sucesso!');
  end;
end;

procedure TFormMain.FilterChanged(Sender: TObject);
begin
  UpdateParamControls;
  RunFilter;
end;

procedure TFormMain.ParamChanged(Sender: TObject);
begin
  lblBrightnessVal.Caption := IntToStr(tbBrightness.Position);
  lblContrastVal.Caption := FormatFloat('0.0', tbContrast.Position / 100.0) + 'x';
  lblThresholdVal.Caption := IntToStr(tbThreshold.Position);
  lblRadiusVal.Caption := IntToStr(tbRadius.Position) + ' px';
  RunFilter;
end;

procedure TFormMain.UpdateParamControls;
var
  Idx: Integer;
begin
  Idx := cbFilter.ItemIndex;
  
  { Enable/Disable relevant params based on selected filter }
  tbBrightness.Enabled := (Idx = 3);
  tbContrast.Enabled := (Idx = 3);
  tbThreshold.Enabled := (Idx = 4);
  tbRadius.Enabled := (Idx = 8) or (Idx = 9);
  
  lblBrightness.Enabled := tbBrightness.Enabled;
  lblBrightnessVal.Enabled := tbBrightness.Enabled;
  lblContrast.Enabled := tbContrast.Enabled;
  lblContrastVal.Enabled := tbContrast.Enabled;
  lblThreshold.Enabled := tbThreshold.Enabled;
  lblThresholdVal.Enabled := tbThreshold.Enabled;
  lblRadius.Enabled := tbRadius.Enabled;
  lblRadiusVal.Enabled := tbRadius.Enabled;
end;

procedure TFormMain.RunFilter;
var
  StartTime, EndTime: Int64;
  Idx: Integer;
begin
  if (imgOriginal.Picture.Graphic = nil) or (imgOriginal.Picture.Width = 0) then Exit;
  
  Idx := cbFilter.ItemIndex;
  
  { Se for 'Nenhum', copia a original e sai }
  if Idx = 0 then
  begin
    imgProcessed.Picture.Assign(imgOriginal.Picture);
    lblPerf.Caption := 'Tempo: 0 ms';
    Exit;
  end;
  
  StartTime := GetTickCount64;
  
  try
    case Idx of
      1: FGrayscaleFilter.Apply;
      2: FNegativeFilter.Apply;
      3: begin
           FBrightnessContrastFilter.Brightness := tbBrightness.Position;
           FBrightnessContrastFilter.Contrast := tbContrast.Position / 100.0;
           FBrightnessContrastFilter.Apply;
         end;
      4: begin
           FBinarizationFilter.Threshold := tbThreshold.Position;
           FBinarizationFilter.Apply;
         end;
      5: FBlurFilter.Apply;
      6: FSharpenFilter.Apply;
      7: FSobelFilter.Apply;
      8: begin
           FErosionDilationFilter.Operation := moErosion;
           FErosionDilationFilter.Radius := tbRadius.Position;
           FErosionDilationFilter.Apply;
         end;
      9: begin
           FErosionDilationFilter.Operation := moDilation;
           FErosionDilationFilter.Radius := tbRadius.Position;
           FErosionDilationFilter.Apply;
         end;
    end;
  except
    on E: Exception do
      ShowMessage('Erro ao processar filtro: ' + E.Message);
  end;
  
  EndTime := GetTickCount64;
  lblPerf.Caption := Format('⏱️ Tempo: %d ms', [EndTime - StartTime]);
end;

end.
