unit aidiskitem;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TAIDiskItemType = (
    ditUnknown,
    ditVolume,
    ditDirectory,
    ditFile
  );

  { TAIDiskItem }

  TAIDiskItem = class
  public
    FullPath: string;
    Name: string;
    Extension: string;
    ParentPath: string;
    ItemType: TAIDiskItemType;
    Size: Int64;
    CreatedAt: TDateTime;
    ModifiedAt: TDateTime;
    Depth: Integer;
    IsHidden: Boolean;
    IsReadOnly: Boolean;
    IsSystem: Boolean;
    
    constructor Create;
  end;

implementation

{ TAIDiskItem }

constructor TAIDiskItem.Create;
begin
  inherited Create;
  FullPath := '';
  Name := '';
  Extension := '';
  ParentPath := '';
  ItemType := ditUnknown;
  Size := 0;
  CreatedAt := 0.0;
  ModifiedAt := 0.0;
  Depth := 0;
  IsHidden := False;
  IsReadOnly := False;
  IsSystem := False;
end;

end.
