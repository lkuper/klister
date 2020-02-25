{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
module Value where

import Control.Lens
import Data.Text (Text)
import qualified Data.Text as T

import Core
import Datatype
import Env
import Signals
import Syntax

type VEnv = Env Var Value
type TEnv = Env MacroVar Value

data MacroAction
  = MacroActionPure Value
  | MacroActionBind MacroAction Closure
  | MacroActionSyntaxError (SyntaxError Syntax)
  | MacroActionSendSignal Signal
  | MacroActionWaitSignal Signal
  | MacroActionIdentEq HowEq Value Value
  | MacroActionLog Syntax
  deriving (Eq, Show)

data Value
  = ValueClosure Closure
  | ValueSyntax Syntax
  | ValueMacroAction MacroAction
  | ValueSignal Signal
  | ValueBool Bool
  | ValueCtor Constructor [Value]
  deriving (Eq, Show)

valueText :: Value -> Text
valueText (ValueClosure _) = "#<closure>"
valueText (ValueSyntax stx) = "'" <> syntaxText stx
valueText (ValueMacroAction m) = T.pack (show m)
valueText (ValueSignal s) = "#!" <> T.pack (show s)
valueText (ValueBool b) = if b then "#true" else "#false"
valueText (ValueCtor c args) =
  "(" <> view (constructorName . constructorNameText) c <> " " <>
  T.intercalate " " (map valueText args) <> ")"

-- | Find a simple description that is suitable for inclusion in error messages.
describeVal :: Value -> Text
describeVal (ValueClosure _) = "function"
describeVal (ValueSyntax _) = "syntax"
describeVal (ValueMacroAction _) = "macro action"
describeVal (ValueSignal _) = "signal"
describeVal (ValueBool _) = "boolean"
describeVal (ValueCtor c _args) =
  view (constructorName . constructorNameText) c

data Closure = Closure
  { _closureEnv   :: VEnv
  , _closureIdent :: Ident
  , _closureVar   :: Var
  , _closureBody  :: Core
  }
  deriving (Eq, Show)

makePrisms ''MacroAction
makePrisms ''Value
makeLenses ''Closure
