log = (args...)-> console.log(args...)
do($=jQuery)->
  class Facade
    defaults:
      radius: 70
      warpLevel: 0.5
      spring: 0.015
      friction: 0.93

    constructor: (@$el, options)->
      @options = _.extend {}, @defaults, options

      @width = @$el.width()
      @height = @$el.height()
      @offset = { x: @width * 0.5, y: @height * 0.5 }

      @circle = new Circle(@options.radius)
      @circle = new RandomCircle(@circle)
      @circle = new ScrollCircle(@circle)
      @circle = new FlickCircle(@circle, @$el, @offset)

      @img = new PreloadImage(@$el.data("image"))
      @img.promise().then(@onImage)

      @ctx = @$el[0].getContext("2d")
      @ctx.fillStyle = @ctx.strokeStyle = "#e6e5e5"

      Timer.getInstance().on(@onTimer)

    onTimer: =>
      @update()
      @render()

    onImage: (img)=>
      @ctx.fillStyle = @ctx.createPattern(img, "repeat")

    update: =>
      @circle.update()

    render: =>
      @ctx.clearRect( 0, 0, @width, @height )
      @ctx.beginPath()

      start = @circle.at(-1).getCenter(@circle.at(0))
      start = Geometry.add(start, @offset)
      @ctx.moveTo(start.x, start.y)

      @circle.curvePointEach (sub, pos)=>
        sub = Geometry.add(sub, @offset)
        pos = Geometry.add(pos, @offset)
        @ctx.quadraticCurveTo(sub.x, sub.y, pos.x, pos.y)

      @ctx.stroke()

      @ctx.closePath()
      @ctx.fill()

  class Circle
    VERTEX_NUM = 8
    ROT = 360.0 / VERTEX_NUM

    constructor: (@radius)->
      @points = for i in [0..VERTEX_NUM]
        rad = Math.PI * ROT * i / 180
        [x,y] = [@radius * Math.cos(rad), @radius * Math.sin(rad)]
        new Point x, y

    at: (idx)=>
      idx = idx % VERTEX_NUM
      idx += VERTEX_NUM if idx < 0
      @points[idx]

    curvePointEach: (callback)=>
      for i in [0...VERTEX_NUM]
        now = @points[i]
        next = @points[(i + 1) % VERTEX_NUM]
        callback( now, now.getCenter(next) )

    update: (fix, pow)=>
      point.update() for point in @points

  class RandomCircle extends Circle
    constructor: (@circle)->
      @points = (new WarpPoint(point) for point in @circle.points)

  class ScrollCircle extends Circle
    constructor: (@circle)->
      @points = (new VelocityPoint(point) for point in @circle.points)

      @ss = ScrollSensor.getInstance()
      @ss.on(@onScroll)

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

  class FlickCircle extends Circle
    constructor: (@circle, @$el, @offset)->
      @points = (new VelocityPoint(point) for point in @circle.points)
      @prevMouse = null
      @$el.on("mousemove", _.throttle(@onMouseMove,0.03))
      @$el.on("mouseover", @onMouseOver)

    onMouseMove: (e)=>
      rect = e.target.getBoundingClientRect()
      mouse =
        x: e.clientX - rect.left - @offset.x
        y: e.clientY - rect.top  - @offset.y

      @flick(mouse) if @prevMouse?
      @prevMouse = mouse

    onMouseOver: (e)=>
      @prevMouse = null

    flick: (mouse)=>
      mv = Geometry.sub(mouse, @prevMouse)

      res = for now, i in @points
        next = @at(i+1)
        Geometry.isIntersection(now, next, @prevMouse, mouse)

      if _.any(res)
        cross = Geometry.intersectionPoint(now, next, @prevMouse, mouse)

        mvStrength= Geometry.abs(mv)
        mv = Geometry.multi(mv, 0.5 / mvStrength) if (mvStrength < 0.5)
        mv = Geometry.multi(mv, 3.5 / mvStrength) if (mvStrength > 3.5)

        for point in @points
          v = Geometry.sub(cross, point)
          dist = Geometry.abs(v)

          pow = 10 / dist
          pow = 0.2 if pow < 0.2
          pow = 1   if 1 < pow or _.isNaN(dist)


          point.vX += pow * mv.x
          point.vY += pow * mv.y

  class Point
    constructor: (@myX, @myY)->

    update:=>

    x:=> @myX + (if @point? then @point.x() else 0)
    y:=> @myY + (if @point? then @point.y() else 0)
    getCenter: (other)=>
      x: (@x() + other.x()) * 0.5
      y: (@y() + other.y()) * 0.5

  class WarpPoint extends Point
    FIX = 0.5
    RADIUS = 0.05

    constructor: (@point)->
      @myX = @myY = 0
      @theta = { x: 0, y: 0 }
      @addTheta =
        x: Math.random() * RADIUS - RADIUS * 0.5
        y: Math.random() * RADIUS - RADIUS * 0.5
      @warp = Math.random() * 24 - 12

    update: =>
      @point.update()
      @theta = Geometry.add(@theta, @addTheta)
      @myX = (@warp * Math.sin(@theta.x) * FIX)
      @myY = (@warp * Math.cos(@theta.y) * FIX)


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
      @img = new Image
      @img.onload = @_onLoad
      @img.src = @src

    promise: =>
      @_dfd.promise()

    _onLoad: =>
      @_dfd.resolve(@img)

  class Events
    constructor: ->
      @callbacks = $.Callbacks()

    on: (callback)=>
      @callbacks.add(callback)

    off: (callback)=>
      @callbacks.remove(callback)

    emit: (args...)=>
      @callbacks.fire(args...)

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

  Geometry = do->
    peel = (obj,key)->
      switch
        when _(obj[key]).isFunction() then obj[key]()
        else obj[key]

    abs: abs = (v)->
      [x,y] = [peel(v,"x"), peel(v,"y")]
      Math.sqrt( x * x + y * y )

    add: add = (a, b)->
      x: peel(a,"x") + peel(b,"x")
      y: peel(a,"y") + peel(b,"y")

    sub: sub = (a, b)->
      x: peel(a,"x") - peel(b,"x")
      y: peel(a,"y") - peel(b,"y")

    multi: multi = (v, m)->
      x: peel(v,"x") * m
      y: peel(v,"y") * m

    # a * b * cos
    dot: dot = (a,b)->
      peel(a,"x") * peel(b,"x") + peel(a,"y") * peel(b,"y")

    # a * b * sin
    cross: cross = (a, b)->
      peel(a,"x") * peel(b,"y") - peel(a,"y") * peel(b,"x")

    isIntersectionHalf : iih = (start, end, o1, o2)->
      v = sub(end,start)
      a = sub(o1, start)
      b = sub(o2, start)
      0 <= dot(v,a) and 0 <= dot(v,b) and cross(v,a) * cross(v,b) <= 0

    isIntersection: (start1, end1, start2, end2)->
      iih(start1,end1, start2, end2) and iih(end1, start1, start2, end2)

    intersectionPoint: (start1, end1, start2, end2)->
      v = sub(end2, start2)
      d1 = cross v, sub(start1, start2)
      d2 = cross v, sub(start2, start2)
      t = d1 / (d1 + d2)
      add start2, multi(v, t)

  $.fn.extend
    floatCanvas: (options = {})->
      for dom in @
        $dom = $(dom)
        unless $.data($dom, "floatCanvas")?
          $.data $dom, "floatCanvas", new Facade($dom, options)


### options
radius
warpLevel
spring
friction
###
