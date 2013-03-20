non_get = Activity.add(:non_get, :api)
  non_get.api_test :post_requests, :lookup => lambda{|api|
    root = api.get('/api/v1/users/self/folders/root')
    next_path = "/api/v1/folders/#{root['id']}/folders"
    while next_path
      json = api.get(next_path)
      folder = json.detect{|f| f['name'] == 'grindylow' }
      return folder['id'] if folder
      raise ApiError.new("Couldn't find the folder") unless json.next_url
      next_path = "/" + json.next_url.split(/\//, 4)[-1]
    end
  }, :explanation => <<-EOF
    <p>Now let's get into non-GET requests. Remember, with REST
    you use HTTP verbs for different actions. So in general, POST
    means you're creating something, PUT means you're updating something
    that already exists, and DELETE means you're deleting something
    that already exists.</p>
    <p>Let's start with POST.</p>
    <p>For this test I want you to 
    <a href="https://canvas.instructure.com/doc/api/files.html#method.folders.create">create a folder</a>
    in your personal
    files area in Canvas (<code>/api/v1/users/self/folders</code>)
    with the name of <code>grindylow</code>. If
    you already have a folder in your files area you'll want to rename
    it. When you successfully create the folder, enter its <code>id</code>
    attribute.</p>
  EOF
  
  non_get.api_test :put_requests, :lookup => lambda{|api|
    api.get('/api/v1/users/self/profile')['short_name']
  }, :explanation => <<-EOF
    <p>Awesome, now for a PUT request. Let's update your profile.
    I want you to 
    <a href="https://canvas.instructure.com/doc/api/users.html#method.users.update">change
    you user settings</a> and set your short_name to something other than what
    it is right now, and tell me what you set it to.</p>
    <p>Side note: If your library only supports GET and POST requests,
    it is still possible to make PUT and DELETE requests to Canvas.
    Just make a POST request with the additional parameter, 
    <code>_method=PUT</code></p>
  EOF
  
  non_get.api_test :delete_requests, :setup => lambda{|api|
    user = api.get('/api/v1/users/self/profile')
    user_code = "user_#{user['id']}"
    obj = api.post('/api/v1/calendar_events', {
      'calendar_event[context_code]' => user_code, 
      'calendar_event[title]' => "Delete Me",
      'calendar_event[start_at]' => "2009-01-01",
      'calendar_event[end_at]' => "2009-01-01",
      'calendar_event[location_name]' => "#{user['primary_email']}_#{user['calendar']['ics']}"
    })
    raise ApiError.new('Event creation failed') unless obj['id']
    obj['id']
  }, :lookup => lambda{|api|
    user = api.get('/api/v1/users/self/profile')
    user_code = "user_#{user['id']}"
    list = api.get("/api/v1/calendar_events?context_codes[]=#{user_code}&type=event&start_date=2009-01-01&end_date=2009-01-01")
    event = list.detect{|e| e['title'] == 'Delete Me' }
    raise ApiError.new("Event not deleted") if event
    "#{user['primary_email']}_#{user['calendar']['ics']}"    
  }, :explanation => <<-EOF
    <p>DELETE requests should be more of the same at this point.
    Let's have you delete the calendar event I secret created on
    your personal calendar. You know, the one with the <code>id</code>
    of <code><span class='setup_result'>...</span></code>. Tell me the value of
    the <code>location_name</code> attribute returned for the event
    after it's been deleted.</p>
  EOF
  
  non_get.api_test :create_communication_channel, :lookup => lambda{|api|
    channels = api.get('/api/v1/users/self/communication_channels')
    channel = channels.detect{|c| c['address'] == '8888675309@example.com' && c['type'] == 'sms' }
    raise ApiError.new("Channel not found") if !channel
    channel['id']
  }, :explanation => <<-EOF
    <p>Let's try another request. Add a new communication channel to
    your personal account. Add an SMS channel with the address of
    <code>8888675309@example.com</code>. Tell me the <code>id</code>
    attribute of this new channel.</p>
  EOF
  
  non_get.api_test :update_calendar_event, :setup => lambda{|api|
    user = api.get('/api/v1/users/self/profile')
    user_code = "user_#{user['id']}"
    obj = api.post('/api/v1/calendar_events', {
      'calendar_event[context_code]' => user_code, 
      'calendar_event[title]' => "Ice Cream Party",
      'calendar_event[start_at]' => "2010-02-01",
      'calendar_event[end_at]' => "2010-02-01"
    })
    raise ApiError.new('Event creation failed') unless obj['id']
  }, :lookup => lambda{|api|
    user = api.get('/api/v1/users/self/profile')
    user_code = "user_#{user['id']}"
    list = api.get("/api/v1/calendar_events?context_codes[]=#{user_code}&type=event&start_date=2011-01-31&end_date=2011-02-02")
    raise ApiError.new("Event not found") unless list.length > 0
    e = list.detect{|e| e['title'] == 'Ice Cream Party' }
    raise ApiError.new("Event not found") unless e
    e['id']
  }, :explanation => <<-EOF
    <p>I created a calendar event on February 1, 2010 with the title of
    "Ice Cream Party". Find the event and move it to February 1, 2011.
    Enter the ID of the event when you're done.</p>
  EOF
