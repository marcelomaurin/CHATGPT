-- ============================================================================
-- Base de demonstracao para o pg_schema_rag_demo
--
-- Os nomes de colunas sao DELIBERADAMENTE abreviados e pouco descritivos.
-- E o COMMENT ON que carrega o significado. Esse e exatamente o cenario em que
-- o RAG de esquema se prova: sem os comentarios, uma pergunta como
-- "faturamento por competencia" nao casa com a coluna "dt_ref".
--
-- Uso:
--   createdb rag_demo
--   psql -d rag_demo -f demo_schema.sql
-- ============================================================================

DROP TABLE IF EXISTS itens_nf     CASCADE;
DROP TABLE IF EXISTS notas_fiscais CASCADE;
DROP TABLE IF EXISTS produtos      CASCADE;
DROP TABLE IF EXISTS fam_prod      CASCADE;
DROP TABLE IF EXISTS clientes      CASCADE;
DROP TABLE IF EXISTS municipios    CASCADE;
DROP TABLE IF EXISTS vendedores    CASCADE;

-- ---------------------------------------------------------------------------
CREATE TABLE municipios (
    id      serial PRIMARY KEY,
    nm      varchar(120) NOT NULL,
    uf      char(2)      NOT NULL,
    cd_ibge varchar(7)
);

COMMENT ON TABLE  municipios         IS 'Municipios brasileiros usados para localizar clientes e apurar vendas por regiao';
COMMENT ON COLUMN municipios.nm      IS 'Nome do municipio, cidade';
COMMENT ON COLUMN municipios.uf      IS 'Sigla da unidade federativa, estado';
COMMENT ON COLUMN municipios.cd_ibge IS 'Codigo IBGE do municipio';

-- ---------------------------------------------------------------------------
CREATE TABLE clientes (
    id      serial PRIMARY KEY,
    rz      varchar(150) NOT NULL,
    fant    varchar(150),
    doc     varchar(18),
    mun_id  integer REFERENCES municipios(id),
    sit     char(1) NOT NULL DEFAULT 'A',
    dt_cad  date    NOT NULL DEFAULT CURRENT_DATE,
    lim_cr  numeric(14,2) DEFAULT 0
);

COMMENT ON TABLE  clientes        IS 'Cadastro de clientes da empresa, pessoas juridicas e fisicas compradoras';
COMMENT ON COLUMN clientes.rz     IS 'Razao social do cliente, nome completo';
COMMENT ON COLUMN clientes.fant   IS 'Nome fantasia, nome comercial do cliente';
COMMENT ON COLUMN clientes.doc    IS 'CNPJ ou CPF do cliente, documento fiscal';
COMMENT ON COLUMN clientes.mun_id IS 'Municipio de domicilio do cliente';
COMMENT ON COLUMN clientes.sit    IS 'Situacao cadastral: A = ativo, I = inativo, B = bloqueado';
COMMENT ON COLUMN clientes.dt_cad IS 'Data de cadastro do cliente';
COMMENT ON COLUMN clientes.lim_cr IS 'Limite de credito aprovado em reais';

-- ---------------------------------------------------------------------------
CREATE TABLE vendedores (
    id     serial PRIMARY KEY,
    nm     varchar(120) NOT NULL,
    mat    varchar(20),
    perc_c numeric(5,2) DEFAULT 0,
    ativo  boolean NOT NULL DEFAULT true
);

COMMENT ON TABLE  vendedores        IS 'Equipe comercial, representantes responsaveis pelas vendas';
COMMENT ON COLUMN vendedores.nm     IS 'Nome do vendedor, representante comercial';
COMMENT ON COLUMN vendedores.mat    IS 'Matricula funcional do vendedor';
COMMENT ON COLUMN vendedores.perc_c IS 'Percentual de comissao sobre o valor vendido';
COMMENT ON COLUMN vendedores.ativo  IS 'Indica se o vendedor esta ativo na equipe';

-- ---------------------------------------------------------------------------
CREATE TABLE fam_prod (
    id serial PRIMARY KEY,
    ds varchar(80) NOT NULL
);

COMMENT ON TABLE  fam_prod    IS 'Familias de produtos, categoria ou linha de produto';
COMMENT ON COLUMN fam_prod.ds IS 'Descricao da familia, nome da categoria de produto';

