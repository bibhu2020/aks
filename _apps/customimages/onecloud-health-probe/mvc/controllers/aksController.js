const model = require('../models/aksModel');

module.exports = {
  index: async (req, res) => {
    const data = model.getData(); // Get data from model
    res.status(200);
    res.render("aks/index", { data: data }); //sends the requests to the views location defined in app.js
  },
};
