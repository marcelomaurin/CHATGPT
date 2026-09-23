{==============================================================================
  AI Autonomous Virtual Professor & Presentation Subsystem
  Implementa:
  - TPresentationResource: Recursos visuais/multimidia com metadados semanticos
  - TPresentationConcept: Conceito individual do roteiro da exposicao
  - TPresentationPackage: Pacote de exposicao de um projeto (RAG + Recursos + Conceitos)
  - TAIPresentationResourceManager: Localizacao inteligente do melhor recurso
  - TAIPersonPresentationHistory: Rastreamento do que cada pessoa ja viu
  - TAIPresentationAgent: Agente Professor Autonomo que conduz a apresentacao,
    aprofunda, desvia para duvidas e retoma sem perder o fio condutor.
==============================================================================}
unit aipresentation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, DateUtils;

type
  { Tipos de recurso visual / didatico }
  TPresentationResourceType = (
    prtImage,       { Foto microscopica, foto real do hardware, resultado }
    prtSlide,       { Slide especifico ou renderizado }
    prtDiagram,     { Esquema arquitetural, diagrama em blocos, fluxo }
    prtVideo,       { Video demonstrativo }
    prtDocument,    { Documento, artigo ou ficha tecnica }
    prtSimulation   { Simulacao ou grafico interativo }
  );

  { Estados do Professor Virtual Autonomo }
  TAIPresentationState = (
    psIdle,                 { Aguardando visitante se aproximar }
    psGreeting,             { Saudando o visitante e identificando contexto }
    psPresentingConcept,    { Apresentando um conceito e exibindo recurso }
    psAnsweringQuestion,    { Respondendo duvida do visitante (desvio temporario) }
    psPaused,               { Pausado (barge-in ou interrupcao) }
    psTransitioning         { Transicao entre conceitos ou projetos }
  );

  { Recurso multimidia com metadados semanticos para selecao pela IA }
  TPresentationResource = class(TPersistent)
  private
    FID: string;
    FProjectCode: string;
    FTitle: string;
    FDescription: string;
    FResourceType: TPresentationResourceType;
    FFilePath: string;
    FTopics: TStringList;
    FRelevanceScore: Single;
  public
    constructor Create(const AID, AProjectCode, ATitle, ADesc: string;
      AResourceType: TPresentationResourceType; const AFilePath: string);
    destructor Destroy; override;

    procedure AddTopic(const ATopic: string);
    function MatchesQuery(const AQuery: string): Single;

    property ID: string read FID write FID;
    property ProjectCode: string read FProjectCode write FProjectCode;
    property Title: string read FTitle write FTitle;
    property Description: string read FDescription write FDescription;
    property ResourceType: TPresentationResourceType read FResourceType write FResourceType;
    property FilePath: string read FFilePath write FFilePath;
    property Topics: TStringList read FTopics;
    property RelevanceScore: Single read FRelevanceScore write FRelevanceScore;
  end;

  { Conceito do roteiro semantico do projeto }
  TPresentationConcept = class(TPersistent)
  private
    FID: string;
    FTitle: string;
    FDescription: string;
    FOrderIndex: Integer;
    FKeyPoints: TStringList;
    FPreferredResourceType: TPresentationResourceType;
  public
    constructor Create(const AID, ATitle, ADesc: string; AOrderIndex: Integer;
      APreferredResourceType: TPresentationResourceType = prtImage);
    destructor Destroy; override;

    procedure AddKeyPoint(const APoint: string);

    property ID: string read FID write FID;
    property Title: string read FTitle write FTitle;
    property Description: string read FDescription write FDescription;
    property OrderIndex: Integer read FOrderIndex write FOrderIndex;
    property KeyPoints: TStringList read FKeyPoints;
    property PreferredResourceType: TPresentationResourceType read FPreferredResourceType write FPreferredResourceType;
  end;

  { Pacote de exposicao completo de um projeto }
  TPresentationPackage = class(TPersistent)
  private
    FProjectCode: string;
    FTitle: string;
    FSummary: string;
    FObjectives: string;
    FFoundations: string;
    FResults: string;
    FChallenges: string;
    FConcepts: TList;   { Lista de TPresentationConcept }
    FResources: TList;  { Lista de TPresentationResource }
    FRAGDocuments: TStringList;

    function GetConceptCount: Integer;
    function GetResourceCount: Integer;
  public
    constructor Create(const ACode, ATitle, ASummary, AObjectives, AFoundations, AResults, AChallenges: string);
    destructor Destroy; override;

    function AddConcept(const AID, ATitle, ADesc: string; AOrderIndex: Integer;
      APreferredType: TPresentationResourceType = prtImage): TPresentationConcept;
    function AddResource(const AID, ATitle, ADesc: string; AType: TPresentationResourceType;
      const AFilePath: string; const ATopicsCSV: string = ''): TPresentationResource;

    function GetConcept(AIndex: Integer): TPresentationConcept;
    function FindConcept(const AID: string): TPresentationConcept;
    function GetResource(AIndex: Integer): TPresentationResource;
    function FindResource(const AID: string): TPresentationResource;
    function FindBestResourceForTopic(const ATopicQuery: string): TPresentationResource;

    property ProjectCode: string read FProjectCode write FProjectCode;
    property Title: string read FTitle write FTitle;
    property Summary: string read FSummary write FSummary;
    property Objectives: string read FObjectives write FObjectives;
    property Foundations: string read FFoundations write FFoundations;
    property Results: string read FResults write FResults;
    property Challenges: string read FChallenges write FChallenges;
    property ConceptCount: Integer read GetConceptCount;
    property ResourceCount: Integer read GetResourceCount;
    property RAGDocuments: TStringList read FRAGDocuments;
  end;

  { Rastreamento do que cada pessoa ja assistiu na exposicao }
  TAIPersonPresentationHistory = class(TPersistent)
  private
    FPersonID: string;
    FViewedProjects: TStringList;
    FViewedConcepts: TStringList; { 'PROJECT:CONCEPT_ID' }
  public
    constructor Create(const APersonID: string);
    destructor Destroy; override;

    function HasViewedConcept(const AProjectCode, AConceptID: string): Boolean;
    procedure MarkConceptViewed(const AProjectCode, AConceptID: string);
    function HasViewedProject(const AProjectCode: string): Boolean;
    procedure MarkProjectViewed(const AProjectCode: string);
    function GetNextUnviewedConcept(APackage: TPresentationPackage): TPresentationConcept;

    property PersonID: string read FPersonID;
    property ViewedProjects: TStringList read FViewedProjects;
    property ViewedConcepts: TStringList read FViewedConcepts;
  end;

  { Gerenciador de Recursos e Pacotes de Apresentacao }
  TAIPresentationResourceManager = class(TComponent)
  private
    FPackages: TList; { Lista de TPresentationPackage }
    function GetPackageCount: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function AddPackage(const ACode, ATitle, ASummary, AObjectives, AFoundations, AResults, AChallenges: string): TPresentationPackage;
    function FindPackage(const ACode: string): TPresentationPackage;
    function GetPackage(AIndex: Integer): TPresentationPackage;
    function FindBestResource(const AProjectCode, ATopicQuery: string): TPresentationResource;

    function FindImage(const AProjectCode, ATopic: string): TPresentationResource;
    function FindSlide(const AProjectCode, ATopic: string): TPresentationResource;
    function FindDiagram(const AProjectCode, ATopic: string): TPresentationResource;

    procedure InitDefaultAcademicPackages;

    property PackageCount: Integer read GetPackageCount;
  end;

  { Eventos do Agente Professor Virtual }
  TOnNarrativeSpokenEvent = procedure(Sender: TObject; const ANarrative, AEmotion, AGesture: string) of object;
  TOnResourceSelectedEvent = procedure(Sender: TObject; AResource: TPresentationResource) of object;
  TOnConceptAdvancedEvent = procedure(Sender: TObject; AConcept: TPresentationConcept) of object;
  TOnPresentationProjectChangedEvent = procedure(Sender: TObject; APackage: TPresentationPackage) of object;
  TOnPresentationStateChangedEvent = procedure(Sender: TObject; AState: TAIPresentationState) of object;

  { Agente Professor Virtual Autonomo }
  TAIPresentationAgent = class(TComponent)
  private
    FResourceManager: TAIPresentationResourceManager;
    FInternalResourceManager: Boolean;
    FState: TAIPresentationState;
    FCurrentPackage: TPresentationPackage;
    FCurrentConcept: TPresentationConcept;
    FCurrentResource: TPresentationResource;
    FActivePersonID: string;
    FActivePersonName: string;
    FPersonHistories: TList; { Lista de TAIPersonPresentationHistory }

    { Controle de Desvio e Retomada }
    FPendingResumeNarrative: string;
    FReturnConcept: TPresentationConcept;
    FReturnPackage: TPresentationPackage;

    { Eventos }
    FOnNarrativeSpoken: TOnNarrativeSpokenEvent;
    FOnResourceSelected: TOnResourceSelectedEvent;
    FOnConceptAdvanced: TOnConceptAdvancedEvent;
    FOnProjectChanged: TOnPresentationProjectChangedEvent;
    FOnStateChanged: TOnPresentationStateChangedEvent;

    function GetPersonHistory(const APersonID: string): TAIPersonPresentationHistory;
    procedure SetState(AValue: TAIPresentationState);
    procedure SetResourceManager(AValue: TAIPresentationResourceManager);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Ciclo da Apresentacao Autonoma
    function StartPresentation(const APersonID, APersonName: string; const APreferredProject: string = ''): string;
    function ContinuePresentation: string;
    procedure PausePresentation;
    function AnswerQuestion(const AQuestion: string): string;
    function ResumePresentation: string;
    function SelectNextProject: string;
    function SelectConcept(const AConceptID: string): string;
    procedure SelectResource(AResource: TPresentationResource);

    function GetStatusSummary: string;

    property ResourceManager: TAIPresentationResourceManager read FResourceManager write SetResourceManager;
    property State: TAIPresentationState read FState;
    property CurrentPackage: TPresentationPackage read FCurrentPackage;
    property CurrentConcept: TPresentationConcept read FCurrentConcept;
    property CurrentResource: TPresentationResource read FCurrentResource;
    property ActivePersonID: string read FActivePersonID write FActivePersonID;
    property ActivePersonName: string read FActivePersonName write FActivePersonName;

    property OnNarrativeSpoken: TOnNarrativeSpokenEvent read FOnNarrativeSpoken write FOnNarrativeSpoken;
    property OnResourceSelected: TOnResourceSelectedEvent read FOnResourceSelected write FOnResourceSelected;
    property OnConceptAdvanced: TOnConceptAdvancedEvent read FOnConceptAdvanced write FOnConceptAdvanced;
    property OnProjectChanged: TOnPresentationProjectChangedEvent read FOnProjectChanged write FOnProjectChanged;
    property OnStateChanged: TOnPresentationStateChangedEvent read FOnStateChanged write FOnStateChanged;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('OpenAI Agent', [TAIPresentationResourceManager, TAIPresentationAgent]);
