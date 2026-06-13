-- Inicialização do banco de dados maurinsoft_chatgpt
-- Adaptado de dbtokenlist.pas (TDBTokenList)

CREATE TABLE IF NOT EXISTS tokens (
    key   VARCHAR(255) NOT NULL PRIMARY KEY,
    token TEXT         NOT NULL
);
