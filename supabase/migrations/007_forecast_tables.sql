-- =============================================
-- CRS Brands – 007: Star Schema S&OP (Forecast de Demanda)
-- Modelo dimensional (Star Schema) conforme docs/Documentacao_Migrations_SOP.md
-- Ordem: ENUM -> Dimensoes (regioes, produtos, de_para) -> Fato (fatos_vendas)
-- Rodar APOS 006_prevent_self_delete.sql
-- =============================================

-- ======= UP ========

-- 0. ENUM para tipo_cenario (criado antes da tabela fato)
DO $$
BEGIN
  CREATE TYPE public.crs_brands_tipo_cenario AS ENUM (
    'REALIZADO', 'ORCADO', 'DEMANDA_ESTATISTICA', 'DEMANDA_FINAL'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END$$;

-- ---------------------------------------------
-- 1. DIMENSOES (Master Data)
-- ---------------------------------------------

-- 1.1 Regioes de venda
CREATE TABLE IF NOT EXISTS public.crs_brands_regioes (
  id_regional VARCHAR(50) PRIMARY KEY,
  nome VARCHAR(255),
  informacao_demanda VARCHAR(255),
  gr_vendas VARCHAR(255)
);

-- 1.2 Portfolio de produtos (hierarquia)
CREATE TABLE IF NOT EXISTS public.crs_brands_produtos (
  id_item VARCHAR(50) PRIMARY KEY,
  descricao VARCHAR(255),
  tipo_mercado VARCHAR(100),
  familia_totvs VARCHAR(150),
  familia_comercial VARCHAR(150),
  familia_plan_i VARCHAR(150),
  familia_plan_ii VARCHAR(150),
  curva_abc_est CHAR(1) CHECK (curva_abc_est IN ('A', 'B', 'C')),
  curva_abc_vendas CHAR(1) CHECK (curva_abc_vendas IN ('A', 'B', 'C')),
  numero INTEGER
);

-- 1.3 De-Para de SKUs (ciclo de vida / unificacao de historico)
CREATE TABLE IF NOT EXISTS public.crs_brands_de_para (
  id_item_antigo VARCHAR(50) PRIMARY KEY
    REFERENCES public.crs_brands_produtos(id_item) ON DELETE RESTRICT,
  id_item_novo VARCHAR(50) NOT NULL
    REFERENCES public.crs_brands_produtos(id_item) ON DELETE RESTRICT,
  data_alteracao TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Gatilho: evita auto-mapeamento e loops de mapeamento (ex.: A -> B -> A)
CREATE OR REPLACE FUNCTION public.crs_brands_de_para_prevent_loop()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_cursor VARCHAR(50);
  v_steps INTEGER := 0;
BEGIN
  -- 1) auto-mapeamento
  IF NEW.id_item_antigo = NEW.id_item_novo THEN
    RAISE EXCEPTION 'Mapeamento invalido: o item % nao pode mapear para si mesmo.', NEW.id_item_antigo;
  END IF;

  -- 2) segue a cadeia a partir do destino; se voltar a origem, ha loop
  v_cursor := NEW.id_item_novo;
  WHILE v_cursor IS NOT NULL LOOP
    IF v_cursor = NEW.id_item_antigo THEN
      RAISE EXCEPTION 'Mapeamento invalido: loop detectado envolvendo % -> %.',
        NEW.id_item_antigo, NEW.id_item_novo;
    END IF;
    v_steps := v_steps + 1;
    IF v_steps > 1000 THEN
      RAISE EXCEPTION 'Mapeamento invalido: cadeia muito longa (possivel loop).';
    END IF;
    SELECT d.id_item_novo INTO v_cursor
    FROM public.crs_brands_de_para d
    WHERE d.id_item_antigo = v_cursor;
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_crs_brands_de_para_prevent_loop ON public.crs_brands_de_para;
CREATE TRIGGER trg_crs_brands_de_para_prevent_loop
BEFORE INSERT OR UPDATE ON public.crs_brands_de_para
FOR EACH ROW
EXECUTE FUNCTION public.crs_brands_de_para_prevent_loop();

-- ---------------------------------------------
-- 2. TABELA FATO (Transacional verticalizada)
-- ---------------------------------------------
-- Nomes de coluna conforme o SOP (incluindo "volume_orçado" com acento e
-- "volume_demmanda"). Identificadores com acento exigem aspas duplas no SQL.
CREATE TABLE IF NOT EXISTS public.crs_brands_fatos_vendas (
  data_referencia DATE NOT NULL,
  id_item VARCHAR(50) NOT NULL
    REFERENCES public.crs_brands_produtos(id_item) ON DELETE RESTRICT,
  id_regional VARCHAR(50) NOT NULL
    REFERENCES public.crs_brands_regioes(id_regional) ON DELETE RESTRICT,
  tipo_cenario public.crs_brands_tipo_cenario NOT NULL,
  volume_orcado DECIMAL(15,2),
  volume_realizado DECIMAL(15,2),
  volume_demanda DECIMAL(15,2),
  CONSTRAINT pk_crs_brands_fatos_vendas
    PRIMARY KEY (data_referencia, id_item, id_regional, tipo_cenario)
);

CREATE INDEX IF NOT EXISTS idx_fatos_vendas_data
  ON public.crs_brands_fatos_vendas(data_referencia);
CREATE INDEX IF NOT EXISTS idx_fatos_vendas_tipo_cenario
  ON public.crs_brands_fatos_vendas(tipo_cenario);

-- ======= DOWN ========
-- DROP TABLE IF EXISTS public.crs_brands_fatos_vendas CASCADE;
-- DROP TRIGGER IF EXISTS trg_crs_brands_de_para_prevent_loop ON public.crs_brands_de_para;
-- DROP FUNCTION IF EXISTS public.crs_brands_de_para_prevent_loop();
-- DROP TABLE IF EXISTS public.crs_brands_de_para CASCADE;
-- DROP TABLE IF EXISTS public.crs_brands_produtos CASCADE;
-- DROP TABLE IF EXISTS public.crs_brands_regioes CASCADE;
-- DROP TYPE IF EXISTS public.crs_brands_tipo_cenario;
