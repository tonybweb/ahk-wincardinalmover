# WinCardinalMover
Provides window moving and resizing from anywhere within a window. Constrains to monitor edges, does NOT SUPPORT multiple monitors yet.

The center of the window is assigned to moving the window. The first 20% from the inner edge of each window is assigned to resizing based on the cardinal directions:  N, S, W, E, NE, SE, NW, and SW

<p align="center" width="100%"><img src="WinCardinalMover-demo.png" alt="GUI with Buttons" width="642"/></p>

 ## Motivation
 I grew tired of needing to be super accurate with my mouse when resizing windows. Thinner window borders and higher resolutions have exacerbated the issue.

## Demo
Try it out yourself. Run the included `demo.ahk` file for a GUI which dynamically shows the active hotkey points.

 ## Example Usage
The "forward" mouse button on your mouse will activate WinCardinalMover. Holding `Ctrl` after first holding `XButton2` will add taskbar constraining.
 ```ahk
#Requires AutoHotkey v2
#Include <ahk-wincardinalmove\WinCardinalMover>

XButton2::WinCardinalMover("XButton2", "Ctrl")
```
