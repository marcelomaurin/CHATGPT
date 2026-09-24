# Face Recognition Demo - Lazarus & YOLO Landmarks

Demonstração do pipeline completo de reconhecimento facial e identidade baseado em landmarks extraídos por modelos YOLO (ex.: `yolov8n-face.pt`).

## Componentes Utilizados
- `TYOLO`: Detector e extrator de keypoints / landmarks faciais.
- `TAIFaceRecognition`: Fachada de alto nível para orquestração.
- `TAIFaceRegistry`: Gerenciamento e armazenamento de perfis e amostras.
- `TAIFaceDescriptorBuilder`: Geração de descritores geométricos normalizados.
- `TAIFaceMatcher`: Comparação por similaridade de cosseno e distância euclidiana.

## Funcionalidades Demonstradas
1. Cadastro de uma identidade de referência a partir de uma foto (validação de face única, bounding box e qualidade).
2. Extração de características geométricas invariantes à escala e rotação dos olhos.
3. Consulta e reconhecimento de novas imagens.
4. Exibição clara de cada etapa do pipeline:
   - Coordenadas da face detectada
   - Confiança do modelo
   - Quantidade de keypoints
   - Dimensão do vetor descritor
   - Score de similaridade e distância
   - Status da classificação (`MATCH`, `UNKNOWN`, `AMBIGUOUS` ou `ERROR`).
