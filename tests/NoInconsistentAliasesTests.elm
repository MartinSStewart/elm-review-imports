module NoInconsistentAliasesTests exposing (all)

import NoInconsistentAliases as Rule exposing (rule)
import Review.Test
import Test exposing (Test, describe, test)


all : Test
all =
    describe "NoInconsistentAliases"
        [ test "reports incorrect aliases" <|
            \_ ->
                """
module Main exposing (main)
import Html
import Html.Attributes as A
main = Html.div [ A.class "container" ] []
"""
                    |> Review.Test.run
                        (Rule.config
                            [ ( [ "Html", "Attributes" ], "Attr" )
                            ]
                            |> rule
                        )
                    |> Review.Test.expectErrors
                        [ incorrectAliasError "Attr" "Html.Attributes" "A"
                            |> Review.Test.atExactly { start = { row = 4, column = 27 }, end = { row = 4, column = 28 } }
                            |> Review.Test.whenFixed
                                """
module Main exposing (main)
import Html
import Html.Attributes as Attr
main = Html.div [ Attr.class "container" ] []
"""
                        ]
        , test "reports incorrect aliases in a function signature" <|
            \_ ->
                """
module Main exposing (main)
import Json.Encode as E
import Page
main : Program E.Value Page.Model Page.Msg
main =
    Page.program
"""
                    |> Review.Test.run
                        (Rule.config
                            [ ( [ "Json", "Encode" ], "Encode" )
                            ]
                            |> rule
                        )
                    |> Review.Test.expectErrors
                        [ incorrectAliasError "Encode" "Json.Encode" "E"
                            |> Review.Test.atExactly { start = { row = 3, column = 23 }, end = { row = 3, column = 24 } }
                            |> Review.Test.whenFixed
                                """
module Main exposing (main)
import Json.Encode as Encode
import Page
main : Program Encode.Value Page.Model Page.Msg
main =
    Page.program
"""
                        ]
        , test "reports incorrect aliases in a type alias" <|
            \_ ->
                """
module Main exposing (main)
import Json.Encode as E
import Page
type alias JsonValue = E.Value
main : Program JsonValue Page.Model Page.Msg
main =
    Page.program
"""
                    |> Review.Test.run
                        (Rule.config
                            [ ( [ "Json", "Encode" ], "Encode" )
                            ]
                            |> rule
                        )
                    |> Review.Test.expectErrors
                        [ incorrectAliasError "Encode" "Json.Encode" "E"
                            |> Review.Test.atExactly { start = { row = 3, column = 23 }, end = { row = 3, column = 24 } }
                            |> Review.Test.whenFixed
                                """
module Main exposing (main)
import Json.Encode as Encode
import Page
type alias JsonValue = Encode.Value
main : Program JsonValue Page.Model Page.Msg
main =
    Page.program
"""
                        ]
        , test "does not report modules imported with no alias" <|
            \_ ->
                """
module Main exposing (main)
import Html.Attributes
main = 1"""
                    |> Review.Test.run
                        (Rule.config
                            [ ( [ "Html", "Attributes" ], "Attr" )
                            ]
                            |> rule
                        )
                    |> Review.Test.expectNoErrors
        , test "does not report modules with the correct alias" <|
            \_ ->
                """
module Main exposing (main)
import Html.Attributes as Attr
main = 1"""
                    |> Review.Test.run
                        (Rule.config
                            [ ( [ "Html", "Attributes" ], "Attr" )
                            ]
                            |> rule
                        )
                    |> Review.Test.expectNoErrors
        , test "does not report modules with no preferred alias" <|
            \_ ->
                """
module Main exposing (main)
import Json.Encode as E
main = 1"""
                    |> Review.Test.run
                        (Rule.config
                            [ ( [ "Html", "Attributes" ], "Attr" )
                            ]
                            |> rule
                        )
                    |> Review.Test.expectNoErrors
        ]


incorrectAliasError : String -> String -> String -> Review.Test.ExpectedError
incorrectAliasError expectedAlias moduleName wrongAlias =
    Review.Test.error
        { message = "Incorrect alias `" ++ wrongAlias ++ "` for module `" ++ moduleName ++ "`"
        , details = [ "This import does not use your preferred alias `" ++ expectedAlias ++ "`." ]
        , under = wrongAlias
        }
