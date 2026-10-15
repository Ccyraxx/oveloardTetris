-- Executa o ponto de entrada real (game.lua -> main.lua) com um "ui" simulado que valida
-- a API documentada. NÃO equivale a rodar na SDK/emulador do Lupi.
local UiMock = require "ui"

local function printed(log, needle)
    for _, t in ipairs(log.texts) do
        if string.find(t[1], needle, 1, true) then return true end
    end
    return false
end

return function(T)
    T.test("integracao: game.lua/main.lua rodam quadro a quadro, do titulo ao game over e reinicio", function()
        require "palette"
        UiMock.install_constants()
        local ui, log = UiMock.new()
        rawset(_G, "ui", ui)
        dofile("game.lua")

        local function frame()
            log.reset_frame()
            update()
        end

        -- Titulo
        for _ = 1, 10 do frame() end
        T.eq(log.cls, 1, "um cls por quadro")
        T.eq(#log.palset, #Palette, "paleta registrada a cada quadro")
        T.truthy(printed(log, "PRESS Z"))

        -- Inicia a partida com BTN_Z (uma borda de subida)
        log.held[BTN_Z] = true; frame(); log.held[BTN_Z] = false; frame()
        T.truthy(printed(log, "SCORE"), "partida iniciou")
        T.truthy(printed(log, "SYSTEM ONLINE"))

        -- Pausa e retoma
        log.held[BTN_F] = true; frame(); log.held[BTN_F] = false; frame()
        T.truthy(printed(log, "PAUSED"))
        log.held[BTN_F] = true; frame(); log.held[BTN_F] = false; frame()
        T.falsy(printed(log, "PAUSED"))

        -- Joga solto ate o sistema falhar: DOWN apertado com uma soltura periodica.
        local max_calls, failed_at = 0, nil
        for n = 1, 6000 do
            log.held[DOWN] = (n % 15 ~= 0)
            log.held[LEFT] = (n % 200) < 30
            frame()
            if log.calls > max_calls then max_calls = log.calls end
            if printed(log, "SYSTEM FAILURE") and printed(log, "FINAL SCORE") then failed_at = n; break end
        end
        T.truthy(failed_at, "o jogo deveria chegar ao game over")
        print(string.format("        (game over no quadro %d; maximo de %d chamadas ui por quadro)", failed_at, max_calls))
        T.truthy(max_calls < 600, "chamadas de desenho por quadro")

        -- Reinicio: aguarda a trava e aperta BTN_Z
        log.held[DOWN], log.held[LEFT] = false, false
        for _ = 1, 60 do frame() end
        log.held[BTN_Z] = true; frame(); log.held[BTN_Z] = false; frame()
        T.truthy(printed(log, "SYSTEM ONLINE"), "nova partida iniciou")
        T.falsy(printed(log, "SYSTEM FAILURE"))
        local zero = false
        for _, t in ipairs(log.texts) do if t[1] == "0000000" then zero = true end end
        T.truthy(zero, "placar zerado na nova partida")
    end)

    T.test("integracao: partida longa com entradas variadas nao gera erro", function()
        require "palette"
        local ui, log = UiMock.new()
        rawset(_G, "ui", ui)
        local seed = 12345
        local function rnd(n) seed = (seed * 16807) % 2147483647; return seed % n end
        log.held[BTN_Z] = true; update(); log.held[BTN_Z] = false
        for _ = 1, 20000 do
            log.reset_frame()
            for _, id in ipairs({ LEFT, RIGHT, DOWN, BTN_Z, BTN_X, BTN_F, BTN_G }) do
                if rnd(12) == 0 then log.held[id] = not log.held[id] end
            end
            update()
        end
    end)
end
