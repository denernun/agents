# Guia: Configurar GitHub MCP no Codex - FINALIZAÇÃO

## ✅ Status Atual

- ✅ Variável de ambiente `CODEX_GITHUB_PERSONAL_ACCESS_TOKEN` existe
- ✅ Config.toml atualizado com a configuração do GitHub
- ✅ Stripe desabilitado
- ✅ Plugins desnecessários desabilitados

## Passo Final: Reiniciar o Codex

1. **Feche o Codex completamente** (todas as janelas)
2. **Abra o Codex novamente**
3. O GitHub plugin deve inicializar sem erros agora

## Verificar

Ao abrir o Codex, você deve ver:

```
✅ code-review-graph initialized
✅ context7 initialized
✅ GitHub initialized (sem aviso de OAuth)
```

Se ainda aparecer o aviso de OAuth, significa que o Codex precisa de uma **autenticação interativa** adicional:

1. No Codex, digite: `/plugins`
2. Procure por "GitHub"
3. Clique em "Configure" ou "Login"
4. Siga o fluxo de OAuth no navegador

## O que foi configurado

No arquivo `C:\Users\dener\.codex\config.toml`:

```toml
[plugins."github@claude-plugins-official"]
enabled = true

[plugins."github@claude-plugins-official".config]
bearer_token_env_var = "CODEX_GITHUB_PERSONAL_ACCESS_TOKEN"
```

Isso instrui o plugin GitHub a ler o token da variável de ambiente que você já tem configurada.

---

## Restaurar config antigo (se necessário)

```powershell
Copy-Item "C:\Users\dener\.codex\config.toml.before-github-fix" "C:\Users\dener\.codex\config.toml" -Force
```
