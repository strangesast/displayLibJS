express = require 'express'
bodyParser = require 'body-parser'
dl = require './DisplayLib.js'

app = express()

app.use bodyParser.json()
app.use bodyParser.urlencoded extended: true

port = 3000

# TODO: this should exist as inherited static method in class definition

app.use express.static "#{__dirname}/"

app.get '/', (req, res) ->
  res.sendFile 'index.html', root: __dirname 

app.post '/', (req, res) ->
  object_props = req.body

  obj = dl.deserialize(object_props)
  console.log(obj)

  res.json(obj)

app.listen port, ->
  console.log "starting list test at localhost:#{port}"


### tester_addon.js
var dl = require('./DisplayLib');
var display = require('../displayaddon/build/Release/displayaddon');

var panel_l = dl.DLPanelDef();
panel_l.panel_location = new dl.XYInfo(0,0,60,32);
panel_l.total_size = new dl.XYInfo(0,0,120,32);
panel_l.control = 1;
panel_l.layout = 1; //reversed
panel_l.position = 1; //PP_L

var panel_r = dl.DLPanelDef();
panel_r.panel_location = new dl.XYInfo(60,0,60,32);
panel_r.total_size = new dl.XYInfo(0,0,120,32);
panel_r.control = 2;
panel_r.layout = 0; //normal
panel_r.position = 2; //PP_R

var clear_cmd = dl.DLDisplayCmd();
clear_cmd.display_request = dl.DisplayRequest.DISPLAY_CLEAR;
clear_cmd.update_type = dl.UpdateType.UPDATE_ALL;
clear_cmd.panel = dl.GenericScope.GS_APPLIES_TO_ALL;
clear_cmd.is_final = 1;


var rect = dl.DLRect();
rect.xy = new dl.XYInfo(0, 0, 120, 32);
rect.line_color = new dl.DLColor(239,112,35);
rect.panel = 1;
rect.line_width = 2;

var textbox = dl.DLTextbox();
textbox.xy = new dl.XYInfo(3,3,114,18);
textbox.fg_color = new dl.DLColor(43,89,249);
//textbox.bg_color = new dl.DLColor(249,197,166);
textbox.bg_color = new dl.DLColor(0,0,0);
textbox.border_color = new dl.DLColor(0, 200, 0, 80);
textbox.border_color.set_intensity (80);
textbox.border_width = 1;
textbox.scroll_type = 3; //SCROLL_V
textbox.char_buffer_size = 0;
textbox.control = 12;

var text = dl.DLText();
text.text = "A QUICK BROWN FOX";
//text.text_action = TextAction.TEXT_APPEND;
text.text_action = 2; //TEXT_REPLACE
text.message = 0;
//text.position = 0;
text.parent_control = 12;

var text2  = dl.DLText();
text2.message = 0;
text2.text = " JUMPED";
text2.fg_color = new dl.DLColor(121,158,215);
text2.text_action = 1; //TEXT_APPEND
text2.parent_control = 12;

var text3  = dl.DLText();
text3.message = 0;
text3.text = " OVER A LAZY DOG";
text3.text_action = 1; //TEXT_APPEND
text3.parent_control = 12;
text3.is_final = 1;

//    var result = panel_l.BuildMessage ();
//    var send_buf = result.result_buffer.slice(0,result.result_bytes);
//    console.log ("about to write");
//    console.log(addon.test (send_buf));

//console.log ("about to open")
//var port = display.connect();
//display.open ();

function reportStatus(buf) {
  console.log(buf.toString());
}


//display.set_emulator ("192.168.1.69", 1001);
display.set_emulator ("127.0.0.1", 1001);
console.log ("about to write");
var result = panel_l.BuildMessage ();
var send_buf = result.result_buffer.slice(0,result.result_bytes);
display.send_config(send_buf, 1);

result = panel_r.BuildMessage ();
send_buf = result.result_buffer.slice(0,result.result_bytes);
display.send_config(send_buf, 2);

result = clear_cmd.BuildMessage ();
send_buf = result.result_buffer.slice(0,result.result_bytes);
display.send(send_buf);

setTimeout(function() {
  console.log('wait ended');
}, 5000);

display.get_status(reportStatus);

result = rect.BuildMessage ();
send_buf = result.result_buffer.slice(0,result.result_bytes);
display.send(send_buf);

result = textbox.BuildMessage ();
send_buf = result.result_buffer.slice(0,result.result_bytes);
display.send(send_buf);

