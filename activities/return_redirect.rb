return_redirect = Activity.add(:return_redirect)
  return_redirect.intro = <<-EOF
    Make sure you know how to redirect back to the LMS, potentially
    with success or error messages
  EOF

  return_redirect.add_redirect_test :launch_presentation_return_url, :iterations => 3, :explanation => <<-EOF
    <p>When the user is done doing their thing inside an app, 
    typically one of two things happens. Either the apps leads them to some
    terminal page ("Thanks for playing! The end.") or the app can 
    optionally redirect the user back to a return URL provided by the 
    learning platform in the launch. This URL, <code>launch_presentation_return_url</code>
    comes across as a POST parameter.</p>
    <p>Let's make sure you know how to redirect users to this URL
    by doing it three times in a row. Ready, go!</p>
  EOF
  
  return_redirect.add_redirect_test :lti_msg, :lti_return => {:lti_msg => "Most things in here don't react well to bullets."}, :explanation => <<-EOF
    <p>As part of this return process you can optionally provide information
    for either the user to see or for the learning platform to log. To 
    return a message to the user, append the query parameter <code>lti_msg</code>
    to the <code>launch_presentation_return_url</code> and the learning
    platform should display it for the user.</p>
    <p>To make sure you can do this, I want you to redirect to the return
    URL with the message, <code>Most things in here don't react well to bullets.</code>
  EOF
  
  return_redirect.add_redirect_test :lti_log, :include_query_string => true, :lti_return => {:lti_log => "One ping only."}, :explanation => <<-EOF
    <p>Great, so you can send a message to the user. If you want to
    send a message for the learning platform to log without telling 
    the user (say, for logging or I guess secret messages) you append
    the query parameter <code>lti_log</code>.</p>
    <p>Send the log message, <code>One ping only.</code> as a log return message.</p>
    <p>Side note: this return URL, unlike the last one, already has
    a query string included. You should be able to append to the URL
    whether or not it already has a query string.</p>
  EOF

  return_redirect.add_redirect_test :lti_errormsg, :lti_return => {:lti_errormsg => "Who's going to save you, Junior?!"}, :explanation => <<-EOF
    <p>In addition to regular messages you can also send error messages
    with return redirects. User-visible error messages should be sent via 
    the <code>lti_errormsg</code> parameter.</p>
    <p>The question of what happens if you sent both <code>lti_msg</code>
    and <code>lti_errormsg</code> is not defined, but you should probably
    not send error and standard messages in the same return.</p>
    <p>Send the message, <code>Who's going to save you, Junior?!</code> as
    a user-visible error message.</p>
  EOF
  
  return_redirect.add_redirect_test :lti_errorlog, :include_query_string => true, :lti_return => {:lti_errorlog => "The floor's on fire... see... *&* the chair."}, :explanation => <<-EOF
    <p>Last one, <code>lti_errorlog</code>. This is used to log
    server error messages that the user shouldn't see. If you had a
    failed launch for some reason (other than a failed signature,
    in which case you should assume the redirect URL is dangerous)
    or had an unexpected error this would
    probably be the best message to send.</p>
    <p>Send the message, <code>The floor's on fire... see... *&* the chair.</code>
    as a server error message.</p>
  EOF
  
