require File.dirname(__FILE__) + '/spec_helper'
require 'nokogiri'

describe 'LTI Launch' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  describe "fake_launch" do
  end
  
  describe "activity launch" do
    it "should fail gracefully when no parameters sent" do
      lti_config
      post "/launch/non-activity"
      assert_error_page("Invalid tool launch - unknown tool consumer")
    end
    
    it "should fail gracefully on incorrect signature" do
      lti_config
      post "/launch/non-activity", {:oauth_consumer_key => @config.consumer_key}
      assert_error_page("Invalid tool launch - invalid parameters")
    end
    
    it "should set session variables on success" do
      lti_config
      IMS::LTI::ToolProvider.any_instance.should_receive(:valid_request?).and_return(true)
      post "/launch/non-activity", {:oauth_consumer_key => @config.consumer_key, :custom_canvas_user_id => '1234', :lis_person_name_full => "Bob Jones"}
      session['user_id'].should == '1234'
      session['key'].should_not == nil
      session['secret'].should_not == nil
      session['name'].should == "Bob Jones"
    end
    
    it "should fail gracefull if no activity defined" do
      lti_config
      IMS::LTI::ToolProvider.any_instance.should_receive(:valid_request?).and_return(true)
      post "/launch/non-activity", {:oauth_consumer_key => @config.consumer_key}
      assert_error_page("Invalid activity")
    end
    
    it "should redirect to the correct activity" do
      lti_config
      IMS::LTI::ToolProvider.any_instance.should_receive(:valid_request?).and_return(true)
      post "/launch/post_launch", {:oauth_consumer_key => @config.consumer_key}
      last_response.should be_redirect
      last_response.location.should == "http://example.org/launch/post_launch/0"
    end
  end
  
  describe "activity launch" do
    it "should fail if session is lost" do
      get "/launch/no-activity/0"
      assert_error_page("Session lost")
    end
    
    it "should fail if no activity found" do
      get "/launch/no-activity/0", {}, 'rack.session' => {'user_id' => '1234'}
      assert_error_page("Invalid activity")

      get "/launch/post_launch/100", {}, 'rack.session' => {'user_id' => '1234'}
      assert_error_page("Invalid activity")
    end
    
    it "should render form if successful" do
      get "/launch/post_launch/0", {}, 'rack.session' => {'user_id' => '1234', 'key' => 'asdf', 'secret' => 'jkl'}
      last_response.should be_ok
      html = Nokogiri::HTML(last_response.body)
      html.css('#app_launch').length.should == 1
      html.css("form[target='app_launch']").length.should == 1
      html.css("#consumer_key").text.should == session['key']
      html.css("#shared_secret").text.should == session['secret']
    end
  end
  
  describe "activity test" do
    it "should fail if session is lost" do
      post "/test/no-activity/0"
      assert_error_page("Session lost")
    end
    
    it "should fail if no activity found" do
      post "/test/no-activity/0", {}, 'rack.session' => {'user_id' => '1234'}
      assert_error_page("Invalid activity")

      post "/test/post_launch/100", {}, 'rack.session' => {'user_id' => '1234'}
      assert_error_page("Invalid activity")
    end
    
    it "should fail if no launch_url provided" do
      post "/test/post_launch/0", {}, 'rack.session' => {'user_id' => '1234', 'key' => 'asdf', 'secret' => 'jkl'}
      assert_error_page("Launch URL required")
    end
    
    it "should render launch form if successful" do
      post "/test/post_launch/0", {:launch_url => "http://www.example.com"}, 'rack.session' => {'user_id' => '1234', 'key' => 'asdf', 'secret' => 'jkl'}
      last_response.should be_ok
      html = Nokogiri::HTML(last_response.body)
      html.css("form#ltiLaunchForm").length.should == 1
    end
  end
  
#      it "should require a launch_url" do
#      get "/launch/post_launch/0", {}, 'rack.session' => {'user_id' => '1234'}
#      assert_error_page("Launch URL required")
#    end
    

end
