using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Activity as Activity;
using Toybox.Math as Math;
//using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.Application as App;

enum {       
    SUNRISET_NOW=0,
    SUNRISET_MAX,
    SUNRISET_NBR
}

class lateView extends Ui.WatchFace {
    hidden const CENTER = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    hidden var centerX;
    hidden var centerY;
    hidden var height;
    hidden var color = Graphics.COLOR_YELLOW;
    hidden var dateColor = 0x555555;
    hidden var activityColor = 0x555555;
    hidden var activity = 0;
    hidden var dateForm;
    hidden var showSunrise = false;
    hidden var utcOffset;

	hidden var active;
	
    hidden var clockTime;
    hidden var day = -1;
    // sunrise/sunset
    hidden var lonW;
	hidden var latN;
    hidden var sunrise = new [SUNRISET_NBR];
    hidden var sunset = new [SUNRISET_NBR];

    // resources
    hidden var moon = null;   
    hidden var sun = null; 
    hidden var sunrs = null;   
    hidden var sunst = null;   
    hidden var icon = null;
    hidden var weatherIcon = null;
    hidden var fontSmall = null; 
    hidden var fontMinutes = null;
    hidden var fontHours = null;
    hidden var fontCondensed = null;
    
    hidden var dateY = null;
    hidden var radius;
    hidden var secradius;
    hidden var circleWidth = 2; 
    hidden var dialSize = 0;
    hidden var batteryY;

    hidden var activityY;
    hidden var batThreshold = 5;
    
    // redraw full watchface
    hidden var redrawAll=2; // 2: 2 clearDC() because of lag of refresh of the screen ?
    hidden var lastRedrawMin=-1;
    
    function initialize (){
        //var time=Sys.getTimer();
        WatchFace.initialize();
        var set=Sys.getDeviceSettings();
        height = set.screenHeight;
        centerX = set.screenWidth >> 1;
        centerY = height >> 1;
        //sunrise/sunset stuff
        clockTime = Sys.getClockTime();
        
        //read last values from the Object Store
        var temp=App.getApp().getProperty(OSCOUNTER);
        if(temp!=null && temp instanceof Number) {counter=temp;}
        
        temp=App.getApp().getProperty(OSTodayHigh);
        if(temp!=null && temp instanceof String) {bgTodayHigh=temp;}
        
        temp=App.getApp().getProperty(OSTodayLow);
        if(temp!=null && temp instanceof String) {bgTodayLow=temp;}
        
        temp=App.getApp().getProperty(OSTodayDesc);
        if(temp!=null && temp instanceof String) {bgTodayDesc=temp;}
        
        temp=App.getApp().getProperty(OSTomorrowHigh);
        if(temp!=null && temp instanceof String) {bgTomorrowHigh=temp;}
        
        temp=App.getApp().getProperty(OSTomorrowLow);
        if(temp!=null && temp instanceof String) {bgTomorrowLow=temp;}
        
        temp=App.getApp().getProperty(OSTomorrowDesc);
        if(temp!=null && temp instanceof String) {bgTomorrowDesc=temp;}
        
        var tempValidResponse =App.getApp().getProperty(OSValidResponse);
        if(tempValidResponse!=null && tempValidResponse instanceof Boolean) {bgValidResponse=tempValidResponse;}
        
        var now=Sys.getClockTime();
    	var ts=now.hour+":"+now.min.format("%02d");
        //Sys.println("From OS: data="+bgTodayHigh+","+bgTodayLow+","+bgTomorrowHigh+","+bgTomorrowLow+" "+counter+" at "+ts);
		//printMemoryStats();
    }
    
    function onExitSleep() {
    	active=true;
    	redrawAll = 2;
    	Ui.requestUpdate();
    }

    function onEnterSleep() {
    	active=false;
    	redrawAll =0;
    	Ui.requestUpdate();
    }
    
    //! Load your resources here
    // F5: 240px > F3: 218px > Epix: 148px 
    function onLayout (dc) {
        //setLayout(Rez.Layouts.WatchFace(dc));
        loadSettings();
    }

