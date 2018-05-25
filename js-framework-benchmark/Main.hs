{-# LANGUAGE OverloadedStrings #-}
module Main where

-- from base
import Control.Arrow ((&&&))
import Control.Monad (void)
import qualified Data.List as L (tail,splitAt,filter)
import Data.Monoid ((<>))
import Data.Traversable (for)

-- from pure-default
import Pure.Data.Default (Default(..))

-- from pure-txt
import Pure.Data.Txt (Txt,ToTxt(..),FromTxt(..))
import qualified Pure.Data.Txt as Txt

-- from pure-core
import Pure.Data.View
import Pure.Data.View.Patterns

-- from pure-html
import Pure.Data.HTML
import Pure.Data.HTML.Properties hiding (Span)

-- from pure-dom
import Pure.DOM (inject)

-- from pure-lifted
import Pure.Data.Lifted (Element(..),Body(..),getBody,toJSV)

-- from pure-events
import Pure.Data.Events

-- from vector
import qualified Data.Vector as V
import qualified Data.Vector.Mutable as MV

--------------------------------------------------------------------------------

foreign import javascript unsafe
  "$r = Math.round(Math.random()*1000)%$1"
    rand :: Int -> IO Int

data Row = Row
  { ident    :: Int
  , label    :: Txt
  , selected :: Bool
  } deriving Eq

data Model = Model
  { rows    :: [(Int,Row)]
  , lastId  :: Int
  }

data Msg
  = CreateM Int
  | AppendM Int
  | UpdateEveryM Int
  | ClearM
  | SwapM
  | SelectM Int
  | RemoveM Int
  | DoNothingM

adjectives :: V.Vector Txt
adjectives = V.fromList
  [  "pretty",  "large",  "big",  "small",  "tall",  "short",  "long"
  ,  "handsome",  "plain",  "quaint",  "clean",  "elegant",  "easy",  "angry"
  ,  "crazy",  "helpful",  "mushy",  "odd",  "unsightly",  "adorable"
  ,  "important",  "inexpensive",  "cheap",  "expensive",  "fancy"
  ]

colors :: V.Vector Txt
colors = V.fromList
  [  "red",  "yellow",  "blue",  "green",  "pink",  "brown"
  ,  "purple",  "brown",  "white",  "black",  "orange"
  ]

nouns :: V.Vector Txt
nouns = V.fromList
  [  "table",  "chair",  "house",  "bbq",  "desk",  "car"
  ,  "pony",  "cookie",  "sandwich",  "burger",  "pizza"
  ,  "mouse",  "keyboard"
  ]

text :: (ToTxt a) => a -> View
text = fromTxt . toTxt

choose :: V.Vector x -> IO x
choose vs = do
  r <- rand (V.length vs)
  return $ vs V.! r

createRows :: Int -> Int -> IO [(Int,Row)]
createRows n newId = for [0..n] $ \n -> do
  adjective <- choose adjectives
  color     <- choose colors
  noun      <- choose nouns
  return (n,Row
    { ident    = newId + n
    , label    = Txt.intercalate " " [adjective,color,noun]
    , selected = False
    })

bang :: (Int,Row) -> (Int,Row)
bang (index,row)
  | index `mod` 10 == 0 = (index,row { label = label row <> " !!!" })
  | otherwise           = (index,row)

-- updateEvery :: Int -> (Row -> Row) -> [Row] -> [Row]
-- updateEvery n f = V.toList . update . V.fromList
--   where
--     update vector =
--       let
--         count = quot (V.length vector) n
--         patch x = ( x * n, f )
--         patches = V.generate count patch
--       in
--         V.accumulate (flip ($)) vector patches

swap :: Int -> Int -> [a] -> [a]
swap i j = V.toList . V.modify (\v -> MV.swap v i j) . V.fromList

selectRow :: Int -> Row -> Row
selectRow i row
  | i == ident row = row { selected = True  }
  | i /= ident row = row { selected = False }
  | otherwise      = row

main :: IO ()
main = do
  b <- getBody
  inject (Element $ toJSV b) $ ($ ()) $ ComponentIO $ \self ->
    let
        upd msg = void $ setState self $ \_ mdl -> do
          mdl' <-
            case msg of
              CreateM amount -> do
                newRows <- createRows amount (lastId mdl)
                return mdl { rows = newRows, lastId = lastId mdl + amount }

              AppendM amount -> do
                newRows <- createRows amount (lastId mdl)
                return mdl { rows = rows mdl <> newRows, lastId = lastId mdl + amount }

              UpdateEveryM amount ->
                return mdl { rows = fmap bang (rows mdl) }

              ClearM ->
                return mdl { rows = [] }

              SwapM ->
                return mdl { rows = swap 1 998 (rows mdl) }

              RemoveM i ->
                return mdl { rows = L.filter (\(_,r) -> ident r /= i) (rows mdl) }

              SelectM i ->
                return mdl { rows = fmap (fmap (selectRow i)) (rows mdl) }

              DoNothingM ->
                return mdl
          return (mdl',return ())

        buttonPrimaryBlock :: [View]
        buttonPrimaryBlock = fmap button buttons
          where
            button (ident,label,msg) =
              Div <| Classes [ "col-sm-6", "smallpad" ] |>
                [ Button <| Attribute "ref" "text"
                          . Classes [ "btn", "btn-primary", "btn-block" ]
                          . OnClick (\_ -> upd msg)
                          . Type "button"
                          . Id ident
                          |>
                    [ fromTxt label ]
                ]

            buttons =
              [ ( "run10", "Create 10 rows", CreateM 10 )
              , ( "run", "Create 1,000 rows", CreateM 1000 )
              , ( "runlots", "Create 10,000 rows", CreateM 10000 )
              , ( "add10", "Append 100 rows", AppendM 10 )
              , ( "add", "Append 1,000 rows", AppendM 1000 )
              , ( "update2", "Update every 2nd row", UpdateEveryM 2 )
              , ( "update", "Update every 10th row", UpdateEveryM 10 )
              , ( "clear", "Clear", ClearM )
              , ( "swaprows", "Swap Rows", SwapM )
              , ( "donothing", "Do Nothing", DoNothingM )
              ]

        row :: Row -> View
        row = ComponentIO $ \self ->
          def
            { construct = return ()
            , force = \n _ -> do
                o <- getProps self
                return (ident o /= ident n || label o /= label n || selected o /= selected n)
            , render = \(Row i l s) _ ->
                Tr <| (if s then Class "danger" else id) |>
                  [ Td <| Class "col-md-1" |> [ text i ]
                  , Td <| Class "col-md-4" |> [ A <| OnClick (\_ -> upd (SelectM i)) |> [ text l ] ]
                  , Td <| Class "col-md-1" |>
                      [ A <| OnClick (\_ -> upd (RemoveM i)) |>
                          [ Span <| Classes [ "glyphicon", "glyphicon-remove" ] . Attribute "aria-hidden" "true"
                          ]
                      ]
                  , Td <| Class "col-md-6"
                  ]
            }
    in
        def
            { construct = return (Model [] 1)
            , render = \_ model ->
                Div <| Id "main" |>
                    [ Div <| Class "container" |>
                        [ Div <| Class "jumbotron" |>
                            [ Div <| Class "row" |>
                                  [ Div <| Class "col-md-6" |> [ H1 <||> [ "pure-v0.7-keyed" ] ]
                                  , Div <| Class "col-md-6" |> buttonPrimaryBlock
                                  ]
                            ]
                        , Table <| Classes [ "table", "table-hover", "table-striped", "test-data" ] |>
                            [ (Keyed Tbody) <||#> fmap (fmap row) (rows model) ]
                        , Span <| Classes [ "preloadicon", "glyphicon", "glyphicon-remove" ] . Property "aria-hidden" "true"
                        ]
                    ]
            }
