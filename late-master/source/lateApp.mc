using Toybox.Application as App;
using Toybox.Background;
using Toybox.System as Sys;
using Toybox.WatchUi as Ui;

// info about whats happening with the background process
var counter=0;
var bgTodayHigh="";
var bgTodayLow="";
var bgTodayDesc="";
var bgTomorrowHigh="";
var bgTomorrowLow="";
var bgTomorrowDesc="";
var bgValidResponse=false;
var canDoBG=false;
// keys to the object store data
var OSCOUNTER="oscounter";
var OSTodayHigh="OSTodayHigh";
var OSTodayLow="OSTodayLow";
var OSTodayDesc="OSTodayDesc";
var OSTomorrowHigh="OSTomorrowHigh";
var OSTomorrowLow="OSTomorrowLow";
var OSTomorrowDesc="OSTomorrowDesc";
var OSValidResponse="OSValidResponse";

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
    
    function onBackgroundData(data) {
    	counter++;
    	var now=Sys.getClockTime();
    	var ts=now.hour+":"+now.min.format("%02d");
        Sys.println("onBackgroundData="+ data +" at "+ts);
        App.getApp().setProperty(OSValidResponse,false);
    	if ( data != "" ) { //we got data
	    	//split data into
	    	var myString = "" + data;
	    	data = "";
	    	var index = myString.find(",");
	    	//Sys.println("index="+ index);
	    	var todayHigh=myString.substring(0,index);
	    	//Sys.println("todayHigh="+ todayHigh);
	    	myString = myString.substring(index + 1,  myString.length());
	    	//Sys.println("myString="+ myString);
	    	index = myString.find(",");
	    	//Sys.println("index="+ index);
	    	var todayLow=myString.substring(0,index);
	    	myString = myString.substring(index + 1,  myString.length());
	    	//Sys.println("myString="+ myString);
	    	index = myString.find(",");
	    	//Sys.println("index="+ index);
	    	var todayDesc = myString.substring(0,index);
	    	myString = myString.substring(index + 1,  myString.length());
	    	//Sys.println("myString="+ myString);
	    	index = myString.find(",");
	    	//Sys.println("index="+ index);
	    	var tomorrowHigh = myString.substring(0,index);
	    	myString = myString.substring(index + 1,  myString.length());
	    	//Sys.println("myString="+ myString);
	    	index = myString.find(",");
	    	//Sys.println("index="+ index);
	    	var tomorrowLow = myString.substring(0,index);
	    	myString = myString.substring(index + 1,  myString.length());
	    	//Sys.println("myString="+ myString);
	    	index = myString.find(",");
	    	if ( index == null ) {
	    		index = myString.length();
	    	}
	    	//Sys.println("index="+ index);
	    	var tomorrowDesc = myString.substring(0,index);
	    	myString = "";
	    	Sys.println("Parsed vars: "+ todayHigh + ", " + todayLow + ", " + todayDesc + ", " + tomorrowHigh + ", " + tomorrowLow + ", " + tomorrowDesc);
	    	if(todayHigh.toNumber()!=999) {
	    		bgTodayHigh=todayHigh;
	        	App.getApp().setProperty(OSTodayHigh,todayHigh);
	        	Sys.println("setting todays high");
	    	}
			bgTodayLow=todayLow;
			bgTodayDesc=todayDesc;
			bgTomorrowHigh=tomorrowHigh;
			bgTomorrowLow=tomorrowLow;
			bgTomorrowDesc=tomorrowDesc;
			bgValidResponse = true;
	        App.getApp().setProperty(OSTodayLow,todayLow);
	        App.getApp().setProperty(OSTodayDesc,todayDesc);
	        App.getApp().setProperty(OSTomorrowHigh,tomorrowHigh);
	        App.getApp().setProperty(OSTomorrowLow,tomorrowLow);
	        App.getApp().setProperty(OSTomorrowDesc,tomorrowDesc);
	        App.getApp().setProperty(OSValidResponse,true);
	        todayHigh="";
			todayLow="";
			todayDesc="";
			tomorrowHigh="";
			tomorrowLow="";
			tomorrowDesc="";
	        Ui.requestUpdate();
    	}
    	
    }    

    function getServiceDelegate(){
    	var now=Sys.getClockTime();
    	var ts=now.hour+":"+now.min.format("%02d");    
    	Sys.println("getServiceDelegate: "+ts);
        return [new LatebgServiceDelegate()];
    }
}