end;

{ TPresentationResource }

constructor TPresentationResource.Create(const AID, AProjectCode, ATitle, ADesc: string;
  AResourceType: TPresentationResourceType; const AFilePath: string);
begin
  inherited Create;
  FID := AID;
  FProjectCode := AProjectCode;
  FTitle := ATitle;
  FDescription := ADesc;
  FResourceType := AResourceType;
  FFilePath := AFilePath;
  FTopics := TStringList.Create;
  FRelevanceScore := 0.0;
end;

destructor TPresentationResource.Destroy;
begin
  FTopics.Free;
  inherited Destroy;
end;

procedure TPresentationResource.AddTopic(const ATopic: string);
begin
  if (Trim(ATopic) <> '') and (FTopics.IndexOf(Trim(ATopic)) < 0) then
    FTopics.Add(Trim(ATopic));
end;

function TPresentationResource.MatchesQuery(const AQuery: string): Single;
var
  Q, LowerDesc, LowerTitle: string;
  I: Integer;
  Score: Single;
begin
  Score := 0.0;
  Q := LowerCase(Trim(AQuery));
  if Q = '' then Exit(0.0);

  LowerTitle := LowerCase(FTitle);
  LowerDesc := LowerCase(FDescription);

  // Correspondencia direta de topicos
  for I := 0 to FTopics.Count - 1 do
  begin
    if Pos(LowerCase(FTopics[I]), Q) > 0 then
      Score := Score + 2.0
    else if Pos(Q, LowerCase(FTopics[I])) > 0 then
      Score := Score + 1.5;
  end;

  // Correspondencia no titulo
  if Pos(Q, LowerTitle) > 0 then
    Score := Score + 2.5;

  // Correspondencia na descricao
  if Pos(Q, LowerDesc) > 0 then
    Score := Score + 1.0;

  FRelevanceScore := Score;
  Result := Score;
