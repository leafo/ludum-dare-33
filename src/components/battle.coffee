
R.component "Battle", {
  propTypes: {
    party: React.PropTypes.any.isRequired
  }

  getInitialState: ->
    {
      phase: "enter_commands"
      current_player: 0
      orders: Immutable.Map {}
    }

  componentDidUpdate: (prev_props, prev_state) ->
    if @state.phase == "executing" && prev_state.phase != "executing"
      console.log "orders:", @state.orders.toJS()

      setTimeout =>
        @setState @getInitialState()
      , 1000

  componentDidMount: ->
    @dispatch {
      undo_orders: (e, menu) =>
        next_player = @state.current_player - 1
        if next_player >= 0
          @setState {
            current_player: next_player
          }
        else
          @setState command_erroring: true
          $(menu).one "animationend", =>
            @setState command_erroring: false

      set_orders: (e, order) =>
        next_player = @state.current_player + 1

        phase = if next_player >= @props.party.members.size
          "executing"
        else
          @state.phase

        @setState {
          phase: phase
          orders: @state.orders.set @state.current_player, order
          current_player: next_player
        }

    }

  render: ->
    div {
      className: "battle_widget"
      children: [
        div className: "battle_interface", children: [
          R.BattleEnemyList @extend_props @state
          R.BattleParty @extend_props @state
          div className: "frame debug_frame", "Phase: #{@state.phase}"
        ]

        R.BattleField @extend_props @state
      ]
    }
}

R.component "BattleField", {
  propTypes: {
    enemy_party: React.PropTypes.any.isRequired
  }

  render: ->
    div className: "battle_field_widget", children: @render_enemies()

  render_enemies: ->
    for enemy in @props.enemy_party.to_array()
      div {
        className: "enemy_sprite"
        style: {
          background: "rgba(255,100,100,0.8)"
          width: "50px"
          height: "50px"
        }
      }
}

R.component "BattleEnemyList", {
  propTypes: {
    enemy_party: React.PropTypes.any.isRequired
  }

  render: ->
    div className: "enemy_list_widget frame", children: @render_enemies()

  render_enemies: ->
    for enemy in @props.enemy_party.to_array()
      div { className: "enemy_row" }, "#{enemy.name}"
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
    current = @props.party.get @props.current_player

    menus = for menu, i in @state.menu_stack.toArray()
      top = i == @state.menu_stack.size - 1

      switch menu
        when "action"
          R.ChoiceDialog {
            inactive: !top
            classes: if @props.command_erroring
              ["animated shake"]

            choices: [
              ["Attack", "attack"]
              ["Magic", "skill"]
              ["Defend", "defend"]
            ]
          }

        when "enemies"
          R.ChoiceDialog {
            inactive: !top
            choices: for e, id in @props.enemy_party.to_array()
              [e.name, ["enemy", id]]
          }

        when "players"
          R.ChoiceDialog {
            inactive: !top
            choices: for e, id in @props.party.to_array()
              [e.name, ["player", id]]
          }
        else
          throw "unknown menu in stack: #{menu}"

    div className: "dialog_stack", children: menus

  phase: (name) ->
    name == @props.phase

  render_party: ->
    frames = for player, i in @props.party.to_array()
      classes = if @phase("enter_commands") && @props.current_player == i
        "acitve"
      else
        ""

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
          "HP: #{player.stats.get("hp")} MP: #{player.stats.get("mp")}"
      ]

    div className: "player_frames", children: frames

}

