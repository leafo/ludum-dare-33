
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
    }

  componentDidUpdate: (prev_props, prev_state) ->
    if @state.phase == "executing" && prev_state.phase != "executing"
      events = @props.battle.run_turn @state.orders.toJS()
      console.debug "Got #{events.size} events..."
      @run_event events

  componentDidMount: ->
    @dispatch {
      undo_orders: (e, menu) =>
        party = @props.battle.player_party
        prev_player = party.next_living_member @state.current_player, -1

        if prev_player
          @setState current_player: prev_player.id
        else
          @setState command_erroring: true
          $(menu).one "animationend", =>
            @setState command_erroring: false

      set_orders: (e, order) =>
        party = @props.battle.player_party
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

  run_event: (events) ->
    events ||= @state.events
    next_event = events.first()
    if next_event
      next_event()
      if @props.battle.is_over()
        @props.battle.end_battle()
        @setState {
          phase: "finished"
          orders: Immutable.Map {}
          events: null
        }
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
    for enemy, idx in @props.battle.enemy_party.to_array()
      classes = _.compact([
        "enemy_sprite"
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
      stats = enemy.battle_stats

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

        switch top
          when "action"
            switch opt
              when "attack"
                @setState {
                  menu_stack: @state.menu_stack.push "enemies"
                  order_stack: orders
                }
                return
              when "skill"
                @setState {
                  menu_stack: @state.menu_stack.push "players"
                  order_stack: orders
                }
                return

        # fall through, send the orders
        @trigger "set_orders", orders
        @reset_menu()

    }

  render_battle_menu: ->
    return unless @props.phase == "enter_commands"
    # TODO: use this to customize menu
    current = @props.battle.player_party.get @props.current_player

    menus = for menu, i in @state.menu_stack.toArray()
      top = i == @state.menu_stack.size - 1

      switch menu
        when "action"
          R.ChoiceDialog {
            active: top
            classes: if @props.command_erroring
              ["animated shake"]

            choices: [
              ["Attack", "attack"]
              ["Magic", "skill"]
              ["Defend", "defend"]
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
        else
          throw "unknown menu in stack: #{menu}"

    div className: "dialog_stack", children: menus

  phase: (name) ->
    name == @props.phase

  render_party: ->
    frames = for battle_player, i in @props.battle.player_party.to_array()
      player = battle_player.entity
      battle_stats = battle_player.battle_stats

      classes = _.compact([
        if @phase("enter_commands") && @props.current_player == i
          "choosing_order"

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
          })[orders[0]]

        div {}, "#{player.name}"
        div { className: "stat_row" },
          "HP: #{battle_stats.get("hp")} MP: #{battle_stats.get("mp")}"
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
              if @props.battle.player_wins()
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

