R.component "InventoryMenu", {
  getInitialState: ->
    {
      menu_stack: Immutable.List ["inventory"]
      highlighted_item: null
      current_item: null
    }

  componentDidMount: ->
    @dispatch {
      highlight_choice: (e, item) =>
        if $(e.target).is ".inventory_menu"
          @setState highlighted_item: item
        e.stopPropagation()

      choose: (e, val) =>
        target = $(e.target)

        if target.is ".player_menu"
          @state.current_item.use null, val
          @setState {
            menu_stack: @getInitialState().menu_stack
            current_item: null
          }
          return

        if target.is ".inventory_menu"
          # no items, go home
          unless @props.game.inventory.items.first()
            @trigger "set_view", L.Game.default_view()...
            return

          if val.is_consumable()
            @setState {
              current_item: val
              menu_stack: @state.menu_stack.push "choose_player"
            }

          return

      cancel: =>
        if @state.menu_stack.size == 1
          @trigger "set_view", L.Game.default_view()...
        else
          @setState menu_stack: @state.menu_stack.pop()
    }

  render: ->
    div {
      className: "inventory_menu_widget"
      children: if @props.game.inventory.items.first()
        @render_items()
      else
        @render_empty_state()
    }

  render_items: ->
    message = @state.highlighted_item?.description || "An item"

    menus = for menu, i in @state.menu_stack.toArray()
      top = i == @state.menu_stack.size - 1
      switch menu
        when "inventory"
          stacks = @props.game.inventory.stacked_items().toArray()

          R.ChoiceDialog {
            active: top
            classes: ["inventory_menu"]
            choices: for item_stack in stacks
              item = item_stack.first()
              [
                [
                  "#{item.name}"
                  span { className: "item_quantity" },
                    "x#{s.numberFormat item_stack.size}"
                ]
                item
              ]
          }

        when "choose_player"
          R.ChoiceDialog {
            active: top
            classes: ["player_menu"]
            choices: for player, id in @props.game.party.to_array()
              ["#{player.name} #{player.summary_string()}", player]
          }

    [
      div className: "info_bar", R.RevealText text: message
      div className: "dialog_stack centered", children: menus
    ]

  render_empty_state: ->
    [
      div className: "frame", "You have no items"
      R.ChoiceDialog {
        choices: ["Return to menu"]
      }
    ]


}
