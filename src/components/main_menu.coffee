
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
          when "heal"
            console.warn "Healing party"
            @props.game.heal_party()
            @trigger "refresh"

          when "battle"
            console.warn "Creating new battle"
            @trigger "set_view", "Battle", {
              battle: L.Factory.battle 1, @props.game
            }
    }

  render: ->
    div className: "main_menu_widget", children: [
      div className: "info_bar", R.RevealText text: "What do you want to do?"
      div className: "menu_columns", children: [
        div className: "options_column", children: [
          R.ChoiceDialog {
            classes: [
              if @state.erroring
                "animated shake"
            ]

            choices: _.compact [
              unless @props.game.party.is_dead()
                ["Battle", "battle"]
              ["Heal", "heal"]
            ]
          }

          div className: "frame", children: [
            div {}, "GOLT:"
            div {}, s.numberFormat @props.game.money
          ]
        ]

        div {
          className: "player_party"
          children: for p in @props.party.to_array()
            R.PlayerStatusRow { player: p }
        }
      ]
    ]
}


R.component "PlayerStatusRow", {
  render: ->
    player = @props.player

    hp = player.stats.get "hp"
    max_hp = player.stats.get "max_hp"

    mp = player.stats.get "mp"
    max_mp = player.stats.get "max_mp"

    div className: "player_status_row_widget frame", children: [
      div className: "primary_column",
        div {}, player.name
        div {},
          span className: "player_level", "Lv. #{player.level.get("level")}"
        "Next: #{s.numberFormat player.level.get("next_exp")  - player.level.get("exp")}"

      div className: "bar_column",
        R.ProgressBar {
          label: "HP: #{s.numberFormat hp}/#{s.numberFormat max_mp}"
          classes: ["hp_bar"]
          p: hp/max_hp
        }

        R.ProgressBar {
          label: "MP: #{s.numberFormat mp}/#{s.numberFormat max_mp}"
          classes: ["mp_bar"]
          p: mp/max_mp
        }
    ]
}


