import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

// 24-hour dial in the style of Russian submarine watches: the hour hand makes
// one turn per day, midnight (24) is at the top and noon (12) at the bottom.
// Even hours are large numerals, odd hours small ones.
class Submarine24View extends WatchUi.WatchFace {

    private const NUMERAL_COLOR = 0xDDDDDD;
    private const HAND_COLOR = 0xE8E8E8;
    private const SECONDS_COLOR = Graphics.COLOR_RED;

    private var _lowPower as Boolean = false;

    function initialize() {
        WatchFace.initialize();
    }

    function onEnterSleep() as Void {
        _lowPower = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _lowPower = false;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var radius = cx;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        drawMinuteTrack(dc, cx, cy, radius);
        drawHourDial(dc, cx, cy, radius);

        var clock = System.getClockTime();
        var hours = clock.hour + clock.min / 60.0;

        dc.setColor(HAND_COLOR, Graphics.COLOR_TRANSPARENT);
        drawHand(dc, cx, cy, hourAngle(hours), radius * 0.55, radius * 0.09, radius * 0.1);
        drawHand(dc, cx, cy, (clock.min + clock.sec / 60.0) / 60.0 * 2 * Math.PI,
            radius * 0.88, radius * 0.06, radius * 0.1);

        // The seconds hand is only drawn in high-power mode (saves AMOLED power).
        if (!_lowPower) {
            dc.setColor(SECONDS_COLOR, Graphics.COLOR_TRANSPARENT);
            var angle = clock.sec / 60.0 * 2 * Math.PI;
            var from = polar(cx, cy, angle + Math.PI, radius * 0.18);
            var to = polar(cx, cy, angle, radius * 0.9);
            dc.setPenWidth(2);
            dc.drawLine(from[0], from[1], to[0], to[1]);
            dc.setPenWidth(1);
            dc.fillCircle(cx, cy, radius * 0.035);
        }
    }

    // Angle (radians, clockwise from the top) of `hours` on the 24h dial.
    private function hourAngle(hours as Float) as Float {
        return hours / 24.0 * 2 * Math.PI;
    }

    // Point at `angle` (clockwise from the top) and `distance` from the center.
    private function polar(cx as Number, cy as Number, angle as Float, distance as Float) as Graphics.Point2D {
        return [cx + distance * Math.sin(angle), cy - distance * Math.cos(angle)] as Graphics.Point2D;
    }

    private function drawMinuteTrack(dc as Dc, cx as Number, cy as Number, radius as Number) as Void {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        for (var m = 0; m < 60; m++) {
            var angle = m / 60.0 * 2 * Math.PI;
            var inner = (m % 5 == 0) ? radius * 0.93 : radius * 0.96;
            var from = polar(cx, cy, angle, inner);
            var to = polar(cx, cy, angle, radius * 0.99);
            dc.setPenWidth((m % 5 == 0) ? 3 : 1);
            dc.drawLine(from[0], from[1], to[0], to[1]);
        }
        dc.setPenWidth(1);
    }

    private function drawHourDial(dc as Dc, cx as Number, cy as Number, radius as Number) as Void {
        dc.setColor(NUMERAL_COLOR, Graphics.COLOR_TRANSPARENT);
        for (var h = 1; h <= 24; h++) {
            var angle = hourAngle(h.toFloat());
            if (h == 12) {
                // Noon: hollow triangle pointing outwards instead of a numeral.
                drawTriangle(dc, cx, cy, angle, radius * 0.68, radius * 0.8, radius * 0.06, false);
            } else if (h % 2 == 0) {
                var at = polar(cx, cy, angle, radius * 0.74);
                dc.drawText(at[0], at[1], Graphics.FONT_MEDIUM, h.toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
                var at = polar(cx, cy, angle, radius * 0.58);
                dc.drawText(at[0], at[1], Graphics.FONT_XTINY, h.toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                drawTriangle(dc, cx, cy, angle, radius * 0.84, radius * 0.9, radius * 0.025, true);
            }
        }
    }

    // Triangle with its base at `baseDist` and its tip at `tipDist` from the center.
    private function drawTriangle(dc as Dc, cx as Number, cy as Number, angle as Float,
                                  baseDist as Float, tipDist as Float, halfWidth as Float,
                                  filled as Boolean) as Void {
        var base = polar(cx, cy, angle, baseDist);
        var dx = Math.cos(angle) * halfWidth;
        var dy = Math.sin(angle) * halfWidth;
        var points = [
            [base[0] - dx, base[1] - dy] as Graphics.Point2D,
            [base[0] + dx, base[1] + dy] as Graphics.Point2D,
            polar(cx, cy, angle, tipDist)
        ] as Array<Graphics.Point2D>;
        if (filled) {
            dc.fillPolygon(points);
        } else {
            dc.setPenWidth(2);
            dc.drawLine(points[0][0], points[0][1], points[1][0], points[1][1]);
            dc.drawLine(points[1][0], points[1][1], points[2][0], points[2][1]);
            dc.drawLine(points[2][0], points[2][1], points[0][0], points[0][1]);
            dc.setPenWidth(1);
        }
    }

    // Tapered hand: a kite with a short tail behind the center.
    private function drawHand(dc as Dc, cx as Number, cy as Number, angle as Float,
                              length as Float, width as Float, tail as Float) as Void {
        var tip = polar(cx, cy, angle, length);
        var left = polar(cx, cy, angle - 0.5 * Math.PI, width / 2);
        var right = polar(cx, cy, angle + 0.5 * Math.PI, width / 2);
        var back = polar(cx, cy, angle + Math.PI, tail);
        dc.fillPolygon([back, left, tip, right] as Array<Graphics.Point2D>);
    }
}