end;

{ TPresentationConcept }

constructor TPresentationConcept.Create(const AID, ATitle, ADesc: string; AOrderIndex: Integer;
  APreferredResourceType: TPresentationResourceType);
begin
  inherited Create;
  FID := AID;
  FTitle := ATitle;
  FDescription := ADesc;
  FOrderIndex := AOrderIndex;
  FPreferredResourceType := APreferredResourceType;
  FKeyPoints := TStringList.Create;
end;

destructor TPresentationConcept.Destroy;
begin
  FKeyPoints.Free;
  inherited Destroy;
end;

procedure TPresentationConcept.AddKeyPoint(const APoint: string);
begin
  if Trim(APoint) <> '' then
    FKeyPoints.Add(Trim(APoint));
end;

{ TPresentationPackage }

constructor TPresentationPackage.Create(const ACode, ATitle, ASummary, AObjectives, AFoundations, AResults, AChallenges: string);
begin
  inherited Create;
  FProjectCode := ACode;
  FTitle := ATitle;
  FSummary := ASummary;
  FObjectives := AObjectives;
  FFoundations := AFoundations;
  FResults := AResults;
  FChallenges := AChallenges;
  FConcepts := TList.Create;
  FResources := TList.Create;
  FRAGDocuments := TStringList.Create;
end;

destructor TPresentationPackage.Destroy;
var
  I: Integer;
begin
  for I := 0 to FConcepts.Count - 1 do
    TPresentationConcept(FConcepts[I]).Free;
  FConcepts.Free;

  for I := 0 to FResources.Count - 1 do
    TPresentationResource(FResources[I]).Free;
  FResources.Free;

  FRAGDocuments.Free;
  inherited Destroy;
end;

function TPresentationPackage.GetConceptCount: Integer;
begin
  Result := FConcepts.Count;
end;

function TPresentationPackage.GetResourceCount: Integer;
begin
  Result := FResources.Count;
end;

function TPresentationPackage.AddConcept(const AID, ATitle, ADesc: string; AOrderIndex: Integer;
  APreferredType: TPresentationResourceType): TPresentationConcept;
begin
  Result := TPresentationConcept.Create(AID, ATitle, ADesc, AOrderIndex, APreferredType);
  FConcepts.Add(Result);
end;

function TPresentationPackage.AddResource(const AID, ATitle, ADesc: string; AType: TPresentationResourceType;
  const AFilePath: string; const ATopicsCSV: string): TPresentationResource;
var
  Topics: TStringList;
  I: Integer;
begin
  Result := TPresentationResource.Create(AID, FProjectCode, ATitle, ADesc, AType, AFilePath);
  if Trim(ATopicsCSV) <> '' then
  begin
    Topics := TStringList.Create;
    try
      Topics.Delimiter := ',';
      Topics.StrictDelimiter := True;
      Topics.DelimitedText := ATopicsCSV;
      for I := 0 to Topics.Count - 1 do
        Result.AddTopic(Trim(Topics[I]));
    finally
      Topics.Free;
    end;
  end;
  FResources.Add(Result);
end;

function TPresentationPackage.GetConcept(AIndex: Integer): TPresentationConcept;
begin
  if (AIndex >= 0) and (AIndex < FConcepts.Count) then
    Result := TPresentationConcept(FConcepts[AIndex])
  else
    Result := nil;
end;

function TPresentationPackage.FindConcept(const AID: string): TPresentationConcept;
var
  I: Integer;
  C: TPresentationConcept;
begin
  for I := 0 to FConcepts.Count - 1 do
  begin
    C := TPresentationConcept(FConcepts[I]);
    if SameText(C.ID, AID) or SameText(C.Title, AID) then
      Exit(C);
  end;
  Result := nil;
end;

function TPresentationPackage.GetResource(AIndex: Integer): TPresentationResource;
begin
  if (AIndex >= 0) and (AIndex < FResources.Count) then
    Result := TPresentationResource(FResources[AIndex])
  else
    Result := nil;
end;

function TPresentationPackage.FindResource(const AID: string): TPresentationResource;
var
  I: Integer;
  R: TPresentationResource;
