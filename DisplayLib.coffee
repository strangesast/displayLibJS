MSG_NONE = 0

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

class XYInfo
  constructor: (@x=0, @y=0, @x_size=0, @y_size=0) ->
  @Clear = ->
    @x = 0
    @y = 0
    @x_size = 0
    @y_size = 0

DLColor = (red, green, blue, intensity) ->
  if not red?
    @value = -1
  else if not intensity?
    @value =
      0x7f000000 + 
      (red & 0xff) << 16 +
      (green & 0xff) << 8 +
      (blue & 0xff)
  else
    intensity = if 0 < intensity < 100 then intensity else 100
    @value =
      intensity << 24 +
      (red & 0xff) << 16 +
      (green & 0xff) << 8 +
      (blue & 0xff)
  @red = -> (@value >> 16) & 0xff
  @green = -> (@value >> 8) & 0xff
  @blue = -> @value & 0xff
  @RGB = (red, green, blue, intensity=100) ->
    intensity = if 0 < intensity < 100 then intensity else 100
    @value =
      (intensity << 24) +
      ((red & 0xff) << 16) +
      ((green & 0xff) << 8) +
      (blue & 0xff)
  @get_intensity = ->
    intensity = (@value & 0x7f000000) >> 24
    if 0 < intensity < 100 then intensity else 100
  @set_intensity = (_intensity) ->
    intensity = unless _intensity < 0 or _intensity > 100
    then _intensity else 100
    @value = (@value & 0x00ffffff) | (intensity << 24)
  @setEmpty = ->
    @value = -1
  @isEmpty = ->
    @value & 0xff000000 == 0xff000000
  @getValue = ->
    @value

class DLBase
  @type: MSG_NONE
  @category: ObjectCategory.OC_UNSPECIFIED
  @layer: 0
  @panel: 0 
  @control: 0
  @parent_control: 0
  @is_final: 0
  @display_attribute: DisplayAttribute.DA_NONE
  @color: DLColor 0

  @EncodeInt: (value, encoded_buffer, pos) ->
    if value < 0
      value*=-1
      encoded_buffer[pos] = ProtocolCode.START_NUMBER_NEG
    else
      encoded_buffer[pos] = ProtocolCode.START_NUMBER_POS

    pos++
    while value > 0
      encoded_buffer[pos] = 0x30 + (value & 0x0f)
      pos++
      value = value >> 4
    encoded_buffer[pos] = ProtocolCode.END_ELEMENT
    return pos++
  
  @EncodeString: (string_value, encoded_buffer, pos) ->
    encoded_buffer[pos] = ProtocolCode.START_TEXT
    pos++
    for char, i in string_value
      if string_value.charCodeAt i < ProtocolCode.FIRST_LEGAL_CHAR
        continue
      encoded_buffer[pos] = string_value.charCodeAt i
      pos++
    encoded_buffer[pos] = ProtocolCode.END_ELEMENT
    return pos++

  @DecodeInt: (encoded_buffer, pos) ->
    is_negative = false
    if encoded_buffer[pos] == ProtocolCode.START_NUMBER_POS
    else if encoded_buffer[pos] == ProtocolCode.START_NUMBER_NEG
      is_negative = true
    else
      result_int: 0
      result_pos: 0

  @DecodeString: (encoded_buffer, pos) ->
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

  @BuildMessageContents: (buffer, pos) -> 
    pos

  @BuildMessage: ->
    msg_buffer = new Buffer 2000
    pos = 0

    msg_buffer[pos] = ProtocolCode.MSG_START
    pos++
    msg_buffer[pos] = ProtocolCode.MAGIC_NUMBER
    pos++
    pos = @EncodeInt @type, msg_buffer, pos

    # EncodeInt
    common_values = [
      @layer
      @panel
      @control
      @parent_control
      @is_final
      @display_attribute
    ]

    # TODO: what is happening here?
    pos = common_values.reduce (prev, curr, i) ->
      @EncodeInt curr, msg_buffer, prev
    , pos

    pos = @BuildMessageContents msg_buffer, pos
    msg_buffer[pos] = ProtocolCode.MSG_END
    pos++

    return result_buffer: msg_buffer, result_buffer: pos


MSG_RECT = 101

class DLRect extends DLBase
  @type: MSG_RECT
  @xy: new XYInfo
  @line_color: new DLColor
  @fill_color: new DLColor
  @line_width: 1

  @BuildMessageContents: (msg_buffer, pos) ->
    [
      @xy.x
      @xy.y
      @xy.x_size
      @xy.y_size
      @line_color
      @line_width
    ].reduce (prev, curr, i) ->
      @EncodeInt curr, msg_buffer, prev
    , pos


MSG_TEXTBOX = 110;

