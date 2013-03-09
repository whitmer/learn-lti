require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'Signature Check Activity' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  it "should succeed when marked as valid with correct signature" do
    Samplers.should_receive(:random).and_return(1)
    get "/fake_launch"
    get "/launch/signature_check/2", {}, 'rack.session' => {'farthest_for_signature_check' => 10}
    post "/test/signature_check/2", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/signature_check/2", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true

    post "/validate/signature_check/2", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
    json['error'].should == 'Session lost'
  end
  
  it "should fail with the correct answer as answer instead of valid" do
    Samplers.should_receive(:random).and_return(1)
    get "/fake_launch"
    get "/launch/signature_check/2", {}, 'rack.session' => {'farthest_for_signature_check' => 10}
    post "/test/signature_check/2", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/signature_check/2", {'answer' => session['answer_for_signature_check_2']}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
  it "should fail when marked as valid with the wrong signature" do
    Samplers.should_receive(:random).and_return(1)
    get "/fake_launch"
    get "/launch/signature_check/2", {}, 'rack.session' => {'farthest_for_signature_check' => 10}
    post "/test/signature_check/2", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/signature_check/2", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
  it "should succeed when marked as invalid with the wrong signature" do
    Samplers.should_receive(:random).and_return(0)
    get "/fake_launch"
    get "/launch/signature_check/2", {}, 'rack.session' => {'farthest_for_signature_check' => 10}
    post "/test/signature_check/2", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/signature_check/2", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  
  it "should fail when marked as invalid with the correct signature" do
    Samplers.should_receive(:random).and_return(0)
    get "/fake_launch"
    get "/launch/signature_check/2", {}, 'rack.session' => {'farthest_for_signature_check' => 10}
    post "/test/signature_check/2", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/signature_check/2", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end

  it "should succeed when marked as valid with correct nonce" do
    Samplers.should_receive(:random).with(3).and_return(1)
    get "/fake_launch"
    get "/launch/signature_check/0", {}, 'rack.session' => {'farthest_for_signature_check' => 10}
    post "/test/signature_check/0", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/signature_check/0", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  
  it "should fail when marked as valid with the wrong nonce" do
    Samplers.should_receive(:random).with(3).and_return(1)
    get "/fake_launch"
    get "/launch/signature_check/0", {}, 'rack.session' => {'farthest_for_signature_check' => 10}
    post "/test/signature_check/0", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/signature_check/0", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
  it "should succeed when marked as invalid with the wrong nonce" do
    Samplers.should_receive(:random).with(3).and_return(0)
    get "/fake_launch"
    get "/launch/signature_check/0", {}, 'rack.session' => {'farthest_for_signature_check' => 10}
    post "/test/signature_check/0", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/signature_check/0", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  
  it "should fail when marked as invalid with the correct nonce" do
    Samplers.should_receive(:random).with(3).and_return(0)
    get "/fake_launch"
    get "/launch/signature_check/0", {}, 'rack.session' => {'farthest_for_signature_check' => 10}
    post "/test/signature_check/0", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/signature_check/0", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
  it "should succeed when marked as valid with an old nonce" do
    Samplers.should_receive(:random).with(3).and_return(1)
    Samplers.should_receive(:random).with(3.1).and_return(0)
    get "/fake_launch"
    get "/launch/signature_check/0", {}, 'rack.session' => {'farthest_for_signature_check' => 10, 'answers_for_signature_check_0' => '12345,12345,12345'}
    post "/test/signature_check/0", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/signature_check/0", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  
  it "should fail when marked as invalid with an old nonce" do
    Samplers.should_receive(:random).with(3).and_return(1)
    Samplers.should_receive(:random).with(3.1).and_return(0)
    get "/fake_launch"
    get "/launch/signature_check/0", {}, 'rack.session' => {'farthest_for_signature_check' => 10, 'answers_for_signature_check_0' => '12345,12345,12345'}
    post "/test/signature_check/0", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/signature_check/0", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
  it "should succeed when marked as valid with correct timestamp" do
    Samplers.should_receive(:random).with(3).and_return(1)
    Samplers.should_receive(:random).with(3.1).and_return(1)
    get "/fake_launch"
    get "/launch/signature_check/1", {}, 'rack.session' => {'farthest_for_signature_check' => 10}
    post "/test/signature_check/1", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/signature_check/1", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  it "should fail when marked as valid with the wrong timestamp" do
    Samplers.should_receive(:random).with(3).and_return(1)
    Samplers.should_receive(:random).with(3.1).and_return(1)
    get "/fake_launch"
    get "/launch/signature_check/1", {}, 'rack.session' => {'farthest_for_signature_check' => 10}
    post "/test/signature_check/1", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/signature_check/1", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
  it "should succeed when marked as invalid with the wrong timestamp" do
    Samplers.should_receive(:random).with(3).and_return(0)
    Samplers.should_receive(:random).with(3.1).and_return(1)
    get "/fake_launch"
    get "/launch/signature_check/1", {}, 'rack.session' => {'farthest_for_signature_check' => 10}
    post "/test/signature_check/1", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/signature_check/1", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  
  it "should fail when marked as invalid with the correct timestamp" do
    Samplers.should_receive(:random).with(3).and_return(0)
    Samplers.should_receive(:random).with(3.1).and_return(1)
    get "/fake_launch"
    get "/launch/signature_check/1", {}, 'rack.session' => {'farthest_for_signature_check' => 10}
    post "/test/signature_check/1", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/signature_check/1", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
  it "should succeed when marked as valid with an old timestamp" do
    Samplers.should_receive(:random).with(3).and_return(1)
    Samplers.should_receive(:random).with(3.1).and_return(0)
    get "/fake_launch"
    get "/launch/signature_check/1", {}, 'rack.session' => {'farthest_for_signature_check' => 10}
    post "/test/signature_check/1", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/signature_check/1", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  
  it "should fail when marked as invalid with an old timestamp" do
    Samplers.should_receive(:random).with(3).and_return(1)
    Samplers.should_receive(:random).with(3.1).and_return(0)
    get "/fake_launch"
    get "/launch/signature_check/1", {}, 'rack.session' => {'farthest_for_signature_check' => 10}
    post "/test/signature_check/1", {'launch_url' => 'http://www.example.com/launch'}
    post "/validate/signature_check/1", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
end
