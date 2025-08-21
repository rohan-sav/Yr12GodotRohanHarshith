# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.4 skiing game project named "testing". The game features:
- A skiing character that can move left/right to avoid trees
- RigidBody3D-based physics for the player
- A main menu system with play/options/quit functionality
- Web export capabilities configured for browser deployment

## Key Commands

### Running the Game
- Open the project in Godot Editor: Load `testing/project.godot`
- Run main scene: F5 or press the play button (main scene is set to Collision.tscn via uid)
- Export for web: Use the configured Web export preset in `export_presets.cfg`

### Project Structure
- Main project files are in the `testing/` directory
- `testing/project.godot` - Main Godot project configuration
- `testing/export_presets.cfg` - Web export configuration (exports to `D:/Buiklds/RohanHarshith/index.html`)

## Architecture

### Scene Structure
- **MainMenu** (`MainMenu.gd`) - Entry point with navigation to game scenes
- **Collision.tscn** - Main gameplay scene 
- **TestWorld.tscn** - Testing environment
- **Player scenes** - Multiple player implementations in `Player/` directory

### Player Movement System
- Uses RigidBody3D physics (`PlayerMovement.gd`)
- Input handling: KEY_LEFT/KEY_RIGHT for horizontal movement
- Collision detection with trees triggers scene reload
- Move speed configurable via exported variable (default: 2.0)

### Input Configuration
Custom input actions defined in project.godot:
- `KEY_LEFT` - Left arrow key movement
- `KEY_RIGHT` - Right arrow key movement

### Plugin System
Contains "path-tool" plugin for creating and exporting path data:
- Location: `path-tool/` directory
- Purpose: Custom nodes for path creation and CSV export
- Usage: Add PathPointManager and PathPoint3D nodes, connect with dock controls

## Asset Organization
- **Models/**: 3D models including skiing character and track
- **Menu/**: UI assets and menu graphics  
- **Player/**: Player-related scenes and scripts
- **path-tool/**: Plugin for path creation tools

## Development Notes
- Game uses Godot's scene system with .tscn files for levels and components
- Scripts are in GDScript (.gd files) 
- Input system uses Godot's Input singleton with custom action mappings
- Physics-based movement using RigidBody3D linear velocity manipulation