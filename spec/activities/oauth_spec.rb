require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'OAuth Tests' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  it "should succeed when step 1 is correctly run" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/0", {}
    post "/oauth_start/oauth/0", {'url' => 'http://www.example.com/login'}
    last_response.location.should == 'http://www.example.com/login'
    path = "/login/oauth2/auth?client_id=#{@user.id}&response_type=code&redirect_uri=#{CGI.escape("http://www.example.com/auth")}"
    get path
    @user.reload
    last_response.location.should == "http://www.example.com/auth?code=#{@user.settings['fake_code']}"
    post "/validate/oauth/0", {'answer' => 'http://example.org/login/oauth2/auth'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  
  it "should fail when step 1 skips the launch step" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/0", {}
    path = "/login/oauth2/auth?client_id=#{@user.id}&response_type=code&redirect_uri=#{CGI.escape("http://www.example.com/auth")}"
    get path
    @user.reload
    last_response.body.should == "Missing the launch step"
    post "/validate/oauth/0", {'answer' => 'http://example.org/login/oauth2/auth'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
  it "should fail when step 1 hasn't happened yet" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/0", {}
    post "/validate/oauth/0", {'answer' => 'http://example.org/login/oauth2/auth'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
    json['answer'].should == 'http://example.org/login/oauth2/auth (plus hitting this endpoint)'
  end
  
  it "should fail when the wrong value is entered for step 1" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/0", {}
    post "/oauth_start/oauth/0", {'url' => 'http://www.example.com/login'}
    last_response.location.should == 'http://www.example.com/login'
    path = "/login/oauth2/auth?client_id=#{@user.id}&response_type=code&redirect_uri=#{CGI.escape("http://www.example.com/auth")}"
    get path
    @user.reload
    last_response.location.should == "http://www.example.com/auth?code=#{@user.settings['fake_code']}"
    post "/validate/oauth/0", {'answer' => 'http://example.org/login/oauth2/auth/'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
    json['answer'].should == 'http://example.org/login/oauth2/auth (plus hitting this endpoint)'
  end
  
  it "should succeed when code is correctly retrieved for step 2" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/1", {}
    post "/oauth_start/oauth/1", {'url' => 'http://www.example.com/login'}
    last_response.location.should == 'http://www.example.com/login'
    path = "/login/oauth2/auth?client_id=#{@user.id}&response_type=code&redirect_uri=#{CGI.escape("http://www.example.com/auth")}"
    get path
    @user.reload
    last_response.location.should == "http://www.example.com/auth?code=#{@user.settings['fake_code']}"
    post "/validate/oauth/1", {'answer' => @user.settings['fake_code']}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
    json['answer'].should == @user.settings['fake_code']
  end
  
  it "should fail when incorrect code is retrieved for step 2" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/1", {}
    post "/oauth_start/oauth/1", {'url' => 'http://www.example.com/login'}
    last_response.location.should == 'http://www.example.com/login'
    path = "/login/oauth2/auth?client_id=#{@user.id}&response_type=code&redirect_uri=#{CGI.escape("http://www.example.com/auth")}"
    get path
    @user.reload
    last_response.location.should == "http://www.example.com/auth?code=#{@user.settings['fake_code']}"
    post "/validate/oauth/1", {'answer' => "aaa"}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
    json['answer'].should == @user.settings['fake_code']
  end
  
  it "should not have the correct code unless step 2 is finished" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/1", {}
    post "/oauth_start/oauth/1", {'url' => 'http://www.example.com/login'}
    last_response.location.should == 'http://www.example.com/login'
    @user.reload.settings['fake_code'].should == nil
    post "/validate/oauth/1", {'answer' => ""}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
    json['error'].should == "still waiting for auth step..."
  end
  
  it "should correctly check for access denied" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/2", {}
    Samplers.should_receive(:random).with(2).and_return(0)
    post "/oauth_start/oauth/2", {'url' => 'http://www.example.com/login'}
    session['access_denied'].should == true
    last_response.location.should == 'http://www.example.com/login'
    path = "/login/oauth2/auth?client_id=#{@user.id}&response_type=code&redirect_uri=#{CGI.escape("http://www.example.com/auth")}"
    get path
    @user.reload
    last_response.location.should == "http://www.example.com/auth?error=access_denied"
    post "/validate/oauth/2", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
    json['valid'].should == false
  end
  
  it "should correctly check for no access denied" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/2", {}
    Samplers.should_receive(:random).with(2).and_return(1)
    post "/oauth_start/oauth/2", {'url' => 'http://www.example.com/login'}
    session['access_denied'].should == false
    last_response.location.should == 'http://www.example.com/login'
    path = "/login/oauth2/auth?client_id=#{@user.id}&response_type=code&redirect_uri=#{CGI.escape("http://www.example.com/auth")}"
    get path
    @user.reload
    last_response.location.should == "http://www.example.com/auth?code=#{@user.settings['fake_code']}"
    post "/validate/oauth/2", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
    json['valid'].should == true
  end
  
  it "should succeed when token is correctly retrieved for step 3" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/3", {}
    post "/oauth_start/oauth/3", {'url' => 'http://www.example.com/login'}
    last_response.location.should == 'http://www.example.com/login'
    path = "/login/oauth2/auth?client_id=#{@user.id}&response_type=code&redirect_uri=#{CGI.escape("http://www.example.com/auth")}"
    get path
    @user.reload
    last_response.location.should == "http://www.example.com/auth?code=#{@user.settings['fake_code']}"
    post "/login/oauth2/token", {'redirect_uri' => "http://www.example.com/auth", 'client_id' => @user.id.to_s, 'client_secret' => @user.settings['fake_secret'], 'code' => @user.settings['fake_code']}
    json = JSON.parse(last_response.body)
    json['access_token'].should == @user.reload.settings['fake_token']
    post "/validate/oauth/3", {'answer' => json['access_token']}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  
  it "should fail when incorrect token is entered for step 3" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/3", {}
    post "/oauth_start/oauth/3", {'url' => 'http://www.example.com/login'}
    last_response.location.should == 'http://www.example.com/login'
    path = "/login/oauth2/auth?client_id=#{@user.id}&response_type=code&redirect_uri=#{CGI.escape("http://www.example.com/auth")}"
    get path
    @user.reload
    last_response.location.should == "http://www.example.com/auth?code=#{@user.settings['fake_code']}"
    post "/login/oauth2/token", {'redirect_uri' => "http://www.example.com/auth", 'client_id' => @user.id.to_s, 'client_secret' => @user.settings['fake_secret'], 'code' => @user.settings['fake_code']}
    json = JSON.parse(last_response.body)
    json['access_token'].should == @user.reload.settings['fake_token']
    post "/validate/oauth/3", {'answer' => 'zzz'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
    json['answer'].should == @user.settings['fake_token']
  end
  
  it "should not have the correct token unless step 3 is completed" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/3", {}
    post "/oauth_start/oauth/3", {'url' => 'http://www.example.com/login'}
    @user.reload.settings['fake_token'].should be_nil
    last_response.location.should == 'http://www.example.com/login'
    path = "/login/oauth2/auth?client_id=#{@user.id}&response_type=code&redirect_uri=#{CGI.escape("http://www.example.com/auth")}"
    get path
    @user.reload
    last_response.location.should == "http://www.example.com/auth?code=#{@user.settings['fake_code']}"
    @user.reload.settings['fake_token'].should be_nil
    post "/validate/oauth/3", {'answer' => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
    json['error'].should == 'still waiting for token exchange...'
  end
  
  it "should succeed when logout happens correctly" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/4", {}
    delete "/login/oauth2/token", {'access_token' => @user.settings['fake_token']}
    last_response.should be_ok
    post "/validate/oauth/4", {'answer' => "200"}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  
  it "should fail when logout hasn't happened correctly" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/4", {}
    post "/validate/oauth/4", {'answer' => "200"}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
    json['answer'].should == "200 (plus correctly logging out)"
  end
  
  it "should check for correctly expired access tokens" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/5", {}
    
    get "/api/v1/secret/oauth/5/#{@user.id}/#{@user.settings['verification']}", {'access_token' => 'zzz'}
    last_response.body.should == 'Invalid access token'
    Samplers.should_receive(:random).with(2).and_return(0)
    get "/api/v1/secret/oauth/5/#{@user.id}/#{@user.settings['verification']}", {'access_token' => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    json['status'].should == 'unauthorized'
    post "/validate/oauth/5", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  
  it "should succeed when access token isn't expired" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/5", {}
    
    get "/api/v1/secret/oauth/5/#{@user.id}/#{@user.settings['verification']}", {'access_token' => 'zzz'}
    last_response.body.should == 'Invalid access token'
    Samplers.should_receive(:random).with(2).and_return(1)
    get "/api/v1/secret/oauth/5/#{@user.id}/#{@user.settings['verification']}", {'access_token' => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    json['secret'].should_not be_nil
    post "/validate/oauth/5", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  
  it "should fail when the user thinks expiration happened but it hasn't" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/5", {}
    
    get "/api/v1/secret/oauth/5/#{@user.id}/#{@user.settings['verification']}", {'access_token' => 'zzz'}
    last_response.body.should == 'Invalid access token'
    Samplers.should_receive(:random).with(2).and_return(1)
    get "/api/v1/secret/oauth/5/#{@user.id}/#{@user.settings['verification']}", {'access_token' => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    json['secret'].should_not be_nil
    post "/validate/oauth/5", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
  it "should fail when the user misses expiration response" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/5", {}
    
    get "/api/v1/secret/oauth/5/#{@user.id}/#{@user.settings['verification']}", {'access_token' => 'zzz'}
    last_response.body.should == 'Invalid access token'
    Samplers.should_receive(:random).with(2).and_return(0)
    get "/api/v1/secret/oauth/5/#{@user.id}/#{@user.settings['verification']}", {'access_token' => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    json['status'].should == 'unauthorized'
    post "/validate/oauth/5", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
  it "should check for correctly throttled requests" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/6", {}
    
    get "/api/v1/secret/oauth/6/#{@user.id}/#{@user.settings['verification']}", {'access_token' => 'zzz'}
    last_response.body.should == 'Invalid access token'
    Samplers.should_receive(:random).with(2).and_return(0)
    get "/api/v1/secret/oauth/6/#{@user.id}/#{@user.settings['verification']}", {'access_token' => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    json['status'].should == 'throttled'
    post "/validate/oauth/6", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  
  it "should succeed when not throttled" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/6", {}
    
    get "/api/v1/secret/oauth/6/#{@user.id}/#{@user.settings['verification']}", {'access_token' => 'zzz'}
    last_response.body.should == 'Invalid access token'
    Samplers.should_receive(:random).with(2).and_return(1)
    get "/api/v1/secret/oauth/6/#{@user.id}/#{@user.settings['verification']}", {'access_token' => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    json['secret'].should_not be_nil
    post "/validate/oauth/6", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  
  it "should fail when the user things throttling has happened but it hasn't" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/6", {}
    
    get "/api/v1/secret/oauth/6/#{@user.id}/#{@user.settings['verification']}", {'access_token' => 'zzz'}
    last_response.body.should == 'Invalid access token'
    Samplers.should_receive(:random).with(2).and_return(1)
    get "/api/v1/secret/oauth/6/#{@user.id}/#{@user.settings['verification']}", {'access_token' => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    json['secret'].should_not be_nil
    post "/validate/oauth/6", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
  it "should fail when the user misses throttling response" do
    fake_launch({'farthest_for_oauth' => 10})
    get "/launch/oauth/6", {}
    
    get "/api/v1/secret/oauth/6/#{@user.id}/#{@user.settings['verification']}", {'access_token' => 'zzz'}
    last_response.body.should == 'Invalid access token'
    Samplers.should_receive(:random).with(2).and_return(0)
    get "/api/v1/secret/oauth/6/#{@user.id}/#{@user.settings['verification']}", {'access_token' => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    json['status'].should == 'throttled'
    post "/validate/oauth/6", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
  context "oauth_start" do
    it "should require user"
    it "should redirect to the specified url"
    it "should remember the url and generate a random token"
  end
  
  context "login" do
    it "should show status page on code or error (mobile results"
    it "should require client id and other parameters"
    it "should store the randome token from oauth_start for verification"
    it "should send code on success"
    it "should send error on failure"
  end
  
  context "token exchange" do
    it "should require all parameters"
    it "should change token information"
    it "should return the token"
  end
  
  context "logout" do
    it "should require valid user token"
    it "should delete token information"
  end
  
  context "secret api call" do
    it "should return 400 on expired request"
    it "should return 429 on throttled request"
    it "should return secret on success"
  end
  
  context "validate" do
    it "should require user information"
    it "should check for random token on step_1"
    it "should check for correct answer on step_1"
    it "should check for access_denied on step_2"
    it "should check for correct code on step_2"
    it "should check for correct token on step_3"
  end
end

# 
# oauth = Activity.add(:oauth, :api)
#   oauth.intro = <<-EOF
#     Make sure you know how to do the oauth dance.
#   EOF
#   
#   oauth.oauth_test :oauth_redirect, :phase => :step_1, :explanation => <<-EOF
#     <p>Now let's talk about what to do when you're building
#     an app for more than just personal use. We don't allow
#     third parties to require users to create access tokens in
#     their profile like you've been doing for testing, instead
#     when you're ready to go live you're going to need a
#     Developer Key for your Canvas instance. You'll use this
#     key's id and secret to execute the OAuth "dance" and get
#     access tokens for users of your app.</p>
#     <p>Step one for OAuth is for you to redirect the user
#     to the OAuth endpoint provided by Canvas. There are three
#     required parameters that need to be attached to the redirect
#     endpoint as query parameters:</p>
#     <dl>
#       <dt><code>client_id</code></dt>
#       <dd>The id provided as part of your Developer Key</dd>
#       <dt><code>response_type</code></dt>
#       <dd>As per the OAuth spec. This should be <code>code</code></dd>
#       <dt><code>redirect_uri</code></dt>
#       <dd>When you create a Developer Key you'll provide us with a 
#       redirect URI that's used to send people back from Canvas to your
#       app when authorized. You can direct to a different URI with this
#       parameter if you want, but it has to match the domain of the 
#       original URI.</dd>
#     <dl>
#     <p>Side note for mobile apps: mobile apps don't have a web presence,
#     so <code>redirect_uri</code> doesn't make as much sense. For mobile
#     apps using OAuth you should specify <code>urn:ietf:wg:oauth:2.0:oob</code>
#     as the <code>redirect_uri</code> value. Then the user will be
#     redirected to <code>/login/oauth2/auth?code=&lt;<code&gt;></code> on
#     the Canvas domain, and you'll be responsible to strip the 
#     <code>code</code> parameter out of this URL.</p>
#     <p>For this test, and for all the tests in this activity,
#     you'll be using a different auth endpoint than you would 
#     use with Canvas. The workflow is the same, but when you 
#     want to talk to Canvas you'll need to get a Developer Key
#     and use the Canvas Oauth endpoint, 
#     <code>/login/oauth2/auth</code>. For now, use the URL id and secret
#     specified in the testing box.</p>
#     <p>Let's see what you can do. Specify a URL on your site that will 
#     trigger the auth process. We'll launch that in an iframe which should
#     then redirect to the auth URL specified with the necessary parameters.
#     Enter the URL you redirected to when you're done.
#     </p>
#   EOF
#   
#   oauth.oauth_test :oauth_return, :phase => :step_2, :explanation => <<-EOF
#     <p>In step two of the OAuth dance, the user is going to get redirected
#     back to the <code>redirect_uri</code> you provided. If they actually
#     authorized your app then they'll hit your endpoint with an additional
#     query parameter, <code>code</code>. You want to grab that parameter,
#     since you're going to be exchanging it for an access token for
#     the user.</p>
#   EOF
#   
#   oauth.oauth_test :access_denied, :phase => :step_2, :pick_access_denied => true, :allow_access_denied => true, :iterations => 5, :explanation => <<-EOF
#     <p>Staying on step two for a minute, if someone decides at authorization time
#     that they actually don't want to authorize your app, you'll get a 
#     different query parameter (this applies for mobile apps as well), 
#     <code>error=access_denied</code>. This means the user did not authorize
#     your application to make API calls on their behalf.</p>
#     <p>At this point you should generate a reasonably-friendly page letting
#     the user know that they denied access for your app and that as a result your
#     app isn't going to be able to do cool stuff for them. Keep in mind that
#     the user may not think anything of it, since all they did was click the
#     "Cancel" button, not some giant red "DENY ACCESS" button or anything,
#     so you really shouldn't be showing them an angry error page.
#     Keep it friendly and give them the option to re-authorize if they want.</p>
#     <p>For this test, you're going to go through the first two steps of the 
#     OAuth dance five times. Each time you'll either get a code back or an
#     "access denied" error. Tell me which you got each time.</p>
#   EOF
#   
#   oauth.oauth_test :oauth_token_exchange, :phase => :step_3, :explanation => <<-EOF
#     <p>Now that you've successfully gotten a code, you need to exchange that for
#     an actual access token. To do so you're going to make a server-to-server
#     POST request to the correct endpoint (for testing it's up in the test box, for
#     Canvas it's <code>/login/oauth2/token</code>). You'll need to send along
#     the following parameters:</p>
#     <dl>
#       remind them why we didn't send the secret before
#     </dl>
#   EOF
#   
#   oauth.local_api_test :logging_out, :logout => true, :explanation => <<-EOF
#   EOF
#   
#   oauth.local_api_test :oauth_expired_token, :allow_expired => true, :pick_expired => true, :iterations => 3, :explanation => <<-EOF
#     <p>Next let's talk about token expiration and removal. In Canvas a user
#     can see all of the applications they've authorized on their behalf on
#     their profile page. At any point they can delete the token without your
#     knowing. Also, access tokens can potentially expire depending on how they're
#     created.</p>
#     <p>When a token expires or is deleted, you'll get the same message as if you'd used
#     an invalid access token. Either way you're obviously going to need a 
#     different token, so you should re-initiate the oauth flow.</p>
#     <p>For this test, make an API call to the URL shown in the test box, using
#     the access token there as well. Call it
#     three times and tell me if the response means your token is expired or not.</p>
#   EOF
#   
#   # TODO: give them a way to check if their access token is still valid
#   # oauth.api_test :bad_access_token, :explanation => <<-EOF
#   #   <p>
#   # EOF
#   
#   oauth.local_api_test :rate_limits, :allow_throttling => true, :pick_throttled => true, :iterations => 3, :explanation => <<-EOF
#     <p>One semi-related topic rate limiting or throttling. Rate limites are defined
#     in the terms of use for Canvas and may differ for some open source implementations.
#     Throttled requests will return with the HTTP status <code>429 Too Many Requests</code>.
#     What to do in the case of rate limiting depends on your terms, and you should
#     review the documentation for more details.</p>
#     <p>For this test make an API call to the URL shown in the test box, using
#     the access token there as well. Call it
#     three times and tell me if the response was rate limited or not.</p>
#   EOF
