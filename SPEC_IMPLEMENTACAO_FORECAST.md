# 📊 SISTEMA DE FORECAST CRS BRANDS - ESPECIFICAÇÃO COMPLETA
## Documentação para Implementação por Agente IA

---

## 📋 ÍNDICE

1. [Visão Geral do Sistema](#1-visão-geral-do-sistema)
2. [Arquitetura do Projeto](#2-arquitetura-do-projeto)
3. [Estrutura de Banco de Dados](#3-estrutura-de-banco-de-dados)
4. [Migrations Supabase](#4-migrations-supabase)
5. [Workflows n8n](#5-workflows-n8n)
6. [Endpoints da API](#6-endpoints-da-api)
7. [Front-end](#7-front-end)
8. [Casos de Uso](#8-casos-de-uso)
9. [Checklist de Implementação](#9-checklist-de-implementação)

---

## 1. VISÃO GERAL DO SISTEMA

### 1.1 Objetivo

Criar um **Sistema de Previsão de Vendas (Forecast)** para a CRS Brands que:

- ✅ Substitui o sistema atual de chat/RAG por funcionalidades de forecast
- ✅ Mantém a autenticação e gestão de usuários do Supabase
- ✅ Processa uploads de planilhas Excel com histórico de vendas
- ✅ Calcula previsões usando a metodologia determinística da planilha atual
- ✅ Exibe dashboards e relatórios de forecast
- ✅ Permite comparação de cenários (otimista, pessimista, realista)

### 1.2 Diferenças do Sistema Atual

| Aspecto | Sistema Atual (Imagens Bahia) | Novo Sistema (Forecast CRS) |
|---------|------------------------------|----------------------------|
| **Foco** | Chat conversacional + RAG | Previsão de vendas + Analytics |
| **Dados** | Documentos MD (conhecimento) | Planilhas Excel (vendas históricas) |
| **Processamento** | LLM para respostas | Cálculos determinísticos + agregações |
| **Outputs** | Mensagens de chat | Relatórios, gráficos, KPIs |
| **Histórico** | Sessões de chat | Versões de forecast |

### 1.3 Tecnologias

- **Backend**: n8n (workflows de automação)
- **Banco de Dados**: Supabase (PostgreSQL + GoTrue)
- **Front-end**: HTML/CSS/JS single-file
- **Processamento**: Python (openpyxl, pandas) via n8n Code node
- **Auth**: Supabase Auth (multi-tenant por empresa)

---

## 2. ARQUITETURA DO PROJETO

### 2.1 Estrutura de Diretórios

```
CRS-Brants/
├── docs/
│   └── metodologia/
│       └── METODOLOGIA_FORECAST.md    # Documentação da metodologia (já existe)
│
├── front/
│   └── forecast.html                  # Interface web do sistema de forecast
│
├── supabase/
│   ├── criacao_admin/
│   │   └── seed.admin.ps1            # Script para criar admin (reutilizar)
│   └── migrations/
│       ├── 001_user_crud_functions.sql        # (MANTER - já existe)
│       ├── 002_add_roles.sql                  # (MANTER - já existe)
│       ├── 003_admin_guards.sql               # (MANTER - já existe)
│       ├── 004_company_scope.sql              # (MANTER - já existe)
│       ├── 005_prevent_self_role_change.sql   # (MANTER - já existe)
│       ├── 006_prevent_self_delete.sql        # (MANTER - já existe)
│       ├── 007_forecast_tables.sql            # ⭐ CRIAR - Tabelas de forecast
│       ├── 008_forecast_functions.sql         # ⭐ CRIAR - Funções SQL
│       └── 009_forecast_policies.sql          # ⭐ CRIAR - RLS policies
│
└── workflows/                         # Workflows n8n
    ├── CRS-Forecast-Upload-Historico.json     # ⭐ CRIAR - Upload de histórico
    ├── CRS-Forecast-Calcular-Previsao.json    # ⭐ CRIAR - Cálculo de forecast
    ├── CRS-Forecast-API-Dashboard.json        # ⭐ CRIAR - API para dashboard
    ├── CRS-Forecast-GET-Historicos.json       # ⭐ CRIAR - Listar históricos
    ├── CRS-Forecast-GET-Previsoes.json        # ⭐ CRIAR - Listar previsões
    ├── CRS-Forecast-DELETE-Previsao.json      # ⭐ CRIAR - Deletar previsão
    └── CRS-Forecast-Export-Excel.json         # ⭐ CRIAR - Exportar para Excel
```

### 2.2 Fluxo de Dados

```
┌─────────────────┐
│   Front-end     │
│ (forecast.html) │
└────────┬────────┘
         │
         │ HTTP Requests
         ▼
┌─────────────────────────────────────┐
│          n8n Workflows              │
│  ┌───────────────────────────────┐  │
│  │ 1. Upload Histórico           │  │
│  │    - Recebe Excel             │  │
│  │    - Valida estrutura         │  │
│  │    - Salva no banco           │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ 2. Calcular Previsão          │  │
│  │    - Lê histórico             │  │
│  │    - Aplica metodologia       │  │
│  │    - Calcula 12 meses         │  │
│  │    - Calcula KPIs             │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ 3. API Dashboard              │  │
│  │    - Retorna dados agregados  │  │
│  │    - Gráficos e tabelas       │  │
│  └───────────────────────────────┘  │
└──────────────┬──────────────────────┘
               │
               │ SQL Queries
               ▼
┌─────────────────────────────────────┐
│         Supabase PostgreSQL         │
│  ┌────────────────────────────────┐ │
│  │ Tabelas:                       │ │
│  │ - historico_vendas             │ │
│  │ - orcamento                    │ │
│  │ - previsoes                    │ │
│  │ - previsoes_detalhadas         │ │
│  │ - kpis_forecast                │ │
│  └────────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

## 3. ESTRUTURA DE BANCO DE DADOS

### 3.1 Diagrama ER

```
┌──────────────────────┐
│    auth.users        │ (Supabase - já existe)
│──────────────────────│
│ id (PK)              │
│ email                │
│ company_name         │
│ role                 │
└──────────┬───────────┘
           │
           │ 1:N
           │
┌──────────▼───────────┐
│  historico_vendas    │
│──────────────────────│
│ id (PK)              │
│ user_id (FK)         │◄──────┐
│ company_name         │       │
│ ano                  │       │
│ mes                  │       │
│ item (SKU)           │       │
│ descricao            │       │
│ regional             │       │
│ nome_regional        │       │
│ tipo_mercado         │       │
│ familia_totvs        │       │
│ familia_comercial    │       │
│ familia_plan_i       │       │
│ familia_plan_ii      │       │
│ quantidade           │       │
│ valor                │       │
│ upload_batch_id      │       │
│ created_at           │       │
└──────────────────────┘       │
                               │
┌──────────────────────┐       │
│     orcamento        │       │
│──────────────────────│       │
│ id (PK)              │       │
│ user_id (FK)         │───────┤
│ company_name         │       │
│ ano                  │       │
│ item (SKU)           │       │
│ regional             │       │
│ orcamento_total      │       │
│ created_at           │       │
└──────────────────────┘       │
                               │
┌──────────────────────┐       │
│    previsoes         │       │
│──────────────────────│       │
│ id (PK)              │       │
│ user_id (FK)         │───────┤
│ company_name         │       │
│ nome_cenario         │       │
│ descricao            │       │
│ ano_base             │       │
│ ano_previsao         │       │
│ status               │       │
│ created_at           │       │
│ updated_at           │       │
└──────────┬───────────┘       │
           │                   │
           │ 1:N               │
           │                   │
┌──────────▼───────────┐       │
│ previsoes_detalhadas │       │
│──────────────────────│       │
│ id (PK)              │       │
│ previsao_id (FK)     │       │
│ item (SKU)           │       │
│ regional             │       │
│ mes                  │       │
│ quantidade_prevista  │       │
│ orcamento_distribuido│       │
│ vendas_ano_anterior  │       │
│ diferenca            │       │
└──────────────────────┘       │
                               │
┌──────────────────────┐       │
│   kpis_forecast      │       │
│──────────────────────│       │
│ id (PK)              │       │
│ previsao_id (FK)     │       │
│ user_id (FK)         │───────┘
│ company_name         │
│ mape                 │
│ wape                 │
│ forecast_accuracy    │
│ total_previsto       │
│ total_realizado      │
│ erro_total           │
│ created_at           │
└──────────────────────┘
```

### 3.2 Dicionário de Dados

#### 3.2.1 Tabela: `historico_vendas`

Armazena os dados históricos de vendas importados das planilhas Excel.

| Campo | Tipo | Descrição | Obrigatório | Índice |
|-------|------|-----------|-------------|--------|
| `id` | UUID | ID único do registro | Sim | PK |
| `user_id` | UUID | Referência ao usuário (auth.users) | Sim | FK, Index |
| `company_name` | TEXT | Nome da empresa (multi-tenant) | Sim | Index |
| `ano` | INTEGER | Ano da venda (ex: 2023, 2024, 2025) | Sim | Index |
| `mes` | INTEGER | Mês da venda (1-12) | Sim | Index |
| `item` | TEXT | Código SKU do produto | Sim | Index |
| `descricao` | TEXT | Descrição do produto | Sim | - |
| `regional` | TEXT | Código da regional (R01, R02, etc.) | Sim | Index |
| `nome_regional` | TEXT | Nome completo da regional | Sim | - |
| `tipo_mercado` | TEXT | Mercado Interno / Exportação | Sim | - |
| `familia_totvs` | TEXT | Família Totvs do produto | Não | - |
| `familia_comercial` | TEXT | Família Comercial | Não | - |
| `familia_plan_i` | TEXT | Família Plan I | Não | - |
| `familia_plan_ii` | TEXT | Família Plan II | Não | - |
| `quantidade` | DECIMAL(15,2) | Quantidade vendida | Sim | - |
| `valor` | DECIMAL(15,2) | Valor total da venda | Não | - |
| `upload_batch_id` | UUID | ID do batch de upload | Sim | Index |
| `created_at` | TIMESTAMPTZ | Data de criação do registro | Sim | - |

**Constraints:**
- `CHECK (ano >= 2020 AND ano <= 2030)`
- `CHECK (mes >= 1 AND mes <= 12)`
- `CHECK (quantidade >= 0)`

**Índices Compostos:**
- `(company_name, ano, mes, item, regional)` - Para queries de agregação

#### 3.2.2 Tabela: `orcamento`

Armazena os valores de orçamento por SKU e regional.

| Campo | Tipo | Descrição | Obrigatório | Índice |
|-------|------|-----------|-------------|--------|
| `id` | UUID | ID único do registro | Sim | PK |
| `user_id` | UUID | Referência ao usuário | Sim | FK |
| `company_name` | TEXT | Nome da empresa | Sim | Index |
| `ano` | INTEGER | Ano do orçamento | Sim | Index |
| `item` | TEXT | Código SKU | Sim | Index |
| `regional` | TEXT | Código da regional | Sim | Index |
| `orcamento_total` | DECIMAL(15,2) | Valor total orçado para o ano | Sim | - |
| `created_at` | TIMESTAMPTZ | Data de criação | Sim | - |

**Constraints:**
- `UNIQUE (company_name, ano, item, regional)`
- `CHECK (orcamento_total >= 0)`

#### 3.2.3 Tabela: `previsoes`

Armazena os cenários de previsão criados pelos usuários.

| Campo | Tipo | Descrição | Obrigatório | Índice |
|-------|------|-----------|-------------|--------|
| `id` | UUID | ID único da previsão | Sim | PK |
| `user_id` | UUID | Referência ao usuário | Sim | FK, Index |
| `company_name` | TEXT | Nome da empresa | Sim | Index |
| `nome_cenario` | TEXT | Nome do cenário (ex: "Cenário Otimista") | Sim | - |
| `descricao` | TEXT | Descrição detalhada | Não | - |
| `ano_base` | INTEGER | Ano usado como base (ex: 2025) | Sim | - |
| `ano_previsao` | INTEGER | Ano da previsão (ex: 2026) | Sim | - |
| `status` | TEXT | calculando / concluido / erro | Sim | - |
| `created_at` | TIMESTAMPTZ | Data de criação | Sim | - |
| `updated_at` | TIMESTAMPTZ | Data de atualização | Sim | - |

**Constraints:**
- `CHECK (status IN ('calculando', 'concluido', 'erro'))`

#### 3.2.4 Tabela: `previsoes_detalhadas`

Armazena os valores mensais da previsão para cada SKU/Regional.

| Campo | Tipo | Descrição | Obrigatório | Índice |
|-------|------|-----------|-------------|--------|
| `id` | UUID | ID único | Sim | PK |
| `previsao_id` | UUID | Referência à previsão | Sim | FK, Index |
| `item` | TEXT | Código SKU | Sim | Index |
| `regional` | TEXT | Código da regional | Sim | Index |
| `mes` | INTEGER | Mês da previsão (1-12) | Sim | Index |
| `quantidade_prevista` | DECIMAL(15,2) | Quantidade prevista | Sim | - |
| `orcamento_distribuido` | DECIMAL(15,2) | Orçamento distribuído | Sim | - |
| `vendas_ano_anterior` | DECIMAL(15,2) | Vendas do mesmo mês ano anterior | Sim | - |
| `diferenca` | DECIMAL(15,2) | Diferença (previsão - ano anterior) | Sim | - |

**Constraints:**
- `CHECK (mes >= 1 AND mes <= 12)`

**Índices Compostos:**
- `(previsao_id, item, regional, mes)`

#### 3.2.5 Tabela: `kpis_forecast`

Armazena os indicadores de performance do forecast.

| Campo | Tipo | Descrição | Obrigatório | Índice |
|-------|------|-----------|-------------|--------|
| `id` | UUID | ID único | Sim | PK |
| `previsao_id` | UUID | Referência à previsão | Sim | FK, Index |
| `user_id` | UUID | Referência ao usuário | Sim | FK |
| `company_name` | TEXT | Nome da empresa | Sim | Index |
| `mape` | DECIMAL(10,4) | Mean Absolute Percentage Error | Não | - |
| `wape` | DECIMAL(10,4) | Weighted Absolute Percentage Error | Não | - |
| `forecast_accuracy` | DECIMAL(10,4) | Acurácia do forecast (0-1) | Não | - |
| `total_previsto` | DECIMAL(15,2) | Total previsto | Sim | - |
| `total_realizado` | DECIMAL(15,2) | Total realizado (se disponível) | Não | - |
| `erro_total` | DECIMAL(15,2) | Erro total absoluto | Não | - |
| `created_at` | TIMESTAMPTZ | Data de criação | Sim | - |

---

## 4. MIGRATIONS SUPABASE

### 4.1 Migration 007: `007_forecast_tables.sql`

**Objetivo:** Criar todas as tabelas do sistema de forecast.

**Arquivo:** `supabase/migrations/007_forecast_tables.sql`

```sql
-- =============================================
-- CRS Brands – 007: Forecast Tables
-- Cria estrutura de dados para sistema de forecast
-- =============================================

-- ======= UP ========

-- 1. Tabela de histórico de vendas
CREATE TABLE IF NOT EXISTS public.historico_vendas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_name TEXT NOT NULL,
  ano INTEGER NOT NULL CHECK (ano >= 2020 AND ano <= 2030),
  mes INTEGER NOT NULL CHECK (mes >= 1 AND mes <= 12),
  item TEXT NOT NULL,
  descricao TEXT NOT NULL,
  regional TEXT NOT NULL,
  nome_regional TEXT NOT NULL,
  tipo_mercado TEXT NOT NULL,
  familia_totvs TEXT,
  familia_comercial TEXT,
  familia_plan_i TEXT,
  familia_plan_ii TEXT,
  quantidade DECIMAL(15,2) NOT NULL CHECK (quantidade >= 0),
  valor DECIMAL(15,2),
  upload_batch_id UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices para performance
CREATE INDEX idx_historico_vendas_user ON public.historico_vendas(user_id);
CREATE INDEX idx_historico_vendas_company ON public.historico_vendas(company_name);
CREATE INDEX idx_historico_vendas_ano ON public.historico_vendas(ano);
CREATE INDEX idx_historico_vendas_mes ON public.historico_vendas(mes);
CREATE INDEX idx_historico_vendas_item ON public.historico_vendas(item);
CREATE INDEX idx_historico_vendas_regional ON public.historico_vendas(regional);
CREATE INDEX idx_historico_vendas_batch ON public.historico_vendas(upload_batch_id);
CREATE INDEX idx_historico_vendas_composite ON public.historico_vendas(company_name, ano, mes, item, regional);

-- 2. Tabela de orçamento
CREATE TABLE IF NOT EXISTS public.orcamento (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_name TEXT NOT NULL,
  ano INTEGER NOT NULL CHECK (ano >= 2020 AND ano <= 2030),
  item TEXT NOT NULL,
  regional TEXT NOT NULL,
  orcamento_total DECIMAL(15,2) NOT NULL CHECK (orcamento_total >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (company_name, ano, item, regional)
);

-- Índices
CREATE INDEX idx_orcamento_user ON public.orcamento(user_id);
CREATE INDEX idx_orcamento_company ON public.orcamento(company_name);
CREATE INDEX idx_orcamento_ano ON public.orcamento(ano);
CREATE INDEX idx_orcamento_item ON public.orcamento(item);
CREATE INDEX idx_orcamento_regional ON public.orcamento(regional);

-- 3. Tabela de previsões (cenários)
CREATE TABLE IF NOT EXISTS public.previsoes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_name TEXT NOT NULL,
  nome_cenario TEXT NOT NULL,
  descricao TEXT,
  ano_base INTEGER NOT NULL,
  ano_previsao INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'calculando' CHECK (status IN ('calculando', 'concluido', 'erro')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices
CREATE INDEX idx_previsoes_user ON public.previsoes(user_id);
CREATE INDEX idx_previsoes_company ON public.previsoes(company_name);

-- 4. Tabela de previsões detalhadas (valores mensais)
CREATE TABLE IF NOT EXISTS public.previsoes_detalhadas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  previsao_id UUID NOT NULL REFERENCES public.previsoes(id) ON DELETE CASCADE,
  item TEXT NOT NULL,
  regional TEXT NOT NULL,
  mes INTEGER NOT NULL CHECK (mes >= 1 AND mes <= 12),
  quantidade_prevista DECIMAL(15,2) NOT NULL,
  orcamento_distribuido DECIMAL(15,2) NOT NULL,
  vendas_ano_anterior DECIMAL(15,2) NOT NULL,
  diferenca DECIMAL(15,2) NOT NULL
);

-- Índices
CREATE INDEX idx_previsoes_detalhadas_previsao ON public.previsoes_detalhadas(previsao_id);
CREATE INDEX idx_previsoes_detalhadas_item ON public.previsoes_detalhadas(item);
CREATE INDEX idx_previsoes_detalhadas_regional ON public.previsoes_detalhadas(regional);
CREATE INDEX idx_previsoes_detalhadas_mes ON public.previsoes_detalhadas(mes);
CREATE INDEX idx_previsoes_detalhadas_composite ON public.previsoes_detalhadas(previsao_id, item, regional, mes);

-- 5. Tabela de KPIs do forecast
CREATE TABLE IF NOT EXISTS public.kpis_forecast (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  previsao_id UUID NOT NULL REFERENCES public.previsoes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_name TEXT NOT NULL,
  mape DECIMAL(10,4),
  wape DECIMAL(10,4),
  forecast_accuracy DECIMAL(10,4),
  total_previsto DECIMAL(15,2) NOT NULL,
  total_realizado DECIMAL(15,2),
  erro_total DECIMAL(15,2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices
CREATE INDEX idx_kpis_forecast_previsao ON public.kpis_forecast(previsao_id);
CREATE INDEX idx_kpis_forecast_user ON public.kpis_forecast(user_id);
CREATE INDEX idx_kpis_forecast_company ON public.kpis_forecast(company_name);

-- Trigger para atualizar updated_at em previsoes
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_previsoes_updated_at
BEFORE UPDATE ON public.previsoes
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ======= DOWN ========
-- DROP TRIGGER IF EXISTS update_previsoes_updated_at ON public.previsoes;
-- DROP FUNCTION IF EXISTS update_updated_at_column();
-- DROP TABLE IF EXISTS public.kpis_forecast CASCADE;
-- DROP TABLE IF EXISTS public.previsoes_detalhadas CASCADE;
-- DROP TABLE IF EXISTS public.previsoes CASCADE;
-- DROP TABLE IF EXISTS public.orcamento CASCADE;
-- DROP TABLE IF EXISTS public.historico_vendas CASCADE;
```

### 4.2 Migration 008: `008_forecast_functions.sql`

**Objetivo:** Criar funções SQL para operações de forecast.

**Arquivo:** `supabase/migrations/008_forecast_functions.sql`

```sql
-- =============================================
-- CRS Brands – 008: Forecast Functions
-- Funções para cálculos e consultas de forecast
-- =============================================

-- ======= UP ========

-- 1. Função para obter vendas agregadas por SKU/Regional/Período
CREATE OR REPLACE FUNCTION get_vendas_agregadas(
  p_company_name TEXT,
  p_ano INTEGER,
  p_item TEXT DEFAULT NULL,
  p_regional TEXT DEFAULT NULL
)
RETURNS TABLE(
  item TEXT,
  regional TEXT,
  mes INTEGER,
  quantidade_total DECIMAL,
  valor_total DECIMAL
)
LANGUAGE sql
STABLE
AS $$
  SELECT
    item,
    regional,
    mes,
    SUM(quantidade) AS quantidade_total,
    SUM(valor) AS valor_total
  FROM public.historico_vendas
  WHERE company_name = p_company_name
    AND ano = p_ano
    AND (p_item IS NULL OR item = p_item)
    AND (p_regional IS NULL OR regional = p_regional)
  GROUP BY item, regional, mes
  ORDER BY item, regional, mes;
$$;

-- 2. Função para calcular sazonalidade por SKU/Regional
CREATE OR REPLACE FUNCTION calcular_sazonalidade(
  p_company_name TEXT,
  p_ano INTEGER,
  p_item TEXT,
  p_regional TEXT
)
RETURNS TABLE(
  mes INTEGER,
  proporcao DECIMAL
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_total DECIMAL;
BEGIN
  -- Calcular total anual
  SELECT SUM(quantidade) INTO v_total
  FROM public.historico_vendas
  WHERE company_name = p_company_name
    AND ano = p_ano
    AND item = p_item
    AND regional = p_regional;
  
  -- Se não houver vendas, retornar distribuição uniforme
  IF v_total IS NULL OR v_total = 0 THEN
    RETURN QUERY
    SELECT m::INTEGER, (1.0/12.0)::DECIMAL
    FROM generate_series(1, 12) m;
  ELSE
    -- Retornar proporção de cada mês
    RETURN QUERY
    SELECT
      mes::INTEGER,
      (COALESCE(SUM(quantidade), 0) / v_total)::DECIMAL AS proporcao
    FROM public.historico_vendas
    WHERE company_name = p_company_name
      AND ano = p_ano
      AND item = p_item
      AND regional = p_regional
    GROUP BY mes
    ORDER BY mes;
  END IF;
END;
$$;

-- 3. Função para listar previsões do usuário
CREATE OR REPLACE FUNCTION get_previsoes_usuario(p_user_id UUID)
RETURNS TABLE(
  id UUID,
  nome_cenario TEXT,
  descricao TEXT,
  ano_base INTEGER,
  ano_previsao INTEGER,
  status TEXT,
  created_at TIMESTAMPTZ,
  total_previsto DECIMAL,
  mape DECIMAL,
  wape DECIMAL
)
SECURITY DEFINER
SET search_path = public
LANGUAGE sql
STABLE
AS $$
  SELECT
    p.id,
    p.nome_cenario,
    p.descricao,
    p.ano_base,
    p.ano_previsao,
    p.status,
    p.created_at,
    k.total_previsto,
    k.mape,
    k.wape
  FROM public.previsoes p
  LEFT JOIN public.kpis_forecast k ON k.previsao_id = p.id
  WHERE p.user_id = p_user_id
  ORDER BY p.created_at DESC;
$$;

-- 4. Função para deletar previsão
CREATE OR REPLACE FUNCTION delete_previsao(p_previsao_id UUID, p_user_id UUID)
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  -- Verificar se a previsão pertence ao usuário
  SELECT COUNT(*) INTO v_count
  FROM public.previsoes
  WHERE id = p_previsao_id AND user_id = p_user_id;
  
  IF v_count = 0 THEN
    RETURN FALSE;
  END IF;
  
  -- Deletar (CASCADE vai deletar detalhes e KPIs)
  DELETE FROM public.previsoes WHERE id = p_previsao_id;
  
  RETURN TRUE;
END;
$$;

-- 5. Função para obter detalhes de uma previsão
CREATE OR REPLACE FUNCTION get_previsao_detalhes(
  p_previsao_id UUID,
  p_user_id UUID
)
RETURNS TABLE(
  item TEXT,
  regional TEXT,
  mes INTEGER,
  quantidade_prevista DECIMAL,
  orcamento_distribuido DECIMAL,
  vendas_ano_anterior DECIMAL,
  diferenca DECIMAL
)
SECURITY DEFINER
SET search_path = public
LANGUAGE sql
STABLE
AS $$
  SELECT
    pd.item,
    pd.regional,
    pd.mes,
    pd.quantidade_prevista,
    pd.orcamento_distribuido,
    pd.vendas_ano_anterior,
    pd.diferenca
  FROM public.previsoes_detalhadas pd
  INNER JOIN public.previsoes p ON p.id = pd.previsao_id
  WHERE pd.previsao_id = p_previsao_id
    AND p.user_id = p_user_id
  ORDER BY pd.item, pd.regional, pd.mes;
$$;

-- 6. Função para obter resumo por SKU
CREATE OR REPLACE FUNCTION get_resumo_por_sku(
  p_previsao_id UUID,
  p_user_id UUID
)
RETURNS TABLE(
  item TEXT,
  descricao TEXT,
  total_previsto DECIMAL,
  total_ano_anterior DECIMAL,
  crescimento_percentual DECIMAL
)
SECURITY DEFINER
SET search_path = public
LANGUAGE sql
STABLE
AS $$
  SELECT
    pd.item,
    MAX(hv.descricao) AS descricao,
    SUM(pd.quantidade_prevista) AS total_previsto,
    SUM(pd.vendas_ano_anterior) AS total_ano_anterior,
    CASE
      WHEN SUM(pd.vendas_ano_anterior) > 0 THEN
        ((SUM(pd.quantidade_prevista) - SUM(pd.vendas_ano_anterior)) / SUM(pd.vendas_ano_anterior) * 100)
      ELSE 0
    END AS crescimento_percentual
  FROM public.previsoes_detalhadas pd
  INNER JOIN public.previsoes p ON p.id = pd.previsao_id
  LEFT JOIN public.historico_vendas hv ON hv.item = pd.item AND hv.company_name = p.company_name
  WHERE pd.previsao_id = p_previsao_id
    AND p.user_id = p_user_id
  GROUP BY pd.item
  ORDER BY total_previsto DESC;
$$;

-- ======= DOWN ========
-- DROP FUNCTION IF EXISTS get_resumo_por_sku(UUID, UUID);
-- DROP FUNCTION IF EXISTS get_previsao_detalhes(UUID, UUID);
-- DROP FUNCTION IF EXISTS delete_previsao(UUID, UUID);
-- DROP FUNCTION IF EXISTS get_previsoes_usuario(UUID);
-- DROP FUNCTION IF EXISTS calcular_sazonalidade(TEXT, INTEGER, TEXT, TEXT);
-- DROP FUNCTION IF EXISTS get_vendas_agregadas(TEXT, INTEGER, TEXT, TEXT);
```

### 4.3 Migration 009: `009_forecast_policies.sql`

**Objetivo:** Configurar Row Level Security (RLS) para multi-tenancy.

**Arquivo:** `supabase/migrations/009_forecast_policies.sql`

```sql
-- =============================================
-- CRS Brands – 009: Forecast Policies (RLS)
-- Políticas de segurança para multi-tenancy
-- =============================================

-- ======= UP ========

-- 1. Habilitar RLS em todas as tabelas
ALTER TABLE public.historico_vendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orcamento ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.previsoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.previsoes_detalhadas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kpis_forecast ENABLE ROW LEVEL SECURITY;

-- 2. Policies para historico_vendas

-- Usuários podem ver apenas dados da sua empresa
CREATE POLICY "Usuarios veem historico da propria empresa"
ON public.historico_vendas
FOR SELECT
USING (
  company_name = (
    SELECT raw_user_meta_data->>'company_name'
    FROM auth.users
    WHERE id = auth.uid()
  )
);

-- Usuários podem inserir dados da sua empresa
CREATE POLICY "Usuarios inserem historico da propria empresa"
ON public.historico_vendas
FOR INSERT
WITH CHECK (
  user_id = auth.uid() AND
  company_name = (
    SELECT raw_user_meta_data->>'company_name'
    FROM auth.users
    WHERE id = auth.uid()
  )
);

-- Apenas admins podem deletar
CREATE POLICY "Apenas admins deletam historico"
ON public.historico_vendas
FOR DELETE
USING (
  (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'admin'
);

-- 3. Policies para orcamento

CREATE POLICY "Usuarios veem orcamento da propria empresa"
ON public.orcamento
FOR SELECT
USING (
  company_name = (
    SELECT raw_user_meta_data->>'company_name'
    FROM auth.users
    WHERE id = auth.uid()
  )
);

CREATE POLICY "Usuarios inserem orcamento da propria empresa"
ON public.orcamento
FOR INSERT
WITH CHECK (
  user_id = auth.uid() AND
  company_name = (
    SELECT raw_user_meta_data->>'company_name'
    FROM auth.users
    WHERE id = auth.uid()
  )
);

CREATE POLICY "Usuarios atualizam orcamento da propria empresa"
ON public.orcamento
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 4. Policies para previsoes

CREATE POLICY "Usuarios veem proprias previsoes"
ON public.previsoes
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Usuarios criam proprias previsoes"
ON public.previsoes
FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Usuarios atualizam proprias previsoes"
ON public.previsoes
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Usuarios deletam proprias previsoes"
ON public.previsoes
FOR DELETE
USING (user_id = auth.uid());

-- 5. Policies para previsoes_detalhadas

CREATE POLICY "Usuarios veem detalhes de proprias previsoes"
ON public.previsoes_detalhadas
FOR SELECT
USING (
  previsao_id IN (
    SELECT id FROM public.previsoes WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Usuarios inserem detalhes de proprias previsoes"
ON public.previsoes_detalhadas
FOR INSERT
WITH CHECK (
  previsao_id IN (
    SELECT id FROM public.previsoes WHERE user_id = auth.uid()
  )
);

-- 6. Policies para kpis_forecast

CREATE POLICY "Usuarios veem KPIs de proprias previsoes"
ON public.kpis_forecast
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Usuarios inserem KPIs de proprias previsoes"
ON public.kpis_forecast
FOR INSERT
WITH CHECK (user_id = auth.uid());

-- ======= DOWN ========
-- DROP POLICY IF EXISTS "Usuarios inserem KPIs de proprias previsoes" ON public.kpis_forecast;
-- DROP POLICY IF EXISTS "Usuarios veem KPIs de proprias previsoes" ON public.kpis_forecast;
-- DROP POLICY IF EXISTS "Usuarios inserem detalhes de proprias previsoes" ON public.previsoes_detalhadas;
-- DROP POLICY IF EXISTS "Usuarios veem detalhes de proprias previsoes" ON public.previsoes_detalhadas;
-- DROP POLICY IF EXISTS "Usuarios deletam proprias previsoes" ON public.previsoes;
-- DROP POLICY IF EXISTS "Usuarios atualizam proprias previsoes" ON public.previsoes;
-- DROP POLICY IF EXISTS "Usuarios criam proprias previsoes" ON public.previsoes;
-- DROP POLICY IF EXISTS "Usuarios veem proprias previsoes" ON public.previsoes;
-- DROP POLICY IF EXISTS "Usuarios atualizam orcamento da propria empresa" ON public.orcamento;
-- DROP POLICY IF EXISTS "Usuarios inserem orcamento da propria empresa" ON public.orcamento;
-- DROP POLICY IF EXISTS "Usuarios veem orcamento da propria empresa" ON public.orcamento;
-- DROP POLICY IF EXISTS "Apenas admins deletam historico" ON public.historico_vendas;
-- DROP POLICY IF EXISTS "Usuarios inserem historico da propria empresa" ON public.historico_vendas;
-- DROP POLICY IF EXISTS "Usuarios veem historico da propria empresa" ON public.historico_vendas;
-- 
-- ALTER TABLE public.kpis_forecast DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.previsoes_detalhadas DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.previsoes DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.orcamento DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.historico_vendas DISABLE ROW LEVEL SECURITY;
```

---

## 5. WORKFLOWS N8N

### 5.1 Workflow: `CRS-Forecast-Upload-Historico.json`

**Objetivo:** Receber upload de planilha Excel e importar dados históricos.

**Endpoint:** `POST /webhook/crs-forecast/upload-historico`

**Input:**
```json
{
  "file": "<base64_encoded_excel>",
  "filename": "historico_vendas_2025.xlsx",
  "user_id": "uuid-do-usuario",
  "company_name": "CRS Brands"
}
```

**Fluxo:**

```
1. Webhook Trigger
   ├─ Method: POST
   ├─ Path: /webhook/crs-forecast/upload-historico
   └─ Authentication: Bearer Token (Supabase JWT)

2. Validate Input
   ├─ Verificar se file existe
   ├─ Verificar se user_id e company_name existem
   └─ Se inválido → Return Error 400

3. Decode Base64 File
   └─ Code Node (JavaScript)

4. Parse Excel
   ├─ Code Node (Python)
   ├─ Usa: openpyxl, pandas
   ├─ Lê aba "Base_Histórica_de_Vendas"
   └─ Valida estrutura (colunas obrigatórias)

5. Transform Data
   ├─ Code Node (Python)
   ├─ Gera upload_batch_id (UUID)
   ├─ Adiciona user_id e company_name a cada linha
   └─ Formata dados para SQL

6. Bulk Insert Supabase
   ├─ HTTP Request Node
   ├─ POST /rest/v1/historico_vendas
   ├─ Headers: apikey, Authorization
   └─ Body: array de registros

7. Return Response
   └─ {
        "success": true,
        "batch_id": "uuid",
        "records_imported": 1500,
        "anos_importados": [2023, 2024, 2025]
      }
```

**Code Node - Parse Excel (Python):**

```python
import openpyxl
import pandas as pd
import base64
import json
from io import BytesIO

# Input
file_base64 = items[0].json['file']
filename = items[0].json['filename']

# Decode
file_bytes = base64.b64decode(file_base64)
file_io = BytesIO(file_bytes)

# Ler Excel
df = pd.read_excel(file_io, sheet_name='Base_Histórica_de_Vendas')

# Validar colunas obrigatórias
required_columns = [
    'Ano', 'Mês', 'Item', 'Descrição', 'Regional', 
    'Nome Regional', 'Tipo de Mercado', 'Quantidade'
]

missing = [col for col in required_columns if col not in df.columns]
if missing:
    return [{'json': {'error': f'Colunas faltando: {missing}'}}]

# Converter para lista de dicts
records = df.to_dict('records')

return [{'json': {'records': records, 'count': len(records)}}]
```

**Code Node - Transform Data (Python):**

```python
import uuid

records = items[0].json['records']
user_id = items[0].json['user_id']
company_name = items[0].json['company_name']
batch_id = str(uuid.uuid4())

output_records = []

for record in records:
    output_records.append({
        'user_id': user_id,
        'company_name': company_name,
        'ano': int(record['Ano']),
        'mes': int(record['Mês']),
        'item': str(record['Item']),
        'descricao': str(record['Descrição']),
        'regional': str(record['Regional']),
        'nome_regional': str(record['Nome Regional']),
        'tipo_mercado': str(record['Tipo de Mercado']),
        'familia_totvs': str(record.get('Família Totvs', '')),
        'familia_comercial': str(record.get('Família Comercial', '')),
        'familia_plan_i': str(record.get('Família Plan I', '')),
        'familia_plan_ii': str(record.get('Família Plan II', '')),
        'quantidade': float(record['Quantidade']),
        'valor': float(record.get('Valor', 0)),
        'upload_batch_id': batch_id
    })

return [{'json': {'records': output_records, 'batch_id': batch_id}}]
```

### 5.2 Workflow: `CRS-Forecast-Calcular-Previsao.json`

**Objetivo:** Calcular previsão de 12 meses usando a metodologia da planilha.

**Endpoint:** `POST /webhook/crs-forecast/calcular-previsao`

**Input:**
```json
{
  "user_id": "uuid",
  "company_name": "CRS Brands",
  "nome_cenario": "Cenário Realista 2026",
  "descricao": "Previsão baseada em histórico 2025",
  "ano_base": 2025,
  "ano_previsao": 2026
}
```

**Fluxo:**

```
1. Webhook Trigger

2. Create Previsao Record
   ├─ INSERT INTO previsoes
   ├─ status = 'calculando'
   └─ Retorna previsao_id

3. Fetch Histórico 2025
   ├─ Query: get_vendas_agregadas(company_name, 2025)
   └─ Retorna vendas por item/regional/mes

4. Fetch Orçamento 2026
   ├─ SELECT * FROM orcamento WHERE ano = 2026
   └─ Retorna orcamento total por item/regional

5. Calculate Forecast (Code Node - Python)
   ├─ Para cada item/regional:
   │  ├─ Calcular sazonalidade de 2025
   │  ├─ Distribuir orçamento 2026 pela sazonalidade
   │  └─ Calcular: forecast = orcamento_distribuido - vendas_2025
   └─ Gerar array de previsoes_detalhadas

6. Bulk Insert Previsoes Detalhadas
   └─ INSERT INTO previsoes_detalhadas

7. Calculate KPIs (Code Node - Python)
   ├─ MAPE, WAPE, Forecast Accuracy
   └─ Total previsto

8. Insert KPIs
   └─ INSERT INTO kpis_forecast

9. Update Previsao Status
   ├─ UPDATE previsoes
   └─ SET status = 'concluido'

10. Return Response
    └─ {
         "success": true,
         "previsao_id": "uuid",
         "total_previsto": 150000,
         "kpis": {...}
       }
```

**Code Node - Calculate Forecast (Python):**

```python
import pandas as pd

# Inputs
historico = items[0].json['historico']  # Lista de vendas 2025
orcamento = items[0].json['orcamento']  # Lista de orçamentos 2026
previsao_id = items[0].json['previsao_id']

# Converter para DataFrames
df_hist = pd.DataFrame(historico)
df_orc = pd.DataFrame(orcamento)

# Agrupar histórico por item/regional
grouped = df_hist.groupby(['item', 'regional'])

previsoes_detalhadas = []

for (item, regional), group in grouped:
    # Buscar orçamento
    orc_row = df_orc[(df_orc['item'] == item) & (df_orc['regional'] == regional)]
    
    if orc_row.empty:
        continue  # Pular se não houver orçamento
    
    orcamento_total = float(orc_row.iloc[0]['orcamento_total'])
    
    # Calcular total anual de 2025
    total_2025 = group['quantidade_total'].sum()
    
    # Para cada mês
    for mes in range(1, 13):
        mes_data = group[group['mes'] == mes]
        
        if total_2025 > 0 and not mes_data.empty:
            # Calcular proporção do mês
            vendas_mes_2025 = float(mes_data['quantidade_total'].iloc[0])
            proporcao = vendas_mes_2025 / total_2025
        else:
            # Distribuição uniforme
            vendas_mes_2025 = 0
            proporcao = 1.0 / 12.0
        
        # Distribuir orçamento pela sazonalidade
        orcamento_distribuido = orcamento_total * proporcao
        
        # Calcular diferença (forecast)
        quantidade_prevista = orcamento_distribuido
        diferenca = orcamento_distribuido - vendas_mes_2025
        
        previsoes_detalhadas.append({
            'previsao_id': previsao_id,
            'item': item,
            'regional': regional,
            'mes': mes,
            'quantidade_prevista': round(quantidade_prevista, 2),
            'orcamento_distribuido': round(orcamento_distribuido, 2),
            'vendas_ano_anterior': round(vendas_mes_2025, 2),
            'diferenca': round(diferenca, 2)
        })

return [{'json': {'previsoes_detalhadas': previsoes_detalhadas}}]
```

**Code Node - Calculate KPIs (Python):**

```python
import pandas as pd
import numpy as np

previsoes = items[0].json['previsoes_detalhadas']
df = pd.DataFrame(previsoes)

# Total previsto
total_previsto = df['quantidade_prevista'].sum()
total_ano_anterior = df['vendas_ano_anterior'].sum()

# MAPE (Mean Absolute Percentage Error)
# Só calcular se houver valores reais > 0
df_nonzero = df[df['vendas_ano_anterior'] > 0]
if len(df_nonzero) > 0:
    mape = (np.abs((df_nonzero['quantidade_prevista'] - df_nonzero['vendas_ano_anterior']) / df_nonzero['vendas_ano_anterior'])).mean()
else:
    mape = None

# WAPE (Weighted Absolute Percentage Error)
if total_ano_anterior > 0:
    wape = np.abs(df['quantidade_prevista'] - df['vendas_ano_anterior']).sum() / total_ano_anterior
else:
    wape = None

# Forecast Accuracy
if wape is not None:
    forecast_accuracy = 1 - wape
else:
    forecast_accuracy = None

# Erro total
erro_total = np.abs(total_previsto - total_ano_anterior)

kpis = {
    'mape': round(mape, 4) if mape is not None else None,
    'wape': round(wape, 4) if wape is not None else None,
    'forecast_accuracy': round(forecast_accuracy, 4) if forecast_accuracy is not None else None,
    'total_previsto': round(total_previsto, 2),
    'total_realizado': round(total_ano_anterior, 2),
    'erro_total': round(erro_total, 2)
}

return [{'json': {'kpis': kpis}}]
```

### 5.3 Workflow: `CRS-Forecast-API-Dashboard.json`

**Objetivo:** API para retornar dados agregados para o dashboard.

**Endpoints:**

1. `GET /webhook/crs-forecast/dashboard/resumo?user_id=uuid`
2. `GET /webhook/crs-forecast/dashboard/por-regional?previsao_id=uuid&user_id=uuid`
3. `GET /webhook/crs-forecast/dashboard/por-mes?previsao_id=uuid&user_id=uuid`
4. `GET /webhook/crs-forecast/dashboard/top-skus?previsao_id=uuid&user_id=uuid&limit=10`

### 5.4 Workflow: `CRS-Forecast-GET-Historicos.json`

**Objetivo:** Listar batches de histórico importados.

**Endpoint:** `GET /webhook/crs-forecast/historicos?user_id=uuid`

**Response:**
```json
{
  "batches": [
    {
      "batch_id": "uuid",
      "records_count": 1500,
      "anos": [2023, 2024, 2025],
      "uploaded_at": "2026-06-15T10:30:00Z"
    }
  ]
}
```

### 5.5 Workflow: `CRS-Forecast-GET-Previsoes.json`

**Objetivo:** Listar previsões do usuário.

**Endpoint:** `GET /webhook/crs-forecast/previsoes?user_id=uuid`

**Response:**
```json
{
  "previsoes": [
    {
      "id": "uuid",
      "nome_cenario": "Cenário Otimista",
      "ano_base": 2025,
      "ano_previsao": 2026,
      "status": "concluido",
      "created_at": "2026-06-16T08:00:00Z",
      "kpis": {
        "mape": 0.1234,
        "wape": 0.0567,
        "total_previsto": 150000
      }
    }
  ]
}
```

### 5.6 Workflow: `CRS-Forecast-DELETE-Previsao.json`

**Objetivo:** Deletar uma previsão.

**Endpoint:** `DELETE /webhook/crs-forecast/previsoes/:id?user_id=uuid`

### 5.7 Workflow: `CRS-Forecast-Export-Excel.json`

**Objetivo:** Exportar previsão para Excel.

**Endpoint:** `GET /webhook/crs-forecast/export/:previsao_id?user_id=uuid`

**Response:** Arquivo Excel em base64

---

## 6. ENDPOINTS DA API

### 6.1 Resumo de Endpoints

| Método | Endpoint | Descrição | Auth |
|--------|----------|-----------|------|
| POST | `/webhook/crs-forecast/upload-historico` | Upload de histórico | Bearer |
| POST | `/webhook/crs-forecast/upload-orcamento` | Upload de orçamento | Bearer |
| POST | `/webhook/crs-forecast/calcular-previsao` | Calcular forecast | Bearer |
| GET | `/webhook/crs-forecast/historicos` | Listar históricos | Bearer |
| GET | `/webhook/crs-forecast/previsoes` | Listar previsões | Bearer |
| GET | `/webhook/crs-forecast/previsoes/:id` | Detalhes da previsão | Bearer |
| DELETE | `/webhook/crs-forecast/previsoes/:id` | Deletar previsão | Bearer |
| GET | `/webhook/crs-forecast/dashboard/resumo` | Dashboard resumo | Bearer |
| GET | `/webhook/crs-forecast/dashboard/por-regional` | Agregação regional | Bearer |
| GET | `/webhook/crs-forecast/dashboard/por-mes` | Agregação mensal | Bearer |
| GET | `/webhook/crs-forecast/dashboard/top-skus` | Top SKUs | Bearer |
| GET | `/webhook/crs-forecast/export/:id` | Exportar Excel | Bearer |

### 6.2 Autenticação

Todos os endpoints usam **Bearer Token** (Supabase JWT):

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

O `user_id` e `company_name` são extraídos do JWT.

---

## 7. FRONT-END

### 7.1 Estrutura do Arquivo `forecast.html`

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <title>Forecast CRS Brands</title>
  <!-- Mesma base do front.html do Imagens Bahia -->
  <!-- Adaptar cores para identidade CRS Brands -->
</head>
<body>
  <div class="app-container">
    <!-- Header -->
    <header class="app-header">
      <div class="logo">CRS BRANDS - Forecast</div>
      <div class="user-info">
        <span id="userName"></span>
        <button id="logoutBtn">Sair</button>
      </div>
    </header>

    <!-- Sidebar -->
    <aside class="sidebar">
      <nav>
        <button data-page="dashboard">Dashboard</button>
        <button data-page="upload">Upload Histórico</button>
        <button data-page="orcamento">Upload Orçamento</button>
        <button data-page="previsoes">Previsões</button>
        <button data-page="calcular">Calcular Forecast</button>
        <button data-page="usuarios" id="usersNavBtn">Usuários</button>
      </nav>
    </aside>

    <!-- Main Content -->
    <main class="main-content">
      <!-- Dashboard -->
      <section id="dashboardSection">
        <h1>Dashboard de Forecast</h1>
        <!-- KPIs -->
        <!-- Gráficos -->
        <!-- Tabelas resumo -->
      </section>

      <!-- Upload Histórico -->
      <section id="uploadSection">
        <h1>Upload Histórico de Vendas</h1>
        <input type="file" id="uploadHistorico" accept=".xlsx">
        <button id="btnUploadHistorico">Importar</button>
      </section>

      <!-- Upload Orçamento -->
      <section id="orcamentoSection">
        <h1>Upload Orçamento</h1>
        <input type="file" id="uploadOrcamento" accept=".xlsx">
        <button id="btnUploadOrcamento">Importar</button>
      </section>

      <!-- Lista de Previsões -->
      <section id="previsoesSection">
        <h1>Previsões Criadas</h1>
        <table id="tblPrevisoes">
          <!-- Lista de previsões -->
        </table>
      </section>

      <!-- Calcular Forecast -->
      <section id="calcularSection">
        <h1>Calcular Nova Previsão</h1>
        <form id="formCalcular">
          <input type="text" name="nome_cenario" placeholder="Nome do Cenário">
          <select name="ano_base">
            <option value="2025">2025</option>
          </select>
          <select name="ano_previsao">
            <option value="2026">2026</option>
          </select>
          <button type="submit">Calcular</button>
        </form>
      </section>

      <!-- Gestão de Usuários (Admin) -->
      <section id="usersSection">
        <!-- Reutilizar do Imagens Bahia -->
      </section>
    </main>
  </div>

  <script>
    // Lógica de autenticação (Supabase)
    // Navegação entre páginas
    // Chamadas aos endpoints n8n
    // Renderização de gráficos (Chart.js)
  </script>
</body>
</html>
```

### 7.2 Bibliotecas JavaScript

- **Supabase.js** - Autenticação
- **Chart.js** - Gráficos
- **XLSX.js** - Leitura local de Excel (preview)
- **Lucide** - Ícones

---

## 8. CASOS DE USO

### 8.1 UC-01: Upload de Histórico de Vendas

**Ator:** Usuário autenticado

**Fluxo:**
1. Usuário acessa página "Upload Histórico"
2. Seleciona arquivo Excel (.xlsx)
3. Clica em "Importar"
4. Sistema valida estrutura da planilha
5. Sistema importa dados para `historico_vendas`
6. Usuário recebe confirmação com quantidade de registros importados

**Resultado:** Dados históricos disponíveis para cálculo de forecast

### 8.2 UC-02: Calcular Previsão de 12 Meses

**Ator:** Usuário autenticado

**Pré-condição:** Histórico de 2025 e orçamento de 2026 importados

**Fluxo:**
1. Usuário acessa "Calcular Forecast"
2. Preenche nome do cenário e descrição
3. Seleciona ano base (2025) e ano previsão (2026)
4. Clica em "Calcular"
5. Sistema aplica metodologia:
   - Busca vendas de 2025
   - Calcula sazonalidade
   - Distribui orçamento 2026
   - Calcula diferença (forecast)
6. Sistema calcula KPIs (MAPE, WAPE, Accuracy)
7. Sistema salva previsão com status "concluído"
8. Usuário recebe ID da previsão

**Resultado:** Previsão de 12 meses disponível no dashboard

### 8.3 UC-03: Visualizar Dashboard

**Ator:** Usuário autenticado

**Fluxo:**
1. Usuário acessa "Dashboard"
2. Seleciona uma previsão da lista
3. Sistema exibe:
   - KPIs principais (MAPE, WAPE, Total Previsto)
   - Gráfico de barras: Previsto vs Ano Anterior por Mês
   - Gráfico de pizza: Top 10 SKUs
   - Tabela: Previsão por Regional
   - Gráfico de linha: Tendência mensal

**Resultado:** Visualização consolidada da previsão

### 8.4 UC-04: Exportar Previsão para Excel

**Ator:** Usuário autenticado

**Fluxo:**
1. Usuário seleciona uma previsão
2. Clica em "Exportar Excel"
3. Sistema gera planilha com:
   - Aba "Resumo": KPIs e totais
   - Aba "Por SKU": Detalhamento por produto
   - Aba "Por Regional": Detalhamento por regional
   - Aba "Mensal": Valores mês a mês
4. Usuário faz download do arquivo

**Resultado:** Arquivo Excel com forecast completo

---

## 9. CHECKLIST DE IMPLEMENTAÇÃO

### 9.1 Banco de Dados

- [ ] Executar migration `007_forecast_tables.sql`
- [ ] Executar migration `008_forecast_functions.sql`
- [ ] Executar migration `009_forecast_policies.sql`
- [ ] Testar inserção manual em `historico_vendas`
- [ ] Testar funções SQL criadas
- [ ] Validar RLS policies

### 9.2 Workflows n8n

- [ ] Importar `CRS-Forecast-Upload-Historico.json`
- [ ] Importar `CRS-Forecast-Calcular-Previsao.json`
- [ ] Importar `CRS-Forecast-API-Dashboard.json`
- [ ] Importar `CRS-Forecast-GET-Historicos.json`
- [ ] Importar `CRS-Forecast-GET-Previsoes.json`
- [ ] Importar `CRS-Forecast-DELETE-Previsao.json`
- [ ] Importar `CRS-Forecast-Export-Excel.json`
- [ ] Configurar credenciais Supabase em cada workflow
- [ ] Testar cada endpoint individualmente
- [ ] Testar fluxo completo (upload → cálculo → dashboard)

### 9.3 Front-end

- [ ] Criar arquivo `forecast.html`
- [ ] Implementar autenticação com Supabase
- [ ] Implementar página de Upload Histórico
- [ ] Implementar página de Upload Orçamento
- [ ] Implementar página de Cálculo de Previsão
- [ ] Implementar Dashboard com gráficos
- [ ] Implementar lista de Previsões
- [ ] Implementar exportação para Excel
- [ ] Reutilizar página de Gestão de Usuários
- [ ] Testar responsividade
- [ ] Ajustar identidade visual CRS Brands

### 9.4 Testes

- [ ] Testar upload de planilha válida
- [ ] Testar upload de planilha inválida (estrutura errada)
- [ ] Testar cálculo de forecast com diferentes cenários
- [ ] Testar multi-tenancy (usuários de empresas diferentes)
- [ ] Testar permissões (admin vs usuário comum)
- [ ] Testar cálculo de KPIs (MAPE, WAPE)
- [ ] Testar exportação para Excel
- [ ] Testar performance com 10.000+ registros

### 9.5 Documentação

- [ ] Atualizar `README.md` do projeto
- [ ] Documentar endpoints da API
- [ ] Criar guia de uso para usuários finais
- [ ] Documentar metodologia de cálculo
- [ ] Criar troubleshooting guide

---

## 10. REFERÊNCIAS

- **Metodologia de Forecast:** `docs/metodologia/METODOLOGIA_FORECAST.md`
- **Planilha Original:** `6- Cenário de Demanda 15.06.2026.xlsx`
- **Sistema Atual (Imagens Bahia):** `README.md` (para referência de estrutura)

---

## 11. NOTAS FINAIS PARA O AGENTE IMPLEMENTADOR

### 11.1 Prioridades

1. **Banco de dados primeiro** - Execute as migrations e valide
2. **Workflows básicos** - Upload e cálculo são críticos
3. **API Dashboard** - Para visualização dos dados
4. **Front-end** - Por último, pode reutilizar estrutura do Imagens Bahia

### 11.2 Pontos de Atenção

⚠️ **Multi-tenancy** - Sempre filtrar por `company_name`
⚠️ **Validação de Excel** - Planilhas podem ter formatos diferentes
⚠️ **Performance** - Criar índices nas colunas de filtro
⚠️ **Sazonalidade zero** - Se não houver vendas em 2025, distribuir uniformemente
⚠️ **Divisão por zero** - Cuidado ao calcular MAPE/WAPE

### 11.3 Otimizações Futuras

🚀 Implementar cache de cálculos
🚀 Adicionar fila de processamento para grandes volumes
🚀 Implementar versionamento de previsões
🚀 Adicionar ajustes manuais de forecast
🚀 Implementar machine learning para melhorar precisão

---

**FIM DA ESPECIFICAÇÃO**

**Versão:** 1.0  
**Data:** 16/06/2026  
**Autor:** Claude (Agente IA Especialista)  
**Para:** Agente Implementador (mais barato 😄)

---

**BOA SORTE NA IMPLEMENTAÇÃO! 🚀📊**
