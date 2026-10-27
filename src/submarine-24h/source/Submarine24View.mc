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

    // Steps gauge: small ring above the center, with a footprint icon in its gap.
    // Angles are in degrees clockwise from the top (0° = 12 o'clock); the ring runs
    // clockwise from STEPS_RING_START to STEPS_RING_END, leaving a gap for the icon.
    private const STEPS_RING_START = 335;
    private const STEPS_RING_END = 285;
    private const STEPS_RING_ANGLE = 0.0; // position on the dial, clockwise from the top
    private const STEPS_RING_DISTANCE = 0.37; // from the center, in radius units
    private const STEPS_RING_RADIUS = 0.19;
    private const STEPS_RING_WIDTH = 7;

    // Hand styles (values of the HandStyle setting; 0 = classic).
    private const HAND_STYLE_BATON = 1;
    private const HAND_STYLE_LOZENGE = 2;
    private const HAND_STYLE_DAUPHINE = 3;
    private const HAND_STYLE_SKELETON = 4;
    private const HAND_STYLE_ALPHA = 5;
    private const HAND_STYLE_BREGUET = 6;
    private const HAND_STYLE_SYRINGE = 7;
    private const HAND_STYLE_ARROW = 8;
    private const HAND_STYLE_LEAF = 9;
    private const HAND_STYLE_PENCIL = 10;

    private var _evenFont as Graphics.FontType = Graphics.FONT_TINY;
    private var _oddFont as Graphics.FontType = Graphics.FONT_XTINY;
    private var _labelFont as Graphics.FontType = Graphics.FONT_XTINY;
    private var _dateFont as Graphics.FontType = Graphics.FONT_TINY;
    // Date: weekday, then day and month, in French or English (user setting, independent of
    // the watch language); the names come from resources/strings/date.xml.
    private const DATE_Y = 0.28; // first line, below the center, in radius units

    private var _dayNames as Array<String> = [];
    private var _monthNames as Array<String> = [];
    private var _lowPower as Boolean = false;
    private var _config as Config = new Config();

    function initialize() {
        WatchFace.initialize();
        _config.load();
    }

    // Called by the application when the user changes the settings.
    function reloadSettings() as Void {
        _config.load();
        loadDateNames();
    }

    function onLayout(dc as Dc) as Void {
        _evenFont = loadFont(dc, EVEN_FONT_FACES, EVEN_FONT_SIZE_RATIO, Graphics.FONT_TINY);
        _oddFont = loadFont(dc, SMALL_FONT_FACES, ODD_FONT_SIZE_RATIO, Graphics.FONT_XTINY);
        _labelFont = loadFont(dc, SMALL_FONT_FACES, LABEL_FONT_SIZE_RATIO, Graphics.FONT_XTINY);
        _dateFont = loadFont(dc, SMALL_FONT_FACES, DATE_FONT_SIZE_RATIO, Graphics.FONT_TINY);

        loadDateNames();
    }

    private function loadDateNames() as Void {
        var days = [Rez.Strings.FrDay1, Rez.Strings.FrDay2, Rez.Strings.FrDay3, Rez.Strings.FrDay4,
                    Rez.Strings.FrDay5, Rez.Strings.FrDay6, Rez.Strings.FrDay7];
        var months = [Rez.Strings.FrMonth1, Rez.Strings.FrMonth2, Rez.Strings.FrMonth3,
                      Rez.Strings.FrMonth4, Rez.Strings.FrMonth5, Rez.Strings.FrMonth6,
                      Rez.Strings.FrMonth7, Rez.Strings.FrMonth8, Rez.Strings.FrMonth9,
                      Rez.Strings.FrMonth10, Rez.Strings.FrMonth11, Rez.Strings.FrMonth12];
        if (_config.dateLanguage == Config.LANGUAGE_ENGLISH) {
            days = [Rez.Strings.EnDay1, Rez.Strings.EnDay2, Rez.Strings.EnDay3, Rez.Strings.EnDay4,
                    Rez.Strings.EnDay5, Rez.Strings.EnDay6, Rez.Strings.EnDay7];
            months = [Rez.Strings.EnMonth1, Rez.Strings.EnMonth2, Rez.Strings.EnMonth3,
                      Rez.Strings.EnMonth4, Rez.Strings.EnMonth5, Rez.Strings.EnMonth6,
                      Rez.Strings.EnMonth7, Rez.Strings.EnMonth8, Rez.Strings.EnMonth9,
                      Rez.Strings.EnMonth10, Rez.Strings.EnMonth11, Rez.Strings.EnMonth12];
        }
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
        if (_config.showBattery) {
            drawBattery(dc, cx, cy, radius);
        }
        if (_config.showSteps) {
            drawSteps(dc, cx, cy, radius);
        }
        if (_config.showDate) {
            drawDate(dc, cx, cy, radius);
        }

        var clock = System.getClockTime();
        var hours = clock.hour + clock.min / 60.0;

        dc.setColor(_config.handsColor, Graphics.COLOR_TRANSPARENT);
        drawHand(dc, cx, cy, hourAngle(hours), radius * 0.55, radius * 0.09, radius * 0.1);
        drawHand(dc, cx, cy, (clock.min + clock.sec / 60.0) / 60.0 * 2 * Math.PI,
            radius * 0.88, radius * 0.06, radius * 0.1);

        // The seconds hand is only drawn in high-power mode (saves AMOLED power).
        if (!_lowPower && _config.showSeconds) {
            dc.setColor(_config.secondsColor, Graphics.COLOR_TRANSPARENT);
            var angle = clock.sec / 60.0 * 2 * Math.PI;
            var from = polar(cx, cy, angle + Math.PI, radius * 0.18);
            var to = polar(cx, cy, angle, radius * 0.9);
            dc.setPenWidth(2);
            dc.drawLine(from[0], from[1], to[0], to[1]);
            dc.setPenWidth(1);
            dc.fillCircle(cx, cy, radius * 0.035);
        } else {
            dc.fillCircle(cx, cy, radius * 0.035);
        }
    }

    // Angle (radians, clockwise from the top) of `hours` on the 24h dial.
    private function hourAngle(hours as Float) as Float {
        var offset = _config.midnightAtTop ? 0.0 : Math.PI;
        return offset + hours / 24.0 * 2 * Math.PI;
    }

    // Point at `angle` (clockwise from the top) and `distance` from the center.
    private function polar(cx as Number, cy as Number, angle as Float, distance as Float) as Graphics.Point2D {
        return [cx + distance * Math.sin(angle), cy - distance * Math.cos(angle)] as Graphics.Point2D;
    }

    private function drawMinuteTrack(dc as Dc, cx as Number, cy as Number, radius as Number) as Void {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        for (var m = 0; m < 60; m++) {
            var degrees = m * 6;
            if (_config.showBattery && (degrees <= RING_GAP_DEG || degrees >= 360 - RING_GAP_DEG)) {
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
            if (h % 2 == 0) {
                var at = polar(cx, cy, angle, radius * 0.7);
                dc.drawText(at[0], at[1], _evenFont, h.toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
                if (_config.showOddNumerals) {
                    var at = polar(cx, cy, angle, radius * 0.77);
                    dc.setColor(ODD_NUMERAL_COLOR, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(at[0], at[1], _oddFont, h.toString(),
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                }
                // Odd-hour mark: a thick colored tick on the minute track, bolder than the minute ticks.
                var from = polar(cx, cy, angle, radius * 0.875);
                var to = polar(cx, cy, angle, radius * 0.94);
                dc.setColor(_config.oddMarkColor, Graphics.COLOR_TRANSPARENT);
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
            var color = _config.batteryColor;
            if (level < _config.batteryRedBelow) {
                color = Graphics.COLOR_RED;
            } else if (level < _config.batteryOrangeBelow) {
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
            dc.setColor(_config.stepsColor, Graphics.COLOR_TRANSPARENT);
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
        dc.setColor(_config.stepsColor, Graphics.COLOR_TRANSPARENT);
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

    // Hand drawn in the style chosen in the settings (see HAND_STYLE_* below). The shape is
    // described in a local frame: `s` runs along the hand from the center towards the tip,
    // `p` across it (positive to the right).
    private function drawHand(dc as Dc, cx as Number, cy as Number, angle as Float,
                              length as Float, width as Float, tail as Float) as Void {
        var style = _config.handStyle;
        var color = _config.handsColor;
        var l = length;
        var t = tail;
        var w = width / 2.0;      // half width at the widest point
        var b = width * 0.3;      // half width of thin parts
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);

        if (style == HAND_STYLE_BATON) {
            fill(dc, cx, cy, angle, [[-t, -b * 1.4], [l, -b * 1.4], [l, b * 1.4], [-t, b * 1.4]]);
        } else if (style == HAND_STYLE_LOZENGE) {
            fill(dc, cx, cy, angle, [[-t, 0], [0.25 * l, -w], [l, 0], [0.25 * l, w]]);
        } else if (style == HAND_STYLE_DAUPHINE) {
            fill(dc, cx, cy, angle, [[-t, 0], [0, -w], [l, 0], [0, w]]);
            // Dark ridge along the middle gives the two-facet look.
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            var from = localPoint(cx, cy, angle, -t, 0);
            var to = localPoint(cx, cy, angle, l, 0);
            dc.drawLine(from[0], from[1], to[0], to[1]);
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        } else if (style == HAND_STYLE_SKELETON) {
            outline(dc, cx, cy, angle, [[-t, 0], [0, -w], [l, 0], [0, w]]);
        } else if (style == HAND_STYLE_ALPHA) {
            fill(dc, cx, cy, angle, [[-t, -b * 0.6], [0.55 * l, -b * 0.6], [0.7 * l, -w],
                                     [l, 0], [0.7 * l, w], [0.55 * l, b * 0.6], [-t, b * 0.6]]);
        } else if (style == HAND_STYLE_BREGUET) {
            // Thin stem with a ring ("apple") near the tip.
            var r = w * 0.9;
            var c = 0.78 * l;
            line(dc, cx, cy, angle, -t, c - r, 3);
            var at = localPoint(cx, cy, angle, c, 0);
            dc.setPenWidth(2);
            dc.drawCircle(at[0], at[1], r);
            line(dc, cx, cy, angle, c + r, l, 3);
            dc.setPenWidth(1);
        } else if (style == HAND_STYLE_SYRINGE) {
            line(dc, cx, cy, angle, -t, l, 3);
            fill(dc, cx, cy, angle, [[0.15 * l, -w], [0.55 * l, -w], [0.55 * l, w], [0.15 * l, w]]);
        } else if (style == HAND_STYLE_ARROW) {
            fill(dc, cx, cy, angle, [[-t, -b * 0.6], [0.7 * l, -b * 0.6], [0.7 * l, -w * 1.4],
                                     [l, 0], [0.7 * l, w * 1.4], [0.7 * l, b * 0.6], [-t, b * 0.6]]);
        } else if (style == HAND_STYLE_LEAF) {
            // Lens shape: half width follows a sine from the tail to the tip.
            var steps = 8;
            var left = [];
            var right = [];
            for (var i = 0; i <= steps; i++) {
                var k = i.toFloat() / steps;
                var s = -t + k * (l + t);
                var p = w * Math.sin(Math.PI * k);
                left.add([s, -p]);
                if (i > 0 && i < steps) {
                    right.add([s, p]);
                }
            }
            for (var i = right.size() - 1; i >= 0; i--) {
                left.add(right[i]);
            }
            fill(dc, cx, cy, angle, left);
        } else if (style == HAND_STYLE_PENCIL) {
            fill(dc, cx, cy, angle, [[-t, -b * 1.4], [0.82 * l, -b * 1.4], [l, 0],
                                     [0.82 * l, b * 1.4], [-t, b * 1.4]]);
        } else {
            // Classic: tapered kite with a short tail behind the center.
            fill(dc, cx, cy, angle, [[-t, 0], [0, -w], [l, 0], [0, w]]);
        }
    }

    // Point at (s, p) in the hand's local frame.
    private function localPoint(cx as Number, cy as Number, angle as Float,
                                s as Numeric, p as Numeric) as Graphics.Point2D {
        return [cx + s * Math.sin(angle) + p * Math.cos(angle),
                cy - s * Math.cos(angle) + p * Math.sin(angle)] as Graphics.Point2D;
    }

    private function toPoints(cx as Number, cy as Number, angle as Float,
                              shape as Array) as Array<Graphics.Point2D> {
        var typed = shape as Array<Array<Numeric>>;
        var points = [] as Array<Graphics.Point2D>;
        for (var i = 0; i < typed.size(); i++) {
            points.add(localPoint(cx, cy, angle, typed[i][0], typed[i][1]));
        }
        return points;
    }

    private function fill(dc as Dc, cx as Number, cy as Number, angle as Float,
                          shape as Array) as Void {
        dc.fillPolygon(toPoints(cx, cy, angle, shape));
    }

    private function outline(dc as Dc, cx as Number, cy as Number, angle as Float,
                             shape as Array) as Void {
        var points = toPoints(cx, cy, angle, shape);
        dc.setPenWidth(2);
        for (var i = 0; i < points.size(); i++) {
            var next = points[(i + 1) % points.size()];
            dc.drawLine(points[i][0], points[i][1], next[0], next[1]);
        }
        dc.setPenWidth(1);
    }

    private function line(dc as Dc, cx as Number, cy as Number, angle as Float,
                          fromS as Numeric, toS as Numeric, penWidth as Number) as Void {
        var from = localPoint(cx, cy, angle, fromS, 0);
        var to = localPoint(cx, cy, angle, toS, 0);
        dc.setPenWidth(penWidth);
        dc.drawLine(from[0], from[1], to[0], to[1]);
        dc.setPenWidth(1);
    }
}
