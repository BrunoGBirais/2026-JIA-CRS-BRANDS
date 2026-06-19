# Correções de Login e Segurança

## Data: 2026-06-17

## Problemas Identificados e Corrigidos

### 1. Botão de Login Não Funcionava (front.html)

**Problema:** O botão de login não estava fazendo nada quando clicado.

**Causa Raiz:** A função `checkAuth()` estava sendo chamada ANTES do DOM estar totalmente carregado, fazendo com que os elementos do formulário não fossem encontrados (`document.getElementById()` retornava `null`) e os event listeners não fossem registrados.

**Solução:** Modificado o código de inicialização para garantir que `checkAuth()` só seja executado quando o DOM estiver pronto:

```javascript
// Antes:
checkAuth();
document.addEventListener("DOMContentLoaded", () => {
  lucide.createIcons();
});

// Depois:
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", () => {
    lucide.createIcons();
    checkAuth();
  });
} else {
  lucide.createIcons();
  checkAuth();
}
```

### 2. Falta de Verificação de Empresa em Operações Sensíveis

**Problema:** Embora o login verificasse a empresa, outras operações não revalidavam se o usuário pertence à CRS Brands.

**Solução:** Criada função auxiliar `verifyCompanyAccess()` que verifica se o usuário atual pertence à empresa "crs_brants":

```javascript
async function verifyCompanyAccess() {
  try {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) return false;
    
    const meta = session.user.user_metadata || {};
    const company = (meta.company_name || "").trim().toLowerCase();
    
    if (company !== "crs_brants") {
      console.warn("Acesso negado: empresa '" + company + "' não autorizada.");
      await supabase.auth.signOut();
      // ... exibe mensagem de erro
      return false;
    }
    return true;
  } catch (err) {
    console.error("Erro ao verificar empresa:", err);
    return false;
  }
}
```

## Operações Protegidas

### front.html
- ✅ Login inicial (função `handleSession`)
- ✅ Upload de histórico (`uploadHistoryFile`)
- ✅ Calcular previsão (`predictBtn` click event)
- ✅ Calcular previsão (página vazia) (`emptyPredictBtn` click event)

### forecast.html
- ✅ Login inicial (função `checkAuth`)
- ✅ Upload de histórico (`uploadHistorico`)
- ✅ Upload de orçamento (`uploadOrcamento`)
- ✅ Calcular previsão (`calcularPrevisao`)
- ✅ Deletar previsão (`deletePrevisao`)

## Segurança Implementada

### Camadas de Proteção

1. **Verificação no Login**
   - Valida empresa "crs_brants" no `user_metadata`
   - Desloga automaticamente usuários de outras empresas
   - Exibe mensagem de erro específica

2. **Verificação em Operações Sensíveis**
   - Chamada de `verifyCompanyAccess()` antes de operações críticas
   - Valida sessão e empresa antes de cada operação
   - Logout automático se empresa não corresponder

3. **Proteção no Backend**
   - Policies do Supabase (RLS - Row Level Security)
   - RPCs que verificam permissões (`crs_brants_admin_*`)
   - Funções do N8n que validam company_name

## Nome da Empresa Padronizado

O sistema verifica a empresa como **"crs_brants"** (lowercase) em `user_metadata.company_name`.

## Mensagens de Erro

- **Login de empresa não autorizada:**
  ```
  "Acesso não autorizado. Este sistema é exclusivo para CRS Brands."
  ```

- **Tentativa de operação sem autorização:**
  ```
  "Acesso não autorizado"
  ```

## Testes Recomendados

1. ✅ Login com usuário da CRS Brands
2. ⚠️ Tentativa de login com usuário de outra empresa (deve ser bloqueado)
3. ✅ Upload de histórico
4. ✅ Upload de orçamento
5. ✅ Cálculo de previsão
6. ✅ Deleção de previsão
7. ⚠️ Verificar se logout automático funciona quando empresa muda

## Arquivos Modificados

- `front/front.html`
- `front/forecast.html`

## Observações Importantes

- A verificação é case-insensitive (lowercase)
- O logout é automático quando empresa não corresponde
- As mensagens de erro são específicas para não expor informações sensíveis
- A segurança é em camadas: frontend + backend (Supabase RLS)
