ruleset manage_fleet {
  meta {
    name "Manage Fleet"
    description <<Manage Fleet ruleset for part 1 of Pico lab 2>>
    author "Kyle Cornelison"
    logging on
    use module Subscriptions
    use module io.picolabs.pico alias wrangler
    shares vehicles, showChildren, __testing, generateReport, reports
    // provides trips, long_trips, short_trips
    // shares trips, long_trips, short_trips
  }

  global {
    // Get all of the Subscribed Vehicle Picos
    vehicles = function() {
      ent:vehicles.defaultsTo({})
    }

    reports = function() {
      ent:reports.defaultsTo({})
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
                              { "name": "showChildren" },
                              { "name": "generateReport" },
                              { "name": "reports" } ],
                 "events":  [ { "domain": "vehicles", "type": "empty" },
                              { "domain": "reports", "type": "empty" },
                              { "domain": "fleet", "type": "create_report",
                                "attrs": [ "cid" ] },
                              { "domain": "reports", "type": "recent"},
                              { "domain": "car", "type": "new_vehicle",
                                "attrs": [ "vehicle_id" ] },
                              { "domain": "car", "type": "unneeded_vehicle",
                                "attrs": [ "vehicle_id" ] }
                            ]
               }

    // Generate Report
    generateReport = function() {
      // Run the report on each vehicle
      r = vehicles().map(function(v,k){
        eci = v{["eci"]};
        Subscriptions:skyQuery("" + eci, "trip_store", "trips")
      });

      // Remove empty reports - Not actually needed
      //r = r.filter(function(v,k){
      //  not (v >< "status")
      //});

      // Final Report
      report = {};

      // Put values into the report
      report = report.put({"vehicles":vehicles().length()});
      report = report.put({"responded": r.length()});
      report = report.put({"trips": r});

      // Display the report
      report.encode()
    }

  }

  // Starts the Process of Generating a Report ::: Scatter-Gather
  rule start_report {
      select when fleet create_report
      foreach vehicles() setting (vehicle)
        pre {
          f_eci = meta:eci
          v_eci = vehicle{["eci"]}
          cid = event:attr("cid")
        }
        event:send(
          { "eci": v_eci, "eid": "get-vehicle-report",
            "domain": "vehicle", "type": "create_report",
            "attrs": { //"vehicle_id": id,
                 "fleet_eci": f_eci,
                 "cid": cid
            }
          }
        )
  }

  // Stores a Vehicle Report
  rule store_report {
    select when fleet store_report
    pre {
      eci = meta:eci
      cid = event:attr("cid")
      vid = event:attr("vid")
      report = event:attr("vehicle_report")
    }
    //event:send(
    //  { "eci": eci, "eid": "check-report",
    //    "domain": "fleet", "type": "report_stored" }
    //)
    always {
      ent:reports := ent:reports.defaultsTo({}, "reports initialization was needed");
      ent:reports{"report " + [cid]} := ent:reports{"report " + [cid]}.defaultsTo({}, "report initialization was needed");
      ent:reports{"report " + [cid]} := ent:reports{"report " + [cid]}.put("vehicle " + [vid], report)
    }
  }

  // Checks the Report's status
  //rule check_report {
  //  select when fleet report_stored
  //  pre {
  //    eci = meta:eci
  //    vechicle_count = vehicles().length()
  //    respond_count = ent:fleet_report.length()
  //  }
  //  if vehicle_count == respond_count then
  //    event:send(
  //      { "eci": eci, "eid": "process-report",
  //        "domain": "fleet", "type": "report_ready" }
  //    )
  //  noop()
  //}

  // Process the Report and Send it Off
  rule process_report {
    select when fleet report_ready
    send_directive("Fleet Report")
      with report = ent:reports
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
    if vehicle_id.klog("found vehicle_id") then
        event:send(
          { "eci": the_vehicle.eci, "eid": "install-ruleset",
            "domain": "pico", "type": "new_ruleset",
            "attrs": { "rid": "Subscriptions", "vehicle_id": vehicle_id }
            //"attrs": { "Prototype_rids": "Subscriptions", "vehicle_id": vehicle_id }
          }
        )
        event:send(
          { "eci": the_vehicle.eci, "eid": "install-ruleset",
            "domain": "pico", "type": "new_ruleset",
            "attrs": { "rid": "track_trips", "vehicle_id": vehicle_id }
          }
        )
        event:send(
          { "eci": the_vehicle.eci, "eid": "install-ruleset",
            "domain": "pico", "type": "new_ruleset",
            "attrs": { "rid": "trip_store", "vehicle_id": vehicle_id }
          }
        )
    fired {
      ent:vehicles := ent:vehicles.defaultsTo({});
      ent:vehicles{[vehicle_id]} := the_vehicle
    }
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

  // Remove all reports
  rule empty_reports {
    select when reports empty
    always {
      ent:reports := {}
    }
  }

  // Returns the n most recent reports
  rule get_latest_reports {
    select when reports recent
    pre {
      keys = ent:reports.keys().reverse().slice(5)
      send = ent:reports.filter(function(v,k){keys >< k})
      json = send.encode()
    }
    send_directive("Recent Reports")
      with reports = json
  }

}
