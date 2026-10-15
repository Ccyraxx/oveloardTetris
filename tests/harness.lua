-- Harness mínimo de testes em Lua padrão (sem dependências).
local H = { tests = {}, passed = 0, failed = 0 }

function H.test(name, fn) H.tests[#H.tests + 1] = { name = name, fn = fn } end

local function show(v) return type(v) == "string" and string.format("%q", v) or tostring(v) end

function H.eq(actual, expected, msg)
    if actual ~= expected then
        error((msg or "valores diferentes") .. ": esperado " .. show(expected) .. ", obtido " .. show(actual), 2)
    end
end
function H.truthy(v, msg) if not v then error(msg or "esperava verdadeiro", 2) end end
function H.falsy(v, msg) if v then error(msg or "esperava falso", 2) end end

function H.run()
    for _, t in ipairs(H.tests) do
        local ok, err = pcall(t.fn)
        if ok then
            H.passed = H.passed + 1
            print("  ok    " .. t.name)
        else
            H.failed = H.failed + 1
            print("  FALHA " .. t.name .. "\n        " .. tostring(err))
        end
    end
    print(string.format("\n%d testes, %d passaram, %d falharam (%s)", #H.tests, H.passed, H.failed, _VERSION))
    return H.failed == 0
end

return H
