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
            , test "parsing \"10a.2bc.3#!.19\" should parse as an identifier" <|
                \_ ->
                    let
                        input =
                            "10a.2bc.3#!.19"

                        actual =
                            Data.parse input

                        expected =
                            Ok <|
                                Identifier "10"
                    in
                    actual
                        |> Expect.equal expected
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
            ]
        ]
