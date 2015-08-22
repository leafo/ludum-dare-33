
R.component "Battle", {
  propTypes: {
    party: React.PropTypes.any.isRequired
  }

  getInitialState: ->
    {
      state: "enter_commands"
      current_player: 0
    }

  render: ->
    div {
      className: "battle_widget"
      children: [
        R.BattleParty @extend_props @state
      ]
    }
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
      choose: (e, opt) =>
        # @trigger "set_orders"
        console.log "chose", opt
    }

  render_battle_menu: ->
    return unless @props.state == "enter_commands"
    current = @props.party.players.get(@props.current_player)

    R.ChoiceDialog choices: [
      ["Attack", "attack"]
      ["Magic", "skill"]
      ["Defend", "defend"]
    ]

  render_party: ->
    frames = for player, i in @props.party.players.toArray()
      classes = if @props.state == "enter_commands" && @props.current_player == i
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

