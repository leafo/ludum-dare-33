
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

        phase = if next_player >= @props.party.players.size
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
    for enemy in @props.enemy_party.players.toArray()
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
    for enemy in @props.enemy_party.players.toArray()
      div { className: "enemy_row" }, "#{enemy.name}"
}

R.component "BattleParty", {
  propTypes: {
    party: React.PropTypes.any.isRequired
  }

  render: ->
    div {
      className: "party_widget"
      children: [
        @render_battle_menu()
        @render_party()
      ]
    }

  componentDidMount: ->
    @dispatch {
      cancel: (e) =>
        @trigger "undo_orders", e.target

      choose: (e, opt) =>
        @trigger "set_orders", opt
    }

  render_battle_menu: ->
    return unless @props.phase == "enter_commands"
    current = @props.party.players.get(@props.current_player)

    R.ChoiceDialog {
      classes: if @props.command_erroring
        ["animated shake"]

      choices: [
        ["Attack", "attack"]
        ["Magic", "skill"]
        ["Defend", "defend"]
      ]
    }

  phase: (name) ->
    name == @props.phase

  render_party: ->
    frames = for player, i in @props.party.players.toArray()
      classes = if @phase("enter_commands") && @props.current_player == i
        "acitve"
      else
        ""

      div className: "frame #{classes}", children: [
        div {}, "#{player.name}"
        div { className: "stat_row" },
          "HP: #{player.stats.get("hp")} MP: #{player.stats.get("mp")}"
      ]

    div className: "player_frames", children: frames

}

