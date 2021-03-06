{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveDataTypeable, OverloadedStrings #-}

module Config
    ( readConfig
    , Config(..)
    , Network(..)
    , Channel(..)
    , WatchedRepo(..)
    ) where

import Control.Applicative ((<$>), (<*>), pure, (<|>))
import Data.Aeson (Value (..), FromJSON (..), (.:), (.:?), (.!=), Object, eitherDecode)
import Data.Text (Text)

import GHC.Generics (Generic) -- used to automatically create instances of Hashable
import Data.Hashable -- (Hashable)

import System.IO (withFile, IOMode(ReadMode), hGetContents)

--import qualified Data.ByteString.Char8 as B
import qualified Data.ByteString.Lazy.Char8 as B


data Config = Config
    { configNetworks :: [Network]
    , configAuthToken :: Text
    } deriving (Show, Eq, Generic)

instance FromJSON Config where
    parseJSON (Object v) =
        Config <$> v .: "networks"
               <*> v .: "auth_token" -- for GitHub
    parseJSON _ = fail "Config must be an object"

instance Hashable Config

data Network = Network
    { networkName :: Text
    , networkServer :: Text
    , networkPort :: Int
    , networkNick :: Text
    , networkChannels :: [Channel]
    } deriving (Show, Eq, Generic)

instance FromJSON Network where
    parseJSON (Object v) =
        Network <$> v .: "name"
                <*> v .: "server"
                <*> v .: "port"
                <*> v .: "nick"
                <*> v .: "channels"
    parseJSON _ = fail "Network must be an object"

instance Hashable Network

data Channel = Channel
    { channelName :: Text
    , channelWatchedGithubRepos :: [WatchedRepo]
    , channelEnableOffensiveLanguage :: Bool
    , channelReplyToGreetings :: Bool
    , channelReplyToCatchPhrases :: Bool
    } deriving (Show, Eq, Generic)

instance FromJSON Channel where
    parseJSON (Object v) =
        Channel <$> v .: "name"
                <*> v .:? "watched_repos" .!= []
                <*> v .: "offensive_language"
                <*> v .:? "reply_to_greetings" .!= False
                <*> v .:? "reply_to_catch_phrases" .!= False
    parseJSON _ = fail "Channel must be an object"

instance Hashable Channel

data WatchedRepo = WatchedRepo
    { watchedRepoOwner :: Text
    , watchedRepoName :: Text
    } deriving (Show, Eq, Generic)

instance FromJSON WatchedRepo where
    parseJSON (Object v) =
        WatchedRepo <$> v .: "owner"
                    <*> v .: "name"
    parseJSON _ = fail "WatchedRepo must be an object"

instance Hashable WatchedRepo

-- Mapping filename to IO action returning a Config object
readConfig :: String -> IO (Maybe Config)
readConfig filename = do
                        json <- readFile filename
                        dec <- return ((eitherDecode $ B.pack json) :: (Either String Config)) -- TODO: Clean this up!
                        case dec of
                            Left err -> putStrLn err >> return Nothing
                            Right config -> return $ Just config

