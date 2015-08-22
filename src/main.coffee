
L.start = ->
  React.render R.Game(), document.body

R.component "Game", {
  render: ->
    div { className: "game_frame" }, "Hello from react"
}
