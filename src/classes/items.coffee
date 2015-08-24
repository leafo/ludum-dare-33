
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

  constructor: ->
    super
    # heals 15
    @stats = Immutable.Map {
      hp: 15
    }

  use: (user, target) ->
    target.stats = target.stats.merge @stats.map (val, name) ->
      val = target.stats.get(name) + val
      val = Math.max 0, val
      if max = target.stats.get "max_#{name}"
        val = Math.min max, val

      val

