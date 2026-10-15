# LUPI — SYSTEM OVERLOAD

Puzzle de blocos descendentes para o console Lupi, sobre a base `primeiro-jogo`.
Você administra um sistema que recebe blocos de dados sem parar: organize-os, libere
memória removendo linhas e não deixe a carga chegar ao limite.

100% código Lua: **sem imagens, fontes ou áudio externos**, sem internet.

## Estado de verificação (leia antes de usar)

| Categoria | Situação |
|---|---|
| Testes automatizados da lógica (70) | **Executados e aprovados** em Lua 5.3 e 5.4 convencionais |
| Execução do jogo com `ui` simulado (valida a API documentada) | **Executada**: `game.lua` → `main.lua`, do título ao game over e reinício |
| Verificação estática de compatibilidade | **Feita** (sem sintaxe 5.3+, sem `os`/`io`/`string.*`) |
| Execução na SDK/emulador oficial do Lupi | **NÃO realizada** (sem acesso) |
| Teste no console Lupi físico | **NÃO realizado** (sem acesso) |

Passar nos testes prova que a lógica está correta e que o jogo só chama funções da API
documentada com a assinatura correta. **Não prova** que ele funciona na SDK real: veja
"Premissas não confirmadas" abaixo.

## Controles

Nomes das constantes da SDK (`BTN_Z` etc.); o rótulo físico de cada uma depende do console.

| Botão | Ação |
|---|---|
| `LEFT` / `RIGHT` | Mover (segure para repetir: atraso de 12 quadros, depois a cada 4) |
| `DOWN` | Queda acelerada (+1 ponto por linha). Precisa soltar e apertar de novo a cada peça |
| `BTN_Z` | Girar horário; também inicia/reinicia a partida |
| `BTN_X` | Girar anti-horário |
| `BTN_F` | Pausar / retomar |
| `BTN_G` | Na pausa: voltar à tela inicial |

A tela inicial exibe este mapeamento.

## Regras implementadas

- 7 peças tradicionais, sorteadas em "sacos" de 7 (todas aparecem uma vez por saco). Próxima peça visível.
- Tabuleiro 10×20. Rotação **sem compensação de parede**: se a posição resultante for inválida, nada muda.
- A peça trava no primeiro quadro de descida em que não consegue descer (sem atraso de trava).
- Linhas completas são removidas juntas. Pontos: 100 / 300 / 500 / 800 para 1–4 linhas, × nível
  (nível anterior à subida causada por essas linhas).
- Nível = 1 + linhas ÷ 10, máximo 15. A queda vai de 1 linha a cada 48 quadros (nível 1) até 1 quadro (nível 15).
- Game over quando uma peça nova não cabe na entrada, ou quando uma peça trava parcialmente acima do topo.
- Estado do sistema pela altura da pilha: `SYSTEM ONLINE` / `PROCESSING DATA` →
  `MEMORY PRESSURE` (≥ 50 %) → `CRITICAL LOAD` (≥ 75 %, pisca) → `SYSTEM FAILURE`.
- Após o game over há 45 quadros em que o botão de reinício é ignorado (evita reiniciar martelando o giro).

**Não implementados:** reserva de peça (hold), queda instantânea, peça-fantasma, animações, áudio, recordes.

## Executar

O repositório oficial não traz comando de execução nem empacotamento, e a documentação a que tive
acesso não os descreve. Use o procedimento padrão do Lupi para abrir esta pasta: o ponto de entrada
continua sendo o do repositório original (`game.lua` define `update()`, que chama `loop(frame)` em `main.lua`).
`lupi.yaml` não foi alterado.

## Testes

Na raiz do projeto, com Lua 5.3 ou 5.4 instalado (nenhuma outra dependência):

```
lua tests/run.lua
```

Sai com código ≠ 0 se algum teste falhar. Cobertura: formas e rotação das peças, tabuleiro, colisões
(paredes, piso, blocos), rotação válida/inválida, gravidade e velocidade por nível, queda acelerada,
fixação, remoção de 1 e 4 linhas e reorganização, pontuação, progressão de dificuldade, game over
(entrada bloqueada e fixação acima do topo), reinício completo, repetição de movimento, fluxo de telas,
layout (nada fora da tela nem sobre o tabuleiro, supondo fonte de 8 px por caractere) e uma execução
de ponta a ponta de `game.lua`.

`tests/mocks/` contém **simulações** de `palette`, `sprites` e `ui`, usadas só pelos testes e nunca
carregadas pelo jogo. O mock de `ui` implementa apenas as funções documentadas e falha em qualquer outra
função, assinatura errada, coordenada não inteira ou cor fora da paleta.

## Arquitetura

Arquivos na raiz, com prefixo `ov_` para não colidir com módulos embutidos da SDK (`palette`, `sprites`).
Subpastas não são usadas porque o repositório só demonstra `require` de arquivos na raiz.

