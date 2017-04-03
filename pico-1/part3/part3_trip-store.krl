ruleset trip_store {
  meta {
    name "Part 3 - Trip Store"
    description <<
Part 3 of lab
>>
    author "Kyle Cornelison"
    logging on
    provides trips, long_trips, short_trips
    shares trips, long_trips, short_trips
  }

  global {
    trips = function(){
	getTrips()
    }

    long_trips = function() {
 	getLongTrips()
    }

    short_trips = function() {
	allTrips = getTrips();
        longTrips = getLongTrips();

	temp = allTrips.collect(function(trip){(trip{"mileage"} > 1000) => "long" | "short"});
        shortTrips = temp{"short"};
	shortTrips
    }

    clear_trips = [] 
    clear_long_trips = []
  
    getTrips = function() {
      ent:trips
    }

    getLongTrips = function() {
      ent:long_trips
    }
  }
 
  rule collect_trips {
    select when explicit trip_processed
    pre {
      passed_timestamp = event:attr("timestamp").klog("Passed in timestamp: ")
      passed_mileage = event:attr("mileage").klog("Passed in mileage: ")
    }
    send_directive("collect_trips") with
      timestamp = passed_timestamp
      mileage = passed_mileage
    always {
      ent:trips := ent:trips.defaultsTo(clear_trips, "initialization was needed");
      ent:trips := ent:trips.append({"timestamp": passed_timestamp, "mileage": passed_mileage})
    }
  }

  rule collect_long_trips {
    select when explicit found_long_trip
    pre {
      passed_timestamp = event:attr("timestamp").klog("Passed in timestamp: ")
      passed_mileage = event:attr("mileage").klog("Passed in mileage: ")
    }
    send_directive("collect_long_trips") with
      timestamp = passed_timestamp
      mileage = passed_mileage
    always {
      ent:long_trips := ent:long_trips.defaultsTo(clear_trips, "initialization was needed");
      ent:long_trips := ent:long_trips.append({"timestamp": passed_timestamp, "mileage": passed_mileage})
    }
  }

  rule clear_trips {
    select when car trip_reset
    always {
      ent:trips := clear_trips;
      ent:long_trips := clear_long_trips
    }
  }

}
