---
name: delphi-erpclass
description: Convenções do ERP Delphi/VCL da ERPCLASS (Delphi 12, Firebird, FireDAC/UniDAC, ACBr, Horse). Use ao editar .pas/.dfm/.dpr/.inc em projetos *-erp, ao criar unit nova em domain/providers/services, ao mexer em form legado, ou quando houver risco de encoding ANSI/UTF-8.
---

# ERPClass — Delphi / VCL

Base legada grande e viva: ~2.275 `.pas` e ~1.255 `.dfm`. A regra geral é
**somar código novo na estrutura organizada, sem reescrever o legado** e sem
inflar os utilitários globais.

## Antes de editar

1. **Plano curto e confirmação** antes de alterar código, salvo pedido trivial
   ou "pode fazer". Mudança em ERP mexe em faturamento/fiscal.
2. Use `codegraph_explore` (skill `codegraph`) antes de grep amplo: o índice já
   devolve símbolo + chamadores + blast radius numa chamada.
3. Responda em **português**; identificadores em código seguem o padrão do
   arquivo que você está editando (a base é mista).

## Encoding — a regra que mais quebra build

`.pas` e `.dfm` do legado estão em **ANSI (CP1252)**, os novos em UTF-8.

- **Nunca** converta o encoding de um arquivo existente.
- **Nunca** faça edição cega em linha com acento: leia a linha, confirme os
  bytes, só então edite. Uma reescrita "inofensiva" de arquivo inteiro troca o
  encoding e corrompe todos os acentos do form.
- `.dfm` é recurso compilado no binário: acento corrompido vira texto quebrado
  em tela, não erro de compilação. Não aparece no teste, aparece no cliente.
- Há `dfm-to-txt.bat` na raiz para inspecionar `.dfm` binário.

## Onde colocar código novo

`source/` está organizado por responsabilidade — respeite a pasta:

| Pasta | O que vai aqui |
|---|---|
| `domain/` | regra de negócio, query builders, comparers |
| `providers/` | integrações e acesso externo (a maior: ~406 units) |
| `services/` | serviços de aplicação (cache, computer, etc.) |
| `builders/` | montagem de consultas/pesquisas |
| `helpers/` | helpers de tipo (`DateTimeHelper`, `JSONHelper`) |
| `enums/`, `types/`, `constants/` | vocabulário e constantes |
| `exception/` | hierarquia de exceção (`ExceptionsBase`) |
| `modules/`, `view/` | forms e telas |
| `utils/` | **legado** — `Global.pas`, `Funcoes.pas` |

**Não expanda `source/utils/Global.pas` nem `Funcoes.pas`.** Eles são o depósito
histórico; código novo entra em `domain/`, `providers/` ou `services/` com
interface própria. Adicionar mais uma função global é a dívida que já existe.

## Nomenclatura de unit

Namespace pontuado, do geral para o específico:

```
Query.Builder.pas            Query.Builder.Interfaces.pas
Cache.Service.pas            Cache.Interfaces.pas
Comparer.Connection.pas      Enums.Canais.pas
```

Interface separada da implementação (`*.Interfaces.pas`) quando houver mais de
um implementador ou necessidade de fake em teste.

## Forms VCL — sequência das rotinas

Ordem correta (está em `source/docs/Docs.txt`):

```
CreateParams → FormCreate → FormShow → FormKeyPress → FormKeyDown
```

Padrão de navegação por Enter já estabelecido no projeto:

```pascal
// FormKeyPress
if (Key = #13) then
begin
  Key := #0;
  Perform(Wm_NextDlgCtl, 0, 0);
end;
```

Coloque inicialização que depende de handle em `CreateParams`/`FormShow`, não em
`FormCreate`.

## Documentação que já existe no repo

Antes de perguntar ou inventar, leia `source/docs/`:

| Arquivo | Assunto |
|---|---|
| `Docs.txt` | sequência de forms, padrões de relatório, fluxo de `version.inc` |
| `Observer.txt` | padrão observer com tipo de evento (`procedure ... of object`) |
| `Grids.txt` | convenções de grid |
| `API.txt` | integração HTTP |
| `Reforma.txt` | reforma tributária |
| `Firestore.txt` | integração Firestore |

Regras fiscais detalhadas estão em `docs/reforma/`. Não duplique esse conteúdo
em código nem nesta skill — referencie.

## Relatórios

Largura fixa por número de colunas (80 / 96 / 132 / 136), com helpers `tb*`
(`tbStrZero`, `tbPadR`). Copie o cabeçalho do relatório de mesma largura em vez
de recalcular posição; os exemplos exatos estão em `source/docs/Docs.txt`.

## version.inc

`source/version.inc` é versionado mas mantido local com
`git update-index --assume-unchanged`. **Não** faça commit de alteração de
versão sem pedido explícito — isso troca a versão publicada.

## Ao concluir

- Compile antes de afirmar que está pronto (`compilar.bat` na raiz).
- Se alterou `.dfm`, confirme os acentos em tela, não só a compilação.
- Descreva o que foi verificado e o que não foi.
