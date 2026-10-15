require "palette"
require "sprites"

local Input = require "ov_input"
local App = require "ov_app"
local Render = require "ov_render"
local Theme = require "ov_theme"

-- Constantes de botão (LEFT, BTN_Z...) são globais da SDK; resolvidas no primeiro uso.
local buttons

local function read_button(name)
    if not buttons then
        buttons = {
            left = LEFT, right = RIGHT, down = DOWN,
            rotate_cw = BTN_Z, rotate_ccw = BTN_X,
            pause = BTN_F, back = BTN_G,
        }
    end
    return ui.btn(buttons[name])
end

local input = Input.new(read_button)
local app = App.new()

function loop(frame)

    for i = 1, #Palette do
        local color = Palette[i]
        ui.palset(i - 1, color)
    end

    ui.clip(0,0,480,270)
    ui.camera(0,0)
    ui.cls(Theme.colors.bg)

    App.update(app, input:poll(), frame)
    Render.draw(app, frame)
end
