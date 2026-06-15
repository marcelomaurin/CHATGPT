unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, TypInfo, aiframeprocessor, aiwordtypes;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlLeft: TPanel;
    pnlClient: TPanel;
    pnlBottom: TPanel;

    // Actions
    btnLoad: TButton;
    btnProcess: TButton;
    btnSave: TButton;
    ResetBtn: TButton;

    // Formats & Mode Group
    grpParameters: TGroupBox;
    lblScale: TLabel;
    tbScaleFactor: TTrackBar;
    lblScaleVal: TLabel;

    chkGrayscale: TCheckBox;
    chkModifyInput: TCheckBox;
    chkEnableChannelAdjustments: TCheckBox;

    lblMode: TLabel;
    cbRGBChannelMode: TComboBox;

    // Channel parameters
    grpChannels: TGroupBox;
    chkRedEnabled: TCheckBox;
    chkGreenEnabled: TCheckBox;
    chkBlueEnabled: TCheckBox;

    lblRedGain: TLabel;
    tbRedGain: TTrackBar;
    lblGreenGain: TLabel;
    tbGreenGain: TTrackBar;
    lblBlueGain: TLabel;
    tbBlueGain: TTrackBar;

    lblRedOffset: TLabel;
    tbRedOffset: TTrackBar;
    lblGreenOffset: TLabel;
    tbGreenOffset: TTrackBar;
    lblBlueOffset: TLabel;
    tbBlueOffset: TTrackBar;

    chkInvertRed: TCheckBox;
    chkInvertGreen: TCheckBox;
    chkInvertBlue: TCheckBox;

    // Images panel
    pnlImages: TPanel;
    imgOriginal: TImage;
    imgProcessed: TImage;
    lblOriginal: TLabel;
    lblProcessed: TLabel;

    // Log
    memoLog: TMemo;

    // Component
    FrameProcessor1: TAIFrameProcessor;

    // Dialogs
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;

    procedure FormCreate(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnProcessClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure ResetBtnClick(Sender: TObject);
    procedure tbScaleFactorChange(Sender: TObject);
  private
    FLoadedPath: string;
    FWorkBmp: TBitmap;
    procedure LogMsg(const AMsg: string);
    procedure SyncPropertiesToUI;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FWorkBmp := TBitmap.Create;
  FrameProcessor1 := TAIFrameProcessor.Create(Self);
  SyncPropertiesToUI;
  LogMsg('Demo TAIFrameProcessor inicializado com sucesso.');
end;

procedure TfrmMain.LogMsg(const AMsg: string);
begin
  memoLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' - ' + AMsg);
end;

procedure TfrmMain.SyncPropertiesToUI;
begin
  chkGrayscale.Checked := FrameProcessor1.Grayscale;
  chkModifyInput.Checked := FrameProcessor1.ModifyInput;
  cbRGBChannelMode.ItemIndex := Integer(FrameProcessor1.RGBChannelMode);
  chkEnableChannelAdjustments.Checked := FrameProcessor1.EnableChannelAdjustments;

  chkRedEnabled.Checked := FrameProcessor1.RedEnabled;
  chkGreenEnabled.Checked := FrameProcessor1.GreenEnabled;
  chkBlueEnabled.Checked := FrameProcessor1.BlueEnabled;

  tbRedGain.Position := Round(FrameProcessor1.RedGain * 100);
  tbGreenGain.Position := Round(FrameProcessor1.GreenGain * 100);
  tbBlueGain.Position := Round(FrameProcessor1.BlueGain * 100);

  tbRedOffset.Position := FrameProcessor1.RedOffset;
  tbGreenOffset.Position := FrameProcessor1.GreenOffset;
  tbBlueOffset.Position := FrameProcessor1.BlueOffset;

  chkInvertRed.Checked := FrameProcessor1.InvertRed;
  chkInvertGreen.Checked := FrameProcessor1.InvertGreen;
  chkInvertBlue.Checked := FrameProcessor1.InvertBlue;

  tbScaleFactor.Position := Round(FrameProcessor1.ScaleFactor * 10);
  lblScaleVal.Caption := FloatToStr(FrameProcessor1.ScaleFactor);
end;

procedure TfrmMain.tbScaleFactorChange(Sender: TObject);
begin
  lblScaleVal.Caption := FloatToStr(tbScaleFactor.Position / 10.0);
end;

