require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'Return Redirect Activity' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  it "should trigger success on matching redirect" do
    fake_launch({"farthest_for_return_redirect" => 10})
    get_with_session "/launch/return_redirect/1", {}
    post_with_session "/test/return_redirect/1", {'launch_url' => 'http://www.example.com/launch'}
    html = Nokogiri::HTML(last_response.body)
    html.css("input[name='launch_presentation_return_url']").length.should == 1
    return_url = html.css("input[name='launch_presentation_return_url']")[0]['value']
    rand_id = return_url.split(/\//)[-1]
    
    get_with_session "/tool_return/return_redirect/1/#{rand_id}?lti_msg=Most%20things%20in%20here%20don't%20react%20well%20to%20bullets."
    html = Nokogiri::HTML(last_response.body)
    json = JSON.parse(html.css('#result_data').text)
    json['correct'].should == true
  end
  
  it "should trigger failure on non-matching redirect" do
    fake_launch({"farthest_for_return_redirect" => 10})
    get_with_session "/launch/return_redirect/1", {}
    post_with_session "/test/return_redirect/1", {'launch_url' => 'http://www.example.com/launch'}
    html = Nokogiri::HTML(last_response.body)
    html.css("input[name='launch_presentation_return_url']").length.should == 1
    return_url = html.css("input[name='launch_presentation_return_url']")[0]['value']
    rand_id = return_url.split(/\//)[-1]
    
    get_with_session "/tool_return/return_redirect/1/1234?lti_msg=Most%20things%20in%20here%20don't%20react%20well%20to%20bullets."
    html = Nokogiri::HTML(last_response.body)
    json = JSON.parse(html.css('#result_data').text)
    json['correct'].should == false

    get_with_session "/tool_return/return_redirect/1/#{rand_id}?lti_msg=Most%20things%20in%20here%20don't%20react%20well%20to%20bullets"
    html = Nokogiri::HTML(last_response.body)
    json = JSON.parse(html.css('#result_data').text)
    json['correct'].should == false
  end
  
end
