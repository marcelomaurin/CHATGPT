unit aiwordxml;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DOM, XMLRead, XMLWrite;

function LoadXML(const AFileName: string): TXMLDocument;
procedure SaveXML(ADoc: TXMLDocument; const AFileName: string);

function FindChildNode(AParent: TDOMNode; const ATagName: string): TDOMNode;
function GetOrCreateChildNode(AParent: TDOMNode; const ATagName: string): TDOMNode;
function GetNodeAttribute(ANode: TDOMNode; const AName: string; const ADefault: string = ''): string;
procedure SetNodeAttribute(ANode: TDOMNode; const AName: string; const AValue: string);
procedure SetNodeText(ANode: TDOMNode; const AText: string);
function GetNodeText(ANode: TDOMNode): string;

implementation

function LoadXML(const AFileName: string): TXMLDocument;
begin
  Result := nil;
  if FileExists(AFileName) then
    ReadXMLFile(Result, AFileName);
end;

procedure SaveXML(ADoc: TXMLDocument; const AFileName: string);
begin
  if Assigned(ADoc) then
    WriteXMLFile(ADoc, AFileName);
end;

function FindChildNode(AParent: TDOMNode; const ATagName: string): TDOMNode;
var
  Child: TDOMNode;
begin
  Result := nil;
  if not Assigned(AParent) then
    Exit;
  Child := AParent.FirstChild;
  while Assigned(Child) do
  begin
    if Child.NodeName = ATagName then
    begin
      Result := Child;
      Exit;
    end;
    Child := Child.NextSibling;
  end;
end;

function GetOrCreateChildNode(AParent: TDOMNode; const ATagName: string): TDOMNode;
var
  Doc: TXMLDocument;
begin
  Result := FindChildNode(AParent, ATagName);
  if not Assigned(Result) and Assigned(AParent) then
  begin
    if AParent.NodeType = DOCUMENT_NODE then
      Doc := TXMLDocument(AParent)
    else
      Doc := TXMLDocument(AParent.OwnerDocument);
      
    if Assigned(Doc) then
    begin
      Result := Doc.CreateElement(ATagName);
      AParent.AppendChild(Result);
    end;
  end;
end;

function GetNodeAttribute(ANode: TDOMNode; const AName: string; const ADefault: string = ''): string;
var
  Attr: TDOMNode;
begin
  Result := ADefault;
  if not Assigned(ANode) or not Assigned(ANode.Attributes) then
    Exit;
  Attr := ANode.Attributes.GetNamedItem(AName);
  if Assigned(Attr) then
    Result := Attr.NodeValue;
end;

procedure SetNodeAttribute(ANode: TDOMNode; const AName: string; const AValue: string);
var
  Attr: TDOMAttr;
  Doc: TXMLDocument;
begin
  if not Assigned(ANode) then
    Exit;
    
  if ANode.NodeType = DOCUMENT_NODE then
    Doc := TXMLDocument(ANode)
  else
    Doc := TXMLDocument(ANode.OwnerDocument);
    
  if not Assigned(Doc) then
    Exit;
    
  Attr := Doc.CreateAttribute(AName);
  Attr.Value := AValue;
  ANode.Attributes.SetNamedItem(Attr);
end;

procedure SetNodeText(ANode: TDOMNode; const AText: string);
var
  TextNode: TDOMNode;
  Doc: TXMLDocument;
begin
  if not Assigned(ANode) then
    Exit;
    
  // Clear existing children (normally just text nodes)
  while Assigned(ANode.FirstChild) do
    ANode.RemoveChild(ANode.FirstChild);
    
  if ANode.NodeType = DOCUMENT_NODE then
    Doc := TXMLDocument(ANode)
  else
    Doc := TXMLDocument(ANode.OwnerDocument);
    
  if Assigned(Doc) then
  begin
    TextNode := Doc.CreateTextNode(AText);
    ANode.AppendChild(TextNode);
  end;
end;

function GetNodeText(ANode: TDOMNode): string;
var
  Child: TDOMNode;
begin
  Result := '';
  if not Assigned(ANode) then
    Exit;
  Child := ANode.FirstChild;
  while Assigned(Child) do
  begin
    if (Child.NodeType = TEXT_NODE) or (Child.NodeType = CDATA_SECTION_NODE) then
      Result := Result + Child.NodeValue;
    Child := Child.NextSibling;
  end;
end;

end.
