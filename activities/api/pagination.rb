pagination = Activity.add(:pagination, :api)
  pagination.intro = <<-EOF
    Make sure you know how pagination works in Canvas API results
  EOF
  
  pagination.api_test :pagination_header, :setup => lambda{|api|
    json = api.get('/api/v1/users/self/page_views?per_page=10000')
    raise ApiError.new("Not enough page views. You need to spend more time in Canvas before you can pass this test.") if !json.next_url
  }, :lookup => lambda{|api|
    json = api.get('/api/v1/users/self/page_views')
    json.link
  }, :explanation => <<-EOF
    <p>Some API endpoints in Canvas use a technique called 
    <a href="https://canvas.instructure.com/doc/api/file.pagination.html">pagination</a>.
    Basically if there are potentially a lot of results that could
    be returned, we return them in chunks rather than all at once. This
    keeps us from maxing out our server queue, but does take a little
    awareness on your side. For the most part it shouldn't be too
    much of an issue, but there will probably be places where a couple
    API calls are required in order to get a full list, so don't forget
    about pagination.</p>
    <p>Basically any endpoint that returns a list of JSON objects
    should be considered a candidate for pagination, whether or not
    the API docs actually say it's currently paginated.</p>
    <p>Pagination is supported in the Canvas API using the <code>Link</code>
    header. You should watch for this header when making API calls.
    <i>It's not uncommon for people to get frustrated that they're not
    getting back all the results they want, only to realize they are
    failing to check for pagination</i>.</p>
    <p>For this test, I want you to paste the string you get as the <code>Link</code>
    header value when making a Canvas API call to 
    <code><%= @api_host %>/api/v1/users/self/page_views</code>. This header is
    what is parsed to get the URL for the next page of results.</p>
  EOF
  
  pagination.api_test :next_url, :setup => lambda{|api|
    user = api.get('/api/v1/users/self/profile')
    user_code = "user_#{user['id']}"
    3.times do |i|
      obj = api.post('/api/v1/calendar_events', {
        'calendar_event[context_code]' => user_code, 
        'calendar_event[title]' => "Pagination Event #{i}",
        'calendar_event[start_at]' => "2010-01-01",
        'calendar_event[end_at]' => "2010-01-01"
      })
      raise ApiError("Event not created") unless obj['id']
    end
  }, :lookup => lambda{|api|
    user = api.get('/api/v1/users/self/profile')
    user_code = "user_#{user['id']}"
    list = api.get("/api/v1/calendar_events?type=event&start_date=2010-01-01&end_date=2010-01-01&per_page=1")
    list.next_url
  }, :explanation => <<-EOF
    <p>Now that you've got the <code>Link</code> parameter pulled out,
    let's get it parsed. Repeat explanation below:</p>
    <p>The format for the <code>Link</code> header is:
    <code>URL; rel="value", URL; rel="value", etc.</code>. The easiest
    thing to do is find a library that will parse this HTTP standard on
    your behalf. If that's not an option, you can split the string on commas
    to get a list of URLs and their matching values looking something like
    <code>http://www.example.com?page=1; rel="first"</code>. For pagination
    you're mostly concerned with the <code>rel="next"</code> link, since that's
    what you'll call to get the next list of results.</p>
    <p>For this test, you need to make an api call to
    <code><%= @api_host %>/api/v1/calendar_events?type=event&start_date=2010-01-01&end_date=2010-01-01&per_page=1</code> 
    and enter the URL of the
    <code>rel="next"</code> result.</p>
  EOF
  
  pagination.api_test :per_page, :lookup => lambda{|api|
    api.get('/api/v1/users/self/page_views?per_page=1000000').length.to_s
  }, :explanation => <<-EOF
    <p>There's another option you should be aware of related to
    pagination, and that's the <code>per_page</code> parameter. This
    parameter lets you specify how many results you want to get on each
    "page", or API result set.</p>
    <p>Right now you're likely thinking, "sweet, I'll just set per_page
    to 100000000 and never worry about pagination again!" Sorry, it
    doesn't work like that. Different endpoints have different pagination
    maxes to keep from filling our request queues with lots of long
    requests (remember, that's the whole point of pagination in the
    first place). So if you set <code>per_page=1000000</code> then Canvas will
    interpret that as <code>per_page=10</code> or <code>per_page=50</code>
    or some other value, depending on the endpoint.</p>
    <p>For this test I want you to tell me what's the maximum number 
    of records you can get back on a single page when using the 
    <a href="https://canvas.instructure.com/doc/api/users.html#method.page_views.index">user
    page views endpoint</a>.</p>
  EOF
  
  pagination.api_test :find_page_view, :setup => lambda{|api|
    json = api.get('/api/v1/users/self/page_views?per_page=1000000')
    raise "Not enough page views" unless json.next_url
    json = api.get("/" + json.next_url.split(/\//, 4)[-1])
    raise "Not enough page views" unless json.length > 3
    puts json[3].to_json
    json[3]['request_id']
  }, :lookup => lambda{|api|
    json = api.get('/api/v1/users/self/page_views?per_page=1000000')
    json = api.get("/" + json.next_url.split(/\//, 4)[-1])
    json[3]['url']
  }, :explanation => <<-EOF
    <p>Ok, let's put these skills to really good use. One of the page views
    in your personal account has the <code>request_id</code> of 
    <code class="setup_result">...</code>. Find this page view and tell
    me the value of its <code>url</code> attribute.</p>
  EOF
