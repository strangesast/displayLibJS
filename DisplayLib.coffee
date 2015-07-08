SVGNS = "http://www.w3.org/2000/svg"

class Base
  constructor: (@xy) ->
  
  # should never have a base class, but here for consistency
  type: 'Base' 

  newSVGElement: (kind, attributes) ->
    elem = document.createElementNS SVGNS, kind
    for attr of attributes
      elem.setAttribute attr, attributes[attr]
    elem

  set_hidden: (bool) ->
    visibility = if bool then 'hidden' else 'visible'
    @repr?.setAttribute 'visibility', visibility

  render_self: (visibility) ->
    r_attributes = 
      name: "#{@type}"
      transform: "translate(#{@xy.x}, #{@xy.y})"
      visibility: visibility

    if @name?
      r_attributes['id'] = "#{@type}_#{@name.replace(' ', '_')}"

    repr = @newSVGElement 'g', r_attributes

    b_attributes = 
      name: 'bounds'
      width: @xy.x_size
      height: @xy.y_size
      visibility: 'inherit'
      draggable: true

    if @render_color?
      b_attributes.fill = @render_color

    @bounds = @newSVGElement 'rect', b_attributes

    repr.appendChild @bounds

    return repr

  render: (visibility='visible') ->
    @repr = @render_self visibility

    return @repr

  # convert class instance to object
  serialize: (obj=@) ->
    ret = {}
    for prop of obj
      val = obj[prop]

      if val instanceof Array
        temp = []
        for each in val
          temp.push @serialize each
        ret[prop] = temp

      else if val instanceof Object and val.serialize?
        ret[prop] = val.serialize()

      else if typeof val in ["number", "string", "boolean", "null"]
        ret[prop] = val

    return ret

  # convert object back to class instance
  @deserialize = (obj) ->
    throw new Error('not a valid object') unless obj?.type?
    throw new Error('not in exports') unless exports[obj.type]?

    object = new exports[obj.type]

    for prop of obj
      val = obj[prop]
      if val instanceof Array
        temp = []
        for each in val
          temp.push @deserialize(each)
        object[prop] = temp
      else if val.type?
        object[prop] = @deserialize(val)
      else
        object[prop] = val

    return object


class XYInfo extends Base
  constructor: (@x=0, @y=0, @x_size=0, @y_size=0) ->

  type: 'XYInfo'

  clear: ->
    @x = 0
    @y = 0
    @x_size = 0
    @y_size = 0


