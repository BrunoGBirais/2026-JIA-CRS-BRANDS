-- =============================================
-- CRS Brands – 008: Funcoes RPC (CRUD) – crs_brands_produtos
-- =============================================
-- Stored procedures para o Modulo de Gestao de Produtos (Master Data).
-- Expostas via PostgREST RPC (POST /rest/v1/rpc/<funcao>) e consumidas pelo
-- frontend. Os limites de string (VARCHAR) e o dominio das curvas ABC (CHECK)
-- sao garantidos pela tabela public.crs_brands_produtos definida em 007.
--
-- Rodar APOS 007_forecast_tables.sql
-- =============================================

-- ======= UP ========

-- ---------------------------------------------
-- 1. READ – retorna todos os produtos
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION public.crs_brands_get_produtos()
RETURNS SETOF public.crs_brands_produtos
SECURITY DEFINER
SET search_path = public
LANGUAGE sql
STABLE
AS $$
  SELECT *
  FROM public.crs_brands_produtos
  ORDER BY id_item;
$$;

-- ---------------------------------------------
-- 2. CREATE – insere um novo produto
--    Retorna a linha inserida.
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION public.crs_brands_insert_produto(
  p_id_item           VARCHAR(50),
  p_descricao         VARCHAR(255),
  p_tipo_mercado      VARCHAR(100) DEFAULT NULL,
  p_familia_totvs     VARCHAR(150) DEFAULT NULL,
  p_familia_comercial VARCHAR(150) DEFAULT NULL,
  p_familia_plan_i    VARCHAR(150) DEFAULT NULL,
  p_familia_plan_ii   VARCHAR(150) DEFAULT NULL,
  p_curva_abc_est     CHAR(1)      DEFAULT NULL,
  p_curva_abc_vendas  CHAR(1)      DEFAULT NULL,
  p_numero            INTEGER      DEFAULT NULL
)
RETURNS public.crs_brands_produtos
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_row public.crs_brands_produtos;
BEGIN
  IF p_id_item IS NULL OR length(trim(p_id_item)) = 0 THEN
    RAISE EXCEPTION 'id_item e obrigatorio.';
  END IF;
  IF p_descricao IS NULL OR length(trim(p_descricao)) = 0 THEN
    RAISE EXCEPTION 'descricao e obrigatoria.';
  END IF;

  INSERT INTO public.crs_brands_produtos (
    id_item, descricao, tipo_mercado,
    familia_totvs, familia_comercial, familia_plan_i, familia_plan_ii,
    curva_abc_est, curva_abc_vendas, numero
  )
  VALUES (
    p_id_item, p_descricao, p_tipo_mercado,
    p_familia_totvs, p_familia_comercial, p_familia_plan_i, p_familia_plan_ii,
    p_curva_abc_est, p_curva_abc_vendas, p_numero
  )
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

-- ---------------------------------------------
-- 3. UPDATE – atualiza um produto existente (busca por p_id_item)
--    A chave (id_item) nao e alterada. Retorna a linha atualizada;
--    se o id nao existir, levanta excecao.
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION public.crs_brands_update_produto(
  p_id_item           VARCHAR(50),
  p_descricao         VARCHAR(255),
  p_tipo_mercado      VARCHAR(100) DEFAULT NULL,
  p_familia_totvs     VARCHAR(150) DEFAULT NULL,
  p_familia_comercial VARCHAR(150) DEFAULT NULL,
  p_familia_plan_i    VARCHAR(150) DEFAULT NULL,
  p_familia_plan_ii   VARCHAR(150) DEFAULT NULL,
  p_curva_abc_est     CHAR(1)      DEFAULT NULL,
  p_curva_abc_vendas  CHAR(1)      DEFAULT NULL,
  p_numero            INTEGER      DEFAULT NULL
)
RETURNS public.crs_brands_produtos
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_row public.crs_brands_produtos;
BEGIN
  IF p_id_item IS NULL OR length(trim(p_id_item)) = 0 THEN
    RAISE EXCEPTION 'id_item e obrigatorio.';
  END IF;

  UPDATE public.crs_brands_produtos
  SET
    descricao         = p_descricao,
    tipo_mercado      = p_tipo_mercado,
    familia_totvs     = p_familia_totvs,
    familia_comercial = p_familia_comercial,
    familia_plan_i    = p_familia_plan_i,
    familia_plan_ii   = p_familia_plan_ii,
    curva_abc_est     = p_curva_abc_est,
    curva_abc_vendas  = p_curva_abc_vendas,
    numero            = p_numero
  WHERE id_item = p_id_item
  RETURNING * INTO v_row;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Produto com id_item % nao encontrado.', p_id_item;
  END IF;

  RETURN v_row;
END;
$$;

-- ---------------------------------------------
-- 4. DELETE – remove um produto
--    Retorna TRUE se removido. Caso o produto possua historico de vendas
--    (FK em crs_brands_fatos_vendas / crs_brands_de_para com ON DELETE RESTRICT),
--    o PostgreSQL levanta foreign_key_violation e a excecao se propaga ao
--    frontend para tratamento amigavel.
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION public.crs_brands_delete_produto(
  p_id_item VARCHAR(50)
)
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  DELETE FROM public.crs_brands_produtos
  WHERE id_item = p_id_item;

  GET DIAGNOSTICS v_count = ROW_COUNT;

  IF v_count = 0 THEN
    RAISE EXCEPTION 'Produto com id_item % nao encontrado.', p_id_item;
  END IF;

  RETURN TRUE;
END;
$$;

-- ======= DOWN ========
-- DROP FUNCTION IF EXISTS public.crs_brands_delete_produto(VARCHAR);
-- DROP FUNCTION IF EXISTS public.crs_brands_update_produto(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, CHAR, CHAR, INTEGER);
-- DROP FUNCTION IF EXISTS public.crs_brands_insert_produto(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, CHAR, CHAR, INTEGER);
-- DROP FUNCTION IF EXISTS public.crs_brands_get_produtos();