procedure TfrmMain.btnLoadClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    FLoadedPath := OpenDialog1.FileName;
    try
      imgOriginal.Picture.LoadFromFile(FLoadedPath);
      FWorkBmp.Assign(imgOriginal.Picture.Bitmap);
      LogMsg('Imagem carregada: ' + ExtractFileName(FLoadedPath) + ' (' + IntToStr(FWorkBmp.Width) + 'x' + IntToStr(FWorkBmp.Height) + ')');
    except
      on E: Exception do
        LogMsg('Erro ao carregar imagem: ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.btnProcessClick(Sender: TObject);
var
  LInputBmp: TBitmap;
  LProcessed: TBitmap;
begin
  if (FLoadedPath = '') and (imgOriginal.Picture.Bitmap.Width <= 0) then
  begin
    LogMsg('Erro: Por favor, carregue uma imagem primeiro.');
    Exit;
  end;

  // Sync controls to component properties
  FrameProcessor1.ScaleFactor := tbScaleFactor.Position / 10.0;
  FrameProcessor1.Grayscale := chkGrayscale.Checked;
  FrameProcessor1.ModifyInput := chkModifyInput.Checked;
  FrameProcessor1.RGBChannelMode := TAIRGBChannelMode(cbRGBChannelMode.ItemIndex);
  FrameProcessor1.EnableChannelAdjustments := chkEnableChannelAdjustments.Checked;

  FrameProcessor1.RedEnabled := chkRedEnabled.Checked;
  FrameProcessor1.GreenEnabled := chkGreenEnabled.Checked;
  FrameProcessor1.BlueEnabled := chkBlueEnabled.Checked;

  FrameProcessor1.RedGain := tbRedGain.Position / 100.0;
  FrameProcessor1.GreenGain := tbGreenGain.Position / 100.0;
  FrameProcessor1.BlueGain := tbBlueGain.Position / 100.0;

  FrameProcessor1.RedOffset := tbRedOffset.Position;
  FrameProcessor1.GreenOffset := tbGreenOffset.Position;
  FrameProcessor1.BlueOffset := tbBlueOffset.Position;

  FrameProcessor1.InvertRed := chkInvertRed.Checked;
  FrameProcessor1.InvertGreen := chkInvertGreen.Checked;
  FrameProcessor1.InvertBlue := chkInvertBlue.Checked;

  LogMsg('Iniciando processamento...');

  if FrameProcessor1.ModifyInput then
  begin
    // Modify input directly
    LInputBmp := imgOriginal.Picture.Bitmap;
    LProcessed := FrameProcessor1.ProcessBitmap(LInputBmp);
    if Assigned(LProcessed) then
    begin
      imgProcessed.Picture.Assign(LProcessed);
      LogMsg('Processamento concluído com ModifyInput=True.');
      memoLog.Lines.Add(FrameProcessor1.GetDiagnosticReport);
    end
    else
      LogMsg('Erro de processamento: ' + FrameProcessor1.LastError);
  end
  else
  begin
    // Safe cloning
    LInputBmp := TBitmap.Create;
    try
      LInputBmp.Assign(imgOriginal.Picture.Bitmap);
      LProcessed := FrameProcessor1.ProcessBitmap(LInputBmp);
      if Assigned(LProcessed) then
      begin
        imgProcessed.Picture.Assign(LProcessed);
        LProcessed.Free;
        LogMsg('Processamento concluído com ModifyInput=False.');
        memoLog.Lines.Add(FrameProcessor1.GetDiagnosticReport);
      end
      else
        LogMsg('Erro de processamento: ' + FrameProcessor1.LastError);
    finally
      LInputBmp.Free;
    end;
  end;
end;

procedure TfrmMain.btnSaveClick(Sender: TObject);
begin
  if imgProcessed.Picture.Bitmap.Width <= 0 then
  begin
    LogMsg('Aviso: Nenhuma imagem processada para salvar.');
    Exit;
  end;

  if SaveDialog1.Execute then
  begin
    if FrameProcessor1.SaveBitmapToFile(imgProcessed.Picture.Bitmap, SaveDialog1.FileName) then
      LogMsg('Imagem salva com sucesso em: ' + SaveDialog1.FileName)
    else
      LogMsg('Erro ao salvar imagem: ' + FrameProcessor1.LastError);
  end;
end;

procedure TfrmMain.ResetBtnClick(Sender: TObject);
begin
  FrameProcessor1.ResetDefaults;
  SyncPropertiesToUI;
  LogMsg('Propriedades restauradas aos valores padrão.');
end;

end.