-- ---------------------------------------------------------------------------
CREATE TABLE produtos (
    id      serial PRIMARY KEY,
    ds      varchar(150) NOT NULL,
    cod     varchar(30),
    fam_id  integer REFERENCES fam_prod(id),
    un      varchar(6) NOT NULL DEFAULT 'UN',
    vl_un   numeric(14,4) NOT NULL DEFAULT 0,
    est_min numeric(14,3) DEFAULT 0,
    ncm     varchar(10)
);

COMMENT ON TABLE  produtos         IS 'Cadastro de produtos disponiveis para venda, itens do catalogo';
COMMENT ON COLUMN produtos.ds      IS 'Descricao do produto, nome do item';
COMMENT ON COLUMN produtos.cod     IS 'Codigo interno ou SKU do produto';
COMMENT ON COLUMN produtos.fam_id  IS 'Familia ou categoria a que o produto pertence';
COMMENT ON COLUMN produtos.un      IS 'Unidade de medida: UN, KG, CX, LT';
COMMENT ON COLUMN produtos.vl_un   IS 'Preco unitario de tabela em reais';
COMMENT ON COLUMN produtos.est_min IS 'Estoque minimo de seguranca';
COMMENT ON COLUMN produtos.ncm     IS 'Codigo NCM de classificacao fiscal';

-- ---------------------------------------------------------------------------
CREATE TABLE notas_fiscais (
    id      serial PRIMARY KEY,
    num     integer NOT NULL,
    serie   varchar(5) NOT NULL DEFAULT '1',
    cli_id  integer NOT NULL REFERENCES clientes(id),
    vend_id integer REFERENCES vendedores(id),
    dt_emi  date NOT NULL,
    dt_ref  date NOT NULL,
    vl_tot  numeric(14,2) NOT NULL DEFAULT 0,
    vl_desc numeric(14,2) NOT NULL DEFAULT 0,
    st      char(1) NOT NULL DEFAULT 'E'
);

COMMENT ON TABLE  notas_fiscais         IS 'Notas fiscais de venda emitidas, cabecalho do faturamento';
COMMENT ON COLUMN notas_fiscais.num     IS 'Numero da nota fiscal';
COMMENT ON COLUMN notas_fiscais.serie   IS 'Serie da nota fiscal';
COMMENT ON COLUMN notas_fiscais.cli_id  IS 'Cliente destinatario da nota';
COMMENT ON COLUMN notas_fiscais.vend_id IS 'Vendedor responsavel pela venda';
COMMENT ON COLUMN notas_fiscais.dt_emi  IS 'Data de emissao da nota fiscal';
COMMENT ON COLUMN notas_fiscais.dt_ref  IS 'Data de competencia do faturamento, mes de referencia contabil';
COMMENT ON COLUMN notas_fiscais.vl_tot  IS 'Valor total da nota em reais, faturamento bruto';
COMMENT ON COLUMN notas_fiscais.vl_desc IS 'Valor total de desconto concedido em reais';
COMMENT ON COLUMN notas_fiscais.st      IS 'Situacao: E = emitida, C = cancelada, D = denegada';

-- ---------------------------------------------------------------------------
CREATE TABLE itens_nf (
    id      serial PRIMARY KEY,
    nf_id   integer NOT NULL REFERENCES notas_fiscais(id),
    prod_id integer NOT NULL REFERENCES produtos(id),
    seq     integer NOT NULL,
    qtd     numeric(14,3) NOT NULL,
    vl_un   numeric(14,4) NOT NULL,
    vl_tot  numeric(14,2) NOT NULL
);

COMMENT ON TABLE  itens_nf         IS 'Itens das notas fiscais, produtos vendidos em cada nota';
COMMENT ON COLUMN itens_nf.nf_id   IS 'Nota fiscal a que o item pertence';
COMMENT ON COLUMN itens_nf.prod_id IS 'Produto vendido no item';
COMMENT ON COLUMN itens_nf.seq     IS 'Numero sequencial do item dentro da nota';
COMMENT ON COLUMN itens_nf.qtd     IS 'Quantidade vendida do produto';
COMMENT ON COLUMN itens_nf.vl_un   IS 'Preco unitario praticado na venda em reais';
COMMENT ON COLUMN itens_nf.vl_tot  IS 'Valor total do item em reais, quantidade vezes preco unitario';

