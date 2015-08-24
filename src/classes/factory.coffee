L.Factory = {
  leveled_player: (l) ->
    player = new L.Player
    while player.level.get("level") < l
      player.give_exp player.level.get("next_exp")

    player

  level: (l) ->
    L.Factory.leveled_player(l).level

  battle: (level, game) ->
    enemies = new L.Party [
      new L.Enemy "Rags 1"
      new L.Enemy "Rags 2"
    ]

    new L.Battle game, enemies
}
