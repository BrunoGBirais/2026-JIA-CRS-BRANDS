# Documentação de Arquitetura e Migrations: Sistema S&OP (Forecast de Demanda)

Este documento serve como especificação técnica para a geração das *migrations* no PostgreSQL (Supabase). O modelo adota uma arquitetura em *Star Schema* otimizada para rotinas de ETL automatizadas e cálculos analíticos complexos.

---

## 1. Tabelas de Dimensão (Master Data)

Estas tabelas armazenam os cadastros estáticos e as hierarquias de negócio.

### Tabela: `crs_brands_regioes`
Armazena o mapeamento das regionais de venda.
* **`id_regional`** (`VARCHAR(50)`): Chave Primária (PK). Ex: 'R01', 'R10'.
* **`nome`** (`VARCHAR(255)`): Nome da regional. Ex: 'R01 - SP CAPITAL'.
* **`informacao_demanda`** (`VARCHAR(255)`): Responsável pela demanda.
* **`gr_vendas`** (`VARCHAR(255)`): Gerente de vendas responsável.

### Tabela: `crs_brands_produtos`
Armazena a hierarquia do portfólio de produtos.
* **`id_item`** (`VARCHAR(50)`): Chave Primária (PK). Código do SKU.
* **`descricao`** (`VARCHAR(255)`): Nome do produto.
* **`tipo_mercado`** (`VARCHAR(100)`): Ex: 'MERCADO INTERNO', 'MERCADO EXTERNO'.
* **`familia_totvs`** (`VARCHAR(150)`): Categoria nível 1.
* **`familia_comercial`** (`VARCHAR(150)`): Categoria nível 2.
* **`familia_plan_i`** (`VARCHAR(150)`): Categoria de planejamento 1.
* **`familia_plan_ii`** (`VARCHAR(150)`): Categoria de planejamento 2.
* **`curva_abc_est`** (`CHAR(1)`): Classificação ABC para estoque (A, B ou C).
* **`curva_abc_vendas`** (`CHAR(1)`): Classificação ABC para vendas (A, B ou C).
* **`numero`** (`int`)

---

### Tabela: `crs_brands_de_para`
Mapeia o ciclo de vida dos SKUs para unificação de histórico de vendas de produtos descontinuados.
* **`id_item_antigo`** (`VARCHAR(50)`): Chave Primária (PK) e Chave Estrangeira (FK) referenciando `crs_brands_produtos(id_item)`.
* **`id_item_novo`** (`VARCHAR(50)`): Chave Estrangeira (FK) referenciando `crs_brands_produtos(id_item)`.
* **`data_alteracao`** (`TIMESTAMP`): Registro de quando a transição ocorreu. Padrão `NOW()`.

---

## 3. Tabela Fato (Transacional)

Unifica todos os eventos quantitativos (passado, metas e futuro) em uma estrutura verticalizada, ideal para consultas analíticas via SQL (Window Functions) e consumo em Dashboards (Power BI/Metabase).

### Tabela: `crs_brands_fatos_vendas`
* **`data_referencia`** (`DATE`): Primeiro dia do mês/ano da transação. Ex: '2026-01-01'.
* **`id_item`** (`VARCHAR(50)`): FK referenciando `crs_brands_produtos(id_item)`.
* **`id_regional`** (`VARCHAR(50)`): FK referenciando `crs_brands_regioes(id_regional)`.
* **`tipo_cenario`** (`VARCHAR(50)`): Define a natureza do dado. Valores restritos (Enum ou Check constraint): `'REALIZADO'`, `'ORCADO'`, `'DEMANDA_ESTATISTICA'`, `'DEMANDA_FINAL'`.
* **`volume_orçado`** (`DECIMAL(15,2)`): Quantidade registrada.
* **`volume_realizado`** (`DECIMAL(15,2)`): Quantidade feita de fato.
* **`volume_demmanda`** (`DECIMAL(15,2)`): Quantidade demandada.

**Índices e Restrições (Constraints):**
* **Primary Key Composta:** `(data_referencia, id_item, id_regional, tipo_cenario)`. Isso garante que não haverá duplicidade de cenários para o mesmo produto, região e mês.
* Criar índice (Index) na coluna `data_referencia` para otimizar filtros temporais.
* Criar índice (Index) na coluna `tipo_cenario` para otimizar agregações de Dashboard.

---

## Instruções para o Agente de Código (Prompt System)
1. Gere o script SQL de migration criando os tipos `ENUM` necessários para `tipo_cenario` antes da criação da tabela fato.
2. Respeite estritamente os relacionamentos de Chaves Estrangeiras (Foreign Keys) na ordem de criação (Regiões e Produtos primeiro, Fatos por último).
3. Adicione `ON DELETE RESTRICT` nas Foreign Keys da tabela Fato para evitar perda acidental de histórico de vendas se um produto for deletado da dimensão.
4. Para a tabela `crs_brands_de_para`, configure gatilhos (triggers) ou regras para evitar loops de mapeamento (ex: A -> B -> A).
