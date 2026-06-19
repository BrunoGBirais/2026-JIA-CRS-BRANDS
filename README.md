# Imagens Bahia — Assistente Virtual com IA

Assistente virtual conversacional para a **Imagens Bahia**, empresa com mais de 60 anos de mercado, referência em imagens religiosas católicas e afro-religiosas. O projeto reúne um **front-end web**, **workflows de automação no n8n** (agente de IA + RAG + chat history) e uma camada de **autenticação e administração de usuários no Supabase**.

---

## ✨ Visão geral

O sistema oferece:

- 💬 **Chat com IA** treinado com a base de conhecimento institucional, catálogo de produtos, playbook de vendas e respostas a objeções da Imagens Bahia.
- 📚 **RAG (Retrieval-Augmented Generation)** alimentado por documentos em Markdown versionados em `docs/rag_docs/`.
- 🗂️ **Histórico de sessões** persistente (listar, recuperar e excluir conversas).
- 🔐 **Autenticação multiusuário** com Supabase (GoTrue) e papéis (admin / usuário) com guard-rails de segurança.
- 🏢 **Escopo por empresa** (multi-tenant ready) com políticas para impedir auto-promoção e auto-exclusão.

---

## 🗂️ Estrutura do repositório

```
imagens_bahia/
├── docs/
│   └── rag_docs/                # Base de conhecimento usada pelo RAG
│       ├── 01_institucional_imagens_bahia.md
│       ├── 02_produtos_materiais_linhas.md
│       ├── 03_playbook_vendas_interno.md
│       └── 04_objecoes_respostas_modelo.md
├── front/
│   └── front.html               # Interface web do assistente (single-file)
├── supabase/
│   ├── criacao_admin/
│   │   └── seed.admin.ps1       # Script PowerShell para criar usuário admin
│   └── migrations/              # Migrações SQL (rodar em ordem)
│       ├── 001_user_crud_functions.sql
│       ├── 002_add_roles.sql
│       ├── 003_admin_guards.sql
│       ├── 004_company_scope.sql
│       ├── 005_prevent_self_role_change.sql
│       └── 006_prevent_self_delete.sql
└── workflows/                   # Workflows do n8n (importar via JSON)
    ├── Imagens-Bahia-agent-ia.json
    ├── Imagens_Bahia-RAG.json
    ├── Imagens_Bahia-Front.json
    ├── imagens_bahia-Chat-GET-Sessions.json
    ├── imagens_bahia-Chat-GET-History.json
    ├── imagens_bahia-Chat-DELETE-Session.json
    └── [Imagens_Bahia] Sub-fixo_ Consultar Planilha Inteligente.json
```

---

## 🧩 Componentes

### 1. Front-end (`front/front.html`)

Aplicação single-file em HTML/CSS/JS puro, sem build step. Usa:

- `marked.js` para renderizar Markdown nas respostas
- `highlight.js` para code highlighting
- `lucide` para ícones
- Tipografia Google Fonts (Cinzel, Cormorant Garamond, Inter, Raleway)
- Tema visual alinhado à identidade da Imagens Bahia (azul royal `#1c4a85` e dourado `#e9a826`)

Basta abrir o arquivo no navegador ou servir via qualquer servidor estático.

### 2. Workflows n8n (`workflows/`)

