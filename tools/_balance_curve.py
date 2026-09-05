"""Auditoria de balance: XP ganho por estagio vs level do Kael (P2 #16).

Simula a campanha linear (intro -> Aurius fase 3) com a economia real:
- XP de batalha = soul_ether dos inimigos x 0.4 (arena_battle.gd:378)
- XP de traversal/puzzle = rewards declarados no map_database
- Curva de level = 100 * level^1.5 (progression_system.gd)
- Projeção de stats: base Kael (80/12/8) + crescimento por level
"""

import math

ENEMIES = {
    'mercenario': 15, 'cacador': 12, 'inquisidor': 30, 'paladino': 80,
    'troll': 25, 'lobo_sombrio': 8, 'aranha_gigante': 10, 'esqueleto': 8,
    'santo_cardeal': 200, 'goblin_lama': 12, 'orc_chefe': 40,
    'cardeal_ignis': 200, 'cardeal_zephyr': 200, 'cardeal_aqua': 200,
    'cardeal_terra': 200, 'cardeal_umbra': 200,
    'aurius_fase1': 500, 'aurius_fase2': 500, 'aurius_fase3': 500,
}

# (mapa, inimigos do pool com contagem, xp de traversal+puzzle)
STAGES = [
    ('0 intro',  {'mercenario': 2, 'cacador': 1}, 40),
    ('1 floresta', {'lobo_sombrio': 3, 'aranha_gigante': 2}, 0),
    ('2 necropole', {'esqueleto': 2, 'troll': 2}, 180),
    ('3 castelo', {'inquisidor': 2, 'paladino': 2}, 140),
    ('4 santo', {'troll': 3}, 255),
    ('5 ignis', {'cardeal_ignis': 1}, 260),
    ('6 zephyr', {'cardeal_zephyr': 1}, 200),
    ('7 aqua', {'cardeal_aqua': 1}, 240),
    ('8 terra', {'cardeal_terra': 1}, 270),
    ('9 umbra', {'cardeal_umbra': 1}, 300),
    ('10 aurius1', {'aurius_fase1': 1}, 360),
    ('11 aurius2', {'aurius_fase2': 1}, 0),
    ('12 aurius3', {'aurius_fase3': 1}, 0),
]

# niveis requerem XP cumulativo de sum(100*i^1.5) ate level-1
LEVELS = [0.0]
for i in range(1, 60):
    LEVELS.append(LEVELS[-1] + 100 * i ** 1.5)


def level_for_xp(xp: float) -> int:
    lv = 1
    while lv < 59 and LEVELS[lv] <= xp:
        lv += 1
    return lv


total_xp = 0.0
print(f"{'estagio':12s} {'xp_ganho':>9s} {'xp_total':>9s} {'level':>5s}")
for name, pool, bonus_xp in STAGES:
    fight_xp = sum(ENEMIES[e] * n for e, n in pool.items()) * 0.4
    total_xp += fight_xp + bonus_xp
    lv = level_for_xp(total_xp)
    print(f'{name:12s} {fight_xp + bonus_xp:9.0f} {total_xp:9.0f} {lv:5d}')

# stats projetados com growth escolhido
print('\nprojetado (hp +14/lv, atk +2/lv, def +1/lv, mp +5/lv):')
for lv in (1, 5, 10, 14, 18, 22):
    hp = 80 + 14 * (lv - 1)
    atk = 12 + 2 * (lv - 1)
    df = 8 + 1 * (lv - 1)
    print(f'  lv{lv:2d}: hp={hp} atk={atk} def={df}')

# TTK alvo: dano do Kael no boss (atk - def/2?) verificar formula
print('\nreferencia bosses: ignis 320hp def16, terra 380 def15, aurius1 600 def20')
