-- MOCK PARA TESTES do objeto global "ui". Implementa SOMENTE as funções documentadas
-- em Lupi Game API Reference e valida assinatura e tipos de cada chamada.
-- Qualquer outra função (ex.: ui.fill) falha com "attempt to call a nil value".
local M = {}

function M.new()
    local log = { calls = 0, texts = {}, rects = {}, palset = {}, cls = 0, held = {} }
    local ui = {}

    local function is_int(v) return type(v) == "number" and math.floor(v) == v end
    local function coord(v, name) assert(is_int(v), name .. " deve ser inteiro, recebeu " .. tostring(v)) end
    local function color(v, name)
        assert(is_int(v) and v >= 0 and v < #Palette,
            name .. " deve ser índice de paleta 0.." .. (#Palette - 1) .. ", recebeu " .. tostring(v))
    end
    local function count() log.calls = log.calls + 1 end

    function ui.cls(c) count(); log.cls = log.cls + 1; if c ~= nil then color(c, "cls.color") end end
    function ui.clip(x, y, w, h) count(); if x ~= nil then coord(x, "x"); coord(y, "y"); coord(w, "w"); coord(h, "h") end end
    function ui.camera(x, y) count(); if x ~= nil then coord(x, "x"); coord(y, "y") end end
    function ui.palset(i, c)
        count()
        assert(is_int(i) and i >= 0 and i <= 255, "palset.index inválido")
        assert(is_int(c) and c >= 0 and c <= 0x7FFF, "palset.color deve ser RGB555")
        log.palset[#log.palset + 1] = i
    end
    local function rect_like(kind)
        return function(x0, y0, x1, y1, c)
            count()
            coord(x0, "x0"); coord(y0, "y0"); coord(x1, "x1"); coord(y1, "y1"); color(c, kind .. ".color")
            log.rects[#log.rects + 1] = { kind, x0, y0, x1, y1 }
        end
    end
    ui.rect, ui.rectfill = rect_like("rect"), rect_like("rectfill")
    function ui.line(x0, y0, x1, y1, c)
        count()
        coord(x0, "x0"); coord(y0, "y0"); coord(x1, "x1"); coord(y1, "y1"); color(c, "line.color")
        log.rects[#log.rects + 1] = { "line", x0, y0, x1, y1 }
    end
    function ui.print(s, x, y, c)
        count()
        assert(type(s) == "string", "print.text deve ser string, recebeu " .. type(s))
        coord(x, "x"); coord(y, "y"); color(c, "print.color")
        log.texts[#log.texts + 1] = { s, x, y }
    end
    -- Botões: log.held[id] = true/false controla o que o jogo "vê".
    function ui.btn(id, player)
        count()
        assert(is_int(id), "btn.id deve ser inteiro (constante da SDK), recebeu " .. tostring(id))
        return log.held[id] and 255 or false
    end

    function log.reset_frame()
        log.calls, log.cls = 0, 0
        log.texts, log.rects, log.palset = {}, {}, {}
    end
    return ui, log
end

-- Constantes globais documentadas.
function M.install_constants()
    local c = { LEFT = 0, RIGHT = 1, UP = 2, DOWN = 3, BTN_Z = 4, BTN_X = 5,
                BTN_F = 12, BTN_G = 13, BTN_Q = 14, BTN_E = 15 }
    for k, v in pairs(c) do rawset(_G, k, v) end
end

return M
