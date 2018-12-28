module Data exposing (Data(..), parse)

import Parser exposing (..)


type Data
    = Identifier String
    | IpAddress IpAddressData


type alias IpAddressData =
    { networkID1 : Int
    , networkID2 : Int
    , hostID1 : Int
    , hostID2 : Int
    , subnetMask : Maybe Int
    }


parse : String -> Result String Data
parse input =
    let
        parser =
            oneOf
                [ backtrackable ipAddress
                , identifier
                ]
    in
    input
        |> run parser
        |> Result.mapError deadEndsToString


identifier : Parser Data
identifier =
    chompWhile Char.isDigit
        |> getChompedString
        |> map Identifier


ipAddress : Parser Data
ipAddress =
    succeed IpAddressData
        |= network
        |. dot
        |= network
        |. dot
        |= host
        |. dot
        |= host
        |= optionalSubnetMask
        |> map IpAddress


network : Parser Int
network =
    let
        toInt input =
            input
                |> String.toInt
                |> Maybe.withDefault -1
    in
    chompWhile Char.isDigit
        |> getChompedString
        |> andThen (lengthWithIn 1 3)
        |> map toInt


lengthWithIn : Int -> Int -> String -> Parser String
lengthWithIn minimum maximum input =
    let
        n =
            String.length input
    in
    if minimum <= n && n <= maximum then
        succeed input

    else
        problem <|
            "expecting input to be between "
                ++ String.fromInt minimum
                ++ " and "
                ++ String.fromInt maximum


host : Parser Int
host =
    network


dot : Parser ()
dot =
    symbol "."


subnetMask : Parser Int
subnetMask =
    let
        toInt input =
            input
                |> String.dropLeft 1
                |> String.toInt
                |> Maybe.withDefault -1
    in
    (succeed ()
        |. chompIf (\c -> c == '/')
        |. chompWhile Char.isDigit
    )
        |> getChompedString
        |> map toInt


optionally : Parser a -> Parser (Maybe a)
optionally parser =
    oneOf
        [ parser |> map Just
        , succeed Nothing
        ]


optionalSubnetMask : Parser (Maybe Int)
optionalSubnetMask =
    optionally subnetMask
