using Toybox.Background;
using Toybox.System as Sys;
using Toybox.Communications;

// The Service Delegate is the main entry point for background processes
// our onTemporalEvent() method will get run each time our periodic event
// is triggered by the system.

(:background)
class LatebgServiceDelegate extends Toybox.System.ServiceDelegate {
	
	function initialize() {
		Sys.ServiceDelegate.initialize();

	}
	
    function onTemporalEvent() {
    	var now=Sys.getClockTime();
    	var ts=now.hour+":"+now.min.format("%02d");
        Sys.println("bg exit: "+ts);
        //just return the timestamp
        
        	//Draw forcast //TODO need to update this to pull location based on IP then pass that to openweathermap
			//var latLon = Toybox.Position.info.position.toDegrees();
			//https://api.darksky.net/forecast/dec84d9b5c99a82a25e386b2257cf9b0/37.8267,-122.4233?exclude=currently,minutely,hourly,alerts,flags
			
		//Communications.makeWebRequest("https://freegeoip.net/json/", {"format" => "json"}, {}, method(:onReceiveLocation));
		
		Communications.makeWebRequest("https://api.darksky.net/forecast/dec84d9b5c99a82a25e386b2257cf9b0/37.8267,-122.4233?exclude=currently,minutely,hourly,alerts,flags", {"format" => "json"}, {}, method(:onReceiveLocation));
		
		//Communications.makeWebRequest(url, {}, {}, method(:onReceive));
		    //Communications.makeJsonRequest("http://freegeoip.net/json", {}, {}, method(:onReceive));
		    //country_code	"US"
		    //city	"Leesburg"
		    //zip_code	"20176"
		    
		    //api.openweathermap.org/data/2.5/forecast?zip=20176,US&APPID=f175ed51e7c728ca4b30395693a24d34&units=imperial
			//Comm.makeJsonRequest("http://api.openweathermap.org/data/2.5/weather",{"lat"=>latLon[0].toFloat(), "lon"=>latLon[1].toFloat(),"appid"=>"f175ed51e7c728ca4b30395693a24d34"}, {}, method(:onReceive));
			
        
        //Background.exit(ts);
    }
    
    function onReceiveLocation(responseCode, data)
	{
        Sys.println("location data received");
        
        printMemoryStats();
	    if( responseCode == 200 )
	    {
	        Sys.println("data ok 200");	
	        Sys.println(data);
	        /*var mystring = "" + data;
	        data = "";
	        var index = mystring.find("region_code=>");
	        var region_code = mystring.substring(index + 13,  index + 15);
	        index = mystring.find("zip_code=>");
	        var zip_code = mystring.substring(index + 10,  index + 15);
	        data = region_code + "/" + zip_code;
	        Sys.println(data);
	        
	        var AppID="673c015c876b7115";
	        //var AppID="f175ed51e7c728ca4b30395693a24d34";
	        
	        //http://api.wunderground.com/api/673c015c876b7115/forecast/q/VA/Leesburg.json
	        //var URL = "https://api.openweathermap.org/data/2.5/forecast?zip=" + data + "&APPID=" + AppID + "&units=imperial";
	        var URL = "https://api.wunderground.com/api/" + AppID + "/forecast/q/" + data + ".json";
	        Sys.println(URL);
	        */
	        printMemoryStats();
	        //Communications.makeWebRequest(URL, {"format" => "json"}, {}, method(:onReceiveForcast));
	        Background.exit("");
	    }
	    else
	    { 
	    	Sys.println("response code:" + responseCode);
       	 	Sys.println("data:" + data);
       	 	Background.exit("");
	    }
	    //Background.exit(data);
	    //Ui.requestUpdate(); // this will then display the debug variable on the screen.
	}
	
	function onReceiveForcast(responseCode, data)
	{
        Sys.println("forcast data received");
	    if( responseCode == 200 )
	    {
	        Sys.println("data ok 200");	
	        Sys.println(data);
	        var mystring = "" + data;
	        data = "";
	        var todayHigh = "";
	        var todayLow = "";
	        var tomorrowHigh = "";
	        var tomorrowLow = "";
			var data = "";
			//TODO put todayHigh, todayLow, tomorrowHigh, tomorrowLow into data
	        Background.exit(data);
	    }
	    else
	    { 
	    	Sys.println("response code:" + responseCode);
	    	Sys.println("data:" + data);
       	 	Background.exit("");
	    }
	    //Background.exit(data);
	    //Ui.requestUpdate(); // this will then display the debug variable on the screen.
	}

	function printMemoryStats() {
		var systemStats = Sys.getSystemStats();
        Sys.println(Lang.format("$1$, $2$, $3$", [
            systemStats.freeMemory,
            systemStats.usedMemory,
            1.0 * systemStats.freeMemory / systemStats.totalMemory
        ]));
	}
}
