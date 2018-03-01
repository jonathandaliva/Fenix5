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
    	//var now=Sys.getClockTime();
    	//var ts=now.hour+":"+now.min.format("%02d");
        //Sys.println("bg exit: "+ts);
        //just return the timestamp
        //Draw forcast //TODO need to update this to pull location based on IP then pass that to openweathermap
		//var latLon = Toybox.Position.info.position.toDegrees();
		//https://api.darksky.net/forecast/dec84d9b5c99a82a25e386b2257cf9b0/37.8267,-122.4233?exclude=currently,minutely,hourly,alerts,flags
		Communications.makeWebRequest("https://freegeoip.net/json/", {"format" => "json"}, {}, method(:onReceiveLocation));
		/*
		var params = {
		  "format" => "json",
		  "lat" => "39.174801",
		  "lon" => "-100.532600"
		};
		Communications.makeWebRequest("https://www.simplefuckingweatherapi.com/greeting", params, {}, method(:onReceiveForcast));
		*/
		//Communications.makeWebRequest("https://api.wunderground.com/api/673c015c876b7115/planner_02170218/q/VA/Sterling.json", {"format" => "json"}, {}, method(:onReceiveLocation));
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
        //Sys.println("location data received");
        //printMemoryStats();
	    if( responseCode == 200 )
	    {
	        //Sys.println("Location data ok 200");	
	        //Sys.println(data);
	        var mystring = "" + data;
	        data = "";
	        /*
	        var index = mystring.find("region_code=>");
	        var region_code = mystring.substring(index + 13,  index + 15);
	        index = mystring.find("zip_code=>");
	        var zip_code = mystring.substring(index + 10,  index + 15);
	        data = region_code + "/" + zip_code;
	        */
	        var lon = getJsonObject(mystring,"longitude=>");
	        //Sys.println("lon: " + lon);
	        
	        var lat = getJsonObject(mystring,"latitude=>");
	        //Sys.println("lat: " + lat);
	        mystring = "";
	        //var AppID="673c015c876b7115";
	        //var AppID="f175ed51e7c728ca4b30395693a24d34";
	        //http://api.wunderground.com/api/673c015c876b7115/forecast/q/VA/Leesburg.json
	        //var URL = "https://api.openweathermap.org/data/2.5/forecast?zip=" + data + "&APPID=" + AppID + "&units=imperial";
	        //var URL = "https://api.wunderground.com/api/" + AppID + "/forecast/q/" + data + ".json";
	        var URL = "https://www.simplefuckingweatherapi.com/greeting"; 
	        //Sys.println(URL);
	        var params = {
			  "format" => "json",
			  "lat" => lat,
			  "lon" => lon
			};
			//Sys.println(params);
	        //printMemoryStats();
	        Communications.makeWebRequest(URL, params, {}, method(:onReceiveForcast));
	        //Background.exit("");
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
        //Sys.println("forcast data received");
	    if( responseCode == 200 )
	    {
	        //Sys.println("Forcast data ok 200");	
	        //Sys.println(data);
	        var mystring = "" + data;
	        data = "";
	        var validResponse = getJsonObject(mystring,"validResponse=>");
	        //if (validResponse instanceof Boolean) {
		        if ( validResponse ) {
		        	Sys.println("Forcast API returned good data");
			        var todayHigh = getJsonObject(mystring,"tdyHigh=>");
			        var todayLow = getJsonObject(mystring,"tdyLow=>");
			        var todayDesc = getJsonObject(mystring,"tdyDesc=>");
			        var tomorrowHigh = getJsonObject(mystring,"tmwHigh=>");
			        var tomorrowLow = getJsonObject(mystring,"tmwLow=>");
			        var tomorrowDesc = getJsonObject(mystring,"tmwDesc=>");
					data = todayHigh + "," + todayLow + "," + todayDesc + "," + tomorrowHigh + "," + tomorrowLow + "," + tomorrowDesc;
					//Sys.println(data);
				}
			//}
			mystring = "";
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
	
	function getJsonObject(jsonString, fieldName) {
		var index = jsonString.find(fieldName);
		jsonString = jsonString.substring(index + fieldName.length(),  jsonString.length());
		index = jsonString.find(",");
	    if (index == null) {
			index = jsonString.find("}");
			if (index == null) {
				index = jsonString.length();
			}
		}
		var fieldValue = jsonString.substring(0,  index);
		jsonString = "";
		return fieldValue;
	}
}
