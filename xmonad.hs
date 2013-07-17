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

import Graphics.X11.ExtraTypes.XF86

--------------------------------------------------------------------------------
-- CONFIG VARIABLES
--------------------------------------------------------------------------------
conf_modMask		= mod4Mask
conf_terminal		= "urxvt -tr -sh 10 +sb -fg white -bg black -sl 10000"
conf_focusedBorderColor	= "#00A6FF"
conf_workspaces		= ["web", "code", "mon"] ++ map show [4..9]


------------------------------------------------------------
-- KEYS
------------------------------------------------------------

keys_volinc	= ((0,xF86XK_AudioRaiseVolume),	spawn "amixer -q set Master 5%+ unmute")
keys_voldec	= ((0,xF86XK_AudioLowerVolume),	spawn "amixer -q set Master 5%- unmute")
keys_mute	= ((0,xF86XK_AudioMute),	spawn "amixer -q set Speaker toggle")

myKeys _	= M.fromList
	[ keys_volinc
	, keys_voldec
	, keys_mute
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

myLayoutHook	= smartBorders (tiled ||| Mirror tiled ||| Full)
	where
		tiled	= Tall nmaster delta ratio
		nmaster	= 1
		ratio	= 1/2
		delta	= 3/100

myConfig	= defaultConfig {
	modMask			= conf_modMask,
	terminal		= conf_terminal,
	focusedBorderColor	= conf_focusedBorderColor,
	workspaces		= conf_workspaces,
	keys			= \c -> myKeys c `M.union` keys defaultConfig c,
	manageHook		= myManageHook <+> manageHook defaultConfig,
	layoutHook		= myLayoutHook
}

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Some basic functions 
--------------------------------------------------------------------------------

keybind_toggle_dzen	:: (XConfig Layout -> (KeyMask, KeySym))
keybind_toggle_dzen _	= (mod4Mask, xK_b)

-- XMonad dzen2
--main	= xmonad =<< dzen myConfig

-- My dzen2
--main = xmonad =<< statusBar "echo 'Hello world' | dzen2 -fg grey -ta l -p 5" defaultPP keybind_toggle_dzen myConfig

-- No dzen2
--main = xmonad myConfig