unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  numps, aiinput, aioutput, Math;

type

  { TfrmDemo }

  TfrmDemo = class(TForm)
    btnExecMath: TButton;
    btnNormalize: TButton;
    btnDenormalize: TButton;
    btnSoftmax: TButton;
    cbMathOp: TComboBox;
    edtInputData: TEdit;
    edtMinRange: TEdit;
    edtMaxRange: TEdit;
    lblResult: TLabel;
    lblMathParams: TLabel;
    lblInputInfo: TLabel;
    lblClasses: TLabel;
    lblLogits: TLabel;
    memMathOutput: TMemo;
    memInputOutput: TMemo;
    memClasses: TMemo;
    memLogits: TMemo;
    memOutputScores: TMemo;
    PageControl1: TPageControl;
    tabMath: TTabSheet;
    tabInput: TTabSheet;
    tabOutput: TTabSheet;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnExecMathClick(Sender: TObject);
    procedure btnNormalizeClick(Sender: TObject);
    procedure btnDenormalizeClick(Sender: TObject);
    procedure btnSoftmaxClick(Sender: TObject);
  private
    FNumPS: TNumPS;
    FAIInput: TAIInputData;
    FAIOutput: TAIOutputData;
    function MatrixToString(const M: TMatrix): string;
    function ArrayToString(const A: TArray): string;
  public
  end;

var
  frmDemo: TfrmDemo;

implementation

{$R *.lfm}

{ TfrmDemo }

function TfrmDemo.MatrixToString(const M: TMatrix): string;
var
  I, J: Integer;
  RowStr: string;
begin
  Result := '';
  for I := 0 to High(M) do
  begin
    RowStr := '  [';
    for J := 0 to High(M[I]) do
    begin
      RowStr := RowStr + Format('%0.4f', [M[I, J]]);
      if J < High(M[I]) then
        RowStr := RowStr + ', ';
    end;
    RowStr := RowStr + ']';
    Result := Result + RowStr + sLineBreak;
  end;
end;

function TfrmDemo.ArrayToString(const A: TArray): string;
var
  I: Integer;
begin
  Result := '[';
  for I := 0 to High(A) do
  begin
    Result := Result + Format('%0.4f', [A[I]]);
    if I < High(A) then
      Result := Result + ', ';
  end;
  Result := Result + ']';
end;

procedure TfrmDemo.FormCreate(Sender: TObject);
begin
  FNumPS := TNumPS.Create(Self);
  FAIInput := TAIInputData.Create(Self);
  FAIOutput := TAIOutputData.Create(Self);
  
  cbMathOp.ItemIndex := 0;
end;

procedure TfrmDemo.FormDestroy(Sender: TObject);
begin
  // Self is the owner of FNumPS, FAIInput, FAIOutput, so they will be freed automatically.
end;

procedure TfrmDemo.btnExecMathClick(Sender: TObject);
var
  OpName: string;
  ArrValue: TArray;
  MatA, MatB, MatC: TMatrix;
