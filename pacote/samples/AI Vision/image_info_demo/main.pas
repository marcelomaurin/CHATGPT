unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Clipbrd, aiimageinfo, lazpng;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnOpen: TButton;
    btnReadInfo: TButton;
    btnClearLog: TButton;
    btnCopyReport: TButton;
    edFileName: TEdit;
    imgPreview: TImage;
    lblStatus: TLabel;
    lblTitle: TLabel;
    memoLog: TMemo;
    OpenDialog1: TOpenDialog;
    pnlTop: TPanel;
    procedure btnClearLogClick(Sender: TObject);
    procedure btnCopyReportClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnReadInfoClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FAIImageInfo: TAIImageInfo;
    procedure AddLog(const AMsg: string);
    procedure UpdateStatus(const AMsg: string);
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FAIImageInfo := TAIImageInfo.Create(Self);

  lblTitle.Caption := 'TAIImageInfo Demo';
  UpdateStatus('Ready');

  OpenDialog1.Filter :=
    'Image files|*.png;*.jpg;*.jpeg;*.bmp;*.gif;*.tif;*.tiff|' +
    'PNG|*.png|' +
    'JPEG|*.jpg;*.jpeg|' +
    'Bitmap|*.bmp|' +
    'All files|*.*';

  AddLog('TAIImageInfo Demo initialized.');
end;

procedure TfrmMain.btnOpenClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    edFileName.Text := OpenDialog1.FileName;

    try
      imgPreview.Picture.LoadFromFile(edFileName.Text);
      imgPreview.Proportional := True;
      imgPreview.Stretch := True;
      imgPreview.Center := True;

      AddLog('Image selected: ' + edFileName.Text);
      UpdateStatus('Image loaded for preview');
    except
      on E: Exception do
      begin
        AddLog('Preview error: ' + E.Message);
        UpdateStatus('Preview error');
      end;
    end;
  end;
end;

procedure TfrmMain.btnReadInfoClick(Sender: TObject);
begin
  memoLog.Clear;
  AddLog('--- Reading Image Info ---');

  if Trim(edFileName.Text) = '' then
  begin
    AddLog('No image file selected.');
    UpdateStatus('No file selected');
    Exit;
  end;

  if FAIImageInfo.LoadInfoFromFile(edFileName.Text) then
  begin
    AddLog(FAIImageInfo.AsText);
    UpdateStatus('Image info loaded successfully');
  end
  else
  begin
    AddLog('Error: ' + FAIImageInfo.LastError);
    UpdateStatus('Error reading image info');
  end;

  AddLog('--- Finished ---');
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
  UpdateStatus('Log cleared');
end;

procedure TfrmMain.btnCopyReportClick(Sender: TObject);
begin
  Clipboard.AsText := memoLog.Text;
  UpdateStatus('Report copied to clipboard');
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(AMsg);
end;

procedure TfrmMain.UpdateStatus(const AMsg: string);
begin
  lblStatus.Caption := 'Status: ' + AMsg;
end;

end.
