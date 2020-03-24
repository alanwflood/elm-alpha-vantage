module SearchBar exposing (Model, Msg, init, subscriptions, update, view)

import Browser.Events as Events
import Html exposing (..)
import Html.Attributes exposing (class, href, style, type_, value)
import Html.Events exposing (..)
import Http
import Json.Decode exposing (Decoder, field, list, map, string, succeed)
import Json.Decode.Extra exposing (parseFloat)
import Json.Decode.Pipeline exposing (required)
import Url.Builder as Build



-- HTTP


type alias ApiKey =
    String


fetchSymbolSearch : String -> ApiKey -> Cmd Msg
fetchSymbolSearch searchTerm apiKey =
    Http.get
        { url =
            Build.custom
                (Build.CrossOrigin
                    "https://www.alphavantage.co"
                )
                [ "query" ]
                [ Build.string "function" "SYMBOL_SEARCH"
                , Build.string "keywords" searchTerm
                , Build.string "apikey" apiKey
                ]
                Nothing
        , expect = Http.expectJson RecieveSearchSymbol decodeSearchSymbolList
        }



-- JSON


decodeSearchSymbolList : Decoder (List SearchSymbol)
decodeSearchSymbolList =
    field "bestMatches" (list decodeSearchSymbol)


decodeSearchSymbol : Decoder SearchSymbol
decodeSearchSymbol =
    succeed SearchSymbol
        |> required "1. symbol" string
        |> required "2. name" string
        |> required "3. type" string
        |> required "4. region" string
        |> required "5. marketOpen" string
        |> required "6. marketClose" string
        |> required "7. timezone" string
        |> required "8. currency" string
        |> required "9. matchScore" parseFloat



-- MODEL


type alias SearchSymbol =
    { symbol : String
    , name : String
    , symbolType : String
    , region : String
    , marketOpen : String
    , marketClose : String
    , timezone : String
    , currency : String
    , matchScore : Float
    }


type alias Model =
    { apiKey : ApiKey
    , searchTerm : String
    , isSearchListOpen : Bool
    , searchSymbols : List SearchSymbol
    }


init : String -> Model
init apiKey =
    Model apiKey "" False []



-- UPDATE


type Msg
    = SetSearchTerm String
    | FetchSymbolSearch
    | RecieveSearchSymbol (Result Http.Error (List SearchSymbol))
    | SetSearchSymbol (List SearchSymbol)
    | SetSearchListOpen Bool


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetSearchTerm searchTerm ->
            if searchTerm == "" then
                update (SetSearchSymbol []) { model | searchTerm = searchTerm }

            else
                ( { model | searchTerm = searchTerm }, Cmd.none )

        FetchSymbolSearch ->
            ( model, fetchSymbolSearch model.searchTerm model.apiKey )

        SetSearchSymbol searchSymbols ->
            ( { model
                | searchSymbols = searchSymbols
                , isSearchListOpen = List.isEmpty searchSymbols == False
              }
            , Cmd.none
            )

        SetSearchListOpen bool ->
            ( { model | isSearchListOpen = bool }, Cmd.none )

        RecieveSearchSymbol result ->
            case result of
                Ok json ->
                    update (SetSearchSymbol json) model

                Err _ ->
                    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.isSearchListOpen then
        Events.onClick <| succeed (SetSearchListOpen False)

    else
        Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "shadow-md rounded-lg m-t-3" ]
        [ viewSearchForm model
        , viewSymbolsList model.searchSymbols model.isSearchListOpen
        ]



-- viewNav : Html msg
-- viewNav =
--     nav [ class "flex items-center justify-between flex-wrap bg-teal p-6" ]
--         [ ul [ class "w-full block flex-grow lg:flex lg:items-center lg:w-auto" ]
--             [ viewLink "Home" "/home"
--             ]
--         ]


viewSymbolsList : List SearchSymbol -> Bool -> Html Msg
viewSymbolsList searchSymbols isSearchListOpen =
    let
        searchList =
            searchSymbols
                |> List.sortBy .matchScore
                |> List.reverse
                |> List.map
                    (\s ->
                        li []
                            [ a
                                [ href <| "/"

                                -- Url.Builder.absolute [ "sym", s.symbol ] []
                                , stopPropagationOn "click" <| succeed ( SetSearchTerm s.name, True )
                                , class "flex justify-between p-2 hover:bg-grey-lighter no-underline text-grey-dark hover:text-grey-darker"
                                ]
                                [ div [] [ text s.name ]
                                , div [] [ text s.symbol ]
                                ]
                            ]
                    )
    in
    if isSearchListOpen then
        ul [ class "list-reset overflow-y-auto", style "max-height" "15rem" ] searchList

    else
        text ""


stopListCloseOn : String -> Bool -> Html.Attribute Msg
stopListCloseOn attribute bool =
    stopPropagationOn attribute <| succeed ( SetSearchListOpen bool, True )


viewSearchForm : Model -> Html Msg
viewSearchForm model =
    let
        roundedClass =
            if model.isSearchListOpen then
                "none"

            else
                "lg"

        borderColor =
            if model.isSearchListOpen then
                " border-blue"

            else
                "border-grey-lighter"
    in
    Html.form [ onSubmit FetchSymbolSearch, class ("flex items-stretch rounded-t-lg rounded-b-" ++ roundedClass) ]
        [ input
            [ class ("appearance-none block w-full bg-grey-lighter text-grey-darker py-3 px-4 leading-tight focus:outline-none focus:bg-white border-b-2 rounded-tl-lg rounded-bl-" ++ roundedClass ++ " " ++ borderColor)
            , onInput SetSearchTerm
            , stopListCloseOn "click" True
            , stopListCloseOn "focus" True
            , value model.searchTerm
            , type_ "search"
            ]
            []
        , button
            [ class ("bg-blue hover:bg-blue-dark border-b-2 border-blue text-white font-bold py-3 px-4 focus:outline-none rounded-tr-lg rounded-br-" ++ roundedClass)
            , type_ "submit"
            ]
            [ text "Search" ]
        ]
