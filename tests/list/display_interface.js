var dl = require('./DisplayLib');
var display = require('../../displayaddon');
var dlA = require('./DisplayLibA');

/*
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
*/
var def_has_been_sent = false;

exports.templateFull = function(json_text) {
    //convert to object
    display.set_emulator ("192.168.1.69", 1001);
    var obj = dl.Base.deserialize(json_text);
    if ((obj.string_type != null) === 'Template') {
        console.log ('deserialize failed');
        return;
    }
    var result;
    var send_buf;
    //look for a definition (presence of one or more panel def)
    if (obj.panels.length > 0 && !def_has_been_sent) {
        def_has_been_sent = true;
        console.log ("sending panel definition");
        var i;
        console.log ('panels: ' + obj.panels.length)
        for (i=0; i<obj.panels.length; i++) {
            //send each panel            
            result = obj.panels[i].buildmessage ();
            send_buf = result.result_buffer.slice(0,result.result_bytes);
            display.send_config (send_buf,i+1);
            console.log ('panel def: bytes: '+result.result_bytes);
        }

        //send the inital command to configure the display
        var dc = new dl.DisplayCmd();
        dc.display_request = dl.DisplayRequest.DISPLAY_CLEAR;
        dc.update_type = dl.UpdateType.UPDATE_ALL;
        dc.panel = dl.GenericScope.GS_APPLIES_TO_ALL;
        dc.is_final = 1;
        result = dc.buildmessage();
        send_buf = result.result_buffer.slice(0,result.result_bytes);
        display.send (send_buf);
        console.log ('panel cmd'+result.result_bytes);
    }

    //send the rest of the objects
    console.log ("sending elements");
    var i;
    console.log ('elements: ' + obj.elements.length)
    for (i=0; i<obj.elements.length; i++) {
        //send each panel
        if (i == obj.elements.length-1) {
            obj.elements[i].is_final = 1;
        }
        result = obj.elements[i].buildmessage ();
        send_buf = result.result_buffer.slice(0,result.result_bytes);
        display.send_config (send_buf,i+1);
        console.log ('element def: type:'+obj.elements[i].string_type + ' bytes: '+result.result_bytes);
    }

    
}




