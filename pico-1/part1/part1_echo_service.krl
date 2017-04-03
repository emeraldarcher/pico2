ruleset echo_service {
  meta {
    name "Part 1 - Echo Service"
    description <<
Part 1 of lab
>>
    author "Kyle Cornelison"
    logging on
  }
 
  rule hello {
    select when echo hello
    send_directive("say") with
      something = "Hello World"
  }

  rule message {
    select when echo message
    pre { 
      input = event:attr("input").klog("passed in input: ")
    } 
    send_directive("say") with
      something = input 
  }

}