begin
  for I := 0 to FResources.Count - 1 do
  begin
    R := TPresentationResource(FResources[I]);
    if SameText(R.ID, AID) or SameText(R.Title, AID) then
      Exit(R);
  end;
  Result := nil;
end;

function TPresentationPackage.FindBestResourceForTopic(const ATopicQuery: string): TPresentationResource;
var
  I: Integer;
  R: TPresentationResource;
  Score, BestScore: Single;
  BestRes: TPresentationResource;
begin
  BestScore := -1.0;
  BestRes := nil;

  for I := 0 to FResources.Count - 1 do
  begin
    R := TPresentationResource(FResources[I]);
    Score := R.MatchesQuery(ATopicQuery);
    if Score > BestScore then
    begin
      BestScore := Score;
      BestRes := R;
    end;
  end;

  if (BestRes = nil) and (FResources.Count > 0) then
    BestRes := TPresentationResource(FResources[0]);

  Result := BestRes;
end;

{ TAIPersonPresentationHistory }

constructor TAIPersonPresentationHistory.Create(const APersonID: string);
begin
  inherited Create;
  FPersonID := APersonID;
  FViewedProjects := TStringList.Create;
  FViewedConcepts := TStringList.Create;
end;

destructor TAIPersonPresentationHistory.Destroy;
begin
  FViewedProjects.Free;
  FViewedConcepts.Free;
  inherited Destroy;
end;

function TAIPersonPresentationHistory.HasViewedConcept(const AProjectCode, AConceptID: string): Boolean;
var
  Key: string;
begin
  Key := UpperCase(AProjectCode) + ':' + UpperCase(AConceptID);
  Result := FViewedConcepts.IndexOf(Key) >= 0;
end;

procedure TAIPersonPresentationHistory.MarkConceptViewed(const AProjectCode, AConceptID: string);
var
  Key: string;
begin
  Key := UpperCase(AProjectCode) + ':' + UpperCase(AConceptID);
  if FViewedConcepts.IndexOf(Key) < 0 then
    FViewedConcepts.Add(Key);
  MarkProjectViewed(AProjectCode);
end;

function TAIPersonPresentationHistory.HasViewedProject(const AProjectCode: string): Boolean;
begin
  Result := FViewedProjects.IndexOf(UpperCase(AProjectCode)) >= 0;
end;

procedure TAIPersonPresentationHistory.MarkProjectViewed(const AProjectCode: string);
begin
  if FViewedProjects.IndexOf(UpperCase(AProjectCode)) < 0 then
    FViewedProjects.Add(UpperCase(AProjectCode));
end;

function TAIPersonPresentationHistory.GetNextUnviewedConcept(APackage: TPresentationPackage): TPresentationConcept;
var
  I: Integer;
  C: TPresentationConcept;
begin
  if APackage = nil then Exit(nil);
  for I := 0 to APackage.ConceptCount - 1 do
  begin
    C := APackage.GetConcept(I);
    if not HasViewedConcept(APackage.ProjectCode, C.ID) then
      Exit(C);
  end;
  // Se ja viu todos, retorna o primeiro como revisao
  if APackage.ConceptCount > 0 then
    Result := APackage.GetConcept(0)
  else
    Result := nil;
end;

{ TAIPresentationResourceManager }

constructor TAIPresentationResourceManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPackages := TList.Create;
  InitDefaultAcademicPackages;
end;

destructor TAIPresentationResourceManager.Destroy;
var
  I: Integer;
begin
  for I := 0 to FPackages.Count - 1 do
    TPresentationPackage(FPackages[I]).Free;
  FPackages.Free;
  inherited Destroy;
end;

function TAIPresentationResourceManager.GetPackageCount: Integer;
begin
  Result := FPackages.Count;
end;

function TAIPresentationResourceManager.AddPackage(const ACode, ATitle, ASummary, AObjectives, AFoundations, AResults, AChallenges: string): TPresentationPackage;
begin
  Result := TPresentationPackage.Create(ACode, ATitle, ASummary, AObjectives, AFoundations, AResults, AChallenges);
  FPackages.Add(Result);
end;

function TAIPresentationResourceManager.FindPackage(const ACode: string): TPresentationPackage;
var
  I: Integer;
  P: TPresentationPackage;
begin
  for I := 0 to FPackages.Count - 1 do
  begin
    P := TPresentationPackage(FPackages[I]);
    if SameText(P.ProjectCode, ACode) or (Pos(LowerCase(ACode), LowerCase(P.Title)) > 0) then
      Exit(P);
  end;
  Result := nil;
end;

function TAIPresentationResourceManager.GetPackage(AIndex: Integer): TPresentationPackage;
begin
  if (AIndex >= 0) and (AIndex < FPackages.Count) then
    Result := TPresentationPackage(FPackages[AIndex])
  else
    Result := nil;
end;

function TAIPresentationResourceManager.FindBestResource(const AProjectCode, ATopicQuery: string): TPresentationResource;
var
  Pkg: TPresentationPackage;
begin
  Pkg := FindPackage(AProjectCode);
  if Pkg <> nil then
    Result := Pkg.FindBestResourceForTopic(ATopicQuery)
  else
    Result := nil;
end;

function TAIPresentationResourceManager.FindImage(const AProjectCode, ATopic: string): TPresentationResource;
var
  Pkg: TPresentationPackage;
  I: Integer;
  R, Best: TPresentationResource;
  Score, BestScore: Single;
begin
  Pkg := FindPackage(AProjectCode);
  if Pkg = nil then Exit(nil);

  BestScore := -1.0;
  Best := nil;
  for I := 0 to Pkg.ResourceCount - 1 do
  begin
    R := Pkg.GetResource(I);
    if R.ResourceType in [prtImage, prtDiagram, prtSlide] then
    begin
      Score := R.MatchesQuery(ATopic);
      if Score > BestScore then
      begin
        BestScore := Score;
        Best := R;
      end;
    end;
  end;
  Result := Best;
