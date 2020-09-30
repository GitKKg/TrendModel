{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

module Commnuication where

import GHC.Generics
import Data.Aeson
import Data.Text

import           Control.Monad           (forever, unless)
import qualified Data.ByteString         as B
import qualified Data.ByteString.Char8   as BC
import qualified Network.WebSockets      as WS
import qualified Network.WebSockets.Snap as WS
import           Snap.Core               (Snap)
import qualified Snap.Core               as Snap
import qualified Snap.Http.Server        as Snap
import qualified Snap.Util.FileServe     as Snap
import qualified System.IO               as IO
import Debug.Trace

import Control.Concurrent (threadDelay)
--import qualified System.Process          as Process

import Data.ByteString.Internal
import Data.ByteString.Lazy
import Data.Maybe

data Person = Person {
      name :: Text
    , age  :: Int
    } deriving (Generic, Show)

instance ToJSON Person where
    -- No need to provide a toJSON implementation.

    -- For efficiency, we write a simple toEncoding implementation, as
    -- the default version uses toJSON.
    toEncoding = genericToEncoding defaultOptions

encodePerson = encode (Person {name = "Joe", age = 12})

aesonTest =  decode . fromStrict. packChars $ "[1,2,3]" :: Maybe [Int]

en123 = encode ([1,2,3] :: [Int])

de123 = decode en123 :: Maybe [Int]

data StockData = StockData {
  code :: String,
  pricesL :: [Float]
                           } deriving (Generic , Show)

instance ToJSON StockData where
  toEncoding = genericToEncoding defaultOptions

instance FromJSON StockData where
  parseJSON = withObject "StockData" $ \v -> StockData
    <$> v .: "code"
    <*> v .: "pricesL" 
    

someStock = encode (StockData {code ="000001", pricesL = [1.2,3.6,9.08]})
someStockD = decode someStock :: Maybe StockData

data MessagePack = MessagePack {
  mpType :: String,
  mpWords :: String, -- talking words
  mpPayload :: StockData
                               } deriving (Generic, Show)

instance ToJSON MessagePack where
  toEncoding = genericToEncoding defaultOptions

instance FromJSON MessagePack where
  parseJSON = withObject "MessagePack" $ \v -> MessagePack
    <$> v .: "mpType"
    <*> v .: "mpMsg"
    <*> v .: "mpPayload" 
  
messagePack1 = encode (MessagePack
                       { mpType = "pricesL", mpWords = "data" ,
                         mpPayload = StockData {
                           code ="000001", pricesL = [1.2,3.6,9.08]
                           }
                       }
                      )

emptyStockData = StockData {
  code = "",
  pricesL = []
                           }

messagePack2 = encode (MessagePack
                       { mpType = "pricesL", mpWords = "data" ,
                         mpPayload = fromJust someStockD
                       }
                      )
messagePack3 = encode (MessagePack
                       { mpType = "words",
                         mpWords = "Hello,client!",
                         mpPayload = emptyStockData 
                       }
                      )                              

messagePack1D = decode messagePack1 :: Maybe MessagePack

snapApp :: Snap ()
snapApp = Snap.route
  [
    -- use Snap.serveDirectory to set html directory
    -- could not add Snap.ifTop,it seems some js files will be got in the deeper path
    -- "/home/kyle/vue/QuasarWebSocketD3Trend/dist/spa/"
    -- "/home/kyle/vue/Stock_app/dist/spa-mat/"
    ("", Snap.serveDirectory "/home/kyle/vue/QuasarWebSocketD3Trend/dist/spa/"),
    -- ws://localhost:8000/websocket
    ("websocket" , wsSnapHandle)
  ]

wsSnapHandle :: Snap ()
wsSnapHandle = WS.runWebSocketsSnap wsHandle

wsHandle :: WS.ServerApp
wsHandle pending = do
  conn <- WS.acceptRequest pending
  forever $ do
    traceM $ "hi"
    cmdBs <- WS.receiveData @B.ByteString conn
    traceM $ "Server Got message " ++ show cmdBs
    threadDelay 1000000
    -- WS.sendTextData conn $ cmdBs
--    WS.sendTextData conn $ BC.pack "Server got"  `BC.append` cmdBs `BC.append` "echo back" -- echo back
    --WS.sendTextData conn $ someStock
    WS.sendTextData conn $ messagePack2
    WS.sendTextData conn $ messagePack3
    --WS.sendClose conn $ BC.pack "bye"
    return ()
