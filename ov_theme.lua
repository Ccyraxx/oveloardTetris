-- Configuração de apresentação: cores, posições e textos. Nenhuma regra de jogo aqui.
-- Todas as cores vêm da paleta DB32 do módulo "palette" da SDK (ver db32.png).

require "palette"
assert(Palette and Palette.hex, "ov_theme: o módulo 'palette' da SDK deve fornecer Palette.hex")
local hex = Palette.hex

local colors = {
    bg = hex(0x222034),
    board_bg = hex(0x000000),
    grid = hex(0x323c39),
    border = hex(0x847e87),
    dim = hex(0x595652),
    text = hex(0xffffff),
    label = hex(0x9badb7),
    accent = hex(0x5fcde4),
    ok = hex(0x6abe30),
    warn = hex(0xfbf236),
    danger = hex(0xd95763),
    danger_dark = hex(0xac3232),
    window_bg = hex(0x000000),
    cell_highlight = hex(0xcbdbfc),
}

-- Cor de cada peça, na ordem de ov_pieces.lua: I O T S Z J L.
local piece_colors = {
    hex(0x5fcde4), hex(0xfbf236), hex(0xd77bba), hex(0x99e550),
    hex(0xd95763), hex(0x5b6ee1), hex(0xdf7126),
}

-- Tela 480x270. Textos só alinhados à esquerda (métricas da fonte não documentadas).
local layout = {
    board_x = 180, board_y = 15, cell = 12,
    left_x = 8, right_x = 316,
    line_h = 10,
    next_y = 27, next_box = 44, next_cell = 10,
    bar_y = 94, bar_w = 140, bar_h = 10,
    key_col = 0, action_col = 56, -- deslocamentos da tabela de controles
}

return {
    colors = colors,
    piece_colors = piece_colors,
    layout = layout,
    load_warn = 0.5,      -- a partir daqui: MEMORY PRESSURE
    load_critical = 0.75, -- a partir daqui: CRITICAL LOAD
    boot_frames = 180,    -- quanto tempo a partida mostra SYSTEM ONLINE
    -- { botão na tela, ação }. Os botões são BTN_Z, BTN_X etc. da SDK (ver main.lua).
    controls = {
        { "LEFT", "MOVE LEFT" }, { "RIGHT", "MOVE RIGHT" }, { "DOWN", "SOFT DROP" },
        { "Z", "ROTATE CW" }, { "X", "ROTATE CCW" }, { "F", "PAUSE" },
    },
}