end;

function TAIPresentationResourceManager.FindSlide(const AProjectCode, ATopic: string): TPresentationResource;
var
  Pkg: TPresentationPackage;
  I: Integer;
  R: TPresentationResource;
begin
  Pkg := FindPackage(AProjectCode);
  if Pkg = nil then Exit(nil);

  for I := 0 to Pkg.ResourceCount - 1 do
  begin
    R := Pkg.GetResource(I);
    if (R.ResourceType = prtSlide) and (R.MatchesQuery(ATopic) > 0) then
      Exit(R);
  end;
  Result := FindImage(AProjectCode, ATopic);
end;

function TAIPresentationResourceManager.FindDiagram(const AProjectCode, ATopic: string): TPresentationResource;
var
  Pkg: TPresentationPackage;
  I: Integer;
  R: TPresentationResource;
begin
  Pkg := FindPackage(AProjectCode);
  if Pkg = nil then Exit(nil);

  for I := 0 to Pkg.ResourceCount - 1 do
  begin
    R := Pkg.GetResource(I);
    if (R.ResourceType = prtDiagram) and (R.MatchesQuery(ATopic) > 0) then
      Exit(R);
  end;
  Result := FindImage(AProjectCode, ATopic);
end;

procedure TAIPresentationResourceManager.InitDefaultAcademicPackages;
var
  Pkg: TPresentationPackage;
begin
  // 1. Projeto Hemácias
  Pkg := AddPackage(
    'HEMACIAS',
    'Hemácias - Visão Computacional Biomédica',
    'Sistema inteligente de detecção, classificação e contagem de células sanguíneas em imagens microscópicas.',
    'Automatizar o hemograma por microscopia digital com alta acurácia e redução de fadiga laboratorial.',
    'Microscopia de imersão, coloração Leishman/Giemsa, aquisição digital e Deep Learning.',
    'Acurácia de 96.4% na detecção de eritrócitos, leucócitos e plaquetas em tempo real.',
    'Variações de iluminação de bancada e sobreposição de hemácias aglomeradas.'
  );
  Pkg.AddConcept('microscopia', 'Microscopia e Aquisição', 'Captura digital da lâmina através de câmera de microscópio calibrada.', 0, prtImage)
     .AddKeyPoint('Resolução de captura e campo óptico');
  Pkg.AddConcept('yolo', 'Detecção com YOLO', 'Aplicação de rede neural YOLOv8 treinada para identificar as células.', 1, prtImage)
     .AddKeyPoint('Bounding boxes por tipo de célula (eritrócito, leucócito, plaqueta)');
  Pkg.AddConcept('contagem', 'Contagem e Métricas', 'Filtro morfológico e eliminação de células cortadas pelas bordas.', 2, prtDiagram)
     .AddKeyPoint('Histograma de contagem e volumetria celular');
  Pkg.AddConcept('calibracao', 'Calibração e Validação', 'Calibração micrométrica por pixel e validação cruzada com hematologistas.', 3, prtSlide)
     .AddKeyPoint('Índices de sensibilidade e especificidade');

  Pkg.AddResource('img_microscopio', 'Captura da Lâmina', 'Imagem microscópica direta da lâmina de sangue periférico.', prtImage, 'img/hemacias_lamina.jpg', 'microscopia,lamina,captura,aquisicao,campo');
  Pkg.AddResource('img_yolo', 'Detecção YOLO Celular', 'Células identificadas e marcadas com bounding boxes pelo modelo YOLO.', prtImage, 'img/hemacias_detectadas.jpg', 'yolo,deteccao,ia,identificacao,bounding box');
  Pkg.AddResource('diag_fluxo', 'Fluxo de Processamento', 'Diagrama em blocos do pipeline óptico até o laudo automatizado.', prtDiagram, 'img/hemacias_arquitetura.png', 'arquitetura,fluxo,contagem,processamento,pipeline');
  Pkg.AddResource('slide_metricas', 'Resultados e Métricas', 'Slide com matriz de confusão e sensibilidade diagnóstica.', prtSlide, 'img/hemacias_metricas.png', 'calibracao,metricas,resultados,validacao,acuracia');

  // 2. Projeto Robotinics
  Pkg := AddPackage(
    'ROBOTINICS',
    'Robotinics - Robótica Móvel e ROS',
    'Plataforma de pesquisa em robôs autônomos, odometria, sensores LIDAR e nós ROS.',
    'Desenvolver navegação autônoma indoor com mapeamento SLAM e baixo custo de hardware.',
    'Cinemática diferencial, microcontroladores Arduino/ESP32 e middleware ROS.',
    'Navegação ponto a ponto com desvio de obstáculos em tempo real.',
    'Acumulação de erro de odometria em pistas lisas e latência de processamento de nuvem de pontos.'
  );
  Pkg.AddConcept('hardware', 'Arquitetura e Hardware', 'Estrutura mecânica, atuadores DC com encoder e ponte H.', 0, prtDiagram)
     .AddKeyPoint('Microcontrolador Arduino para tarefas de tempo real');
  Pkg.AddConcept('ros', 'Nós ROS e Telemetria', 'Comunicação distribuída via tópicos e serviços ROS.', 1, prtDiagram)
     .AddKeyPoint('Integração com sensores e computação de bordo');
  Pkg.AddConcept('slam', 'Mapeamento e Navegação', 'Algoritmo SLAM com sensor LIDAR 2D para mapear o ambiente.', 2, prtImage)
     .AddKeyPoint('Desvio dinâmico de obstáculos');

  Pkg.AddResource('img_robo', 'Protótipo Robotinics', 'Fotografia do robô móvel com sensores e placa controladora.', prtImage, 'img/robo_hardware.jpg', 'hardware,robo,arduino,motores,chassi');
  Pkg.AddResource('diag_ros', 'Topologia dos Nós ROS', 'Esquema de comunicação entre nós sensores e nós de controle.', prtDiagram, 'img/ros_nodes.png', 'ros,arquitetura,nós,telemetria,topologia');
  Pkg.AddResource('img_slam', 'Mapa SLAM Gerado', 'Planta baixa do laboratório mapeada em tempo real pelo LIDAR.', prtImage, 'img/slam_map.png', 'slam,mapa,lidar,navegacao,obstaculos');

  // 3. Projeto ECG Monitor
  Pkg := AddPackage(
    'ECG',
    'ECG Monitor - Telemetria Cardíaca e IA',
    'Monitoramento cardíaco portátil com detecção de arritmias via YOLO 1D.',
    'Detecção precoce de taquicardias e batimentos ectópicos em ambientes ambulatoriais.',
    'Eletrofisiologia, amplificador AD8232, filtros passa-faixa e redes neurais 1D.',
    'Classificação de arritmias com latência inferior a 120 ms por batimento.',
    'Artefatos musculares de movimento e ruído de rede 60 Hz.'
  );
  Pkg.AddConcept('aquisicao', 'Aquisição e Filtros DSP', 'Condicionamento de sinal analógico e filtragem de ruído de 60 Hz.', 0, prtDiagram);
  Pkg.AddConcept('yolo1d', 'Classificação YOLO 1D', 'Segmentação da onda cardíaca (P, QRS, T) e detecção de anomalias.', 1, prtImage);

  Pkg.AddResource('diag_ecg', 'Esquema de Aquisição AD8232', 'Diagrama dos eletrodos e filtros analógicos/digitais.', prtDiagram, 'img/ecg_circuito.png', 'aquisicao,circuito,ad8232,filtro,dsp');
  Pkg.AddResource('img_ecg_yolo', 'Detecção de Arritmias', 'Sinal cardíaco segmentado com anomalias classificadas.', prtImage, 'img/ecg_yolo1d.png', 'yolo1d,arritmia,qrs,classificacao,batimento');

  // 4. Projeto CASA / Jarvis
  Pkg := AddPackage(
    'CASA',
    'CASA - Automação Residencial e IoT',
    'Ecossistema de domótica com controle por voz, telemetria climática e túnel seguro.',
    'Oferecer automação residencial completa com privacidade e processamento local/híbrido.',
    'MQTT, atuadores relé, sensores de temperatura/umidade e túnel Cloudflare Zero-Trust.',
    'Controle confiável de iluminação, irrigação e segurança com baixa latência.',
    'Resiliência a quedas de energia e sincronização de estado entre nós IoT.'
  );
  Pkg.AddConcept('iot', 'Dispositivos e Atuadores', 'Controle inteligente de cargas elétricas, iluminação e bombas.', 0, prtImage);
  Pkg.AddConcept('seguranca', 'Segurança e Conectividade', 'Túnel criptografado sem exposição direta de portas na internet.', 1, prtDiagram);

  Pkg.AddResource('img_casa_painel', 'Painel de Automação', 'Visão geral dos dispositivos IoT e telemetria da residência.', prtImage, 'img/casa_dashboard.png', 'iot,painel,dispositivos,reles,automacao');
  Pkg.AddResource('diag_casa_rede', 'Topologia Zero-Trust', 'Esquema de comunicação segura entre os sensores e a nuvem.', prtDiagram, 'img/casa_topologia.png', 'seguranca,rede,tunel,cloudflare,zero-trust');
