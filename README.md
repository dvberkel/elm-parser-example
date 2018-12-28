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

This walk through is meant to provide an example of `elm/parser` but it is expected that you are at least familiar with the [documentation](https://package.elm-lang.org/packages/elm/parser/latest/).

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

### Import `elm/parser`
When working with `elm/parser` it is nice to freely use all the functionality. Therefore we expose all the bindings in the `Parser` name space.

```elm
import Parser exposing (..)
```

### Focusing on `Identifier`
The beauty of `elm/parser` is that it allows you to focus on a single part and combine them later on. For now we will focus on a parser for the `Identifier`.

We will start with the signature of the `identifier` function. This function is a `Parser Data` that will parse an `Identifier`

```elm
identifier : Parser Data
```

To implement the parser we take a look at the [`getChompedString`](https://package.elm-lang.org/packages/elm/parser/latest/Parser#getChompedString) function. It takes a parser and returns the String that this parser consumed. It works with the family of `chomp...` functions like `chompIf`, `chompWhile` etcetera.

We are going to look for the [`chompWhile: (Char -> Bool) -> Parser ()`](https://package.elm-lang.org/packages/elm/parser/latest/Parser#chompWhile) function. From the documentation

> Chomp zero or more characters if they pass the test. This is commonly useful for chomping whitespace or variable names

We want to chomp digits for which we can use the [`Char.isDigit`](https://package.elm-lang.org/packages/elm/core/latest/Char#isDigit) function.

The `getChompedString` returns a `String` and we want `Data` we can use the [`Parser.map`](https://package.elm-lang.org/packages/elm/parser/latest/Parser#map) function to transform the parsed `String` into an `Identifier`.

```elm
identifier : Parser Data
identifier =
    chompWhile Char.isDigit
        |> getChompedString
        |> map Identifier
```

### Partial parsing input
We now can use the `identifier` parser to make some of our tests pass. `elm/parser` provides a [`run`](https://package.elm-lang.org/packages/elm/parser/latest/Parser#run) function that accepts a `Parser a` some input to parse and returns a `Result (List DeadEnd) a`.

[`DeadEnd`](https://package.elm-lang.org/packages/elm/parser/latest/Parser#DeadEnd) is a description of why a parser can get stuck. There is a [`deadEndsToString`](https://package.elm-lang.org/packages/elm/parser/latest/Parser#deadEndsToString) function but unfortunately that is [not implemented](https://github.com/elm/parser/issues/9) sensible. We are going to use it anyway, and come back to it later.

```elm
parse : String -> Result String Data
parse input =
    let
        parser =
            identifier
    in
    input
        |> run parser
        |> Result.mapError deadEndsToString

```

We bound the `identifier` parser to `parser` in a `let`-block so that we can change the parser easily later on.

This code now passes one of our tests.

### Focus on `IpAddress`
With the `identifier` under our belt, we continue with the `IpAddress`. The signature is similar

```elm
ipAddress : Parser Data
```

Now we will work in a top-down fashion. We will liberally dream up function that we will define until we find primitives that fit the bill.

So below we define the `ipAddress` parser in terms of parsers we wish we had.

```elm
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
```

Newly introduces parsers are `network`, `dot`, `host`, and `optionalSubnetMask`. Here are their signatures.

```elm
network: Parser Int

dot: Parser ()

host: Parser Int

optionalSubnetMask: Parser (Maybe Int)
```

#### `network`
Let's focus on `network` for the moment. The network part is basically a sequence of digits with a length of one, two or three. We already know how to parse a sequence of digits. Once we have parsed the digits we want to succeed or fail depending on the number of digits we parsed.

```elm
network : Parser Int
network =
    let
        toInt input =
            input
                |> String.toInt
                |> MaybeWithDefaul -1
    in
    chompWhile Char.isDigit
        |> getChompedString
        |> andThen (lengthWithIn 1 3)
        |> map toInt
```

Here you see the use of [`andThen`](https://package.elm-lang.org/packages/elm/parser/latest/Parser#andThen). Its signature `(a -> Parser b) -> Parser a -> Parser b` allows you to return a parser depending on the result of an other parser. We use it to succeed or fail depending on the length of the parsed digits.

```elm
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
```

Here the [`succeed`](https://package.elm-lang.org/packages/elm/parser/latest/Parser#succeed) return the input and [`problem`](https://package.elm-lang.org/packages/elm/parser/latest/Parser#problem) signals the failure.

#### `host`
`host` is exactly alike to `network`. One could create a single function and alias `network` and `host` to it.

#### `dot`
The `dot` parser parses `'.'`. The `elm/parser` package exposes [`symbol`](https://package.elm-lang.org/packages/elm/parser/latest/Parser#symbol) for this situation.

```elm
dot : Parser ()
dot =
    symbol "."
```

#### `optionalSubnetMask`
Arguably `optionalSubnetMask` is the most interesting. For this we will first focus on assuming the subnet-mask is always present. For this we create a `subnetMask` parser.

```elm
subnetMask : Parser Int
subnetMask =
    let
        toInt input =
            input
                |> String.dropLeft 1
                |> String.toInt
                |> Maybe.withDefault -1
    in
    succeed ()
        |> chompIf '/'
        |> chompWhile Char.isDigit
        |> getChompedString
        |> map toInt
```

Nothing new is presented here. We first chomp if the character is `'/'` and then chomp a sequence of digits. Because we also had chomped a `'/'` we need to drop that character when we convert it to a integer.

Now we are going to write an higher order function that will accept a `Parser a` and returns a `Parser (Maybe a)`. This allows us to make any parser optionally.

```elm
optionally : Parser a -> Parser (Maybe a)
optionally parser =
    oneOf
        [ parser |> map Just
        , succeed Nothing
        ]
```

[oneOf](https://package.elm-lang.org/packages/elm/parser/latest/Parser#oneOf) is a parser

> will keep trying parsers until oneOf them starts chomping characters. 

So we take our `parser` and create a new parser that wraps the result of `parser` in a `Just`. If that does not succeed, we accept `Nothing`.

`optionalSubnetMask` can now be implemented.

```elm
optionalSubnetMask : Parser (Maybe Int)
optionalSubnetMask =
    optionally subnetMask
```

### Parsing IpAddress or Identifier
`oneOf` can now also be used to implement our `parse` function. Instead of the `parser = identifier` in the let block, we should used

```elm
        parser =
            oneOf
                [ backtrackable ipAddress
                , identifier
                ]
```

The most notable new concept is [`backtrackable`](https://package.elm-lang.org/packages/elm/parser/latest/Parser#backtrackable). It is needed because oneOf will otherwise not choose a different path. Both ipAddress and identifier start with a sequence of digits, so `oneOf` will chomp characters in both cases. With backtrackable we allow `oneOf` to pick the alternate path.

## Test pass
With this definition the tests pass. The entire parser is given below.

```elm
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
``` 

### Part of input
At the moment our `parse` function would happily only parse a part of the input. For example if one would try to parse `"10a.2bc.3#!.19"` the result would be `Ok (Identifier "10")` as can be seen by the following repl session.

```plain
> import Data exposing (parse)
> parse "10a.2bc.3#!.19"
Ok (Identifier "10") : Result String Data.Data
```

We can remedy that by using the [`end`](https://package.elm-lang.org/packages/elm/parser/latest/Parser#end) parser.

In order not to disturb other test we will expose a `parseComplete` function.

```elm
parseComplete : String -> Result String Data
parseComplete input =
    let
        incompleteParser =
            oneOf
                [ backtrackable ipAddress
                , identifier
                ]

        parser =
            succeed identity
                |= incompleteParser
                |. end
    in
    input
        |> run parser
        |> Result.mapError deadEndsToString
```

which will pass the following test

```test
            , test "parsing \"10a.2bc.3#!.19\" with `parseComplete` should fail" <|
                \_ ->
                    let
                        input =
                            "10a.2bc.3#!.19"

                        actual =
                            Data.parseComplete input

                        expected =
                            Err "TODO deadEndsToString"
                    in
                    actual
                        |> Expect.equal expected
```

## Considerations
We made some choices that could have been made differently. Below we summarize them.

* Instead of using `getChompedString` we could have used `int`.
* Instead of using `getChompedString` and the general `Parser.map` we could have used `mapChompedString`.
* We haven't done error reporting.
