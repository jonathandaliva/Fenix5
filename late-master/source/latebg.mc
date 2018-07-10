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
    	var URL = "https://www.simplefuckingweatherapi.com/forecast"; 
	    //Sys.println(URL);
	    var params = {
			  "format" => "json",
		};

	    Communications.makeWebRequest(URL, params, {}, method(:onReceiveForcast));
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
