ruleset track_trips_2 {
  meta {
    name "Part 2 - Track Trips"
    description <<
Part 1 of lab
>>
    author "Kyle Cornelison"
    logging on
  }
 
  rule process_trip {
    select when car new_trip
    pre { 
      mileage = event:attr("mileage").klog("passed in mileage: ")
    } 
    send_directive("trip") with
      trip_length = mileage 
  }

}
