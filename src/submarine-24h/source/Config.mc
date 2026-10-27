import Toybox.Application;
import Toybox.Lang;

// User settings (see resources/properties and resources/settings), read once and
// again whenever they change, so that drawing never queries the properties.
class Config {

    // Date language values.
    public static const LANGUAGE_FRENCH = 0;
    public static const LANGUAGE_ENGLISH = 1;

    var handsColor as Number = 0xE8E8E8;
    var secondsColor as Number = 0xFF0000;
    var oddMarkColor as Number = 0xFF5500;
    var stepsColor as Number = 0x00AAFF;
    var batteryColor as Number = 0x00FF00;

    var batteryOrangeBelow as Number = 30;
    var batteryRedBelow as Number = 15;

    var showSeconds as Boolean = true;
    var showDate as Boolean = true;
    var showSteps as Boolean = true;
    var showBattery as Boolean = true;
    var showOddNumerals as Boolean = true;
    var midnightAtTop as Boolean = true;

    var dateLanguage as Number = LANGUAGE_FRENCH;
    var handStyle as Number = 0;

    function load() as Void {
        handsColor = readNumber("HandsColor", handsColor);
        secondsColor = readNumber("SecondsColor", secondsColor);
        oddMarkColor = readNumber("OddMarkColor", oddMarkColor);
        stepsColor = readNumber("StepsColor", stepsColor);
        batteryColor = readNumber("BatteryColor", batteryColor);

        batteryOrangeBelow = readNumber("BatteryOrangeBelow", batteryOrangeBelow);
        batteryRedBelow = readNumber("BatteryRedBelow", batteryRedBelow);

        showSeconds = readBoolean("ShowSeconds", showSeconds);
        showDate = readBoolean("ShowDate", showDate);
        showSteps = readBoolean("ShowSteps", showSteps);
        showBattery = readBoolean("ShowBattery", showBattery);
        showOddNumerals = readBoolean("ShowOddNumerals", showOddNumerals);
        midnightAtTop = readBoolean("MidnightAtTop", midnightAtTop);

        dateLanguage = readNumber("DateLanguage", dateLanguage);
        handStyle = readNumber("HandStyle", handStyle);
    }

    private function readNumber(key as String, fallback as Number) as Number {
        try {
            var value = Application.Properties.getValue(key);
            return (value instanceof Number) ? value : fallback;
        } catch (ex) {
            return fallback;
        }
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
