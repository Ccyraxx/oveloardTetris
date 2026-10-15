local App = require "ov_app"
local Settings = require "ov_settings"

local function idle()
    return { move = 0, soft = false, rotate_cw = false, rotate_ccw = false,
             pause = false, back = false, confirm = false }
end
local function press(app, field, frame)
    local a = idle(); a[field] = true
    if field == "rotate_cw" then a.confirm = true end
    App.update(app, a, frame or 0)
end

return function(T)
    T.test("fluxo: comeca na tela inicial e confirmar inicia a partida", function()
        local app = App.new()
        T.eq(app.scene, "title"); T.eq(app.session, nil)
        App.update(app, idle(), 0)
        T.eq(app.scene, "title")
        press(app, "confirm", 10)
        T.eq(app.scene, "playing")
        T.eq(app.session.score, 0)
        T.eq(app.session.ticks, 0, "a acao de confirmar nao vaza para a partida")
    end)

    T.test("fluxo: pausa congela a partida, retoma e volta ao titulo", function()
        local app = App.new()
        press(app, "confirm", 1)
        App.update(app, idle(), 2)
        local ticks = app.session.ticks
        press(app, "pause")
        T.eq(app.scene, "paused")
        for _ = 1, 100 do App.update(app, idle(), 0) end
        T.eq(app.session.ticks, ticks)
        press(app, "pause")
        T.eq(app.scene, "playing")
        press(app, "pause")
        press(app, "back")
        T.eq(app.scene, "title"); T.eq(app.session, nil)
    end)

    T.test("fluxo: botao back so vale na pausa", function()
        local app = App.new()
        press(app, "confirm", 1)
        press(app, "back")
        T.eq(app.scene, "playing")
    end)

    T.test("fluxo: partida chega ao game over e so reinicia apos a trava", function()
        local app = App.new()
        press(app, "confirm", 3)
        for y = 2, 19 do
            for x = 0, 8 do app.session.board:set(x, y, 2) end
        end
        local a = idle(); a.soft = true
        local guard = 0
        while app.scene == "playing" do
            App.update(app, a, 0)
            guard = guard + 1
            T.truthy(guard < 20000, "nunca terminou")
        end
        T.eq(app.scene, "gameover")
        T.eq(app.session.over, true)
        local dead = app.session

        press(app, "confirm", 50)
        T.eq(app.scene, "gameover", "ainda dentro da trava")
        for _ = 1, Settings.gameover_lockout do App.update(app, idle(), 0) end
        press(app, "confirm", 77)
        T.eq(app.scene, "playing")
        T.truthy(app.session ~= dead)
        T.eq(app.session.score, 0); T.eq(app.session.over, false)
        T.eq(app.session.board:height(), 0)
    end)

    T.test("fluxo: partidas iniciadas em quadros diferentes usam sementes diferentes", function()
        local firsts, distinct = {}, 0
        for frame = 1, 40 do
            local app = App.new()
            press(app, "confirm", frame * 13)
            local k = app.session.piece.kind
            if not firsts[k] then firsts[k] = true; distinct = distinct + 1 end
        end
        T.truthy(distinct >= 5, "pouca variedade: " .. distinct)
    end)
end
