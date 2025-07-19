const express = require("express");
const router = express.Router();
const path = require("path");

const aksController = require("../mvc/controllers/aksController");
const appController = require("../mvc/controllers/appController");

//set the middleware to use default template while rending the view
router.all("/*", (req, res, next) => {
    req.app.set("layout", "_layouts/default");
    next();
  });

  router.get("/akshealth/", aksController.index);
  router.get("*", appController.index);

module.exports = router;
