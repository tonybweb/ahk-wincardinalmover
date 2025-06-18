/************************************************************************
 * @description WinCardinalMover - provides window moving and resizing
 *   from anywhere within a window. Constrains to monitor edges, does NOT
 *   SUPPORT multiple monitors yet.
 *
 *   The center of the window is assigned to moving the window. The
 *   first 20% from the inner edge of each window is assigned to resizing
 *   based on the cardinal directions:  N, S, W, E, NE, SE, NW, and SW
 *
 * @author tonybweb
 * @link (https://github.com/tonybweb/ahk-wincardinalmover)
 * @date 2025/06/18
 * @version 1.0.1
 *
 * REMARKS
 * SetWinDelay impacts the speed of WinMove, the default value is 100ms
 * which is vethis.mouse.rY slow from a framerate persiective.
 *   WIN_DELAY of 0 is no delay but feels too fast for some windows
 *     (can produce weird artifacts on resize)
 *   Perhaps a WIN_DELAY value tuned to monitor refresh rate is best?
 *   1000 / 120hz = 8.33, 1000 / 60hz = 16.66, etc. 1 seems fine though.
 * Window offets and screen edge handling behave differently per app
 * setWindowOffsets attempts to reconcile the differences. All scenarios
 * may not be accounted for yet.
 ***********************************************************************/

class WinCardinalMover {
  static N := 1, S := 2, W := 3, E := 4,
    NE := 5, SE := 6, NW := 7, SW := 8,
    DWMWA_EXTENDED_FRAME_BOUNDS := 9,
    EDGE_MULTIPLIER := 0.20,
    TASKBAR_HEIGHT := 40,
    WIN_DELAY := 1

  static win := {},
    mouse := {},
    hk := "",
    optionKey := "Ctrl",
    on := 0

  static __New() {
    this.DEFAULT_WIN_DELAY := A_WinDelay ;Default is 100
  }

  static Call(hk, optionKey := "Ctrl") {
    CoordMode("Mouse", "Screen")
    this.hk := hk
    this.optionKey := optionKey
    if (! this.on) {
      SetWinDelay(this.WIN_DELAY)
      this.on := 1

      MouseGetPos(&x, &y, &hwnd), this.mouse.startingX := x, this.mouse.startingY := y, this.win.hwnd := hwnd
      WinGetPos(&x, &y, &w, &h, this.win.hwnd), this.win.x := x, this.win.y := y, this.win.w := w, this.win.h := h
      this.setWindowOffsets()

      WinActivate(this.win.hwnd)
      this.direction := this.findWindowCompassDirection()
      this.moveOrSizeWindow()

      this.on := 0
      SetWinDelay(this.DEFAULT_WIN_DELAY)
    }
  }

  static moveOrSizeWindow() {
    static X_INDEX := 1, Y_INDEX := 2, W_INDEX := 3, H_INDEX := 4
    moveArgs := [unset,unset,unset,unset,this.win.hwnd]

    while GetKeyState(this.hk, "P") {
      MouseGetPos(&currentX, &currentY)
      deltaX := currentX - this.mouse.startingX
      deltaY := currentY - this.mouse.startingY

      switch this.direction {
        case this.N:
          UpdateNorthConstraint()

        case this.S:
          UpdateSouthConstraint()

        case this.E:
          UpdateEastConstraint()

        case this.W:
          UpdateWestConstraint()

        case this.NE:
          UpdateNorthConstraint()
          UpdateEastConstraint()

        case this.NW:
          UpdateNorthConstraint()
          UpdateWestConstraint()

        case this.SE:
          UpdateSouthConstraint()
          UpdateEastConstraint()

        case this.SW:
          UpdateSouthConstraint()
          UpdateWestConstraint()

        default:
          maxX := A_ScreenWidth - this.win.w
          maxY := A_ScreenHeight - this.win.h - this.win.offsets.bottom
          if (GetKeyState(this.optionKey)) {
            maxY -= this.TASKBAR_HEIGHT
          }

          moveArgs[X_INDEX] := Min(Max(0, this.win.x + deltaX), maxX)
          moveArgs[Y_INDEX] := Min(Max(0, this.win.y + deltaY), maxY)
      }
      WinMove(moveArgs*)
    }

    UpdateNorthConstraint() {
      moveArgs[Y_INDEX] := Max(this.win.y + deltaY, 0)
      moveArgs[H_INDEX] := Min(this.win.h - deltaY, this.win.h + this.win.y)
    }
    UpdateSouthConstraint() {
      height := A_ScreenHeight - this.win.offsets.bottom
      allowedHeight := GetKeyState(this.optionKey) ? height - this.TASKBAR_HEIGHT : height
      moveArgs[H_INDEX] := this.win.h + Min(deltaY, allowedHeight - (this.win.h + this.win.y))
    }
    UpdateEastConstraint() {
      moveArgs[W_INDEX] := Min(this.win.w + deltaX, A_ScreenWidth - this.win.x)
    }
    UpdateWestConstraint() {
      moveArgs[X_INDEX] := Max(this.win.x + deltaX + this.win.offsets.left, this.win.offsets.left)
      moveArgs[W_INDEX] := Min(this.win.w - deltaX, this.win.x + this.win.w)
    }
  }

  static findWindowCompassDirection() {
    ; relative
    this.mouse.rX := this.mouse.startingX - this.win.x
    this.mouse.rY := this.mouse.startingY - this.win.y

    x1 := Round(this.win.w * this.EDGE_MULTIPLIER)
    x2 := Round(this.win.w * (1 - this.EDGE_MULTIPLIER))
    y1 := Round(this.win.h * this.EDGE_MULTIPLIER)
    y2 := Round(this.win.h * (1 - this.EDGE_MULTIPLIER))

    if (this.mouse.rX < x1 && this.mouse.rY < y1) {
      return this.NW
    }
    if (this.mouse.rX > x2 && this.mouse.rY < y1) {
      return this.NE
    }
    if (this.mouse.rX < x1 && this.mouse.rY > y2) {
      return this.SW
    }
    if (this.mouse.rX > x2 && this.mouse.rY > y2) {
      return this.SE
    }
    if (this.mouse.rX >= x1 && this.mouse.rX <= x2 && this.mouse.rY < y1) {
      return this.N
    }
    if (this.mouse.rX >= x1 && this.mouse.rX <= x2 && this.mouse.rY > y2) {
      return this.S
    }
    if (this.mouse.rX < x1 && this.mouse.rY >= y1 && this.mouse.rY <= y2) {
      return this.W
    }
    if (this.mouse.rX > x2 && this.mouse.rY >= y1 && this.mouse.rY <= y2) {
      return this.E
    }
    return false
  }

  static setWindowOffsets() {
    this.win.offsets := {
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
    }
    extendedRect := Buffer(16, 0)
    hResult := DllCall("dwmapi.dll\DwmGetWindowAttribute",
      "Ptr", this.win.hwnd,
      "UInt", this.DWMWA_EXTENDED_FRAME_BOUNDS,
      "Ptr", extendedRect,
      "UInt", 16)

    if (hResult != 0) {
      return
    }

    extLeft := NumGet(extendedRect, 0, "Int")
    extTop := NumGet(extendedRect, 4, "Int")
    extRight := NumGet(extendedRect, 8, "Int")
    extBottom := NumGet(extendedRect, 12, "Int")

    this.win.offsets := {
      left: this.win.x - extLeft,
      top: this.win.y - extTop,
      right: extRight - (this.win.x + this.win.w),
      bottom: extBottom - (this.win.y + this.win.h),
    }
  }
}
