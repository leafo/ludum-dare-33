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
  
  is_dead: =>
    @battle_stats.get("hp") == 0

  take_hit: (attacker) ->
    console.debug "#{@entity.name} being hit by #{attacker.entity.name}"