-- ---------------------------------------------------------------------------
-- Dados minimos para que as consultas geradas retornem algo
-- ---------------------------------------------------------------------------
INSERT INTO municipios (nm, uf, cd_ibge) VALUES
  ('Ribeirao Preto', 'SP', '3543402'),
  ('Jardinopolis',   'SP', '3525300'),
  ('Campinas',       'SP', '3509502'),
  ('Belo Horizonte', 'MG', '3106200');

INSERT INTO clientes (rz, fant, doc, mun_id, sit, dt_cad, lim_cr) VALUES
  ('Comercial Aurora Ltda',     'Aurora',    '12.345.678/0001-90', 1, 'A', '2023-02-10', 50000),
  ('Distribuidora Serra Norte', 'SerraNorte','23.456.789/0001-01', 2, 'A', '2023-06-01', 120000),
  ('Mercearia do Vale ME',      'Do Vale',   '34.567.890/0001-12', 3, 'I', '2022-11-20', 15000),
  ('Atacado Minas Center SA',   'MinasCenter','45.678.901/0001-23',4, 'A', '2024-01-15', 300000);

INSERT INTO vendedores (nm, mat, perc_c, ativo) VALUES
  ('Carlos Peixoto', 'V001', 3.50, true),
  ('Marta Andrade',  'V002', 4.00, true),
  ('Nelson Faria',   'V003', 2.75, false);

INSERT INTO fam_prod (ds) VALUES
  ('Bebidas'), ('Limpeza'), ('Mercearia Seca'), ('Higiene');

INSERT INTO produtos (ds, cod, fam_id, un, vl_un, est_min, ncm) VALUES
  ('Refrigerante Cola 2L',       'BEB001', 1, 'UN', 7.4900,  120, '22021000'),
  ('Agua Mineral 500ml Caixa',   'BEB002', 1, 'CX', 28.9000,  40, '22011000'),
  ('Detergente Neutro 500ml',    'LIM001', 2, 'UN', 2.7500,  200, '34022000'),
  ('Sabao em Po 1kg',            'LIM002', 2, 'UN', 12.3000,  80, '34022000'),
  ('Arroz Tipo 1 5kg',           'MER001', 3, 'UN', 26.9000, 150, '10063021'),
  ('Feijao Carioca 1kg',         'MER002', 3, 'UN', 8.4000,  180, '07133399'),
  ('Sabonete Glicerina 90g',     'HIG001', 4, 'UN', 2.1000,  300, '34011190');

INSERT INTO notas_fiscais (num, serie, cli_id, vend_id, dt_emi, dt_ref, vl_tot, vl_desc, st) VALUES
  (1001, '1', 1, 1, '2025-01-15', '2025-01-01',  1874.50,  40.00, 'E'),
  (1002, '1', 2, 2, '2025-01-28', '2025-01-01',  5320.00, 120.00, 'E'),
  (1003, '1', 4, 1, '2025-02-05', '2025-02-01', 12840.00, 380.00, 'E'),
  (1004, '1', 1, 2, '2025-02-19', '2025-02-01',   942.30,   0.00, 'C'),
  (1005, '1', 2, 1, '2025-03-03', '2025-03-01',  7415.80, 200.00, 'E'),
  (1006, '1', 4, 2, '2025-03-22', '2025-03-01',  3208.90,  55.00, 'E');

INSERT INTO itens_nf (nf_id, prod_id, seq, qtd, vl_un, vl_tot) VALUES
  (1, 1, 1, 100.000,  7.4900,  749.00),
  (1, 5, 2,  30.000, 26.9000,  807.00),
  (1, 3, 3, 116.000,  2.7500,  319.00),
  (2, 5, 1, 120.000, 26.9000, 3228.00),
  (2, 6, 2, 200.000,  8.4000, 1680.00),
  (2, 7, 3, 200.000,  2.1000,  420.00),
  (3, 2, 1, 300.000, 28.9000, 8670.00),
  (3, 4, 2, 200.000, 12.3000, 2460.00),
  (3, 1, 3, 230.000,  7.4900, 1722.70),
  (5, 5, 1, 200.000, 26.9000, 5380.00),
  (5, 6, 2, 100.000,  8.4000,  840.00),
  (5, 3, 3, 435.000,  2.7500, 1196.25),
  (6, 1, 1, 200.000,  7.4900, 1498.00),
  (6, 4, 2, 100.000, 12.3000, 1230.00),
  (6, 7, 3, 230.000,  2.1000,  483.00);