begin
  OpName := cbMathOp.Text;
  memMathOutput.Clear;
  
  if OpName = 'Zeros (3x3)' then
  begin
    MatA := FNumPS.Zeros(3, 3);
    memMathOutput.Lines.Add('=== TNumPS.Zeros(3, 3) ===');
    memMathOutput.Lines.Add(MatrixToString(MatA));
  end
  else if OpName = 'Ones (3x3)' then
  begin
    MatA := FNumPS.Ones(3, 3);
    memMathOutput.Lines.Add('=== TNumPS.Ones(3, 3) ===');
    memMathOutput.Lines.Add(MatrixToString(MatA));
  end
  else if OpName = 'Arange (0..10, step 2)' then
  begin
    ArrValue := FNumPS.Arange(0, 10, 2);
    memMathOutput.Lines.Add('=== TNumPS.Arange(0, 10, 2) ===');
    memMathOutput.Lines.Add(ArrayToString(ArrValue));
  end
  else if OpName = 'LinSpace (0..1, 5 steps)' then
  begin
    ArrValue := FNumPS.LinSpace(0, 1, 5);
    memMathOutput.Lines.Add('=== TNumPS.LinSpace(0, 1, 5) ===');
    memMathOutput.Lines.Add(ArrayToString(ArrValue));
  end
  else if OpName = 'Identity (4x4)' then
  begin
    MatA := FNumPS.Eye(4);
    memMathOutput.Lines.Add('=== TNumPS.Eye(4) ===');
    memMathOutput.Lines.Add(MatrixToString(MatA));
  end
  else if OpName = 'Random Matrix (3x3)' then
  begin
    MatA := FNumPS.Random(3, 3);
    memMathOutput.Lines.Add('=== TNumPS.Random(3, 3) ===');
    memMathOutput.Lines.Add(MatrixToString(MatA));
  end
  else if OpName = 'MatMul (Matrix Multiplication)' then
  begin
    SetLength(MatA, 2, 3);
    MatA[0, 0] := 1; MatA[0, 1] := 2; MatA[0, 2] := 3;
    MatA[1, 0] := 4; MatA[1, 1] := 5; MatA[1, 2] := 6;
    
    SetLength(MatB, 3, 2);
    MatB[0, 0] := 7;  MatB[0, 1] := 8;
    MatB[1, 0] := 9;  MatB[1, 1] := 10;
    MatB[2, 0] := 11; MatB[2, 1] := 12;
    
    MatC := FNumPS.MatMul(MatA, MatB);
    memMathOutput.Lines.Add('=== MatA (2x3) ===');
    memMathOutput.Lines.Add(MatrixToString(MatA));
    memMathOutput.Lines.Add('=== MatB (3x2) ===');
    memMathOutput.Lines.Add(MatrixToString(MatB));
    memMathOutput.Lines.Add('=== TNumPS.MatMul(MatA, MatB) (2x2) ===');
    memMathOutput.Lines.Add(MatrixToString(MatC));
  end
  else if OpName = 'Statistics on [1.2, 4.5, 9.8, -2.1]' then
  begin
    SetLength(ArrValue, 4);
    ArrValue[0] := 1.2; ArrValue[1] := 4.5; ArrValue[2] := 9.8; ArrValue[3] := -2.1;
    
    memMathOutput.Lines.Add('=== Vetor: [1.2, 4.5, 9.8, -2.1] ===');
    memMathOutput.Lines.Add(Format('Soma (Sum): %0.4f', [FNumPS.Sum(ArrValue)]));
    memMathOutput.Lines.Add(Format('Média (Mean): %0.4f', [FNumPS.Mean(ArrValue)]));
    memMathOutput.Lines.Add(Format('Desvio Padrão (Std): %0.4f', [FNumPS.Std(ArrValue)]));
    memMathOutput.Lines.Add(Format('Mínimo (Min): %0.4f em índice %d', [FNumPS.Min(ArrValue), FNumPS.ArgMin(ArrValue)]));
    memMathOutput.Lines.Add(Format('Máximo (Max): %0.4f em índice %d', [FNumPS.Max(ArrValue), FNumPS.ArgMax(ArrValue)]));
  end;
end;

procedure TfrmDemo.btnNormalizeClick(Sender: TObject);
begin
  memInputOutput.Clear;
  FAIInput.MinRange := StrToFloatDef(edtMinRange.Text, 0.0);
  FAIInput.MaxRange := StrToFloatDef(edtMaxRange.Text, 1.0);
  
  FAIInput.LoadFromString(edtInputData.Text, ',');
  memInputOutput.Lines.Add('=== Dados Originais (RawData) ===');
  memInputOutput.Lines.Add(ArrayToString(FAIInput.RawData));
  
  FAIInput.Normalize;
  memInputOutput.Lines.Add('=== Dados Normalizados (NormalizedData) ===');
  memInputOutput.Lines.Add(ArrayToString(FAIInput.NormalizedData));
end;

procedure TfrmDemo.btnDenormalizeClick(Sender: TObject);
begin
  if FAIInput.GetLength = 0 then
  begin
    ShowMessage('Primeiro clique em Normalizar para carregar e normalizar os dados.');
    Exit;
  end;
  FAIInput.Denormalize;
  memInputOutput.Lines.Add('=== Dados Desnormalizados (Denormalized) ===');
  memInputOutput.Lines.Add(ArrayToString(FAIInput.RawData));
end;

procedure TfrmDemo.btnSoftmaxClick(Sender: TObject);
var
  I: Integer;
  LogitsArr: TArray;
begin
  memOutputScores.Clear;
  FAIOutput.Classes.Clear;
  for I := 0 to memClasses.Lines.Count - 1 do
    if Trim(memClasses.Lines[I]) <> '' then
      FAIOutput.Classes.Add(Trim(memClasses.Lines[I]));
      
  SetLength(LogitsArr, memLogits.Lines.Count);
  for I := 0 to memLogits.Lines.Count - 1 do
    LogitsArr[I] := StrToFloatDef(Trim(memLogits.Lines[I]), 0.0);
    
  FAIOutput.Probabilities := LogitsArr;
  
  memOutputScores.Lines.Add('=== Logits Originais ===');
  memOutputScores.Lines.Add(ArrayToString(FAIOutput.Probabilities));
  
  FAIOutput.SoftMax;
  
  memOutputScores.Lines.Add('=== Probabilidades SoftMax ===');
  memOutputScores.Lines.Add(ArrayToString(FAIOutput.Probabilities));
  
  for I := 0 to High(FAIOutput.Probabilities) do
  begin
    if I < FAIOutput.Classes.Count then
      memOutputScores.Lines.Add(Format('%s: %0.2f%%', [FAIOutput.Classes[I], FAIOutput.Probabilities[I] * 100.0]))
    else
      memOutputScores.Lines.Add(Format('Classe %d: %0.2f%%', [I, FAIOutput.Probabilities[I] * 100.0]));
  end;
  
  lblResult.Caption := 'Decisão: ' + FAIOutput.ClassificationResult;
end;

end.
