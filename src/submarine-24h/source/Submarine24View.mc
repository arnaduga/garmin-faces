import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;
import Toybox.WatchUi;

// 24-hour dial in the style of Russian submarine watches: the hour hand makes
// one turn per day, midnight (24) is at the top and noon (12) at the bottom.
// Even hours are large numerals, odd hours small ones.
class Submarine24View extends WatchUi.WatchFace {

    private const NUMERAL_COLOR = 0xDDDDDD;
    private const ODD_NUMERAL_COLOR = 0x777777;
    private const GAUGE_TEXT_COLOR = 0xBBBBBB;

    // Small texts use a vector font (size relative to the screen width) so they can be
    // smaller than the built-in fonts; a built-in font is the fallback.
    private const EVEN_FONT_SIZE_RATIO = 0.080;
    private const ODD_FONT_SIZE_RATIO = 0.047;
    private const DATE_FONT_SIZE_RATIO = 0.075;
    private const GAUGE_FONT_SIZE_RATIO = 0.062;
    // Face names available on the vivoactive6 (see its simulator.json); the first one found is used.
    private const EVEN_FONT_FACES = ["RobotoCondensedBold", "RobotoCondensedRegular", "RobotoRegular"];
    private const SMALL_FONT_FACES = ["RobotoCondensedRegular", "RobotoRegular"];

    // Gauges (steps, battery): small rings with a gap holding an icon, the value in the middle.
    // Angles are in degrees clockwise from the top (0° = 12 o'clock); a ring runs clockwise
    // from GAUGE_START to GAUGE_END, leaving a gap for the icon. Radii are in units of the dial radius.
    private const GAUGE_START = 335;
    private const GAUGE_END = 285;
    private const GAUGE_RADIUS = 0.19;
    private const GAUGE_WIDTH = 7;
    // Gauge slots: 0 = top, 1 = right (hour 5 of the 24h dial), 2 = left (the mirror position of the right one).
    // Each slot shows the gauge picked in the settings (see Config.GAUGE_*).
    private const SLOT_ANGLE = [0.0, 75.0, 285.0];       // degrees clockwise from the top
    private const SLOT_DISTANCE = [0.37, 0.44, 0.44];    // in units of the dial radius
    private const ICON_STEPS = 0;
    private const ICON_BATTERY = 1;
    private const ICON_HEART = 2;
    private const ICON_STRESS = 3;
    private const ICON_ACTIVE = 4;
    // Pictograms are drawn on a grid of about 16 px; this scales them up.
    private const ICON_SCALE = 1.25;

    // Day/night ring: the outermost ring, from sunrise to sunset on the 24 h scale.
    private const DAY_NIGHT_WIDTH = 6;
    private const SUN_RETRY_SECONDS = 60; // retry this often while the location is unknown

    // Hand styles (values of the HandStyle setting; 0 = classic).
    private const HAND_STYLE_BATON = 1;
    private const HAND_STYLE_LOZENGE = 2;
    private const HAND_STYLE_DAUPHINE = 3;
    private const HAND_STYLE_SKELETON = 4;
    private const HAND_STYLE_ALPHA = 5;
    private const HAND_STYLE_BREGUET = 6;
    private const HAND_STYLE_ARROW = 7;
    private const HAND_STYLE_LEAF = 8;
    private const HAND_STYLE_PENCIL = 9;
    private const HAND_STYLE_GHOST = 10;
    private const HAND_STYLE_GLASS = 11;
    private const HAND_STYLE_NEON = 12;
    private const HAND_STYLE_TWO_TONE = 13;
    private const HAND_STYLE_SWORD = 14;
    private const HAND_STYLE_MERCEDES = 15;
    private const HAND_STYLE_PEARLS = 16;
    private const HAND_STYLE_COMET = 17;
    private const HAND_STYLE_BUBBLE = 18;

    // Pixel sizes (pen widths, pictograms) were tuned for a screen this wide and are scaled
    // proportionally on other devices.
    private const REFERENCE_WIDTH = 390.0;
    private var _scale as Float = 1.0;

    private var _evenFont as Graphics.FontType = Graphics.FONT_TINY;
    private var _oddFont as Graphics.FontType = Graphics.FONT_XTINY;
    private var _dateFont as Graphics.FontType = Graphics.FONT_TINY;
    private var _gaugeFont as Graphics.FontType = Graphics.FONT_XTINY;
    // Date: weekday, then day and month, in French or English (user setting, independent of
    // the watch language); the names come from resources/strings/date.xml.
    private const DATE_Y = 0.28; // first line, below the center, in radius units

