require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'Signature Check Activity' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  it "should succeed when marked as valid with correct signature" do
    Samplers.should_receive(:random).and_return(1)
    fake_launch({'farthest_for_signature_check' => 10})
    get_with_session "/launch/signature_check/2", {}
    post_with_session "/test/signature_check/2", {'launch_url' => 'http://www.example.com/launch'}
    post_with_session "/validate/signature_check/2", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true

    post_with_session "/validate/signature_check/2", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
    json['error'].should == 'Session lost'
  end
  
  it "should fail with the correct answer as answer instead of valid" do
    Samplers.should_receive(:random).and_return(1)
    fake_launch({'farthest_for_signature_check' => 10})
    get_with_session "/launch/signature_check/2", {}
    post_with_session "/test/signature_check/2", {'launch_url' => 'http://www.example.com/launch'}
    post_with_session "/validate/signature_check/2", {'answer' => session['answer_for_signature_check_2']}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
  it "should fail when marked as valid with the wrong signature" do
    Samplers.should_receive(:random).and_return(1)
    fake_launch({'farthest_for_signature_check' => 10})
    get_with_session "/launch/signature_check/2", {}
    post_with_session "/test/signature_check/2", {'launch_url' => 'http://www.example.com/launch'}
    post_with_session "/validate/signature_check/2", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
  it "should succeed when marked as invalid with the wrong signature" do
    Samplers.should_receive(:random).and_return(0)
    fake_launch({'farthest_for_signature_check' => 10})
    get_with_session "/launch/signature_check/2", {}
    post_with_session "/test/signature_check/2", {'launch_url' => 'http://www.example.com/launch'}
    post_with_session "/validate/signature_check/2", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  
  it "should fail when marked as invalid with the correct signature" do
    Samplers.should_receive(:random).and_return(0)
    fake_launch({'farthest_for_signature_check' => 10})
    get_with_session "/launch/signature_check/2", {}
    post_with_session "/test/signature_check/2", {'launch_url' => 'http://www.example.com/launch'}
    post_with_session "/validate/signature_check/2", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end

  it "should succeed when marked as valid with correct nonce" do
    Samplers.should_receive(:random).with(3).and_return(1)
    fake_launch({'farthest_for_signature_check' => 10})
    get_with_session "/launch/signature_check/0", {}
    post_with_session "/test/signature_check/0", {'launch_url' => 'http://www.example.com/launch'}
    html = Nokogiri::HTML(last_response.body)
    html.css("input[name='oauth_nonce']")[0]['value'].should_not == ""
    post_with_session "/validate/signature_check/0", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  
  it "should fail when marked as invalid with the correct nonce" do
    Samplers.should_receive(:random).with(3).and_return(1)
    fake_launch({'farthest_for_signature_check' => 10})
    get_with_session "/launch/signature_check/0", {}
    post_with_session "/test/signature_check/0", {'launch_url' => 'http://www.example.com/launch'}
    html = Nokogiri::HTML(last_response.body)
    html.css("input[name='oauth_nonce']")[0]['value'].should_not == ""
    post_with_session "/validate/signature_check/0", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
  it "should succeed when marked as invalid with a blank nonce" do
    Samplers.should_receive(:random).with(3).and_return(0)
    fake_launch({'farthest_for_signature_check' => 10})
    get_with_session "/launch/signature_check/0", {}
    post_with_session "/test/signature_check/0", {'launch_url' => 'http://www.example.com/launch'}
    html = Nokogiri::HTML(last_response.body)
    html.css("input[name='oauth_nonce']")[0]['value'].should == ""
    post_with_session "/validate/signature_check/0", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  
  it "should fail when marked as valid with a blank nonce" do
    Samplers.should_receive(:random).with(3).and_return(0)
    fake_launch({'farthest_for_signature_check' => 10})
    get_with_session "/launch/signature_check/0", {}
    post_with_session "/test/signature_check/0", {'launch_url' => 'http://www.example.com/launch'}
    html = Nokogiri::HTML(last_response.body)
    html.css("input[name='oauth_nonce']")[0]['value'].should == ""
    post_with_session "/validate/signature_check/0", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
  it "should succeed when marked as invalid with an old nonce" do
    Samplers.should_not_receive(:random).with(3)
    Samplers.should_receive(:random).with(3.1).and_return(0)
    fake_launch({'farthest_for_signature_check' => 10})
    get_with_session "/launch/signature_check/0", {}, 'rack.session' => {'answer_count_for_signature_check_0' => 1, 'answers_for_signature_check_0' => '12345,12345,12345'}
    post_with_session "/test/signature_check/0", {'launch_url' => 'http://www.example.com/launch'}
    html = Nokogiri::HTML(last_response.body)
    html.css("input[name='oauth_nonce']")[0]['value'].should == '12345'
    post_with_session "/validate/signature_check/0", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  
  it "should fail when marked as valid with an old nonce" do
    Samplers.should_not_receive(:random).with(3)
    Samplers.should_receive(:random).with(3.1).and_return(0)
    fake_launch({'farthest_for_signature_check' => 1})
    get_with_session "/launch/signature_check/0", {}, 'rack.session' => {'answer_count_for_signature_check_0' => 1, 'answers_for_signature_check_0' => '12345,12345,12345'}
    post_with_session "/test/signature_check/0", {'launch_url' => 'http://www.example.com/launch'}
    html = Nokogiri::HTML(last_response.body)
    html.css("input[name='oauth_nonce']")[0]['value'].should == '12345'
    post_with_session "/validate/signature_check/0", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
  it "should use an old nonce if it hasn't yet after 3 iterations" do
    Samplers.should_not_receive(:random).with(3)
    Samplers.should_not_receive(:random).with(3.1)
    fake_launch({'farthest_for_signature_check' => 10})
    get_with_session "/launch/signature_check/0", {}, 'rack.session' => {'answer_count_for_signature_check_0' => 3, 'answers_for_signature_check_0' => '12345,123456,1234567'}
    post_with_session "/test/signature_check/0", {'launch_url' => 'http://www.example.com/launch'}
    html = Nokogiri::HTML(last_response.body)
    html.css("input[name='oauth_nonce']")[0]['value'].should == '12345'
  end
  
  it "should use a blank nonce if it hasn't yet after 4 iterations" do
    Samplers.should_not_receive(:random).with(3)
    Samplers.should_receive(:random).with(3.1).and_return(1)
    fake_launch({'farthest_for_signature_check' => 10})
    get_with_session "/launch/signature_check/0", {}, 'rack.session' => {'answer_count_for_signature_check_0' => 4, 'answers_for_signature_check_0' => '12345,12345,12345,12345'}
    post_with_session "/test/signature_check/0", {'launch_url' => 'http://www.example.com/launch'}
    html = Nokogiri::HTML(last_response.body)
    html.css("input[name='oauth_nonce']")[0]['value'].should == ''
  end
  
  it "should succeed when marked as valid with correct timestamp" do
    Samplers.should_receive(:random).with(3).and_return(1)
    Samplers.should_receive(:random).with(3.1).and_return(1)
    fake_launch({'farthest_for_signature_check' => 10})
    get_with_session "/launch/signature_check/1", {}
    post_with_session "/test/signature_check/1", {'launch_url' => 'http://www.example.com/launch'}
    post_with_session "/validate/signature_check/1", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  it "should fail when marked as valid with the wrong timestamp" do
    Samplers.should_receive(:random).with(3).and_return(1)
    Samplers.should_receive(:random).with(3.1).and_return(1)
    fake_launch({'farthest_for_signature_check' => 10})
    get_with_session "/launch/signature_check/1", {}
    post_with_session "/test/signature_check/1", {'launch_url' => 'http://www.example.com/launch'}
    post_with_session "/validate/signature_check/1", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
  it "should succeed when marked as invalid with the wrong timestamp" do
    Samplers.should_receive(:random).with(3).and_return(0)
    Samplers.should_receive(:random).with(3.1).and_return(1)
    fake_launch({'farthest_for_signature_check' => 10})
    get_with_session "/launch/signature_check/1", {}
    post_with_session "/test/signature_check/1", {'launch_url' => 'http://www.example.com/launch'}
    post_with_session "/validate/signature_check/1", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  
  it "should fail when marked as invalid with the correct timestamp" do
    Samplers.should_receive(:random).with(3).and_return(0)
    Samplers.should_receive(:random).with(3.1).and_return(1)
    fake_launch({'farthest_for_signature_check' => 10})
    get_with_session "/launch/signature_check/1", {}
    post_with_session "/test/signature_check/1", {'launch_url' => 'http://www.example.com/launch'}
    post_with_session "/validate/signature_check/1", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
  it "should succeed when marked as valid with an old timestamp" do
    Samplers.should_receive(:random).with(3.1).and_return(0)
    fake_launch({'farthest_for_signature_check' => 10})
    get_with_session "/launch/signature_check/1", {}
    post_with_session "/test/signature_check/1", {'launch_url' => 'http://www.example.com/launch'}
    post_with_session "/validate/signature_check/1", {'valid' => 'No'}
    json = JSON.parse(last_response.body)
    json['correct'].should == true
  end
  
  it "should fail when marked as invalid with an old timestamp" do
    Samplers.should_receive(:random).with(3.1).and_return(0)
    Samplers.should_not_receive(:random).with(3)
    fake_launch({'farthest_for_signature_check' => 10})
    get_with_session "/launch/signature_check/1", {}
    post_with_session "/test/signature_check/1", {'launch_url' => 'http://www.example.com/launch'}
    post_with_session "/validate/signature_check/1", {'valid' => 'Yes'}
    json = JSON.parse(last_response.body)
    json['correct'].should == false
  end
  
  it "should use an old timestamp if it hasn't yet after 3 iterations" do
    Samplers.should_not_receive(:random).with(3)
    Samplers.should_not_receive(:random).with(3.1)
    fake_launch({'farthest_for_signature_check' => 10})
    past_times = ([Time.now.to_i.to_s] * 3).join(",")
    get_with_session "/launch/signature_check/1", {}, 'rack.session' => {'answer_count_for_signature_check_1' => 3, 'answers_for_signature_check_1' => past_times}
    post_with_session "/test/signature_check/1", {'launch_url' => 'http://www.example.com/launch'}
    html = Nokogiri::HTML(last_response.body)
    html.css("input[name='oauth_timestamp']")[0]['value'].to_i.should > 0
    html.css("input[name='oauth_timestamp']")[0]['value'].to_i.should < (Time.now - 10).to_i
    html.css("input[name='oauth_timestamp']")[0]['value'].to_i.should < (Date.today - 50).to_time.to_i
  end
  
  it "should send a blank timestamp if it hasn't yet after 4 iterations" do
    Samplers.should_not_receive(:random).with(3)
    Samplers.should_receive(:random).with(3.1).and_return(1)
    fake_launch({'farthest_for_signature_check' => 10})
    get_with_session "/launch/signature_check/1", {}, 'rack.session' => {'answer_count_for_signature_check_1' => 4, 'answers_for_signature_check_1' => '1,1,1,1'}
    post_with_session "/test/signature_check/1", {'launch_url' => 'http://www.example.com/launch'}
    html = Nokogiri::HTML(last_response.body)
    html.css("input[name='oauth_timestamp']")[0]['value'].should == ""
  end
  
end
