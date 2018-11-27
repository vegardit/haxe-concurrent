// based on https://github.com/back2dos/travix/blob/master/src/travix/js/runPhantom.js
var fs = require('fs');
var system = require('system');
var webpage = require('webpage');

var path = system.args[0].split('\\').join('/').split('/');
fs.changeWorkingDirectory(path.slice(0, path.length - 1).join('/'));

var page = webpage.create();

page.onConsoleMessage = function(msg) {
  console.log(msg);
};

page.onCallback = function(data) {
    if(!data) return;
    switch (data.cmd) {
        case 'doctest:exit':
            phantom.exit(data.exitCode);
            break;
        default:
            // ignore
            break;
    }
}

page.open("phantom.html", function (status) {
    if(status != "success")
        console.log("Loading " + url + "faild: " + status);
});
