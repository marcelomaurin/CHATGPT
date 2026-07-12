unit parser_fixture;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  { FakeCommentUnit, }
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  fpjson;

type
  TVisibleComponent = class(TComponent)
  end;

implementation

uses
  Math,
  DateUtils;

type
  TPrivateImplementationClass = class(TObject)
  end;

procedure Register;
begin
  RegisterComponents(
    'AI Tests',
    [
      TVisibleComponent
    ]
  );
end;

end.
