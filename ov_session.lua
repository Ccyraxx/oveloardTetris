-- Estado e regras de uma partida. Não desenha nada e não lê controles:
-- recebe o que o jogador fez por quadro (tabela "actions", ver ov_input.lua).

local Settings = require "ov_settings"
local Pieces = require "ov_pieces"
local Board = require "ov_board"
local Bag = require "ov_bag"

local Session = {}
Session.__index = Session

function Session.level_for_lines(lines)
    local level = math.floor(lines / Settings.lines_per_level) + 1
    if level > Settings.max_level then level = Settings.max_level end
    return level
end

-- Eventos do último update ("move", "rotate", "lock", "clear", "level", "over").
-- São o ponto de ligação para efeitos sonoros e visuais futuros.
local function push_event(self, name)
    local n = self.event_count + 1
    self.event_count = n
    self.events[n] = name
end

local function finish(self)
    self.over = true
    self.piece = nil
    push_event(self, "over")
end

-- Cria a próxima peça no topo, centralizada. Se não couber, a partida acaba.
local function spawn(self)
    local kind = self.next_kind
    self.next_kind = self.bag:take()
    local x = math.floor((self.board.w - Pieces.size(kind)) / 2)
    local y = -Pieces.top_row(kind)
    if not self.board:fits(Pieces.cells(kind, 1), x, y) then
        finish(self)
        return
    end
    self.piece = { kind = kind, rot = 1, x = x, y = y }
    self.fall_counter = 0
end

function Session.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Session)
    self.board = Board.new(Settings.board_w, Settings.board_h)
    self.bag = opts.bag or Bag.new(opts.seed or 1)
    self.score, self.lines, self.level = 0, 0, 1
    self.load = 0              -- ocupação da pilha, de 0 a 1
    self.ticks = 0
    self.over = false
    self.fall_counter = 0
    self.soft_armed = true     -- queda acelerada só vale se o botão foi solto após a última fixação
    self.last_cleared = 0
    self.events, self.event_count = {}, 0
    self.next_kind = self.bag:take()
    spawn(self)
    return self
end

local function try_move(self, dx, dy)
    local p = self.piece
    if self.board:fits(Pieces.cells(p.kind, p.rot), p.x + dx, p.y + dy) then
        p.x, p.y = p.x + dx, p.y + dy
        return true
    end
    return false
end

-- Sem compensação de parede: rotação inválida mantém a posição anterior.
local function try_rotate(self, dir)
    local p = self.piece
    local rot = Pieces.rotate(p.rot, dir)
    if self.board:fits(Pieces.cells(p.kind, rot), p.x, p.y) then
        p.rot = rot
        push_event(self, "rotate")
    end
end

local function lock_piece(self)
    local p = self.piece
    local inside = self.board:place(Pieces.cells(p.kind, p.rot), p.x, p.y, p.kind)
    self.piece = nil -- a peça fixada deixa de receber movimentos
    self.soft_armed = false
    push_event(self, "lock")
    if not inside then
        finish(self) -- fixou parcialmente acima do topo
        return
    end

    local cleared = self.board:clear_lines()
    self.last_cleared = cleared
    if cleared > 0 then
        -- A pontuação usa o nível anterior à subida de nível causada por estas linhas.
        self.score = self.score + Settings.line_scores[cleared] * self.level
        self.lines = self.lines + cleared
        push_event(self, "clear")
        local level = Session.level_for_lines(self.lines)
        if level > self.level then
            self.level = level
            push_event(self, "level")
        end
    end
    self.load = self.board:height() / self.board.h
    spawn(self)
end

function Session:update(actions)
    self.event_count = 0
    if self.over then return end
    self.ticks = self.ticks + 1

    if actions.move ~= 0 and try_move(self, actions.move, 0) then
        push_event(self, "move")
    end
    if actions.rotate_cw then
        try_rotate(self, 1)
    elseif actions.rotate_ccw then
        try_rotate(self, -1)
    end

    if not actions.soft then self.soft_armed = true end
    local soft = actions.soft and self.soft_armed
    local interval = Settings.gravity_frames[self.level]
    if soft and Settings.soft_drop_frames < interval then
        interval = Settings.soft_drop_frames
    end

    self.fall_counter = self.fall_counter + 1
    if self.fall_counter >= interval then
        self.fall_counter = 0
        if try_move(self, 0, 1) then
            if soft then self.score = self.score + Settings.soft_drop_points end
        else
            lock_piece(self)
        end
    end
end

return Session
