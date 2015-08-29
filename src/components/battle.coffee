
class TimeoutSet
  constructor: (@opts) ->
    @items = Immutable.Set()
    @timeouts = Immutable.Set()

  add: (value, timeout=0) ->
    return if @items.includes value

    @items = @items.add value
    @opts.on_update?()

    t = window.setTimeout =>
      @items = @items.remove value
      @timeouts = @timeouts.remove t
      @opts.on_update?()
    , timeout

  to_array: ->
    @items.toArray()

  to_list: ->
    @items.toList()

  cleanup: ->
    for timeout in @state.indicator_timeouts.toJS()
      window.clearTimeout timeout

R.component "Battle", {
  propTypes: {
    party: React.PropTypes.any.isRequired
  }

  getInitialState: ->
    first_member = @props.battle.player_party.next_living_member()

    {
      phase: "enter_commands"
      current_player: first_member.id
      orders: Immutable.Map {}
      events: null

      battle_indicators: new TimeoutSet on_update: => @forceUpdate()
    }

  componentDidUpdate: (prev_props, prev_state) ->
    if @state.phase == "executing" && prev_state.phase != "executing"
      events = @props.battle.run_turn @state.orders.toJS()
      console.debug "Got #{events.size} events..."
      @run_event events

  componentWillUnmount: ->
    for timeout in @state.indicator_timeouts.toJS()
      clearTimeout timeout

  componentDidMount: ->
    @dispatch {
      undo_orders: (e, menu) =>
        party = @props.battle.player_party
        first_member = party.next_living_member()
        prev_player = party.next_living_member @state.current_player, -1

        if prev_player && first_member.id != @state.current_player
          @setState {
            current_player: prev_player.id
            orders: @state.orders.delete prev_player.id
          }
        else
          @setState command_erroring: true
          $(menu).one "animationend", =>
            @setState command_erroring: false

      set_orders: (e, order) =>
        party = @props.battle.player_party

        if order.first() == "macro"
          # we only have one macro right now, here's where we'd add more
          @setState {
            phase: "executing"
            orders: Immutable.Map party.members.map (bp) ->
              [bp.id, Immutable.List ["attack", ["enemy", "worst_hp"]]]
          }
          return

        if order.first() == "escape"
          @props.battle.escape()
          @end_battle()
          return

        next_player = party.next_living_member @state.current_player
        orders = @state.orders.set @state.current_player, order

        if next_player
          @setState {
            orders: orders
            current_player: next_player.id
          }
        else
          @setState {
            phase: "executing"
            orders: orders
          }

    }

  end_battle: ->
    @props.battle.end_battle()
    @setState {
      phase: "finished"
      orders: Immutable.Map {}
      events: null
    }

  run_event: (events) ->
    events ||= @state.events
    next_event = events.first()
    if next_event
      change = next_event()
      if change
        [target, delta] = change
        @state.battle_indicators.add change, 500

      if @props.battle.is_over()
        @end_battle()
      else
        @setState events: events.shift()
        setTimeout =>
          @run_event()

        , 100
    else
      # all done, reset
      @setState @getInitialState()

  render: ->
    div {
      className: "battle_widget"
      children: [
        div className: "battle_interface", children: [
          switch @state.phase
            when "finished"
              R.BattleVictory @extend_props @state
            else
              [
                R.BattleEnemyList @extend_props @state
                R.BattleParty @extend_props @state
                div className: "frame debug_frame",
                  "Phase: #{@state.phase}"
              ]
        ]

        R.BattleField @extend_props @state
      ]
    }
}

R.component "BattleField", {
  render: ->
    div className: "battle_field_widget", children: @render_enemies()

  render_enemies: ->
    indicators = @props.battle_indicators.to_list().groupBy ([be, damage]) -> be
    for enemy in @props.battle.enemy_party.to_array()
      classes = _.compact([
        "enemy_sprite"
        if indicators.get enemy
          "taking_hit"

      ]).join " "

      div {
        className: classes
        style: {
          opacity: if enemy.is_dead() then "0" else "1"
          background: "rgba(255,100,100,0.8)"
          width: "50px"
          height: "50px"
        }
      }
}

R.component "BattleEnemyList", {
  render: ->
    div className: "enemy_list_widget frame", children: @render_enemies()

  render_enemies: ->
    for enemy in @props.battle.enemy_party.to_array()
      stats = enemy.stats

      div { className: "enemy_row" }, "#{enemy.entity.name} (#{stats.get("hp")}/#{stats.get("max_hp")})"
}

