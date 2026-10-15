local Board = require "ov_board"

local function fill_row(b, y, except)
    for x = 0, b.w - 1 do if x ~= except then b:set(x, y, 2) end end
end
local function row_empty(b, y)
    for x = 0, b.w - 1 do if b:get(x, y) ~= 0 then return false end end
    return true
end
local SQUARE = { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }

return function(T)
    T.test("tabuleiro: inicia vazio com as dimensoes pedidas", function()
        local b = Board.new(10, 20)
        T.eq(b.w, 10); T.eq(b.h, 20); T.eq(b:height(), 0)
        for y = 0, 19 do T.truthy(row_empty(b, y)) end
    end)

    T.test("tabuleiro: colisao com paredes e piso", function()
        local b = Board.new(10, 20)
        T.truthy(b:fits(SQUARE, 0, 0))
        T.falsy(b:fits(SQUARE, -1, 0), "parede esquerda")
        T.truthy(b:fits(SQUARE, 8, 0))
        T.falsy(b:fits(SQUARE, 9, 0), "parede direita")
        T.truthy(b:fits(SQUARE, 0, 18))
        T.falsy(b:fits(SQUARE, 0, 19), "piso")
    end)

    T.test("tabuleiro: acima do topo e livre; colisao com blocos fixados", function()
        local b = Board.new(10, 20)
        T.truthy(b:fits(SQUARE, 4, -1))
        b:set(5, 10, 3)
        T.falsy(b:fits(SQUARE, 4, 9), "sobrepoe (5,10)")
        T.truthy(b:fits(SQUARE, 6, 9))
        T.truthy(b:fits(SQUARE, 3, 9))
    end)

    T.test("tabuleiro: place grava o tipo; acima do topo retorna false", function()
        local b = Board.new(10, 20)
        T.eq(b:place(SQUARE, 3, 18, 7), true)
        T.eq(b:get(3, 18), 7); T.eq(b:get(4, 19), 7); T.eq(b:height(), 2)
        T.eq(b:place(SQUARE, 0, -1, 4), false)
        T.eq(b:get(0, 0), 4, "parte dentro do tabuleiro e gravada")
    end)

    T.test("tabuleiro: sem linhas cheias nada e removido", function()
        local b = Board.new(10, 20)
        fill_row(b, 19, 4)
        T.eq(b:clear_lines(), 0)
        T.eq(b:get(0, 19), 2)
    end)

    T.test("tabuleiro: remove uma linha cheia e desce o que estava acima", function()
        local b = Board.new(10, 20)
        fill_row(b, 19)
        b:set(3, 18, 5)
        T.eq(b:clear_lines(), 1)
        T.eq(b:get(3, 19), 5, "bloco desceu uma linha")
        T.eq(b:get(3, 18), 0)
        T.eq(b:get(0, 19), 0, "linha removida")
    end)

    T.test("tabuleiro: remove varias linhas nao adjacentes e reorganiza as restantes", function()
        local b = Board.new(10, 20)
        fill_row(b, 17); fill_row(b, 19)
        fill_row(b, 18, 6)       -- linha incompleta entre as duas cheias
        b:set(1, 16, 4)
        T.eq(b:clear_lines(), 2)
        T.eq(b:get(0, 19), 2, "linha incompleta foi para o fundo")
        T.eq(b:get(6, 19), 0)
        T.eq(b:get(1, 18), 4, "bloco do topo desceu duas linhas")
        T.truthy(row_empty(b, 17))
        T.eq(b:height(), 2)
    end)

    T.test("tabuleiro: quatro linhas ao mesmo tempo", function()
        local b = Board.new(10, 20)
        for y = 16, 19 do fill_row(b, y) end
        T.eq(b:clear_lines(), 4)
        T.eq(b:height(), 0)
    end)

    T.test("tabuleiro: altura da pilha", function()
        local b = Board.new(10, 20)
        b:set(0, 12, 1)
        T.eq(b:height(), 8)
        b:set(9, 0, 1)
        T.eq(b:height(), 20)
    end)
end
