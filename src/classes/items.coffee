
class L.Inventory
  constructor: ->
    @items = Immutable.List()

  give: (item) ->
    @items = @items.push item

  equipment: ->
    @items.filter (item) -> item.is_equipment()

  consumables: ->
    @items.filter (item) -> item.is_consumable()

class L.Item
  is_equipment: ->
    @ instanceof L.Equipment

  is_consumable: ->
    @ instanceof L.Consumable

  constructor: (name) ->
    @name = name if name?
    @stats = Immutable.Map()

class L.Equipment extends L.Item
  @slots: ["head", "arm", "body", "pant"]
  name: "unknown equip"
  slot: "head"
  description: "Can be equiped"

class L.Consumable extends L.Item
  name: "unknown food"
  description: "Can be consumed"

