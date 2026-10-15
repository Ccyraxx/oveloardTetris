local UiMock = require "ui"
local App = require "ov_app"
local Session = require "ov_session"
local Render = require "ov_render"
local Theme = require "ov_theme"

local CHAR_W = 8 -- pior caso assumido: a largura da fonte não está documentada

local function setup()
    require "palette"
    UiMock.install_constants()
    local ui, log = UiMock.new()
    rawset(_G, "ui", ui)
    return log
end

local function playing_app(seed)
    local app = App.new()
    app.scene, app.session = "playing", Session.new({ seed = seed or 4 })
    return app
end

local function check_inside_screen(log)
    for _, r in ipairs(log.rects) do
        for i = 2, 5 do
            local v = r[i]
            local limit = (i == 2 or i == 4) and 479 or 269
            assert(v >= 0 and v <= limit, r[1] .. " fora da tela: " .. v)
        end
    end
    for _, t in ipairs(log.texts) do
        assert(t[2] >= 0 and t[3] >= 0 and t[3] <= 262, "texto fora da tela: " .. t[1])
        assert(t[2] + #t[1] * CHAR_W <= 480, "texto estoura a largura (8px/char): " .. t[1] .. " x=" .. t[2])
    end
end

return function(T)
    T.test("render: cores do tema existem na paleta e so usam DB32", function()
        setup()
        T.eq(#Palette, 32)
        for name, c in pairs(Theme.colors) do T.truthy(c >= 0 and c < 32, name) end
        T.eq(#Theme.piece_colors, 7)
        local seen = {}
        for kind = 1, 7 do
            T.falsy(seen[Theme.piece_colors[kind]], "cores de peca repetidas")
            seen[Theme.piece_colors[kind]] = true
        end
    end)

    T.test("render: todas as cenas usam so a API documentada, dentro da tela", function()
        local log = setup()
        local app = App.new()
        for frame = 0, 70, 10 do Render.draw(app, frame) end -- titulo (com e sem cursor)
        app.scene, app.session = "playing", Session.new({ seed = 3 })
        for frame = 0, 70, 10 do Render.draw(app, frame) end
        app.scene = "paused"
        Render.draw(app, 0)
        app.scene = "gameover"
        app.session.over, app.session.piece = true, nil
        for _, t in ipairs({ 0, 30, 60 }) do app.timer = t; Render.draw(app, t) end
        check_inside_screen(log)
    end)

    T.test("render: tabuleiro cheio, carga critica e proxima peca de cada tipo", function()
        local log = setup()
        local app = playing_app()
        local b = app.session.board
        for y = 3, 19 do for x = 0, 9 do b:set(x, y, (x + y) % 7 + 1) end end
        app.session.load = 0.9
        for kind = 1, 7 do
            app.session.next_kind = kind
            Render.draw(app, kind * 7)
        end
        check_inside_screen(log)
    end)

    T.test("render: texto dos paineis nao invade o tabuleiro (fonte de 8px)", function()
        local log = setup()
        local app = playing_app()
        Render.draw(app, 0)
        local L = Theme.layout
        for _, t in ipairs(log.texts) do
            local right = t[2] + #t[1] * CHAR_W
            if t[2] < L.board_x then
                assert(right <= L.board_x - 4, "painel esquerdo invade o tabuleiro: " .. t[1])
            else
                assert(t[2] >= L.board_x + 10 * L.cell + 4, "painel direito invade o tabuleiro: " .. t[1])
            end
        end
    end)

    T.test("render: tabuleiro ocupa a area prevista e e o maior elemento", function()
        local log = setup()
        local app = playing_app()
        Render.draw(app, 0)
        local L = Theme.layout
        local found = false
        for _, r in ipairs(log.rects) do
            if r[1] == "rectfill" and r[2] == L.board_x and r[3] == L.board_y then
                found = true
                T.eq(r[4] - r[2] + 1, 10 * L.cell)
                T.eq(r[5] - r[3] + 1, 20 * L.cell)
            end
        end
        T.truthy(found, "fundo do tabuleiro nao desenhado")
    end)

    T.test("render: blocos acima do topo do tabuleiro nao sao desenhados", function()
        local log = setup()
        local app = playing_app()
        app.session.piece = { kind = 1, rot = 2, x = 3, y = -1 } -- I vertical: um bloco na linha -1
        Render.draw(app, 0)
        local L = Theme.layout
        local inside_board_cols = 0
        for _, r in ipairs(log.rects) do
            if r[1] == "rectfill" and r[2] >= L.board_x and r[2] < L.board_x + 10 * L.cell then
                T.truthy(r[3] >= L.board_y, "bloco desenhado acima do tabuleiro: y=" .. r[3])
                inside_board_cols = inside_board_cols + 1
            end
        end
        T.truthy(inside_board_cols > 0)
    end)

    T.test("render: status segue a carga", function()
        local s = Session.new({ seed = 1 })
        T.eq((Render.status(s)), "SYSTEM ONLINE")
        s.ticks = 1000
        T.eq((Render.status(s)), "PROCESSING DATA")
        s.load = 0.5
        T.eq((Render.status(s)), "MEMORY PRESSURE")
        s.load = 0.75
        T.eq((Render.status(s)), "CRITICAL LOAD")
        s.over = true
        T.eq((Render.status(s)), "SYSTEM FAILURE")
    end)

    T.test("render: tela inicial mostra o mapeamento de controles", function()
        local log = setup()
        Render.draw(App.new(), 0)
        local all = {}
        for _, t in ipairs(log.texts) do all[#all + 1] = t[1] end
        local text = table.concat(all, "|")
        for _, word in ipairs({ "LEFT", "RIGHT", "DOWN", "ROTATE CW", "ROTATE CCW", "PAUSE", "BOOT" }) do
            T.truthy(string.find(text, word, 1, true), "falta '" .. word .. "' na tela inicial")
        end
    end)

    T.test("render: bloco individual pode ser trocado em um unico ponto", function()
        local log = setup()
        local calls = 0
        local original = Render.cell
        Render.cell = function(...) calls = calls + 1; return original(...) end
        local app = playing_app()
        Render.draw(app, 0)
        Render.cell = original
        T.truthy(calls >= 5, "peca atual (4) + proxima (4) devem passar por Render.cell")
    end)
end
