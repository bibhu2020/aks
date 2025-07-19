const model = require('../models/appModel');

module.exports = {
  index: async (req, res) => {
    const data = model.getData(); // Get data from model
    res.status(parseInt(process.env.APP_STATUS || 200));
    res.render("app/index", { data: data }); //sends the requests to the views location defined in app.js
  },
};
