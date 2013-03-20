get = Activity.add(:get_requests, :api)
  get.intro = <<-EOF
    Get you started and make sure you 
    understand how to handle GET requests with the Canvas API. 
  EOF
  
  get.api_test :rest_intro, :answer => :status_code, :explanation => <<-EOF
    <p>REST is cool. It uses standard HTTP verbs instead of things like remote
    procedure calls to access information. It makes it a lot easier to make API
    calls, and if you've APId before then you've almost definitely seen REST
    in action.</p>
    <p>For this test I want you to make a RESTful GET request to an endpoint
    on this testing server and enter the result. Make a GET request to
    <code><%= host %>/api/v1/status</code>. You'll get a JSON response back which you'll
    need to parse, then tell me the value of the attribute <code>code</code> in
    the resulting JSON structure. If you're not sure how to make a GET request,
    just paste the URL into a browser window.</p>
  EOF

  get.api_test :while_1, :lookup => lambda{|api|
    res = api.get("/api/v1/users/self/profile")
    res['id']
  }, :explanation => <<-EOF
    <p>Cross-domain API calls are not allowed in Canvas. There's a layer of security
    we've added to prevent third-party sites from accessing API information using
    sneaky tricks like &lt;script&gt; tags pointing to a Canvas domain to gather
    information (more info here). If you try to make a request to the Canvas API
    from within an authenticated browser, we'll prepend the JSON response with the
    JavaScript code <code>while(1);</code>, which helps prevent attackers from
    pulling out data unwittingly. This shouldn't be an issue, and the while code
    won't be appended if you're using an access token, so in general this shouldn't
    be an issue for you.</p>
    <p>If you're curious you can see this by looking at the raw network traffic in
    your modern browser's debugger.</p>
    <p>Even if you're not curious, we're now going to use your browser's debugger
    to make our first API call to the actual Canvas API. Open up the JavaScript
    console in your browser and enter the following code:
    <code>$.getJSON("/api/v1/users/self/profile", function(data) { console.log(data); })</code>.
    After a second you'll see a data structure returned in your console. Browse through
    it and enter the value for the <code>id</code> attribute.</p>
  EOF
  
  get.api_test :error_handling, :answer => "You are not authorized to perform that action.", :explanation => <<-EOF
    <p>Canvas API has some error messages. I'll be the first to admin they're
    not always as valuable or awesome as they could be. We're working on that. In
    the mean time, let's go through the error messages, how to run into each one
    and what each one means.</p>
    <p>First, <code>404 Not Found</code>. Run the following code in your
    browser's debugger: <code>$.getJSON("/api/v1/users/self/profilex", function(data) { console.log(data); })</code>.
    You should see a response show up in your console with a <code>status</code> value
    of <code>not_found</code> and a <code>message</code> of <code>An error occurred.</code>.
    This error typically happens when you have an invalid endpoint. In this case, the endpoint
    should be "profile", not "profilex". Note that you should be treating this
    as an error <b>not because it has a status or error_report_id attribute</b>, but because
    the HTTP Status header of the response was not in the 200-range.</p>
    <p>Side note: If you're really struggling, the <code>error_report_id</code> attribute
    gives you an error code you can use to help troubleshoot. If you're on a local instance
    this is the database id you should look up in the error_reports table. If you're in
    the cloud, you can share this with an Instructure employee for more detailed help.</p>
    <p>Next, let's look at <code>401 Authorization Required</code>. Run the following
    code: <code>$.getJSON("/api/v1/users/230519/profile", function(data) { console.log(data); })</code>.
    The response status should be 401 (Unauthorized) unless you're somehow associated 
    with this user. The <code>status</code> attribute should be <code>unauthorized</code>, 
    and the <code>message</code> should be <code>You are not authorized to perform that action.</code>
    This message happens if you try to access a resource for which you don't have permission.
    If this happens you should make sure you're using the right access token and that the
    user actually has correct permissions.</p>
    <p>Ok, next comes another <code>404 Not Found</code>. Run this code:
    <code>$.getJSON("/api/v1/users/0/profile", function(data) { console.log(data); })</code>.
    You should get a 404 again this time with a <code>status</code> of <code>not_found</code>
    and a <code>message</code> of <code>The specified resource does not exist.</code> This
    happens typically when you have a bad id (in this case, there is no user with the id of 0).
    <p>
    <p>Last, another <code>401 Not Authorized</code>. Run this code:
    <code>$.getJSON("/api/v1/users/self/profile?access_token=asdf", function(data) { console.log(data); })</code>.
    You'll get a 401 again with a <code>status</code> of <code>unauthorized</code>
    and a <code>message</code> of <code>Invalid access token.</code>. This happens when
    you have an invalid or expired access token.</p>
    <p>There are other cases where you'll get less-useful errors. Run this code:
    <code>$.ajaxJSON("/api/v1/courses/{{ course_id }}/assignments", 'POST', {}, function(data) {}, function(data) { console.log(data); });</code>
    You will get a response back with the body of <code>"error"</code>. It's valid JSON,
    but it's not a JSON object. This is unfortunate and embarrassing, and I'm hoping we
    get this fixed before this lesson goes live, but if not, sorry. When you hit one
    of these errors there's not much more we can do to help with troubleshooting. You may
    have a bad parameter or be missing a required parameter, but it also just might be
    a temporary problem with the API service.</p>
    <p>For this test, run the following code:
    <code>$.getJSON("/api/v1/courses/123/external_feeds", function(data) { console.log(data); })</code> 
    and tell me the value of the <code>message</code> attribute.</p>
  EOF
  
  get.api_test :https, :answer => "https", :explanation => <<-EOF
    <p>Freebie. All Canvas API calls should be executed over https (SSL). There are a 
    lot of reasons why this is a good idea in general, but for Canvas it is a requirement.
    If you try to make an http API call you will be redirected to https.<p>
    <p>So now the question. Which protocol should you use for Canvas API calls, http
    or https?</p>
  EOF
  
  get.api_test :access_token, :lookup => lambda{|api|
    res = api.get("/api/v1/users/self/profile")
    res['calendar']['ics']
  }, :explanation => <<-EOF
    <p>Now let's start getting to the good stuff. Up to now we've been making API calls
    via the developer console in your browser. Now I'm going to take a leap of faith and
    assume you're going to follow my next piece of advice. Technically you could pass
    all the API tests using just your browser. But if you really want to be a Canvas
    API developer you should now move to your programming language of choice and start
    making calls using whatever libraries you need there.</p>
    <p>To get started down that path we need to get you an access token. Later on down
    the line we'll work through the oauth flow in its entirety so you know how to get
    access tokens on behalf of your users. But for now you're going to be making API calls
    just for yourself, so we can short-circuit the OAuth dance by generating a token
    by hand. Go to your profile page in Canvas and generate an access token at the
    bottom of that page using the interface provided. You can use this token for most of the
    rest of the lessons and activities around API.</p>
    <p>Once you've got an access token, make an API call using your backend server to
    <code>/api/v1/users/self/profile?access_token=&lt;your_access_token&gt;</code> (the
    domain will be whatever domain you use to log in to Canvas, probably 
    canvas.instructure.com). Tell
    me what you get back for the <code>calendar -&gt; ics </code> attribute.</p>
  EOF
  
  get.api_test :get_courses, :lookup => lambda{|api|
    res = api.get("/api/v1/courses")
    raise ApiError.new("You must be enrolled in at least one course before running this lesson") unless res[0]
    res[0]['id']
  }, :explanation => <<-EOF
    <p>Sweet, let's get moving now. For this next endpoint you'll need to be
    enrolled in at least one course. If you're not, go create one and you should
    be auto-enrolled as an instructor.</p>
    <p>I want you to get the 
    <a href="https://canvas.instructure.com/doc/api/courses.html#method.courses.index">list of courses you're enrolled in</a> 
    and tell
    me the <code>id</code> of the first course returned by the API call.</p>
  EOF
  
  get.api_test :filtering, :lookup => lambda{|api|
    user = api.get('/api/v1/users/self/profile')
    user_code = "user_#{user['id']}"
    list = api.get("/api/v1/calendar_events?context_codes[]=#{user_code}&type=event&start_date=2010-12-31&end_date=2011-01-02")
    raise ApiError.new("Event not found") unless list.length > 0
    e = list.select{|e| e['title'] == 'API Test Event' }[0]
    raise ApiError.new("Event not found") unless e
    e['id']
  }, :setup => lambda{|api|
    user = api.get('/api/v1/users/self/profile')
    user_code = "user_#{user['id']}"
    list = api.get("/api/v1/calendar_events?context_codes[]=#{user_code}&type=event&start_date=2010-12-31&end_date=2011-01-02")
    list.each do |e|
      if e['title'] == 'API Test Event'
        res = api.delete('/api/v1/calendar_events/' + e['id'].to_s)
      end
    end
    obj = api.post('/api/v1/calendar_events', {
      'calendar_event[context_code]' => user_code, 
      'calendar_event[title]' => "API Test Event",
      'calendar_event[start_at]' => "2011-01-01",
      'calendar_event[end_at]' => "2011-01-01"
    })
    raise ApiError.new('Event creation failed') unless obj['id']
    true
  }, :explanation => <<-EOF
    <p>Some API endpoints allow for filtering based on criteria. To filter you'll
    just be adding additional query parameters on to the end of the URL. For example,
    <a href="https://canvas.instructure.com/doc/api/courses.html#method.courses.index">the course list endpoint</a> 
    you just used has an optional parameter that lets you filter to see only
    users with a certain role. If you made a request to
    <code>/api/v1/courses?enrollment_type=ta&access_token=&lt;your_access_token&gt;</code>
    then you'd get back the list of all those courses in which you were a TA. Fancy, huh?
    Most filters only apply to GET requests and allow you slice the data in ways that
    make it more valuable.</p>
    <p>For this test I've created an event on your personal calendar set back on
    January 1, 2011 called "API Test Event". I want you to get the <code>id</code> of that event using
    the date and type filtering available on
    <a href="https://canvas.instructure.com/doc/api/all_resources.html#method.calendar_events_api.index">the
    calendar list endpoint</a>.
  EOF
  
  get.api_test :includes, :lookup => lambda{|api|
    res = api.get("/api/v1/users/self/favorites/courses?include[]=term")
    res[0]['term']['id']
  }, :explanation => <<-EOF
    <p>Now let's talk about includes. Some API endpoints include optional information
    only if specified. For example, the courses endpoint you just used can optionally
    return total scores and grades for each course in which you're a student. On the
    assignment groups endpoint you can also optionally get back the assignments
    included in each group. Basically anywhere you see the <code>include[]</code>
    request parameter, there are optional values that can be used.</p>
    <p>The notation for includes may be something you haven't seen before ("what's the 
    [] at the end doing?"). This is a notation we use to allow sending multiple
    parameters with the same value in a single request. So you could have a request like
    <code>/api/v1/courses?include[]=syllabus_body&include[]=total_scores</code> to
    include multiple optional values in the same response. You'll see this [] notation
    used a few other places in the API as well, for the same reason. Basically it's a hint
    to our system that you're sending back an array of values instead of a single
    value.</p>
    <p>For this test I want you to get the <code>term -&gt; id</code> attribute
    that is optionally returned when using the
    <a href="https://canvas.instructure.com/doc/api/all_resources.html#method.favorites.list_favorite_courses">course
    favorites list endpoint</a> for the first course in your list.</p>
  EOF
  
  get.api_test :another_get, :lookup => lambda{|api|
    res = api.get "/api/v1/users/self/communication_channels"
    res[0]['id']
  }, :explanation => <<-EOF
    <p>This should hopefully be getting easier. For our last GET request I want you
    to tell me the <code>id</code> of the first communication channel returned when
    querying your 
    <a href="https://canvas.instructure.com/doc/api/communication_channels.html#method.communication_channels.index">list
    of communication channels</a> (hint: set <code>:user_id</code> to <code>self</code> to
    get results for whoever is the current user -- in this case, you).</p>
  EOF