class DLTextbox extends DLBase
  @type: MSG_TEXTBOX
  @xy: new XYInfo
  @fg_color: new DLColor
  @bg_color: new DLColor
  @border_color: new DLColor
  @border_width: new DLColor
  @text_xy: new XYInfo
  @char_buffer_size: 200
  @preferred_font: ""

  @BuildMessageContents = (msg_buffer, pos) ->
    pos = [
      @xy.x
      @xy.y
      @xy.x_size
      @xy.y_size
      @fg_color
      @bg_color
      @border_color
      @border_width
      @text_xy.x
      @text_xy.y
      @text_xy.x_size
      @text_xy.y_size
      @char_buffer_size
    ].reduce (prev, curr, i) ->
      @EncodeInt curr, msg_buffer, prev
    , pos

    @EncodeString(@preferred_font, msg_buffer, pos)    


MSG_TEXTBOX_CMD = 161

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


CMD_NONE = 0 # this was missing in original version
S_PARTICULAR_CONTROL = 1 # as was this

class DLTextboxCmd extends DLBase
  @type: MSG_TEXTBOX_CMD
  @command: CMD_NONE
  @scope: S_PARTICULAR_CONTROL
  @selected_message: -1
  @scroll_param: -1
  @scroll_rate: -1
  @scroll_effect: ScrollEffect.SE_NONE
  @scroll_command: ScrollCommand.SCROLL_NONE
  @scroll_orientation: ScrollOrientation.SO_NONE
  @message_command: MessageCommand.MESSAGE_NONE
  @message_param: -1

  @BuildMessageContents = (msg_buffer, pos) ->
    [
      @command
      @scope
      @selected_message
      @scroll_param
      @scroll_rate
      @scroll_effect
      @scroll_command
      @scroll_orientation
      @message_command
      @message_param
    ].reduce (prev, curr, i) ->
      @EncodeInt(curr, msg_buffer, prev)
    , pos


MSG_TEXT = 150

TextAction = Object.freeze
  TEXT_NOACTION:0
  TEXT_APPEND: 1
  TEXT_REPLACE: 2
  TEXT_CLEAR: 3

TextFlag = Object.freeze
  TF_NONE: 0
  TF_LINEBREAK: 1
  TF_MSGEND: 2

class DLText extends DLBase
  @type: MSG_TEXT
  @fg_color: new DLColor
  @bg_color: new DLColor
  @position: 0
  @text: ""
  @message: 0
  @text_action: TextAction.TEXT_NOACTION
  @text_spacing: -1
  @text_flag: TextFlag.TF_NONE
  @preferred_font: ""


  @BuildMessageContents: (msg_buffer, pos) ->
    pos = [
      @fg_color.value
      @bg_color.value
      @position
      @message
      @text_action
      @text_flag
      @text_spacing
    ].reduce (prev, curr, i) ->
      @EncodeInt curr, msg_buffer, prev
    , pos

    [
      @preferred_font
      @text
    ].reduce (prev, curr, i) ->
      @EncodeString curr, msg_buffer, prev
    , pos


MSG_PANELDEF = 151

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

class DLPanelDef extends DLBase
  @type: MSG_PANELDEF
  @fg_color: new DLColor
  @bg_color: new DLColor
  @geometry: PanelGeometry.PG_NOT_SPECIFIED
  @position: PanelPosition.PP_NOT_SPECIFIED
  @layout: PanelLayout.PL_NORMAL
  @panel_location: new XYInfo
  @total_size: new XYInfo

  @BuildMessageContents: (msg_buffer, pos) ->
    [
      @fg_color.value
      @bg_color.value
      @geometry
      @position
      @layout
      @panel_location.x
      @panel_location.y
      @panel_location.x_size
      @panel_location.y_size
      @total_size.x
      @total_size.y
      @total_size.x_size
      @total_size.y_size
    ].reduce (prev, curr, i) ->
      @EncodeInt curr, msg_buffer, prev
    , pos

MSG_GENERIC_CMD = 160

MSG_DISPLAY_CMD = 163

DisplayRequest = Object.freeze
  DISPLAY_NO_REQUEST: 0
  DISPLAY_CLEAR: 1

UpdateType = Object.freeze
  UPDATE_NONE: 0
  UPDATE_SPECIFIED_ITEMS: 1
  UPDATE_ALL: 2

class DLDisplayCmd extends DLBase
  @type: MSG_DISPLAY_CMD
  @display_request: DisplayRequest.DISPLAY_NO_REQUEST
  @update_type: UpdateType.UPDATE_NONE
  @bright_level: -1
  @bright_range: -1

  @BuildMessageContents: (msg_buffer, pos) ->
    [
      @display_request
      @update_type
      @bright_level
      @bright_range
    ].reduce (prev, curr, i) ->
      @EncodeInt curr, msg_buffer, prev
    , pos

MSG_TEXTBOX_CMD = 161
MSG_TIMER_CMD = 162
