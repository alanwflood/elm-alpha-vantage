// Styles
import("./assets/stylesheets/tailwind.css");

// Elm
import { Elm } from "./elm/Main.elm";
const node = document.createElement("div");
document.body.appendChild(node);
var app = Elm.Main.init({ node });
console.log(app);
