### `DLList` Tests

To begin:
* `git pull` or `git clone` this repository to get the latest code
* `npm install` in the root of this repository (not in /tests/list/)
* `cd /tests/list/` to move to the test directory
* `coffee -c *.coffee` to convert the coffee files (`DisplayLib.coffee`, `server.coffee`, `client.coffee`) to javascript
* start the test server with `node server.js`
* go to the default url / port at `localhost:3000`

After that, you should see a number of svg objects that represent each of the displayLib objects created.

To try the scrolling animation, see [this](https://github.com/strangesast/displayLibJS/commit/7ec2286f18cae056bed7ee7b426f45d2b954c785) commit

Currently, there is no reporting as to the success or failure of the transmission except the count of objects transmitted that is logged.
