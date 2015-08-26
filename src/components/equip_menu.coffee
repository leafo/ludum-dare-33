R.component "EquipMenu", {
  getInitialState: -> { }

  componentDidMount: ->
    @dispatch {
      choose: (e, val) ->
        console.log "choose", val

      cancel: =>
        @trigger "set_view", L.Game.default_view()...

    }

  render: ->
    div className: "equip_menu_component", children: [
      @render_player_picker()
    ]

  render_player_picker: ->
    R.ChoiceDialog {
      choices: for player, i in @props.game.party.to_array()
        [player.name, i]
    }

}
