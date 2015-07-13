var dl = require('./DisplayLib');
var display = require('../../displayaddon');
var dlA = require('./DisplayLibA');


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
    if (obj.panels.length > 0) {
        console.log ("sending panel definition");
        var i, result, send_buf;
        console.log ('panels: ' + obj.panels.length)
        for (i=0; i<obj.panels.length; i++) {
            //send each panel            
            result = obj.panels[i].buildmessage ();
            send_buf = result.result_buffer.slice(0,result.result_bytes);
            display.send_config (send_buf,i+1);
            console.log ('panel def: bytes: '+result.result_bytes);
        }
/*
        var clear_cmd = dlA.DLDisplayCmd();
        clear_cmd.display_request = dlA.DisplayRequest.DISPLAY_CLEAR;
        clear_cmd.update_type = dlA.UpdateType.UPDATE_ALL;
        clear_cmd.panel = dlA.GenericScope.GS_APPLIES_TO_ALL;
        clear_cmd.is_final = 1;
        result = clear_cmd.BuildMessage ();
        send_buf = result.result_buffer.slice(0,result.result_bytes);
        display.send(send_buf, 1);
*/

        //send the inital command to configure the display
        var dc = new dl.DisplayCmd();
        dc.display_request = dl.DisplayRequest.DISPLAY_CLEAR;
        dc.update_type = dl.UpdateType.UPDATE_ALL;
        dc.panel = dl.GenericScope.GS_APPLIES_TO_ALL;
        dc.is_final = 1;
//        dc.type = 163;
        result = dc.buildmessage();
        send_buf = result.result_buffer.slice(0,result.result_bytes);
        display.send (send_buf);
        console.log ('panel cmd'+result.result_bytes);

    }
}

exports.initDisplay = function (json_text) {
    
    display.set_emulator ("192.168.1.94", 1001);
    console.log ("init display");
    /*
    var obj = dl.Base.deserialize(json_text);
    if ((obj.string_type != null) === 'Template') {
        console.log ('deserialize failed');
        return;
    }
    */
    
    
    var result = panel_l.BuildMessage ();
    var send_buf = result.result_buffer.slice(0,result.result_bytes);
    display.send_config(send_buf, 1);
    
    result = panel_r.BuildMessage ();
    send_buf = result.result_buffer.slice(0,result.result_bytes);
    display.send_config(send_buf, 2);
    
    clear_cmd.is_final = 1;
    result = clear_cmd.BuildMessage ();
    send_buf = result.result_buffer.slice(0,result.result_bytes);
    display.send(send_buf);    
    
    /*
 //   var b = obj.buildmessage();
    var i, result, send_buf;
    console.log ('panels: ' + obj.panels.length)
    for (i=0; i<obj.panels.length; i++) {
        //send each panel
        result = obj.panels[i].buildmessage ();
//        send_buf = result.result_buffer.slice(0,result.result_bytes);
        display.send_config (send_buf,i+1);
        console.log ('panel def: bytes: '+result.result_bytes);
        console.log ('config: ' + send_buf)
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
 
   
    */
    
    
    
    
    
}



/*

    config_buffer_queue = [];
    for (i = j = 0, ref = obj.panels.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
      result = b[i];
      send_buf = result.result_buffer.slice(0, result.result_bytes);
      config_buffer_queue.push(send_buf);
    }
    buffer_queue = [];
    dc = new dl.DisplayCmd();
    dc.display_request = dl.DisplayRequest.DISPLAY_CLEAR;
    dc.update_type = dl.UpdateType.UPDATE_ALL;
    dc.panel = dl.GenericScope.GS_APPLIES_TO_ALL;
    dc.is_final = 1;
    result = dc.buildmessage();
    send_buf = result.result_buffer.slice(0, result.result_bytes);
    buffer_queue.push(send_buf);
    for (i = k = ref1 = obj.panels.length, ref2 = b.length; ref1 <= ref2 ? k < ref2 : k > ref2; i = ref1 <= ref2 ? ++k : --k) {
      result = b[i];
      send_buf = result.result_buffer.slice(0, result.result_bytes);
      buffer_queue.push(send_buf);
    }
    display.set_emulator('127.0.0.1', 1001);
    results = [];
    reportStatus = function(buf) {
      return console.log("STATUS: " + (buf.toString()));
    };
    return config_buffer_queue.reduce(function(prev, curr, i) {
      return prev.then(function(elem) {
        return new Promise(function(resolve, reject) {
          var s;
          console.log(i);
          s = display.send_config(curr, i + 1);
          results.push(s);
          return resolve(s);
        });
      });
    }, Promise.resolve()).then(function() {
      return buffer_queue.reduce(function(prev, curr, i) {
        return prev.then(function(elem) {
          return new Promise(function(resolve, reject) {
            var s;
            console.log(i);
            s = display.send(curr, reportStatus);
            results.push(s);
            return resolve(s);
          });
        });
      }, Promise.resolve()).then(function() {
        console.log('completed with no error');
        return res.json(results);
      })["catch"](function() {
        return res.json('error2');
      });
    })["catch"](function() {
      return res.json('error1');
    });
*/
