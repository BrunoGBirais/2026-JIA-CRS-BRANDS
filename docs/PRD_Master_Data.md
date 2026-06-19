# 📄 PRD: Módulo de Gestão de Produtos (Master Data)

## 1. Visão Geral
O Módulo de Gestão de Produtos é uma interface de frontend projetada para permitir que a equipa comercial e de S&OP visualize, faça a gestão e mantenha o catálogo de SKUs (Master Data) da companhia. O objetivo é descentralizar a manutenção cadastral, garantindo governança, validação de dados na entrada e bloqueando manipulações diretas na base de dados (Supabase) ou folhas de cálculo soltas.

## 2. Objetivos do Produto
* Fornecer uma interface visual unificada para leitura de todos os produtos (`crs_brands_produtos`).
* Permitir operações CRUD (Criar, Ler, Atualizar, Eliminar) de forma intuitiva.
* Garantir a integridade dos dados por meio de validações de formulário (ex: regras da Curva ABC).
* Disponibilizar a extração rápida de todo o catálogo para relatórios ad-hoc via download de CSV.

## 3. Histórias de Utilizador (User Stories)
* **Visualização:** "Como analista de S&OP, quero ver uma tabela com todos os produtos cadastrados, podendo pesquisar por código ou descrição, para encontrar SKUs rapidamente."
* **Criação:** "Como administrador, quero um botão para adicionar um novo produto, preenchendo as categorias e classificações, para que ele entre no modelo de forecast."
* **Edição:** "Como analista, quero clicar num produto existente e alterar a sua família comercial ou curva ABC, para manter o registo atualizado."
* **Eliminação:** "Como administrador, quero poder apagar um produto que foi registado com erro, desde que ele não possua histórico de vendas atrelado."
* **Exportação:** "Como gestor, quero um botão 'Exportar CSV' para transferir a base completa de produtos e utilizá-la em apresentações ou cruzamentos no Excel."

---

## 4. Requisitos Funcionais (Âmbito da Interface)

### 4.1. Ecrã Principal (Data Grid / Tabela)
* **Componente Base:** Uma tabela interativa listando todos os registos.
* **Colunas Visíveis:** Código (ID), Descrição, Tipo de Mercado, Família (Comercial), Curva ABC Est., Curva ABC Vendas.
* **Controlos Superiores:**
  * Barra de pesquisa rápida (filtra por `id_item` ou `descricao`).
  * Botão primário: `+ Novo Produto`.
  * Botão secundário: `📥 Exportar CSV`.
* **Paginação:** A tabela deve exibir os dados em páginas (ex: 50 itens por página) para não sobrecarregar o navegador.

### 4.2. Formulário de Criação / Edição (Modal ou Side-panel)
Ao clicar em "Novo Produto" ou "Editar", uma janela deve abrir com os seguintes campos mapeados para a tabela da base de dados:
* **`id_item` (Código do Item):** Campo de texto. *Obrigatório*. (Bloqueado para edição se for uma atualização de produto existente).
* **`descricao` (Descrição):** Campo de texto longo. *Obrigatório*.
* **`tipo_mercado` (Mercado):** Menu suspenso (Dropdown) com opções comuns (ex: 'MERCADO INTERNO', 'MERCADO EXTERNO').
* **Famílias (`totvs`, `comercial`, `plan_i`, `plan_ii`):** Campos de texto ou menus suspensos caso as categorias sejam fixas.
* **`curva_abc_est` (ABC Estoque):** Botões de rádio ou Dropdown estrito contendo apenas: `A`, `B`, `C`.
* **`curva_abc_vendas` (ABC Vendas):** Botões de rádio ou Dropdown estrito contendo apenas: `A`, `B`, `C`.

### 4.3. Regras de Eliminação (Delete)
* O botão de eliminar (geralmente um ícone de caixote do lixo na linha da tabela) deve acionar um modal de confirmação: *"Tem a certeza que deseja eliminar o produto [Descrição]? Esta ação não pode ser desfeita."*
* **Tratamento de Erro:** Se a base de dados devolver erro de *Foreign Key constraint* (ou seja, o produto não pode ser apagado porque já possui histórico de vendas na tabela de factos), o frontend deve capturar esse erro e exibir um alerta amigável: *"Falha ao eliminar: Este produto possui histórico de vendas ou procura registada."*

### 4.4. Módulo de Exportação
* O clique no botão "Exportar CSV" deve disparar uma consulta (query) que puxa todos os registos (ignorando a paginação do ecrã) e converte o JSON devolvido pelo Supabase para um ficheiro `.csv`, iniciando o download automaticamente no navegador do utilizador. O separador do CSV deve ser ponto e vírgula (`;`) ou vírgula (`,`), dependendo do padrão da equipa.

---

## 5. Requisitos Não Funcionais
* **Conectividade:** O frontend deve ligar-se ao Supabase preferencialmente via API REST (Supabase Client) para latência mínima nas operações CRUD.
* **Feedback Visual (Toast/Snackbars):** Toda a ação de sucesso (guardar, editar, eliminar) ou erro deve exibir uma notificação temporária no canto do ecrã informando o resultado ao utilizador.
* **Performance:** A pesquisa textual na tabela deve ter um *debounce* (esperar o utilizador parar de digitar por 300ms antes de consultar a base de dados) para evitar excesso de requisições.

---

## 6. Fluxograma de Arquitetura de Dados (CRUD)

1. **Read (Ler):** Frontend faz um `GET` no Supabase (Tabela `crs_brands_produtos`) -> Preenche a tabela no ecrã.
2. **Create (Criar):** Utilizador preenche form -> Frontend faz `POST` -> Supabase valida as constraints (ex: CHECK de Curva ABC) -> Devolve Sucesso -> Tabela atualiza.
3. **Update (Editar):** Utilizador altera form -> Frontend faz `PATCH` usando o `id_item` -> Devolve Sucesso -> Tabela atualiza.
4. **Delete (Eliminar):** Utilizador clica no ícone -> Frontend faz `DELETE` usando o `id_item` -> Devolve Sucesso -> Linha desaparece da tabela.
