// models/exampleModel.js
exports.getData = () => {
    var msg = '';
    const app = process.env.APP_NAME || "server";

    if (process.env.APP_STATUS != 200) {
      msg = "Your application " + app + " is not healthy. Please contact your system administrator.";
    }
    else {
      msg = "Your application " + app + " is healthy.";
    }

    return msg;
  };
  