unit aigpu;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, LResources;

type
  TAIGPUInfo = record
    Name: string;
    MemoryTotalMB: QWord;
    MemoryUsedMB: QWord;
    MemoryFreeMB: QWord;
    CUDACoreCount: Integer;
    UsagePercent: Double;
  end;

  TAIGPU = class(TComponent)
  private
    FLastInfo: TAIGPUInfo;
  public
    constructor Create(AOwner: TComponent); override;
    function RefreshInfo: TAIGPUInfo;
    function GetGPUName: string;
    function GetMemoryTotalMB: QWord;
    function GetMemoryUsedMB: QWord;
    function GetMemoryFreeMB: QWord;
    function GetCUDACoreCount: Integer;
    function GetUsagePercent: Double;
  public
    property LastInfo: TAIGPUInfo read FLastInfo;
  end;

procedure Register;

implementation

function TAIGPU.GetGPUName: string;
begin
  Result := 'Unknown GPU';
end;

function TAIGPU.GetMemoryTotalMB: QWord;
begin
  Result := 0;
end;

function TAIGPU.GetMemoryUsedMB: QWord;
begin
  Result := 0;
end;

function TAIGPU.GetMemoryFreeMB: QWord;
begin
  Result := 0;
end;

function TAIGPU.GetCUDACoreCount: Integer;
begin
  Result := 0;
end;

function TAIGPU.GetUsagePercent: Double;
begin
  Result := 0;
end;

constructor TAIGPU.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FillChar(FLastInfo, SizeOf(FLastInfo), 0);
end;

function TAIGPU.RefreshInfo: TAIGPUInfo;
begin
  FLastInfo.Name := GetGPUName;
  FLastInfo.MemoryTotalMB := GetMemoryTotalMB;
  FLastInfo.MemoryUsedMB := GetMemoryUsedMB;
  FLastInfo.MemoryFreeMB := GetMemoryFreeMB;
  FLastInfo.CUDACoreCount := GetCUDACoreCount;
  FLastInfo.UsagePercent := GetUsagePercent;
  Result := FLastInfo;
end;

procedure Register;
begin
  RegisterComponents('AI Hardware', [TAIGPU]);
end;

end.
