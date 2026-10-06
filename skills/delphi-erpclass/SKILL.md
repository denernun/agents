---
name: delphi-erpclass
description: Convenções do ERP Delphi/VCL da ERPCLASS (Delphi 12, Firebird, FireDAC/UniDAC, ACBr, Horse). Use ao editar .pas/.dfm/.dpr/.inc em projetos *-erp, ao criar unit nova em domain/providers/services, ao mexer em form legado, query FireDAC, TTask/threads, emissão ACBr (NFe/NFCe/NFSe/boleto), ao compilar e diagnosticar erro de build, ou quando houver risco de encoding ANSI/UTF-8.
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

## Banco, threads e ACBr — regras curtas

Detalhe e exemplos em [`tecnico.md`](tecnico.md); leia a
seção correspondente antes de mexer nesses pontos.

- **SQL só parametrizado** (`ParamByName(...).AsInteger`, tipo certo, nunca
  `AsString` em número). Não concatene valor em SQL, nem em código novo nem ao
  tocar um trecho legado que já concatena.
- **Query local vive no método**: `Create(nil)` + `try/finally Free`. Nunca
  `Owner = Self` dentro de método (só libera quando o form fecha).
- **Escrita múltipla em transação explícita** (commit/rollback no mesmo método).
- **Nada de VCL fora da thread principal**: só via `TThread.Synchronize`
  (precisa do resultado) ou `TThread.Queue` (notificação). Variável de laço
  capturada em closure precisa de cópia local antes do `TTask.Run`.
- **ACBr é fiscal**: não altere configuração de certificado/SSL/ambiente
  (homologação × produção) sem pedido explícito; veja as armadilhas de NFe/NFCe
  na referência.

## Legado — ordem de modernização

Só modernize quando o pedido for esse, e nesta ordem: (1) SQL seguro no trecho
tocado → (2) extrair interface → (3) teste de caracterização travando o
comportamento atual → (4) refatorar com o teste protegendo. Encoding **não**
entra nessa lista (ver acima) e não saia removendo `with` em massa.

## Ao concluir

- Compile antes de afirmar que está pronto: `compilar.bat --no-pause`
  redirecionando a saída para um log (ver referência) e leia o **primeiro**
  erro do log — os seguintes costumam ser cascata. Não confie só no exit code.
- Se alterou `.dfm`, confirme os acentos em tela, não só a compilação.
- Descreva o que foi verificado e o que não foi.
