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

