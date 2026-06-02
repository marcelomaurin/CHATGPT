unit numps;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, LResources;

type
  TArray = array of Double;
  TMatrix = array of TArray;

  { TNumPS }

  TNumPS = class(TComponent)
  public
    constructor Create(AOwner: TComponent); override;

    // Array / Matrix Creation
    function Zeros(Rows, Cols: Integer): TMatrix;
    function Zeros1D(Size: Integer): TArray;
    function Ones(Rows, Cols: Integer): TMatrix;
    function Ones1D(Size: Integer): TArray;
    function Arange(Start, Stop, Step: Double): TArray;
    function LinSpace(Start, Stop: Double; Num: Integer): TArray;
    function Random(Rows, Cols: Integer): TMatrix;
    function Random1D(Size: Integer): TArray;
    function Eye(N: Integer): TMatrix;

    // Vector Element-wise Operations
    function Add(const A, B: TArray): TArray;
    function Subtract(const A, B: TArray): TArray;
    function Multiply(const A, B: TArray): TArray;
    function Divide(const A, B: TArray): TArray;
    function Scale(const A: TArray; Factor: Double): TArray;

    // Matrix Element-wise Operations
    function MatrixAdd(const A, B: TMatrix): TMatrix;
    function MatrixSubtract(const A, B: TMatrix): TMatrix;
    function MatrixMultiplyElements(const A, B: TMatrix): TMatrix;
    function MatrixDivideElements(const A, B: TMatrix): TMatrix;
    function MatrixScale(const A: TMatrix; Factor: Double): TMatrix;

    // Linear Algebra Operations
    function Dot(const A, B: TArray): Double;
    function MatMul(const A, B: TMatrix): TMatrix;
    function Transpose(const A: TMatrix): TMatrix;

    // Element-wise Math Functions
    function Sin(const A: TArray): TArray;
    function Cos(const A: TArray): TArray;
    function Exp(const A: TArray): TArray;
    function Log(const A: TArray): TArray;
    function Sqrt(const A: TArray): TArray;
    function Power(const A: TArray; Exponent: Double): TArray;

    // Statistics
    function Sum(const A: TArray): Double;
    function Mean(const A: TArray): Double;
    function Std(const A: TArray): Double;
    function Min(const A: TArray): Double;
    function Max(const A: TArray): Double;
    function ArgMin(const A: TArray): Integer;
    function ArgMax(const A: TArray): Integer;

    function MatrixSum(const A: TMatrix): Double;
    function MatrixMean(const A: TMatrix): Double;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA Math', [TNumPS]);
end;

{ TNumPS }

constructor TNumPS.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

// Array / Matrix Creation

function TNumPS.Zeros(Rows, Cols: Integer): TMatrix;
var
  I, J: Integer;
begin
  SetLength(Result, Rows, Cols);
  for I := 0 to Rows - 1 do
    for J := 0 to Cols - 1 do
      Result[I, J] := 0.0;
end;

function TNumPS.Zeros1D(Size: Integer): TArray;
var
  I: Integer;
begin
  SetLength(Result, Size);
  for I := 0 to Size - 1 do
    Result[I] := 0.0;
end;

function TNumPS.Ones(Rows, Cols: Integer): TMatrix;
var
  I, J: Integer;
begin
  SetLength(Result, Rows, Cols);
  for I := 0 to Rows - 1 do
    for J := 0 to Cols - 1 do
      Result[I, J] := 1.0;
end;

function TNumPS.Ones1D(Size: Integer): TArray;
var
  I: Integer;
begin
  SetLength(Result, Size);
  for I := 0 to Size - 1 do
    Result[I] := 1.0;
end;

function TNumPS.Arange(Start, Stop, Step: Double): TArray;
var
  Count, I: Integer;
  Val: Double;
begin
  if Step = 0.0 then
    raise Exception.Create('Arange step cannot be zero.');
  Count := Floor((Stop - Start) / Step);
  if Count < 0 then
    Count := 0;
  SetLength(Result, Count);
  Val := Start;
  for I := 0 to Count - 1 do
  begin
    Result[I] := Val;
    Val := Val + Step;
  end;
end;

function TNumPS.LinSpace(Start, Stop: Double; Num: Integer): TArray;
var
  I: Integer;
  StepValue: Double;
begin
  if Num <= 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;
  if Num = 1 then
  begin
    SetLength(Result, 1);
    Result[0] := Start;
    Exit;
  end;
  SetLength(Result, Num);
  StepValue := (Stop - Start) / (Num - 1);
  for I := 0 to Num - 1 do
    Result[I] := Start + I * StepValue;
end;

function TNumPS.Random(Rows, Cols: Integer): TMatrix;
var
  I, J: Integer;
begin
  Randomize;
  SetLength(Result, Rows, Cols);
  for I := 0 to Rows - 1 do
    for J := 0 to Cols - 1 do
      Result[I, J] := System.Random;
end;

function TNumPS.Random1D(Size: Integer): TArray;
var
  I: Integer;
begin
  Randomize;
  SetLength(Result, Size);
  for I := 0 to Size - 1 do
    Result[I] := System.Random;
