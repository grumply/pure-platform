{-# LANGUAGE OverloadedStrings #-}
module Main where

-- from pure
import Pure

-- from pure-txt
import qualified Pure.Data.Txt as Txt

-- from base
import Control.Arrow ((&&&))
import Control.Monad (void)
import qualified Data.List as L (tail,splitAt,filter)
import Data.Monoid ((<>))
import Data.Traversable (for)
import Data.Function (fix)

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

instance Pure Row where
  view (Row i l s upd _) =
    Tr <| (if s then Class "danger" else id) |>
      [ Td <| Class "col-md-1" |> [ fromTxt $ int i ]
      , Td <| Class "col-md-4" |> [ A <| OnClick (\_ -> upd (SelectM i)) |> [ fromTxt $ toTxt l ] ]
      , Td <| Class "col-md-1" |>
          [ A <| OnClick (\_ -> upd (RemoveM i)) |>
              [ Span <| Classes [ "glyphicon", "glyphicon-remove" ] . Attribute "aria-hidden" "true"
              ]
          ]
      , Td <| Class "col-md-6"
      ]

data Model = Model
  { rows    :: V.Vector (Int,Row)
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

text :: (ToTxt a) => a -> View
text = fromTxt . toTxt

choose :: V.Vector x -> IO x
choose vs = do
  r <- rand (V.length vs)
  return $ V.unsafeIndex vs r

createRows :: Int -> Int -> (Msg -> IO ()) -> IO (V.Vector (Int,Row))
createRows n newId upd = V.generateM n $ \n -> do
  adjective <- choose adjectives
  color     <- choose colors
  noun      <- choose nouns
  return (n,fix $ \r -> Row (newId + n) (adjective <> " " <> color <> " " <> noun) False upd (view r))

-- bang :: (Int,Row) -> (Int,Row)
-- bang (index,row)
--   | index `mod` 10 == 0 = (index,fix $ \r -> row { label = label row <> " !!!", rendered = view r })
--   | otherwise           = (index,row)

bang :: (Int,Row) -> (Int,Row)
bang (index,row) = (index,fix $ \r -> row { label = label row <> " !!!", rendered = view r })

updateEvery :: Int -> (a -> a) -> V.Vector a -> V.Vector a
updateEvery n f vector =
    let
      count = quot (V.length vector) n
      patch x = ( x * n, f )
      patches = V.generate count patch
    in
      V.accumulate (flip ($)) vector patches

swap :: Int -> Int -> V.Vector a -> V.Vector a
swap i j = V.modify (\v -> MV.swap v i j)

selectRow :: Int -> Row -> Row
selectRow i row
  | i == ident row = fix $ \r -> row { selected = True , rendered = view r }
  | selected row   = fix $ \r -> row { selected = False, rendered = view r }
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
                return mdl { rows = V.filter (\(_,r) -> ident r /= i) (rows mdl) }

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

        -- row :: Row -> View
        -- row = ComponentIO $ \self ->
        --   def
        --     { construct = return ()
        --     , force = \n _ -> do
        --         o <- getProps self
        --         return (ident o /= ident n || label o /= label n || selected o /= selected n)
        --     , render = \
        --     }
    in
        def
            { construct = return (Model V.empty 1)
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
                            [ (Keyed Tbody) <||#> fmap (fmap rendered) (V.toList (rows model)) ]
                        , Span <| Classes [ "preloadicon", "glyphicon", "glyphicon-remove" ] . Property "aria-hidden" "true"
                        ]
                    ]
            }
