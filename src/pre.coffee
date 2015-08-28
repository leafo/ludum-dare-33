window.L = {}

class L.Rand
  constructor: (seed) ->
    @r = new MersenneTwister seed

  rand_int: (min, max) ->
    @r.int() % (max - min + 1) + min

