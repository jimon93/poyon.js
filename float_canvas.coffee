log = (args...)-> console.log(args...)
do($=jQuery)->
  class Core
    constructor: (@$el)->
      @width = @$el.width()
      @height = @$el.height()
      @o = { x: @width * 0.5, y: @height * 0.5 }

      @circle = new FloatingCircle(70)
      #@img = new PreloadImage
      @ctx = @$el[0].getContext("2d")

      Timer.getInstance().on =>
        @update()
        @render()


    update: =>
      @circle.update()

    render: =>
      @ctx.clearRect( 0, 0, @width, @height )
      @ctx.beginPath()

      [x,y] = @circle.last().getCenter(@circle.first())
      @ctx.moveTo(x + @o.x, y + @o.y)
      @circle.curvePointEach (sub, pos)=>
        @ctx.quadraticCurveTo(sub[0] + @o.x, sub[1] + @o.y, pos[0] + @o.x, pos[1] + @o.y)
      @ctx.stroke()

      @ctx.closePath()
      @ctx.fill()

  class FloatingCircle
    VERTEX_NUM = 8
    ROT = 360.0 / VERTEX_NUM

    constructor: (@radius)->
      @points = for i in [0..VERTEX_NUM]
        rad = Math.PI * ROT * i / 180
        [x,y] = [@radius * Math.cos(rad), @radius * Math.sin(rad)]
        new VelocityPoint(new WarpPoint(new Point x, y))

      @ss = ScrollSensor.getInstance()
      @ss.on(@onScroll)

    first: =>
      @points[0]

    last: =>
      @points[VERTEX_NUM-1]

    curvePointEach: (callback)=>
      for i in [0...VERTEX_NUM]
        now = @points[i]
        next = @points[(i + 1) % VERTEX_NUM]
        callback( now.getPosition(), now.getCenter(next) )

    update: (fix, pow)=>
      point.update() for point in @points

    onScroll: (diff)=>
      return if diff == 0
      diff *= 0.0018
      for point, idx in @points
        if diff < 0
          pow = diff * point.y() / 100
          pow *= 2.6 if idx == 2
          pow -= 0.1
        else
          pow = diff * (190 - point.y()) / 100
          pow *= 2.6 if idx == 6
          pow += 0.1
        point.vY -= pow

  class Circle

  class RandomCircle

  class ScrollCircle

  class FlickCircle

  class Point
    constructor: (@myX, @myY)->

    update:=>

    x:=> @myX + (if @point? then @point.x() else 0)
    y:=> @myY + (if @point? then @point.y() else 0)
    getPosition: => [@x(), @y()]
    getCenter: (other)=>
      [(@x() + other.x()) * 0.5, (@y() + other.y()) * 0.5]

  class WarpPoint extends Point
    FIX = 0.5
    constructor: (@point)->
      @myX = @myY = 0
      @thetaX = @thetaY = 0
      @addThetaX = Math.random() * 0.05 - 0.025
      @addThetaY = Math.random() * 0.05 - 0.025
      @warp = Math.random() * 24 - 12

    update: =>
      @point.update()
      @thetaX += @addThetaX
      @thetaY += @addThetaY
      @myX = (@warp * Math.sin(@thetaX) * FIX)
      @myY = (@warp * Math.cos(@thetaY) * FIX)

  class WarpPoint extends Point
    FIX = 0.5
    constructor: (@point)->
      @myX = @myY = 0
      @thetaX = @thetaY = 0
      @addThetaX = Math.random() * 0.05 - 0.025
      @addThetaY = Math.random() * 0.05 - 0.025
      @warp = Math.random() * 24 - 12

    update: =>
      @point.update()
      @thetaX += @addThetaX
      @thetaY += @addThetaY
      @myX = (@warp * Math.sin(@thetaX) * FIX)
      @myY = (@warp * Math.cos(@thetaY) * FIX)


  class VelocityPoint extends Point
    SPRING = 0.015
    FRICTION = 0.93
    constructor: (@point)->
      @vX = @vY = 0
      @myX = @myY = 0

    update: =>
      @point.update()
      @myX += @vX = (@vX - @myX * SPRING) * FRICTION
      @myY += @vY = (@vY - @myY * SPRING) * FRICTION

  class PreloadImage
    constructor: (@src)->
      @_dfd = new $.Deferred
      img = new Image
      img.onload = @_onLoad
      img.src = @src

    promise: =>
      @_dfd.promise()

    _onLoad: =>
      @_dfd.resolve(@src)

  class Events
    constructor: ->
      @callbacks = []

    on: (callback)=>
      @callbacks.push callback

    off: (callback)=>
      @callbacks = _.without(@callbacks, callback)

    emit: (args...)=>
      callback(args...) for callback in @callbacks

  Singleton = (klass)->
    instance = null
    getInstance = => instance ?= new klass
    {getInstance}

  ScrollSensor = do->
    class InnerScrollSensor extends Events
      constructor: ->
        super
        @$win = $(window)
        @$win.on("scroll", _.throttle(@onScroll, 50))

      onScroll: (e)=>
        now= @$win.scrollTop()
        @prev ?= now
        diff = now - @prev
        @emit(diff)
        @prev = now

    Singleton(InnerScrollSensor)

  Timer = do->
    class InnerTimer extends Events
      TIME = 1000.0 / 30
      constructor: ->
        super
        @start()

      start: =>
        @emit()
        @id = setTimeout(@start, @time)

      stop: =>
        clearTimeout(@id)

    Singleton(InnerTimer)

  $.fn.extend
    floatCanvas: (options)->
      for obj in @
        new Core($(obj), options)
