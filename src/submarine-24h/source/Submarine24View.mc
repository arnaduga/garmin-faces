import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// 24-hour dial in the style of Russian submarine watches: the hour hand makes
// one turn per day, midnight (24) is at the top and noon (12) at the bottom.
// Even hours are large numerals, odd hours small ones.
class Submarine24View extends WatchUi.WatchFace {

    private const NUMERAL_COLOR = 0xDDDDDD;
    private const ODD_NUMERAL_COLOR = 0x777777;
    private const ODD_MARK_COLOR = Graphics.COLOR_ORANGE;
    private const HAND_COLOR = 0xE8E8E8;
    private const SECONDS_COLOR = Graphics.COLOR_RED;

    // Battery ring: sits on the outer edge, with a gap at the top for the label.
    private const RING_RADIUS = 0.965;
    private const RING_WIDTH = 8;
    private const RING_GAP_DEG = 15; // the ring spans 1 h (15°) to 23 h (345°)
    // Label distance from the center: inside the ring so the text is not clipped by the screen edge.
    private const LABEL_RADIUS = 0.91;

    // Small texts use a vector font (size relative to the screen width) so they can be
    // smaller than the built-in fonts; a built-in font is the fallback.
    private const EVEN_FONT_SIZE_RATIO = 0.072;
    private const ODD_FONT_SIZE_RATIO = 0.042;
    private const LABEL_FONT_SIZE_RATIO = 0.045;
    private const DATE_FONT_SIZE_RATIO = 0.055;
    // Face names available on the vivoactive6 (see its simulator.json); the first one found is used.
    private const EVEN_FONT_FACES = ["RobotoCondensedBold", "RobotoCondensedRegular", "RobotoRegular"];
    private const SMALL_FONT_FACES = ["RobotoCondensedRegular", "RobotoRegular"];

    // Steps gauge: small ring at about 2 o'clock, with a footprint icon in its gap.
    // Angles are in degrees clockwise from the top (0° = 12 o'clock); the ring runs
    // clockwise from STEPS_RING_START to STEPS_RING_END, leaving a gap for the icon.
    private const STEPS_COLOR = 0x00AAFF;
    private const STEPS_RING_START = 335;
    private const STEPS_RING_END = 285;
    private const STEPS_RING_ANGLE = 60.0; // position on the dial, clockwise from the top
    private const STEPS_RING_DISTANCE = 0.38; // from the center, in radius units
    private const STEPS_RING_RADIUS = 0.19;
    private const STEPS_RING_WIDTH = 4;

    private var _evenFont as Graphics.FontType = Graphics.FONT_TINY;
    private var _oddFont as Graphics.FontType = Graphics.FONT_XTINY;
    private var _labelFont as Graphics.FontType = Graphics.FONT_XTINY;
    private var _dateFont as Graphics.FontType = Graphics.FONT_TINY;
    // Date: weekday, then day and month, in French whatever the watch language is
    // (the names come from resources/strings/date.xml).
    private const DATE_Y = 0.28; // first line, below the center, in radius units

    private var _dayNames as Array<String> = [];
    private var _monthNames as Array<String> = [];
    private var _lowPower as Boolean = false;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        _evenFont = loadFont(dc, EVEN_FONT_FACES, EVEN_FONT_SIZE_RATIO, Graphics.FONT_TINY);
        _oddFont = loadFont(dc, SMALL_FONT_FACES, ODD_FONT_SIZE_RATIO, Graphics.FONT_XTINY);
        _labelFont = loadFont(dc, SMALL_FONT_FACES, LABEL_FONT_SIZE_RATIO, Graphics.FONT_XTINY);
        _dateFont = loadFont(dc, SMALL_FONT_FACES, DATE_FONT_SIZE_RATIO, Graphics.FONT_TINY);

