local Bag = require "ov_bag"

return function(T)
    T.test("sorteio: cada saco de 7 contem as 7 pecas uma vez", function()
        local bag = Bag.new(42)
        for _ = 1, 20 do
            local seen, n = {}, 0
            for _ = 1, 7 do
                local k = bag:take()
                T.truthy(k >= 1 and k <= 7 and k == math.floor(k), "peca invalida " .. tostring(k))
                T.falsy(seen[k], "peca repetida no saco")
                seen[k] = true; n = n + 1
            end
            T.eq(n, 7)
        end
    end)

    T.test("sorteio: mesma semente gera a mesma sequencia", function()
        local a, b = Bag.new(7), Bag.new(7)
        for _ = 1, 50 do T.eq(a:take(), b:take()) end
    end)

    T.test("sorteio: sementes proximas (numeros de quadro) nao comecam iguais", function()
        local firsts, distinct = {}, 0
        for seed = 1, 30 do
            local k = Bag.new(seed):take()
            if not firsts[k] then firsts[k] = true; distinct = distinct + 1 end
        end
        T.truthy(distinct >= 5, "primeira peca pouco variada: " .. distinct .. " valores distintos")
    end)

    T.test("sorteio: distribuicao uniforme ao longo de muitos sacos", function()
        local bag, counts = Bag.new(123), {}
        for k = 1, 7 do counts[k] = 0 end
        for _ = 1, 700 do local k = bag:take(); counts[k] = counts[k] + 1 end
        for k = 1, 7 do T.eq(counts[k], 100, "peca " .. k) end
    end)

    T.test("sorteio: aceita semente zero e muito grande", function()
        local b0, b1 = Bag.new(0), Bag.new(2147483647 * 3 + 5)
        T.truthy(b0:take() >= 1); T.truthy(b1:take() >= 1)
    end)
end
