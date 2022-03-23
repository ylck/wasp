module Wasp.Analyzer.Parser.Tokenizer
  ( isValidWaspIdentifier,
  )
where

import Control.Monad.Except (runExcept)
import Control.Monad.State (evalStateT)
import Wasp.Analyzer.Parser.Lexer (alexScanTokens)
import Wasp.Analyzer.Parser.Monad (Parser, makeInitialState)
import Wasp.Analyzer.Parser.Token (Token (Token), TokenType (TIdentifier))

isValidWaspIdentifier :: String -> Bool
isValidWaspIdentifier str = case tokenize str of
  Just [Token (TIdentifier name) _ _] -> length name == length str
  _ -> False

tokenize :: String -> Maybe [Token]
tokenize str = alexScanTokens str >>= extractTokens

extractTokens :: [Parser Token] -> Maybe [Token]
extractTokens = mapM extractToken

extractToken :: Parser Token -> Maybe Token
extractToken tokenParser = case runExcept $ evalStateT tokenParser $ makeInitialState "" of
  Left _ -> Nothing
  Right token -> Just token
