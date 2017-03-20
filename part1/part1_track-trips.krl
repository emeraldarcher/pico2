ruleset track_trips {
  meta {
    name "Part 1 - Track Trips"
    description <<
Part 1 of lab
>>
    author "Kyle Cornelison"
    logging on
  }
 
  rule process_trip {
    select when echo message
    pre { 
      mileage = event:attr("mileage").klog("passed in mileage: ")
    } 
    send_directive("trip") with
      trip_length = mileage 
  }

}