| Arquivo | Responsabilidade | Conhece a SDK? |
|---|---|---|
| `game.lua` | Original: `update()` conta quadros e chama `loop` | sim |
| `main.lua` | `loop(frame)`: registra a paleta, liga botões da SDK ao jogo, chama atualização e desenho | sim |
| `ov_settings.lua` | Regras e ritmo (gravidade, pontos, repetição de movimento) | não |
| `ov_pieces.lua` | Geometria das 7 peças **como dados**; rotações geradas na carga | não |
| `ov_board.lua` | Grade lógica: colisão, fixação, remoção de linhas | não |
| `ov_bag.lua` | Sorteio por sacos com gerador próprio (sem depender de `math.random`) | não |
| `ov_session.lua` | Estado da partida: peça, gravidade, pontos, nível, game over, eventos | não |
| `ov_input.lua` | Botões → ações por quadro (borda de subida, repetição) | não (recebe uma função `read`) |
| `ov_app.lua` | Telas: título, partida, pausa, game over | não |
| `ov_theme.lua` | Cores (DB32), posições, textos | só `Palette.hex` |
| `ov_render.lua` | Desenha tudo com `ui.rectfill/rect/line/print` | `ui` |

Decisões principais:

- **Lógica independente de visual:** uma peça é geometria + posição + tipo. Só `ov_render.lua` sabe
  como ela é desenhada.
- **Tempo por quadros:** a única temporização documentada é `update` a 60 FPS. Toda velocidade é
  contada em quadros. Se o console perder quadros, o jogo desacelera junto.
- **Entrada própria:** usa só `ui.btn` (estado segurado) e implementa borda de subida e repetição,
  porque o comportamento de repetição de `ui.btnp` não está documentado.
- **Pouca alocação por quadro:** a lógica não cria tabelas a cada quadro (tabela de ações reutilizada; peças e
  cálculos de carga só na fixação). O desenho ainda monta algumas strings de texto por quadro; não medi o custo no console.
- **Desenho tolerante:** blocos deixam 1 px de vão, de modo que ficam corretos tanto se os cantos de
  `rectfill` forem inclusivos quanto exclusivos.

## Premissas não confirmadas (verifique no console)

1. **`Palette.hex(0xRRGGBB)`** devolve o índice (base 0) da cor na paleta DB32. Vem do módulo embutido `palette`,
   que **não está no repositório**; a premissa vem do uso em `main.lua` original. O jogo usa só cores do `db32.png`.
2. **Fonte de `ui.print`:** largura e altura de caractere não estão documentadas. Todo texto é alinhado à esquerda,
   com no máximo 30 caracteres por linha e 10 px entre linhas. Se a fonte for maior que 8×9 px, pode haver sobreposição.
3. **Cantos de `ui.rect`/`ui.rectfill`:** inclusivos ou exclusivos? Desenho tolerante a ambos (ver acima).
4. **Versão de Lua da SDK:** não documentada. O código evita recursos novos e foi testado em 5.3 e 5.4;
   5.1, 5.2 e LuaJIT **não** foram executados (apenas verificação estática).
5. **`update()` sem argumento:** `game.lua` original não usa o argumento `frame` que a documentação cita.
   Mantive o contador do repositório.
6. O jogo supõe que `math.floor`, `ipairs`, `setmetatable` e `assert` existem (biblioteca padrão).

## Evolução futura — **planejado, nada disto está implementado**

| Ideia | O que mudar |
|---|---|
| Sprites nos blocos | Trocar o corpo de `Render.cell` em `ov_render.lua` por `ui.spr`/`ui.tile`; guardar as referências em `ov_theme.lua`. A lógica não muda |
| Texturas/padrões por tipo de dado | Também em `Render.cell` (ex.: `ui.fillp`) e em `ov_theme.lua` |
| Fonte personalizada | Concentrar as chamadas `ui.print` de `ov_render.lua` na função local `text` e trocá-la |
| Efeitos sonoros e música | `Session` já registra `session.events` por quadro (`move`, `rotate`, `lock`, `clear`, `level`, `over`). Em `ov_app.lua`, depois de `session:update`, percorra esses eventos e chame `sfx.fx(...)`. Música: `sfx.music(...)` ao trocar de cena |
| Animações de transição / efeitos de falha | Novo estado em `ov_app.lua` (cena de transição) e desenho em `ov_render.lua`, usando `app.timer` |
| Novos modos de dificuldade | Novas tabelas em `ov_settings.lua`; `Session.new` receberia a escolhida |
| Recordes persistentes | Depende de armazenamento que não foi verificado na SDK |
| Novos temas | Outro conjunto em `ov_theme.lua` (cores DB32 e posições) |
| Hold, hard drop, peça-fantasma | Regras em `ov_session.lua`, desenho em `ov_render.lua`, botão em `main.lua`/`ov_input.lua` |

Antes de qualquer uma dessas evoluções, confira na documentação da SDK as funções correspondentes.

## Licença

MIT, como no repositório original (`LICENSE`).
