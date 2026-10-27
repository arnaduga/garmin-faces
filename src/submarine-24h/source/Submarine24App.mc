import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class Submarine24App extends Application.AppBase {

    private var _view as Submarine24View or Null = null;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        _view = new Submarine24View();
        return [_view];
    }

    function onSettingsChanged() as Void {
        if (_view != null) {
            _view.reloadSettings();
        }
        WatchUi.requestUpdate();
    }
}
