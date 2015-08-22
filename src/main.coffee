
L.start = ->
  React.render R.Game(), document.body

R.component "Game", {
  render: ->
    div {
      className: "game_frame"
      children: [
        div className: "dialog_widget", "Is this even a game?"
        R.ChoiceDialog choices: [
          "Yes"
          "No"
        ]
      ]
    }
}

R.component "ChoiceDialog", {
  getInitialState: ->
    { selected_option: 0 }

  move_up: ->
    selected = @state.selected_option - 1

    if selected < 0
      selected = @props.choices.length - 1

    @setState selected_option: selected

  move_down: ->
    console.log "move down"
    @setState {
      selected_option: (@state.selected_option + 1) % @props.choices.length
    }

  componentDidMount: ->
    @unbind_keys = R.key_input {
      up: @move_up
      down: @move_down
      confirm: =>
        @trigger "confirm"

    }

  componentDidUnmount: ->
    @unbind_keys()

  render: ->
    console.log "selected:", @state.selected_option
    div {
      className: "choice_dialog_widget"
      children: @render_choices()
    }

  render_choices: ->
    for choice, i in @props.choices
      cls = if i == @state.selected_option
        "selected"
      else
        ""

      div className: "choice #{cls}", children: [
        div className: "selector"
        span className: "choice_label", choice
      ]
}
