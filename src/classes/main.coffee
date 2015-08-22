
L.Stats = (stats={}) ->
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
    @stats = L.Stats {
      hp: 20
      mp: 10
      str: 1
      def: 1
      mag: 1
      mdef: 1
    }

class L.Player extends L.Entity
  name: "Sab"

  constructor: ->
    super
    @level = L.Level()
    @stat_progress = L.Stats()
    @stat_growth = L.Stats {
      hp: 5.5
      mp: 2.2
      str: 1.4
      def: 1.8
      mag: 0.6
      mdef: 0.8
    }

  give_exp: (exp) ->
    @level = @level.merge {
      exp: @level.get("exp") + exp
    }

    while @level.get("exp") > @level.get("next_exp")
      extra = @level.get("exp") - @level.get("next_exp")
      @level = @level.merge {
        exp: extra
        level: @level.get("level") + 1
        next_exp: Math.floor @level.get("next_exp") * 1.4
      }

      @level_stats()

  level_stats: ->
    # increment stat progress
    @stat_progress = @stat_progress.mergeWith (stat, grow) ->
      stat + grow
    , @stat_growth

    # increment stats from integers
    @stats = @stats.mergeWith (stat, growth, k) ->
      stat + Math.floor growth
    , @stat_progress

    # save fractional growth
    @stat_progress = @stat_progress.map (v, k) ->
      v - Math.floor v

class L.BattleEntity
  constructor: (@entity) ->
    @entity = @entity.stats

  take_hit: (attacker) ->

class L.Party
  constructor: (players) ->
    @players = Immutable.List players

