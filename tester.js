var dl = require('./DisplayLIb');

var rect = dl.DLRect();
rect.xy = new dl.XYInfo(0, 0, 60, 32);
rect.line_color = new dl.DLColor(239,112,35);
rect.panel = 1;
rect.line_width = 1;

var textbox = dl.DLTextbox();
textbox.xy = new dl.XYInfo(3,3,40,10);
textbox.fg_color = new dl.DLColor(43,89,249);
textbox.bg_color = new dl.DLColor(249,197,166);
textbox.border_color = new dl.DLColor(0, 200, 0);
textbox.boarder_width = 1;
textbox.control = 12;                          

var text = dl.DLText();
text.text = "ab";
//text.text_action = TextAction.TEXT_APPEND;
text.text_action = 1; //TEXT_APPEND
text.message = 0;
text.position = 0;
text.parent_control = 12;                            



var net = require('net');


var HOST = '127.0.0.1';
var PORT = '1001';

var socket = new net.Socket();
//var mybuffer = new Buffer([0x02,0x03,0x87]);

socket.connect (PORT, HOST, function() {
    console.log ("about to write");
    var result = rect.BuildMessage ();
    var send_buf = result.result_buffer.slice(0,result.result_bytes);
    socket.write(send_buf);
    
    result = textbox.BuildMessage ();
    send_buf = result.result_buffer.slice(0,result.result_bytes);
    socket.write(send_buf);
    
    result = text.BuildMessage ();
    send_buf = result.result_buffer.slice(0,result.result_bytes);
    socket.write(send_buf);
    
    console.log ("written");
    socket.destroy();
})