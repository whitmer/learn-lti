require File.dirname(__FILE__) + '/spec_helper'
require 'nokogiri'
require 'ostruct'

describe 'OAuth for API launches' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  it "should not require api token if non-api-launch" do
    User.create(:user_id => '1234')
    get "/launch/post_launch/0", {}, 'rack.session' => {'user_id' => '1234', 'key' => 'asdf', 'secret' => 'jkl'}
    last_response.should be_ok
  end
  
  it "should require canvas oauth config if api-launch" do
    User.create(:user_id => '1234')
    get "/launch/get_requests/0", {}, 'rack.session' => {'api_host' => 'canvas.tv', 'user_id' => '1234', 'key' => 'asdf', 'secret' => 'jkl'}
    last_response.should_not be_ok
    assert_error_page("Missing oauth config")
  end

  it "should require api token if api-launch" do
    User.create(:user_id => '1234')
    canvas_config
    get "/launch/get_requests/0", {}, 'rack.session' => {'api_host' => 'canvas.tv', 'user_id' => '1234', 'key' => 'asdf', 'secret' => 'jkl'}
    last_response.should be_redirect
    last_response.location.should == "http://canvas.tv/login/oauth2/auth?client_id=#{@canvas_config.consumer_key}&response_type=code&redirect_uri=http%3A%2F%2Fexample.org%2Foauth_success"
  end
  
  it "should not redirect to api token on api-launch if already retrieved" do
    User.create(:user_id => '1234', :settings => {'access_token' => 'asdfyuiop'})
    canvas_config
    get "/launch/get_requests/0", {}, 'rack.session' => {'api_host' => 'canvas.tv', 'user_id' => '1234', 'key' => 'asdf', 'secret' => 'jkl'}
    last_response.should be_ok
  end
  
  describe "canvas_oauth" do
    it "should fail if session is lost" do
      get "/canvas_oauth"
      last_response.should_not be_ok
      assert_error_page("User session lost")
    end
    
    it "should remember user token if returned" do
      canvas_config
      User.create(:user_id => '1234')
      Net::HTTP.any_instance.should_receive(:request).and_return(OpenStruct.new(:body => {:access_token => 'abc'}.to_json))
      get "/canvas_oauth", {}, 'rack.session' => {'api_host' => 'canvas.tv', 'user_id' => '1234', 'activity' => 'get_requests', 'activity_index' => '0'}
      last_response.should be_redirect
      last_response.location.should == "http://example.org/launch/get_requests/0"
      user = User.first(:user_id => '1234')
      user.settings['access_token'].should == 'abc'
    end
    
    it "should fail gracefully if user token rejected" do
      canvas_config
      User.create(:user_id => '1234')
      Net::HTTP.any_instance.should_receive(:request).and_return(OpenStruct.new(:body => {}.to_json))
      get "/canvas_oauth", {}, 'rack.session' => {'api_host' => 'canvas.tv', 'user_id' => '1234', 'activity' => 'get_requests', 'activity_index' => '0'}
      assert_error_page("There was a problem retrieving permission to access Canvas on your behalf. Without this permission we can't test your ability to use the Canvas API. Please reload the page and re-authorize to continue.")
    end
  end

end
