program test_avatar_3d;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, aimodel3d, aiavatartypes, aigltfloader;

var
  Model: TAIModel3D;
  GLBFile: string;
begin
  WriteLn('========================================');
  WriteLn('TESTE AUTOMATIZADO 3D AVATAR (TAREFAS 11-27)');
  WriteLn('========================================');
  
    GLBFile := ExtractFilePath(ParamStr(0)) + 'test_avatar_sample.glb';
  if not FileExists(GLBFile) then
    GLBFile := ExtractFilePath(ParamStr(0)) + 'tests' + DirectorySeparator + 'test_avatar_sample.glb';
  if not FileExists(GLBFile) then
    GLBFile := 'tests' + DirectorySeparator + 'test_avatar_sample.glb';
  if not FileExists(GLBFile) then
    GLBFile := 'D:' + DirectorySeparator + 'projetos' + DirectorySeparator + 'maurinsoft' + DirectorySeparator + 'CHATGPT' + DirectorySeparator + 'tests' + DirectorySeparator + 'test_avatar_sample.glb';
  if not FileExists(GLBFile) then
  begin
    WriteLn('[ERRO] Arquivo de teste nao encontrado: ', GLBFile);
    Halt(1);
  end;
  
  Model := TAIModel3D.Create(nil);
  try
    WriteLn('[1] Carregando arquivo GLB...');
    Model.LoadFromFile(GLBFile);
    
    if not Model.LastSuccess then
    begin
      WriteLn('[ERRO] Falha ao carregar GLB: ', Model.LastResult);
      Halt(2);
    end;
    
    WriteLn('  - Vertices: ', Model.VerticesCount);
    WriteLn('  - Faces: ', Model.FacesCount);
    WriteLn('  - HasSkinning: ', Model.HasSkinning);
    WriteLn('  - Materiais: ', Length(Model.Materials));
    WriteLn('  - Skins: ', Length(Model.Skins));
    
    if Model.VerticesCount <> 3 then
    begin
      WriteLn('[ERRO] Esperado 3 vertices, obtido: ', Model.VerticesCount);
      Halt(3);
    end;
    
    if Model.FacesCount <> 1 then
    begin
      WriteLn('[ERRO] Esperado 1 face, obtido: ', Model.FacesCount);
      Halt(4);
    end;
    
    if not Model.HasSkinning then
    begin
      WriteLn('[ERRO] Modelo deveria possuir Skinning.');
      Halt(5);
    end;
    
    if Length(Model.Materials) <> 1 then
    begin
      WriteLn('[ERRO] Esperado 1 material, obtido: ', Length(Model.Materials));
      Halt(6);
    end;
    
    if Model.Materials[0].Name <> 'PbrMat' then
    begin
      WriteLn('[ERRO] Nome do material incorreto: ', Model.Materials[0].Name);
      Halt(7);
    end;
    
    WriteLn('[2] Testando deformacao Skinning (ApplySkinning)...');
    WriteLn('  - V1 Original: (', Model.Faces[0].V1.X:0:2, ', ', Model.Faces[0].V1.Y:0:2, ', ', Model.Faces[0].V1.Z:0:2, ')');
    
    Model.ApplySkinning;
    
    WriteLn('  - V1 Skinned: (', Model.Faces[0].V1.X:0:2, ', ', Model.Faces[0].V1.Y:0:2, ', ', Model.Faces[0].V1.Z:0:2, ')');
    WriteLn('  - Bounding Box Min: (', Model.MinX:0:2, ', ', Model.MinY:0:2, ', ', Model.MinZ:0:2, ')');
    WriteLn('  - Bounding Box Max: (', Model.MaxX:0:2, ', ', Model.MaxY:0:2, ', ', Model.MaxZ:0:2, ')');
    
    // A translacao do joint no GLB de teste foi [0, 2, 0].
    // Portanto, o vertice (0,0,0) com peso 1.0 no joint 0 deve ter Y deformado para 2.0!
    if Abs(Model.Faces[0].V1.Y - 2.0) > 0.01 then
    begin
      WriteLn('[ERRO] Deformacao de skinning incorreta! Esperado Y=2.0, obtido: ', Model.Faces[0].V1.Y:0:4);
      Halt(8);
    end;
    
    WriteLn('[3] Testando ResetSkinning...');
    Model.ResetSkinning;
    WriteLn('  - V1 Reset: (', Model.Faces[0].V1.Y:0:2, ')');
    if Abs(Model.Faces[0].V1.Y - 0.0) > 0.01 then
    begin
      WriteLn('[ERRO] ResetSkinning falhou! Esperado Y=0.0, obtido: ', Model.Faces[0].V1.Y:0:4);
      Halt(9);
    end;
    
    WriteLn('========================================');
    WriteLn('[SUCESSO] TODOS OS TESTES PASSARAM COM EXITO!');
    WriteLn('========================================');
  finally
    Model.Free;
  end;
end.
