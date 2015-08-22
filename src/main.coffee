
L.start = ->
  React.render R.Game(), document.body

R.component "Game", {
  render: ->
    div {}, "Hello from react"
}
