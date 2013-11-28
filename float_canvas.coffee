class FloatCircle
  constructor: ->

  update: =>

  render: (context)=>
    context.beginPath()
    context.closePath()
    context.fill()

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

