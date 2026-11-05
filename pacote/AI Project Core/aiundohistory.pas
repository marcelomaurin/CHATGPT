unit aiundohistory;

{ Lazarus AI Suite - AI Project Core
  Historico de desfazer/refazer por fotos (snapshots) do documento.

  Uso tipico:
    History.BeginChange('Editar nome', Doc.SaveToText);   // foto ANTES de mudar
    ... altera o documento ...
    History.EndChange;
    if History.CanUndo then Doc.LoadFromText(History.Undo(Doc.SaveToText));

  - BeginChange/EndChange podem ser aninhados: so o nivel externo grava foto,
    entao um comando composto vira um unico passo de desfazer.
  - Uma alteracao nova limpa a pilha de refazer.
  - Limite configuravel (padrao 100 passos); os mais antigos sao descartados.
  - A foto e texto livre (normalmente JSON); a classe nao conhece o documento. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  EAIUndoHistory = class(Exception);

  TAIUndoHistory = class
  private
    FUndo, FRedo: TStringList;
    FDepth: Integer;
    FLimit: Integer;
    FSuspended: Integer;
    procedure Push(L: TStringList; const Desc, Snap: string);
    class function Split(const Entry: string; out Desc: string): string; static;
    procedure SetLimit(AValue: Integer);
  public
    constructor Create(ALimit: Integer = 100);
    destructor Destroy; override;
    { grava a foto somente no nivel externo; True = foto gravada }
    function BeginChange(const Desc, Snapshot: string): Boolean;
    { True = o nivel externo terminou (o documento passa a "modificado") }
    function EndChange: Boolean;
    { retorna a foto a restaurar; CurrentSnapshot vai para a outra pilha }
    function Undo(const CurrentSnapshot: string): string;
    function Redo(const CurrentSnapshot: string): string;
    function CanUndo: Boolean;
    function CanRedo: Boolean;
    function UndoDescription: string;
    function RedoDescription: string;
    function UndoCount: Integer;
    function RedoCount: Integer;
    procedure Clear;
    { durante a restauracao o documento pode chamar BeginChange sem gravar }
    procedure Suspend;
    procedure Resume;
    function InChange: Boolean;
    property Limit: Integer read FLimit write SetLimit;
  end;

implementation

constructor TAIUndoHistory.Create(ALimit: Integer);
begin
  inherited Create;
  FUndo := TStringList.Create;
  FRedo := TStringList.Create;
  FLimit := ALimit;
  if FLimit < 1 then FLimit := 1;
end;

destructor TAIUndoHistory.Destroy;
begin
  FUndo.Free;
  FRedo.Free;
  inherited Destroy;
end;

procedure TAIUndoHistory.SetLimit(AValue: Integer);
begin
  if AValue < 1 then AValue := 1;
  FLimit := AValue;
  while FUndo.Count > FLimit do FUndo.Delete(0);
  while FRedo.Count > FLimit do FRedo.Delete(0);
end;

procedure TAIUndoHistory.Push(L: TStringList; const Desc, Snap: string);
begin
  L.Add(Desc + #0 + Snap);
  while L.Count > FLimit do L.Delete(0);
end;

class function TAIUndoHistory.Split(const Entry: string; out Desc: string): string;
var P: Integer;
begin
  P := Pos(#0, Entry);
  Desc := Copy(Entry, 1, P - 1);
  Result := Copy(Entry, P + 1, MaxInt);
end;

function TAIUndoHistory.BeginChange(const Desc, Snapshot: string): Boolean;
begin
  Result := False;
  if FSuspended > 0 then Exit;
  if FDepth = 0 then
  begin
    Push(FUndo, Desc, Snapshot);
    Result := True;
  end;
  Inc(FDepth);
end;

function TAIUndoHistory.EndChange: Boolean;
begin
  Result := False;
  if FSuspended > 0 then Exit;
  if FDepth <= 0 then
    raise EAIUndoHistory.Create('EndChange sem BeginChange');
  Dec(FDepth);
  if FDepth = 0 then
  begin
    FRedo.Clear;
    Result := True;
  end;
end;

function TAIUndoHistory.InChange: Boolean;
begin
  Result := FDepth > 0;
end;

function TAIUndoHistory.CanUndo: Boolean;
begin
  Result := (FUndo.Count > 0) and (FDepth = 0);
end;

function TAIUndoHistory.CanRedo: Boolean;
begin
  Result := (FRedo.Count > 0) and (FDepth = 0);
end;

function TAIUndoHistory.Undo(const CurrentSnapshot: string): string;
var Desc: string;
begin
  if not CanUndo then raise EAIUndoHistory.Create('nada para desfazer');
  Result := Split(FUndo[FUndo.Count - 1], Desc);
  FUndo.Delete(FUndo.Count - 1);
  Push(FRedo, Desc, CurrentSnapshot);
end;

function TAIUndoHistory.Redo(const CurrentSnapshot: string): string;
var Desc: string;
begin
  if not CanRedo then raise EAIUndoHistory.Create('nada para refazer');
  Result := Split(FRedo[FRedo.Count - 1], Desc);
  FRedo.Delete(FRedo.Count - 1);
  Push(FUndo, Desc, CurrentSnapshot);
end;

function TAIUndoHistory.UndoDescription: string;
begin
  Result := '';
  if FUndo.Count > 0 then Split(FUndo[FUndo.Count - 1], Result);
end;

function TAIUndoHistory.RedoDescription: string;
begin
  Result := '';
  if FRedo.Count > 0 then Split(FRedo[FRedo.Count - 1], Result);
end;

function TAIUndoHistory.UndoCount: Integer;
begin
  Result := FUndo.Count;
end;

function TAIUndoHistory.RedoCount: Integer;
begin
  Result := FRedo.Count;
end;

procedure TAIUndoHistory.Clear;
begin
  FUndo.Clear;
  FRedo.Clear;
  FDepth := 0;
end;

procedure TAIUndoHistory.Suspend;
begin
  Inc(FSuspended);
end;

procedure TAIUndoHistory.Resume;
begin
  if FSuspended > 0 then Dec(FSuspended);
end;

end.
