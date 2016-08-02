module Demo.Code exposing (..) 

import Html exposing (Html, text)

import Platform.Cmd exposing (Cmd)
import String
import Markdown

import Material.Elevation as Elevation
import Material.Options as Options exposing (css, div, stylesheet, Property)
import Material.Helpers as Helpers exposing (cmd)


type State 
  = Idle 
  | First String
  | Showing String
  | FadingIn String
  | FadingOut (String, String)


type alias Model = State


model : Model 
model = Idle

type Msg 
  = Set String
  | Timeout String


delay : Float
delay = 
  200


later : String -> Cmd Msg 
later s = 
  Helpers.delay delay (Timeout s)


update : Msg -> State -> (State, Cmd Msg)
update action state = 
  let
    guard b x = 
      if b then 
        x
      else
        (state, Cmd.none)
  in
    case action of 
      Set s -> 
        case state of 
          Idle ->              
            (First s, cmd (Timeout s))

          First _ -> 
            (First s, Cmd.none)
            
          Showing s' -> 
            guard (s /= s') ( FadingOut (s', s), later s' )

          FadingIn s' ->       
            guard (s /= s') ( FadingOut (s', s), later s )

          FadingOut (s', _) -> 
            (FadingOut (s', s), Cmd.none)

      Timeout s -> 
        case state of 
          Idle -> 
            ( state, Cmd.none ) -- Can't happen

          First _ -> 
            ( FadingIn s, later s )

          Showing s' -> 
            ( state, Cmd.none ) -- Also can't happen

          FadingIn s' -> 
            guard (s == s') ( Showing s, Cmd.none )

          FadingOut (s', s'') -> 
            guard (s == s') ( FadingIn s'', later s'' )


-- Shenanigans to strip extra whitespace from code examples. 


lead : Int -> String -> Int
lead k str = 
  case String.uncons str of 
    Just (' ', str') -> 
      lead (k+1) str'

    _ -> 
      k


dropWhile : (a -> Bool) -> List a -> List a
dropWhile f xs =
  case xs of
    [] -> 
      xs
    (x :: xs') as xs -> 
      if f x then dropWhile f xs' else xs

trim : String -> String
trim s = 
  let
    -- Drop initial empty lines
    lines = 
      String.trimRight s
        |> String.lines 
        |> dropWhile (String.trim >> (==) "")
    -- Find the amount of lead space on the first line
    k = 
      List.head lines 
        |> Maybe.map (lead 0)
        |> Maybe.withDefault 0
  in
    -- Remove that amount of space from every line
    lines 
      |> List.map (String.dropLeft k)
      |> String.join "\n"


code : List (Property c m) -> String -> Html m
code options str = 
  div 
    (Options.many
      [ css "overflow" "auto" 
      , css "border-radius" "2px"
      , css "font-size" "10pt"
      , Elevation.e2
      ] :: options)
    [ Markdown.toHtml [] <| "```elm\n" ++ trim str ++ "\n```" ]


html : List (Property c m) -> String -> Html m
html options str = 
  div 
    (Options.many
      [ css "overflow" "auto" 
      , css "border-radius" "2px"
      , css "font-size" "10pt"
      , Elevation.e2
      ] :: options)
    [ Markdown.toHtml [] <| "```html\n" ++ trim str ++ "\n```" ]


-- VIEW


view : State -> List (Property c a) -> Html a
view state options = 
  let 
    opacity =
      case state of 
        Idle -> 0
        First _ -> 0
        FadingIn _ -> 1.0
        FadingOut _ -> 0 
        Showing _ -> 1.0
    body = 
      case state of 
        Idle -> text ""
        First s -> code options s
        FadingIn s -> code options s
        FadingOut (s, _) -> code options s
        Showing s -> code options s
  in
    div 
      [ css "transition" ("opacity " ++ toString delay ++ "ms ease-in-out")
      , css "opacity" (toString opacity)
      ]
      [ body ]