end;

{ TAIPresentationAgent }

constructor TAIPresentationAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FState := psIdle;
  FInternalResourceManager := True;
  FResourceManager := TAIPresentationResourceManager.Create(nil);
  FPersonHistories := TList.Create;
  FPendingResumeNarrative := '';
end;

procedure TAIPresentationAgent.SetResourceManager(AValue: TAIPresentationResourceManager);
begin
  if FResourceManager <> AValue then
  begin
    if FInternalResourceManager and (FResourceManager <> nil) then
    begin
      FResourceManager.Free;
      FInternalResourceManager := False;
    end;
    FResourceManager := AValue;
    FInternalResourceManager := False;
  end;
end;

destructor TAIPresentationAgent.Destroy;
var
  I: Integer;
begin
  for I := 0 to FPersonHistories.Count - 1 do
    TAIPersonPresentationHistory(FPersonHistories[I]).Free;
  FPersonHistories.Free;

  if FInternalResourceManager and (FResourceManager <> nil) then
    FResourceManager.Free;

  inherited Destroy;
end;

function TAIPresentationAgent.GetPersonHistory(const APersonID: string): TAIPersonPresentationHistory;
var
  I: Integer;
  H: TAIPersonPresentationHistory;
begin
  for I := 0 to FPersonHistories.Count - 1 do
  begin
    H := TAIPersonPresentationHistory(FPersonHistories[I]);
    if SameText(H.PersonID, APersonID) then
      Exit(H);
  end;
  H := TAIPersonPresentationHistory.Create(APersonID);
  FPersonHistories.Add(H);
  Result := H;
end;

procedure TAIPresentationAgent.SetState(AValue: TAIPresentationState);
begin
  if FState <> AValue then
  begin
    FState := AValue;
    if Assigned(FOnStateChanged) then
      FOnStateChanged(Self, FState);
  end;
end;

