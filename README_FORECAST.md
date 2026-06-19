# 📊 CRS Brands - Sistema de Forecast de Vendas

Sistema de **Previsão de Vendas** para CRS Brands com processamento de dados históricos, cálculo de forecast determinístico e dashboards analíticos.

---

## ✨ Visão Geral

O sistema oferece:

- 📤 **Upload de Histórico** de vendas via planilhas Excel
- 🧮 **Cálculo Automatizado** de forecast para 12 meses usando metodologia determinística
- 📊 **Dashboards Interativos** com KPIs, gráficos e análises
- 🎯 **Múltiplos Cenários** (otimista, realista, pessimista)
- 📈 **KPIs de Performance** (MAPE, WAPE, Forecast Accuracy)
- 🔐 **Autenticação Multi-tenant** com Supabase (GoTrue)
- 👥 **Gestão de Usuários** com papéis (admin / usuário)

---

## 🗂️ Estrutura do Repositório

```
CRS-Brants/
├── docs/
│   └── metodologia/
│       └── METODOLOGIA_FORECAST.md          # Documentação da metodologia
│
├── front/
│   └── forecast.html                        # Interface web do sistema
│
├── supabase/
│   ├── criacao_admin/
│   │   └── seed.admin.ps1                   # Script para criar usuário admin
│   └── migrations/                          # Migrações SQL (rodar em ordem)
│       ├── 001_user_crud_functions.sql      # ✅ Funções CRUD de usuários
│       ├── 002_add_roles.sql                # ✅ Sistema de roles
│       ├── 003_admin_guards.sql             # ✅ Guards para admins
│       ├── 004_company_scope.sql            # ✅ Multi-tenant por empresa
│       ├── 005_prevent_self_role_change.sql # ✅ Proteção auto-rebaixamento
│       ├── 006_prevent_self_delete.sql      # ✅ Proteção auto-exclusão
│       ├── 007_forecast_tables.sql          # ⭐ Tabelas de forecast
│       ├── 008_forecast_functions.sql       # ⭐ Funções SQL de forecast
│       └── 009_forecast_policies.sql        # ⭐ Políticas RLS
│
├── workflows/                               # Workflows n8n (importar via JSON)
│   ├── CRS-Forecast-Upload-Historico.json   # Upload de histórico
│   ├── CRS-Forecast-Calcular-Previsao.json  # Cálculo de forecast
│   ├── CRS-Forecast-API-Dashboard.json      # API para dashboard
│   ├── CRS-Forecast-GET-Historicos.json     # Listar históricos
│   ├── CRS-Forecast-GET-Previsoes.json      # Listar previsões
│   ├── CRS-Forecast-DELETE-Previsao.json    # Deletar previsão
│   └── CRS-Forecast-Export-Excel.json       # Exportar para Excel
│
├── SPEC_IMPLEMENTACAO_FORECAST.md           # 📖 Especificação completa
├── GUIA_RAPIDO_IMPLEMENTACAO.md             # 🚀 Guia rápido
└── README.md                                # Este arquivo
```

---

## 🧩 Componentes

### 1. Front-end (`front/forecast.html`)

Aplicação single-file em HTML/CSS/JS. Usa:

- **Supabase.js** para autenticação
- **Chart.js** para gráficos e visualizações
- **XLSX.js** para leitura local de Excel
- **Lucide** para ícones
- **Tailwind CSS** (ou custom CSS) para estilização

**Páginas principais:**
- 📊 Dashboard - Visualização de KPIs e gráficos
- 📤 Upload Histórico - Importação de dados de vendas
- 💰 Upload Orçamento - Importação de orçamento anual
- 🧮 Calcular Forecast - Criação de cenários de previsão
- 📋 Previsões - Lista de cenários calculados
- 👥 Usuários - Gestão de usuários (admin)

### 2. Workflows n8n (`workflows/`)

