window.R = {}

R.scope_event_name = (name) ->
  "leaf:#{name}"

R.trigger = (c, name, args...) ->
  $(c.getDOMNode()).trigger R.scope_event_name(name), [args...]

R.dispatch = (c, event_table) ->
  node = $ c.getDOMNode()

  for own event_name, fn of event_table
    node.on R.scope_event_name(event_name), fn

key_aliases = {
  confirm: ["space", "enter"]
}

R.key_input = (tbl) ->
  for own key_name, fn of tbl
    do (fn) ->
      wrapped = (e) ->
        e.preventDefault()
        fn()

      if key_names = key_aliases[key_name]
        for key_name in key_names
          key key_name, wrapped
      else
        key key_name, wrapped

  ->
    console.log "unbinding keys"

    for own key_name of tbl
      if key_names = key_aliases[key_name]
        for key_name in key_names
          key.unbind key_name
      else
        key.unbind key_name

R.component = (name, data) ->
  data.trigger = ->
    R.trigger @, arguments...
    undefined

  data.dispatch = ->
    R.dispatch @, arguments...
    undefined

  data.extend_props = (more_props) ->
    $.extend {}, @props, more_props

  data.displayName = "R.#{name}"
  cl = React.createClass(data)
  R[name] = React.createFactory(cl)
  R[name]._class = cl

{
  div, span, a, p, ol, ul, li, strong, em, img, form, label, input, textarea,
  button, h1, h2, h3, h4, h5, h6
} = React.DOM
