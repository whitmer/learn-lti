require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'POST Launch Activity' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end

  it "should allow testing for a paramter" do
    fake_launch
    get "/launch/post_launch/0"
    post "/test/post_launch/0", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/post_launch/0", {'answer' => 'basic-lti-launch-request'}
    json = JSON.parse(last_response.body)
    json['answer'].should == 'basic-lti-launch-request'
    json['correct'].should == true
    json['next'].should == "/launch/post_launch/1"
  end
  
  it "should error on incorrect answer" do
    fake_launch
    get "/launch/post_launch/0"
    post "/test/post_launch/0", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/post_launch/0", {'answer' => 'ice-cream'}
    json = JSON.parse(last_response.body)
    json['answer'].should == 'basic-lti-launch-request'
    json['correct'].should == false
    json['next'].should == nil
  end
  
  it "should error on repeated attempts" do
    fake_launch
    get "/launch/post_launch/0"
    post "/test/post_launch/0", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/post_launch/0", {'answer' => 'ice-cream'}
    post "/validate/post_launch/0", {'answer' => 'basic-lti-launch-request'}
    json = JSON.parse(last_response.body)
    json['error'].should == 'Session lost'
    json['next'].should == nil
    post "/validate/post_launch/0", {'answer' => nil}
    json = JSON.parse(last_response.body)
    json['error'].should == 'Session lost'
    json['next'].should == nil
  end
  
  it "should allow testing custom fields if a value is provided" do
    fake_launch({'farthest_for_post_launch' => 20})
    get "/launch/post_launch/11", {}
    post "/test/post_launch/11", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/post_launch/11", {'answer' => session["answer_for_post_launch_11"]}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end

  describe "role picking" do
    it "should succeed when correct roles are picked" do
      fake_launch({'farthest_for_post_launch' => 20})
      get "/launch/post_launch/5", {}
      post "/test/post_launch/5", {'launch_url' => 'http://www.example.com/launch'}
      answer = session["answer_for_post_launch_5"]
      answer.should_not be_nil
      roles = Samplers.map_roles(answer)
      post "/validate/post_launch/5", {'role' => roles}
      json = JSON.parse(last_response.body)
      json['correct'].should == true
    end
    
    it "should fail when answer is set but not roles" do
      fake_launch({'farthest_for_post_launch' => 20})
      get "/launch/post_launch/5", {}
      Samplers.should_receive(:random_roles).and_return("Learner,ContentDeveloper")

      post "/test/post_launch/5", {'launch_url' => 'http://www.example.com/launch'}
      answer = session["answer_for_post_launch_5"]
      post "/validate/post_launch/5", {'answer' => answer}
      json = JSON.parse(last_response.body)
      json['correct'].should == false
    end
    
    it "should fail when correct roles are not picked" do
      fake_launch({'farthest_for_post_launch' => 20})
      get "/launch/post_launch/5", {}
      post "/test/post_launch/5", {'launch_url' => 'http://www.example.com/launch'}
      post "/validate/post_launch/5", {'role' => ['a', 'b']}
      json = JSON.parse(last_response.body)
      json['correct'].should == false

      post "/validate/post_launch/5", {'role' => "a"}
      json = JSON.parse(last_response.body)
      json['correct'].should == false
    end
  end
  
  describe "iterations" do
    it "should increment on correct answer" do
      fake_launch({'farthest_for_post_launch' => 20})
      get "/launch/post_launch/5", {}
      post "/test/post_launch/5", {'launch_url' => 'http://www.example.com/launch'}
      answer = session["answer_for_post_launch_5"]
      answer.should_not be_nil
      roles = Samplers.map_roles(answer)
      post "/validate/post_launch/5", {'role' => roles}
      json = JSON.parse(last_response.body)
      json['correct'].should == true
      json['times_left'].should == 2
    end
    
    it "should reset on any failure" do
      fake_launch({'farthest_for_post_launch' => 20})
      get "/launch/post_launch/5", {}
      post "/test/post_launch/5", {'launch_url' => 'http://www.example.com/launch'}
      answer = session["answer_for_post_launch_5"]
      answer.should_not be_nil
      roles = Samplers.map_roles(answer)
      post "/validate/post_launch/5", {'role' => roles}
      session["answer_for_post_launch_5"].should be_nil
      
      post "/validate/post_launch/5", {'role' => nil}
      json = JSON.parse(last_response.body)
      json['correct'].should == false
      json['error'].should == "Session lost"
      
      post "/test/post_launch/5", {'launch_url' => 'http://www.example.com/launch'}
      answer = session["answer_for_post_launch_5"]
      answer.should_not be_nil
      roles = Samplers.map_roles(answer)
      post "/validate/post_launch/5", {'role' => roles}
      json = JSON.parse(last_response.body)
      json['correct'].should == true
      json['times_left'].should == 2
    end
    
    it "should provide 'next' when iterations are complete" do
      fake_launch({'farthest_for_post_launch' => 20})
      get "/launch/post_launch/5", {}
      post "/test/post_launch/5", {'launch_url' => 'http://www.example.com/launch'}
      answer = session["answer_for_post_launch_5"]
      answer.should_not be_nil
      roles = Samplers.map_roles(answer)
      post "/validate/post_launch/5", {'role' => roles}
      json = JSON.parse(last_response.body)
      json['correct'].should == true
      json['times_left'].should == 2
      json['next'].should == nil

      post "/test/post_launch/5", {'launch_url' => 'http://www.example.com/launch'}
      answer = session["answer_for_post_launch_5"]
      answer.should_not be_nil
      roles = Samplers.map_roles(answer)
      post "/validate/post_launch/5", {'role' => roles}
      json = JSON.parse(last_response.body)
      json['correct'].should == true
      json['times_left'].should == 1
      json['next'].should == nil

      post "/test/post_launch/5", {'launch_url' => 'http://www.example.com/launch'}
      answer = session["answer_for_post_launch_5"]
      answer.should_not be_nil
      roles = Samplers.map_roles(answer)
      post "/validate/post_launch/5", {'role' => roles}
      json = JSON.parse(last_response.body)
      json['correct'].should == true
      json['times_left'].should == nil
      json['next'].should == '/launch/post_launch/6'
    end
  end
end
