-- Fluxo do jogo: tela inicial -> partida <-> pausa -> game over -> nova partida.

local Settings = require "ov_settings"
local Session = require "ov_session"

local App = {}

function App.new()
    return { scene = "title", session = nil, timer = 0 }
end

local function start_game(app, frame)
    -- O número do quadro em que o jogador apertou o botão serve de semente.
    app.session = Session.new({ seed = frame + 1 })
    app.scene = "playing"
    app.timer = 0
end

-- Na troca de cena a ação que a provocou não é repassada à nova cena no mesmo quadro.
function App.update(app, actions, frame)
    app.timer = app.timer + 1
    local scene = app.scene

    if scene == "title" then
        if actions.confirm then start_game(app, frame) end

    elseif scene == "playing" then
        if actions.pause then
            app.scene, app.timer = "paused", 0
            return
        end
        app.session:update(actions)
        if app.session.over then app.scene, app.timer = "gameover", 0 end

    elseif scene == "paused" then
        if actions.pause then
            app.scene, app.timer = "playing", 0
        elseif actions.back then
            app.scene, app.session, app.timer = "title", nil, 0
        end

    elseif scene == "gameover" then
        if actions.confirm and app.timer >= Settings.gameover_lockout then
            start_game(app, frame)
        end
    end
end

return App
