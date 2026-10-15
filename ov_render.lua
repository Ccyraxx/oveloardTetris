-- Renderização: desenha o estado do jogo com retângulos, linhas e texto.
-- Para trocar retângulos por sprites, altere Render.cell (único ponto que desenha um bloco).

local Theme = require "ov_theme"
local Pieces = require "ov_pieces"
local Settings = require "ov_settings"

local C, L = Theme.colors, Theme.layout
local Render = {}

local function text(s, x, y, color) ui.print(s, x, y, color) end

local function pad(n, width)
    local s = tostring(n)
    while #s < width do s = "0" .. s end
    return s
end

local function blink(frame, period)
    return math.floor(frame / period) % 2 == 0
end

-- Texto e cor do estado do sistema, conforme a carga.
function Render.status(session)
    if session.over then return "SYSTEM FAILURE", C.danger end
    if session.load >= Theme.load_critical then return "CRITICAL LOAD", C.danger end
    if session.load >= Theme.load_warn then return "MEMORY PRESSURE", C.warn end
    if session.ticks < Theme.boot_frames then return "SYSTEM ONLINE", C.ok end
    return "PROCESSING DATA", C.ok
end

-- Um bloco de dados. x, y: canto superior esquerdo; size: lado da célula em pixels.
function Render.cell(x, y, size, kind)
    local last = size - 2 -- deixa 1 px de vão entre blocos vizinhos
    ui.rectfill(x, y, x + last, y + last, Theme.piece_colors[kind])
    ui.rectfill(x, y, x + last, y, C.cell_highlight)
    ui.rectfill(x, y, x, y + last, C.cell_highlight)
end

local function window(x0, y0, x1, y1, color)
    ui.rectfill(x0, y0, x1, y1, C.window_bg)
    ui.rect(x0, y0, x1, y1, color)
end

local function draw_board(session, frame, hide_cells)
    local bx, by, cs = L.board_x, L.board_y, L.cell
    local board = session.board
    local w, h = board.w, board.h
    local bw, bh = w * cs, h * cs

    ui.rectfill(bx, by, bx + bw - 1, by + bh - 1, C.board_bg)
    for x = 1, w - 1 do ui.line(bx + x * cs - 1, by, bx + x * cs - 1, by + bh - 1, C.grid) end
    for y = 1, h - 1 do ui.line(bx, by + y * cs - 1, bx + bw - 1, by + y * cs - 1, C.grid) end

    if not hide_cells then
        for y = 0, h - 1 do
            for x = 0, w - 1 do
                local kind = board:get(x, y)
                if kind ~= 0 then Render.cell(bx + x * cs, by + y * cs, cs, kind) end
            end
        end
        local p = session.piece
        if p then
            local cells = Pieces.cells(p.kind, p.rot)
            for i = 1, 4 do
                local y = p.y + cells[i][2]
                if y >= 0 then
                    Render.cell(bx + (p.x + cells[i][1]) * cs, by + y * cs, cs, p.kind)
                end
            end
        end
    end

    local border = C.border
    if session.over then
        border = C.danger
    elseif session.load >= Theme.load_critical then
        border = blink(frame, 15) and C.danger or C.danger_dark
    end
    ui.rect(bx - 2, by - 2, bx + bw + 1, by + bh + 1, border)
end

local function draw_next(kind)
    local cs, x0, y0 = L.next_cell, L.right_x, L.next_y
    ui.rect(x0, y0, x0 + L.next_box, y0 + L.next_box, C.border)
    local minx, miny, maxx, maxy = Pieces.extent(kind)
    local ox = x0 + math.floor((L.next_box - (maxx - minx + 1) * cs) / 2)
    local oy = y0 + math.floor((L.next_box - (maxy - miny + 1) * cs) / 2)
    local cells = Pieces.cells(kind, 1)
    for i = 1, 4 do
        Render.cell(ox + (cells[i][1] - minx) * cs, oy + (cells[i][2] - miny) * cs, cs, kind)
    end
end

