-- Executar na raiz do projeto:  lua tests/run.lua
package.path = "./?.lua;./tests/?.lua;./tests/mocks/?.lua;" .. package.path

-- Modo estrito: acusa leitura/escrita de globais não declaradas (erros de digitação,
-- vazamento de variáveis). Só os nomes abaixo são globais legítimos neste projeto.
local allowed = { Palette = true, ui = true, loop = true, update = true, Frame = true,
                  LEFT = true, RIGHT = true, UP = true, DOWN = true, BTN_Z = true, BTN_X = true,
                  BTN_F = true, BTN_G = true, BTN_Q = true, BTN_E = true }
setmetatable(_G, {
    __newindex = function(t, k, v)
        if not allowed[k] then error("atribuição a global não declarada '" .. tostring(k) .. "'", 2) end
        rawset(t, k, v)
    end,
    __index = function(_, k)
        if not allowed[k] then error("leitura de global não declarada '" .. tostring(k) .. "'", 2) end
        return nil
    end,
})

local H = require "harness"
local suites = { "test_pieces", "test_board", "test_bag", "test_session", "test_input",
                 "test_app", "test_render", "test_integration" }
for _, name in ipairs(suites) do
    print(name)
    require(name)(H)
end
print("")
if not H.run() then error("há testes falhando", 0) end
