
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
      set_view: (e, view, view_props) =>
        @setState view: view, view_props: view_props
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

    div {
      className: "progress_bar_widget #{classes}"
      style: { backgroundColor: @props.bg_color }
      children: [
        if @props.label
          div className: "progress_bar_label", @props.label

        div className: "progress_bar_track",
          div className: "progress_bar_inner", style: {
            backgroundColor: @props.bg_color
            width: "#{Math.round @props.p * 100}%"
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
