
L.start = ->
  React.render R.Game(), document.body

R.component "Game", {
  getInitialState: ->
    game = new L.Game

    {
      view: "MainMenu"
      game: game
      party: game.party
    }

  componentDidMount: ->
    @dispatch {
      set_view: (e, view, view_props) =>
        @setState view: view, view_props: view_props

      refresh: =>
        @forceUpdate()
    }

  render: ->
    div {
      className: "game_frame"
      children: R[@state.view] @extend_props @state, @state.view_props
    }
}

R.component "ProgressBar", {
  render: ->
    classes = _.compact(@props.classes).join " "

    if @props.label?
      classes += " has_label"

    p = Math.min 1, Math.max 0, @props.p

    div {
      className: "progress_bar_widget #{classes}"
      style: { backgroundColor: @props.bg_color }
      children: [
        if @props.label
          div className: "progress_bar_label", @props.label

        div className: "progress_bar_track",
          if p > 0
            div className: "progress_bar_inner", style: {
              backgroundColor: @props.bg_color
              width: "#{Math.round p * 100}%"
            }
      ]
    },
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

  bind_keys: ->
    if @_unbind_keys
      throw "keys already bound"

    @_unbind_keys = R.key_input {
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

  unbind_keys: ->
    @_unbind_keys?()
    delete @_unbind_keys

  componentDidUpdate: (prev_props) ->
    if @props.inactive && !prev_props.inactive
      @unbind_keys()

    if !@props.inactive && prev_props.inactive
      @bind_keys()

  componentDidMount: ->
    @bind_keys() unless @props.inactive

  componentWillUnmount: ->
    @unbind_keys()

  render: ->
    classes = _.compact(@props.classes).join " "
    if @props.inactive
      classes += " inactive"

    div {
      className: "choice_dialog_widget frame #{classes}"
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


R.component "RevealText", {
  getDefaultProps: ->
    {
      rate: 20
      text: ""
    }

  getInitialState: ->
    { visible_characters: 1 }

  componentWillReceiveProps: (next_props) ->
    if next_props.text != @props.text
      @set_timer()

  componentDidMount: ->
    @set_timer()

  set_timer: ->
    if @state.timer
      window.clearInterval @state.timer

    @setState {
      visible_characters: 1
      timer: setInterval =>
        if @state.visible_characters >= @props.text.length
          window.clearInterval @state.timer
          @setState timer: null
        else
          @setState visible_characters: @state.visible_characters += 1
      , @props.rate
    }

  componentWillUnmount: ->
    return unless @state.timer
    window.clearInterval @state.timer

  render: ->
    div className: "reveal_text_widget", children: [
      span className: "visible_characters",
        @props.text.substring 0, @state.visible_characters

      span className: "hidden_characters",
        @props.text.substring @state.visible_characters
    ]
}
