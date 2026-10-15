local Session = require "ov_session"
local Settings = require "ov_settings"
local Board = require "ov_board"

local I, O, T_, S, Z, J, L = 1, 2, 3, 4, 5, 6, 7

local function idle()
    return { move = 0, soft = false, rotate_cw = false, rotate_ccw = false,
             pause = false, back = false, confirm = false }
end
local function fake_bag(list)
    local i = 0
    return { take = function() i = i + 1; return list[(i - 1) % #list + 1] end }
end
local function new_session(kinds) return Session.new({ bag = fake_bag(kinds or { O }) }) end
local function run(s, frames, actions)
    actions = actions or idle()
    for _ = 1, frames do s:update(actions) end
end
local function occupied(b)
    local n = 0
    for y = 0, b.h - 1 do for x = 0, b.w - 1 do if b:get(x, y) ~= 0 then n = n + 1 end end end
    return n
end
local function snapshot(b)
    local t = {}
    for i = 1, #b.cells do t[i] = b.cells[i] end
    return table.concat(t, ",")
end
local function fill_row(b, y, from, to)
    for x = from or 0, to or b.w - 1 do b:set(x, y, 2) end
end
local function has_event(s, name)
    for i = 1, s.event_count do if s.events[i] == name then return true end end
    return false
end

return function(T)
    T.test("config: tabela de gravidade cobre todos os niveis e nunca desacelera", function()
        T.eq(#Settings.gravity_frames, Settings.max_level)
        T.eq(Settings.gravity_frames[1], 48, "nivel 1: uma linha a cada 0,8 s a 60 quadros/s")
        for i = 2, #Settings.gravity_frames do
            T.truthy(Settings.gravity_frames[i] <= Settings.gravity_frames[i - 1], "nivel " .. i)
        end
        T.truthy(Settings.gravity_frames[#Settings.gravity_frames] >= 1)
        T.eq(#Settings.line_scores, 4)
    end)

    T.test("sessao: estado inicial e peca nasce centralizada no topo", function()
        local s = new_session({ T_, I })
        T.eq(s.score, 0); T.eq(s.lines, 0); T.eq(s.level, 1)
        T.eq(s.over, false); T.eq(occupied(s.board), 0)
        T.eq(s.piece.kind, T_); T.eq(s.piece.x, 3); T.eq(s.piece.y, 0)
        T.eq(s.next_kind, I)
        local i = new_session({ I })
        T.eq(i.piece.y, -1, "o I nasce com sua fileira de blocos na linha 0")
    end)

    T.test("sessao: nivel por linhas (progressao e limite)", function()
        T.eq(Session.level_for_lines(0), 1)
        T.eq(Session.level_for_lines(9), 1)
        T.eq(Session.level_for_lines(10), 2)
        T.eq(Session.level_for_lines(99), 10)
        T.eq(Session.level_for_lines(140), 15)
        T.eq(Session.level_for_lines(5000), Settings.max_level)
    end)

    T.test("movimento: lateral valido", function()
        local s = new_session()
        local a = idle(); a.move = -1
        s:update(a)
        T.eq(s.piece.x, 3)
        a.move = 1; s:update(a); s:update(a)
        T.eq(s.piece.x, 5)
        T.truthy(has_event(s, "move"))
    end)

    T.test("movimento: nao atravessa as paredes", function()
        local s = new_session()
        local a = idle(); a.move = -1
        for _ = 1, 20 do s:update(a) end
        T.eq(s.piece.x, 0)
        a.move = 1
        for _ = 1, 20 do s:update(a) end
        T.eq(s.piece.x, 8, "O ocupa duas colunas")
    end)

    T.test("movimento: nao atravessa blocos fixados", function()
        local s = new_session()
        s.board:set(3, 0, 5); s.board:set(3, 1, 5)
        local a = idle(); a.move = -1
        s:update(a); s:update(a)
        T.eq(s.piece.x, 4, "para encostado ao bloco em x=3")
        T.eq(has_event(s, "move"), false)
    end)

    T.test("rotacao: valida muda a orientacao", function()
        local s = new_session({ T_ })
        local a = idle(); a.rotate_cw = true
        s:update(a)
        T.eq(s.piece.rot, 2)
        a.rotate_cw = false; a.rotate_ccw = true
        s:update(a); s:update(a)
        T.eq(s.piece.rot, 4)
        T.truthy(has_event(s, "rotate"))
    end)

    T.test("rotacao: invalida (bloco fixado) preserva posicao e orientacao", function()
        local s = new_session({ I })
        s.piece = { kind = I, rot = 1, x = 3, y = 5 }
        s.board:set(5, 7, 4) -- ocuparia a coluna x+2 na orientacao vertical
        local a = idle(); a.rotate_cw = true
        s:update(a)
        T.eq(s.piece.rot, 1); T.eq(s.piece.x, 3); T.eq(s.piece.y, 5)
        T.eq(has_event(s, "rotate"), false)
    end)

    T.test("rotacao: invalida contra a parede", function()
        local s = new_session({ I })
        s.piece = { kind = I, rot = 2, x = 7, y = 5 } -- vertical na coluna 9
        local a = idle(); a.rotate_cw = true
        s:update(a)
        T.eq(s.piece.rot, 2, "horizontal passaria da coluna 9")
        T.eq(s.piece.x, 7)
    end)

    T.test("gravidade: desce exatamente a cada N quadros do nivel", function()
        local s = new_session()
        local interval = Settings.gravity_frames[1]
        local y0 = s.piece.y
        run(s, interval - 1)
        T.eq(s.piece.y, y0)
        run(s, 1)
        T.eq(s.piece.y, y0 + 1)
        run(s, interval)
        T.eq(s.piece.y, y0 + 2)
    end)

    T.test("gravidade: nivel maior desce mais rapido", function()
        local s = new_session()
        s.level = 2
        local y0 = s.piece.y
        run(s, Settings.gravity_frames[2])
        T.eq(s.piece.y, y0 + 1)
        T.truthy(Settings.gravity_frames[2] < Settings.gravity_frames[1])
    end)

    T.test("queda acelerada: desce a cada 2 quadros e soma 1 ponto por linha", function()
        local s = new_session()
        local a = idle(); a.soft = true
        local y0 = s.piece.y
        run(s, 10, a)
        T.eq(s.piece.y, y0 + 5)
        T.eq(s.score, 5)
    end)

    T.test("queda acelerada: nao vaza para a peca seguinte ate soltar o botao", function()
        local s = new_session()
        local a = idle(); a.soft = true
        local guard = 0
        while occupied(s.board) == 0 do
            s:update(a); guard = guard + 1
            T.truthy(guard < 200, "peca nunca fixou")
        end
        local score, y0 = s.score, s.piece.y
        run(s, 10, a) -- botao ainda apertado
        T.eq(s.piece.y, y0, "nova peca nao cai rapido")
        T.eq(s.score, score)
        s:update(idle()) -- solta
        run(s, 2, a)     -- aperta de novo
        T.eq(s.piece.y, y0 + 1)
    end)

    T.test("fixacao: peca pousa, vira bloco do tabuleiro e nasce outra", function()
        local s = new_session()
        local first = s.piece
        run(s, 48 * 25)
        T.truthy(occupied(s.board) >= 4)
        T.truthy(s.piece ~= first, "peca nova")
        for _, p in ipairs({ { 4, 19 }, { 5, 19 }, { 4, 18 }, { 5, 18 } }) do
            T.eq(s.board:get(p[1], p[2]), O)
        end
    end)

    T.test("fixacao: peca fixada nao recebe mais movimentos", function()
        local s = new_session()
        run(s, 48 * 25)
        local before = snapshot(s.board)
        local a = idle(); a.move = -1; a.rotate_cw = true
        for _ = 1, 5 do s:update(a) end
        T.eq(snapshot(s.board), before)
        T.truthy(s.piece.x < 4, "o movimento valeu para a peca nova")
    end)

    T.test("linhas: remove uma linha, soma pontos e libera espaco", function()
        local s = new_session({ I })
        fill_row(s.board, 19, 0, 2); fill_row(s.board, 19, 7, 9)
        s.piece = { kind = I, rot = 1, x = 3, y = 18 } -- ocupa 3..6 na linha 19
        run(s, Settings.gravity_frames[1])
        T.eq(s.lines, 1); T.eq(s.score, 100); T.eq(s.last_cleared, 1)
        T.eq(occupied(s.board), 0)
        T.eq(s.load, 0)
        T.truthy(has_event(s, "clear"))
    end)

    T.test("linhas: quatro de uma vez valem 800 x nivel e reorganizam o resto", function()
        local s = new_session({ I })
        for y = 16, 19 do fill_row(s.board, y, 1, 9) end
        s.board:set(5, 15, T_) -- marcador acima das linhas cheias
        s.piece = { kind = I, rot = 2, x = -2, y = 16 } -- vertical na coluna 0, linhas 16..19
        run(s, Settings.gravity_frames[1])
        T.eq(s.lines, 4); T.eq(s.score, 800)
        T.eq(s.board:get(5, 19), T_, "marcador desceu 4 linhas")
        T.eq(occupied(s.board), 1)
    end)

    T.test("linhas: pontuacao multiplica pelo nivel da partida", function()
        local s = new_session({ I })
        s.level, s.lines = 3, 20
        fill_row(s.board, 19, 0, 2); fill_row(s.board, 19, 7, 9)
        s.piece = { kind = I, rot = 1, x = 3, y = 18 }
        run(s, Settings.gravity_frames[3])
        T.eq(s.score, 300)
    end)

    T.test("dificuldade: dez linhas sobem o nivel; pontos usam o nivel anterior", function()
        local s = new_session({ I })
        s.lines = 9
        fill_row(s.board, 19, 0, 2); fill_row(s.board, 19, 7, 9)
        s.piece = { kind = I, rot = 1, x = 3, y = 18 }
        run(s, Settings.gravity_frames[1])
        T.eq(s.lines, 10); T.eq(s.level, 2); T.eq(s.score, 100)
        T.truthy(has_event(s, "level"))
    end)

    T.test("dificuldade: nivel nao passa do maximo", function()
        local s = new_session({ I })
        s.lines, s.level = 199, Settings.max_level
        fill_row(s.board, 19, 0, 2); fill_row(s.board, 19, 7, 9)
        s.piece = { kind = I, rot = 1, x = 3, y = 18 }
        run(s, Settings.gravity_frames[Settings.max_level])
        T.eq(s.level, Settings.max_level)
    end)

    T.test("carga: acompanha a altura da pilha", function()
        local s = new_session({ I })
        s.board:set(0, 10, 2) -- altura 10 de 20
        s.piece = { kind = I, rot = 1, x = 3, y = 18 }
        run(s, Settings.gravity_frames[1])
        T.eq(s.load, 0.5)
    end)

    T.test("game over: entrada bloqueada impede nova peca", function()
        local s = new_session({ O })
        for y = 2, 19 do fill_row(s.board, y, 0, 8) end -- coluna 9 livre: nenhuma linha fecha
        run(s, 48 * 3)
        T.eq(s.over, true)
        T.eq(s.piece, nil)
        T.truthy(s.board:get(4, 0) ~= 0, "a ultima peca ficou fixada no topo")
    end)

    T.test("game over: fixar acima do topo tambem encerra", function()
        local s = new_session({ I })
        s.piece = { kind = I, rot = 2, x = 3, y = -2 } -- ocupa as linhas -2..1 na coluna 5
        s.board:set(5, 2, 4)
        run(s, Settings.gravity_frames[1])
        T.eq(s.over, true)
        T.truthy(has_event(s, "over"))
    end)

    T.test("game over: partida encerrada ignora controles e congela pontuacao", function()
        local s = new_session({ O })
        for y = 2, 19 do fill_row(s.board, y, 0, 8) end
        run(s, 48 * 3)
        local snap, score, ticks = snapshot(s.board), s.score, s.ticks
        local a = idle(); a.move = 1; a.rotate_cw = true; a.soft = true
        run(s, 100, a)
        T.eq(snapshot(s.board), snap); T.eq(s.score, score); T.eq(s.ticks, ticks)
    end)

    T.test("reinicio: nova sessao nao herda nada da anterior", function()
        local old = new_session({ O })
        for y = 2, 19 do fill_row(old.board, y, 0, 8) end
        old.score, old.lines, old.level = 999, 33, 4
        run(old, 48 * 3)
        T.eq(old.over, true)
        local s = Session.new({ seed = 5 })
        T.eq(s.over, false); T.eq(s.score, 0); T.eq(s.lines, 0); T.eq(s.level, 1)
        T.eq(s.load, 0); T.eq(occupied(s.board), 0); T.truthy(s.piece ~= nil)
        T.truthy(s.board ~= old.board)
    end)

    T.test("sessao: mesma semente produz a mesma partida", function()
        local a, b = Session.new({ seed = 9 }), Session.new({ seed = 9 })
        for _ = 1, 3000 do a:update(idle()); b:update(idle()) end
        T.eq(snapshot(a.board), snapshot(b.board))
        T.eq(a.over, b.over)
    end)
end
