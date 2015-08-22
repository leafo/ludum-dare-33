L.Factory = {
  leveled_player: (l) ->
    player = new L.Player
    while player.level.get("level") < l
      player.give_exp player.level.get("next_exp")

    player

  level: (l) ->
    L.Factory.leveled_player(l).level
}
