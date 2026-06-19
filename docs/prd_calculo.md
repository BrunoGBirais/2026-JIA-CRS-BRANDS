# Product Requirement Document (PRD)
## Ref: Dynamic Rolling S&OP Forecasting Engine via n8n & Supabase

### 1. Visão Geral do Produto
O objetivo deste fluxo no n8n é criar um motor de cálculo dinâmico e contínuo para previsão de demanda (S&OP) utilizando o conceito de **Rolling Forecast**. O fluxo atuará como uma API que recebe parâmetros macro de simulação vindos de um front-end (pesos e taxa de crescimento), extrai a base de dados do Supabase, processa a média móvel ponderada linha por linha e projeta **sempre os 12 próximos meses** de forma móvel, avançando de ano se necessário (ex: de Novembro/2026 até Outubro/2027).

### 2. Arquitetura do Fluxo (n8n)
O workflow deve ser composto por 3 nós principais conectados em série:
1. **Webhook Node (Trigger):** Método `POST`. Recebe o payload do front-end com os parâmetros de simulação e o mês de partida.
2. **Supabase Node (Data Retrieval):** Operação `GetAll`. Busca todos os registros da tabela de histórico de vendas (consolidados por item/regional).
3. **Code Node (JavaScript Processing):** Processa a lógica de S&OP combinando os parâmetros do Webhook com os dados específicos de cada linha do banco, gerando a janela móvel de 12 meses.

---

### 3. Requisitos Funcionais e Regras de Negócio

#### 3.1. Parâmetros de Entrada (Webhook Payload)
O JSON recebido pelo Webhook deve aceitar os seguintes campos (com *fallbacks* padrão caso venham vazios):
* `peso_2023` (Número, Padrão: `0.5`)
* `peso_2024` (Número, Padrão: `1.0`)
* `peso_2025` (Número, Padrão: `4.0`)
* `peso_6m_2025` (Número, Padrão: `2.0`)
* `peso_3m_2025` (Número, Padrão: `2.0`)
* `crescimento` (Número, Padrão: `0.08` — representando 8%)
* `mes_inicio_projecao` (String no formato `"AAAA-MM"`, Padrão: Mês subsequente ao mês atual do sistema)

#### 3.2. Estrutura de Dados do Banco (Supabase)
O script deve estar preparado para ler as seguintes propriedades de cada item retornado:
* **Identificadores:** `Item` (ou `id_item`), `Descrição`, `Regionais` (ou `regional`).
* **Históricos para Baseline:** `media_2023`, `media_2024`, `media_2025`, `media_6meses_2025`, `media_3meses_2025`.
* **Realizado Corrente (Histórico Mensal):** Colunas ou propriedades nomeadas no padrão `real_jan_2026`, `real_fev_2026`, etc., ou um objeto mapeado de histórico.

#### 3.3. Metodologia de Cálculo (A ser executada no Code Node)
Para cada item retornado pelo Supabase, o algoritmo deve aplicar os seguintes passos:

1. **Cálculo da Linha de Base (Baseline Ponderada):**
   Multiplicar cada média histórica pelo seu respectivo peso e dividir pela soma total dos pesos ativos.
   $$\text{Média Ponderada S\&OP} = \frac{(M_{2023} \cdot P_{2023}) + (M_{2024} \cdot P_{2024}) + (M_{2025} \cdot P_{2025}) + (M_{6M25} \cdot P_{6M25}) + (M_{3M25} \cdot P_{3M25})}{\sum \text{Pesos}}$$

2. **Aplicação do Fator de Crescimento:**
   $$\text{Baseline Projetada} = \text{Média Ponderada S\&OP} \cdot (1 + \text{taxaCrescimento})$$

3. **Geração da Janela Móvel de 12 Meses (Rolling Forecast):**
   * A partir do `mes_inicio_projecao` (ex: `2026-11`), o código deve gerar uma sequência de 12 meses consecutivos (ex: `2026-11`, `2026-12`, `2027-01` ... `2027-10`).
   * **Regra de Preenchimento:** Para cada um desses 12 meses da janela móvel, o script verifica se já existe um valor real consolidado no banco. Se houver valor real ($> 0$), ele mantém o real. Se estiver zerado, nulo ou for um mês estritamente futuro, ele preenche com o valor calculado da `Baseline Projetada`.

4. **Agregações Finais:**
   Calcular o `total_forecast_12m` (soma dos 12 meses resultantes da janela móvel) e a `media_forecast_12m` (total dividido por 12).

---

### 4. Requisitos Técnicos do Código JavaScript (n8n)
* Use o método `$item(0).$node["Nome_do_Node"].json.body` dentro do loop para garantir que o nó de código acesse os parâmetros do Webhook de forma global, independentemente de quantas linhas venham do Supabase.
* Garanta tratamento para divisão por zero (caso a soma dos pesos seja 0, o resultado da média ponderada deve ser 0).
* As chaves do objeto de projeção mensal devem ser dinâmicas no formato `"AAAA-MM"`.

### 5. Formato de Saída Esperado (Output Schema)
O nó de código gerado deve retornar um JSON com esta estrutura para cada item:
```json
{
  "id_item": "1211",
  "descricao": "AGUARD COMP OLD CESAR 88 965ML 12X1",
  "regional": "R01 - SP CAPITAL",
  "parametros_utilizados": {
    "peso_2023": 0.5,
    "peso_2024": 1,
    "peso_2025": 4,
    "peso_6m_2025": 2,
    "peso_3m_2025": 2,
    "crescimento": 0.08,
    "mes_inicio_projecao": "2026-11"
  },
  "ponderada_sop": 1694,
  "total_forecast_12m": 21530.2,
  "media_forecast_12m": 1794.18,
  "projeção_dinamica_12m": {
    "2026-11": 1829.52,
    "2026-12": 1829.52,
    "2027-01": 1829.52,
    "2027-02": 1829.52
  }
}