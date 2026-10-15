# Auditoria técnica (resumo)

Fontes realmente examinadas: o ZIP do repositório `primeiro-jogo` (8 arquivos) e o texto
"Lupi Game API Reference" fornecido na conversa. `github.com` e `lupi.api.br/docs` bloqueiam acesso
automatizado, portanto **não** li o site da documentação nem exemplos adicionais da SDK.

1. **Início:** `game.lua` define `update()`; a cada chamada incrementa `Frame` e chama `loop(Frame)`, definida em
   `main.lua` (repositório; API Reference: "Main callback: update(frame), 60 vezes por segundo").
   `lupi.yaml` tem só `name`, `public`, `version`.
2. **Desenho:** `ui.rectfill`, `ui.rect`, `ui.line`, `ui.print`, `ui.cls`, `ui.clip`, `ui.camera`
   (API Reference, Graphics). Tela 480×270, paleta indexada de 256 cores, registrada a cada quadro com
   `ui.palset(i, rgb555)` (API Reference e `main.lua`).
3. **Controles:** `ui.btn(id)` → `false` ou pressão 0-255; constantes `LEFT RIGHT UP DOWN BTN_Z BTN_X BTN_F BTN_G`
   (API Reference, Input). Usado apenas o estado "segurado".
4. **Ciclo:** `update` a 60 FPS, sem delta de tempo documentado → temporização em quadros.
5. **Restrições:** sem assets na v1; módulos `palette` e `sprites` são exigidos por `main.lua` mas não estão no
   repositório (embutidos, presumivelmente); só cores da paleta DB32 (`db32.png`); `ui.print` sem métricas
   de fonte documentadas; versão de Lua não documentada.
6. **Executar/testar:** nenhum comando ou emulador documentado. Lógica testada em Lua convencional; desenho
   validado contra um `ui` simulado que reproduz as assinaturas da API Reference.
7. **Dúvidas abertas:** semântica exata de `Palette.hex`; métricas da fonte; cantos inclusivos/exclusivos de
   `rect`/`rectfill`; versão de Lua; rótulos físicos dos botões; se a pasta `tests/` é empacotada com o jogo;
   comportamento de repetição de `ui.btnp` (não usado); armazenamento persistente (não usado).

## Divergências registradas

- API Reference: `update(frame)` recebe o número do quadro. Repositório: `update()` sem argumento, com contador
  próprio. Mantida a convenção do repositório (fonte mais específica).
- API Reference (exemplo): `ui.cls(1)` e paleta de índices 0-99. Repositório: `ui.cls(Palette.hex(...))` com
  paleta DB32. Seguido o repositório.

## APIs usadas e origem

| API | Origem |
|---|---|
| `update`, `loop` | `game.lua`, `main.lua` |
| `ui.palset`, `ui.clip`, `ui.camera`, `ui.cls`, `ui.print` | `main.lua` e API Reference |
| `ui.rect`, `ui.rectfill`, `ui.line` | API Reference |
| `ui.btn` e constantes de botão | API Reference |
| `Palette`, `Palette.hex` | `main.lua` (módulo `palette`, não visível) |
| `require "palette"`, `require "sprites"` | `main.lua` (mantidos) |

Não usados: `ui.btnp`, `ui.spr`, `ui.tile`, `ui.fillp`, `ui.layout`, `sfx.*`.