Pipeline de automação importável no [n8n](https://n8n.io):

| Workflow | Função |
|---|---|
| `Imagens-Bahia-agent-ia.json` | Agente principal de IA (orquestra LLM + ferramentas) |
| `Imagens_Bahia-RAG.json` | Indexação e consulta da base de conhecimento |
| `Imagens_Bahia-Front.json` | Endpoint consumido pelo front-end |
| `imagens_bahia-Chat-GET-Sessions.json` | Lista sessões de chat do usuário |
| `imagens_bahia-Chat-GET-History.json` | Recupera histórico de uma sessão |
| `imagens_bahia-Chat-DELETE-Session.json` | Exclui uma sessão |
| `[Imagens_Bahia] Sub-fixo_ Consultar Planilha Inteligente.json` | Sub-workflow para consulta a planilha |

### 3. Supabase (`supabase/`)

Camada de dados, auth e administração de usuários.

**Migrações** (executar em ordem em `supabase/migrations/`):

1. `001_user_crud_functions.sql` — funções CRUD de usuários (listar / confirmar / etc.)
2. `002_add_roles.sql` — adiciona o campo `role` ao retorno e gestão
3. `003_admin_guards.sql` — restringe operações sensíveis a admins
4. `004_company_scope.sql` — escopo multi-tenant por `company_name`
5. `005_prevent_self_role_change.sql` — impede que um admin rebaixe a si mesmo
6. `006_prevent_self_delete.sql` — impede que um admin exclua a si mesmo

**Seed do administrador** (`criacao_admin/seed.admin.ps1`):

Script PowerShell que cria o usuário admin via GoTrue API e exibe o SQL complementar para confirmar o e-mail e atribuir o papel `admin`.

---

## 🚀 Como rodar

### Pré-requisitos

- Instância **Supabase** (self-hosted ou Supabase Cloud)
- Instância **n8n** (self-hosted ou n8n Cloud)
- Provedor de LLM configurado no n8n (ex.: OpenAI, Anthropic, etc.)
- Navegador moderno

### 1. Configurar o Supabase

```powershell
# Aplicar as migrações em ordem usando psql, Supabase Studio ou pgAdmin
# Ex.: psql -h <host> -U postgres -d postgres -f supabase/migrations/001_user_crud_functions.sql
# ... repetir para 002 a 006
```

Edite `supabase/criacao_admin/seed.admin.ps1` e atualize:

- `$SUPABASE_URL` — URL da sua instância
- `$ANON_KEY` — anon key do projeto
- `$EMAIL` / `$PASSWORD` — credenciais iniciais do admin

Depois execute:

```powershell
cd supabase/criacao_admin
./seed.admin.ps1
```

Em seguida, rode no banco o SQL exibido pelo script para confirmar o e-mail e fixar o papel `admin`.

> ⚠️ **Segurança:** troque a senha padrão imediatamente após o primeiro login e **nunca** commite chaves reais. Use variáveis de ambiente / `.env` em produção.

### 2. Importar os workflows no n8n

1. Acesse seu n8n → **Workflows** → **Import from File**.
2. Importe um a um os arquivos `.json` em `workflows/`.
3. Configure as credenciais (LLM, Supabase, etc.) em cada workflow.
4. Ative os workflows que expõem webhooks (chat, sessions, history, delete).

### 3. Configurar o front-end

Abra `front/front.html` e ajuste a(s) URL(s) de webhook do n8n para apontar para a sua instância. Em seguida sirva o arquivo:

```powershell
# Opção simples com Python
cd front
python -m http.server 8080
```

Acesse `http://localhost:8080/front.html`.

---

## 📚 Base de conhecimento (RAG)

Os documentos em `docs/rag_docs/` são versionados em Markdown para facilitar revisão por humanos e ingestão pelo workflow de RAG. Para atualizar a base:

1. Edite ou adicione arquivos `.md` em `docs/rag_docs/`.
2. Reexecute o workflow `Imagens_Bahia-RAG.json` para reindexar.

Conteúdo atual:

- **Institucional** — história, diferenciais e reconhecimento
- **Produtos** — materiais, linhas e catálogo
- **Playbook de vendas interno**
- **Objeções e respostas modelo**

---

## 🔐 Segurança

- ❌ Não commite `anon_key`, `service_role_key`, senhas ou tokens. Substitua os valores em `seed.admin.ps1` por variáveis de ambiente antes de subir para um repositório público.
- ✅ As migrações `003` a `006` implementam guard-rails para evitar escalada de privilégios e auto-exclusão.
- ✅ Use HTTPS em todas as integrações (n8n ↔ Supabase ↔ front-end).

---

## 🤝 Contribuição

1. Faça um fork do projeto
2. Crie uma branch: `git checkout -b feat/minha-feature`
3. Commit: `git commit -m "feat: minha feature"`
4. Push: `git push origin feat/minha-feature`
5. Abra um Pull Request

---

## 📄 Licença

Defina aqui a licença do projeto (ex.: MIT, Apache-2.0, proprietária).

---

## 🙋 Sobre a Imagens Bahia

Empresa brasileira com mais de **60 anos de tradição** em imagens religiosas católicas e afro-religiosas, com peças expostas em museus como o **MoMA (Nova Iorque)**, o **Museu de Arte Sacra de São Paulo** e o **Memorial da América Latina**. Atua em todo o Brasil e no exterior, com produção 100% artesanal.

🌐 [imagensbahia.com.br](https://www.imagensbahia.com.br)
