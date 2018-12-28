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