        var days = [Rez.Strings.Day1, Rez.Strings.Day2, Rez.Strings.Day3, Rez.Strings.Day4,
                    Rez.Strings.Day5, Rez.Strings.Day6, Rez.Strings.Day7];
        var months = [Rez.Strings.Month1, Rez.Strings.Month2, Rez.Strings.Month3,
                      Rez.Strings.Month4, Rez.Strings.Month5, Rez.Strings.Month6,
                      Rez.Strings.Month7, Rez.Strings.Month8, Rez.Strings.Month9,
                      Rez.Strings.Month10, Rez.Strings.Month11, Rez.Strings.Month12];
        _dayNames = [];
        for (var i = 0; i < days.size(); i++) {
            _dayNames.add(WatchUi.loadResource(days[i]) as String);
        }
        _monthNames = [];
        for (var i = 0; i < months.size(); i++) {
            _monthNames.add(WatchUi.loadResource(months[i]) as String);
        }
    }

    // Vector font of `sizeRatio` x the screen width, or `fallback` if the device cannot provide it.
    private function loadFont(dc as Dc, faces as Array<String>, sizeRatio as Float,
                              fallback as Graphics.FontType) as Graphics.FontType {
        if (!(Graphics has :getVectorFont)) {
            return fallback;
        }
        try {
            var font = Graphics.getVectorFont({
                :face => faces,
                :size => (dc.getWidth() * sizeRatio).toNumber()
            });
            return (font != null) ? font : fallback;
        } catch (ex) {
            return fallback;
        }
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
        drawBattery(dc, cx, cy, radius);
        drawSteps(dc, cx, cy, radius);
        drawDate(dc, cx, cy, radius);

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
            var degrees = m * 6;
            if (degrees <= RING_GAP_DEG || degrees >= 360 - RING_GAP_DEG) {
                continue;
            }
            var angle = m / 60.0 * 2 * Math.PI;
            var inner = (m % 5 == 0) ? radius * 0.88 : radius * 0.91;
            var from = polar(cx, cy, angle, inner);
            var to = polar(cx, cy, angle, radius * 0.935);
            dc.setPenWidth((m % 5 == 0) ? 3 : 1);
            dc.drawLine(from[0], from[1], to[0], to[1]);
        }
        dc.setPenWidth(1);
    }

    private function drawHourDial(dc as Dc, cx as Number, cy as Number, radius as Number) as Void {
        for (var h = 1; h <= 24; h++) {
            dc.setColor(NUMERAL_COLOR, Graphics.COLOR_TRANSPARENT);
            var angle = hourAngle(h.toFloat());
            if (h == 12) {
                // Noon: hollow triangle pointing outwards instead of a numeral.
                drawTriangle(dc, cx, cy, angle, radius * 0.6, radius * 0.74, radius * 0.06, false);
            } else if (h % 2 == 0) {
                var at = polar(cx, cy, angle, radius * 0.7);
                dc.drawText(at[0], at[1], _evenFont, h.toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
                var at = polar(cx, cy, angle, radius * 0.77);
                dc.setColor(ODD_NUMERAL_COLOR, Graphics.COLOR_TRANSPARENT);
                dc.drawText(at[0], at[1], _oddFont, h.toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                // Odd-hour mark: a thick colored tick on the minute track, bolder than the minute ticks.
                var from = polar(cx, cy, angle, radius * 0.875);
                var to = polar(cx, cy, angle, radius * 0.94);
                dc.setColor(ODD_MARK_COLOR, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(4);
                dc.drawLine(from[0], from[1], to[0], to[1]);
                dc.setPenWidth(1);
            }
        }
    }

    private function drawBattery(dc as Dc, cx as Number, cy as Number, radius as Number) as Void {
        var level = System.getSystemStats().battery;
        var ringRadius = radius * RING_RADIUS;
        // The rounded caps stick out by half the ring width: inset the arc by that angle
        // so the bar visually spans exactly from the 1 h to the 23 h position.
        var capDeg = (RING_WIDTH / 2.0) / ringRadius * 180.0 / Math.PI;
        var from = RING_GAP_DEG + capDeg; // degrees clockwise from the top
        var span = (360 - 2 * from) * level / 100.0;
        // Dc.drawArc angles: 0° is 3 o'clock and they grow counter-clockwise.
        var arcStart = (90 - from + 0.5).toNumber();
        var arcEnd = (90 + from + 0.5).toNumber();

        dc.setPenWidth(RING_WIDTH);
        dc.setColor(0x303030, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, ringRadius, Graphics.ARC_CLOCKWISE, arcStart, arcEnd);
        drawRoundCap(dc, cx, cy, ringRadius, from);
        drawRoundCap(dc, cx, cy, ringRadius, 360 - from);
        if (span >= 1) {
            var color = Graphics.COLOR_GREEN;
            if (level < 15) {
                color = Graphics.COLOR_RED;
            } else if (level < 30) {
                color = Graphics.COLOR_ORANGE;
            }
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cx, cy, ringRadius, Graphics.ARC_CLOCKWISE, arcStart,
                (arcStart - span + 360 + 0.5).toNumber() % 360);
            drawRoundCap(dc, cx, cy, ringRadius, from);
            drawRoundCap(dc, cx, cy, ringRadius, from + span);
        }
        dc.setPenWidth(1);

        // Label in the ring gap: lightning bolt + percentage.
        var text = level.format("%d") + "%";
        var boltWidth = 10;
        var spacing = 4;
        var textWidth = dc.getTextWidthInPixels(text, _labelFont);
        var left = cx - (boltWidth + spacing + textWidth) / 2;
        var labelY = (cy - radius * LABEL_RADIUS).toNumber();

        drawBolt(dc, left + boltWidth / 2, labelY);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(left + boltWidth + spacing, labelY, _labelFont, text,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawSteps(dc as Dc, cx as Number, cy as Number, radius as Number) as Void {
        var info = ActivityMonitor.getInfo();
        var steps = (info.steps != null) ? info.steps : 0;
        var goal = (info.stepGoal != null) ? info.stepGoal : 0;
        var ratio = (goal > 0) ? steps.toFloat() / goal : 0.0;
        if (ratio > 1.0) {
            ratio = 1.0;
        }

        var center = polar(cx, cy, STEPS_RING_ANGLE * Math.PI / 180.0, radius * STEPS_RING_DISTANCE);
        var x = center[0].toNumber();
        var y = center[1].toNumber();
        var ringRadius = (radius * STEPS_RING_RADIUS).toNumber();
        var sweep = ((STEPS_RING_END - STEPS_RING_START + 360) % 360) * ratio;
        // Dc.drawArc angles: 0° is 3 o'clock and they grow counter-clockwise.
        var arcStart = (90 - STEPS_RING_START + 360) % 360;
        var arcEnd = (90 - STEPS_RING_END + 360) % 360;

        dc.setPenWidth(STEPS_RING_WIDTH);
        dc.setColor(0x303030, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(x, y, ringRadius, Graphics.ARC_CLOCKWISE, arcStart, arcEnd);
        if (sweep >= 1) {
            dc.setColor(STEPS_COLOR, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(x, y, ringRadius, Graphics.ARC_CLOCKWISE, arcStart,
                (arcStart - sweep + 360).toNumber() % 360);
        }
        dc.setPenWidth(1);

        // Step count in the middle of the ring.
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, _oddFont, steps.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Footprints in the gap of the ring, halfway between its two ends.
        var gapAngle = (STEPS_RING_START + STEPS_RING_END) / 2.0 * Math.PI / 180.0;
        dc.setColor(STEPS_COLOR, Graphics.COLOR_TRANSPARENT);
        drawFootprint(dc, x + (ringRadius * Math.sin(gapAngle)).toNumber(),
            y - (ringRadius * Math.cos(gapAngle)).toNumber());
    }

    // Two small shoe prints, centered on (x, y).
    private function drawFootprint(dc as Dc, x as Number, y as Number) as Void {
        dc.fillEllipse(x - 3, y - 1, 2, 3);
        dc.fillEllipse(x - 3, y + 4, 1, 1);
        dc.fillEllipse(x + 3, y - 5, 2, 3);
        dc.fillEllipse(x + 3, y, 1, 1);
    }

    // Disk closing the end of a thick arc, at `degrees` clockwise from the top.
    private function drawRoundCap(dc as Dc, cx as Number, cy as Number, ringRadius as Float,
                                  degrees as Float) as Void {
        var at = polar(cx, cy, degrees * Math.PI / 180.0, ringRadius);
        dc.fillCircle(at[0], at[1], RING_WIDTH / 2);
    }

    // Two lines under the center: weekday, then day and month (no year).
    private function drawDate(dc as Dc, cx as Number, cy as Number, radius as Number) as Void {
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var weekday = _dayNames[now.day_of_week - 1];
        var dayAndMonth = now.day.toString() + " " + _monthNames[now.month - 1];
        var y = (cy + radius * DATE_Y).toNumber();

        dc.setColor(NUMERAL_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, _dateFont, weekday,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, y + dc.getFontHeight(_dateFont), _dateFont, dayAndMonth,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Small lightning bolt centered on (x, y).
    private function drawBolt(dc as Dc, x as Number, y as Number) as Void {
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [x + 2, y - 8] as Graphics.Point2D,
            [x - 5, y + 1] as Graphics.Point2D,
            [x - 1, y + 1] as Graphics.Point2D,
            [x - 3, y + 8] as Graphics.Point2D,
            [x + 5, y - 2] as Graphics.Point2D,
            [x + 1, y - 2] as Graphics.Point2D
        ] as Array<Graphics.Point2D>);
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
