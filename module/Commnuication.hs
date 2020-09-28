{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE OverloadedStrings #-}

module Commnuication where

import Data.Aeson

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

aesonTest =  decode . fromStrict. packChars $ "[1,2,3]" :: Maybe [Int]

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
    threadDelay 1000
    -- WS.sendTextData conn $ cmdBs
    WS.sendTextData conn $ BC.pack "Server got"  `BC.append` cmdBs `BC.append` "echo back" -- echo back
    return ()