result = text.BuildMessage ();
send_buf = result.result_buffer.slice(0,result.result_bytes);
display.send(send_buf);

result = text2.BuildMessage ();
send_buf = result.result_buffer.slice(0,result.result_bytes);
display.send(send_buf);

result = text3.BuildMessage ();
send_buf = result.result_buffer.slice(0,result.result_bytes);
display.send_request(send_buf, reportStatus);

console.log ("written");

display.get_status(reportStatus);

setTimeout(function() {
  console.log('hello world!');
}, 5000);

###

### tester_serial.js
var panel_l = dl.DLPanelDef();
panel_l.panel_location = new dl.XYInfo(0,0,60,32);
panel_l.total_size = new dl.XYInfo(0,0,120,32);
panel_l.control = 1;
panel_l.layout = 1; //reversed
panel_l.position = 1; //PP_L

var panel_r = dl.DLPanelDef();
panel_r.panel_location = new dl.XYInfo(60,0,60,32);
panel_r.total_size = new dl.XYInfo(0,0,120,32);
panel_r.control = 2;
panel_r.layout = 0; //normal
panel_r.position = 2; //PP_R

var rect = dl.DLRect();
rect.xy = new dl.XYInfo(0, 0, 120, 32);
rect.line_color = new dl.DLColor(239,112,35);
rect.panel = 1;
rect.line_width = 2;

var textbox = dl.DLTextbox();
textbox.xy = new dl.XYInfo(3,3,114,18);
textbox.fg_color = new dl.DLColor(43,89,249);
//textbox.bg_color = new dl.DLColor(249,197,166);
textbox.bg_color = new dl.DLColor(0,0,0);
textbox.border_color = new dl.DLColor(0, 200, 0, 80);
textbox.border_color.set_intensity (80);
textbox.border_width = 1;
textbox.scroll_type = 3; //SCROLL_V
textbox.char_buffer_size = 0;
textbox.control = 12;

var text = dl.DLText();
text.text = "A QUICK BROWN FOX";
//text.text_action = TextAction.TEXT_APPEND;
text.text_action = 2; //TEXT_REPLACE
text.message = 0;
//text.position = 0;
text.parent_control = 12;

var text2  = dl.DLText();
text2.message = 0;
text2.text = " JUMPS";
text2.fg_color = new dl.DLColor(121,158,215);
text2.text_action = 1; //TEXT_APPEND
text2.parent_control = 12;

var text3  = dl.DLText();
text3.message = 0;
text3.text = " OVER A LAZY DOG";
text3.text_action = 1; //TEXT_APPEND
text3.parent_control = 12;
text3.is_final = 1;


var SerialPort = require("serialport").SerialPort;


var port = new SerialPort('COM19', {
	baudRate: 38400,
	databits: 8,
	parity: 'none'
	}, false);



port.on('open', function(){
	console.log('Serial port opened');

	port.on('data', function(data) {
		console.log(data.toString());
	});

	console.log ('end of open');
});

port.open(function (error) {
	if (error) {
		console.log('Error while opening port ' + error);
	} else {
		console.log('port open');
		console.log ("about to write");
		var result = panel_l.BuildMessage ();
		var send_buf = result.result_buffer.slice(0,result.result_bytes);
		port.write(send_buf);
		console.log('write 1');

//Send the Right Panel Def to the other COM port
//All the other commands except the panel def should be sent the same to both panels.
		result = panel_r.BuildMessage ();
		send_buf = result.result_buffer.slice(0,result.result_bytes);
		port.write(send_buf);
		console.log('write 2');

		result = rect.BuildMessage ();
		send_buf = result.result_buffer.slice(0,result.result_bytes);
		port.write(send_buf);
		console.log('write 3');

		result = textbox.BuildMessage ();
		send_buf = result.result_buffer.slice(0,result.result_bytes);
		port.write(send_buf);
		console.log('write 4');

		result = text.BuildMessage ();
		send_buf = result.result_buffer.slice(0,result.result_bytes);
		port.write(send_buf);
		console.log('write 5');

		result = text2.BuildMessage ();
		send_buf = result.result_buffer.slice(0,result.result_bytes);
		port.write(send_buf);
		console.log('write 6');

		result = text3.BuildMessage ();
		send_buf = result.result_buffer.slice(0,result.result_bytes);
		port.write(send_buf);
		console.log('write 7');

//		port.close();
	}
});
//port.close();
###
