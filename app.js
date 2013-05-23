// VARIABLES
var application_root = __dirname,
    express = require("express"),
    path = require("path"),
    serverPort = process.env.PORT;

// EXPRESS
var app = express();
app.configure(function () {
  app.use(express.methodOverride());
  app.use(express.bodyParser());
  app.use(app.router);

  // views
  app.use(express.static(path.join(application_root, "/")));
});

app.configure('development', function() {
  serverPort = 3000;
});


/* R O U T E S */


app.listen(serverPort);
console.log("started server on port " + serverPort);

// EXPORT
module.exports = app;