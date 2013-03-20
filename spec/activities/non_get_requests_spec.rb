require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'Non-GET Request Tests' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  it "should succeed when correct folder information found" do
    fake_launch({'farthest_for_non_get' => 10})
    get "/launch/non_get/0", {}
    answer = 1236
    Api.any_instance.should_receive(:get).with('/api/v1/users/self/folders').and_return(ArrayWithPagination.new [{}, {}, {'id' => answer, 'name' => 'grindylow'}])
    post "/validate/non_get/0", {'answer' => answer}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == true      
  end
  
  it "should fail when folder information not found" do
    fake_launch({'farthest_for_non_get' => 10})
    get "/launch/non_get/0", {}
    answer = 1236
    Api.any_instance.should_receive(:get).with('/api/v1/users/self/folders').and_return(ArrayWithPagination.new [{}, {}, {'id' => answer}])
    post "/validate/non_get/0", {'answer' => answer}
    json = JSON.parse(last_response.body)
    json['error'].should == "Couldn't find the folder"
    json['correct'].should_not == true      
  end
  
  it "should fail when folder information doesn't match answer" do
    fake_launch({'farthest_for_non_get' => 10})
    get "/launch/non_get/0", {}
    answer = 1236
    Api.any_instance.should_receive(:get).with('/api/v1/users/self/folders').and_return(ArrayWithPagination.new [{}, {}, {'id' => answer, 'name' => 'grindylow'}])
    post "/validate/non_get/0", {'answer' => answer + 1}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == false
  end
  
  it "should succeed when correct short name entered" do
    fake_launch({'farthest_for_non_get' => 10})
    get "/launch/non_get/1", {}
    answer = "bob_jones"
    Api.any_instance.should_receive(:get).with('/api/v1/users/self/profile').and_return({'short_name' => answer})
    post "/validate/non_get/1", {'answer' => answer}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == true
  end
  
  it "should fail when short name not entered correctly" do
    fake_launch({'farthest_for_non_get' => 10})
    get "/launch/non_get/1", {}
    answer = "bob_jones"
    Api.any_instance.should_receive(:get).with('/api/v1/users/self/profile').and_return({'short_name' => answer})
    post "/validate/non_get/1", {'answer' => answer + "s"}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == false
  end
  
  it "should create events correctly in delete request setup" do
    fake_launch({'farthest_for_non_get' => 10})
    get "/launch/non_get/2", {}
    answer = "your house"
    Api.any_instance.should_receive(:get).with('/api/v1/users/self/profile').and_return({'id' => 1, 'primary_email' => 'bob@example.com', 'calendar' => {'ics' => '999'}})
    Api.any_instance.should_receive(:post).and_return({'id' => 1, 'location_name' => answer})
    post "/setup/non_get/2"
  end
  
  it "should succeed when event correctly deleted" do
    fake_launch({'farthest_for_non_get' => 10})
    get "/launch/non_get/2", {}
    answer = "bob@example.com_999"
    Api.any_instance.should_receive(:get).with('/api/v1/users/self/profile').and_return({'id' => 1, 'primary_email' => 'bob@example.com', 'calendar' => {'ics' => '999'}})
    Api.any_instance.should_receive(:get).with('/api/v1/calendar_events?context_codes[]=user_1&type=event&start_date=2009-01-01&end_date=2009-01-01').and_return([])
    post "/validate/non_get/2", {'answer' => answer}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == true
  end
  
  it "should fail when event not yet deleted" do
    fake_launch({'farthest_for_non_get' => 10})
    get "/launch/non_get/2", {}
    answer = "bob@example.com_999"
    Api.any_instance.should_receive(:get).with('/api/v1/users/self/profile').and_return({'id' => 1, 'primary_email' => 'bob@example.com', 'calendar' => {'ics' => '999'}})
    Api.any_instance.should_receive(:get).with('/api/v1/calendar_events?context_codes[]=user_1&type=event&start_date=2009-01-01&end_date=2009-01-01').and_return([{'title' => 'Delete Me'}])
    post "/validate/non_get/2", {'answer' => answer}
    json = JSON.parse(last_response.body)
    json['error'].should == "Event not deleted"
    json['correct'].should_not == true
  end

  
  it "should succeed when communication channel correctly found" do
    fake_launch({'farthest_for_non_get' => 10})
    get "/launch/non_get/2", {}
    answer = "bob@example.com_999"
    Api.any_instance.should_receive(:get).with('/api/v1/users/self/profile').and_return({'id' => 1, 'primary_email' => 'bob@example.com', 'calendar' => {'ics' => '999'}})
    Api.any_instance.should_receive(:get).with('/api/v1/calendar_events?context_codes[]=user_1&type=event&start_date=2009-01-01&end_date=2009-01-01').and_return([{'title' => 'Delete Me'}])
    post "/validate/non_get/2", {'answer' => answer}
    json = JSON.parse(last_response.body)
    json['error'].should == "Event not deleted"
    json['correct'].should_not == true
  end
end
