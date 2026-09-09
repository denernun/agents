# CodeGraph no AgentHub

O HUB mantém MCP por projeto, com caminho explícito e `DO_NOT_TRACK=1`.
O fallback global do Codex é opcional (`Sync-Codegraph.ps1 -Global`) e não fixa
um repositório: em sessões fora do projeto, informe `projectPath` na consulta.
Reabra a sessão depois de mudar os MCPs ou skills; arquivo configurado não prova
que um cliente já carregou a ferramenta.

## Atualização direcionada

`scripts/Sync-Codegraph.ps1 -Projects <repo1>,<repo2> -Global -AdoptLegacySkills`
atualiza somente CodeGraph nas configurações existentes, preserva outros MCPs
e salva backup das skills globais antigas reconhecidas. Use `-DryRun` antes de
aplicar. Skills personalizadas são preservadas. Para indexar, acrescente
`-Initialize`; o instalador normal também inclui a família Delphi.
As cinco skills globais ficam vinculadas à fonte do HUB, evitando cópias antigas.

## Worktrees e qualidade

- Inicialize cada worktree com `codegraph init <worktree> --yes` e gere sua
  configuração a partir do caminho dessa worktree. Não reutilize o caminho
  absoluto da configuração copiada da branch principal.
- Confirme o caminho retornado e os avisos de índice de outra worktree.
- Leia diretamente arquivos sinalizados como desatualizados ou não cobertos.
- Consultas via `projectPath` a outro projeto não garantem watcher ativo nele.
- O grafo ajuda a navegação; compilação, testes e revisão validam correção.
- Em Delphi, valide unit, método e ligação do evento DFM/FMX num fluxo conhecido.
- Arquivos Delphi legados podem retornar acentos com substituição de caracteres.
  Preserve a codificação original ao editar; use leitura que respeite a codificação
  do arquivo em vez de copiar literalmente a saída do grafo nesses casos.
- Em Angular, não infira cobertura de templates/DI a partir do suporte TypeScript.

## Validação reproduzível

`python scripts/Test-CodegraphMcp.py <repo> --query <simbolo>` testa handshake,
descoberta e consulta via stdio. Usa modo sem daemon e sem watcher, com
telemetria e download automático desabilitados apenas no processo de teste.
Pode reconciliar o índice existente; não inicia indexação de projeto novo.

Meça tarefas equivalentes com e sem grafo: resposta correta, tempo, chamadas,
tokens e memória. Não publique economia percentual sem um A/B controlado.
Os benchmarks upstream não certificam desempenho nos produtos do HUB.

## Verificação em 2026-09-09

- CLI e handshake MCP: versão 1.6.0, ferramenta `codegraph_explore` disponível.
- Consultas em `erpclass-admin` e `erpclass-api`: código e relações retornados.
- Piloto Delphi: 2 arquivos, ligação do evento DFM ao método Pascal reconhecida.
- Worktree isolada: consulta retornou o método exclusivo da branch de teste.
- ERP Delphi completo: 7.003 arquivos, 435.798 nós e 627.933 relações;
  consulta MCP a `source/Login.pas` retornou símbolos e código do arquivo.
- Distribuição direcionada: 32 projetos; configurações existentes atualizadas,
  demais servidores preservados. ERP Delphi recebeu a configuração CodeGraph.
- Telemetria local desligada; templates e fallback global usam DO_NOT_TRACK=1.
- Testes de configuração e integração executados; sem benchmark A/B de tokens.

A auditoria final encontrou 33 configurações Cursor com CodeGraph e confirmou
DO_NOT_TRACK=1 em todas, incluindo configurações já corretas antes desta execução.
O banco Delphi foi incluído no .gitignore do ERP.

