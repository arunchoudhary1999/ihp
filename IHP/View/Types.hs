{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE InstanceSigs, UndecidableInstances, AllowAmbiguousTypes, ScopedTypeVariables, IncoherentInstances  #-}

module IHP.View.Types
( FormField (..)
, SubmitButton (..)
, FormContext (..)
, InputType (..)
, CSSFramework (..)
, HtmlWithContext
, Layout
)
where

import IHP.Prelude hiding (div)
import qualified Text.Blaze.Html5 as Blaze
import IHP.FlashMessages.Types


type HtmlWithContext context = (?context :: context) => Blaze.Html

-- | A layout is just a function taking a view and returning a new view.
--
-- __Example:__ A very basic html layout.
--
-- > myLayout :: Layout
-- > myLayout view = [hsx|
-- >     <html>
-- >         <body>
-- >             {view}
-- >         </body>
-- >     </html>
-- > |]
type Layout = Blaze.Html -> Blaze.Html

data FormField = FormField
    { fieldType :: !InputType
    , fieldName :: !Blaze.AttributeValue
    , fieldLabel :: !Text
    , fieldValue :: !Text
    , fieldInputId :: !Text
    , validatorResult :: !(Maybe Text)
    , fieldInput :: !(FormField -> Blaze.Html)
    , fieldClass :: !Text
    , labelClass :: !Text
    , disabled :: !Bool
    , disableLabel :: !Bool
    , disableGroup :: !Bool
    , disableValidationResult :: !Bool
    , cssFramework :: CSSFramework
    , helpText :: !Text
    , placeholder :: !Text
    , required :: Bool
    , autofocus :: Bool
    }

data SubmitButton = SubmitButton
    { label :: Blaze.Html
    , buttonClass :: Text
    , cssFramework :: CSSFramework
    }

data FormContext model = FormContext
    { model :: model -- ^ The record this form is based on
    , formAction :: !Text -- ^ Url where the form is submitted to
    , cssFramework :: !CSSFramework
    , formClass :: !Text -- ^ In the generated HTML, the @class@  attribute will be set to this value
    , formId :: !Text -- ^ In the generated HTML, the @id@ attribute will be set to this value
    , disableJavascriptSubmission :: !Bool -- ^ When set to True, the IHP helpers.js will not submit the form using ajax
    , customFormAttributes :: ![(Text, Text)] -- ^ Attach custom HTML attributes here
    }
instance SetField "model" (FormContext record) record where setField value record = record { model = value }
instance SetField "formAction" (FormContext record) Text where setField value record = record { formAction = value }
instance SetField "cssFramework" (FormContext record) CSSFramework where setField value record = record { cssFramework = value }
instance SetField "formClass" (FormContext record) Text where setField value record = record { formClass = value }
instance SetField "formId" (FormContext record) Text where setField value record = record { formId = value }
instance SetField "disableJavascriptSubmission" (FormContext record) Bool where setField value record = record { disableJavascriptSubmission = value }
instance SetField "customFormAttributes" (FormContext record) [(Text, Text)] where setField value record = record { customFormAttributes = value }

data InputType
    = TextInput
    | NumberInput
    | CheckboxInput
    | ColorInput
    | EmailInput
    | HiddenInput
    | TextareaInput
    | DateInput
    | DateTimeInput
    | PasswordInput
    | SelectInput { options :: ![(Text, Text)] }
    | FileInput


-- | Render functions to render with bootstrap etc.
--
-- We call this functions with the cssFramework passed to have late binding (like from OOP languages)
data CSSFramework = CSSFramework
    { styledFlashMessage :: CSSFramework -> FlashMessage -> Blaze.Html
    , styledFlashMessages :: CSSFramework -> [FlashMessage] -> Blaze.Html
    -- | Renders the full form field calling other functions below
    , styledFormField :: CSSFramework -> FormField -> Blaze.Html
    -- | The primary form submit button
    , styledSubmitButton :: CSSFramework -> SubmitButton -> Blaze.Html
    -- | Class for the primary form submit button
    , styledSubmitButtonClass :: Text
    -- | Renders the help text below an input field. Used with @[hsx|{(textField #firstname) { helpText = "Your first name" } }|]@
    , styledFormFieldHelp :: CSSFramework -> FormField -> Blaze.Html
    -- | First class attached to @<input/>@ elements, e.g. @<input class="form-control"/>@
    , styledInputClass :: FormField -> Text
    -- | When the form validation failed, invalid inputs will have this class
    , styledInputInvalidClass :: FormField -> Text
    -- | Class applied to the div wrapping the label and input, e.g. @"form-group"@
    , styledFormGroupClass :: Text
    -- | Elements that containers the validation error message for a invalid form field
    , styledValidationResult :: CSSFramework -> FormField -> Blaze.Html
    -- | Class name for container of validation error message
    , styledValidationResultClass :: Text
    }
