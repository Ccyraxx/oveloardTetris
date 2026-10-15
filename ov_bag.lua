-- Sorteio de peças em "sacos" de 7 (cada peça aparece uma vez por saco).
-- Usa um gerador próprio (Park-Miller) para depender apenas de aritmética básica e
-- permitir partidas reproduzíveis a partir de uma semente.

local MODULUS = 2147483647
local MULTIPLIER = 16807 -- produto máximo ~3,6e13: exato mesmo em números de ponto flutuante

local Bag = {}
Bag.__index = Bag

local function advance(self)
    self.state = (self.state * MULTIPLIER) % MODULUS
end

-- Inteiro uniforme em 1..n.
local function roll(self, n)
    advance(self)
    return math.floor((self.state - 1) * n / (MODULUS - 1)) + 1
end

function Bag.new(seed)
    local state = math.floor(seed) % MODULUS
    if state == 0 then state = 1 end
    local self = setmetatable({ state = state, items = {}, count = 0 }, Bag)
    -- Sementes pequenas (números de quadro) começam correlacionadas; o aquecimento as espalha.
    for _ = 1, 16 do advance(self) end
    return self
end

local function refill(self)
    local items = self.items
    for i = 1, 7 do items[i] = i end
    for i = 7, 2, -1 do
        local j = roll(self, i)
        items[i], items[j] = items[j], items[i]
    end
    self.count = 7
end

function Bag:take()
    if self.count == 0 then refill(self) end
    local kind = self.items[self.count]
    self.count = self.count - 1
    return kind
end

return Bag
