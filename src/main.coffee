
L.start = ->
  React.render R.Game(), document.body

R.component "Game", {
  render: ->
    div {
      className: "game_frame"
      children: [
        div className: "dialog_widget", "Is this even a game?"
        R.ChoiceDialog choices: [
          "One"
          "Two"
          "Three"
        ]
      ]
    }
}

R.component "ChoiceDialog", {
  getInitialState: ->
    { selected_option: 0 }

  componentDidMount: ->
    console.log "mounting dialog box"

  componentDidUnmount: ->
    console.log "unmounting dialog box"

  render: ->
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
