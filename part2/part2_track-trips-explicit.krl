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
      attrs = event:attrs().klog("Attributes: ")
    }
    fired {
      raise explicit event "trip_processed"
        attributes attrs
    } 
  }

}
