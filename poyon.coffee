log = (args...)-> console.log(args...)
do($=jQuery)->
  class Facade
    defaults:
      warp: true
      scroll: true
      flick: true
      vertexNumber: 8
      warpLevel: 0.5
      warpAngularVelocity: 0.05
      spring: 0.015
      friction: 0.93

    constructor: (@$el, options)->
      @options = _.extend {}, @defaults, options
      throw "no radius parameter" unless @options.radius?

      @circle = new Circle(@options.vertexNumber, @options.radius)
      if @options.warp
        @circle = new WarpCircle(@circle, @options.warpLevel, @options.warpAngularVelocity)
      if @options.scroll
        @circle = new ScrollCircle(@circle, @options.spring, @options.friction)
      if @options.flick
        @circle = new FlickCircle(@circle, @$el, @options.spring, @options.friction)

      @render = new Render(@$el, @circle)

      @img = new PreloadImage(@$el.data("image"))
      @img.promise().then(@render.setImage)

      Timer.getInstance().add(@)

    update: =>
      @circle.update()
      @render.run()

  class Render
    constructor: (@$el, @circle)->
      [@width, @height] = [@$el.width(), @$el.height()]
      @offset = { x: @width * 0.5, y: @height * 0.5 }

      @ctx = @$el[0].getContext("2d")
      @ctx.fillStyle = @ctx.strokeStyle = "#e6e5e5"

    setImage: (img)=>
      @ctx.fillStyle = @ctx.createPattern(img, "repeat")

    run: =>
      @ctx.clearRect( 0, 0, @width, @height )
      @ctx.beginPath()
      @mainRendering()
      @ctx.closePath()
      @ctx.fill()

    mainRendering: =>
      start = @circle.at(-1).getCenter(@circle.at(0))
      start = Geometry.add(start, @offset)
      @ctx.moveTo(start.x, start.y)

      @circle.curvePointEach (sub, pos)=>
        sub = Geometry.add(sub, @offset)
        pos = Geometry.add(pos, @offset)
        @ctx.quadraticCurveTo(sub.x, sub.y, pos.x, pos.y)

      @ctx.stroke()

  class Circle
    VERTEX_NUM = 8

    constructor: (vertexNumber, @radius)->
      rot = 360.0 / vertexNumber
      @points = for i in [0...vertexNumber]
        rad = Math.PI * rot * i / 180
        [x,y] = [@radius * Math.cos(rad), @radius * Math.sin(rad)]
        new Point x, y

    at: (idx)=>
      idx = idx % @points.length
      idx += @points.length if idx < 0
      @points[idx]

    curvePointEach: (callback)=>
      for point, i in @points
        callback( point, point.getCenter(@at i+1) )

    update: (fix, pow)=>
      point.update() for point in @points

  class WarpCircle extends Circle
    constructor: (@circle, level, angularVelocity)->
      @points = (new WarpPoint(point, level, angularVelocity) for point in @circle.points)

  class ScrollCircle extends Circle
    constructor: (@circle, spring, friction)->
      @points = (new VelocityPoint(point, spring, friction) for point in @circle.points)

      ScrollSensor.getInstance().events.add(@onScroll)

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
    constructor: (@circle, @$el, spring, friction)->
      [width, height] = [@$el.width(), @$el.height()]
      @offset = { x: width * 0.5, y: height * 0.5 }

      @points = (new VelocityPoint(point, spring, friction) for point in @circle.points)
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

        mvStrength= Geometry.length(mv)
        mv = Geometry.multi(mv, 0.5 / mvStrength) if (mvStrength < 0.5)
        mv = Geometry.multi(mv, 3.5 / mvStrength) if (mvStrength > 3.5)

        for point in @points
          v = Geometry.sub(cross, point)
          dist = Geometry.length(v)

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
    constructor: (@point, @level, angularVelocity)->
      @myX = @myY = 0
      @theta = { x: 0, y: 0 }
      @addTheta =
        x: Math.random() * angularVelocity - angularVelocity * 0.5
        y: Math.random() * angularVelocity - angularVelocity * 0.5
      @warp = Math.random() * 24 - 12

    update: =>
      @point.update()
      @theta = Geometry.add(@theta, @addTheta)
      @myX = (@warp * Math.sin(@theta.x) * @level)
      @myY = (@warp * Math.cos(@theta.y) * @level)


  class VelocityPoint extends Point
    constructor: (@point, @spring, @friction)->
      @vX = @vY = 0
      @myX = @myY = 0

    update: =>
      @point.update()
      @myX += @vX = (@vX - @myX * @spring) * @friction
      @myY += @vY = (@vY - @myY * @spring) * @friction

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

  Singleton = (klass)->
    instance = null
    getInstance = => instance ?= new klass
    {getInstance}

  ScrollSensor = do->
    class InnerScrollSensor
      constructor: ->
        @events = $.Callbacks()
        @$win = $(window)
        @$win.on("scroll", _.throttle(@onScroll, 50))

      onScroll: (e)=>
        now= @$win.scrollTop()
        @prev ?= now
        diff = now - @prev
        @events.fire(diff)
        @prev = now

    Singleton(InnerScrollSensor)

  Timer = do->
    class InnerTimer
      TIME = 1000.0 / 60

      constructor: ->
        @list = []
        @start()

      start: =>
        @emit()
        @id = setTimeout(@start, TIME)

      stop: =>
        clearTimeout(@id)

      emit: =>
        elem.update() for elem in @list

      add: (elem)=>
        @list.push(elem)

      remove: (elem)=>
        @list = _.without(@list,elem)

    Singleton(InnerTimer)

  Geometry = do->
    length: length = (v)->
      [x,y] = [_.result(v,"x"), _.result(v,"y")]
      Math.sqrt( x * x + y * y )

    add: add = (a, b)->
      x: _.result(a,"x") + _.result(b,"x")
      y: _.result(a,"y") + _.result(b,"y")

    sub: sub = (a, b)->
      x: _.result(a,"x") - _.result(b,"x")
      y: _.result(a,"y") - _.result(b,"y")

    multi: multi = (v, m)->
      x: _.result(v,"x") * m
      y: _.result(v,"y") * m

    # a * b * cos
    dot: dot = (a,b)->
      _.result(a,"x") * _.result(b,"x") + _.result(a,"y") * _.result(b,"y")

    # a * b * sin
    cross: cross = (a, b)->
      _.result(a,"x") * _.result(b,"y") - _.result(a,"y") * _.result(b,"x")

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
    poyon: (options = {})->
      for dom in @
        $dom = $(dom)
        unless $.data($dom, "floatCanvas")?
          $.data $dom, "floatCanvas", if dom.getContext?
             new Facade($dom, options)
          else
            "This browser cannot use CANVAS function in html5."
