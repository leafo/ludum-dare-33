
R.component "StatusMenu", {
  componentDidMount: ->
    @dispatch {
      choose: =>
        @trigger "set_view", L.Game.default_view()...

      cancel: =>
        @trigger "set_view", L.Game.default_view()...
    }

  render: ->
    player = @props.player

    exp = player.level.get "exp"
    max_exp = player.level.get "next_exp"

    hp = player.stats.get "hp"
    max_hp = player.stats.get "max_hp"

    mp = player.stats.get "mp"
    max_mp = player.stats.get "max_mp"

    div className: "status_menu_widget", children: [
      div className: "options_column",
        R.ChoiceDialog {
          choices: [
            "Return"
          ]
        }

      div className: "status_column", children: [
        div className: "frame", children: [
          div children: [
            @props.player.name
            span className: "player_level", "Lv. #{player.level.get("level")}"
          ]

          R.ProgressBar {
            label: "HP: #{s.numberFormat hp}/#{s.numberFormat max_hp}"
            p: hp/max_hp
            classes: ["hp_bar"]
          }

          R.ProgressBar {
            label: "MP: #{s.numberFormat mp}/#{s.numberFormat max_mp}"
            p: hp/max_hp
            classes: ["mp_bar"]
          }

          R.ProgressBar {
            label: "EXP: #{s.numberFormat exp}/#{s.numberFormat max_exp}"
            p: exp/max_exp
            classes: ["exp_bar"]
          }

          table className: "stat_table", tbody {
            children: for stat in ["str", "def", "agi", "mag", "mdef"]
              tr {},
                (td {}, stat.toUpperCase() + ": "),
                (td {}, s.numberFormat player.stats.get stat)
          }
        ]
      ]
    ]
}