end;

// Identity Matrix
function TNumPS.Eye(N: Integer): TMatrix;
var
  I, J: Integer;
begin
  SetLength(Result, N, N);
  for I := 0 to N - 1 do
    for J := 0 to N - 1 do
    begin
      if I = J then
        Result[I, J] := 1.0
      else
        Result[I, J] := 0.0;
    end;
end;

// Vector Element-wise Operations

function TNumPS.Add(const A, B: TArray): TArray;
var
  I, Len: Integer;
begin
  Len := Math.Min(Length(A), Length(B));
  SetLength(Result, Len);
  for I := 0 to Len - 1 do
    Result[I] := A[I] + B[I];
end;

function TNumPS.Subtract(const A, B: TArray): TArray;
var
  I, Len: Integer;
begin
  Len := Math.Min(Length(A), Length(B));
  SetLength(Result, Len);
  for I := 0 to Len - 1 do
    Result[I] := A[I] - B[I];
end;

function TNumPS.Multiply(const A, B: TArray): TArray;
var
  I, Len: Integer;
begin
  Len := Math.Min(Length(A), Length(B));
  SetLength(Result, Len);
  for I := 0 to Len - 1 do
    Result[I] := A[I] * B[I];
end;

function TNumPS.Divide(const A, B: TArray): TArray;
var
  I, Len: Integer;
begin
  Len := Math.Min(Length(A), Length(B));
  SetLength(Result, Len);
  for I := 0 to Len - 1 do
  begin
    if B[I] <> 0.0 then
      Result[I] := A[I] / B[I]
    else
      Result[I] := 0.0;
  end;
end;

function TNumPS.Scale(const A: TArray; Factor: Double): TArray;
var
  I: Integer;
begin
  SetLength(Result, Length(A));
  for I := 0 to High(A) do
    Result[I] := A[I] * Factor;
end;

// Matrix Element-wise Operations

function TNumPS.MatrixAdd(const A, B: TMatrix): TMatrix;
var
  I, J, Rows, Cols: Integer;
begin
  Rows := Math.Min(Length(A), Length(B));
  if Rows = 0 then
    Exit;
  Cols := Math.Min(Length(A[0]), Length(B[0]));
  SetLength(Result, Rows, Cols);
  for I := 0 to Rows - 1 do
    for J := 0 to Cols - 1 do
      Result[I, J] := A[I, J] + B[I, J];
end;

function TNumPS.MatrixSubtract(const A, B: TMatrix): TMatrix;
var
  I, J, Rows, Cols: Integer;
begin
  Rows := Math.Min(Length(A), Length(B));
  if Rows = 0 then
    Exit;
  Cols := Math.Min(Length(A[0]), Length(B[0]));
  SetLength(Result, Rows, Cols);
  for I := 0 to Rows - 1 do
    for J := 0 to Cols - 1 do
      Result[I, J] := A[I, J] - B[I, J];
end;

function TNumPS.MatrixMultiplyElements(const A, B: TMatrix): TMatrix;
var
  I, J, Rows, Cols: Integer;
begin
  Rows := Math.Min(Length(A), Length(B));
  if Rows = 0 then
    Exit;
  Cols := Math.Min(Length(A[0]), Length(B[0]));
  SetLength(Result, Rows, Cols);
  for I := 0 to Rows - 1 do
    for J := 0 to Cols - 1 do
      Result[I, J] := A[I, J] * B[I, J];
end;

function TNumPS.MatrixDivideElements(const A, B: TMatrix): TMatrix;
var
  I, J, Rows, Cols: Integer;
begin
  Rows := Math.Min(Length(A), Length(B));
  if Rows = 0 then
    Exit;
  Cols := Math.Min(Length(A[0]), Length(B[0]));
  SetLength(Result, Rows, Cols);
  for I := 0 to Rows - 1 do
    for J := 0 to Cols - 1 do
    begin
      if B[I, J] <> 0.0 then
        Result[I, J] := A[I, J] / B[I, J]
      else
        Result[I, J] := 0.0;
    end;
end;

function TNumPS.MatrixScale(const A: TMatrix; Factor: Double): TMatrix;
var
  I, J, Rows, Cols: Integer;
begin
  Rows := Length(A);
  if Rows = 0 then
    Exit;
  Cols := Length(A[0]);
  SetLength(Result, Rows, Cols);
  for I := 0 to Rows - 1 do
    for J := 0 to Cols - 1 do
      Result[I, J] := A[I, J] * Factor;
end;

// Linear Algebra Operations

function TNumPS.Dot(const A, B: TArray): Double;
var
  I, Len: Integer;
begin
  Result := 0.0;
  Len := Math.Min(Length(A), Length(B));
  for I := 0 to Len - 1 do
    Result := Result + A[I] * B[I];
end;

function TNumPS.MatMul(const A, B: TMatrix): TMatrix;
var
  I, J, K: Integer;
