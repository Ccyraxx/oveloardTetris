-- MOCK PARA TESTES. Não é o módulo "palette" real do Lupi.
-- Reproduz só o que main.lua do repositório oficial usa: Palette[i] (cor RGB555),
-- #Palette e Palette.hex(0xRRGGBB) -> índice. Conteúdo = db32.png do repositório.
-- A ordem dos canais RGB555 aqui é uma SUPOSIÇÃO e não afeta nenhum teste.
local RGB24 = {
    0x000000,
    0x222034,
    0x45283c,
    0x663931,
    0x8f563b,
    0xdf7126,
    0xd9a066,
    0xeec39a,
    0xfbf236,
    0x99e550,
    0x6abe30,
    0x37946e,
    0x4b692f,
    0x524b24,
    0x323c39,
    0x3f3f74,
    0x306082,
    0x5b6ee1,
    0x639bff,
    0x5fcde4,
    0xcbdbfc,
    0xffffff,
    0x9badb7,
    0x847e87,
    0x696a6a,
    0x595652,
    0x76428a,
    0xac3232,
    0xd95763,
    0xd77bba,
    0x8f974a,
    0x8a6f30,
}

Palette = {}
local index_of = {}
for i, rgb in ipairs(RGB24) do
    local r = math.floor(rgb / 65536) % 256
    local g = math.floor(rgb / 256) % 256
    local b = rgb % 256
    Palette[i] = math.floor(r / 8) * 1024 + math.floor(g / 8) * 32 + math.floor(b / 8)
    index_of[rgb] = i - 1
end

-- Falha se a cor não pertence à paleta: o jogo só pode usar cores DB32.
function Palette.hex(rgb)
    local index = index_of[rgb]
    if index == nil then error(string.format("cor fora da paleta DB32: 0x%06x", rgb), 2) end
    return index
end
