import Toybox.Application;
import Toybox.Lang;

// User settings (see resources/properties and resources/settings), read once and
// again whenever they change, so that drawing never queries the properties.
class Config {

    // Gauge choices for each slot (values of the GaugeTop / GaugeRight / GaugeLeft settings).
    public static const GAUGE_NONE = 0;
    public static const GAUGE_BATTERY = 1;
    public static const GAUGE_STEPS = 2;
    public static const GAUGE_HEART = 3;
    public static const GAUGE_STRESS = 4;
    public static const GAUGE_ACTIVE = 5;

    // Date language values.
    public static const LANGUAGE_FRENCH = 0;
    public static const LANGUAGE_ENGLISH = 1;

    var handsColor as Number = 0xE8E8E8;
    var secondsColor as Number = 0xFF0000;
    var oddMarkColor as Number = 0xD89B2B;
    var stepsColor as Number = 0x00AAFF;
    var heartColor as Number = 0xFF3030;
    var stressColor as Number = 0xFF4000;
    var activeColor as Number = 0xFF00FF;
    var batteryColor as Number = 0x00FF00;

    var batteryOrangeBelow as Number = 30;
    var batteryRedBelow as Number = 15;

    var showSeconds as Boolean = true;
    var showDate as Boolean = true;
    var showOddNumerals as Boolean = true;
    var midnightAtTop as Boolean = true;

    var dateLanguage as Number = LANGUAGE_FRENCH;
    var handStyle as Number = 0;
    // Gauge shown in each slot: [top, right, left].
    var gauges as Array<Number> = [GAUGE_HEART, GAUGE_STEPS, GAUGE_BATTERY];

    var showDayNight as Boolean = true;
    var dayColor as Number = 0xD89B2B;
    var nightColor as Number = 0x303030;

    function load() as Void {
        handsColor = readNumber("HandsColor", handsColor);
        secondsColor = readNumber("SecondsColor", secondsColor);
        oddMarkColor = readNumber("OddMarkColor", oddMarkColor);
        stepsColor = readNumber("StepsColor", stepsColor);
        heartColor = readNumber("HeartColor", heartColor);
        stressColor = readNumber("StressColor", stressColor);
        activeColor = readNumber("ActiveColor", activeColor);
        batteryColor = readNumber("BatteryColor", batteryColor);

        batteryOrangeBelow = readNumber("BatteryOrangeBelow", batteryOrangeBelow);
        batteryRedBelow = readNumber("BatteryRedBelow", batteryRedBelow);

        showSeconds = readBoolean("ShowSeconds", showSeconds);
        showDate = readBoolean("ShowDate", showDate);
        showOddNumerals = readBoolean("ShowOddNumerals", showOddNumerals);
        midnightAtTop = readBoolean("MidnightAtTop", midnightAtTop);

        dateLanguage = readNumber("DateLanguage", dateLanguage);
        handStyle = readNumber("HandStyle", handStyle);
        gauges = [readGauge("GaugeTop", gauges[0]), readGauge("GaugeRight", gauges[1]),
                  readGauge("GaugeLeft", gauges[2])];

        showDayNight = readBoolean("ShowDayNight", showDayNight);
        dayColor = readNumber("DayColor", dayColor);
        nightColor = readNumber("NightColor", nightColor);
    }

    private function readNumber(key as String, fallback as Number) as Number {
        try {
            var value = Application.Properties.getValue(key);
            return (value instanceof Number) ? value : fallback;
        } catch (ex) {
            return fallback;
        }
    }

    private function readGauge(key as String, fallback as Number) as Number {
        var value = readNumber(key, fallback);
        return (value >= GAUGE_NONE && value <= GAUGE_ACTIVE) ? value : fallback;
    }

    private function readBoolean(key as String, fallback as Boolean) as Boolean {
        try {
            var value = Application.Properties.getValue(key);
            return (value instanceof Boolean) ? value : fallback;
        } catch (ex) {
            return fallback;
        }
    }
}
