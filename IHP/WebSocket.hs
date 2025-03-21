{-|
Module: IHP.WebSocket
Description: Building blocks for websocket applications
Copyright: (c) digitally induced GmbH, 2020
-}
{-# LANGUAGE AllowAmbiguousTypes #-}
module IHP.WebSocket
( WSApp (..)
, startWSApp
, setState
, getState
, receiveData
, receiveDataMessage
, sendTextData
)
where

import IHP.Prelude
import qualified Network.WebSockets as Websocket
import IHP.ApplicationContext
import IHP.Controller.RequestContext
import qualified Data.UUID as UUID
import qualified Data.Maybe as Maybe
import qualified Control.Exception as Exception
import IHP.Controller.Context

class WSApp state where
    initialState :: state

    run :: (?state :: IORef state, ?context :: ControllerContext, ?applicationContext :: ApplicationContext, ?modelContext :: ModelContext, ?connection :: Websocket.Connection) => IO ()
    run = pure ()

    onPing :: (?state :: IORef state, ?context :: ControllerContext, ?applicationContext :: ApplicationContext, ?modelContext :: ModelContext, ?connection :: Websocket.Connection) => IO ()
    onPing = pure ()

    onClose :: (?state :: IORef state, ?context :: ControllerContext, ?applicationContext :: ApplicationContext, ?modelContext :: ModelContext, ?connection :: Websocket.Connection) => IO ()
    onClose = pure ()

startWSApp :: forall state. (WSApp state, ?applicationContext :: ApplicationContext, ?requestContext :: RequestContext, ?context :: ControllerContext, ?modelContext :: ModelContext) => Websocket.Connection -> IO ()
startWSApp connection = do
    state <- newIORef (initialState @state)
    let ?state = state
    let ?connection = connection
    let
        handleException Websocket.ConnectionClosed = pure ()
        handleException (Websocket.CloseRequest {}) = pure ()
        handleException e = error ("Unhandled Websocket exception: " <> show e)
    result <- Exception.try ((Websocket.withPingThread connection 30 (onPing @state) (run @state)) `Exception.catch` handleException)
    onClose @state
    case result of
        Left (Exception.SomeException e) -> putStrLn (tshow e)
        Right _ -> pure ()

setState :: (?state :: IORef state) => state -> IO ()
setState newState = writeIORef ?state newState

getState :: (?state :: IORef state) => IO state
getState = readIORef ?state

receiveData :: (?connection :: Websocket.Connection, Websocket.WebSocketsData a) => IO a
receiveData = Websocket.receiveData ?connection

receiveDataMessage :: (?connection :: Websocket.Connection) => IO Websocket.DataMessage
receiveDataMessage = Websocket.receiveDataMessage ?connection

sendTextData :: (?connection :: Websocket.Connection, Websocket.WebSocketsData text) => text -> IO ()
sendTextData text = Websocket.sendTextData ?connection text

instance Websocket.WebSocketsData UUID where
    fromDataMessage (Websocket.Text byteString _) = UUID.fromLazyASCIIBytes byteString |> Maybe.fromJust
    fromDataMessage (Websocket.Binary byteString) = UUID.fromLazyASCIIBytes byteString |> Maybe.fromJust
    fromLazyByteString byteString = UUID.fromLazyASCIIBytes byteString |> Maybe.fromJust
    toLazyByteString = UUID.toLazyASCIIBytes
