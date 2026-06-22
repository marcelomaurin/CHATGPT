unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, numps;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblStatus: TLabel;
    btnRun: TButton;
    btnClearLog: TButton;
    memoLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    FAINumps: TNumPS;
    FEditArr: TEdit;
    procedure AddLog(const AMsg: string);
    function ParseStringToDoubleArray(const S: string): TArray;
    function DoubleArrayToString(const A: TArray): string;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  AddLog('Numps Demo (numps) initialized.');
  FAINumps := TNumPS.Create(Self);
  
  FEditArr := TEdit.Create(Self);
  FEditArr.Parent := pnlTop;
  FEditArr.Left := 15;
  FEditArr.Top := 115;
  FEditArr.Width := 300;
  FEditArr.Text := '1.2, 4.5, -2.3, 0.0, 8.1';
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Handled by LCL Owner auto-free.
end;

function TfrmMain.ParseStringToDoubleArray(const S: string): TArray;
var
  List: TStringList;
  I: Integer;
  V: Double;
  FormatSettings: TFormatSettings;
begin
  Result := nil;
  List := TStringList.Create;
  try
    List.Delimiter := ',';
    List.StrictDelimiter := True;
    List.DelimitedText := S;
    SetLength(Result, List.Count);
    FormatSettings := DefaultFormatSettings;
    FormatSettings.DecimalSeparator := '.';
    for I := 0 to List.Count - 1 do
    begin
      if not TryStrToFloat(Trim(List[I]), V, FormatSettings) then
      begin
        if not TryStrToFloat(Trim(List[I]), V) then
          V := 0.0;
      end;
      Result[I] := V;
    end;
  finally
    List.Free;
  end;
end;

function TfrmMain.DoubleArrayToString(const A: TArray): string;
var
  I: Integer;
begin
  Result := '[';
  for I := 0 to High(A) do
  begin
    Result := Result + FloatToStr(A[I]);
    if I < High(A) then
      Result := Result + ', ';
  end;
  Result := Result + ']';
end;

procedure TfrmMain.btnRunClick(Sender: TObject);
var
  Arr: TArray;
  ZerosArr, OnesArr: TArray;
begin
  lblStatus.Caption := 'Status: Processing...';
  AddLog('--- Starting Execution ---');
  try
    AddLog('Input Array String: ' + FEditArr.Text);
    Arr := ParseStringToDoubleArray(FEditArr.Text);
    
    AddLog('Parsed vector length: ' + IntToStr(Length(Arr)));
    AddLog('Values: ' + DoubleArrayToString(Arr));
    
    if Length(Arr) > 0 then
    begin
      AddLog('Mean: ' + FloatToStr(FAINumps.Mean(Arr)));
      AddLog('Std (Standard Deviation): ' + FloatToStr(FAINumps.Std(Arr)));
      AddLog('Sum: ' + FloatToStr(FAINumps.Sum(Arr)));
      AddLog('Min: ' + FloatToStr(FAINumps.Min(Arr)));
      AddLog('Max: ' + FloatToStr(FAINumps.Max(Arr)));
      AddLog('ArgMin (index of Min): ' + IntToStr(FAINumps.ArgMin(Arr)));
      AddLog('ArgMax (index of Max): ' + IntToStr(FAINumps.ArgMax(Arr)));
    end
    else
    begin
      AddLog('Array is empty, skipping statistics.');
    end;

    AddLog('--- Demonstrating other NumPS array generators ---');
    ZerosArr := FAINumps.Zeros1D(5);
    AddLog('Zeros1D(5): ' + DoubleArrayToString(ZerosArr));
    
    OnesArr := FAINumps.Ones1D(5);
    AddLog('Ones1D(5): ' + DoubleArrayToString(OnesArr));

    lblStatus.Caption := 'Status: Completed Successfully';
  except
    on E: Exception do
    begin
      AddLog('Critical Error: ' + E.Message);
      lblStatus.Caption := 'Status: Execution Error';
    end;
  end;
  AddLog('--- Execution Finished ---');
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(AMsg);
end;

end.

