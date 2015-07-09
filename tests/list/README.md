### `DLList` Tests

To begin:
* `git pull` or `git clone` this repository to get the latest code
* `npm install` in the root of this repository (not in /tests/list/)

You'll need a symbolic link (or copy) of displayaddon.node in the root of displayLibJS.
Linking looks something like this: `ln -s /path/to/displayaddon.node /different/path/to/displayLibJS/displayaddon.node`
Copying looks like this `cp /path/to/displayaddon.node /different/path/to/displayLibJS/`

The advantage of linking is that if you recompile or otherwise modify displayaddon.node you do not have to re-copy it.

After you have displayaddon.node:
* `cd /tests/list/` to move to the right test directory within displayLibJS (`/tests/list` was initally for testing a list object but has since been used for all tests -- that'll be fixed soon)
* `coffee -c *.coffee` to convert the coffee files (`DisplayLib.coffee`, `server.coffee`, `client.coffee`) to javascript
* finally, start the test server with `node server.js`

After that, you can load the page (also seen at `strangesast.github.io/displayLibJS/` but with the ability to test the displayaddon) at `localhost:3000`.

Currently, there is no reporting as to the success or failure of the transmission except the count of objects transmitted (which is logged).  Panel definition transmission works, but something is still missing for other objects.
