import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class Submarine24App extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new Submarine24View()];
    }
}
