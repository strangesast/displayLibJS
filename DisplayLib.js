//var net = require('net');
var MSG_NONE = 0;

var ObjectCategory = Object.freeze ({OC_UNSPECIFIED:0, OC_CONTROL:1, OC_SHAPE:2, OC_DATA:3})
var ProtocolCode = Object.freeze (
{MSG_END:0x01,MSG_START:0x02,START_ARRAY:0x03,END_ARRAY:0x04,START_TEXT:0x05,END_ELEMENT:0x06,
START_NUMBER_POS:0x07,START_NUMBER_NEG:0x08,FIRST_LEGAL_CHAR:0x09,MAGIC_NUMBER:0x87});

var XYInfo = function (a_x, a_y, a_x_size, a_y_size) {
    if (a_x === undefined) {
        this.x = 0;
        this.y = 0;
    }
    else {
        this.x = a_x;
        this.y = a_y;
    }
    if (a_x_size === undefined) {
        a_x_size = 0;
        a_y_size = 0;
    }
    else {
        this.x_size = a_x_size;
        this.y_size = a_y_size;
    }
    this.Clear = function () {
        this.x = 0;
        this.y = 0
        this.x_size = 0;
        this.y_size = 0;
    }
}

var DLColor = function (a_red,a_green,a_blue) {
    if (a_red === undefined) {
        this.value = -1;
    }
    else {
        this.value = ((a_red & 0xff)<< 16) + ((a_green & 0xff) << 8) + (a_blue & 0xff);
    }
    this.red = function () {
        return (this.value >> 16) & 0xff;
    }
    this.green = function () {
        return (this.value >> 8) & 0xff;
    }
    this.blue = function () {
        return this.value & 0xff;
    }
    this.RGB = function (a_red, a_green, a_blue) {
        this.value = ((a_red & 0xff)<< 16) + ((a_green & 0xff) << 8) + (a_blue & 0xff);
    }
    this.setEmpty = function () {
        this.value = -1;
    }
    this.isEmpty = function () {
        return (this.value & 0xff000000) 
    }
    this.getValue = function () {
        return this.value;
    }
}


var DLBase = function () {
    this.type = MSG_NONE;
    this.category = ObjectCategory.OC_UNSPECIFIED;
    this.layer = 0;
    this.panel = 0;
    this.control = 0;
    this.color = DLColor(0);
}
    
DLBase.prototype.EncodeInt = function (value, encoded_buffer, pos) {
//        var encoded_buffer = new Buffer(100);
    if (value<0) {
        value = -value;
        encoded_buffer[pos] = ProtocolCode.START_NUMBER_NEG;
    }else {
        encoded_buffer[pos] = ProtocolCode.START_NUMBER_POS;
    }
    pos++;
    //send LS nibble until value is empty
    while (value > 0) {
        encoded_buffer[pos] = 0x30 + (value & 0x0f);
        pos++;
        value = value >> 4;
    }
    encoded_buffer[pos] = ProtocolCode.END_ELEMENT;
    pos++;
    return pos;
}
DLBase.prototype.EncodeString = function (string_value, encoded_buffer, pos) {
//    console.log ("text: " + string_value + "length: " + string_value.length);
    encoded_buffer[pos] = ProtocolCode.START_TEXT;
    pos++;
    for (i=0; i<string_value.length; i++) {
        //skip illegal characters
        if (string_value.charCodeAt(i) < ProtocolCode.FIRST_LEGAL_CHAR) {
            continue;
        }
        encoded_buffer[pos] = string_value.charCodeAt(i);
//        console.log ("pos: " + i + " = " + string_value.charCodeAt(i));
        pos++;
    }
    encoded_buffer[pos] = ProtocolCode.END_ELEMENT;
    pos++;
    return pos;
}
    
DLBase.prototype.DecodeInt = function (encoded_buffer, pos) {
    var is_negative = false;
    if (encoded_buffer[pos] == ProtocolCode.START_NUMBER_POS) {
        //code
    }
    else if (encoded_buffer[pos] == ProtocolCode.START_NUMBER_NEG) {
        is_negative = true;
    }
    else {
        return {
            result_int:0,
            result_pos:0
        }
    }
}
    
DLBase.prototype.DecodeString = function (encoded_buffer, pos) {
    if (encoded_buffer[pos] != ProtocolCode.START_TEXT) {
        return 0;
    }
    var return_string;
    for (i=0; ;i++) {
        if (encoded_buffer[pos] == ProtocolCode.END_ELEMENT) {
            pos++;  //accept the delimiter
            break;
        }
        //check for unexpected control character
        else if (encoded_buffer[pos] < ProtocolCode.FIRST_LEGAL_CHAR) {
            break;
        }
        return_string = return_string + encoded_buffer[pos];
        pos++;
    }
    return {
        result_str:return_string,
        result_pos:pos
    }
}
    
    
DLBase.prototype.BuildMessageContents = function (buffer, pos) {
    return pos;
}
    
