
L.start = ->
  React.render R.Game(), document.body

R.component "Game", {
  render: ->
    div { className: "game_frame" },
      div className: "dialog_widget", "Is this even a game?"
}