procedure TAIPresentationAgent.SelectResource(AResource: TPresentationResource);
begin
  FCurrentResource := AResource;
  if Assigned(FOnResourceSelected) and (AResource <> nil) then
    FOnResourceSelected(Self, AResource);
end;

function TAIPresentationAgent.StartPresentation(const APersonID, APersonName: string; const APreferredProject: string): string;
var
  Hist: TAIPersonPresentationHistory;
  Greeting, NextConceptText: string;
begin
  FActivePersonID := APersonID;
  FActivePersonName := APersonName;
  SetState(psGreeting);

  if FResourceManager = nil then
    Exit('Bem-vindo à nossa feira de projetos da FATEC.');

  // Seleciona o projeto
  if Trim(APreferredProject) <> '' then
    FCurrentPackage := FResourceManager.FindPackage(APreferredProject)
  else
    FCurrentPackage := FResourceManager.GetPackage(0); // Hemacias como primeiro projeto destaque

  if FCurrentPackage = nil then
    Exit('Bem-vindo. No momento não há projetos carregados.');

  if Assigned(FOnProjectChanged) then
    FOnProjectChanged(Self, FCurrentPackage);

  Hist := GetPersonHistory(APersonID);

  if Trim(APersonName) <> '' then
  begin
    if Hist.HasViewedProject(FCurrentPackage.ProjectCode) then
      Greeting := 'Olá novamente, ' + APersonName + '! Que bom te ver de volta.'
    else
      Greeting := 'Olá, ' + APersonName + '! Seja bem-vindo à nossa feira de tecnologia da FATEC.';
  end
  else
    Greeting := 'Olá! Seja muito bem-vindo à nossa apresentação de projetos da FATEC.';

  // Localiza o proximo conceito nao assistido por esta pessoa
  FCurrentConcept := Hist.GetNextUnviewedConcept(FCurrentPackage);

  if FCurrentConcept <> nil then
  begin
    FCurrentResource := FCurrentPackage.FindBestResourceForTopic(FCurrentConcept.Title + ' ' + FCurrentConcept.Description);
    SelectResource(FCurrentResource);

    NextConceptText := ' Vou começar apresentando o projeto ' + FCurrentPackage.Title + '.' +
      ' Aqui na tela você pode ver: ' + FCurrentResource.Title + '. ' +
      FCurrentConcept.Description;

    Hist.MarkConceptViewed(FCurrentPackage.ProjectCode, FCurrentConcept.ID);
  end
  else
  begin
    NextConceptText := ' Este é o projeto ' + FCurrentPackage.Title + ': ' + FCurrentPackage.Summary;
  end;

  Result := Greeting + NextConceptText;
  SetState(psPresentingConcept);

  if Assigned(FOnNarrativeSpoken) then
    FOnNarrativeSpoken(Self, Result, 'alegria', 'agWave');
end;

function TAIPresentationAgent.ContinuePresentation: string;
var
  Hist: TAIPersonPresentationHistory;
  NextIdx: Integer;
begin
  if FCurrentPackage = nil then
    Exit(SelectNextProject);

  SetState(psPresentingConcept);
  Hist := GetPersonHistory(FActivePersonID);

  // Procura o proximo conceito dentro do mesmo projeto
  if FCurrentConcept <> nil then
    NextIdx := FCurrentConcept.OrderIndex + 1
  else
    NextIdx := 0;

  if NextIdx < FCurrentPackage.ConceptCount then
  begin
    FCurrentConcept := FCurrentPackage.GetConcept(NextIdx);
    FCurrentResource := FCurrentPackage.FindBestResourceForTopic(FCurrentConcept.Title + ' ' + FCurrentConcept.Description);
    SelectResource(FCurrentResource);

    Hist.MarkConceptViewed(FCurrentPackage.ProjectCode, FCurrentConcept.ID);

    Result := 'Continuando a nossa explicação sobre ' + FCurrentPackage.Title + ': ' +
      'no tópico ' + FCurrentConcept.Title + ', ' + FCurrentConcept.Description +
      '. Observe o recurso selecionado na tela: ' + FCurrentResource.Title + '.';

    if Assigned(FOnConceptAdvanced) then
      FOnConceptAdvanced(Self, FCurrentConcept);

    if Assigned(FOnNarrativeSpoken) then
      FOnNarrativeSpoken(Self, Result, 'neutro', 'agExplain');
  end
  else
  begin
    // Projeto concluido para esta pessoa -> passa autonomamente para o proximo
    Result := SelectNextProject;
  end;
end;

procedure TAIPresentationAgent.PausePresentation;
begin
  SetState(psPaused);
end;

function TAIPresentationAgent.AnswerQuestion(const AQuestion: string): string;
var
  AnswerText: string;
  MatchingRes: TPresentationResource;
