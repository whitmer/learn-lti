require File.dirname(__FILE__) + '/spec_helper'

describe 'Models' do
  include Rack::Test::Methods
  
  def app
    TestLti
  end
  
  describe "User" do
    it "should send scores back correctly" do
      lti_config
      user
      @user.lti_config = @config
      @user.save
      @user.settings = {
        'outcome_url' => 'http://www.example.com/outcome',
        'outcome_for_post_launch' => '1234asdf'
      }
      obj = {}
      IMS::LTI::ToolProvider.should_receive(:new).with(@config.consumer_key, @config.shared_secret, {
        'lis_outcome_service_url' => 'http://www.example.com/outcome',
        'lis_result_sourcedid' => '1234asdf'
      }).and_return(obj)
      obj.should_receive(:post_replace_result_with_data!).with(0.231, "text" => "Finished 3 of 13 lessons").and_return(true)
      
      @user.update_score('post_launch', 2)
    end
  end    

end

