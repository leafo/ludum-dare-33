
L.Stats = (status={}) ->
  Immutable.Map({
    hp: 0
    mp: 0
    str: 0
    def: 0
    mag: 0
    mdef: 0
  }).merge stats


L.Level = (status={}) ->
  Immutable.Map({
    exp: 0
    next_exp: 100
    level: 1
  })


class L.Entity
  name: "Unkwn"

  constructor: ->
    @stats = L.Stats()

class L.Player
  name: "Sab"

  constructor: ->
    super
    @level = L.Level()

  give_exp: (exp) ->
    @level = @level.merge {
      exp: @level.get("exp") + exp
    }

    if @level.get("exp") > @level.get("next_exp")
      extra = @level.get("exp") - @level.get("next_exp")
      @level = @level.merge {
        exp: extra
        level: @level.get("level") + 1
        next_exp: Math.floor @level.get("next_exp") * 1.4
      }


class L.BattleEntity
  constructor: (@entity) ->
    @entity = @entity.stats

  take_hit: (attacker) ->

