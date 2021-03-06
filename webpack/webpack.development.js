const path = require("path");
const DashboardPlugin = require("webpack-dashboard/plugin");
const webpack = require("webpack");

module.exports = {
  entry: [
    "webpack-dev-server/client?http://localhost:8080",
    path.resolve(__dirname, "../src/index.js")
  ],
  module: {
    rules: [
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: [
          "elm-hot-webpack-loader",
          {
            loader: "elm-webpack-loader",
            options: {
              cwd: path.resolve(__dirname, "..")
            }
          }
        ]
      },
      {
        test: /\.css$/,
        use: [
          "style-loader",
          { loader: "css-loader", options: { importLoaders: 1 } },
          "postcss-loader"
        ]
      }
    ]
  },
  plugins: [new webpack.HotModuleReplacementPlugin(), new DashboardPlugin()],
  devServer: {
    contentBase: path.resolve(__dirname, "../src"),
    historyApiFallback: true,
    inline: true,
    stats: "errors-only",
    hot: true
  }
};
