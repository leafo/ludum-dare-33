
L.start = ->
  React.render R.Game(), document.body

R.component "Game", {
  getInitialState: ->
    game = new L.Game

    [view, view_props] = L.Game.default_view()

    {
      view: view
      view_props: view_props
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

R.component "JointChoiceDialog", {
  getInitialState: -> { current_menu: 0 }
  getDefaultProps: -> { active: true }

  componentDidMount: ->
    @bind_keys()

  componentWillUnmount: ->
    @unbind_keys()

  ignore_input: ->
    !@props.active


  componentWillReceiveProps: (next_props) ->
    if @state.current_menu >= next_props.menus.length
      @setState {
        current_menu: next_props.menus.length - 1
      }

  move_left: ->
    return if @ignore_input()
    next_menu = @state.current_menu - 1
    if next_menu < 0
      next_menu = @props.menus.length - 1

    @setState {
      current_menu: next_menu
    }

  move_right: ->
    return if @ignore_input()
    @setState {
      current_menu: (@state.current_menu + 1) % @props.menus.length
    }

  bind_keys: ->
    if @_unbind_keys
      throw "keys already bound"

    @_unbind_keys = R.key_input {
      left: @move_left
      right: @move_right
    }

  unbind_keys: ->
    @_unbind_keys?()
    delete @_unbind_keys

  render: ->
    div className: "joint_choice_dialog", children: for menu, i in @props.menus
      R.ChoiceDialog @extend_props menu, {
        focus: @state.current_menu == i
      }

}

R.component "ChoiceDialog", {
  getInitialState: ->
    {
      selected_choice: 0
    }

  getDefaultProps: ->
    {
      active: true
      focus: true
    }

  move_up: ->
    return if @ignore_input()
    selected = @state.selected_choice - 1

    if selected < 0
      selected = @props.choices.length - 1

    @setState selected_choice: selected

  move_down: ->
    return if @ignore_input()
    @setState {
      selected_choice: (@state.selected_choice + 1) % @props.choices.length
    }

  bind_keys: ->
    @unbind_keys = R.key_input {
      up: @move_up
      down: @move_down
      cancel: =>
        return if @ignore_input()
        @trigger "cancel"

      confirm: =>
        return if @ignore_input()
        selected = @props.choices[@state.selected_choice]

        value = if selected instanceof Array
          selected[1]
        else
          selected

        @trigger "choose", value
    }

  ignore_input: ->
    !@props.active || !@props.focus

  componentDidMount: ->
    @bind_keys()

  componentWillUnmount: ->
    @unbind_keys?()

  render: ->
    classes = _.compact(@props.classes).join " "
    unless @props.active
      classes += " inactive"

    if @props.focus
      classes += " focused"

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

      cls = if @props.focus && i == @state.selected_choice
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