    function setLayoutVars(){
        if(height>218){
            if(activity>0){
                fontCondensed = Ui.loadResource(Rez.Fonts.Condensed240);
                activityY = (height>180) ? height-Gfx.getFontHeight(fontCondensed)-10 : centerY+80-Gfx.getFontHeight(fontCondensed)>>1 ;
            }
            if(dialSize>0){
                fontMinutes = Ui.loadResource(Rez.Fonts.MinuteBig240);
                fontHours = Ui.loadResource(Rez.Fonts.HoursBig240px);
                fontSmall = Ui.loadResource(Rez.Fonts.SmallBig240);
                radius = 89;
                dateY = centerY-Gfx.getFontHeight(fontHours)>>1-Gfx.getFontHeight(fontMinutes)-7;
                batteryY=height-15 ;
                circleWidth=circleWidth*3+1;
                activityY= centerY+Gfx.getFontHeight(fontHours)>>1+5;
            } else {
                //fontMinutes = Ui.loadResource(Rez.Fonts.Minute240);
                //fontHours = Ui.loadResource(Rez.Fonts.Hours240px);
                fontHours = Ui.loadResource(Rez.Fonts.HoursBig240px);
                fontMinutes = Ui.loadResource(Rez.Fonts.Hours240px);
                fontSmall = Ui.loadResource(Rez.Fonts.Small240);
                //radius = 63;
                radius = 100;
                //dateY = centerY-90-(Gfx.getFontHeight(fontSmall)>>1);
                secradius = 119;
                //dateY = centerY-80-(Gfx.getFontHeight(fontSmall)>>1);
                dateY = centerY-70-(Gfx.getFontHeight(fontSmall)>>1);
                batteryY = centerY+38;
            }
        } else {
            if(activity>0){
                fontCondensed = Ui.loadResource(Rez.Fonts.Condensed);
                activityY = (height>180) ? height-Gfx.getFontHeight(fontCondensed)-10 : centerY+80-Gfx.getFontHeight(fontCondensed)>>1 ;    
            }
            if(dialSize>0){
                fontMinutes = Ui.loadResource(Rez.Fonts.MinuteBig);
                fontHours = Ui.loadResource(Rez.Fonts.HoursBig);        
                fontSmall = Ui.loadResource(Rez.Fonts.SmallBig);
                radius = 81;
                dateY = centerY-Gfx.getFontHeight(fontHours)>>1-Gfx.getFontHeight(fontMinutes)-6;
                batteryY=height-15;
                circleWidth=circleWidth*3;
                activityY= centerY+Gfx.getFontHeight(fontHours)>>1+5;
            } else {
                fontMinutes = Ui.loadResource(Rez.Fonts.Minute);
                fontHours = Ui.loadResource(Rez.Fonts.Hours);     
                fontSmall = Ui.loadResource(Rez.Fonts.Small);   
                radius = 55;
                dateY = centerY-80-(Gfx.getFontHeight(fontSmall)>>1);
                batteryY = centerY+33;
                
            }
        }
        var langTest = Calendar.info(Time.now(), Time.FORMAT_MEDIUM).day_of_week.toCharArray()[0]; // test if the name of week is in latin. Name of week because name of month contains mix of latin and non-latin characters for some languages. 
        if(langTest.toNumber()>382){ // fallback for not-supported latin fonts 
            fontSmall = Gfx.FONT_SMALL;
        }
        dateColor = 0xaaaaaa;
    }

    function loadSettings(){
        color = App.getApp().getProperty("color");
        dateForm = App.getApp().getProperty("dateForm");
        activity = App.getApp().getProperty("activity");
        //activity = 2;  /* %REM REMOVE ---------------- TEST -----------------*/
        showSunrise = App.getApp().getProperty("sunriset");
        batThreshold = App.getApp().getProperty("bat");
        circleWidth = App.getApp().getProperty("boldness");
        dialSize = App.getApp().getProperty("dialSize");

//color = 0x00AAFF;
//activity = 2;
//showSunrise = true;
//batThreshold = 100;
//dialSize = 1;
//circleWidth = 3;

        // when running for the first time: load resources and compute sun positions
        if(showSunrise ){ // TODO recalculate when day or position changes
            moon = Ui.loadResource(Rez.Drawables.Moon);
            sun = Ui.loadResource(Rez.Drawables.Sun);
            sunrs = Ui.loadResource(Rez.Drawables.Sunrise);
            sunst = Ui.loadResource(Rez.Drawables.Sunset);
            clockTime = Sys.getClockTime();
            utcOffset = clockTime.timeZoneOffset;
            computeSun();
        }
		
		//If watch is active
        if(activity>0){ 
            dateColor = 0xaaaaaa;
            if(activity == 1) { icon = Ui.loadResource(Rez.Drawables.Steps); }
            else if(activity == 2) { icon = Ui.loadResource(Rez.Drawables.Cal); }
            else if(activity >= 3 && !(ActivityMonitor.getInfo() has :activeMinutesDay)){ 
                activity = 0;   // reset not supported activities
            } else if(activity <= 4) { icon = Ui.loadResource(Rez.Drawables.Minutes); }
            else if(activity == 5) { icon = Ui.loadResource(Rez.Drawables.Floors); }
        } else {
            dateColor = 0x555555;
        }


        redrawAll = 2;
        setLayoutVars();

    }

