{-# LANGUAGE OverloadedStrings #-}
module App
  ( application
  , mkInitialState
  )
where

import qualified Graphics.Vty as V
import qualified Data.Vector as Vec
import Lens.Micro.Platform

import Brick
import Brick.Focus
import Brick.Widgets.Edit (editor)

import Types
import Events
import UI
import Theme
import Canvas

defaultPalette :: Vec.Vector PaletteEntry
defaultPalette = Vec.fromList
    [ PaletteEntry id id
    , PaletteEntry (`V.withForeColor` V.white   ) (`V.withBackColor` V.white)
    , PaletteEntry (`V.withForeColor` V.black   ) (`V.withBackColor` V.black)
    , PaletteEntry (`V.withForeColor` V.blue    ) (`V.withBackColor` V.blue)
    , PaletteEntry (`V.withForeColor` V.red     ) (`V.withBackColor` V.red)
    , PaletteEntry (`V.withForeColor` V.magenta ) (`V.withBackColor` V.magenta)
    , PaletteEntry (`V.withForeColor` V.green   ) (`V.withBackColor` V.green)
    , PaletteEntry (`V.withForeColor` V.cyan    ) (`V.withBackColor` V.cyan)
    , PaletteEntry (`V.withForeColor` V.yellow  ) (`V.withBackColor` V.yellow)
    ]

initialCanvasSize :: (Int, Int)
initialCanvasSize = (20, 10)

mkInitialState :: IO AppState
mkInitialState = do
    c <- newCanvas initialCanvasSize
    return $ AppState { _drawing                 = c
                      , _mode                    = Main
                      , _tool                    = FreeHand
                      , _drawCharacter           = '*'
                      , _showHud                 = True
                      , _drawFgPaletteIndex      = 0
                      , _drawBgPaletteIndex      = 0
                      , _palette                 = defaultPalette
                      , _fgPaletteSelectorExtent = Nothing
                      , _bgPaletteSelectorExtent = Nothing
                      , _toolSelectorExtent      = Nothing
                      , _dragging                = Nothing
                      , _canvasSizeWidthEdit     = editor CanvasSizeWidthEdit (Just 1) ""
                      , _canvasSizeHeightEdit    = editor CanvasSizeHeightEdit (Just 1) ""
                      , _canvasSizeFocus         = focusRing [ CanvasSizeWidthEdit
                                                             , CanvasSizeHeightEdit
                                                             ]
                      , _canvasOffset            = Location $
                                                   initialCanvasSize & each %~ (`div` 2)
                      }

application :: App AppState () Name
application =
    App { appDraw = drawUI
        , appChooseCursor = \s locs ->
            case s^.mode of
                CanvasSizePrompt -> do
                    cur <- focusGetCurrent (s^.canvasSizeFocus)
                    showCursorNamed cur locs
                _ -> Nothing
        , appHandleEvent = handleEvent
        , appStartEvent = \s -> do
            vty <- getVtyHandle
            V.setMode (V.outputIface vty) V.Mouse True
            return s
        , appAttrMap = const theme
        }
