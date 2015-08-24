class L.Battle
  constructor: (@game, enemy_party) ->
    @player_party = new L.Party @game.party.members.map (e, i) ->
      new L.BattleEntity i, e

    @enemy_party = new L.Party enemy_party.members.map (e, i) ->
      new L.BattleEntity i, e

  is_over: =>
    @escaped || @player_wins() || @enemy_wins()

  player_wins: ->
    @enemy_party.members.every (e) -> e.is_dead()

  enemy_wins: ->
    @player_party.members.every (e) -> e.is_dead()

  all_entities: ->
    @player_party.members.concat @enemy_party.members

  loot: ->
    if @escaped
      Immutable.Map {
        money: 0
        exp: 0
        items: Immutable.List()
      }
    else
      Immutable.Map {
        money: 100
        exp: 24
        items: Immutable.List()
      }

  escape: =>
    @escaped = true

  # copy the hp/mp back into the player's main stats
  # give exp
  end_battle: ->
    loot = @loot()

    for battle_player in @player_party.members.toArray()
      player = battle_player.entity

      player.stats = player.stats.merge {
        hp: battle_player.battle_stats.get("hp")
        mp: battle_player.battle_stats.get("mp")
      }

      unless player.is_dead()
        player.give_exp loot.get "exp"

    @game.money += loot.get("money")

  # finds battle entity
  find_target: ([type, idx]) ->
    # TODO: use random member if no idx

    party = switch type
      when "enemy"
        @enemy_party
      when "player"
        @player_party
      else
        throw "unknown target type: #{type}"

    t = party.get idx
    if !t || t.is_dead()
      t = party.living_members().first()

    t

  # get a map of player orders,
  # returns mutable array of callbacks :o
  run_turn: (orders) ->
    enemy_orders = @enemy_party.members.map (enemy) ->
      [enemy.id, ["attack", ["player"]]]

    enemy_orders = Immutable.Map(enemy_orders).toJS()

    defenders = []

    actions = for battle_entity in @all_entities().toArray()
      battle_entity.defending = false
      entity = battle_entity.entity
      continue if entity.is_dead()

      order = if entity instanceof L.Player
        orders[battle_entity.id]
      else if entity instanceof L.Enemy
        enemy_orders[battle_entity.id]
      else
        throw "unknown battle entity for turn"


      if order && order[0] == "defend"
        defenders.push battle_entity

      @turn_event battle_entity, order

    if defenders.length
      actions.unshift =>
        for be in defenders
          console.debug "#{be.entity.name} defends"
          be.defending = true

    Immutable.List _.compact actions

  turn_event: (battle_entity, order) ->
    return unless order

    switch order[0]
      when "attack"
        =>
          target = @find_target order[1]
          if target
            target.take_hit battle_entity
      when "defend"
        # noop
        null
      else
        throw "don't know how to handle order #{order[0]}"


class L.BattleEntity
  constructor: (@id, @entity) ->
    @battle_stats = @entity.stats

  is_dead: =>
    @battle_stats.get("hp") <= 0

  take_hit: (attacker) ->
    console.debug "#{@entity.name} being hit by #{attacker.entity.name}"
    damage =  12

    if @defending
      damage = Math.floor damage / 2

    @battle_stats = @battle_stats.merge {
      hp: Math.max 0, @battle_stats.get("hp") - damage
    }

