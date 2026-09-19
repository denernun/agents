# Design UI — {{PROJECT}}

> **Ponteiro, não spec.** O design system canônico das famílias CLASS vive na
> skill `coreui-styling` no AgentHub (`D:\AGENTS\skills\coreui-styling\`):
> `design-system.md` (spec) + `reference/styles/` (SCSS canônico) +
> `reference/layout-shared/` (componentes). Este arquivo **não copia** a spec e
> **não referencia o design de outro projeto** — só aponta para a skill e lista
> as exceções documentadas deste projeto.

## Fonte da verdade (ordem de precedência)

1. **Skill `coreui-styling`** → `design-system.md` + `reference/styles/`
   (os 4 SCSS deste projeto devem ser **byte-idênticos** à referência).
2. **Este arquivo** → só pode *estreitar* a spec com exceções documentadas
   abaixo. **Nunca** contradiz nem substitui a skill.
3. **CoreUI docs** → https://coreui.io/bootstrap/docs/getting-started/introduction/

Se algo aqui parecer conflitar com a skill, **a skill vence**. Uma divergência
não documentada é defeito a corrigir, não escolha.

## Como registrar uma exceção

Só é exceção legítima o que estiver listado abaixo. Cada entrada precisa de:

- **O quê** diverge (componente / tela / token / propriedade).
- **Por quê** a spec canônica não consegue expressar.
- **Onde** vive — um `src/styles/custom/_<feature>.scss` sobre o SCSS canônico,
  ainda lendo tokens `--ds-*`. Nunca editar os 4 arquivos canônicos, nunca criar
  um segundo sistema de tokens.
- **Escopo** — restrito a este projeto; não vira default para os outros.

Se a exceção seria útil em todos os projetos, ela **não é exceção**: promova
para a skill `coreui-styling` (spec + `reference/`) e sincronize.

## Exceções documentadas deste projeto
<!-- Mantenha as exceções abaixo. Install-AgentHub preserva esta seção. -->
<!-- Nenhuma exceção registrada. Se este projeto não tem desvio, mantenha vazio. -->
