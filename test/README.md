### Tests

To begin:
* `git pull` or `git clone` this repository to get the latest code
* `npm install` in the root of this repository (not in /test/)

After you have displayaddon.node:
* `cd /test/` to move to the test directory
* `coffee -c *.coffee` to convert the coffee files (`DisplayLib.coffee`, `server.coffee`, `client.coffee`) to javascript
* finally, start the test server with `node server.js`

After that, you can load the page (also seen at `strangesast.github.io/displayLibJS/` but with the ability to test the displayaddon) at `localhost:3000`.
