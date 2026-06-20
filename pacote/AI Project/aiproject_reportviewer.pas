unit aiproject_reportviewer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, StdCtrls, Dialogs,
  aiproject, aiproject_reports;

type
  { TAIProjectReportViewer — frame with report selector and export buttons }
  TAIProjectReportViewer = class(TCustomControl)
  private
    FProject: TAIProject;
    FReports: TAIProjectReports;
    FCbReportType: TComboBox;
    FMemoContent: TMemo;
    FBtnGenerate: TButton;
    FBtnExportMD: TButton;
    FBtnExportJSON: TButton;

    procedure OnGenerateClick(Sender: TObject);
    procedure OnExportMDClick(Sender: TObject);
    procedure OnExportJSONClick(Sender: TObject);
    procedure SetProject(AValue: TAIProject);
    procedure BuildUI;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Project: TAIProject read FProject write SetProject;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectReportViewer]);
end;

procedure TAIProjectReportViewer.BuildUI;
begin
  Width := 700;
  Height := 420;

  FCbReportType := TComboBox.Create(Self);
  FCbReportType.Parent := Self;
  FCbReportType.SetBounds(10, 10, 250, 25);
  FCbReportType.Style := csDropDownList;
  FCbReportType.Items.Add('Project Summary');
  FCbReportType.Items.Add('Agile Documents');
  FCbReportType.Items.Add('Tasks');
  FCbReportType.Items.Add('Risks');
  FCbReportType.Items.Add('Agents');
  FCbReportType.Items.Add('Gantt');
  FCbReportType.Items.Add('Timeline');
  FCbReportType.Items.Add('Revision History');
  FCbReportType.ItemIndex := 0;

  FBtnGenerate := TButton.Create(Self);
  FBtnGenerate.Parent := Self;
  FBtnGenerate.SetBounds(270, 10, 100, 28);
  FBtnGenerate.Caption := 'Generate';
  FBtnGenerate.OnClick := @OnGenerateClick;

  FBtnExportMD := TButton.Create(Self);
  FBtnExportMD.Parent := Self;
  FBtnExportMD.SetBounds(380, 10, 100, 28);
  FBtnExportMD.Caption := 'Export .md';
  FBtnExportMD.OnClick := @OnExportMDClick;

  FBtnExportJSON := TButton.Create(Self);
  FBtnExportJSON.Parent := Self;
  FBtnExportJSON.SetBounds(490, 10, 100, 28);
  FBtnExportJSON.Caption := 'Export .json';
  FBtnExportJSON.OnClick := @OnExportJSONClick;

  FMemoContent := TMemo.Create(Self);
  FMemoContent.Parent := Self;
  FMemoContent.SetBounds(10, 48, 680, 360);
  FMemoContent.ScrollBars := ssAutoBoth;
  FMemoContent.ReadOnly := True;
  FMemoContent.TextHint := 'Select a report type and click Generate.';
end;

constructor TAIProjectReportViewer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FReports := TAIProjectReports.Create(Self);
  BuildUI;
end;

destructor TAIProjectReportViewer.Destroy;
begin
  FReports.Free;
  inherited Destroy;
end;

procedure TAIProjectReportViewer.SetProject(AValue: TAIProject);
begin
  if FProject = AValue then Exit;
  FProject := AValue;
  FReports.Project := AValue;
  FMemoContent.Clear;
end;

procedure TAIProjectReportViewer.OnGenerateClick(Sender: TObject);
var
  RType: TReportType;
begin
  if FCbReportType.ItemIndex < 0 then Exit;
  RType := TReportType(FCbReportType.ItemIndex);
  FMemoContent.Text := FReports.GenerateReport(RType);
end;

procedure TAIProjectReportViewer.OnExportMDClick(Sender: TObject);
var
  SD: TSaveDialog;
begin
  SD := TSaveDialog.Create(nil);
  try
    SD.Filter := 'Markdown Files (*.md)|*.md';
    SD.DefaultExt := 'md';
    if SD.Execute then
      FReports.ExportFullMarkdown(SD.FileName);
  finally
    SD.Free;
  end;
end;

procedure TAIProjectReportViewer.OnExportJSONClick(Sender: TObject);
var
  SD: TSaveDialog;
begin
  SD := TSaveDialog.Create(nil);
  try
    SD.Filter := 'JSON Files (*.json)|*.json';
    SD.DefaultExt := 'json';
    if SD.Execute then
      FReports.ExportFullJSON(SD.FileName);
  finally
    SD.Free;
  end;
end;

end.
