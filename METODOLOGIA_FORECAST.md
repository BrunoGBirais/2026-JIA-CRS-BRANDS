# METODOLOGIA DE CÁLCULO DE FORECAST - CRS BRANDS
## Análise da Planilha "6- Cenário de Demanda 15.06.2026"

---

## 📊 ESTRUTURA GERAL DA PLANILHA

### Abas Principais:
1. **DASHBOARD** - Visualizações e indicadores consolidados
2. **Relatório** - Métricas de performance (MAPE, WAPE, Forecast Accuracy)
3. **Base_Histórica_de_Vendas** - Dados brutos de vendas históricas
4. **Metodologia** - Cálculos e projeções (ABA PRINCIPAL)
5. **Orçamento_2026** - Planejamento orçamentário
6. **Orçamento_2025** - Orçamento ano anterior
7. **Demanda** - Análise de demanda
8. **Base_Geral** - Base de dados consolidada
9. **Cadastros** - Cadastro de produtos/regionais
10. **DE_PARA** - Tabela de relacionamentos

---

## 🎯 METODOLOGIA DE FORECAST (Aba "Metodologia")

### 1. ESTRUTURA DE DADOS

A planilha organiza os dados por:
- **SKU (Item)** - Código do produto
- **Descrição** - Nome do produto
- **Regional** - Código da regional (R01, R02, R03, etc.)
- **Nome Regional** - Nome completo (SP CAPITAL, SP INTERIOR, SUL, LESTE, NE, NO, CO, KA e AS, OUTROS)
- **Tipo de Mercado** - Mercado Interno / Exportação
- **Famílias** - Classificação por família (Totvs, Comercial, Plan I, Plan II)

### 2. DADOS HISTÓRICOS (Colunas 11-38)

#### **Ano 2023 (Colunas 11-24)**
- **Coluna 11**: Total 2023 - `=SUM(M6:X6)` - Soma de todos os meses
- **Coluna 12**: Média 2023 - `=IFERROR(AVERAGE(M6:X6),0)` - Média mensal
- **Colunas 13-24**: Meses 1 a 12 de 2023

**Fórmula dos meses históricos:**
```excel
=SUMIFS(
    Base_Histórica_de_Vendas!$M:$M,           // Soma a coluna de valores
    Base_Histórica_de_Vendas!$J:$J, $B6,       // Filtra por Item
    Base_Histórica_de_Vendas!$A:$A, $K$1,      // Filtra por Ano (2023)
    Base_Histórica_de_Vendas!$B:$B, M$5,       // Filtra por Mês
    Base_Histórica_de_Vendas!$C:$C, $D6        // Filtra por Regional
)
```

**Como funciona:**
- Busca na aba "Base_Histórica_de_Vendas"
- Filtra por: **Item + Ano + Mês + Regional**
- Retorna o volume de vendas para aquela combinação
- Se não houver dados, retorna 0

#### **Ano 2024 (Colunas 25-38)**
- Mesma lógica do 2023
- Referência de ano muda para $Y$1 (2024)

#### **Ano 2025 e 2026**
- Continua a mesma estrutura para anos subsequentes

---

## 📈 CÁLCULO DE FORECAST FUTURO

### 3. DIFERENÇAS S&OP vs REALIZADO (Colunas 131-139)

Essas colunas calculam a **diferença entre o orçado (S&OP) e o realizado**:

```excel
Coluna 131: =CW6-BW6  // Mês 1: Forecast - Real
Coluna 132: =CX6-BX6  // Mês 2: Forecast - Real
...
```

**Agregações:**
- **Coluna 138**: Total das diferenças - `=SUM(EJ6:EM6)`
- **Coluna 139**: Média das diferenças - `=IFERROR(AVERAGE(EJ6:EN6),0)`

### 4. PROJEÇÕES FUTURAS (Colunas 140-151)

As últimas 12 colunas representam os **12 meses futuros projetados**:

```excel
Coluna 140 (Mês 1): =CQ6-BC6  // Ajuste baseado em padrões
Coluna 141 (Mês 2): =CR6-BD6
Coluna 142 (Mês 3): =CS6-BE6
...
```

**Interpretação:**
- Compara colunas de diferentes períodos
- Calcula ajustes baseados em desvios históricos
- Aplica correções sazonais e tendências

