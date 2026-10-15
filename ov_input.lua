-- Traduz o estado bruto dos botões em ações por quadro.
-- Recebe uma função read(nome) -> pressionado?, o que mantém este módulo independente
-- da SDK. Nomes lógicos: left, right, down, rotate_cw, rotate_ccw, pause, back.
-- A detecção de "acabou de pressionar" e a repetição de movimento são feitas aqui,
-- usando apenas o estado "segurado" do botão.

local Settings = require "ov_settings"

local NAMES = { "left", "right", "down", "rotate_cw", "rotate_ccw", "pause", "back" }

local Input = {}
Input.__index = Input

function Input.new(read)
    local self = setmetatable({}, Input)
    self.read = read
    self.held, self.prev, self.pressed = {}, {}, {}
    for i = 1, #NAMES do
        local name = NAMES[i]
        self.held[name], self.prev[name], self.pressed[name] = false, false, false
    end
    self.dir, self.dir_frames = 0, 0
    -- Tabela reutilizada a cada quadro para não gerar lixo.
    self.actions = {
        move = 0, soft = false,
        rotate_cw = false, rotate_ccw = false,
        pause = false, back = false, confirm = false,
    }
    return self
end

-- ui.btn devolve false ou a pressão (0-255) do botão.
local function is_down(value)
    return value ~= nil and value ~= false and value ~= 0
end

function Input:poll()
    local held, prev, pressed = self.held, self.prev, self.pressed
    for i = 1, #NAMES do
        local name = NAMES[i]
        prev[name] = held[name]
        held[name] = is_down(self.read(name))
        pressed[name] = held[name] and not prev[name]
    end

    -- Movimento lateral: dispara ao pressionar, espera das_delay quadros e repete a cada
    -- das_interval. Com os dois lados apertados vale o pressionado por último.
    local move = 0
    if pressed.left then
        self.dir, self.dir_frames, move = -1, 0, -1
    elseif pressed.right then
        self.dir, self.dir_frames, move = 1, 0, 1
    elseif self.dir ~= 0 then
        local side = self.dir < 0 and "left" or "right"
        if held[side] then
            self.dir_frames = self.dir_frames + 1
            local extra = self.dir_frames - Settings.das_delay
            if extra >= 0 and extra % Settings.das_interval == 0 then move = self.dir end
        else
            -- Soltou: se o outro lado ainda está apertado, ele assume (com novo atraso).
            if held.left then self.dir = -1
            elseif held.right then self.dir = 1
            else self.dir = 0 end
            self.dir_frames = 0
        end
    end

    local a = self.actions
    a.move = move
    a.soft = held.down
    a.rotate_cw = pressed.rotate_cw
    a.rotate_ccw = pressed.rotate_ccw
    a.pause = pressed.pause
    a.back = pressed.back
    a.confirm = pressed.rotate_cw
    return a
end

return Input
