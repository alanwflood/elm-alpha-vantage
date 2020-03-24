port module Main exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Events exposing (..)
import Json.Decode
import Json.Decode.Pipeline exposing (required)
import Json.Encode
import Routing exposing (Route(..), fromUrl, href, pushUrl)
import SearchBar
import Url



-- MAIN


main : Program String Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- MODEL


type alias UserData =
    { token : String
    , email : String
    , uid : String
    }


type alias Model =
    { currentRoute : Maybe Route
    , key : Nav.Key
    , user : Maybe UserData
    , searchBar : SearchBar.Model
    }


initialModel : Url.Url -> Nav.Key -> String -> Model
initialModel url key apiKey =
    Model (fromUrl url) key Nothing (SearchBar.init apiKey)


init : String -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( initialModel url key flags, Cmd.none )



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | SignInData (Result Json.Decode.Error UserData)
    | GotSearchBarMsg SearchBar.Msg
    | NoOp


changeRouteTo : Maybe Route -> Model -> ( Model, Cmd Msg )
changeRouteTo maybeRoute model =
    case maybeRoute of
        Just Login ->
            ( { model | user = Nothing }, Cmd.batch [ signIn (), Nav.load "/" ] )

        Just Logout ->
            ( { model | user = Nothing }, Cmd.batch [ signOut (), Nav.load "/" ] )

        _ ->
            ( { model | currentRoute = maybeRoute }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            changeRouteTo (fromUrl url) model

        SignInData result ->
            case result of
                Ok value ->
                    ( { model | user = Just value }, Cmd.none )

                Err error ->
                    ( model, Cmd.none )

        GotSearchBarMsg searchBarMsg ->
            let
                ( newModel, cmd ) =
                    SearchBar.update searchBarMsg model.searchBar
            in
            ( { model | searchBar = newModel }, Cmd.map GotSearchBarMsg cmd )

        NoOp ->
            ( model, Cmd.none )



-- JSON


userDataDecoder : Json.Decode.Decoder UserData
userDataDecoder =
    Json.Decode.succeed UserData
        |> Json.Decode.Pipeline.required "token" Json.Decode.string
        |> Json.Decode.Pipeline.required "email" Json.Decode.string
        |> Json.Decode.Pipeline.required "uid" Json.Decode.string



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ signInInfo (Json.Decode.decodeValue userDataDecoder >> SignInData)
        , Sub.map GotSearchBarMsg (SearchBar.subscriptions model.searchBar)
        ]



-- PORTS


port signIn : () -> Cmd msg


port signInInfo : (Json.Encode.Value -> msg) -> Sub msg


port signOut : () -> Cmd msg



-- VIEW


renderForRoute : Maybe Route -> Html Msg
renderForRoute route =
    case route of
        Just foundRoute ->
            case foundRoute of
                Home ->
                    div [] [ text "Home" ]

                Login ->
                    div [] [ text "Sign In" ]

                Logout ->
                    div [] [ text "Sign Out" ]

                Stock stockId ->
                    div [] [ text ("Stock with Id:" ++ stockId) ]

        Nothing ->
            notFoundView


notFoundView : Html msg
notFoundView =
    div [] [ text "Not Found at all" ]


view : Model -> Browser.Document Msg
view model =
    { title = "URL Interceptor"
    , body =
        [ text "The current URL is: "
        , div [] [ authButton model.user ]
        , div [] [ renderForRoute model.currentRoute ]
        , Html.map GotSearchBarMsg (SearchBar.view model.searchBar)
        ]
    }


authButton : Maybe UserData -> Html Msg
authButton user =
    case user of
        Just _ ->
            a [ href Logout ] [ text "Log Out" ]

        Nothing ->
            a [ href Login ] [ text "Log In" ]
