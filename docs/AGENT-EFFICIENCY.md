# Eficiência de execução dos agentes

O HUB aplica uma política curta nos templates de `AGENTS.md`. Ela reduz
verbosidade e contexto desnecessário sem trocar qualidade por economia.

## Política always-on

- Resultado antes de narrativa; não repetir o pedido.
- Detalhes, alternativas e tabelas só quando o pedido, o risco ou uma decisão
  exigirem.
- Buscar símbolos antes de abrir arquivos; limitar a saída de comandos na
  origem.
- Nunca truncar resultados de `Read`, `Edit` ou `Write`: esses bytes podem ser
  necessários para uma edição posterior.
- Segurança, validação, testes, acessibilidade, diagnóstico e requisitos
  explícitos não são candidatos a economia.

## Limites

O HUB não reescreve resultados de ferramentas. Compressão pós-ferramenta deve
ser avaliada por IDE e só pode ser habilitada com allowlist, recuperação de
erros e kill switch. Até então, prefira filtros na chamada (`rg`, intervalo de
linhas, `--stat`, `tail`) em vez de cortar a resposta depois.

## Operação

Depois de atualizar o hub, rode `scripts/Install-AgentHub.ps1 -WriteAgents`
para regenerar os `AGENTS.md` dos projetos. Avalie a mudança por tokens,
duração, retrabalho e falhas de contexto antes de ampliar regras ou automações.
