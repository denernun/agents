# Referência técnica — FireDAC, threads, ACBr, build

Carregue só a seção que interessa. Adaptado do plugin `delphi-dev`
(MIT, Adriano Santos), filtrado para o ERP (VCL, Win32, Firebird).

## FireDAC

### Padrão de query

```pascal
procedure TClienteRepository.Salvar(ACliente: ICliente);
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := 'INSERT INTO CLIENTE (NOME, ATIVO) VALUES (:NOME, :ATIVO)';
    LQuery.ParamByName('NOME').AsString := ACliente.Nome;
    LQuery.ParamByName('ATIVO').AsBoolean := ACliente.Ativo;
    LQuery.ExecSQL;
  finally
    LQuery.Free;
  end;
end;
```

Vazamentos típicos: query como campo da classe sem `Free` no destructor; query
criada com `Owner = Self` dentro de método.

### "Object factory for class {GUID} is missing"

Uma unit FireDAC que se registra no `initialization` não está no link. Inclua
na unit de conexão (`domain/connection/provider/firedac/`) conforme o uso:

| Para | Unit |
|---|---|
| Firebird | `FireDAC.Phys.FB`, `FireDAC.Phys.FBDef` |
| `Open`/`Fetch` de query | `FireDAC.DApt` |
| Filtro client-side com expressão | `FireDAC.Stan.ExprFuncs` |
| Wait cursor no ERP (VCL) | `FireDAC.VCLUI.Wait` |
| Wait cursor em console/serviço (API Horse) | `FireDAC.ConsoleUI.Wait` |

Ter a unit no `uses` só registra a classe; o `TFDGUIxWaitCursor` também
precisa existir como instância (componente no DataModule ou criado no boot).

### Access Violation "Read of address 0" em todo acesso ao banco (console)

App sem GUI (Horse, serviço) linkando `FireDAC.VCLUI.Wait`: o wait cursor tenta
usar `Screen`/`Application`, que não existem → AV na primeira query. Se a
conexão abre no `initialization`, o pool fica vazio e todo request cai no mesmo
nil deref. Correção: `FireDAC.ConsoleUI.Wait`.

### `[FB]-314 Cannot load vendor library [fbclient.dll] ... unsupported architecture`

O `fbclient.dll` precisa ter a bitness **do processo** (ERP Win32 → fbclient
x86). A bitness do servidor Firebird é irrelevante. Para checar uma DLL: offset
`0x3C` → PE header; campo Machine `0x14C` = x86, `0x8664` = x64.

### Exceção engolida

`try/except` vazio em DAO/sincronização faz o app "travar sem erro" quando todo
acesso ao banco falha. Ao diagnosticar, procure `except` silencioso antes de
investigar thread/rede.

## Threads

- Prefira `TTask` (pool da PPL) a `TThread` herdado para trabalho pontual.
- `TThread.Synchronize`: bloqueia até a UI executar — use quando precisa do
  resultado. `TThread.Queue`: não bloqueia — progresso/notificação.
- Resultado de task: `IFuture<T>` (`LFutura.Value` bloqueia até terminar).
- Cancelamento: `LTask.Cancel` e, dentro da task, `TTask.CurrentTask.CheckCanceled`.
- Estado compartilhado: `TCriticalSection` (ou `TMonitor`) sempre com
  `Enter` + `try/finally Leave`.
- Conexão FireDAC **não** é thread-safe: cada thread usa a própria conexão
  (ou uma do pool), nunca a do form/DataModule principal.

```pascal
// ERRADO: a closure captura a variável do laço, não o valor
for LId in LIds do
  TTask.Run(procedure begin Processar(LId); end);

// CERTO: cópia local por iteração (closure dentro de método auxiliar)
for LId in LIds do
  DispararProcessamento(LId);   // procedure DispararProcessamento(AId: Integer)
                                //   → TTask.Run(procedure begin Processar(AId); end)
```

O parâmetro de um método auxiliar é a forma garantida de capturar por valor;
uma variável local declarada fora do laço continua sendo uma única variável.

## ACBr (NFe, NFCe, NFSe, Boleto)

- NFCe/NFe: conversões em `pcnConversaoNFe`, não `pcnConversao`.
- `IdCSC` é `string` — atribuir número trunca zeros à esquerda.
- PDF do DANFE: `DANFE.PathPDF`, não `Configuracoes.Arquivos.PathSalvar`.
- PIX: `fpPagamentoInstantaneo`.
- Chave de acesso: 44 dígitos — extraia/valide antes de usar como nome de arquivo.
- `ForceDirectories` com caminho relativo depende do diretório corrente; use
  caminho absoluto a partir do exe.
- `SSLLib := libNone` só em teste local; nunca deixe isso no fluxo real.
- Regras tributárias ficam em `docs/reforma/` e `source/docs/Reforma.txt`.

## Build com log

`compilar.bat` (raiz → `source\compilar.bat`) não grava log. Para o agente:

```powershell
& cmd.exe /c '"D:\SISTEMAS\ERPCLASS\erpclass-erp\compilar.bat" --no-pause > "%TEMP%\erp_build.log" 2>&1'
```

Depois leia o log e procure `error E`, `error F`, `Fatal`. Corrija o primeiro
erro e recompile.

| Erro | Causa típica |
|---|---|
| E2003 | Identificador não declarado — typo ou unit faltando no `uses` |
| F1026 / F2613 | Unit não encontrada — `uses` ou search path |
| E2010 | Tipos incompatíveis |
| MSB6003 | Linha de comando longa demais — paths/defines excessivos |

Não use `Set-Location` + `cmd /c compilar.bat`: o `cmd` filho não herda o cwd.
Use caminho absoluto entre aspas.
