dl = require './DisplayLib'
#dlA = require './DisplayLibA'
display = require '../../displayaddon'

###
var panel_l = dlA.DLPanelDef();
panel_l.panel_location = new dlA.XYInfo(0,0,60,32);
panel_l.total_size = new dlA.XYInfo(0,0,120,32);
panel_l.control = 1;
panel_l.layout = 1; //reversed
panel_l.position = 1; //PP_L

var panel_r = dlA.DLPanelDef();
panel_r.panel_location = new dlA.XYInfo(60,0,60,32);
panel_r.total_size = new dlA.XYInfo(0,0,120,32);
panel_r.control = 2;
panel_r.layout = 0; //normal
panel_r.position = 2; //PP_R

var clear_cmd = dlA.DLDisplayCmd();
clear_cmd.display_request = dlA.DisplayRequest.DISPLAY_CLEAR;
clear_cmd.update_type = dlA.UpdateType.UPDATE_ALL;
clear_cmd.panel = dlA.GenericScope.GS_APPLIES_TO_ALL;
clear_cmd.is_final = 1;
###

def_has_been_sent = false

templateFull = (json_text) ->
  display.set_emulator '127.0.0.1', 1001
#  display.set_emulator '192.168.1.69', 1001
#  console.log "json text: " + json_text

  obj = dl.Base.deserialize json_text
  throw new Error "must be a template object" unless obj?.string_type == 'Template'

  result = null
  send_buf = null

  if obj.panels?.length > 0 and not def_has_been_sent
    def_has_been_sent = true
    console.log 'sending panel definition'

    for panel, i in obj.panels
      result = panel.buildmessage()
      send_buf = result.result_buffer.slice 0, result.result_bytes
      display.send_config send_buf, i+1
      console.log "panel def: bytes: #{result.result_bytes}"


    dc = new dl.DisplayCmd()
    dc.display_request = dl.DisplayRequest.DISPLAY_CLEAR
    dc.update_type = dl.UpdateType.UPDATE_ALL
    dc.panel = dl.GenericScope.GS_APPLIES_TO_ALL
    dc.is_final = 1
    result = dc.buildmessage()
    send_buf = result.result_buffer.slice 0, result.result_bytes
    display.send send_buf
    console.log "panel cmd #{result.result_bytes}"

  console.log "sending #{obj.elements.length} elements"
  for element, i in obj.elements
    if i == obj.elements.length - 1
      element.is_final = 1
    console.log 'control id = ' + element.control
#    element.control = 12

    result = element.buildmessage()
    send_buf = result.result_buffer.slice 0, result.result_bytes
    display.send send_buf
    
    #** TEMP - provide a some text
    if element.type == dl.MSG_TEXTBOX
      #add some text
      text = new dl.Text new dl.XYInfo(), 'abc', element.control
      text.is_final = element.is_final
      text.text = element.initial_text
#      text.text = 'hello'
      console.log "text: " + text.text + '  textbox: ' + element.control + ' text parent: ' + text.parent_control
      text.parent_control = element.control
      result = text.buildmessage()
      send_buf = result.result_buffer.slice 0, result.result_bytes
      display.send send_buf
     

   

    console.log "element def: type: #{element.string_type} bytes: #{result.result_bytes}"


exports.templateFull = templateFull
