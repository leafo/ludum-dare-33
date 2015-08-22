
L.start = ->
  React.render R.Game(), document.body

R.component "Game", {
  getInitialState: ->
    {
      view: "MainMenu"

      party: new L.Party [
        new L.Player "Sab"
        new L.Player "Lee"
        new L.Player "Iman"
      ]
    }

  componentDidMount: ->
    @dispatch {
      set_view: (e, view) =>
        @setState view: view
    }

  render: ->
    div {
      className: "game_frame"
      children: R[@state.view] @extend_props @state
    }
}

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
            @trigger "set_view", "Battle"
    }

  render: ->
    div className: "main_menu_widget", children: [
      div className: "dialog_widget", "What do you want to do?"
      R.ChoiceDialog {
        classes: if @state.erroring
          ["animated shake"]

        choices: [
          "Battle"
          "Nothing"
        ]
      }
    ]
}

R.component "ChoiceDialog", {
  getInitialState: ->
    { selected_choice: 0 }

  move_up: ->
    selected = @state.selected_choice - 1

    if selected < 0
      selected = @props.choices.length - 1

    @setState selected_choice: selected

  move_down: ->
    @setState {
      selected_choice: (@state.selected_choice + 1) % @props.choices.length
    }

  componentDidMount: ->
    @unbind_keys = R.key_input {
      up: @move_up
      down: @move_down
      cancel: =>
        @trigger "cancel"

      confirm: =>
        selected = @props.choices[@state.selected_choice]
        value = if selected instanceof Array
          selected[1]
        else
          selected

        @trigger "choose", value

    }

  componentWillUnmount: ->
    @unbind_keys()

  render: ->
    classes = _.compact(@props.classes).join " "

    div {
      className: "choice_dialog_widget #{classes}"
      children: @render_choices()
    }

  render_choices: ->
    for choice, i in @props.choices
      label = if choice instanceof Array
        choice[0]
      else
        choice

      cls = if i == @state.selected_choice
        "selected"
      else
        ""

      div className: "choice #{cls}", children: [
        div className: "selector"
        span className: "choice_label", label
      ]
}
