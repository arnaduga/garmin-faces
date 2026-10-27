import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// 24-hour dial in the style of Soviet/Russian submarine watches:
// the hour hand makes one turn per day, the dial shows 1..24.
class Submarine24View extends WatchUi.WatchFace {

    // Angle (radians, clockwise from the top) of hour 0 on the dial.
    // PI puts midnight at the bottom and noon at the top.
    private const MIDNIGHT_ANGLE = Math.PI;

    function initialize() {
        WatchFace.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var radius = cx;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        drawMinuteTrack(dc, cx, cy, radius);
        drawHourDial(dc, cx, cy, radius);
        drawDate(dc, cx, cy, radius);

        var clock = System.getClockTime();
        var hours = clock.hour + clock.min / 60.0;

        // Hour hand (24h scale) and minute hand (60 min scale).
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        drawHand(dc, cx, cy, hourAngle(hours), radius * 0.58, radius * 0.07, radius * 0.1);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        drawHand(dc, cx, cy, clock.min / 60.0 * 2 * Math.PI, radius * 0.92, radius * 0.04, radius * 0.12);

        dc.fillCircle(cx, cy, radius * 0.045);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, radius * 0.02);
    }

    private function hourAngle(hours as Float) as Float {
        return MIDNIGHT_ANGLE + hours / 24.0 * 2 * Math.PI;
    }

    // Point at `angle` (clockwise from the top) and `distance` from the center.
    private function polar(cx as Number, cy as Number, angle as Float, distance as Float) as Array<Number> {
        return [cx + distance * Math.sin(angle), cy - distance * Math.cos(angle)];
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
        for (var h = 1; h <= 24; h++) {
            var angle = hourAngle(h.toFloat());
            var at = polar(cx, cy, angle, radius * 0.77);
            // Night hours (19..05) are dimmed, like the dark half of a 24h dial.
            var isNight = (h >= 19 || h <= 5);
            dc.setColor(isNight ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(at[0], at[1], Graphics.FONT_XTINY, h.toString(),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    private function drawDate(dc as Dc, cx as Number, cy as Number, radius as Number) as Void {
        var now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var w = radius * 0.22;
        var h = radius * 0.14;
        var at = polar(cx, cy, 0.5 * Math.PI, radius * 0.38);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(at[0] - w / 2, at[1] - h / 2, w, h);
        dc.drawText(at[0], at[1], Graphics.FONT_XTINY, now.day.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Tapered hand: a kite with a short tail behind the center.
    private function drawHand(dc as Dc, cx as Number, cy as Number, angle as Float,
                              length as Float, width as Float, tail as Float) as Void {
        var tip = polar(cx, cy, angle, length);
        var left = polar(cx, cy, angle - 0.5 * Math.PI, width / 2);
        var right = polar(cx, cy, angle + 0.5 * Math.PI, width / 2);
        var back = polar(cx, cy, angle + Math.PI, tail);
        dc.fillPolygon([back, left, tip, right]);
    }
}
