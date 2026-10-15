local Pieces = require "ov_pieces"

-- Converte uma lista de células em texto ordenado, para comparar sem depender da ordem.
local function key(cells)
    local parts = {}
    for i, c in ipairs(cells) do parts[i] = c[1] .. "," .. c[2] end
    table.sort(parts)
    return table.concat(parts, ";")
end

return function(T)
    T.test("pecas: 7 formas, cada orientacao com 4 blocos distintos", function()
        T.eq(Pieces.COUNT, 7)
        for kind = 1, 7 do
            for rot = 1, 4 do
                local cells = Pieces.cells(kind, rot)
                T.eq(#cells, 4, Pieces.name(kind) .. " rot " .. rot)
                local seen = {}
                for _, c in ipairs(cells) do
                    local k = c[1] .. "," .. c[2]
                    T.falsy(seen[k], "bloco duplicado em " .. Pieces.name(kind))
                    seen[k] = true
                    T.truthy(c[1] >= 0 and c[2] >= 0 and c[1] < Pieces.size(kind) and c[2] < Pieces.size(kind))
                end
            end
        end
    end)

    T.test("pecas: orientacao de nascimento conhecida (I e T)", function()
        T.eq(key(Pieces.cells(1, 1)), "0,1;1,1;2,1;3,1")
        T.eq(key(Pieces.cells(3, 1)), "0,1;1,0;1,1;2,1")
    end)

    T.test("pecas: rotacao horaria do I leva a vertical na coluna 2", function()
        T.eq(key(Pieces.cells(1, 2)), "2,0;2,1;2,2;2,3")
    end)

    T.test("pecas: quatro rotacoes voltam a forma original; O nao muda", function()
        for kind = 1, 7 do
            local rot = 1
            for _ = 1, 4 do rot = Pieces.rotate(rot, 1) end
            T.eq(rot, 1)
            T.eq(key(Pieces.cells(kind, rot)), key(Pieces.cells(kind, 1)))
        end
        for rot = 2, 4 do T.eq(key(Pieces.cells(2, rot)), key(Pieces.cells(2, 1)), "O rot " .. rot) end
    end)

    T.test("pecas: indice de rotacao horario e anti-horario", function()
        T.eq(Pieces.rotate(1, 1), 2)
        T.eq(Pieces.rotate(4, 1), 1)
        T.eq(Pieces.rotate(1, -1), 4)
        T.eq(Pieces.rotate(3, -1), 2)
    end)

    T.test("pecas: S e Z sao espelhos, J e L sao espelhos (formas distintas)", function()
        T.eq(key(Pieces.cells(4, 1)), "0,1;1,0;1,1;2,0")
        T.eq(key(Pieces.cells(5, 1)), "0,0;1,0;1,1;2,1")
        T.truthy(key(Pieces.cells(6, 1)) ~= key(Pieces.cells(7, 1)))
    end)

    T.test("pecas: top_row e extent da orientacao de nascimento", function()
        T.eq(Pieces.top_row(1), 1)
        for kind = 2, 7 do T.eq(Pieces.top_row(kind), 0, Pieces.name(kind)) end
        local minx, miny, maxx, maxy = Pieces.extent(1)
        T.eq(minx, 0); T.eq(miny, 1); T.eq(maxx, 3); T.eq(maxy, 1)
    end)
end
