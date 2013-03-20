grade_passback = Activity.add(:grade_passback, :lti)
  grade_passback.intro = <<-EOF
    Make sure you know how to pass grades back to the learning platform
  EOF
  
  grade_passback.add_test :outcome_url, :param => :lis_outcome_service_url, :explanation => <<-EOF
    <p>One of the standardized extensions to LTI called the 
    Outcomes Service lets apps send
    scores back to the learning platform's gradebook. Basically the
    learning platform gives the app a callback URL that the app can 
    then POST an XML body to in order to send the scores back.</p>
    <p>Step one is technically a repeat, launch and tell me the
    <code>lis_outcome_service_url</code> URL you get from the learning
    platform. This URL can be considered consistent for any launch
    of your app from the same consumer key and secret, just remember
    that  every configuration
    can potentially have its own URL.</p>
  EOF
  
  grade_passback.add_grade_test :lis_result_sourcedid, :assignment => true, :score => "any", :explanation => <<-EOF
    <p>Once you have the outcome URL then you've got everything you
    need to pass grades back, other than the parameter <code>lis_result_sourcedid</code>,
    which you'll use as a reference for the current user in the current
    course for the current gradebook column.</p>
    <p>What you'll sent back to the learning platform is a POST
    request where the body is XML (
    <a href="https://lti-examples.heroku.com/build_outcome.html">hey look, a nice 
    little builder utility to get you started!</a>) with a 
    <code>Content-Type</code> header of 
    of <code>application/xml</code>, signed using
    <a href="http://oauth.net/core/1.0/#auth_header">OAuth header signatures</a>
    based on the same consumer key and shared secret you used to authorize
    the initial launch. Note: this is different than the way you received
    parameters from the learning platform since those all came across as
    POST multipart/form parameters, but you'll instead be sending auth
    information using the <code>Authorization</code> header, something along
    the lines of <code>OAuth realm="http://sp.example.com/",oauth_consumer_key="0685bd9184jfhq22",oauth_token="ad180jjd733klru7",oauth_signature_method="HMAC-SHA1",oauth_signature="wOJIO9A2W5mFwDgiDvZbTSMK%2FPY%3D",oauth_timestamp="137131200",oauth_nonce="4572616e48616d6d65724c61686176",oauth_version="1.0"</code>.</p>
    <p>For this test, launch your app and use the <code>lis_outcome_service_url</code>
    amd <code>lis_result_sourcedid</code> parameters to send a grade
    back using the <code>resultScore &gt; textString</code> value. 
    Any grade will do, as long as it is properly signed with
    valid XML.</p>
  EOF
  
  grade_passback.add_grade_test :full_credit, :assignment => true, :score => "1", :explanation => <<-EOF
    <p>Now let's get into specifics. Send over a score of 1.0.</p>
    <p>Side note: You've been using the <code>replaceResultRequest</code>
    to set or replace an existing score. There is also the
    <code>readResultRequest</code> for just getting the current value,
    and the <code>deleteResultRequest</code> for clearing the current
    value.</p>
  EOF
  
  grade_passback.add_grade_test :partial_credit, :assignment => true, :score => ".43", :explanation => <<-EOF
    <p>Very good. Now send over a score of 0.43</p>
  EOF

  grade_passback.add_grade_test :submission_text, :assignment => true, :score => "any", :submission_text => "The law will judge you!", :explanation => <<-EOF
    <p>There's also the option within Canvas to send submission content
    in addition to a scalar score value. You can see an example of this
    on our <a href="https://lti-examples.heroku.com/build_outcome.html">outcome
    XML builder</a>. Basically you're adding 
    <code>resultData &gt; text</code> or <code>resultData &gt; url</code>
    to the XML body.</p>
    <p>For this test, send <code>The law will judge you!</code> as the
    <code>resultData &gt; text</code> content.</p>
  EOF
  grade_passback.add_grade_test :submission_url, :assignment => true, :score => "any", :submission_url => "http://www.example.com/horcruxes/8", :explanation => <<-EOF
    <p>Now send <code>http://www.example.com/horcruxes/8</code> as
    the <code>resultData &gt; url</code> content.</p>
  EOF
