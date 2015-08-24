R.component "InventoryMenu", {
  getInitialState: ->
    { highlighted_choice: null }

  componentDidMount: ->
    @dispatch {
      highlight_choice: (e, item) =>
        console.log "setting highlighted_choice", item
        @setState highlighted_choice: item
        e.stopPropagation()

      choose: (e, item) =>
        unless @props.game.inventory.items.first()
          # no items, go home
          @trigger "set_view", L.Game.default_view()...
          return

        console.log "do something with item.........."

      cancel: =>
        @trigger "set_view", L.Game.default_view()...
    }

  render: ->
    all_items = @props.game.inventory.items.toArray()
    message = @state.highlighted_choice?.description || "An item"

    div className: "inventory_menu_widget", children: [
      if all_items.length
        [
          div className: "info_bar", R.RevealText text: message
          R.ChoiceDialog {
            choices: for item in @props.game.inventory.items.toArray()
              [item.name, item]
          }
        ]
      else
        [
          div className: "frame", "You have no items"
          R.ChoiceDialog {
            choices: ["Return to menu"]
          }
        ]
    ]
}
