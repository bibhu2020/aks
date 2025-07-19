// app.js
const express = require("express"); 
const compression = require("compression");
const expressLayouts = require("express-ejs-layouts");
const app = express();

/**********************Configure the Middlewares***********************/
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static("www"));
app.use(expressLayouts);

app.use(
  compression({
    level: 6, //default level is -1. It ranges from -1 to 9.
    threshold: 1 * 1000, //anything below 1000bytes/1KB will not be compressed.
    filter: shouldCompress,
  })
);
function shouldCompress(req, res) {
  if (req.headers["x-no-compression"]) {
    // don't compress responses with this request header
    return false;
  }
  // fallback to standard filter function
  return compression.filter(req, res);
}

/**********************Configure the View Engine**********************/
app.set("view engine", "ejs"); //set the view engine
app.set("views", "./mvc/views"); //Unless it is specified, the engine looks for default path ./views

/**********************Configure the Routes*************************/
const defaultRouter = require("./routes/defaultRouter");
//const apiRouter = require("./routes/apiRouter");
app.use("/", defaultRouter);
//app.use("/api", core, apiRouter);

module.exports = app;

