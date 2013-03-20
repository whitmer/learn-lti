require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'API get_with_session Requests' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  it "should allow answering a :status_code question" do
    fake_launch({'farthest_for_get_requests' => 10})
    get_with_session "/launch/get_requests/0", {}
    answer = Digest::MD5.hexdigest(Date.today.iso8601)[1, 15]
    post_with_session "/validate/get_requests/0", {'answer' => answer}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == true
    json['next'].should == "/launch/get_requests/1"

    post_with_session "/validate/get_requests/0", {'answer' => answer + "a"}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == false
  end
  
  it "should get_with_session the correct id from a profile api call" do
    fake_launch({'farthest_for_get_requests' => 10})
    get_with_session "/launch/get_requests/1", {}
    answer = 'asdf'
    Api.any_instance.should_receive(:get).and_return({'id' => answer})
    post_with_session "/validate/get_requests/1", {'answer' => answer}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == true
    json['next'].should == "/launch/get_requests/2"
  end

  it "should error on different id from a profile api call" do
    fake_launch({'farthest_for_get_requests' => 10})
    get_with_session "/launch/get_requests/1", {}
    answer = 'asdf'
    Api.any_instance.should_receive(:get).and_return({'id' => answer})
    post_with_session "/validate/get_requests/1", {'answer' => "You are not authorized to perform that action."}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == false
  end
  
  it "should ask for the correct error message on unauthorized api call" do
    fake_launch({'farthest_for_get_requests' => 10})
    answer = "You are not authorized to perform that action."
    post_with_session "/validate/get_requests/2", {'answer' => answer}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == true
  end
  
  it "should ask for https on the https question" do
    fake_launch({'farthest_for_get_requests' => 10})
    answer = "https"
    post_with_session "/validate/get_requests/3", {'answer' => answer}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == true

    answer = "http"
    post_with_session "/validate/get_requests/3", {'answer' => answer}
    json = JSON.parse(last_response.body)
    json['answer'].should == "https"
    json['correct'].should == false
  end
  
  it "should get_with_session the correct calendar -> ics value from a profile api call" do
    fake_launch({'farthest_for_get_requests' => 10})
    get_with_session "/launch/get_requests/4", {}
    answer = 'a8toyn24ty2m8ty2'
    Api.any_instance.should_receive(:get).and_return({'calendar' => {'ics' => answer}})
    post_with_session "/validate/get_requests/4", {'answer' => answer}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == true
  end
  
  it "should get_with_session the correct id of the first course in a courses api call" do
    fake_launch({'farthest_for_get_requests' => 10})
    get_with_session "/launch/get_requests/5", {}
    answer = 'a8toyn24ty2m8ty2'
    Api.any_instance.should_receive(:get).and_return([{'id' => answer}])
    post_with_session "/validate/get_requests/5", {'answer' => answer}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == true
  end
  
  context "filtering" do
    it "should error on failed event creation" do
      fake_launch({'farthest_for_get_requests' => 10})
      get_with_session "/launch/get_requests/6", {}
      answer = 'a8toyn24ty2m8ty2'
      Api.any_instance.should_receive(:get).with('/api/v1/users/self/profile').and_return({'id' => 1})
      Api.any_instance.should_receive(:get).with("/api/v1/calendar_events?context_codes[]=user_1&type=event&start_date=2010-12-31&end_date=2011-01-02").and_return([])
      Api.any_instance.should_receive(:post).and_return({})
      post_with_session "/setup/get_requests/6", {}
      json = JSON.parse(last_response.body)
      json['error'].should == 'Event creation failed'
      json['correct'].should_not == true      
    end
    
    it "should delete existing events" do
      fake_launch({'farthest_for_get_requests' => 10})
      get_with_session "/launch/get_requests/6", {}
      Api.any_instance.should_receive(:get).with('/api/v1/users/self/profile').and_return({'id' => 1})
      Api.any_instance.should_receive(:get).with("/api/v1/calendar_events?context_codes[]=user_1&type=event&start_date=2010-12-31&end_date=2011-01-02").and_return([{'id' => 2, 'title' => 'API Test Event'}])
      Api.any_instance.should_receive(:delete).and_return({})
      Api.any_instance.should_receive(:post).and_return({'id' => 3})
      post_with_session "/setup/get_requests/6", {}
    end
    
    it "should error on empty results during lookup" do
      fake_launch({'farthest_for_get_requests' => 10})
      get_with_session "/launch/get_requests/6", {}
      answer = 'a8toyn24ty2m8ty2'
      Api.any_instance.should_receive(:get).with('/api/v1/users/self/profile').and_return({'id' => 1})
      Api.any_instance.should_receive(:get).with("/api/v1/calendar_events?context_codes[]=user_1&type=event&start_date=2010-12-31&end_date=2011-01-02").and_return([])
      post_with_session "/validate/get_requests/6", {'answer' => answer}
      json = JSON.parse(last_response.body)
      json['error'].should == 'Event not found'
      json['correct'].should_not == true      
    end
    
    it "should error if event not found on lookup" do
      fake_launch({'farthest_for_get_requests' => 10})
      get_with_session "/launch/get_requests/6", {}
      answer = 'a8toyn24ty2m8ty2'
      Api.any_instance.should_receive(:get).with('/api/v1/users/self/profile').and_return({'id' => 1})
      Api.any_instance.should_receive(:get).with("/api/v1/calendar_events?context_codes[]=user_1&type=event&start_date=2010-12-31&end_date=2011-01-02").and_return([{'id' => 2}])
      post_with_session "/validate/get_requests/6", {'answer' => answer}
      json = JSON.parse(last_response.body)
      json['error'].should == 'Event not found'
      json['correct'].should_not == true      
    end
    
    it "should succeed when the correct id is entered" do
      fake_launch({'farthest_for_get_requests' => 10})
      get_with_session "/launch/get_requests/6", {}
      answer = 2.to_s
      Api.any_instance.should_receive(:get).with('/api/v1/users/self/profile').and_return({'id' => 1})
      Api.any_instance.should_receive(:get).with("/api/v1/calendar_events?context_codes[]=user_1&type=event&start_date=2010-12-31&end_date=2011-01-02").and_return([{'id' => 2, 'title' => 'API Test Event'}])
      post_with_session "/validate/get_requests/6", {'answer' => answer}
      json = JSON.parse(last_response.body)
      json['answer'].should == answer
      json['correct'].should == true      
    end
    
  end
  
  it "should get_with_session the correct term id when included on courses favorites call" do
    fake_launch({'farthest_for_get_requests' => 10})
    get_with_session "/launch/get_requests/7", {}
    answer = 123.to_s
    Api.any_instance.should_receive(:get).with('/api/v1/users/self/favorites/courses?include[]=term').and_return([{'term' => {'id' => answer}}])
    post_with_session "/validate/get_requests/7", {'answer' => answer}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == true      
  end
  
  it "should get_with_session the correct id of the first communication channel" do
    fake_launch({'farthest_for_get_requests' => 10})
    get_with_session "/launch/get_requests/8", {}
    answer = 1236.to_s
    Api.any_instance.should_receive(:get).with('/api/v1/users/self/communication_channels').and_return([{'id' => answer}])
    post_with_session "/validate/get_requests/8", {'answer' => answer}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == true      
  end
  
  it "should call setup on page load" do
    fake_launch({'farthest_for_get_requests' => 10, 'access_token' => 'abc'})
    get_with_session "/launch/get_requests/8", {}
    last_response.should be_ok
    html = Nokogiri::HTML(last_response.body)
    html.css('#answer')[0]['rel'].should == '/setup/get_requests/8'
  end
end
