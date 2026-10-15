local Input = require "ov_input"
local Settings = require "ov_settings"

-- Controle simulado: held[nome] = true/false/numero.
local function make()
    local held = {}
    local input = Input.new(function(name) return held[name] end)
    return input, held
end

return function(T)
    T.test("entrada: parametros de repeticao esperados", function()
        T.eq(Settings.das_delay, 12); T.eq(Settings.das_interval, 4)
    end)

    T.test("entrada: segurar esquerda move no 1o quadro, apos o atraso e depois em intervalos", function()
        local input, held = make()
        held.left = true
        local fired = {}
        for k = 0, 24 do
            if input:poll().move == -1 then fired[#fired + 1] = k end
        end
        T.eq(table.concat(fired, ","), "0,12,16,20,24")
    end)

    T.test("entrada: soltar e apertar de novo move imediatamente", function()
        local input, held = make()
        held.right = true
        T.eq(input:poll().move, 1)
        T.eq(input:poll().move, 0)
        held.right = false
        T.eq(input:poll().move, 0)
        held.right = true
        T.eq(input:poll().move, 1)
    end)

    T.test("entrada: lados opostos valem o ultimo pressionado e voltam ao outro ao soltar", function()
        local input, held = make()
        held.left = true
        T.eq(input:poll().move, -1)
        held.right = true
        T.eq(input:poll().move, 1)
        held.right = false
        T.eq(input:poll().move, 0, "reinicia atraso para a esquerda")
        local moved_at
        for k = 1, 20 do
            if input:poll().move == -1 then moved_at = k; break end
        end
        T.eq(moved_at, Settings.das_delay)
    end)

    T.test("entrada: rotacao e pausa so disparam na borda de subida", function()
        local input, held = make()
        held.rotate_cw = true; held.pause = true
        local a = input:poll()
        T.eq(a.rotate_cw, true); T.eq(a.confirm, true); T.eq(a.pause, true)
        a = input:poll()
        T.eq(a.rotate_cw, false); T.eq(a.confirm, false); T.eq(a.pause, false)
        held.rotate_cw = false
        input:poll()
        held.rotate_cw = true
        T.eq(input:poll().rotate_cw, true)
    end)

    T.test("entrada: rotacao anti-horaria, back e queda refletem o botao", function()
        local input, held = make()
        held.rotate_ccw = true; held.back = true; held.down = true
        local a = input:poll()
        T.eq(a.rotate_ccw, true); T.eq(a.back, true); T.eq(a.soft, true)
        a = input:poll()
        T.eq(a.rotate_ccw, false); T.eq(a.back, false); T.eq(a.soft, true, "down e nivel, nao borda")
        held.down = false
        T.eq(input:poll().soft, false)
    end)

    T.test("entrada: valor de pressao conta, 0 e false nao", function()
        local input, held = make()
        held.left = 255
        T.eq(input:poll().move, -1)
        held.left = 0
        input:poll()
        held.right = false
        T.eq(input:poll().move, 0)
        held.left = false
        T.eq(input:poll().soft, false)
    end)
end
