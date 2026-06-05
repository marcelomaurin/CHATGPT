unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, ainativeimagefilter, aiimageinfo, aibase, LCLType;

type

  { TfrmFilterDemo }

  TfrmFilterDemo = class(TForm)
    pnlLeft: TPanel;
    pnlClient: TPanel;
    pnlBottom: TPanel;
    pnlOriginal: TPanel;
    pnlProcessed: TPanel;
    Splitter1: TSplitter;
    
    btnLoad: TButton;
    btnSave: TButton;
    btnApply: TButton;
    
    cbFilterType: TComboBox;
    lblFilter: TLabel;
    
    lblThreshold: TLabel;
    edThreshold: TEdit;
    
    lblWidth: TLabel;
    edWidth: TEdit;
    lblHeight: TLabel;
    edHeight: TEdit;
    
    imgOriginal: TImage;
    imgProcessed: TImage;
    
    lblInfoOrig: TLabel;
    lblInfoProc: TLabel;
    
    memLog: TMemo;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;

    procedure FormCreate(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure cbFilterTypeChange(Sender: TObject);
  private
    Filter: TAINativeImageFilter;
    Info: TAIImageInfo;
    OriginalBmp: TBitmap;
    ProcessedBmp: TBitmap;
    procedure LogMsg(const AMsg: string);
    procedure UpdateUI;
  public

  end;

var
  frmFilterDemo: TfrmFilterDemo;

implementation

{$R *.lfm}

{ TfrmFilterDemo }

procedure TfrmFilterDemo.FormCreate(Sender: TObject);
begin
  Filter := TAINativeImageFilter.Create(Self);
  Info := TAIImageInfo.Create(Self);
  OriginalBmp := TBitmap.Create;
  ProcessedBmp := TBitmap.Create;
  
  cbFilterType.Items.Clear;
  cbFilterType.Items.Add('None');
  cbFilterType.Items.Add('Grayscale (Gray)');
  cbFilterType.Items.Add('Threshold (Binarize)');
  cbFilterType.Items.Add('Invert Colors');
  cbFilterType.Items.Add('Resize');
  cbFilterType.Items.Add('Box Blur');
  cbFilterType.ItemIndex := 0;

  edThreshold.Text := '128';
  edWidth.Text := '320';
  edHeight.Text := '240';
  
  UpdateUI;
  LogMsg('Native Image Filter Demo Initialized.');
end;

procedure TfrmFilterDemo.btnLoadClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    LogMsg('Loading image from: ' + OpenDialog1.FileName);
    try
      OriginalBmp.LoadFromFile(OpenDialog1.FileName);
      imgOriginal.Picture.Assign(OriginalBmp);
      
      // Load details using TAIImageInfo
      if Info.LoadInfoFromBitmap(OriginalBmp) then
      begin
        lblInfoOrig.Caption := Format('Original: %dx%d (%d px)', [Info.Width, Info.Height, Info.PixelCount]);
        edWidth.Text := IntToStr(Info.Width div 2);
        edHeight.Text := IntToStr(Info.Height div 2);
      end;
      
      ProcessedBmp.Assign(OriginalBmp);
      imgProcessed.Picture.Assign(ProcessedBmp);
      lblInfoProc.Caption := 'Processed: same as original';
      
      LogMsg(Format('Image loaded successfully: %s', [Info.AsText]));
    except
      on E: Exception do
      begin
        LogMsg('Error loading image: ' + E.Message);
        ShowMessage('Failed to load image: ' + E.Message);
      end;
    end;
  end;
end;

procedure TfrmFilterDemo.btnApplyClick(Sender: TObject);
var
  TStart, TEnd: TDateTime;
  ElapsedMs: Double;
begin
  if OriginalBmp.Width = 0 then
  begin
    ShowMessage('Please load an original image first.');
    Exit;
  end;

  LogMsg('Applying filter...');
  
  // Set up filter properties
  case cbFilterType.ItemIndex of
    0: Filter.FilterType := niftNone;
    1: Filter.FilterType := niftGray;
    2: Filter.FilterType := niftThreshold;
    3: Filter.FilterType := niftInvert;
    4: Filter.FilterType := niftResize;
    5: Filter.FilterType := niftBlurBox;
  end;
  
  Filter.ThresholdValue := StrToIntDef(edThreshold.Text, 128);
  Filter.ResizeWidth := StrToIntDef(edWidth.Text, 320);
  Filter.ResizeHeight := StrToIntDef(edHeight.Text, 240);
  
  ProcessedBmp.Assign(OriginalBmp);
  
  TStart := Now;
  if Filter.ApplyToBitmap(ProcessedBmp) then
  begin
    TEnd := Now;
    ElapsedMs := (TEnd - TStart) * 24.0 * 60.0 * 60.0 * 1000.0;
    
    imgProcessed.Picture.Assign(ProcessedBmp);
    lblInfoProc.Caption := Format('Processed: %dx%d (Filtered in %.2f ms)', 
      [ProcessedBmp.Width, ProcessedBmp.Height, ElapsedMs]);
    LogMsg(Format('Successfully applied filter type index %d in %.2f ms. Info: %s', 
      [cbFilterType.ItemIndex, ElapsedMs, Filter.LastResult]));
  end;
end;

procedure TfrmFilterDemo.btnSaveClick(Sender: TObject);
begin
  if ProcessedBmp.Width = 0 then
  begin
    ShowMessage('No processed image to save.');
    Exit;
  end;

  if SaveDialog1.Execute then
  begin
    LogMsg('Saving processed image to: ' + SaveDialog1.FileName);
    try
      ProcessedBmp.SaveToFile(SaveDialog1.FileName);
      LogMsg('Saved successfully.');
    except
      on E: Exception do
      begin
        LogMsg('Error saving image: ' + E.Message);
        ShowMessage('Failed to save image: ' + E.Message);
      end;
    end;
  end;
end;

procedure TfrmFilterDemo.cbFilterTypeChange(Sender: TObject);
begin
  UpdateUI;
end;

procedure TfrmFilterDemo.UpdateUI;
begin
  // Enable/disable inputs based on chosen filter
  edThreshold.Enabled := cbFilterType.ItemIndex = 2;
  edWidth.Enabled := cbFilterType.ItemIndex = 4;
  edHeight.Enabled := cbFilterType.ItemIndex = 4;
end;

procedure TfrmFilterDemo.LogMsg(const AMsg: string);
begin
  memLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + ' - ' + AMsg);
end;

end.
