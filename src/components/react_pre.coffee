window.R = {}

R.key_listener = ->
  l = new keypress.Listener
  R.key_listener = -> l
  l

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
  cancel: ["escape"]
}

R.key_input = (tbl) ->
  l = R.key_listener()

  listeners = []

  for own key_name, fn of tbl
    if key_names = key_aliases[key_name]
      for key_name in key_names
        listeners.push {
          keys: key_name
          on_keydown: fn
        }
    else
      listeners.push {
        keys: key_name
        on_keydown: fn
      }

  unbind = l.register_many listeners
  -> l.unregister_many unbind

R.component = (name, data) ->
  data.trigger = ->
    R.trigger @, arguments...
    undefined

  data.dispatch = ->
    R.dispatch @, arguments...
    undefined

  data.extend_props = (more...) ->
    $.extend {}, @props, more...

  data.displayName = "R.#{name}"
  cl = React.createClass(data)
  R[name] = React.createFactory(cl)
  R[name]._class = cl

{
  div, span, a, p, ol, ul, li, strong, em, img, form, label, input, textarea,
  button, h1, h2, h3, h4, h5, h6, table, tbody, thead, tr, td
} = React.DOM
