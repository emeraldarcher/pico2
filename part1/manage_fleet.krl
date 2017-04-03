ruleset manage_fleet {
  meta {
    name "Manage Fleet"
    description <<Manage Fleet ruleset for part 1 of Pico lab 2>>
    author "Kyle Cornelison"
    logging on
    use module io.picolabs.pico alias wrangler
    shares vehicles, showChildren, __testing
    // provides trips, long_trips, short_trips
    // shares trips, long_trips, short_trips
  }

  global {
    // Get all of the Subscribed Vehicle Picos
    vehicles = function() {
      ent:vehicles.defaultsTo({})
    }

    // Get the Children of the Fleet (this) Pico
    showChildren = function() {
      wrangler:children()
    }

    // Get a Specific Child from the List of Vehicle Picos
    childFromID = function(vehicle_id) {
      ent:vehicles{vehicle_id}
    }

    // Create a Name From the ID
    nameFromID = function(vehicle_id) {
      "Vehicle " + vehicle_id + " Pico"
    }

    // Testing
    __testing = { "queries": [ { "name": "vehicles" },
                              { "name": "showChildren" } ],
                 "events":  [ { "domain": "vehicles", "type": "empty" },
                              { "domain": "car", "type": "new_vehicle",
                                "attrs": [ "vehicle_id" ] },
                              { "domain": "car", "type": "unneeded_vehicle",
                                "attrs": [ "vehicle_id" ] }
                            ]
               }
  }

  // Create New Vehicle Pico - Already Exists
  rule vehicle_already_exists {
    select when car new_vehicle
    pre {
      vehicle_id = event:attr("vehicle_id")
      exists = ent:vehicles >< vehicle_id
    }
    if exists then
      send_directive("vehicle_ready")
        with vehicle_id = vehicle_id
  }

  // Create New Vehicle Pico - Doesn't Exist
  rule create_vehicle {
    select when car new_vehicle
    pre {
      vehicle_id = event:attr("vehicle_id")
      exists = ent:vehicles >< vehicle_id
    }
    if not exists
    then
      noop()
    fired {
      raise pico event "new_child_request"
        attributes { "dname": nameFromID(vehicle_id),
                     "color": "#FF69B4",
                     "vehicle_id": vehicle_id }
    }
  }

  // Save the New Pico Information
  rule pico_child_initialized {
    select when pico child_initialized
    pre {
      the_vehicle = event:attr("new_child")
      vehicle_id = event:attr("rs_attrs"){"vehicle_id"}
    }
    if vehicle_id.klog("found vehicle_id")
    then
      event:send(
        { "eci": the_vehicle.eci, "eid": "install-ruleset",
          "domain": "pico", "type": "new_ruleset",
          //"attrs": { "rid": "track_trips", "vehicle_id": vehicle_id }
          "attrs": { "Prototype_rids": "Subscriptions;track_trips;trip_store", "vehicle_id": vehicle_id }
        }
      )
    fired {
      ent:vehicles := ent:vehicles.defaultsTo({});
      ent:vehicles{[vehicle_id]} := the_vehicle
    }
  }

  // Subscribe to Child/Parent???
  rule create_subscription {
    select when explicit vehicle_created

  }

  // Delete a Vehicle Pico
  rule delete_vehicle {
    select when car unneeded_vehicle
    pre {
      vehicle_id = event:attr("vehicle_id")
      exists = ent:vehicles >< vehicle_id
      eci = meta:eci
      child_to_delete = childFromID(vehicle_id)
    }
    if exists then
      send_directive("vehicle_deleted")
        with vehicle_id = vehicle_id
    fired {
      raise pico event "delete_child_request"
        attributes child_to_delete;
      ent:vehicles{[vehicle_id]} := null
    }
  }

  // Remove all Vehicles in the Fleet
  rule empty_vehicles {
    select when vehicles empty
    always {
      ent:vehicles := {}
    }
  }

}
