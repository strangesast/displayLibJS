SVGNS = "http://www.w3.org/2000/svg"

CMD_NONE = 0
MSG_NONE = 0
MSG_RECT = 101
MSG_TEXTBOX = 110;
MSG_TEXT = 150
MSG_PANELDEF = 151
MSG_TEXTBOX_CMD = 161
MSG_GENERIC_CMD = 160
MSG_TIMER_CMD = 162
MSG_DISPLAY_CMD = 163
S_PARTICULAR_CONTROL = 1

ObjectCategory = Object.freeze(
  OC_UNSPECIFIED: 0
  OC_CONTROL: 1
  OC_SHAPE: 2
  OC_DATA: 3
  OC_COMMAND: 4
)

ProtocolCode = Object.freeze(
  MSG_END: 0x01
  MSG_START: 0x02
  START_ARRAY: 0x03
  END_ARRAY: 0x04
  START_TEXT: 0x05
  END_ELEMENT: 0x06
  START_NUMBER_POS: 0x07
  START_NUMBER_NEG: 0x08
  FIRST_LEGAL_CHAR: 0x09
  MAGIC_NUMBER: 0x87
)

DisplayAttribute = Object.freeze(
  DA_NONE: 0
  DA_NORMAL: 1
  DA_HIDDEN: 2
  DA_FLASHING: 3
  DA_TBD_1: 10
)

GenericScope = Object.freeze(
  GS_NONE: -1
  GS_APPLIES_TO_ALL: -2
)

ScrollCommand = Object.freeze
  SCROLL_NONE: -1
  SCROLL_AUTO_BY_LINE: 0
  SCROLL_AUTO_BY_PAGE: 1
  SCROLL_MANUAL: 2
  SCROLL_PAUSE: 10
  SCROLL_RESUME: 11
  SCROLL_UP: 12
  SCROLL_DOWN: 13
  SCROLL_TO_TOP: 14
  SCROLL_TO_BOTTOM: 15
  SCROLL_TO_POSITION: 16

ScrollOrientation = Object.freeze
  SO_NONE: -1
  SO_NOSCROLL: 1
  SO_SCROLL_H: 2
  SO_SCROLL_V: 3

ScrollEffect = Object.freeze
  SE_NONE: -1
  SE_NORMAL: 0
  SE_SPORTSYNC: 1
	SE_DIVIDER_BETWEEN_POSTS: 2

MessageCommand = Object.freeze
  MESSAGE_NONE: -1
  MESSAGE_SELECT: 0
  MESSAGE_CYCLE_OFF: 1
  MESSAGE_CYCLE_ON: 2
  MESSAGE_CYCLE_PAUSE: 3
  MESSAGE_CYCLE_RESUME: 4
  MESSAGE_NEXT: 5
  MESSAGE_PREV: 6
  MESSAGE_FIRST: 7
  MESSAGE_LAST: 8
  MESSAGE_CREATE: 10
  MESSAGE_DELETE: 11
  MESSAGE_CYCLE_RATE: 20
  MESSAGE_POSTS_MAX: 21

TextAction = Object.freeze
  TEXT_NOACTION:0
  TEXT_APPEND: 1
  TEXT_REPLACE: 2
  TEXT_CLEAR: 3

TextFlag = Object.freeze
  TF_NONE: 0
  TF_LINEBREAK: 1
  TF_MSGEND: 2

PanelGeometry = Object.freeze
  PG_NOT_SPECIFIED: 0
  PG_SINGLE: 1
  PG_SIDEBYSIDE: 2
  PG_FOURSQUARE: 3

PanelPosition = Object.freeze
  PP_NOT_SPECIFIED:0
  PP_L: 1
  PP_R: 2
  PP_TL: 1
  PP_TR: 2
  PP_BL: 3
  PP_BR: 4

PanelLayout = Object.freeze
  PL_NORMAL: 0
  PL_REVERSED: 1

DisplayRequest = Object.freeze
  DISPLAY_NO_REQUEST: 0
  DISPLAY_CLEAR: 1

