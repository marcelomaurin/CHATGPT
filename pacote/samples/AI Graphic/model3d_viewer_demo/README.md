# Model3D Viewer Demo (ai3dmodelviewer & aimodel3d)

Este projeto demonstra a utilização prática e interativa dos componentes `TAI3DModelViewer` e `TAIModel3D` do pacote `openai_graphic`.

## Funcionalidades Demonstradas
- **Carregamento Real de Modelos 3D**: Suporte a leitura de arquivos Wavefront OBJ e STL (binário e texto) via `TAIModel3D.LoadFromFile`.
- **Geração Procedural de Geometria 3D**: Criação instantânea de malhas 3D (Cubo, Pirâmide, Cilindro) para testes sem necessidade de arquivos externos.
- **Renderização e Projeção 3D Interativa**: Visualização dinâmica no componente visual `TAI3DModelViewer`.
- **Modos de Renderização**: Alternância entre modos Sólido (`rmSolid`), Wireframe (`rmWireframe`) e Nuvem de Pontos (`rmPoints`).
- **Navegação e Câmera**: Rotação orbital através do arrasto com o botão esquerdo do mouse, zoom interativo via scroll do mouse e botões de controle (`ZoomIn`, `ZoomOut`, `ResetCamera`).
- **Transformações Geométricas**: Rotação nos eixos X, Y e Z através de `TAIModel3D.Rotate`.
- **Estatísticas da Malha**: Apresentação em tempo real de número de faces (triângulos), vértices, centroide (MidX/Y/Z), dimensões da Bounding Box e raio do modelo.
- **Exportação de Imagem**: Captura da cena 3D renderizada para arquivo PNG/BMP via `TAI3DModelViewer.ExportScreenshot`.

## Como Compilar e Executar
1. Abra o projeto `model3d_viewer_demo.lpi` no Lazarus.
2. Compile com `Ctrl+F9` ou execute via linha de comando:
   ```bash
   lazbuild model3d_viewer_demo.lpi
   ```
3. Execute o binário gerado e interaja diretamente com o modelo 3D.