begin
  SetState(psAnsweringQuestion);

  // Salva o ponto em que estava para retomada sem perda de contexto
  FReturnConcept := FCurrentConcept;
  FReturnPackage := FCurrentPackage;

  // Busca se ha recurso visual mais pertinente a pergunta
  if FCurrentPackage <> nil then
  begin
    MatchingRes := FCurrentPackage.FindBestResourceForTopic(AQuestion);
    if (MatchingRes <> nil) and (MatchingRes.RelevanceScore >= 2.0) then
      SelectResource(MatchingRes);
  end;

  // Gera resposta didatica contextualizada
  if (Pos('yolo', LowerCase(AQuestion)) > 0) or
     (Pos('inteligencia', LowerCase(AQuestion)) > 0) or
     (Pos('ia', LowerCase(AQuestion)) > 0) or
     (Pos('modelo', LowerCase(AQuestion)) > 0) then
  begin
    AnswerText := 'Excelente pergunta! Neste projeto utilizamos o modelo YOLO versão 8m com pesos ajustados para ' +
      'identificação celular microscópica. Ele realiza inferência em menos de 45 milissegundos por quadro.';
  end
  else if (Pos('arduino', LowerCase(AQuestion)) > 0) or (Pos('hardware', LowerCase(AQuestion)) > 0) then
  begin
    AnswerText := 'Sim! O hardware utiliza controladores dedicados para controle de tempo real dos atuadores e motores, ' +
      'garantindo estabilidade e comunicação serial direta com a unidade de processamento central.';
  end
  else if (Pos('camera', LowerCase(AQuestion)) > 0) or (Pos('sensor', LowerCase(AQuestion)) > 0) then
  begin
    AnswerText := 'A captura utiliza uma câmera CMOS acoplada ao tubo óptico com resolução de 1080p e lente ' +
      'calibrada micrometricamente para cada aumento de objetiva.';
  end
  else
  begin
    AnswerText := 'Boa observação! Em relação à sua pergunta: no contexto do projeto ' +
      FCurrentPackage.Title + ', essa questão se relaciona com os fundamentos do sistema e com os objetivos propostos.';
  end;

  FPendingResumeNarrative := 'Agora, voltando ao ponto principal da nossa apresentação...';
  Result := AnswerText;

  if Assigned(FOnNarrativeSpoken) then
    FOnNarrativeSpoken(Self, Result, 'alegria', 'agNod');
end;

function TAIPresentationAgent.ResumePresentation: string;
var
  ContText: string;
begin
  SetState(psPresentingConcept);
  FCurrentConcept := FReturnConcept;
  FCurrentPackage := FReturnPackage;

  if FCurrentConcept <> nil then
  begin
    FCurrentResource := FCurrentPackage.FindBestResourceForTopic(FCurrentConcept.Title);
    SelectResource(FCurrentResource);

    ContText := 'Voltando ao tópico ' + FCurrentConcept.Title + ': ' +
      FCurrentConcept.Description + '.';
  end
  else
    ContText := ContinuePresentation;

  Result := FPendingResumeNarrative + ' ' + ContText;
  FPendingResumeNarrative := '';

  if Assigned(FOnNarrativeSpoken) then
    FOnNarrativeSpoken(Self, Result, 'neutro', 'agExplain');
end;

function TAIPresentationAgent.SelectNextProject: string;
var
  Idx, NextIdx: Integer;
  Hist: TAIPersonPresentationHistory;
begin
  SetState(psTransitioning);
  Hist := GetPersonHistory(FActivePersonID);

  if FCurrentPackage <> nil then
  begin
    Idx := FResourceManager.FPackages.IndexOf(FCurrentPackage);
    NextIdx := (Idx + 1) mod FResourceManager.PackageCount;
  end
  else
    NextIdx := 0;

  FCurrentPackage := FResourceManager.GetPackage(NextIdx);
  if Assigned(FOnProjectChanged) and (FCurrentPackage <> nil) then
    FOnProjectChanged(Self, FCurrentPackage);

  // Seleciona o primeiro conceito do novo projeto
  FCurrentConcept := Hist.GetNextUnviewedConcept(FCurrentPackage);
  if FCurrentConcept <> nil then
  begin
    FCurrentResource := FCurrentPackage.FindBestResourceForTopic(FCurrentConcept.Title);
    SelectResource(FCurrentResource);
    Hist.MarkConceptViewed(FCurrentPackage.ProjectCode, FCurrentConcept.ID);

    Result := 'Agora vamos conhecer outro projeto de destaque: ' + FCurrentPackage.Title + '. ' +
      FCurrentPackage.Summary + ' Vamos examinar ' + FCurrentConcept.Title +
      ' através do recurso exibido na tela.';
  end
  else
  begin
    Result := 'Passando para o projeto ' + FCurrentPackage.Title + ': ' + FCurrentPackage.Summary;
  end;

  SetState(psPresentingConcept);
  if Assigned(FOnNarrativeSpoken) then
    FOnNarrativeSpoken(Self, Result, 'alegria', 'agPoint');
end;

function TAIPresentationAgent.SelectConcept(const AConceptID: string): string;
var
  C: TPresentationConcept;
begin
  if FCurrentPackage = nil then Exit('');
  C := FCurrentPackage.FindConcept(AConceptID);
  if C <> nil then
  begin
    FCurrentConcept := C;
    FCurrentResource := FCurrentPackage.FindBestResourceForTopic(C.Title);
    SelectResource(FCurrentResource);
    SetState(psPresentingConcept);

    Result := 'Examinando o tópico ' + C.Title + ': ' + C.Description;
    if Assigned(FOnConceptAdvanced) then
      FOnConceptAdvanced(Self, C);
    if Assigned(FOnNarrativeSpoken) then
      FOnNarrativeSpoken(Self, Result, 'neutro', 'agExplain');
  end
  else
    Result := '';
end;

function TAIPresentationAgent.GetStatusSummary: string;
var
  StateStr: string;
begin
  case FState of
    psIdle: StateStr := 'Aguardando Visitante';
    psGreeting: StateStr := 'Saudando Visitante';
    psPresentingConcept: StateStr := 'Apresentando Conceito';
    psAnsweringQuestion: StateStr := 'Respondendo Dúvida';
    psPaused: StateStr := 'Pausado';
    psTransitioning: StateStr := 'Transição de Projeto';
  end;

  Result := 'Estado: ' + StateStr;
  if FCurrentPackage <> nil then
    Result := Result + ' | Projeto: ' + FCurrentPackage.Title;
  if FCurrentConcept <> nil then
    Result := Result + ' | Tópico: ' + FCurrentConcept.Title;
  if FCurrentResource <> nil then
    Result := Result + ' | Recurso: ' + FCurrentResource.Title;
end;

end.
