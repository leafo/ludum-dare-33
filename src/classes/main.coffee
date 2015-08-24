
L.Stats = (stats={}) ->
  Immutable.Map({
    hp: 0
    mp: 0
    max_hp: 0
    max_mp: 0
    str: 0
    def: 0
    agi: 0
    mag: 0
    mdef: 0
  }).merge stats


L.Level = (status={}) ->
  Immutable.Map({
    exp: 0
    next_exp: 100
    level: 1
  })


class L.Game
  @default_view: -> ["MainMenu", {}]

  money: 0

  constructor: ->
    @party = @default_party()

  heal_party: ->
    for player in @party.to_array()
      player.stats = player.stats.merge {
        hp: player.stats.get "max_hp"
        mp: player.stats.get "max_mp"
      }

  default_party: ->
    new L.Party [
      new L.Player "Sab"
      new L.Player "Lee"
      new L.Player "Iman"
    ]

class L.Entity
  name: "Unkwn"

  constructor: ->
    @stats = L.Stats {
      hp: 20
      mp: 10

      max_hp: 20
      max_mp: 10

      str: 1
      def: 1
      agi: 1
      mag: 1
      mdef: 1
    }

  is_dead: =>
    @stats.get("hp") == 0

class L.Enemy extends L.Entity
  name: "Ragr"

  constructor: (name) ->
    @name = name if name?
    super

class L.Player extends L.Entity
  name: "Sab"

  constructor: (name) ->
    @name = name if name?

    super
    @level = L.Level()
    @stat_progress = L.Stats()
    @stat_growth = L.Stats {
      max_hp: 5.5
      max_mp: 2.2
      str: 1.4
      def: 1.8
      agi: 0.9
      mag: 0.6
      mdef: 0.8
    }

  heal: ->
    @stats = @stats.merge {
      hp: @stats.get("max_hp")
      mp: @stats.get("max_mp")
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

class L.Party
  constructor: (members) ->
    @members = Immutable.List members

  to_array: ->
    @members.toArray()

  living_members: ->
    @members.filter (e) -> !e.is_dead()

  is_dead: ->
    @members.every (e) -> e.is_dead()

  random_member: ->

  next_living_member: (idx=-1, direction=1) =>
    while true
      idx += direction
      m = @members.get idx
      return unless m
      return m unless m.is_dead()

  get: (idx) ->
    @members.get idx

