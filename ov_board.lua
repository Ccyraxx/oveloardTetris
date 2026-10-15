-- Grade lógica do tabuleiro. Independente de peças e de renderização:
-- recebe listas de células { dx, dy } e um valor ("kind") por célula; 0 = vazia.
-- Coordenadas começam em 0; y = 0 é a linha do topo.

local Board = {}
Board.__index = Board

function Board.new(w, h)
    local self = setmetatable({ w = w, h = h, cells = {} }, Board)
    for i = 1, w * h do self.cells[i] = 0 end
    return self
end

function Board:get(x, y) return self.cells[y * self.w + x + 1] end
function Board:set(x, y, value) self.cells[y * self.w + x + 1] = value end

-- Células acima do topo (y < 0) são livres: a rotação de peças recém-nascidas pode usá-las.
function Board:is_free(x, y)
    if x < 0 or x >= self.w or y >= self.h then return false end
    if y < 0 then return true end
    return self.cells[y * self.w + x + 1] == 0
end

function Board:fits(cells, px, py)
    for i = 1, #cells do
        local c = cells[i]
        if not self:is_free(px + c[1], py + c[2]) then return false end
    end
    return true
end

-- Grava a peça. Retorna false se algum bloco ficou acima do topo (peça fixada fora da área).
function Board:place(cells, px, py, kind)
    local inside = true
    for i = 1, #cells do
        local x, y = px + cells[i][1], py + cells[i][2]
        if y < 0 then
            inside = false
        else
            self:set(x, y, kind)
        end
    end
    return inside
end

-- Remove todas as linhas cheias de uma vez, compactando de baixo para cima.
-- Retorna quantas linhas foram removidas.
function Board:clear_lines()
    local w, h, cells = self.w, self.h, self.cells
    local write, cleared = h - 1, 0
    for read = h - 1, 0, -1 do
        local base = read * w
        local full = true
        for x = 1, w do
            if cells[base + x] == 0 then full = false; break end
        end
        if full then
            cleared = cleared + 1
        else
            if write ~= read then
                local wbase = write * w
                for x = 1, w do cells[wbase + x] = cells[base + x] end
            end
            write = write - 1
        end
    end
    for y = write, 0, -1 do
        local base = y * w
        for x = 1, w do cells[base + x] = 0 end
    end
    return cleared
end

-- Altura da pilha em linhas (0 = tabuleiro vazio).
function Board:height()
    for y = 0, self.h - 1 do
        local base = y * self.w
        for x = 1, self.w do
            if self.cells[base + x] ~= 0 then return self.h - y end
        end
    end
    return 0
end

return Board
