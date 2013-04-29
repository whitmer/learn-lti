oauth = Activity.add(:oauth, :api)
  oauth.intro = <<-EOF
    Make sure you know how to do the oauth dance.
  EOF
  
  oauth.oauth_test :oauth_redirect, :phase => :step_1, :explanation => <<-EOF
    <p>Now let's talk about what to do when you're building
    an app for more than just personal use. We don't allow
    third parties to require users to create access tokens in
    their profile like you've been doing for testing, instead
    when you're ready to go live you're going to need a
    Developer Key for your Canvas instance. You'll use this
    key's id and secret to execute the OAuth "dance" and get
    access tokens for users of your app.</p>
    <p>Step one for OAuth is for you to redirect the user
    to the OAuth endpoint provided by Canvas. There are three
    required parameters that need to be attached to the redirect
    endpoint as query parameters:</p>
    <dl>
      <dt><code>client_id</code></dt>
      <dd>The id provided as part of your Developer Key</dd>
      <dt><code>response_type</code></dt>
      <dd>As per the OAuth spec. This should be <code>code</code></dd>
      <dt><code>redirect_uri</code></dt>
      <dd>When you create a Developer Key you'll provide us with a 
      redirect URI that's used to send people back from Canvas to your
      app when authorized. You can direct to a different URI with this
      parameter if you want, but it has to match the domain of the 
      original URI.</dd>
    <dl>
    <p>Side note for mobile apps: mobile apps don't have a web presence,
    so <code>redirect_uri</code> doesn't make as much sense. For mobile
    apps using OAuth you should specify <code>urn:ietf:wg:oauth:2.0:oob</code>
    as the <code>redirect_uri</code> value. Then the user will be
    redirected to <code>/login/oauth2/auth?code=&lt;code&gt;</code> on
    the Canvas domain, and you'll be responsible to strip the 
    <code>code</code> parameter out of this URL.</p>
    <p>For this test, and for all the tests in this activity,
    you'll be using a different auth endpoint than you would 
    use with Canvas. The workflow is the same, but when you 
    want to talk to Canvas you'll need to get a Developer Key
    and use the Canvas Oauth endpoint rather than the one at <%= host %>. 
    For now, use the URL, id and secret
    specified in the testing box.</p>
    <p>Let's see what you can do. Specify a URL on your site that will 
    trigger the auth process. We'll launch that in an iframe which should
    then redirect to the auth URL specified with the necessary parameters.
    Enter the URL you redirected to when you're done (without the query
    parameters).
    </p>
  EOF
  
  oauth.oauth_test :oauth_return, :phase => :step_2, :explanation => <<-EOF
    <p>In step two of the OAuth dance, the user is going to get redirected
    back to the <code>redirect_uri</code> you provided. If they actually
    authorized your app then they'll hit your endpoint with an additional
    query parameter, <code>code</code>. You want to grab that parameter,
    since you're going to be exchanging it for an access token for
    the user.</p>
  EOF
  
  oauth.oauth_test :access_denied, :phase => :step_2, :pick_access_denied => true, :allow_access_denied => true, :iterations => 5, :explanation => <<-EOF
    <p>Staying on step two for a minute, if someone decides at authorization time
    that they actually don't want to authorize your app, you'll get a 
    different query parameter (this applies for mobile apps as well), 
    <code>error=access_denied</code>. This means the user did not authorize
    your application to make API calls on their behalf.</p>
    <p>At this point you should generate a reasonably-friendly page letting
    the user know that they denied access for your app and that as a result your
    app isn't going to be able to do cool stuff for them. Keep in mind that
    the user may not think anything of it, since all they did was click the
    "Cancel" button, not some giant red "DENY ACCESS" button or anything,
    so you really shouldn't be showing them an angry error page.
    Keep it friendly and give them the option to re-authorize if they want.</p>
    <p>For this test, you're going to go through the first two steps of the 
    OAuth dance five times. Each time you'll either get a code back or an
    "access denied" error. Tell me which you got each time.</p>
  EOF
  
  oauth.oauth_test :oauth_token_exchange, :phase => :step_3, :explanation => <<-EOF
    <p>Now that you've successfully gotten a code, you need to exchange that for
    an actual access token. To do so you're going to make a server-to-server
    POST request to the correct endpoint (for testing it's up in the test box, for
    Canvas it's <code>/login/oauth2/token</code>). You'll need to send along
    the following parameters:</p>
    <dl>
      <dt><code>client_id</code></dt>
      <dd>The id provided as part of your Developer Key</dd>
      <dt><code>redirect_uri</code></dt>
      <dd>This should be exactly the same value as you sent before</dd>
      <dt><code>client_secret</code></dt>
      <dd>The secret provided as part of your Developer Key. Note that you
      didn't send this across before in the initial auth redirect because
      that would <b>expose your secret to end-users</b>, which would be
      bad. Remember to keep this value protected or anyone can impersonate
      your app.</dd>
      <dt><code>code</code></dt>
      <dd>The code you received during the OAuth dance</dd>
    </dl>
    <p>Now go through the whole process and tell me the final access token
    you get back!</p>
  EOF
  
  oauth.local_api_test :logging_out, :logout => true, :explanation => <<-EOF
    <p>You can optionally "log out" using Canvas OAuth as well. If you're done
    using the access token on behalf of a user, it's best practice to log out
    so the token no longer appears in the user's interface. This makes the
    most sense in a mobile environment, when the user clicks "log out" to 
    initiate a different API session, possibly for a different user. If you
    don't log the old user out, it won't correctly clean up the old user.</p>
    <p>To log out, you just do an authenticated API call to 
    <code>/login/oauth2/token</code>. If you succeed you'll get a 200 Ok status
    response. If the logout fails for any reason you'll get a 400-level status,
    along with a <code>message</code> attribute in the response JSON explaining
    the issue.</p>
    <p>For this test just log out of the fake Canvas API using the information
    provided in the test box. Tell me the HTTP status number of the response.</p>
  EOF
  
  oauth.local_api_test :oauth_expired_token, :allow_expired => true, :pick_expired => true, :iterations => 3, :explanation => <<-EOF
    <p>Next let's talk about token expiration and removal. In Canvas a user
    can see all of the applications they've authorized on their behalf on
    their profile page. At any point they can delete the token without your
    knowing. Also, access tokens can potentially expire depending on how they're
    created.</p>
    <p>When a token expires or is deleted, you'll get the same message as if you'd used
    an invalid access token. Either way you're obviously going to need a 
    different token, so you should re-initiate the oauth flow.</p>
    <p>For this test, make an API call to the URL shown in the test box, using
    the access token there as well. Call it
    three times and tell me if the response means your token is expired or not.</p>
  EOF
  
  # TODO: give them a way to check if their access token is still valid
  # oauth.api_test :bad_access_token, :explanation => <<-EOF
  #   <p>
  # EOF
  
  oauth.local_api_test :rate_limits, :allow_throttling => true, :pick_throttled => true, :iterations => 3, :explanation => <<-EOF
    <p>One semi-related topic rate limiting or throttling. Rate limites are defined
    in the terms of use for Canvas and may differ for some open source implementations.
    Throttled requests will return with the HTTP status <code>429 Too Many Requests</code>.
    What to do in the case of rate limiting depends on your terms, and you should
    review the documentation for more details.</p>
    <p>For this test make an API call to the URL shown in the test box, using
    the access token there as well. Call it
    three times and tell me if the response was rate limited or not.</p>
  EOF
