{-# LANGUAGE OverloadedStrings #-}
module Main where

-- from pure
import Pure

-- from base
import Control.Arrow ((&&&))
import Control.Monad (unless,void)
import Data.List as L (filter)
import Data.Monoid ((<>))
import Data.Traversable (for)

-- from vector
import qualified Data.Vector as V
import qualified Data.Vector.Mutable as MV

--------------------------------------------------------------------------------

foreign import javascript unsafe
  "$r = Math.round(Math.random()*1000)%$1"
    rand :: Int -> IO Int

data Row = Row
  { ident     :: Int
  , label     :: String
  , selected  :: Bool
  , update    :: Msg -> IO ()
  , rendered  :: View
  }

data Model = Model
  { rows    :: V.Vector Row
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

adjectives :: V.Vector String
adjectives = V.fromList
  [  "pretty",  "large",  "big",  "small",  "tall",  "short",  "long"
  ,  "handsome",  "plain",  "quaint",  "clean",  "elegant",  "easy",  "angry"
  ,  "crazy",  "helpful",  "mushy",  "odd",  "unsightly",  "adorable"
  ,  "important",  "inexpensive",  "cheap",  "expensive",  "fancy"
  ]

colors :: V.Vector String
colors = V.fromList
  [  "red",  "yellow",  "blue",  "green",  "pink",  "brown"
  ,  "purple",  "brown",  "white",  "black",  "orange"
  ]

nouns :: V.Vector String
nouns = V.fromList
  [  "table",  "chair",  "house",  "bbq",  "desk",  "car"
  ,  "pony",  "cookie",  "sandwich",  "burger",  "pizza"
  ,  "mouse",  "keyboard"
  ]

choose :: V.Vector x -> IO x
choose vs = do
  r <- rand (V.length vs)
  return $ V.unsafeIndex vs r

createRows :: Int -> Int -> (Msg -> IO ()) -> IO (V.Vector Row)
createRows n newId update = V.generateM n $ \n -> do
  adjective <- choose adjectives
  color     <- choose colors
  noun      <- choose nouns
  return $ renderRow $ Row (newId + n) (adjective <> " " <> color <> " " <> noun) False update undefined

bang :: Row -> Row
bang row = renderRow row { label = label row <> " !!!" }

updateEvery :: Int -> (a -> a) -> V.Vector a -> V.Vector a
updateEvery n f = V.modify (flip update 0)
  where
    update v = go
      where
        go x = unless (x >= MV.length v) $ do
          MV.unsafeModify v f x
          go (x + n)

swap :: Int -> Int -> V.Vector a -> V.Vector a
swap i j = V.modify (\v -> MV.swap v i j)

renderRow :: Row -> Row
renderRow r = r { rendered = View r }

selectRow :: Int -> Row -> Row
selectRow i row
  | i == ident row = renderRow row { selected = True  }
  | selected row   = renderRow row { selected = False }
  | otherwise      = row

data Button = Button
  { bId :: Txt
  , bLabel :: Txt
  , bEvt :: IO ()
  }

button :: (Msg -> IO ()) -> (Txt,Txt,Msg) -> View
button f (ident,label,msg) = View (Main.Button ident label (f msg))

instance Pure Main.Button where
  view (Main.Button ident label evt) =
    Div <| Classes [ "col-sm-6", "smallpad" ] |>
        [ Pure.Button <| Attribute "ref" "text"
                      . Classes [ "btn", "btn-primary", "btn-block" ]
                      . OnClick (\_ -> evt)
                      . Type "button"
                      . Id ident
                      |>
            [ txt label ]
        ]

buttons :: [(Txt,Txt,Msg)]
buttons =
    [ ( "run"       , "Create 1,000 rows"    , CreateM 1000      )
    , ( "runlots"   , "Create 10,000 rows"   , CreateM 10000     )
    , ( "add"       , "Append 1,000 rows"    , AppendM 1000      )
    , ( "update"    , "Update every 10th row", UpdateEveryM 10   )
    , ( "clear"     , "Clear"                , ClearM            )
    , ( "swaprows"  , "Swap Rows"            , SwapM             )
    ]

instance Pure Row where
  view (Row i l s upd _) =
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

keyedRows :: V.Vector Row -> [(Int,View)]
keyedRows = fmap (ident &&& rendered) . V.toList

main :: IO ()
main = do
  b <- getBody
  inject b $ flip ComponentIO () $ \self ->
    let
        upd msg = void $ setState self $ \_ mdl -> do
          mdl' <-
            case msg of
              CreateM amount -> do
                newRows <- createRows amount (lastId mdl) upd
                return mdl { rows = newRows, lastId = lastId mdl + amount }

              AppendM amount -> do
                newRows <- createRows amount (lastId mdl) upd
                return mdl { rows = rows mdl <> newRows, lastId = lastId mdl + amount }

              UpdateEveryM amount ->
                return mdl { rows = updateEvery 10 bang (rows mdl) }

              ClearM ->
                return mdl { rows = V.empty }

              SwapM ->
                return mdl { rows = swap 1 998 (rows mdl) }

              RemoveM i ->
                return mdl { rows = V.filter ((/= i) . ident) (rows mdl) }

              SelectM i ->
                return mdl { rows = fmap (selectRow i) (rows mdl) }

          return (mdl',return ())

    in
        def
            { construct = return (Model V.empty 1)
            , render = \_ model ->
                Div <| Id "main" |>
                    [ Div <| Class "container" |>
                        [ Div <| Class "jumbotron" |>
                            [ Div <| Class "row" |>
                                  [ Div <| Class "col-md-6" |> [ H1 <||> [ txt "pure-v0.7-keyed" ] ]
                                  , Div <| Class "col-md-6" |> (fmap (Main.button upd) buttons)
                                  ]
                            ]
                        , Table <| Classes [ "table", "table-hover", "table-striped", "test-data" ] |>
                            [ Keyed Tbody <||#> keyedRows (rows model) ]
                        , Span <| Classes [ "preloadicon", "glyphicon", "glyphicon-remove" ] . Property "aria-hidden" "true"
                        ]
                    ]
            }
