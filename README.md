# `elm/parser` Example
Creating an `elm/parser` as an answer to a Slack question.

## Question
On Wednesday 26th of December 2018 **ajgreenb** asked the [following question](https://elmlang.slack.com/archives/C0CJ3SBBM/p1545854417211400) on Elm slack #general channel.

> hello! i have a `List String` in which all entries look like one of `2293487`, `10.128.16.255`, `192.168.1.2/32`. that is, it's either a string of just digits; four sets of 1-3 digits each separated by a `.`; or the same followed by a `/` and 1-2 digits. i want to map each list item according to whether it is an id or an ip address (the second two formats would ideally be treated identically.)
>
> initially i thought to use the `Regex` package, but the `Regex` package recommended looking at `elm/parser`. i can't seem to make that do what i want, though. i'm trying to be able to do something like
>
>```type A = ID String | IPAddress String
>
>toA : String -> A
>toA s =
>  case <something> s of
>    <matchID> id ->
>      ID id
>
>    <matchIPAddress> ipAddr ->
>      IPAddress ipAddr```
>
>and then i could `List.map toA [ "2293487", "10.128.16.255", "192.168.1.2/32" ]`. does what i'm trying to do make sense? and does anyone have a suggestion for a good way to do that?

## Answer
This repository contains Elm code that shows how a `elm/parser` can be used to solve ajgreenb problem. Furthermore, this README describes the rational behind some of the decisions.

The starting point will be a skeletal Elm project created by running `elm init` and `elm-test init`.

### Installing `elm/parser`
Add the dependency to `elm/parser` is a good starting point.

```sh
elm install elm/parser
```

### Model data
The next part is to model the data we want to end up with. The question provides a suggestion, but is does not expose the internal structure of the data. In order to provide some insight in how to parse rich data structures, we our modeling our data as follows. 

```elm
module Data exposing (Data(..))


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
```

### Provide `parse` function
Next we create a `parse` function and setup a test to check our intended API in a test. Because parsing can fail, we will need to return a `Result`.

```elm
parse : String -> Result String Data
parse input =
    Err "not yet implemented"
```

From the examples provided in the question we can extract the following tests. Note that the tests will fail at the moment.

```elm
module ParserTest exposing (suite)

import Data exposing (Data(..))
import Expect exposing (Expectation)
import Test exposing (..)


suite : Test
suite =
    describe "Data"
        [ describe "parse"
            [ test "parse identifier" <|
                \_ ->
                    let
                        input =
                            "2293487"

                        actual =
                            Data.parse input

                        expected =
                            Ok <| Identifier input
                    in
                    actual
                        |> Expect.equal expected
            , test "parse IP address" <|
                \_ ->
                    let
                        input =
                            "10.128.16.255"

                        actual =
                            Data.parse input

                        expected =
                            Ok <|
                                IpAddress
                                    { networkID1 = 10
                                    , networkID2 = 128
                                    , hostID1 = 16
                                    , hostID2 = 255
                                    , subnetMask = Nothing
                                    }
                    in
                    actual
                        |> Expect.equal expected
            , test "parse IP address with a subnet mask" <|
                \_ ->
                    let
                        input =
                            "10.128.16.255/32"

                        actual =
                            Data.parse input

                        expected =
                            Ok <|
                                IpAddress
                                    { networkID1 = 10
                                    , networkID2 = 128
                                    , hostID1 = 16
                                    , hostID2 = 255
                                    , subnetMask = Just 32
                                    }
                    in
                    actual
                        |> Expect.equal expected
            ]
        ]
```
