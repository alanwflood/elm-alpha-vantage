module Routing exposing (Route(..), fromUrl, href, pushUrl)

import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Url
import Url.Parser as Parser exposing ((</>), Parser, map, oneOf, parse, s, string, top)


type Route
    = Home
    | Login
    | Logout
    | Stock String


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map Home top
        , map Login (s "login")
        , map Logout (s "logout")
        , map Stock (s "stock" </> string)
        ]



-- PUBLIC HELPERS


href : Route -> Attribute msg
href targetRoute =
    -- Override default href in anchor tags
    Attr.href (routeToString targetRoute)


pushUrl : Nav.Key -> Route -> Cmd msg
pushUrl key route =
    -- Programmatically move to route
    Nav.pushUrl key (routeToString route)


fromUrl : Url.Url -> Maybe Route
fromUrl url =
    -- Convert Url to Route
    parse parser url



-- INTERNAL


routeToString : Route -> String
routeToString page =
    String.join "/" (routeToPieces page)


routeToPieces : Route -> List String
routeToPieces page =
    case page of
        Home ->
            []

        Login ->
            [ "login" ]

        Logout ->
            [ "logout" ]

        Stock string ->
            [ "Stock", string ]
