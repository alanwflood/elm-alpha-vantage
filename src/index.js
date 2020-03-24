// Styles
import("./assets/stylesheets/tailwind.css");

// Elm
import { Elm } from "./elm/Main.elm";
import * as firebase from "firebase/app";
import "firebase/auth";

const node = document.createElement("div");
const flags = process.env.ALPHAVANTAGE_API_KEY;
document.body.appendChild(node);
var app = Elm.Main.init({ node, flags });

const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY,
  authDomain: process.env.FIREBASE_AUTH_DOMAIN,
  databaseURL: process.env.FIREBASE_DATABASE_URL,
  projectId: process.env.FIREBASE_PROJECT_ID,
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.FIREBASE_APP_ID
};

firebase.initializeApp(firebaseConfig);
const provider = new firebase.auth.GoogleAuthProvider();

console.log(app);

app.ports.signIn.subscribe(() => {
  console.log("LogIn called");
  firebase
    .auth()
    .signInWithPopup(provider)
    .then(result => {
      result.user.getIdToken().then(idToken => {
        console.log(result, idToken);
        app.ports.signInInfo.send({
          token: idToken,
          email: result.user.email,
          uid: result.user.uid
        });
      });
    })
    .catch(error => {
      app.ports.signInError.send({
        code: error.code,
        message: error.message
      });
    });
});

app.ports.signOut.subscribe(() => {
  console.log("LogOut called");
  firebase.auth().signOut();
});

//  Observer on user info
firebase.auth().onAuthStateChanged(user => {
  console.log("called");
  if (user) {
    user
      .getIdToken()
      .then(idToken => {
        app.ports.signInInfo.send({
          token: idToken,
          email: user.email,
          uid: user.uid
        });
      })
      .catch(error => {
        console.log("Error when retrieving cached user");
        console.log(error);
      });
  }
});