DLBase.prototype.BuildMessage = function () {
    var msg_buffer = new Buffer(2000);
    var pos = 0;
    
    //build the header
    msg_buffer[pos] = ProtocolCode.MSG_START;
    pos++;
   //magic number
    msg_buffer[pos] = ProtocolCode.MAGIC_NUMBER;
    pos++;
    pos = this.EncodeInt (this.type, msg_buffer, pos);
    
    //write the common values
    pos = this.EncodeInt (this.layer, msg_buffer, pos);
    pos = this.EncodeInt (this.panel, msg_buffer, pos);
    pos = this.EncodeInt (this.control, msg_buffer, pos);
    pos = this.BuildMessageContents (msg_buffer, pos);
    msg_buffer[pos] = ProtocolCode.MSG_END;
    pos++;
    return {
        result_buffer: msg_buffer,
        result_bytes: pos
    }
}

var MSG_RECT = 101;

function DLRect () {
    DLBase.call(this);
    this.type = MSG_RECT;
    this.xy = new XYInfo;
    this.line_color = new DLColor;
    this.fill_color = new DLColor;
    this.line_width = 1;
}

DLRect.prototype = Object.create(DLBase.prototype);
DLRect.prototype.constructor = DLRect;
//override BuildMessageContents
DLRect.prototype.BuildMessageContents = function(msg_buffer, pos) {
    //xy
    pos = this.EncodeInt (this.xy.x, msg_buffer, pos);
    pos = this.EncodeInt (this.xy.y, msg_buffer, pos);
    pos = this.EncodeInt (this.xy.x_size, msg_buffer, pos);
    pos = this.EncodeInt (this.xy.y_size, msg_buffer, pos);
    pos = this.EncodeInt (this.line_color.value, msg_buffer, pos);
    pos = this.EncodeInt (this.fill_color.value, msg_buffer, pos);
    pos = this.EncodeInt (this.line_width, msg_buffer, pos);
    return pos;
}

var MSG_TEXTBOX = 110;

function DLTextbox () {
    DLBase.call(this);
    this.type = MSG_TEXTBOX;
    this.xy = new XYInfo;
    this.fg_color = new DLColor;
    this.bg_color = new DLColor;
    this.border_color = new DLColor;
    this.border_width = 1;
    this.xy_visible = new XYInfo;
}

DLTextbox.prototype = Object.create(DLBase.prototype);
DLTextbox.prototype.constructor = DLTextbox;
//override BuildMessageContents
DLTextbox.prototype.BuildMessageContents = function(msg_buffer, pos) {
    //xy
    pos = this.EncodeInt (this.xy.x, msg_buffer, pos);
    pos = this.EncodeInt (this.xy.y, msg_buffer, pos);
    pos = this.EncodeInt (this.xy.x_size, msg_buffer, pos);
    pos = this.EncodeInt (this.xy.y_size, msg_buffer, pos);
    pos = this.EncodeInt (this.fg_color.value, msg_buffer, pos);
    pos = this.EncodeInt (this.bg_color.value, msg_buffer, pos);
    pos = this.EncodeInt (this.border_color.value, msg_buffer, pos);
    pos = this.EncodeInt (this.border_width, msg_buffer, pos);
    pos = this.EncodeInt (this.xy_visible.x, msg_buffer, pos);
    pos = this.EncodeInt (this.xy_visible.y, msg_buffer, pos);
    pos = this.EncodeInt (this.xy_visible.x_size, msg_buffer, pos);
    pos = this.EncodeInt (this.xy_visible.y_size, msg_buffer, pos);
    return pos;
}


var MSG_TEXT = 150;

function DLText () {
    DLBase.call(this);
    this.type = MSG_TEXT;
    this.fg_color = new DLColor;
    this.bg_color = new DLColor;
    this.position = 0;
    this.text = "";
}

DLText.prototype = Object.create(DLBase.prototype);
DLText.prototype.constructor = DLText;
//override BuildMessageContents
DLText.prototype.BuildMessageContents = function(msg_buffer, pos) {
    //xy
    pos = this.EncodeInt (this.fg_color.value, msg_buffer, pos);
    pos = this.EncodeInt (this.bg_color.value, msg_buffer, pos);
    pos = this.EncodeInt (this.position, msg_buffer, pos);
    pos = this.EncodeString (this.text, msg_buffer, pos);
    return pos;
}



function CreateDLText () {
    return new DLText();
}

function CreateDLTextbox () {
    return new DLTextbox();
}

function CreateDLRect () {
    return new DLRect();
}

module.exports.DLRect = CreateDLRect;
module.exports.DLTextbox = CreateDLTextbox;
module.exports.DLText = CreateDLText;
module.exports.XYInfo = XYInfo;
module.exports.DLColor = DLColor;