    //! Called when this View is brought to the foreground. Restore the state of this View and prepare it to be shown. This includes loading resources into memory.
    function onShow() {
        redrawAll = 2;
    }
    
    //! Called when this View is removed from the screen. Save the state of this View here. This includes freeing resources from memory.
    function onHide(){
        redrawAll =0;
        //var now=Sys.getClockTime();
    	//var ts=now.hour+":"+now.min.format("%02d");        
        //Sys.println("onHide counter="+counter+" "+ts);    
    	App.getApp().setProperty(OSCOUNTER, counter);
    }
    
    //! The user has just looked at their watch. Timers and animations may be started here.
    //function onExitSleep(){
    //    redrawAll = 2;
    //}

    //! Terminate any active timers and prepare for slow updates.
    //function onEnterSleep(){
    //    redrawAll =0;
    //}

    /*function openTheMenu(){
        menu = new MainMenu(self);
        Ui.pushView(new Rez.Menus.MainMenu(), new MyMenuDelegate(), Ui.SLIDE_UP);
    }*/

    //! Update the view
    function onUpdate (dc) {
        clockTime = Sys.getClockTime();

        if (lastRedrawMin != clockTime.min) { redrawAll = 1; }

        if (redrawAll!=0){
            dc.setColor(0x00, 0x00);
            dc.clear();
            lastRedrawMin=clockTime.min;
            var info = Calendar.info(Time.now(), Time.FORMAT_MEDIUM);
            var h=clockTime.hour;

            if(showSunrise){
                if(day != info.day || utcOffset != clockTime.timeZoneOffset ){ // TODO should be recalculated rather when passing sunrise/sunset
                    computeSun();
                }
                drawSunBitmaps(dc);
                // show now in a day
                var a = Math.PI/(12*60.0) * (h*60+clockTime.min);
                /*var bitmapNow = sun;
                if(a<sunset[SUNRISET_NOW] || a>sunrise[SUNRISET_NOW]){
                    bitmapNow = moon;
                } 
                var r = centerX - 11;
                dc.drawBitmap(centerX + (r * Math.sin(a))-bitmapNow.getWidth()>>1, centerY - (r * Math.cos(a))-bitmapNow.getWidth()>>1, bitmapNow);*/
                dc.setColor(0x555555, 0);
                dc.setPenWidth(1);
                var r = centerX-5;
                //dc.drawLine(centerX+(r*Math.sin(a)), centerY-(r*Math.cos(a)),centerX+((r-11)*Math.sin(a)), centerY-((r-11)*Math.cos(a)));
                dc.drawCircle(centerX+((r-5)*Math.sin(a)), centerY-((r-5)*Math.cos(a)),4);

            }
            // TODO recalculate sunrise and sunset every day or when position changes (timezone is probably too rough for traveling)

            // draw hour
            var ampm="am";
            if(Sys.getDeviceSettings().is24Hour == false){
                if(h>11){ h-=12; ampm="pm";}
                if(0==h){ h=12; ampm="pm";}
            }

            //h=12;
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
            if ( h >= 10 ) {
				dc.drawText(centerX-65, centerY-(dc.getFontHeight(fontHours)>>1), fontHours, h.format("%0.1d"), Gfx.TEXT_JUSTIFY_CENTER);
			} else {
				dc.drawText(centerX-48, centerY-(dc.getFontHeight(fontHours)>>1), fontHours, h.format("%0.1d"), Gfx.TEXT_JUSTIFY_CENTER);
			}
			dc.drawText(centerX+35, centerY-(dc.getFontHeight(fontHours)>>1), fontMinutes, lastRedrawMin.format("%02d") , Gfx.TEXT_JUSTIFY_CENTER);
			dc.drawText(centerX+95, centerY-(dc.getFontHeight(fontHours)>>1) - 6, fontSmall, ampm , Gfx.TEXT_JUSTIFY_CENTER);
			
			//Draw HR
			var HRH=ActivityMonitor.getHeartRateHistory(1, true);
			var HRS=HRH.next();
			dc.drawText(centerX + 82,batteryY - 15,fontSmall,"hr:"+HRS.heartRate,Gfx.TEXT_JUSTIFY_CENTER);
			
			//Draw Temp
			// Check device for SensorHistory compatibility
   			if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getTemperatureHistory)) {
				dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK);
				var TempH=Toybox.SensorHistory.getTemperatureHistory({});
				var TempS=TempH.next();
				TempS = TempS.data * 1.8 + 32;
				dc.drawText(centerX+103, centerY - 20, Gfx.FONT_SYSTEM_TINY, Lang.format("$1$°",[TempS.toNumber().toString()]), Gfx.TEXT_JUSTIFY_CENTER);
				
			}
			
			//Draw forcast 
			if ( bgValidResponse || ( bgTodayDesc!= "" && bgTomorrowDesc!="" ) ) {
				dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK);
				//var TempText = bgTomorrowLow;
				//var bgTodayHighNum = bgTodayHigh.toNumber();
				if(bgTodayHigh != null && bgTodayHigh instanceof String && bgTodayHigh!="" && bgTodayHigh.toNumber() instanceof Number) {
					//Sys.println("today high "+ bgTodayHigh +"|");
					dc.drawText(centerX-18, centerY + 51, Gfx.FONT_SYSTEM_TINY, Lang.format("$1$°",[bgTodayHigh.toNumber().toString()]), Gfx.TEXT_JUSTIFY_CENTER);
				}
				if(bgTodayLow != null && bgTodayLow instanceof String && bgTodayLow!="" && bgTodayLow.toNumber() instanceof Number) {
					dc.drawText(centerX-18, centerY + 77, Gfx.FONT_SYSTEM_TINY, Lang.format("$1$°",[bgTodayLow.toNumber().toString()]), Gfx.TEXT_JUSTIFY_CENTER);
				}	
				if(bgTomorrowHigh != null && bgTomorrowHigh instanceof String && bgTomorrowHigh!="" && bgTomorrowHigh.toNumber() instanceof Number) {
					dc.drawText(centerX+25, centerY + 51, Gfx.FONT_SYSTEM_TINY, Lang.format("$1$°",[bgTomorrowHigh.toNumber().toString()]), Gfx.TEXT_JUSTIFY_CENTER);
				}	
				if(bgTomorrowLow != null && bgTomorrowLow instanceof String && bgTomorrowLow!="" && bgTomorrowLow.toNumber() instanceof Number) {
					dc.drawText(centerX+25, centerY + 77, Gfx.FONT_SYSTEM_TINY, Lang.format("$1$°",[bgTomorrowLow.toNumber().toString()]), Gfx.TEXT_JUSTIFY_CENTER);
				}
				
				weatherIcon = getWeatherIcon(bgTodayDesc);				
                dc.drawBitmap(centerX - 77, centerY + 54, weatherIcon);
				weatherIcon = getWeatherIcon(bgTomorrowDesc);				
                dc.drawBitmap(centerX + 42, centerY + 54, weatherIcon);
			}
			
            if(centerY>89){

                // draw Date info
                dc.setColor(dateColor, Gfx.COLOR_BLACK);
                var text = "";
                text = info.day_of_week + " " + info.month;
                text += " " + info.day.format("%0.1d");
                text += " " + info.year;
                dc.drawText(centerX, dateY, fontSmall, text, Gfx.TEXT_JUSTIFY_CENTER);
				
                
                /*dc.drawText(centerX, height-20, fontSmall, ActivityMonitor.getInfo().moveBarLevel, CENTER);
                dc.setPenWidth(2);
                dc.drawArc(centerX, height-20, 12, Gfx.ARC_CLOCKWISE, 90, 90-(ActivityMonitor.getInfo().moveBarLevel.toFloat()/(ActivityMonitor.MOVE_BAR_LEVEL_MAX-ActivityMonitor.MOVE_BAR_LEVEL_MIN)*ActivityMonitor.MOVE_BAR_LEVEL_MAX)*360);
                */

                // activity

                //System.println(method(:humanizeNumber).invoke(100000)); // TODO this is how to save and invoke method callback to get rid of ugly ifelse like below
                // The best circle for activity percentages: dc.setPenWidth(2);dc.setColor(Gfx.COLOR_DK_GRAY, 0); dc.drawArc(centerX, 190, 10, Gfx.ARC_CLOCKWISE, 90, 90-49*6);

                if(activity > 0){
                    text = ActivityMonitor.getInfo();
                    if(activity == 1){ text = humanizeNumber(text.steps); }
                    else if(activity == 2){ text = humanizeNumber(text.calories); }
                    else if(activity == 3){ text = (text.activeMinutesDay.total.toString());} // moderate + vigorous
                    else if(activity == 4){ text = humanizeNumber(text.activeMinutesWeek.total); }
                    else if(activity == 5){ text = (text.floorsClimbed.toString()); }
                    else {text = "";}
                    dc.setColor(activityColor, Gfx.COLOR_BLACK);
                    dc.drawText(centerX + icon.getWidth()>>1, activityY, fontCondensed, text, Gfx.TEXT_JUSTIFY_CENTER); 
                    dc.drawBitmap(centerX - dc.getTextWidthInPixels(text, fontCondensed)>>1 - icon.getWidth()>>1-2, activityY+5, icon);
                }
            }
            drawBatteryLevel(dc);
            //drawMinuteArc(dc);
        }
        
        if(active){
            drawSecondArc(dc, clockTime.sec);
        } else {
            drawSecondArc(dc, 0);
        }
        
        if (0>redrawAll) { redrawAll--; }
    }

    function humanizeNumber(number){
        if(number>1000) {
            return (number.toFloat()/1000).format("%1.1f")+"k";
        } else {
            return number.toString();
        }
    }

	function drawSecondArc (dc, seconds){
		
        var angle =  seconds/60.0*2*Math.PI;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);
        var offset=0;
        var gap=0;

        dc.setColor(Gfx.COLOR_GREEN, 0);

        if(seconds>0){
            //dc.setColor(Gfx.COLOR_GREEN, 0);
            dc.setPenWidth(circleWidth);
            
            if(seconds>=10){
                if(seconds>=52){
                    offset=12;
                    if(seconds==59){
                        gap=4;    
                    } 
                } else {
                    if(seconds>=12&&seconds<=22){
                        offset=9;
                    }
                    else {
                        offset=10;
                    }
                }
            } else {
                if(seconds>=7){
                    offset=8;
                } else {
                    if(seconds==1){
                        offset=4;
                    } else {
                        offset=6;
                    }
                }

            }
            dc.drawArc(centerX, centerY, secradius, Gfx.ARC_CLOCKWISE, 90-gap, 90-seconds*6+offset);
        }
	}

    function drawMinuteArc (dc){
        var minutes = clockTime.min; 
        var angle =  minutes/60.0*2*Math.PI;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);
        var offset=0;
        var gap=0;

        dc.setColor(Gfx.COLOR_WHITE, 0);
        dc.drawText(centerX + (radius * sin), centerY - (radius * cos) , fontMinutes, minutes /*clockTime.min.format("%0.1d")*/, CENTER);

        if(minutes>0){
            dc.setColor(color, 0);
            dc.setPenWidth(circleWidth);
            
            /* kerning values not to have ugly gaps between arc and minutes
            minute:padding px
            1:4 
            2-6:6 
            7-9:8 
            10-11:10 
            12-22:9 
            23-51:10 
            52-59:12
            59:-3*/

            // correct font kerning not to have wild gaps between arc and number
            if(minutes>=10){
                if(minutes>=52){
                    offset=12;
                    if(minutes==59){
                        gap=4;    
                    } 
                } else {
                    if(minutes>=12&&minutes<=22){
                        offset=9;
                    }
                    else {
                        offset=10;
                    }
                }
            } else {
                if(minutes>=7){
                    offset=8;
                } else {
                    if(minutes==1){
                        offset=4;
                    } else {
                        offset=6;
                    }
                }

            }
            dc.drawArc(centerX, centerY, radius, Gfx.ARC_CLOCKWISE, 90-gap, 90-minutes*6+offset);
        }
        
    }

    function drawBatteryLevel (dc){
        var bat = Math.round(Sys.getSystemStats().battery).toNumber();
        var xPos = centerX + 25;
        var yPos = batteryY - 15;
        dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_BLACK);
        dc.drawText(xPos, yPos, fontSmall, "w:" + bat + "%", Gfx.TEXT_JUSTIFY_CENTER);
        
        //batThreshold=100;bat = 10;
		
        /*if(bat<=batThreshold){

            var xPos = centerX-10;
            var yPos = batteryY;

            // print the remaining %
            //var str = bat.format("%d") + "%";
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
            dc.setPenWidth(1);
            dc.fillRectangle(xPos,yPos,20, 10);

            if(bat<=15){
                dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_BLACK);
            } else {
                dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_BLACK);
            }
                
            // draw the battery

            dc.drawRectangle(xPos, yPos, 19, 10);
            dc.fillRectangle(xPos + 19, yPos + 3, 1, 4);

            var lvl = floor((15.0 * (bat / 99.0)));
            if (1.0 <= lvl) { dc.fillRectangle(xPos + 2, yPos + 2, lvl, 6); }
            else {
                dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_BLACK);
                dc.fillRectangle(xPos + 1, yPos + 1, 1, 8);
            }
       }*/
    }


    function drawSunBitmaps (dc) {
        if(sunrise[SUNRISET_NOW] != null) {
            // SUNRISE (sun)
            var a = ((sunrise[SUNRISET_NOW].toNumber() % 24) * 60) + ((sunrise[SUNRISET_NOW] - sunrise[SUNRISET_NOW].toNumber()) * 60);
            a *= Math.PI/(12 * 60.0);
            var r = centerX - 11;
            dc.drawBitmap(centerX + (r * Math.sin(a))-sunrs.getWidth()>>1, centerY - (r * Math.cos(a))-sunrs.getWidth()>>1, sunrs);
            
            // SUNSET (moon)
            a = ((sunset[SUNRISET_NOW].toNumber() % 24) * 60) + ((sunset[SUNRISET_NOW] - sunset[SUNRISET_NOW].toNumber()) * 60); 
            a *= Math.PI/(12 * 60.0);
            dc.drawBitmap(centerX + (r * Math.sin(a))-sunst.getWidth()>>1, centerY - (r * Math.cos(a))-sunst.getWidth()>>1, sunst);
            //System.println(sunset[SUNRISET_NOW].toNumber()+":"+(sunset[SUNRISET_NOW].toFloat()*60-sunset[SUNRISET_NOW].toNumber()*60).format("%1.0d"));

            /*dc.setColor(0x555555, 0);
            dc.drawText(centerX + (r * Math.sin(a))+moon.getWidth()+2, centerY - (r * Math.cos(a))-moon.getWidth()>>1, fontCondensed, sunset[SUNRISET_NOW].toNumber()+":"+(sunset[SUNRISET_NOW].toFloat()*60-sunset[SUNRISET_NOW].toNumber()*60).format("%1.0d"), Gfx.TEXT_JUSTIFY_VCENTER|Gfx.TEXT_JUSTIFY_LEFT);*/

            /*a = (clockTime.hour*60+clockTime.min).toFloat()/1440*360;
            System.println(a + " " + (centerX + (r*Math.sin(a))) + " " +(centerY - (r*Math.cos(a))));
            dc.drawArc(centerX, centerY, 100, Gfx.ARC_CLOCKWISE, 90-a+2, 90-a);*/
        }
    }

    function computeSun() {
        var pos = Activity.getActivityInfo().currentLocation;
        if (pos == null){
            pos = App.getApp().getProperty("location"); // load the last location to fix a Fenix 5 bug that is loosing the location often
            if(pos == null){
                sunrise[SUNRISET_NOW] = null;
                return;
            }

            
        } else {
            pos = pos.toDegrees();
            App.getApp().setProperty("location", pos); // save the location to fix a Fenix 5 bug that is loosing the location often
        }
        // use absolute to get west as positive
        lonW = pos[1].toFloat();
        latN = pos[0].toFloat();


        // compute current date as day number from beg of year
        utcOffset = clockTime.timeZoneOffset;
        var timeInfo = Calendar.info(Time.now().add(new Time.Duration(utcOffset)), Calendar.FORMAT_SHORT);

        day = timeInfo.day;
        var now = dayOfYear(timeInfo.day, timeInfo.month, timeInfo.year);
        //Sys.println("dayOfYear: " + now.format("%d"));
        sunrise[SUNRISET_NOW] = computeSunriset(now, lonW, latN, true);
        sunset[SUNRISET_NOW] = computeSunriset(now, lonW, latN, false);

        // max
        var max;
        if (latN >= 0){
            max = dayOfYear(21, 6, timeInfo.year);
            //Sys.println("We are in NORTH hemisphere");
        } else{
            max = dayOfYear(21,12,timeInfo.year);            
            //Sys.println("We are in SOUTH hemisphere");
        }
        sunrise[SUNRISET_MAX] = computeSunriset(max, lonW, latN, true);
        sunset[SUNRISET_MAX] = computeSunriset(max, lonW, latN, false);

        //adjust to timezone + dst when active
        var offset=new Time.Duration(utcOffset).value()/3600;
        for (var i = 0; i < SUNRISET_NBR; i++){
            sunrise[i] += offset;
            sunset[i] += offset;
        }


        for (var i = 0; i < SUNRISET_NBR-1 && SUNRISET_NBR>1; i++){
            if (sunrise[i]<sunrise[i+1]){
                sunrise[i+1]=sunrise[i];
            }
            if (sunset[i]>sunset[i+1]){
                sunset[i+1]=sunset[i];
            }
        }

        /*var sunriseInfoStr = new [SUNRISET_NBR];
        var sunsetInfoStr = new [SUNRISET_NBR];
        for (var i = 0; i < SUNRISET_NBR; i++)
        {
            sunriseInfoStr[i] = Lang.format("$1$:$2$", [sunrise[i].toNumber() % 24, ((sunrise[i] - sunrise[i].toNumber()) * 60).format("%.2d")]);
            sunsetInfoStr[i] = Lang.format("$1$:$2$", [sunset[i].toNumber() % 24, ((sunset[i] - sunset[i].toNumber()) * 60).format("%.2d")]);
            //var str = i+":"+ "sunrise:" + sunriseInfoStr[i] + " | sunset:" + sunsetInfoStr[i];
            //Sys.println(str);
        }*/
        return;
   }
   
	function printMemoryStats() {
		var systemStats = Sys.getSystemStats();
        Sys.println(Lang.format("$1$, $2$, $3$", [
            systemStats.freeMemory,
            systemStats.usedMemory,
            1.0 * systemStats.freeMemory / systemStats.totalMemory
        ]));
	}
	
	function getWeatherIcon(description) {
		var weatherIcon = null;
		if ( description.find("Fair") != null || description.find("fair") != null || description.find("Clear") != null || description.find("clear") != null || description.find("Sunny") != null ) {
			weatherIcon = Ui.loadResource(Rez.Drawables.Clear);
		} else if ( description.find("Mostly Cloudy") != null ) {
			weatherIcon = Ui.loadResource(Rez.Drawables.Cloudy);
		} else if ( description.find("Cloud") != null ) {
			weatherIcon = Ui.loadResource(Rez.Drawables.Clouds);
		} else if ( description.find("Overcast") != null ) {
			weatherIcon = Ui.loadResource(Rez.Drawables.Overcast);
		} else if ( description.find("Snow") != null ) {
			weatherIcon = Ui.loadResource(Rez.Drawables.Snow);
		} else if ( description.find("Ice") != null || description.find("Freez") != null || description.find("Blizzard") != null ) {
			weatherIcon = Ui.loadResource(Rez.Drawables.Ice);
		} else if ( description.find("Thunderstorm") != null ) {
			weatherIcon = Ui.loadResource(Rez.Drawables.Thunder);
		} else if ( description.find("Rain") != null || description.find("Drizzl") != null || description.find("Shower") != null ) {
			weatherIcon = Ui.loadResource(Rez.Drawables.Rain);
		} else if ( description.find("Tornado") != null || description.find("Funnel") != null || description.find("Hurricane") != null || description.find("Tropical Storm") != null || description.find("Dust") != null || description.find("Sand") != null || description.find("Smoke") != null ) {
			weatherIcon = Ui.loadResource(Rez.Drawables.Tornado);
		} else if ( description.find("Wind") != null || description.find("Breez") != null ) {
			weatherIcon = Ui.loadResource(Rez.Drawables.Windy);
		} else if ( description.find("Hot") != null ) {
			weatherIcon = Ui.loadResource(Rez.Drawables.Hot);
		} else if ( description.find("Cold") != null ) {
			weatherIcon = Ui.loadResource(Rez.Drawables.Cold);
		} else {
				weatherIcon = Ui.loadResource(Rez.Drawables.Overcast);
		}
		
		return weatherIcon;
	}
}