{-# LANGUAGE OverloadedStrings #-}

module Main where

import           Control.Concurrent      (forkIO)
import           Control.Exception       (finally)
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
--import qualified System.Process          as Process

app :: Snap ()
app = Snap.route
  [
    -- use Snap.serveDirectory to set html directory
    ("", Snap.serveDirectory "/home/kyle/WebProgramming/Stock_app/dist/spa-mat/")
  ]

main :: IO ()
main = Snap.httpServe config app
  where
    config =
        Snap.setErrorLog  Snap.ConfigNoLog $
        Snap.setAccessLog Snap.ConfigNoLog $
        Snap.defaultConfig
