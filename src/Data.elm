module Data exposing (Data(..), parse)


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
    Err "not yet implemented"