    private var _dayNames as Array<String> = [];
    private var _monthNames as Array<String> = [];
    private var _lowPower as Boolean = false;
    private var _config as Config = new Config();

    // Sunrise and sunset as hours of the day (null when unknown), refreshed once a day.
    private var _sunrise as Float or Null = null;
    private var _sunset as Float or Null = null;
    // True while the times are the 06:00-18:00 placeholder, so a position is looked up again.
    private var _sunGuessed as Boolean = false;
    private var _sunDay as Number = -1;
    private var _sunChecked as Number = 0;

    // Today's heart rate range, refreshed when the minute changes.
    private var _heartRange as Array<Number or Null> = [null, null];
    private var _heartRangeMinute as Number = -1;

    function initialize() {
        WatchFace.initialize();
        _config.load();
    }

    // Called by the application when the user changes the settings.
    function reloadSettings() as Void {
        _config.load();
        loadDateNames();
        _sunDay = -1; // recompute the sun times on the next update
    }

    function onLayout(dc as Dc) as Void {
        _scale = dc.getWidth() / REFERENCE_WIDTH;
        _evenFont = loadFont(dc, EVEN_FONT_FACES, EVEN_FONT_SIZE_RATIO, false);
        _oddFont = loadFont(dc, SMALL_FONT_FACES, ODD_FONT_SIZE_RATIO, false);
        _dateFont = loadFont(dc, SMALL_FONT_FACES, DATE_FONT_SIZE_RATIO, false);
        _gaugeFont = loadFont(dc, SMALL_FONT_FACES, GAUGE_FONT_SIZE_RATIO, true);

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

    // A size in pixels tuned for REFERENCE_WIDTH, scaled to this screen (at least 1).
    private function px(size as Number) as Number {
        var scaled = Math.round(size * _scale).toNumber();
        return (scaled < 1) ? 1 : scaled;
    }

    // Vector font of `sizeRatio` x the screen width. Devices without vector fonts (their
    // simulator.json lists no `system_ttf` fonts, e.g. the vivoactive5) get the built-in
    // font whose height is closest to it without exceeding it.
    // `smallest`: the built-in fallback is always the smallest one (for texts that must fit a ring).
    private function loadFont(dc as Dc, faces as Array<String>, sizeRatio as Float,
                              smallest as Boolean) as Graphics.FontType {
        var size = (dc.getWidth() * sizeRatio).toNumber();
        if (!(Graphics has :getVectorFont)) {
            return smallest ? Graphics.FONT_XTINY : builtInFont(dc, size);
        }
        try {
            var font = Graphics.getVectorFont({:face => faces, :size => size});
            if (font != null) {
                return font;
            }
        } catch (ex) {
            // Fall through to a built-in font.
        }
        return smallest ? Graphics.FONT_XTINY : builtInFont(dc, size);
    }

    // Largest built-in font whose line height fits `size` (a vector font size, whose line is
    // about 1.2 x taller); the smallest one when none fits.
    private function builtInFont(dc as Dc, size as Number) as Graphics.FontType {
        var candidates = [Graphics.FONT_XTINY, Graphics.FONT_TINY, Graphics.FONT_SMALL,
                          Graphics.FONT_MEDIUM];
        var best = candidates[0];
        for (var i = 1; i < candidates.size(); i++) {
            try {
                if (dc.getFontHeight(candidates[i]) <= size * 1.2) {
                    best = candidates[i];
                }
            } catch (ex) {
                // This size does not exist on the device (e.g. instinct3amoled45mm has no FONT_MEDIUM).
                break;
            }
        }
        return best;
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

        // Low-power mode (AMOLED always-on): only the essentials stay lit, to limit burn-in.
        if (!_lowPower && _config.showDayNight) {
            updateSunTimes();
            drawDayNight(dc, cx, cy, cx);
        }

        drawMinuteTrack(dc, cx, cy, radius);
        drawHourDial(dc, cx, cy, radius);
        if (!_lowPower) {
            for (var slot = 0; slot < _config.gauges.size(); slot++) {
                drawSlot(dc, cx, cy, radius, slot, _config.gauges[slot]);
            }
            if (_config.showDate) {
                drawDate(dc, cx, cy, radius);
            }
        }

        var clock = System.getClockTime();
        var hours = clock.hour + clock.min / 60.0;

        dc.setColor(_config.handsColor, Graphics.COLOR_TRANSPARENT);
        drawHand(dc, cx, cy, hourAngle(hours), radius * 0.55, radius * 0.09, radius * 0.1,
            clock.hour.toString());
        drawHand(dc, cx, cy, (clock.min + clock.sec / 60.0) / 60.0 * 2 * Math.PI,
            radius * 0.88, radius * 0.06, radius * 0.1, clock.min.format("%02d"));

        // The skeleton hands get a smaller hub so the open outlines stay readable.
        var hubRadius = (_config.handStyle == HAND_STYLE_SKELETON) ? radius * 0.02 : radius * 0.035;

        // The seconds hand is only drawn in high-power mode (saves AMOLED power).
        if (!_lowPower && _config.showSeconds) {
            dc.setColor(_config.secondsColor, Graphics.COLOR_TRANSPARENT);
            var angle = clock.sec / 60.0 * 2 * Math.PI;
            var from = polar(cx, cy, angle + Math.PI, radius * 0.18);
            var to = polar(cx, cy, angle, radius * 0.9);
            dc.setPenWidth(px(2));
            dc.drawLine(from[0], from[1], to[0], to[1]);
            dc.setPenWidth(1);
            dc.fillCircle(cx, cy, hubRadius);
        } else {
            dc.fillCircle(cx, cy, hubRadius);
        }
    }

    // Recomputes the sunrise/sunset once a day, or periodically while no location is known.
    private function updateSunTimes() as Void {
        var now = Time.now().value();
        var today = Time.today().value();
        if (today == _sunDay && (!_sunGuessed || now - _sunChecked < SUN_RETRY_SECONDS)) {
            return;
        }
        _sunDay = today;
        _sunChecked = now;
        _sunrise = null;
        _sunset = null;
        _sunGuessed = false;
        if (!(Toybox has :Weather)) {
            return;
        }
        var location = currentLocation();
        if (location != null) {
            try {
                var rise = Weather.getSunrise(location, Time.now());
                var set = Weather.getSunset(location, Time.now());
                if (rise != null && set != null) {
                    _sunrise = hourOfDay(rise);
                    _sunset = hourOfDay(set);
                    return;
                }
            } catch (ex) {
                // Fall through to the local computation.
            }
            computeSunTimes(location);
        }
        if (_sunrise == null) {
            // No position at all: show a typical day so both colors stay visible.
            _sunrise = 6.0;
            _sunset = 18.0;
            _sunGuessed = true;
        }
    }

    // Sunrise/sunset (local hours) from latitude/longitude, used when Weather has no data.
    private function computeSunTimes(location as Position.Location) as Void {
        try {
            var degrees = location.toDegrees();
            var lat = (degrees[0] * Math.PI / 180.0).toFloat();
            var day = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
            var jan1 = Gregorian.moment({:year => day.year, :month => 1, :day => 1, :hour => 12});
            var dayOfYear = ((Time.now().value() - jan1.value()) / 86400).toNumber() + 1;
            var declination = 0.409 * Math.sin(2 * Math.PI * (dayOfYear + 284) / 365.0);
            // Sun's upper edge at the horizon, refraction included (-0.833 degrees).
            var cosH = (-0.01454 - Math.sin(lat) * Math.sin(declination))
                / (Math.cos(lat) * Math.cos(declination));
            if (cosH > 1.0) {
                cosH = 1.0;
            } else if (cosH < -1.0) {
                cosH = -1.0;
            }
            var halfDay = (Math.acos(cosH) * 12.0 / Math.PI).toFloat();
            // Equation of time, in minutes.
            var b = 2 * Math.PI * (dayOfYear - 81) / 364.0;
            var eot = 9.87 * Math.sin(2 * b) - 7.53 * Math.cos(b) - 1.5 * Math.sin(b);
            var clock = System.getClockTime();
            var offset = (clock.timeZoneOffset + clock.dst) / 3600.0;
            var solarNoon = (12.0 - degrees[1] / 15.0 + offset - eot / 60.0).toFloat();
            _sunrise = wrapHours(solarNoon - halfDay);
            _sunset = wrapHours(solarNoon + halfDay);
        } catch (ex) {
            _sunrise = null;
            _sunset = null;
        }
    }

    private function wrapHours(hours as Float) as Float {
        while (hours < 0.0) {
            hours += 24.0;
        }
        while (hours >= 24.0) {
            hours -= 24.0;
        }
        return hours;
    }

    // Last known position, remembered in storage for when there is no fix.
    private function currentLocation() as Position.Location or Null {
        try {
            var info = Position.getInfo();
            if (info != null && info.position != null
                && info.accuracy != Position.QUALITY_NOT_AVAILABLE) {
                var degrees = info.position.toDegrees();
                Application.Storage.setValue("latitude", degrees[0]);
                Application.Storage.setValue("longitude", degrees[1]);
                return info.position;
            }
            var latitude = Application.Storage.getValue("latitude");
            var longitude = Application.Storage.getValue("longitude");
            if (latitude != null && longitude != null) {
                return new Position.Location({
                    :latitude => latitude,
                    :longitude => longitude,
                    :format => :degrees
                });
            }
        } catch (ex) {
            // No position available.
        }
        return null;
    }

    private function hourOfDay(moment as Time.Moment) as Float {
        var info = Gregorian.info(moment, Time.FORMAT_SHORT);
        return info.hour + info.min / 60.0;
    }

    // Outermost ring: night color all around, day color from sunrise to sunset.
    private function drawDayNight(dc as Dc, cx as Number, cy as Number, edge as Number) as Void {
        var width = px(DAY_NIGHT_WIDTH);
        var ringRadius = edge - width / 2;
        dc.setPenWidth(width);
        dc.setColor(_config.nightColor, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, ringRadius);
        if (_sunrise != null && _sunset != null) {
            dc.setColor(_config.dayColor, Graphics.COLOR_TRANSPARENT);
            var from = arcDegrees(_sunrise);
            var to = arcDegrees(_sunset);
            dc.drawArc(cx, cy, ringRadius, Graphics.ARC_CLOCKWISE, from, to);
            // Caps use the same whole degrees as the arc so they sit exactly on its ends.
            drawRoundCap(dc, cx, cy, ringRadius, 90 - from, width);
            drawRoundCap(dc, cx, cy, ringRadius, 90 - to, width);
        }
        dc.setPenWidth(1);
    }

    // Dc.drawArc angle (0° at 3 o'clock, counter-clockwise) of an hour on the 24h dial.
    private function arcDegrees(hours as Float) as Number {
        var compass = hourAngle(hours) * 180.0 / Math.PI;
        var degrees = Math.round(90 - compass).toNumber() % 360;
        return (degrees + 360) % 360;
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
            var angle = m / 60.0 * 2 * Math.PI;
            var inner = (m % 5 == 0) ? radius * 0.88 : radius * 0.91;
            var from = polar(cx, cy, angle, inner);
            var to = polar(cx, cy, angle, radius * 0.935);
            if (_lowPower && m % 5 != 0) {
                continue;
            }
            dc.setPenWidth((m % 5 == 0) ? px(3) : 1);
            dc.drawLine(from[0], from[1], to[0], to[1]);
        }
        dc.setPenWidth(1);
    }