class Template extends Base
  # name (string) used to idenitfy
  # panels (list) list of panel objects used to render template
  # elements (list) list of objects in panel
  # pixels (integer) number of pixels to represent one pixel on display
  # render_delay (integer) how long to wait before readjusting template in milliseconds
  constructor: (@name, @panels=[], @elements=[], @pixels=10, @render_delay=100) ->
    # adjust template extents for panels
    @extents = @recalculateExtents()

  # always same string (and case) as class name
  type: 'Template'

  set_hidden: (bool, what="all") ->
    switch what
      when "panels"
        for panel in @panels
          panel.set_hidden(bool)
      when "elements"
        for element in @elements
          element.set_hidden(bool)
      when "all"
        for each in @panels.concat @elements
          each.set_hidden(bool)
    null

  recalculateExtents: ->
    ext = {}
    for panel in @panels
      ext.x_low ?= panel.xy.x
      ext.y_low ?= panel.xy.y
      ext.x_high ?= panel.xy.x+panel.xy.x_size
      ext.y_high ?= panel.xy.y+panel.xy.y_size
      ext.x_low = Math.min ext.x_low, panel.xy.x
      ext.y_low = Math.min ext.y_low, panel.xy.y
      ext.x_high = Math.max ext.x_high, panel.xy.x+panel.xy.x_size
      ext.y_high = Math.max ext.y_high, panel.xy.y+panel.xy.y_size

    @extents = ext
    return @extents

  render_self: ->
    # create a new svg element for template, should have the option to use existing
    extents = @extents # required for scope change below

    # if no panels are defined initially, start out with a default size
    if Object.keys(extents).every((elem) -> extents[elem] == 0)
      extents = x_low: 0, y_low: 0, x_high: 50, y_high: 50
    
    # viewbox attribute value
    viewbox_str = [
      extents.x_low
      extents.y_low
      extents.x_high-extents.x_low
      extents.y_high-extents.y_low
    ].join(" ")

    repr = @newSVGElement 'svg',
      id: "#{@type}_#{@name.replace(' ', '_')}"
      name: "#{@type}"
      viewBox: viewbox_str
      width: (extents.x_high-extents.x_low)*@pixels
      height: (extents.y_high-extents.y_low)*@pixels


    return repr

  render: ->
    @currently_moving = null
    @extents = @recalculateExtents()
    repr = @render_self()

    scope = @
    move = (e) =>
      if @currently_moving?
        start = @currently_moving.start_position
        end =
          x: e.clientX
          y: e.clientY
        
        offsetx = (end.x - start.x)/@pixels
        offsety = (end.y - start.y)/@pixels
        elem = @currently_moving.element
        elem_repr = elem.repr
        elem_repr.setAttribute 'transform', "translate(#{elem.xy.x+offsetx}, #{elem.xy.y+offsety})"
        unless e.type == "mousemove"
          @currently_moving = null 
          elem.xy.x += Math.round offsetx
          elem.xy.y += Math.round offsety
          elem_repr.setAttribute 'transform', "translate(#{elem.xy.x}, #{elem.xy.y})"
          setTimeout ->
            scope.render.call(scope)
          , scope.render_delay
      null
   
    repr.addEventListener 'mousemove', move
    repr.addEventListener 'mouseup', move
    repr.addEventListener 'mouseout', move

    attachMoverListener = (elem) ->
      movestart = (e) ->
        scope.set_moving elem, e
      elem.bounds.addEventListener 'mousedown', movestart

    for panel in @panels
      panel_repr = panel.render()
      repr.appendChild panel_repr
      attachMoverListener panel

    for element in @elements
      element_repr = element.render()
      repr.appendChild element_repr
      #attachMoverListener element if element.bounds? # probably not necessary

    # if already defined (and presumably attached to a parent node) replace
    # that node with the new one
    if @repr then @repr.parentNode?.replaceChild repr, @repr

    @repr = repr
    return @repr

  # cooooool =>
  set_moving: (elem, e) =>
    @currently_moving = 
      element: elem
      start_position: 
        x: e.clientX
        y: e.clientY


class Panel extends Base
  # name (string) used to identify later, probably unnecessary
  # xy (xyinfo) position / size information
  constructor: (@name, @xy) ->

  type: 'Panel'

  render_color: 'rgba(120, 120, 120, 1.0)'


class Textbox extends Base
  # xy (xyinfo) position / size information
  constructor: (@xy, text) ->
    @elements = []
    if text
      @elements.push new Text(@xy, text)
  
  type: 'Textbox'

  render_color: 'rgba(140, 140, 140, 1.0)'

  render: (visibility='visible') ->
    repr = super visibility

    # elements is an array for now, for posibility of multiple texts
    for element in @elements
      element_repr = element.render('inherit')
      repr.appendChild element_repr

    @repr = repr

    return @repr


class Text extends Base
  constructor: (@xy, @text='undefined', @font_size="6px", @font_family="Sans Serif") ->

  type: 'Text'

  render_color: 'rgba(160, 160, 160, 1.0)'

  text_render_color: 'rgba(200, 200, 200, 1.0)'

  render_self: (visibility) ->
    repr = super visibility

    text = @newSVGElement 'text',
      x: 0
      y: 6
      fill: @text_render_color
      'font-family': @font_family
      'font-size': @font_size
      visibility: 'inherit'

    text.appendChild document.createTextNode @text

    repr.appendChild text

    return repr

  # different default value so this is necessary
  render: (visibility='inherit') ->
    @repr = super visibility

    return @repr

exports =
  'Base': Base
  'XYInfo': XYInfo
  'Template': Template
  'Panel': Panel
  'Textbox': Textbox
  'Text': Text

if module?
  module.exports = exports
else
  window.displayLib = exports
