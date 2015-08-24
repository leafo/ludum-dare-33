
R.component "MainMenu", {
  getInitialState: -> {}

  componentDidMount: ->
    @dispatch {
      cancel: =>
        return if @state.erroring
        @setState erroring: true
        $(@getDOMNode()).one "animationend", =>
          @setState erroring: false

      choose: (e, val) =>
        e.stopPropagation()
        switch val
          when "Battle"
            console.warn "Creating new battle"

            enemies = new L.Party [
              new L.Enemy "Rags 1"
              new L.Enemy "Rags 2"
            ]

            battle = new L.Battle @props.party, enemies

            @trigger "set_view", "Battle", {
              battle: battle
              enemy_party: enemies
            }
    }

  render_player_status: (player) ->


  render: ->
    div className: "main_menu_widget", children: [
      div className: "info_bar", "What do you want to do?"
      div className: "menu_columns", children: [
        div className: "options_column", children: [
          R.ChoiceDialog {
            classes: [
              if @state.erroring
                "animated shake"
            ]

            choices: [
              "Battle"
              "Nothing"
            ]
          }

          div className: "frame", children: [
            div {}, "Golt:"
            div {}, "10000"
          ]

        ]

        div className: "player_party",
          content: (R.PlayerStatus { player: p } for p in @props.party.to_array())
        ]
    ]
}


R.component "PlayerStatus", {
  render: ->
    player = @props.player

    div className: "player_status_widget frame", children: [
      div className: "primary_column",
        div {}, player.name
        div {},
          span className: "player_level", "Lv. #{player.level.get("level")}"
        "Next: #{player.level.get("next_exp")  - player.level.get("exp")}"

      div className: "bar_column",
        R.ProgressBar {
          label: "HP: #{player.stats.get("hp")}/#{player.stats.get("max_hp")}"
          classes: ["hp_bar"]
          p: 0.5
        }

        R.ProgressBar {
          label: "MP: #{player.stats.get("mp")}/#{player.stats.get("max_mp")}"
          classes: ["mp_bar"]
          p: 0.5
        }
    ]
}


