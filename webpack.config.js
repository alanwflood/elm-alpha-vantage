const path = require("path");
const merge = require("webpack-merge");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const Dotenv = require("dotenv-webpack");

const modeConfig = env => require(`./webpack/webpack.${env}.js`);

module.exports = (env = { production: false }) => {
  const isProd = env.production;
  const isDev = !env.production;
  const mode = isDev ? "development" : "production";

  console.log(`Building for: ${mode}`);
  return merge(
    {
      mode,
      output: {
        filename: "main.js",
        path: path.resolve(__dirname, "dist")
      },
      plugins: [
        new HtmlWebpackPlugin({
          inject: "body",
          template: path.resolve(__dirname,  "src", "index.html")
        }),
        new Dotenv({
          path: path.resolve(__dirname, ".env"),
          safe: true
        })
      ]
    },
    modeConfig(mode)
  );
};
