# ECC selecionado no AgentHub

Integração de seis skills de [affaan-m/ECC](https://github.com/affaan-m/ECC),
revisão `8321021c54d670126ce3b2969d5deb880b4b0c2a`. O submodule `vendor/ecc`
preserva a fonte original; as adaptações distribuídas são arquivos versionados
em `skills/`, com licença MIT e atribuição em cada pasta.

| Skill | Distribuição |
|---|---|
| contract-first | Famílias Angular e NestJS |
| api-design | Família NestJS |
| e2e-testing | Angular e projetos `*-www` / `*-ajuda` |
| skill-stocktake | Manutenção: skills locais do hub; pessoais do Codex com `-GlobalSkills` |
| eval-harness | Mesmo escopo de manutenção |
| security-scan | Mesmo escopo de manutenção |

O catálogo `ecc.skills` separa origem e escopo. Nenhuma outra skill ECC é
distribuída. O checkout contém o restante do repositório apenas como fonte;
seus hooks, plugin, regras e instalador não são ativados.

## Instalar e verificar

```powershell
# Apenas as seis skills; respeita .env, exclusões e detecção de IDEs do hub.
./scripts/Sync-EccSkills.ps1 -GlobalSkills -DryRun
./scripts/Sync-EccSkills.ps1 -GlobalSkills
./scripts/Test-EccInstallation.ps1 -GlobalSkills
./scripts/tests/Test-Ecc.ps1
python -m unittest discover -s scripts/tests -v
```

O instalador completo `Install-AgentHub.ps1` também conhece os escopos ECC.
O sync específico não altera MCP, AGENTS.md, hooks, código dos produtos ou
skills de outros fornecedores. Colisões com diretórios manuais são preservadas
e avisadas. Reabra a sessão do agente para atualizar a descoberta de skills.
Links no disco não comprovam carregamento pela IDE.

Para uma máquina nova, use o clone com submodules do hub. As seis adaptações
funcionam sem executar o instalador ECC. Os utilitários opcionais do eval-harness
exigem o checkout original: `git submodule update --init -- vendor/ecc`.

## Adaptações e dependências

- **contract-first / api-design:** DTOs/Swagger, envelopes e convenções dos
  produtos prevalecem. Referências genéricas ficam sob demanda em `reference.md`.
- **e2e-testing:** exemplos corrigidos para listener antes da ação, assertions
  de UI, tracing do Playwright Test e `outputDir`. Usa a versão instalada no
  projeto; não instala Playwright ao carregar a skill.
- **skill-stocktake:** Python padrão, sem Bash/jq/hooks. Hash de conteúdo e
  arquivos auxiliares, aliases por caminho resolvido, uso desconhecido (`null`).
  Inventário incompleto não gera comparação de remoções. Não executa instruções
  das skills nem produz vereditos de qualidade automaticamente.
- **eval-harness:** workflow independente de `/eval`; utilitários opcionais em
  `vendor/ecc/scripts/`. A recusa upstream `gate.isolation_required` permanece.
  Não constitui um executor isolado de candidatos.
- **security-scan:** wrapper somente `scan --format json`, pacote
  `ecc-agentshield@1.6.0`, Node 20+. Primeira execução usa npm para baixar o pacote.
  Sem `--fix`, `init`, `--opus` ou hooks. Fixação de versão direta não substitui
  revisão das dependências transitivas resolvidas pelo npm. A cobertura de cada
  arquivo/IDE deve ser comprovada, complementando com revisão manual.

## Atualizar e remover

ECC fica fora de `-UpdateVendors`: atualizar a fonte requer revisar as seis
adaptações, atualizar a revisão no catálogo e validar antes de gravar o gitlink.
Não copie novamente os SKILL.md originais sobre os adaptados.

Para remover uma atribuição, esvazie sua família/padrão ou desative `maintenance`
no catálogo e rode o sync. Ele remove somente os links ECC gerenciados daquele
escopo. Mantenha a entrada no catálogo durante a limpeza. O uninstall geral
também reconhece os links para `skills/`; skills pessoais exigem `-GlobalSkills`.
Links locais do próprio hub podem ser removidos colocando todas as seis entradas
sem escopo e rodando o sync. Nenhuma rotina apaga o vendor ou os arquivos fonte.

## Evidências desta integração

- Cenários revisados: preservação de DTO/Swagger e envelope existente, corrida de
  resposta Playwright, deduplicação de junctions sem telemetria, comando `/eval`
  ausente e cobertura por arquivo do scanner.
- Testes ECC incluem seleção exata, famílias, dry-run, reinstalação, remoção de
  atribuição, colisão manual, junction real, licença e recusa do runtime.
- A suíte legada `Test-Integration.ps1` tem uma expectativa incompatível com o
  catálogo atual: exige codegraph no Delphi, cuja lista está vazia. Essa falha
  preexistente permanece fora do escopo ECC; a seleção Delphi não foi alterada.
- Verificação final: 20 testes Python e testes ECC passaram; 227 links de skills
  foram conferidos em 31 projetos mais os escopos de manutenção. O novo dry-run
  não propôs alterações. AgentShield detectou a permissão ampla inserida numa
  configuração fictícia, retornando código 1 por achados.
- O inventário do hub identifica corretamente 47 fontes de skills e sinaliza
  `skills/delphi-erpclass` sem SKILL.md. Por isso esse inventário fica incompleto
  e não serve de baseline incremental até resolver a pasta preexistente; isso
  não impede os demais usos das seis skills.