R.component "BattleParty", {
  propTypes: {
    party: React.PropTypes.any.isRequired
  }

  getInitialState: ->
    {
      menu_stack: Immutable.List ["action"]
      order_stack: Immutable.List []
    }

  render: ->
    div {
      className: "party_widget"
      children: [
        @render_battle_menu()
        @render_party()
      ]
    }

  reset_menu: ->
    @setState @getInitialState()

  componentDidMount: ->
    @dispatch {
      cancel: (e) =>
        if @state.menu_stack.size > 1
          @setState {
            menu_stack: @state.menu_stack.pop()
            order_stack: @state.order_stack.pop()
          }
        else
          @trigger "undo_orders", e.target

      choose: (e, opt) =>
        top = @state.menu_stack.last()
        orders = @state.order_stack.push opt

        sub_menu = switch top
          when "action"
            switch opt
              when "macro"
                "macro"
              when "attack"
                "enemies"
              when "item"
                "items"
              when "skill"
                "players"
          when "items"
            "players"

        if sub_menu
          @setState {
            menu_stack: @state.menu_stack.push sub_menu
            order_stack: orders
          }
        else
          @trigger "set_orders", orders
          @reset_menu() if @isMounted()

    }

  on_first_member: ->
    first_member = @props.battle.player_party.next_living_member().id
    @props.current_player == first_member

  used_items: ->
    @props.orders.toList()
      .filter (order) =>
        order.first() == "item"
      .map (order) => order.get(1)

  available_items: ->
    @props.game.inventory.consumables()
      .toOrderedSet().subtract(@used_items()).toList()

  render_battle_menu: ->
    return unless @props.phase == "enter_commands"
    # TODO: use this to customize menu
    current = @props.battle.player_party.get @props.current_player
    first_member = @props.battle.player_party.next_living_member().id

    menus = for menu, i in @state.menu_stack.toArray()
      top = i == @state.menu_stack.size - 1

      switch menu
        when "action"
          R.JointChoiceDialog {
            active: top

            classes: if @props.command_erroring
              ["animated shake"]

            menus: _.compact [
              {
                choices: _.compact [
                  ["Attack", "attack"]
                  # ["Magic", "skill"]
                  unless @available_items().isEmpty()
                    ["Item", "item"]
                  ["Defend", "defend"]
                ]
              }

              if @on_first_member()
                {
                  choices: _.compact [
                    if @props.battle.player_party.living_members().size > 1
                      ["Macro", "macro"]

                    ["Escape", "escape"]
                  ]
                }
            ]
          }

        when "macro"
          R.ChoiceDialog {
            active: top
            choices: [
              ["ATK-ALL", "attack-all"]
            ]
          }
        when "enemies"
          enemies = @props.battle.enemy_party.living_members().toArray()

          R.ChoiceDialog {
            active: top
            choices: for e in enemies
              [e.entity.name, ["enemy", e.id]]
          }

        when "players"
          players = @props.battle.player_party.to_array()

          R.ChoiceDialog {
            active: top
            choices: for e in players
              [e.entity.name, ["player", e.id]]
          }

        when "items"
          stacked_items = @props.game.inventory.stacked_items @available_items()

          R.ChoiceDialog {
            active: top
            classes: "items_menu"
            choices: for item_stack in stacked_items.toArray()
              item = item_stack.first()
              [
                "#{item.name} x#{s.numberFormat item_stack.size}"
                item
              ]
          }
        else
          throw "unknown menu in stack: #{menu}"

    div className: "dialog_stack", children: menus

  phase: (name) ->
    name == @props.phase

  render_party: ->
    indicators = @props.battle_indicators.to_list().groupBy ([be, damage]) -> be

    frames = for battle_player, i in @props.battle.player_party.to_array()
      player = battle_player.entity
      stats = battle_player.stats

      classes = _.compact([
        if @phase("enter_commands") && @props.current_player == i
          "choosing_order"

        if indicators.get battle_player
          "taking_hit"

        if battle_player.is_dead()
          "dead"
      ]).join " "

      div className: "frame #{classes}", children: [
        if orders = @props.orders.get(i)
          orders = orders.toJS()
          div className: "current_order", ({
            attack: "ATK"
            defend: "DEF"
            skill: "SKL"
            item: "ITM"
          })[orders[0]]

        div {}, "#{player.name}"
        div { className: "stat_row" },
          "HP: #{stats.get("hp")} MP: #{stats.get("mp")}"
      ]

    div className: "player_frames", children: frames

}

R.component "BattleVictory", {
  getInitialState: ->
    { show_menu: false }

  componentDidMount: ->
    @dispatch {
      choose: =>
        @trigger "set_view", L.Game.default_view()...
    }

    setTimeout =>
      @setState show_menu: true
    , 200

  render: ->
    loot = @props.battle.loot()

    div className: "battle_victory_widget", children: [
      div className: "victory_columns", children: [
        div className: "summary_column", children: [
          div className: "frame", children: [
            div children: [
              if @props.battle.escaped
                "Escaped"
              else if @props.battle.player_wins()
                "Victory"
              else
                "Defeat"
            ]
            div {}, "EXP: #{s.numberFormat loot.get "exp"}"
            div {}, "GOLT: #{s.numberFormat loot.get "money"}"
          ]

          # div className: "frame", children: [
          #   div {}, "Found:"
          #   div {}, "Gold Butt"
          # ]

          if @state.show_menu
            R.ChoiceDialog {
              choices: [
                "Continue"
              ]
            }
        ]
        div className: "player_column",
          div className: "player_party", children: for bp in @props.battle.player_party.to_array()
            @render_player_row bp
      ]
    ]

  render_player_row: (bp) ->
    player = bp.entity
    exp = player.level.get "exp"
    max_exp = player.level.get "next_exp"

    classes = _.compact([
      if player.is_dead()
        "is_dead"
    ]).join " "

    div className: "frame player_row #{classes}", children: [
      div className: "name_row", children: [
        player.name
        span className: "player_level",
          "Lv. #{player.level.get("level")}"

        if player.is_dead()
          span className: "player_status", "DEAD"
      ]

      R.ProgressBar {
        label: "EXP: #{s.numberFormat exp}/#{s.numberFormat max_exp}"
        p: exp/max_exp
        classes: ["exp_bar"]
      }
    ]
}