---

## 📊 INDICADORES DE PERFORMANCE (Aba "Relatório")

### Métricas Principais:

#### **1. MAPE (Mean Absolute Percentage Error)**
- **Meta**: 0.2 (20%)
- **Resultado atual**: 1.224586 (122.46%)
- **Desvio**: +1.024586
- **Interpretação**: Erro médio percentual absoluto - quanto MENOR, melhor

#### **2. WAPE (Weighted Absolute Percentage Error)**
- **Meta**: 0.15 (15%)
- **Resultado atual**: 0.466706 (46.67%)
- **Desvio**: +0.316706
- **Interpretação**: Erro ponderado pelo volume - mais preciso que MAPE

#### **3. Forecast Accuracy (Acurácia)**
- **Meta**: 0.8 (80%)
- **Resultado atual**: Não calculado (NaN)
- **Desvio**: -0.8
- **Interpretação**: Percentual de acerto da previsão

---

## 🔄 FLUXO DA METODOLOGIA

```
┌─────────────────────────────────────┐
│ 1. BASE HISTÓRICA DE VENDAS         │
│    - Dados reais de vendas por SKU  │
│    - Segmentado por Regional/Mês    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 2. AGREGAÇÃO NA ABA "METODOLOGIA"   │
│    - SUMIFS por Item+Regional+Mês   │
│    - Cálculo de Totais e Médias     │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 3. COMPARAÇÃO S&OP vs REALIZADO     │
│    - Diferenças entre orçado/real   │
│    - Identificação de desvios       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 4. PROJEÇÃO FUTURA (12 meses)       │
│    - Ajustes baseados em histórico  │
│    - Correções de sazonalidade      │
│    - Aplicação de tendências        │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 5. CÁLCULO DE INDICADORES           │
│    - MAPE, WAPE, Forecast Accuracy  │
│    - Monitoramento de performance   │
└─────────────────────────────────────┘
```

---

## 💡 PONTOS-CHAVE DA METODOLOGIA

### ✅ **Granularidade**
- Previsão por **SKU + Regional + Mês**
- Permite análises detalhadas e agregações

### ✅ **Histórico Robusto**
- Utiliza dados de 2023, 2024, 2025
- Mínimo de 24-36 meses de histórico

### ✅ **Comparação S&OP**
- Confronta orçamento planejado vs realizado
- Identifica desvios para correção

### ✅ **Ajustes Dinâmicos**
- Fórmulas calculam diferenças entre períodos
- Aplicam correções automáticas baseadas em padrões

### ⚠️ **Pontos de Atenção**
- MAPE atual (122%) está **MUITO acima** da meta (20%)
- WAPE (47%) está **acima** da meta (15%)
- Indica que o modelo precisa de **ajustes significativos**
- Possíveis causas: sazonalidade não capturada, mudanças de mercado, lançamentos de produtos

---

## 🎓 COMO INTERPRETAR OS RESULTADOS

### **Exemplo prático (Item 1211 - OLD CESAR 88, Regional R01):**

```
Histórico 2023:
- Total anual: 3.348 unidades
- Média mensal: 279 unidades
- Jan/2023: 121 un | Fev/2023: 106 un | Mar/2023: 41 un

Forecast (últimas colunas):
- Mês 1: 1.188,70 un
- Mês 2: 774,21 un
- Mês 3: 1.379,60 un
```

**Observações:**
- Há variação sazonal significativa
- Alguns meses têm valores negativos (ajustes de diferença)
- Indica necessidade de refinamento do modelo

---

## 📌 RESUMO EXECUTIVO

A metodologia de forecast utiliza um **modelo determinístico** baseado em:

1. **Extração de histórico** via SUMIFS da base de vendas
2. **Cálculo de médias e totais** por período
3. **Comparação orçado vs realizado** para identificar desvios
4. **Projeção futura** aplicando ajustes e correções
5. **Monitoramento via KPIs** (MAPE, WAPE, Forecast Accuracy)

**Status atual:** Modelo operacional, mas com **precisão abaixo da meta** - requer calibração e ajustes.

---

**Gerado em:** 16/06/2026  
**Fonte:** Análise da planilha "6- Cenário de Demanda 15.06.2026.xlsx"