    private function drawHourDial(dc as Dc, cx as Number, cy as Number, radius as Number) as Void {
        for (var h = 1; h <= 24; h++) {
            dc.setColor(NUMERAL_COLOR, Graphics.COLOR_TRANSPARENT);
            var angle = hourAngle(h.toFloat());
            if (h % 2 == 0) {
                var at = polar(cx, cy, angle, radius * 0.74);
                dc.drawText(at[0], at[1], _evenFont, h.toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else if (!_lowPower) {
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
                dc.setPenWidth(px(4));
                dc.drawLine(from[0], from[1], to[0], to[1]);
                dc.setPenWidth(1);
            }
        }
    }

    // Draws `gauge` (a Config.GAUGE_* value) in `slot`; nothing for Config.GAUGE_NONE.
    private function drawSlot(dc as Dc, cx as Number, cy as Number, radius as Number,
                              slot as Number, gauge as Number) as Void {
        if (gauge == Config.GAUGE_BATTERY) {
            drawBattery(dc, cx, cy, radius, slot);
        } else if (gauge == Config.GAUGE_STEPS) {
            drawSteps(dc, cx, cy, radius, slot);
        } else if (gauge == Config.GAUGE_HEART) {
            drawHeartRate(dc, cx, cy, radius, slot);
        } else if (gauge == Config.GAUGE_STRESS) {
            drawStress(dc, cx, cy, radius, slot);
        } else if (gauge == Config.GAUGE_ACTIVE) {
            drawActiveMinutes(dc, cx, cy, radius, slot);
        }
    }

    private function drawBattery(dc as Dc, cx as Number, cy as Number, radius as Number,
                                 slot as Number) as Void {
        var level = System.getSystemStats().battery;
        var color = _config.batteryColor;
        if (level < _config.batteryRedBelow) {
            color = Graphics.COLOR_RED;
        } else if (level < _config.batteryOrangeBelow) {
            color = Graphics.COLOR_ORANGE;
        }
        drawGauge(dc, cx, cy, radius, slot, level / 100.0, color,
            level.format("%d") + "%", ICON_BATTERY);
    }

    // Heart rate (bpm) gauge: the ring spans today's lowest (0%) to highest (100%) bpm and
    // the current bpm fills it accordingly.
    private function drawHeartRate(dc as Dc, cx as Number, cy as Number, radius as Number,
                                   slot as Number) as Void {
        var bpm = currentHeartRate();
        var text = (bpm != null) ? bpm.toString() : "--";
        var ratio = 0.0;
        if (bpm != null) {
            var range = todayHeartRateRange();
            var low = (range[0] != null && range[0] < bpm) ? range[0] : bpm;
            var high = (range[1] != null && range[1] > bpm) ? range[1] : bpm;
            if (high > low) {
                ratio = (bpm - low).toFloat() / (high - low);
            }
        }
        drawGauge(dc, cx, cy, radius, slot, ratio, _config.heartColor,
            text, ICON_HEART);
    }

    // [min, max] bpm recorded since midnight; an entry is null when unknown.
    // Cached per minute: the history query is the costly part and the range rarely changes.
    private function todayHeartRateRange() as Array<Number or Null> {
        var clock = System.getClockTime();
        var minuteOfDay = clock.hour * 60 + clock.min;
        if (minuteOfDay != _heartRangeMinute) {
            _heartRange = queryHeartRateRange();
            _heartRangeMinute = minuteOfDay;
        }
        return _heartRange;
    }

    private function queryHeartRateRange() as Array<Number or Null> {
        var low = null;
        var high = null;
        try {
            var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
            var sinceMidnight = now.hour * 3600 + now.min * 60 + now.sec;
            var iterator = ActivityMonitor.getHeartRateHistory(new Time.Duration(sinceMidnight + 1), false);
            var min = iterator.getMin();
            var max = iterator.getMax();
            if (min != ActivityMonitor.INVALID_HR_SAMPLE) {
                low = min;
            }
            if (max != ActivityMonitor.INVALID_HR_SAMPLE) {
                high = max;
            }
        } catch (ex) {
            // No heart rate history available.
        }
        return [low, high];
    }

    private function currentHeartRate() as Number or Null {
        try {
            var info = Activity.getActivityInfo();
            if (info != null && info.currentHeartRate != null) {
                return info.currentHeartRate;
            }
            var sample = ActivityMonitor.getHeartRateHistory(1, true).next();
            if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                return sample.heartRate;
            }
        } catch (ex) {
            // No heart rate available.
        }
        return null;
    }

    private function drawSteps(dc as Dc, cx as Number, cy as Number, radius as Number,
                               slot as Number) as Void {
        var info = ActivityMonitor.getInfo();
        var steps = (info.steps != null) ? info.steps : 0;
        var goal = (info.stepGoal != null) ? info.stepGoal : 0;
        var ratio = (goal > 0) ? steps.toFloat() / goal : 0.0;
        drawGauge(dc, cx, cy, radius, slot, ratio, _config.stepsColor,
            steps.toString(), ICON_STEPS);
    }

    // Stress score (0..100, from the last measurement); `--` and an empty ring when unknown.
    private function drawStress(dc as Dc, cx as Number, cy as Number, radius as Number,
                                slot as Number) as Void {
        var score = null;
        try {
            score = ActivityMonitor.getInfo().stressScore;
        } catch (ex) {
            // No stress data on this device.
        }
        var ratio = (score != null) ? score / 100.0 : 0.0;
        drawGauge(dc, cx, cy, radius, slot, ratio, _config.stressColor,
            (score != null) ? score.toString() : "--", ICON_STRESS);
    }

    // Active minutes of the current week against the weekly goal.
    private function drawActiveMinutes(dc as Dc, cx as Number, cy as Number, radius as Number,
                                       slot as Number) as Void {
        var minutes = 0;
        var goal = 0;
        try {
            var info = ActivityMonitor.getInfo();
            if (info.activeMinutesWeek != null) {
                minutes = info.activeMinutesWeek.total;
            }
            if (info.activeMinutesWeekGoal != null) {
                goal = info.activeMinutesWeekGoal;
            }
        } catch (ex) {
            // No active minutes on this device.
        }
        var ratio = (goal > 0) ? minutes.toFloat() / goal : 0.0;
        drawGauge(dc, cx, cy, radius, slot, ratio, _config.activeColor,
            minutes.toString(), ICON_ACTIVE);
    }

    // Small ring placed in `slot` (see SLOT_*); every gauge has the same shape:
    // dark track, `ratio` (0..1) of it filled with `color`, `text` in the middle, icon in the gap.
    private function drawGauge(dc as Dc, cx as Number, cy as Number, radius as Number,
                               slot as Number, ratio as Float,
                               color as Number, text as String, icon as Number) as Void {
        if (ratio > 1.0) {
            ratio = 1.0;
        }
        var center = polar(cx, cy, SLOT_ANGLE[slot] * Math.PI / 180.0, radius * SLOT_DISTANCE[slot]);
        var x = center[0].toNumber();
        var y = center[1].toNumber();
        var ringRadius = (radius * GAUGE_RADIUS).toNumber();
        var startDeg = GAUGE_START;
        var endDeg = GAUGE_END;
        var sweep = ((endDeg - startDeg + 360) % 360) * ratio;
        // Dc.drawArc angles: 0° is 3 o'clock and they grow counter-clockwise.
        var arcStart = (90 - startDeg + 360) % 360;
        var arcEnd = (90 - endDeg + 360) % 360;

        var gaugeWidth = px(GAUGE_WIDTH);
        dc.setPenWidth(gaugeWidth);
        dc.setColor(0x303030, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(x, y, ringRadius, Graphics.ARC_CLOCKWISE, arcStart, arcEnd);
        drawRoundCap(dc, x, y, ringRadius, startDeg, gaugeWidth);
        drawRoundCap(dc, x, y, ringRadius, endDeg, gaugeWidth);
        if (sweep >= 1) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(x, y, ringRadius, Graphics.ARC_CLOCKWISE, arcStart,
                (arcStart - sweep + 360).toNumber() % 360);
            drawRoundCap(dc, x, y, ringRadius, startDeg, gaugeWidth);
            drawRoundCap(dc, x, y, ringRadius, startDeg + sweep, gaugeWidth);
        }
        dc.setPenWidth(1);

        dc.setColor(GAUGE_TEXT_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, _gaugeFont, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Icon in the gap of the ring, halfway between its two ends.
        var gapAngle = (startDeg + endDeg) / 2.0 * Math.PI / 180.0;
        var iconX = x + (ringRadius * Math.sin(gapAngle)).toNumber();
        var iconY = y - (ringRadius * Math.cos(gapAngle)).toNumber();
        if (icon == ICON_STEPS) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            drawWalker(dc, iconX, iconY);
        } else if (icon == ICON_HEART) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            drawHeart(dc, iconX, iconY);
        } else if (icon == ICON_STRESS) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            drawStressWave(dc, iconX, iconY);
        } else if (icon == ICON_ACTIVE) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            drawStopwatch(dc, iconX, iconY);
        } else {
            drawBolt(dc, iconX, iconY);
        }
    }

    // Half-disc end of a thick arc: a filled circle at `compassDeg` (clockwise from the top).
    private function drawRoundCap(dc as Dc, x as Number, y as Number, ringRadius as Number,
                                  compassDeg as Float or Number, width as Number) as Void {
        var angle = compassDeg * Math.PI / 180.0;
        dc.fillCircle(x + (ringRadius * Math.sin(angle)).toNumber(),
            y - (ringRadius * Math.cos(angle)).toNumber(), width / 2);
    }

    // Walking pictogram (head, torso, arms, legs), centered on (x, y).
    private function drawWalker(dc as Dc, x as Number, y as Number) as Void {
        dc.fillCircle(x + icon(1), y - icon(6), icon(2));
        dc.setPenWidth(icon(2));
        dc.drawLine(x + icon(1), y - icon(3), x - icon(1), y + icon(2));   // torso
        dc.drawLine(x - icon(1), y + icon(2), x + icon(3), y + icon(6));   // front leg
        dc.drawLine(x - icon(1), y + icon(2), x - icon(3), y + icon(6));   // back leg
        dc.drawLine(x, y - icon(2), x + icon(3), y);                       // front arm
        dc.drawLine(x, y - icon(2), x - icon(3), y - icon(1));             // back arm
        dc.setPenWidth(1);
    }

    // Heart made of two discs and a triangle, centered on (x, y).
    private function drawHeart(dc as Dc, x as Number, y as Number) as Void {
        dc.fillCircle(x - icon(2), y - icon(2), icon(3));
        dc.fillCircle(x + icon(2), y - icon(2), icon(3));
        dc.fillPolygon([[x - icon(5), y - icon(1)], [x + icon(5), y - icon(1)],
                        [x, y + icon(5)]] as Array<Graphics.Point2D>);
    }

    // Zigzag line (a tense signal), centered on (x, y).
    private function drawStressWave(dc as Dc, x as Number, y as Number) as Void {
        var xs = [-6, -3, 0, 3, 6];
        var ys = [2, -5, 4, -5, 2];
        dc.setPenWidth(icon(2));
        for (var i = 0; i < xs.size() - 1; i++) {
            dc.drawLine(x + icon(xs[i]), y + icon(ys[i]), x + icon(xs[i + 1]), y + icon(ys[i + 1]));
        }
        dc.setPenWidth(1);
    }

    // Stopwatch: ring, hand and top button, centered on (x, y).
    private function drawStopwatch(dc as Dc, x as Number, y as Number) as Void {
        dc.setPenWidth(icon(1) + 1);
        dc.drawCircle(x, y + icon(1), icon(5));
        dc.drawLine(x, y + icon(1), x + icon(2), y - icon(1));   // hand
        dc.drawLine(x, y - icon(6), x, y - icon(8));             // stem
        dc.setPenWidth(1);
        dc.fillRectangle(x - icon(2), y - icon(9), icon(4), icon(2));
    }

    // A pictogram grid length scaled by ICON_SCALE and the screen size, in pixels.
    private function icon(units as Number) as Number {
        return Math.round(units * ICON_SCALE * _scale).toNumber();
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
            [x + icon(2), y - icon(8)] as Graphics.Point2D,
            [x - icon(5), y + icon(1)] as Graphics.Point2D,
            [x - icon(1), y + icon(1)] as Graphics.Point2D,
            [x - icon(3), y + icon(8)] as Graphics.Point2D,
            [x + icon(5), y - icon(2)] as Graphics.Point2D,
            [x + icon(1), y - icon(2)] as Graphics.Point2D
        ] as Array<Graphics.Point2D>);
    }

    // Hand drawn in the style chosen in the settings (see HAND_STYLE_*). `label` is the value the bubble style shows. The shape is
    // described in a local frame: `s` runs along the hand from the center towards the tip,
    // `p` across it (positive to the right).
    private function drawHand(dc as Dc, cx as Number, cy as Number, angle as Float,
                              length as Float, width as Float, tail as Float,
                              label as String) as Void {
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
        } else if (style == HAND_STYLE_GHOST) {
            // Translucent look: a dimmed body inside a full-color outline.
            dc.setColor(shade(color, 0.28), Graphics.COLOR_TRANSPARENT);
            fill(dc, cx, cy, angle, [[-t, 0], [0, -w], [l, 0], [0, w]]);
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            outline(dc, cx, cy, angle, [[-t, 0], [0, -w], [l, 0], [0, w]]);
        } else if (style == HAND_STYLE_GLASS) {
            // Tinted glass lozenge with a bright reflection along one side.
            var shape = [[-t, 0], [0.25 * l, -w], [l, 0], [0.25 * l, w]];
            dc.setColor(shade(color, 0.35), Graphics.COLOR_TRANSPARENT);
            fill(dc, cx, cy, angle, shape);
            dc.setColor(shade(color, 0.8), Graphics.COLOR_TRANSPARENT);
            outline(dc, cx, cy, angle, shape);
            var from = localPoint(cx, cy, angle, 0.2 * l, -w * 0.4);
            var to = localPoint(cx, cy, angle, 0.7 * l, -w * 0.15);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(from[0], from[1], to[0], to[1]);
        } else if (style == HAND_STYLE_NEON) {
            // Glow: a wide dim stroke, the accent color, then a white core.
            var accent = _config.oddMarkColor;
            dc.setColor(shade(accent, 0.3), Graphics.COLOR_TRANSPARENT);
            line(dc, cx, cy, angle, -t, l, 8);
            dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
            line(dc, cx, cy, angle, -t, l, 4);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            line(dc, cx, cy, angle, -t, l, 1);
        } else if (style == HAND_STYLE_TWO_TONE) {
            // Faceted kite: one half in full color, the other in shade.
            fill(dc, cx, cy, angle, [[-t, 0], [0, -w], [l, 0]]);
            dc.setColor(shade(color, 0.5), Graphics.COLOR_TRANSPARENT);
            fill(dc, cx, cy, angle, [[-t, 0], [l, 0], [0, w]]);
        } else if (style == HAND_STYLE_SWORD) {
            fill(dc, cx, cy, angle, [[0.14 * l, -b], [0.92 * l, -b], [l, 0],
                                     [0.92 * l, b], [0.14 * l, b]]);
            fill(dc, cx, cy, angle, [[0.1 * l, -w * 1.1], [0.16 * l, -w * 1.1],
                                     [0.16 * l, w * 1.1], [0.1 * l, w * 1.1]]);
            line(dc, cx, cy, angle, -t, 0.1 * l, 3);
            var pommel = localPoint(cx, cy, angle, -t, 0);
            dc.fillCircle(pommel[0], pommel[1], b * 1.5);
        } else if (style == HAND_STYLE_MERCEDES) {
            // Open ring with a three-pointed star, on a thin stem ending in a blade.
            var r = w * 1.1;
            var c = 0.32 * l;
            line(dc, cx, cy, angle, -t, c - r, 2);
            var at = localPoint(cx, cy, angle, c, 0);
            dc.setPenWidth(2);
            dc.drawCircle(at[0], at[1], r);
            dc.setPenWidth(1);
            for (var k = 0; k < 3; k++) {
                var a = k * 2.0 * Math.PI / 3.0;
                var spoke = localPoint(cx, cy, angle, c + r * Math.cos(a), r * Math.sin(a));
                dc.drawLine(at[0], at[1], spoke[0], spoke[1]);
            }
            fill(dc, cx, cy, angle, [[c + r, -b * 0.8], [l, 0], [c + r, b * 0.8]]);
        } else if (style == HAND_STYLE_PEARLS) {
            // A string of beads that shrink towards the tip.
            var beads = 7;
            for (var k = 0; k < beads; k++) {
                var u = k.toFloat() / (beads - 1);
                var radius = (w * 0.6 * (1.0 - 0.65 * u)).toNumber();
                if (radius < 2) {
                    radius = 2;
                }
                var at = localPoint(cx, cy, angle, 0.1 * l + u * 0.9 * l, 0);
                dc.fillCircle(at[0], at[1], radius);
            }
            var endPoint = localPoint(cx, cy, angle, -t, 0);
            dc.fillCircle(endPoint[0], endPoint[1], 2);
        } else if (style == HAND_STYLE_COMET) {
            // Fake gradient: short segments that brighten and thin out towards the tip.
            var parts = 10;
            for (var k = 0; k < parts; k++) {
                var u = (k + 0.5) / parts;
                var from = -t + k * (l + t) / parts;
                var to = -t + (k + 1) * (l + t) / parts;
                var thickness = (w * 1.6 * (1.0 - 0.65 * u)).toNumber();
                if (thickness < 2) {
                    thickness = 2;
                }
                dc.setColor(shade(color, 0.15 + 0.85 * u), Graphics.COLOR_TRANSPARENT);
                line(dc, cx, cy, angle, from, to, thickness);
            }
        } else if (style == HAND_STYLE_BUBBLE) {
            // Magnifier: the stem is the handle, the tip a glass lens (dark tint, rim, reflection)
            // sized to leave a margin around the digits.
            var textW = dc.getTextWidthInPixels(label, _evenFont);
            var textH = dc.getFontHeight(_evenFont) * 0.7;
            var r = Math.sqrt(textW * textW + textH * textH) / 2.0 + 5.0;
            if (r < l * 0.1) {
                r = l * 0.1;
            }
            // The lens sits further out than the hand tip (hour: 66% of the dial radius, minutes:
            // 80%) so that it stays clear of the gauges.
            var dial = dc.getWidth() / 2.0;
            var c = (l < dial * 0.7) ? dial * 0.66 : dial * 0.8;
            line(dc, cx, cy, angle, -t, c - r, 4);
            var at = localPoint(cx, cy, angle, c, 0);
            dc.setColor(shade(color, 0.2), Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(at[0], at[1], r);
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(3);
            dc.drawCircle(at[0], at[1], r);
            dc.setPenWidth(2);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(at[0], at[1], r - 4, Graphics.ARC_CLOCKWISE, 165, 115);   // glass reflection
            dc.setPenWidth(1);
            dc.drawText(at[0], at[1], _evenFont, label,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            // Classic: tapered kite with a short tail behind the center.
            fill(dc, cx, cy, angle, [[-t, 0], [0, -w], [l, 0], [0, w]]);
        }
    }

    // `color` scaled towards black by `factor` (0..1): stands in for transparency on the black dial.
    private function shade(color as Number, factor as Float) as Number {
        var r = (((color >> 16) & 0xFF) * factor).toNumber();
        var g = (((color >> 8) & 0xFF) * factor).toNumber();
        var b = ((color & 0xFF) * factor).toNumber();
        return (r << 16) | (g << 8) | b;
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
        dc.setPenWidth(px(penWidth));
        dc.drawLine(from[0], from[1], to[0], to[1]);
        dc.setPenWidth(1);
    }
}
