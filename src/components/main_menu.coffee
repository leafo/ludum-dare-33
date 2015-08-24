
R.component "MainMenu", {
  getInitialState: ->
    {
      menu_stack: Immutable.List ["main"]
      command_stack: Immutable.List()
    }

  componentDidMount: ->
    @dispatch {
      cancel: =>
        if @state.menu_stack.size > 1
          return @setState {
            menu_stack: @state.menu_stack.pop()
          }

        return if @state.erroring
        @setState erroring: true
        $(@getDOMNode()).one "animationend", =>
          @setState erroring: false

      choose: (e, val) =>
        e.stopPropagation()
        target = $(e.target)
        if target.is ".player_menu"
          command = @state.command_stack.first()
          switch command
            when "status"
              @trigger "set_view", "StatusMenu", {
                player: @props.game.party.get val
              }
            else
              throw "Unknow command #{command}"

        if target.is ".main_menu"
          switch val
            when "status"
              console.warn "Status party"
              @setState {
                command_stack: @state.command_stack.push "status"
                menu_stack: @state.menu_stack.push "choose_player"
              }

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
    message = switch @state.menu_stack.last()
      when "choose_player"
        "Choose a team member"
      else
        "What do you want to do?"

    div className: "main_menu_widget", children: [
      div className: "info_bar", R.RevealText text: message
      div className: "menu_columns", children: [
        div className: "options_column", children: [
          @render_menus()

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

  render_menus: ->
    div {
      className: "dialog_stack downward"
      children: for menu, i in @state.menu_stack.toArray()
        top = i == @state.menu_stack.size - 1

        switch menu
          when "main"
            R.ChoiceDialog {
              active: top
              classes: [
                "main_menu"
                if @state.erroring
                  "animated shake"
              ]

              choices: _.compact [
                unless @props.game.party.is_dead()
                  ["Battle", "battle"]
                ["Heal", "heal"]
                ["Status", "status"]
              ]
            }

          when "choose_player"
            R.ChoiceDialog {
              active: top
              classes: ["player_menu"]
              choices: for player, id in @props.game.party.to_array()
                [player.name, id]
            }
    }

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


