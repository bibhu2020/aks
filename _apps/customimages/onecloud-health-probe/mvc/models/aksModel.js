// models/exampleModel.js
exports.getData = () => {
    var msg = '';
    const app = "server";
    msg = "Your application " + app + " is healthy.";

    return msg;
  };
  