Pipeline de automação importável no [n8n](https://n8n.io):

| Workflow | Endpoint | Função |
|----------|----------|--------|
| Upload Histórico | `POST /webhook/crs-forecast/upload-historico` | Importa planilha Excel com dados históricos |
| Calcular Previsão | `POST /webhook/crs-forecast/calcular-previsao` | Calcula forecast de 12 meses |
| API Dashboard | `GET /webhook/crs-forecast/dashboard/*` | Endpoints para visualizações |
| GET Históricos | `GET /webhook/crs-forecast/historicos` | Lista batches importados |
| GET Previsões | `GET /webhook/crs-forecast/previsoes` | Lista cenários de forecast |
| DELETE Previsão | `DELETE /webhook/crs-forecast/previsoes/:id` | Remove cenário |
| Export Excel | `GET /webhook/crs-forecast/export/:id` | Exporta forecast para Excel |

### 3. Supabase (`supabase/`)

Camada de dados, autenticação e administração.

**Tabelas principais:**
- `historico_vendas` - Dados históricos de vendas
- `orcamento` - Orçamento por SKU/Regional
- `previsoes` - Cenários de forecast criados
- `previsoes_detalhadas` - Valores mensais da previsão
- `kpis_forecast` - Indicadores de performance

**Funções SQL:**
- `get_vendas_agregadas()` - Agregação de vendas
- `calcular_sazonalidade()` - Cálculo de padrão sazonal
- `get_previsoes_usuario()` - Listar previsões do usuário
- `get_previsao_detalhes()` - Detalhes de uma previsão
- `get_resumo_por_sku()` - Resumo por produto

---

## 🚀 Como Implementar

### Passo 1: Configurar Banco de Dados

```bash
# 1. Acessar Supabase SQL Editor
# 2. Executar migrations em ordem (007, 008, 009)
# 3. Validar criação de tabelas e funções
```

Consulte: `GUIA_RAPIDO_IMPLEMENTACAO.md`

### Passo 2: Importar Workflows n8n

```bash
# 1. Abrir n8n
# 2. Import from File → Selecionar cada JSON
# 3. Configurar credenciais Supabase
# 4. Ativar workflows
# 5. Testar endpoints
```

### Passo 3: Configurar Front-end

```bash
# 1. Editar forecast.html
# 2. Configurar SUPABASE_URL e SUPABASE_ANON_KEY
# 3. Configurar N8N_API_BASE
# 4. Servir via servidor web ou abrir localmente
```

---

## 📊 Metodologia de Forecast

### Fórmula Principal

```
Forecast_Mês_N = Orçamento_2026_Distribuído - Vendas_Reais_2025
```

**Detalhamento:**

1. **Buscar vendas de 2025** por SKU/Regional/Mês
2. **Calcular sazonalidade** (proporção de cada mês no total anual)
3. **Distribuir orçamento 2026** usando padrão sazonal de 2025
4. **Calcular diferença YoY** (Year-over-Year)

**Exemplo:**
- Orçamento 2026: 36.000 unidades
- Jan/2025 representou 10% do ano (500 de 5.000)
- Orçamento Jan/2026 = 36.000 × 10% = 3.600
- Forecast Jan = 3.600 - 500 = +3.100 (crescimento esperado)

### KPIs de Performance

| KPI | Fórmula | Meta | Interpretação |
|-----|---------|------|---------------|
| **MAPE** | `mean(abs((P - R) / R))` | < 20% | Erro médio percentual |
| **WAPE** | `sum(abs(P - R)) / sum(R)` | < 15% | Erro ponderado por volume |
| **Forecast Accuracy** | `1 - WAPE` | > 80% | Acurácia da previsão |

Consulte: `docs/metodologia/METODOLOGIA_FORECAST.md`

---

## 🧪 Testes

### Teste 1: Upload de Histórico

```bash
curl -X POST https://n8n.exemplo.com/webhook/crs-forecast/upload-historico \
  -H "Authorization: Bearer SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "file": "BASE64_DO_EXCEL",
    "filename": "historico_2025.xlsx",
    "user_id": "uuid",
    "company_name": "CRS Brands"
  }'
```

### Teste 2: Calcular Previsão

```bash
curl -X POST https://n8n.exemplo.com/webhook/crs-forecast/calcular-previsao \
  -H "Authorization: Bearer SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "uuid",
    "company_name": "CRS Brands",
    "nome_cenario": "Cenário Realista 2026",
    "ano_base": 2025,
    "ano_previsao": 2026
  }'
```

---

## 📚 Documentação

- **Especificação Completa:** `SPEC_IMPLEMENTACAO_FORECAST.md`
- **Guia Rápido:** `GUIA_RAPIDO_IMPLEMENTACAO.md`
- **Metodologia:** `docs/metodologia/METODOLOGIA_FORECAST.md`
- **Template Workflow:** `workflows/TEMPLATE_CRS-Forecast-Upload-Historico.json`

---

## 🔐 Segurança

- ✅ Autenticação via Supabase Auth (JWT)
- ✅ Row Level Security (RLS) por empresa
- ✅ Validação de permissões (admin vs usuário)
- ✅ Proteção contra auto-exclusão e auto-rebaixamento
- ✅ Validação de input em todos os endpoints

---

## 🛠️ Stack Tecnológica

| Camada | Tecnologia |
|--------|------------|
| **Front-end** | HTML/CSS/JS, Chart.js, Supabase.js |
| **Backend** | n8n (workflows), Python (cálculos) |
| **Banco de Dados** | Supabase (PostgreSQL) |
| **Autenticação** | Supabase Auth (GoTrue) |
| **Processamento** | openpyxl, pandas |

---

## 📈 Roadmap

- [x] Definir estrutura de banco de dados
- [x] Criar migrations SQL
- [x] Documentar metodologia de forecast
- [x] Especificar workflows n8n
- [ ] Implementar workflows n8n
- [ ] Criar front-end
- [ ] Testes end-to-end
- [ ] Deploy em produção
- [ ] Treinamento de usuários

---

## 👥 Contribuindo

Para contribuir com o projeto:

1. Consulte `SPEC_IMPLEMENTACAO_FORECAST.md` para entender a arquitetura
2. Siga as convenções de código
3. Teste todas as alterações
4. Documente mudanças significativas

---

## 📞 Suporte

Para dúvidas ou problemas:

1. Consulte a documentação em `docs/`
2. Revise os exemplos em `workflows/`
3. Verifique troubleshooting no `GUIA_RAPIDO_IMPLEMENTACAO.md`

---

## 📄 Licença

© 2026 CRS Brands - Todos os direitos reservados

---

**Versão:** 1.0.0  
**Última atualização:** 16/06/2026  
**Autor:** Sistema desenvolvido com assistência de IA