UpdateType = Object.freeze
  UPDATE_NONE: 0
  UPDATE_SPECIFIED_ITEMS: 1
  UPDATE_ALL: 2

class Color
  constructor: (red, green, blue, intensity) ->
    @value = -1
    #test for being called with no arguments
    if typeof red == "undefined"
      @value = -1
    #test for called with only 3 arguments
    else if typeof intensity == "undefined"
      @value = 0x7f000000 + ((red & 0xff)<< 16) + ((green & 0xff) << 8) + (blue & 0xff)
    else
      l_intensity = 100;
      if (intensity > 0 && intensity < 100)
        l_intensity = intensity
      @value = (l_intensity << 24) + ((red & 0xff)<< 16) + ((green & 0xff) << 8) + (blue & 0xff)
  red: () ->
    return (@value >> 16) & 0xff
  green: () ->
    return (@value>>8) & 0xff
  blue: () ->
    return @value & 0xff
  RGB: (red, green, blue, intensity) ->
    l_intensity = 100
    if (typeof intensity != "undefined" && intensity > 0 && intensity < 100)
      l_intensity = intensity
    @value = (l_intensity << 24) + ((red & 0xff)<< 16) + ((green & 0xff) << 8) + (blue & 0xff);
  get_intensity: () ->
    intensity = (@value & 0x7f000000) >> 24;
    if (intensity > 100 || intensity < 0)
      intensity = 100;
    return intensity;
  
  set_intensity: (intensity) ->
    if (intensity < 0 || intensity > 100)
      intensity = 100
    @value = (@value & 0x00ffffff) | (intensity << 24)

  set_empty: () ->
    @value = -1
  is_empty: () ->
    return @value & 0xff000000 == 0xff000000
  get_value: () ->
    return @value

class Base
  constructor: (@xy) ->
    @type=0
    @category=ObjectCategory.OC_UNSPECIFIED
    @layer=-1
    @panel=-1
    @control=-1
    @parent_control=-1
    @is_final=0;
    @display_attribute=DisplayAttribute.DA_NONE
  
  # should never have a base class, but here for consistency
  string_type: 'Base'
  type: 0

  encodeint: (value, encoded_buffer, pos) ->
    if value < 0
      value = -value
      encoded_buffer[pos] = ProtocolCode.START_NUMBER_NEG
    else
      encoded_buffer[pos] = ProtocolCode.START_NUMBER_POS

    pos++
    while value > 0
      encoded_buffer[pos] = 0x30 + (value & 0x0f)
      pos++
      value = value >> 4
    encoded_buffer[pos] = ProtocolCode.END_ELEMENT
    pos++
    return pos
  
  encodestring: (string_value, encoded_buffer, pos) ->
    throw new Error "#{string_value} is not a string" unless typeof string_value == 'string'
    encoded_buffer[pos] = ProtocolCode.START_TEXT
    pos++
    for char, i in string_value
      if string_value.charCodeAt i < ProtocolCode.FIRST_LEGAL_CHAR
        continue
      encoded_buffer[pos] = string_value.charCodeAt i
      pos++
    encoded_buffer[pos] = ProtocolCode.END_ELEMENT
    return pos++

  decodeint: (encoded_buffer, pos) ->
    is_negative = false
    if encoded_buffer[pos] == ProtocolCode.START_NUMBER_POS
    else if encoded_buffer[pos] == ProtocolCode.START_NUMBER_NEG
      is_negative = true
    else
      result_int: 0
      result_pos: 0

  decodestring: (encoded_buffer, pos) ->
    if encoded_buffer[pos] !=  ProtocolCode.START_TEXT
      return 0
    while true
      if encoded_buffer[pos] == ProtocolCode.END_ELEMENT
        pos++
        break
      else if encoded_buffer[pos] < ProtocolCode.FIRST_LEGAL_CHAR
        break
      return_string = return_string + encoded_buffer[pos]
    return result_str: return_string, result_pos: pos


  buildmessagecontents: (msg_buffer, pos) ->
    pos

  buildmessage: ->
    msg_buffer = new Buffer 2000
    pos = 0

    msg_buffer[pos] = ProtocolCode.MSG_START
    pos++
    msg_buffer[pos] = ProtocolCode.MAGIC_NUMBER
    pos++
    pos = @encodeint @type, msg_buffer, pos

    scope = @

    pos = [
      @layer
      @panel
      @control
      @parent_control
      @is_final
      @display_attribute
    ].reduce (prev, curr, i) ->
      scope.encodeint.call scope, curr, msg_buffer, prev
    , pos

    pos = @buildmessagecontents msg_buffer, pos
    msg_buffer[pos] = ProtocolCode.MSG_END
    pos++

    return result_buffer: msg_buffer, result_bytes: pos




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
      name: "#{@string_type}"
      transform: "translate(#{@xy.x}, #{@xy.y})"
      visibility: visibility

    if @name?
      r_attributes['id'] = "#{@string_type}_#{@name.replace(' ', '_')}"

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
    throw new Error('not a valid object') unless obj?.string_type?
    throw new Error('not in exports') unless exports[obj.string_type]?

    object = new exports[obj.string_type]

    for prop of obj
      val = obj[prop]
      if val instanceof Array
        temp = []
        for each in val
          temp.push @deserialize(each)
        object[prop] = temp
      else if val.string_type?
        object[prop] = @deserialize(val)
      else
        object[prop] = val

    return object

