program dev_agents_demo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, aillmproviders, aicapabilities, aimodelrouter,
  aiunifiedllm, aidevagents;

var
  Router: TAIModelRouter;
  LLM: TAIUnifiedLLM;
  SourceAgent: TAISourceAgent;
  BuildAgent: TAILazarusBuildAgent;
  TestAgent: TAITestAgent;
  NetworkAgent: TAINetworkAgent;
begin
  Router := TAIModelRouter.Create(nil);
  LLM := TAIUnifiedLLM.Create(nil);
  SourceAgent := TAISourceAgent.Create(nil);
  BuildAgent := TAILazarusBuildAgent.Create(nil);
  TestAgent := TAITestAgent.Create(nil);
  NetworkAgent := TAINetworkAgent.Create(nil);
  try
    Router.PreferLocal := True;
    Router.AddRoute(llmLlamaCpp, 'local-model', 'http://127.0.0.1:8080');

    LLM.Router := Router;
    LLM.AutoRoute := True;
    LLM.PreferLocal := True;

    SourceAgent.LLM := LLM;
    SourceAgent.RootDirectory := GetCurrentDir;
    SourceAgent.AllowWrite := False;

    BuildAgent.LazBuildPath := 'lazbuild';
    BuildAgent.TimeoutMs := 300000;

    TestAgent.TimeoutMs := 120000;
    NetworkAgent.TimeoutMs := 10000;

    WriteLn('CHATGPT Lazarus development agents');
    WriteLn('  SourceAgent: ready (write disabled by default)');
    WriteLn('  BuildAgent : ready');
    WriteLn('  TestAgent  : ready');
    WriteLn('  NetworkAgent: ready');
    WriteLn('  Preferred provider: ',
      AILLMProviderKindName(Router.Select([aicChat]).ProviderKind));
  finally
    NetworkAgent.Free;
    TestAgent.Free;
    BuildAgent.Free;
    SourceAgent.Free;
    LLM.Free;
    Router.Free;
  end;
end.
