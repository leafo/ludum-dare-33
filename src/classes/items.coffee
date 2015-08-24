
class L.Inventory
  constructor: (@game) ->
    @items = Immutable.List()

  give: (item) ->
    throw "item already has inventory" if item.inventory?
    item.inventory = @
    @items = @items.push item

  remove: (item) ->
    before = @items.size
    @items = @items.filterNot (i) ->
      if i == item
        delete i.inventory
        true

  equipment: ->
    @items.filter (item) -> item.is_equipment()

  consumables: ->
    @items.filter (item) -> item.is_consumable()

  quantity: (item) ->
    @items.count (i) -> i.constructor == item.constructor

  stacked_items: (items=@items) ->
    items.groupBy((item) -> item.constructor).toList()

class L.Item
  @id: 0

  is_equipment: ->
    @ instanceof L.Equipment

  is_consumable: ->
    @ instanceof L.Consumable

  constructor: (name) ->
    @name = name if name?
    @stats = Immutable.Map()
    @id = @constructor.id
    @constructor.id += 1

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
    console.warn "using", @
    target.stats = target.stats.merge @stats.map (val, name) ->
      val = target.stats.get(name) + val
      val = Math.max 0, val
      if max = target.stats.get "max_#{name}"
        val = Math.min max, val

      val

    if @inventory
      @inventory.remove @
    else
      console.warn "used an item that's not in an inventory"

