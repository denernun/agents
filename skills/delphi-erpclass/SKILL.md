---
name: delphi-erpclass
description: Implementar e revisar código Delphi VCL do ERPCLASS, preservando compatibilidade com o legado, formulários e acesso a dados.
---

# Delphi ERPCLASS

Leia as instruções do projeto e o código próximo à alteração para identificar as convenções reais. A stack do catálogo é Delphi 12/VCL, Firebird, FireDAC/UniDAC, ACBr e Horse; confirme quais componentes a unidade utiliza antes de propor mudanças.

- Prefira Domain e Providers/Services para código novo, seguindo os exemplos existentes. Evite ampliar unidades globais como `Global.pas` e `Funcoes.pas`.
- Preserve encoding e finais de linha dos arquivos `.pas` e `.dfm`. Confira o diff, especialmente acentos e propriedades de formulários.
- Mantenha nomes de componentes e handlers sincronizados entre PAS e DFM. Preserve alterações ainda abertas no IDE; use ferramentas do RAD Studio quando disponíveis.
- Preserve contratos públicos, transações e tratamento de exceções. Use parâmetros em consultas SQL e confira a propriedade dos objetos antes de alterar seu ciclo de vida.
- Consulte a documentação de domínio em `../erpclass-docs/source/` quando existir e for relevante à tarefa.
- Compile com a configuração e plataforma utilizadas pelo projeto quando o compilador estiver disponível. Relate os testes executados e qualquer validação que dependa do RAD Studio ou de serviços indisponíveis.
