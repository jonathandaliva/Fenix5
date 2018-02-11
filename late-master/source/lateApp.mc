using Toybox.Application as App;
using Toybox.Background;
using Toybox.System as Sys;
using Toybox.WatchUi as Ui;

// info about whats happening with the background process
var counter=0;
var bgTodayHigh="";
var bgTodayLow="";
var bgTomorrowHigh="";
var bgTomorrowLow="";
var canDoBG=false;
// keys to the object store data
var OSCOUNTER="oscounter";
var OSTodayHigh="";
var OSTodayLow="";
var OSTomorrowHigh="";
var OSTomorrowLow="";

(:background)
class lateApp extends App.AppBase{
    var watch;

    function initialize(){
        AppBase.initialize();
    	var now=Sys.getClockTime();
    	var ts=now.hour+":"+now.min.format("%02d");
    	//you'll see this gets called in both the foreground and background        
        Sys.println("App initialize "+ts);
    }

    function onStart(state) { }

    function onStop(state) { }

    function onSettingsChanged(){
        watch.loadSettings();
        Ui.requestUpdate();
    }

    function getInitialView(){
        //watch = new lateView();
        //return [watch];
        
        //register for temporal events if they are supported
    	if(Toybox.System has :ServiceDelegate) {
    		canDoBG=true;
    		Background.registerForTemporalEvent(new Time.Duration(5*60));
    	} else {
    		Sys.println("****background not available on this device****");
    	}
        return [ new lateView() ];
    }
    
    function onBackgroundData(todayHigh, todayLow, tomorrowHigh, tomorrowLow) {
    	counter++;
    	var now=Sys.getClockTime();
    	var ts=now.hour+":"+now.min.format("%02d");
        Sys.println("onBackgroundData="+todayHigh+","+todayLow+","+tomorrowHigh+","+tomorrowLow+" "+counter+" at "+ts);
        bgTodayHigh=todayHigh;
		bgTodayLow=todayLow;
		bgTomorrowHigh=tomorrowHigh;
		bgTomorrowLow=tomorrowLow;
        App.getApp().setProperty(OSTodayHigh,todayHigh);
        App.getApp().setProperty(OSTodayLow,todayLow);
        App.getApp().setProperty(OSTomorrowHigh,tomorrowHigh);
        App.getApp().setProperty(OSTomorrowLow,tomorrowLow);
        Ui.requestUpdate();
    }    

    function getServiceDelegate(){
    	var now=Sys.getClockTime();
    	var ts=now.hour+":"+now.min.format("%02d");    
    	Sys.println("getServiceDelegate: "+ts);
        return [new LatebgServiceDelegate()];
    }
}