begin
  if (Length(A) = 0) or (Length(B) = 0) or (Length(A[0]) <> Length(B)) then
    raise Exception.Create('MatMul dimension mismatch.');
  SetLength(Result, Length(A), Length(B[0]));
  for I := 0 to High(A) do
    for J := 0 to High(B[0]) do
    begin
      Result[I, J] := 0.0;
      for K := 0 to High(A[0]) do
        Result[I, J] := Result[I, J] + A[I, K] * B[K, J];
    end;
end;

function TNumPS.Transpose(const A: TMatrix): TMatrix;
var
  I, J, Rows, Cols: Integer;
begin
  Rows := Length(A);
  if Rows = 0 then
    Exit;
  Cols := Length(A[0]);
  SetLength(Result, Cols, Rows);
  for I := 0 to Rows - 1 do
    for J := 0 to Cols - 1 do
      Result[J, I] := A[I, J];
end;

// Element-wise Math Functions

function TNumPS.Sin(const A: TArray): TArray;
var
  I: Integer;
begin
  SetLength(Result, Length(A));
  for I := 0 to High(A) do
    Result[I] := System.Sin(A[I]);
end;

function TNumPS.Cos(const A: TArray): TArray;
var
  I: Integer;
begin
  SetLength(Result, Length(A));
  for I := 0 to High(A) do
    Result[I] := System.Cos(A[I]);
end;

function TNumPS.Exp(const A: TArray): TArray;
var
  I: Integer;
begin
  SetLength(Result, Length(A));
  for I := 0 to High(A) do
    Result[I] := System.Exp(A[I]);
end;

function TNumPS.Log(const A: TArray): TArray;
var
  I: Integer;
begin
  SetLength(Result, Length(A));
  for I := 0 to High(A) do
  begin
    if A[I] > 0.0 then
      Result[I] := System.Ln(A[I])
    else
      Result[I] := 0.0;
  end;
end;

function TNumPS.Sqrt(const A: TArray): TArray;
var
  I: Integer;
begin
  SetLength(Result, Length(A));
  for I := 0 to High(A) do
  begin
    if A[I] >= 0.0 then
      Result[I] := System.Sqrt(A[I])
    else
      Result[I] := 0.0;
  end;
end;

function TNumPS.Power(const A: TArray; Exponent: Double): TArray;
var
  I: Integer;
begin
  SetLength(Result, Length(A));
  for I := 0 to High(A) do
    Result[I] := Math.Power(A[I], Exponent);
end;

// Statistics

function TNumPS.Sum(const A: TArray): Double;
var
  I: Integer;
begin
  Result := 0.0;
  for I := 0 to High(A) do
    Result := Result + A[I];
end;

function TNumPS.Mean(const A: TArray): Double;
begin
  if Length(A) = 0 then
    Result := 0.0
  else
    Result := Sum(A) / Length(A);
end;

function TNumPS.Std(const A: TArray): Double;
var
  M, VarianceSum: Double;
  I: Integer;
begin
  if Length(A) <= 1 then
  begin
    Result := 0.0;
    Exit;
  end;
  M := Mean(A);
  VarianceSum := 0.0;
  for I := 0 to High(A) do
    VarianceSum := VarianceSum + Sqr(A[I] - M);
  Result := System.Sqrt(VarianceSum / Length(A));
end;

function TNumPS.Min(const A: TArray): Double;
var
  I: Integer;
begin
  if Length(A) = 0 then
    raise Exception.Create('Empty vector.');
  Result := A[0];
  for I := 1 to High(A) do
    if A[I] < Result then
      Result := A[I];
end;

function TNumPS.Max(const A: TArray): Double;
var
  I: Integer;
begin
  if Length(A) = 0 then
    raise Exception.Create('Empty vector.');
  Result := A[0];
  for I := 1 to High(A) do
    if A[I] > Result then
      Result := A[I];
end;

function TNumPS.ArgMin(const A: TArray): Integer;
var
  I: Integer;
  MinVal: Double;
begin
  if Length(A) = 0 then
    raise Exception.Create('Empty vector.');
  Result := 0;
  MinVal := A[0];
  for I := 1 to High(A) do
    if A[I] < MinVal then
    begin
      MinVal := A[I];
      Result := I;
    end;
end;

function TNumPS.ArgMax(const A: TArray): Integer;
var
  I: Integer;
  MaxVal: Double;
begin
  if Length(A) = 0 then
    raise Exception.Create('Empty vector.');
  Result := 0;
  MaxVal := A[0];
  for I := 1 to High(A) do
    if A[I] > MaxVal then
    begin
      MaxVal := A[I];
      Result := I;
    end;
end;

function TNumPS.MatrixSum(const A: TMatrix): Double;
var
  I: Integer;
begin
  Result := 0.0;
  for I := 0 to High(A) do
    Result := Result + Sum(A[I]);
end;

function TNumPS.MatrixMean(const A: TMatrix): Double;
var
  TotalElements, I: Integer;
begin
  TotalElements := 0;
  for I := 0 to High(A) do
    TotalElements := TotalElements + Length(A[I]);
  if TotalElements = 0 then
    Result := 0.0
  else
    Result := MatrixSum(A) / TotalElements;
end;

initialization
  {$I numps_icon.lrs}

end.