class XYInfo extends Base
  constructor: (@x=0, @y=0, @x_size=0, @y_size=0) ->
    @string_type='XYInfo'

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
  string_type: 'Template'

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

  # determine absolute position / size for rendering and serializing
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

    for panel in @panels
      pos = new XYInfo(
        ext.x_low
        ext.y_low
        ext.x_high-ext.x_low
        ext.y_high-ext.y_low
      )
      panel.total_size = pos

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
      id: "#{@string_type}_#{@name.replace(' ', '_')}"
      name: "#{@string_type}"
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
      attachMoverListener panel if panel.move_unlocked? == true

    for element in @elements
      element_repr = element.render()
      repr.appendChild element_repr
      attachMoverListener element if element.bounds? and element.move_unlocked? == true # probably not necessary

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

  buildmessage: ->
    temp = []
    for panel, i in @panels
      message = panel.buildmessage()
      temp.push message

    for element, i in @elements
      is_final = if i+1 == @elements.length then 1 else 0

      if element.elements?.length > 0
        message = element.buildmessage()
        temp.push message
        for child, j in element.elements
          is_final = if j+1 == element.elements.length then is_final else 0
          child.is_final = is_final
          temp.push child.buildmessage()
      else
        element.is_final
        message = element.buildmessage()
        temp.push message

    return temp


class Panel extends Base
  # name (string) used to identify later, probably unnecessary
  # xy (xyinfo) position / size information
  # total_size (xyinfo) template position / size information
  constructor: (
    @name
    @xy=new XYInfo()
    @move_unlocked = true
    @total_size=new XYInfo()
    @fg_color= new Color()
    @bg_color= new Color()
    @geometry = PanelGeometry.PG_NOT_SPECIFIED
    @position = PanelPosition.PP_NOT_SPECIFIED
    @layout = PanelLayout.PL_NORMAL
  ) ->
    @type = MSG_PANELDEF
    @string_type = 'Panel'

  render_color: 'rgba(120, 120, 120, 1.0)'

  buildmessagecontents: (msg_buffer, pos) ->
    scope = @
    pos = [
      @fg_color.value
      @bg_color.value
      @geometry
      @position
      @layout
      @xy.x
      @xy.y
      @xy.x_size
      @xy.y_size
      @total_size.x
      @total_size.y
      @total_size.x_size
      @total_size.y_size
    ].reduce (prev, curr, i) ->
      scope.encodeint.call scope, curr, msg_buffer, prev
    , pos

    return pos



