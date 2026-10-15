-- Regras e ritmo da partida. Tudo em quadros (a SDK chama update 60x por segundo).
return {
    board_w = 10,
    board_h = 20,

    -- Quadros entre duas descidas, por nível. O tamanho da tabela define o nível máximo.
    gravity_frames = { 48, 40, 33, 27, 22, 18, 14, 11, 8, 6, 5, 4, 3, 2, 1 },
    max_level = 15,
    lines_per_level = 10,

    -- Pontos por 1, 2, 3 e 4 linhas simultâneas (multiplicados pelo nível).
    line_scores = { 100, 300, 500, 800 },
    soft_drop_points = 1,
    soft_drop_frames = 2,

    -- Repetição de movimento lateral ao segurar o botão (DAS).
    das_delay = 12,
    das_interval = 4,

    -- Evita reiniciar sem querer ao martelar o botão de rotação no momento da falha.
    gameover_lockout = 45,
}
