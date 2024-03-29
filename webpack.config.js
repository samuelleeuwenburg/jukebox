const path = require("path");

module.exports = {
  entry: {
    client: "./src/client/Client.bs.js",
  },
  mode: process.env.NODE_ENV === "production" ? "production" : "development",
  output: {
    path: path.join(__dirname, "public"),
    filename: "[name].js",
  },
};