class Textbox extends Base
  # xy (xyinfo) position / size information
  constructor: (
    @xy=new XYInfo()
    text
    @move_unlocked = true
    @text_xy = new XYInfo()
    @fg_color= new Color(200, 200, 200, 100)
    @bg_color= new Color()
    @border_color = new Color(160, 0, 0, 100)
    @border_width = 1
    @scroll_type = 3
    @preferred_font = ""
  ) ->
    @type = MSG_TEXTBOX
    @string_type = 'Textbox'
    @elements = []
    if text
      t = new Text(@text_xy, text, @control)
      @elements.push new Text(@text_xy, text)
  

  buildmessagecontents: (msg_buffer, pos) ->
    scope = @

    pos = [
      @xy.x
      @xy.y
      @xy.x_size
      @xy.y_size
      @fg_color.value
      @bg_color.value
      @border_color.value
      @border_width
      @text_xy.x
      @text_xy.y
      @text_xy.x_size
      @text_xy.y_size
      @char_buffer_size
    ].reduce (prev, curr, i) ->
      scope.encodeint.call scope, curr, msg_buffer, prev
    , pos

    pos = scope.encodestring.call scope, @preferred_font, msg_buffer, pos

    return pos


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
  constructor: (
    @xy
    @text='undefined'
    @parent_control
    @font_size="6px"
    @font_family="Sans Serif"
    @preferred_font=""
    @fg_color = new Color(255, 234, 8)
    @bg_color = new Color(205, 184, 8)
  ) ->
    @string_type = 'Text'
    @type = MSG_TEXT

  buildmessagecontents: (msg_buffer, pos) ->
    scope = @
    pos = [
      @fg_color.value
      @bg_color.value
      @position
      @message
      @text_action
      @text_flag
      @text_spacing
    ].reduce (prev, curr, i) ->
      scope.encodeint.call scope, curr, msg_buffer, prev
    , pos

    [
      @preferred_font
      @text
    ].reduce (prev, curr, i) ->
      scope.encodestring.call scope, curr, msg_buffer, prev
    , pos

    return pos

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


class DisplayCmd extends Base
  constructor: (
    @display_request = DisplayRequest.DISPLAY_NO_REQUEST
    @update_type = UpdateType.UPDATE_NONE
    @bright_level = -1
    @bright_range = -1
  ) ->
    @type = MSG_DISPLAY_CMD
    @string_type='DisplayCmd'

  buildmessagecontents: (msg_buffer, pos) ->
    scope = @
    pos = [
      @display_request
      @update_type
      @bright_level
      @bright_range
    ].reduce (prev, curr, i) ->
      scope.encodeint.call scope, curr, msg_buffer, prev
    , pos

    return pos


exports =
  'Color': Color
  'Base': Base
  'XYInfo': XYInfo
  'Template': Template
  'Panel': Panel
  'Textbox': Textbox
  'Text': Text
  'DisplayCmd': DisplayCmd
  'ObjectCategory': ObjectCategory
  'ProtocolCode': ProtocolCode
  'DisplayAttribute': DisplayAttribute
  'GenericScope': GenericScope
  'ScrollCommand': ScrollCommand
  'ScrollOrientation': ScrollOrientation
  'ScrollEffect': ScrollEffect
  'MessageCommand': MessageCommand
  'TextAction': TextAction
  'TextFlag': TextFlag
  'PanelGeometry': PanelGeometry
  'PanelPosition': PanelPosition
  'PanelLayout': PanelLayout
  'DisplayRequest': DisplayRequest
  'UpdateType': UpdateType
  'CMD_NONE': CMD_NONE
  'MSG_NONE': MSG_NONE
  'MSG_RECT': MSG_RECT
  'MSG_TEXTBOX': MSG_TEXTBOX
  'MSG_TEXT': MSG_TEXT
  'MSG_PANELDEF': MSG_PANELDEF
  'MSG_TEXTBOX_CMD': MSG_TEXTBOX_CMD
  'MSG_GENERIC_CMD': MSG_GENERIC_CMD
  'MSG_TIMER_CMD': MSG_TIMER_CMD
  'MSG_DISPLAY_CMD': MSG_DISPLAY_CMD
  'S_PARTICULAR_CONTROL': S_PARTICULAR_CONTROL


if module?
  module.exports = exports
else
  window.displayLib = exports
