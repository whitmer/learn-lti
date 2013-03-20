require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'Pagination Tests' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  it "should return correct header" do
    fake_launch({'farthest_for_pagination' => 10})
    get_with_session "/launch/pagination/0", {}
    res = ArrayWithPagination.new
    res.link = "bob"
    Api.any_instance.should_receive(:get).with('/api/v1/users/self/page_views').and_return(res)
    post_with_session "/validate/pagination/0", {'answer' => res.link}
    json = JSON.parse(last_response.body)
    json['answer'].should == res.link
    json['correct'].should == true      
  end
  
  it "should fail when incorrect header entered" do
    fake_launch({'farthest_for_pagination' => 10})
    get_with_session "/launch/pagination/0", {}
    res = ArrayWithPagination.new
    res.link = "bob"
    Api.any_instance.should_receive(:get).with('/api/v1/users/self/page_views').and_return(res)
    post_with_session "/validate/pagination/0", {'answer' => res.link + "a"}
    json = JSON.parse(last_response.body)
    json['answer'].should == res.link
    json['correct'].should == false
  end
  
  it "should succeed when correct next url entered" do
    fake_launch({'farthest_for_pagination' => 10})
    get_with_session "/launch/pagination/1", {}
    res = ArrayWithPagination.new
    res.link = "bob"
    res.next_url = "fred"
    Api.any_instance.should_receive(:get).with('/api/v1/users/self/profile').and_return({'id' => 1})
    Api.any_instance.should_receive(:get).with('/api/v1/calendar_events?type=event&start_date=2010-01-01&end_date=2010-01-01&per_page=1').and_return(res)
    post_with_session "/validate/pagination/1", {'answer' => res.next_url}
    json = JSON.parse(last_response.body)
    json['answer'].should == res.next_url
    json['correct'].should == true      
  end
  
  it "should fail when incorrect next url entered" do
    fake_launch({'farthest_for_pagination' => 10})
    get_with_session "/launch/pagination/1", {}
    res = ArrayWithPagination.new
    res.link = "bob"
    res.next_url = "fred"
    Api.any_instance.should_receive(:get).with('/api/v1/users/self/profile').and_return({'id' => 1})
    Api.any_instance.should_receive(:get).with('/api/v1/calendar_events?type=event&start_date=2010-01-01&end_date=2010-01-01&per_page=1').and_return(res)
    post_with_session "/validate/pagination/1", {'answer' => res.next_url + "a"}
    json = JSON.parse(last_response.body)
    json['answer'].should == res.next_url
    json['correct'].should == false
  end
  
  it "should succeed when correct number of entries entered" do
    fake_launch({'farthest_for_pagination' => 10})
    get_with_session "/launch/pagination/2", {}
    Api.any_instance.should_receive(:get).with('/api/v1/users/self/page_views?per_page=1000000').and_return([{}, {}, {}])
    post_with_session "/validate/pagination/2", {'answer' => "3"}
    json = JSON.parse(last_response.body)
    json['answer'].should == "3"
    json['correct'].should == true
  end
  
  it "should fail when incorrect number of entries entered" do
    fake_launch({'farthest_for_pagination' => 10})
    get_with_session "/launch/pagination/2", {}
    Api.any_instance.should_receive(:get).with('/api/v1/users/self/page_views?per_page=1000000').and_return([{}, {}, {}])
    post_with_session "/validate/pagination/2", {'answer' => "4"}
    json = JSON.parse(last_response.body)
    json['answer'].should == "3"
    json['correct'].should == false 
  end
end
