-- Geometria das peças como dados. Não conhece cores, sprites nem tabuleiro.

local ROTATIONS = 4

-- Matriz quadrada na orientação de nascimento (1 = bloco). A ordem define o índice
-- da peça ("kind") usado em todo o jogo.
local SHAPES = {
    { name = "I", rows = { { 0, 0, 0, 0 }, { 1, 1, 1, 1 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 } } },
    { name = "O", rows = { { 1, 1 }, { 1, 1 } } },
    { name = "T", rows = { { 0, 1, 0 }, { 1, 1, 1 }, { 0, 0, 0 } } },
    { name = "S", rows = { { 0, 1, 1 }, { 1, 1, 0 }, { 0, 0, 0 } } },
    { name = "Z", rows = { { 1, 1, 0 }, { 0, 1, 1 }, { 0, 0, 0 } } },
    { name = "J", rows = { { 1, 0, 0 }, { 1, 1, 1 }, { 0, 0, 0 } } },
    { name = "L", rows = { { 0, 0, 1 }, { 1, 1, 1 }, { 0, 0, 0 } } },
}

-- Gira a matriz 90° no sentido horário: o elemento (r, c) vai para (c, n-1-r).
local function rotate_cw(rows, n)
    local out = {}
    for r = 1, n do
        out[r] = {}
        for c = 1, n do
            out[r][c] = rows[n - c + 1][r]
        end
    end
    return out
end

-- Lista de deslocamentos { dx, dy } dos 4 blocos, relativos ao canto da matriz.
local function to_cells(rows, n)
    local cells = {}
    for r = 1, n do
        for c = 1, n do
            if rows[r][c] == 1 then
                cells[#cells + 1] = { c - 1, r - 1 }
            end
        end
    end
    return cells
end

local names, sizes, states, extents = {}, {}, {}, {}

for kind = 1, #SHAPES do
    local rows = SHAPES[kind].rows
    local n = #rows
    names[kind], sizes[kind], states[kind] = SHAPES[kind].name, n, {}
    for rot = 1, ROTATIONS do
        states[kind][rot] = to_cells(rows, n)
        rows = rotate_cw(rows, n)
    end
    -- Caixa envolvente da orientação de nascimento (usada para centralizar e posicionar).
    local minx, miny, maxx, maxy = 99, 99, -1, -1
    for _, cell in ipairs(states[kind][1]) do
        if cell[1] < minx then minx = cell[1] end
        if cell[1] > maxx then maxx = cell[1] end
        if cell[2] < miny then miny = cell[2] end
        if cell[2] > maxy then maxy = cell[2] end
    end
    extents[kind] = { minx, miny, maxx, maxy }
end

local Pieces = { COUNT = #SHAPES, ROTATIONS = ROTATIONS }

function Pieces.name(kind) return names[kind] end
function Pieces.size(kind) return sizes[kind] end

-- Tabela compartilhada: nunca modifique o resultado.
function Pieces.cells(kind, rot) return states[kind][rot] end

-- rot vai de 1 a 4; dir = 1 (horário) ou -1 (anti-horário).
function Pieces.rotate(rot, dir) return (rot - 1 + dir) % ROTATIONS + 1 end

-- Primeira linha ocupada na orientação de nascimento (a peça nasce encostada no topo).
function Pieces.top_row(kind) return extents[kind][2] end

function Pieces.extent(kind)
    local e = extents[kind]
    return e[1], e[2], e[3], e[4]
end

return Pieces
