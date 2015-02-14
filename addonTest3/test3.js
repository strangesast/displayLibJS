var basics = require('./build/Release/addonTest3');

function runMe(buf) {
  console.log(buf.toString());
}

var mybuffer = new Buffer([0x41,0x42,0x43]);

basics.send (mybuffer);

basics.run(runMe);
basics.run(runMe);
basics.run(runMe);

console.log('called');
