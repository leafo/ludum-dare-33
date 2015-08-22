
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


class L.Battle
  constructor: (player_party, enemy_party) ->
    @player_party = new L.Party player_party.members.map (e) ->
      new L.BattleEntity e

    @enemy_party = new L.Party enemy_party.members.map (e) ->
      new L.BattleEntity e

  all_entities: ->
    tuples = @player_party.members.map (e, idx) -> [e, idx]
    tuples = tuples.concat @enemy_party.members.map (e, idx) -> [e, idx]
    tuples.toArray()

  # finds battle entity
  find_target: ([type, idx]) ->
    party = switch type
      when "enemy"
        @enemy_party
      when "player"
        @player_party
      else
        throw "unknown target type: #{type}"

    party.get(idx)

  # get a map of player orders,
  # returns mutable array of callbacks :o
  run_turn: (orders) ->
    console.log "running turn", orders
    actions = for [battle_entity, idx] in @all_entities()
      do (battle_entity, idx) =>
        entity = battle_entity.entity
        if entity instanceof L.Player
          order = orders[idx]
          switch order[0]
            when "attack"
              target = @find_target order[1]
              if target
                => target.take_hit battle_entity
            else
              throw "don't know how to handle order #{order[0]}"

        else if entity instanceof L.Enemy
          null

    Immutable.List _.compact actions

class L.BattleEntity
  constructor: (@entity) ->
    @battle_stats = @entity.stats

  take_hit: (attacker) ->
    console.debug "#{@entity.name} being hit by #{attacker.entity.name}"

class L.Party
  constructor: (members) ->
    @members = Immutable.List members

  to_array: ->
    @members.toArray()

  get: (idx) ->
    @members.get idx



