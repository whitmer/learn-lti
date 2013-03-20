masquerading = Activity.add(:masquerading_and_ids, :api)
  masquerading.intro = <<-EOF
    Make sure you know how to masquerade and use other id-related helpers
  EOF
  masquerading.api_test :masquerading, :answer => "Invalid as_user_id", :explanation => <<-EOF
    <p>The Canvas API lets you make API calls on behalf of other users,
    if you're authorized. There's a permission, "Become other users",
    that needs to be set in the account permissions in order for
    you to use this value.</p>
    <p>Masquerading is simple, you just append a query parameter onto your
    request, <code>as_user_id=&lt;user_id&gt</code>. The user_id will need to
    be someone over whom you have admin access, and will need to be a valid
    it otherwise you'll get an error.</p>
    <p>For this test, since I can't guarantee that you're an admin at some
    school, there's not really a good way to test your ability to masquerade,
    other than for you to try to masquerade as a user_id different than your
    own and tell me the error message you get.</p>
  EOF
  
  masquerading.api_test :sis_ids, :sis_id_test => true, :setup => lambda{|api|
    json = api.get('/api/v1/users/self/profile')
    "user_#{json['id']}"
  }, :lookup => lambda{|api|
    json = api.get('/api/v1/users/self/profile')
    "/api/v1/users/sis_user_id:user_#{json['id']}/profile"
  }, :explanation => <<-EOF
    <p>There are a lot of places in the Canvas API where you are looking up
    users or courses based on IDs. The IDs needed are Canvas-created IDs,
    which is great if you're just using the API, but if you're working from
    another system you may have IDs already in place.</p>
    <p>See, Canvas course and user provisioning typically happens by a
    separate service called a Student Information System (SIS). These systems
    have their own IDs and they send them along to Canvas when provisioning
    users and courses. In other words, Canvas remembers both Canvas IDs and
    SIS-provided IDs, and for most API endpoints you can use either one, 
    whichever is easier for you.</p>
    <p>To use an SIS ID instead of a Canvas ID, you replace 
    <code>&lt;course_id&gt;</code> or <code>&lt;user_id&gt;</code> in the API endpoint with
    <code>sis_course_id:&lt;sis_id&gt;</code>. So to get page views for a user
    whose SIS ID was <code>ABC123</code> you would request the endpoint
    <code>/api/v1/users/sis_user_id:ABC123/page_views</code>.</p>
    <p>For this test, I want you to tell me end endpoint you'd to get
    the profile information for a user with the SIS ID of 
    <code class='setup_result'>...</code>. Start with the first slash,
    don't include the host and protocol (i.e. <code>/api/v1/courses</code>).</p>
    <p>Side note: you can use SIS IDs for masquerading as well. Just change
    <code>as_user_id=&ltuser_id&gt</code> to 
    <code>as_user_id=sis_user_id:&lt;sis_id&gt;</code>.</p>
  EOF
  
  masquerading.api_test :sis_id_hex_encoding, :setup => lambda{|api|
    json = api.get('/api/v1/users/self/profile')
    "#{json['id']}/#{json['primary_email']}"
  }, :lookup => lambda{|api|
    json = api.get('/api/v1/users/self/profile')
    str = "#{json['id']}/#{json['primary_email']}"
    "hex:sis_user_id:" + str.unpack("H*")[0]
  }, :explanation => <<-EOF
    <p>Canvas IDs are always numeric, but SIS IDs can sometimes be some pretty
    crazy strings with non-alphanumeric characters. Often it's not an issue, but 
    if there's any chance you're dealing with SIS IDs containing "/" or "." characters,
    then you're going to need to support the hex encoding format we support for
    complex SIS IDs.</p>
    <p>This is done by converting each UTF-8 byte to a hex-encoded digit and then 
    displayed as ASCII, high nibble first. In ruby, this is easy using 
    <code>str.unpack("H*")[0]</code>. "/" will end up as <code>2f</code>, 
    "." will be <code>2e</code>, "0" becomes <code>30</code>, "1"
    becomes <code>31</code>, etc.</p>
    <p>Once you have the hex value, you enter it as <code>hex:sis_user_id:&lt;sis_id&gt;</code>
    or <code>hex:sis_course_id:&lt;sis_id&gt;</code>, just like you would have
    entered <code>sis_user_id&lt;sis_id&gt;</code> before.</p>
    <p>For this test, I want you to tel me the value you'd enter for
    <code>&lt;user_id&gt;</code> if all you knew were the users's SIS ID,
    <code class='setup_result'>...</code>.</p>
  EOF
  
  
  masquerading.api_test :self_ids, :lookup => lambda {|api|
    json = api.get("/api/v1/users/self/enrollments")
    json[-1]['id'].to_s
  }, :explanation => <<-EOF
    <p>Last, let's make sure we cover one you're already been using. When
    making API calls asking for a <code>&lt;user_id&gt;</code> you can substitube
    <code>self</code> for the user ID. This will then use the ID of the user 
    associated with the current access token. If you use the access token you 
    generated in your profile then it allows you to make requests for your own
    information without having to remember your user ID, but it also applies for
    any other access tokens.</p>
    <p>Let's see if you can use it. Get the 
    <a href="https://canvas.instructure.com/doc/api/all_resources.html#method.enrollments_api.index">list of
    enrollments</a> tied to your personal account and enter the ID of the last enrollment
    provided in the first page of results using the default number of results per page.</p>
  EOF
