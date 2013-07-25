{-# LANGUAGE NoMonomorphismRestriction #-}
import XMonad

import qualified Data.Map as M
import qualified XMonad.StackSet as W

import XMonad.ManageHook
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.DynamicLog

import XMonad.Layout
import XMonad.Layout.NoBorders
import XMonad.Layout.PerWorkspace

import XMonad.Actions.NoBorders
import XMonad.Actions.GridSelect

import XMonad.Util.Run

import Graphics.X11.ExtraTypes.XF86

import System.FilePath.Posix
import System.IO

--------------------------------------------------------------------------------
-- CONFIG VARIABLES
--------------------------------------------------------------------------------
myModMask		= mod4Mask
myTerminal		= "urxvt -tr -sh 10 +sb -fg white -bg black -sl 10000"
myFocusedBorderColor	= "#00A6FF"
myWorkspaces		= ["web", "code", "mon"] ++ map show [4..9]


------------------------------------------------------------
-- KEYS
------------------------------------------------------------

keys_volinc	= ((0,xF86XK_AudioRaiseVolume),	spawn "amixer -q set Master 5%+ unmute")
keys_voldec	= ((0,xF86XK_AudioLowerVolume),	spawn "amixer -q set Master 5%- unmute")
keys_mute	= ((0,xF86XK_AudioMute),	spawn "amixer -q set Speaker toggle")
keys_restart	= ((myModMask,xK_q),		spawn "killall conky dzen2 dzenmon.pl && xmonad --recompile && xmonad --restart")
keys_gridselect = ((myModMask,xK_g),		goToSelected $ myGSConfig myColorizer)

myKeys _	= M.fromList
	[ keys_volinc
	, keys_voldec
	, keys_mute
	, keys_restart
	, keys_gridselect
	]

------------------------------------------------------------
-- HOOKS
------------------------------------------------------------
hook_urxvt_main	= title	    =? "urxvt_main"		--> doShift "code"
hook_wicd_gtk	= className =? "Wicd-client.py"		--> doShift "mon"
hook_abraca	= className =? "Abraca"			--> doShift "mon"
hook_firefox	= className =? "Firefox"		--> doShift "web"
hook_flash	= className =? "Plugin-container"	--> (liftX $ sendMessage ToggleStruts) >> doFullFloat

myManageHook	= composeAll
	[ hook_urxvt_main
	, hook_wicd_gtk
	, hook_abraca
	, hook_flash
	]

------------------------------------------------------------
-- LAYOUT
------------------------------------------------------------

myLayoutHook	= avoidStruts( smartBorders (tiled ||| Mirror tiled ||| Full) )
	where
		tiled	= Tall nmaster delta ratio
		nmaster	= 1
		ratio	= 1/2
		delta	= 3/100

myConfig h	= defaultConfig {
	modMask			= myModMask,
	terminal		= myTerminal,
	focusedBorderColor	= myFocusedBorderColor,
	workspaces		= myWorkspaces,
	keys			= \c -> myKeys c `M.union` keys defaultConfig c,
	manageHook		= myManageHook <+> manageHook defaultConfig,
	logHook			= dynamicLogWithPP $ dzenPP { ppOutput = hPutStrLn h },
	layoutHook		= myLayoutHook
}


------------------------------------------------------------
-- GRIDSELECT
------------------------------------------------------------

myGSConfig col	= buildDefaultGSConfig col
myColorizer	= colorRangeFromClassName
			minBound
			(0x46,0x71,0xD5)
			minBound
			(0xB5,0xB5,0xB5)
			(0xFF,0xFF,0xFF)

--------------------------------------------------------------------------------
-- Some basic functions 
--------------------------------------------------------------------------------

keybind_toggle_dzen	:: (XConfig Layout -> (KeyMask, KeySym))
keybind_toggle_dzen _	= (mod4Mask, xK_b)

-- XMonad dzen2
--main	= xmonad =<< dzen myConfig 

-- My dzen2
--main = xmonad =<< statusBar "echo 'Hello world' | dzen2 -fg grey -ta l -p 5" defaultPP keybind_toggle_dzen myConfig
main = (spawnPipe "~/.xmonad/dzenmon.pl")
	>>= \h -> xmonad $ myConfig h

--main	= (spawnPipe "dzen2") >>= \h -> xmonad $ myConfig h

-- No dzen2
--main = xmonad myConfig