local function draw_load(session, frame)
    local x, y, w, h = L.right_x, L.bar_y, L.bar_w, L.bar_h
    local color = C.ok
    if session.load >= Theme.load_critical then
        color = blink(frame, 15) and C.danger or C.danger_dark
    elseif session.load >= Theme.load_warn then
        color = C.warn
    end
    text("MEMORY LOAD", x, y - 12, C.label)
    ui.rect(x, y, x + w, y + h, C.border)
    local fill = math.floor(session.load * (w - 2))
    if fill > 0 then ui.rectfill(x + 1, y + 1, x + fill, y + h - 1, color) end
    text(tostring(math.floor(session.load * 100)) .. "%", x, y + h + 4, color)
end

local function draw_controls(x, y)
    text("CONTROLS", x, y, C.label)
    for i, row in ipairs(Theme.controls) do
        local ry = y + 12 + (i - 1) * L.line_h
        text(row[1], x + L.key_col, ry, C.accent)
        text(row[2], x + L.action_col, ry, C.text)
    end
end

local function draw_hud(session, frame)
    local x, h = L.left_x, L.line_h
    text("SYSTEM OVERLOAD", x, 15, C.accent)
    ui.line(x, 27, x + 160, 27, C.dim)

    local status, color = Render.status(session)
    if color ~= C.danger or session.over or blink(frame, 15) then
        text(status, x, 46, color)
    end
    text("STATUS", x, 36, C.label)
    text("SCORE", x, 72, C.label)
    text(pad(session.score, 7), x, 72 + h, C.text)
    text("LINES", x, 106, C.label)
    text(pad(session.lines, 4), x, 106 + h, C.text)
    text("LEVEL", x, 140, C.label)
    text(pad(session.level, 2), x, 140 + h, C.text)

    text("NEXT", L.right_x, 15, C.label)
    draw_next(session.next_kind)
    draw_load(session, frame)
    draw_controls(L.right_x, 132)
end

local function draw_title(frame)
    local x = 120
    text("LUPI :: SYSTEM OVERLOAD", x, 34, C.accent)
    ui.line(x, 45, x + 240, 45, C.dim)
    text("> SYSTEM ONLINE", x, 58, C.ok)
    text("> DATA STREAM INCOMING", x, 68, C.text)
    text("> ORGANIZE BLOCKS, FREE MEMORY", x, 78, C.text)
    text("> MEMORY FULL = SYSTEM FAILURE", x, 88, C.danger)

    text("CONTROLS", x, 112, C.label)
    for i, row in ipairs(Theme.controls) do
        local ry = 124 + (i - 1) * L.line_h
        text(row[1], x, ry, C.accent)
        text(row[2], x + 64, ry, C.text)
    end
    text("G", x, 124 + 6 * L.line_h, C.accent)
    text("QUIT TO TITLE (PAUSED)", x + 64, 124 + 6 * L.line_h, C.text)

    text(blink(frame, 30) and "PRESS Z TO BOOT_" or "PRESS Z TO BOOT ", x, 214, C.warn)
    for kind = 1, Pieces.COUNT do
        Render.cell(x + (kind - 1) * 16, 238, 12, kind)
    end
end

local function draw_paused()
    window(172, 98, 308, 172, C.border)
    text("PAUSED", 186, 108, C.accent)
    text("F  RESUME", 186, 132, C.text)
    text("G  TITLE", 186, 146, C.text)
end

local function draw_gameover(app, frame)
    window(172, 88, 308, 182, C.danger)
    text("SYSTEM FAILURE", 186, 98, C.danger)
    text("FINAL SCORE", 186, 118, C.label)
    text(pad(app.session.score, 7), 186, 130, C.text)
    if app.timer >= Settings.gameover_lockout and blink(frame, 30) then
        text("Z  REBOOT", 186, 156, C.warn)
    end
end

function Render.draw(app, frame)
    local scene = app.scene
    if scene == "title" then
        draw_title(frame)
        return
    end
    draw_board(app.session, frame, scene == "paused")
    draw_hud(app.session, frame)
    if scene == "paused" then
        draw_paused()
    elseif scene == "gameover" then
        draw_gameover(app, frame)
    end
end

return Render
