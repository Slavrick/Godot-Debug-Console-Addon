# Godot Debug Console Plugin

This addon adds a debug console to your game, with options to resize, change the console in game. You write the scripts and the addon will parse the scripts folder and run the scripts for you. This addon is a bit rough.



# How to use

## Installation

The repository is simply a demo of the project, you can use it to test the addon before adding it to your project. download the addon from the releases page on this github repository. unzip and add the "addons" folder to your project. 

Enable the plugin within you project by opening by navigating the menus. Project -> Project Settings -> Plugins -> enable

when launching the game, you will have a debug menu.

You must set your hotkey under the input open_debug_console. otherwise the hotkey to open the console will be F3

## Usage

In game you will be able to open the debug console. you can use several built in commands that are a part of the console to modify the look or list commands.

The power of this addon is the ability to write scripts that will be ran. Each script will be called by the deploy command which should be static and require two parameters. will recieve an array of arguments that you sent it in the console and the root node (this is needed, as from a static function you cannot get the root node or anything in the scene tree, may change this in the future). You are expected to return a string which displays the status of what the command did.

The script should also have a help command which returns usage information.

in order to call the script, type a command that is the name of the script minus the file extension.

    ex: sethealth.gd you might call sethealth (hp value)



This addon is configured to only work on debug builds, and in the editor so that players shouldn't have access to the console.






