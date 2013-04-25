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
  
  it "should handle multiple valid encodings" do
    fake_launch({"farthest_for_return_redirect" => 10})
    get_with_session "/launch/return_redirect/3", {}
    post_with_session "/test/return_redirect/3", {'launch_url' => 'http://www.example.com/launch'}
    html = Nokogiri::HTML(last_response.body)
    html.css("input[name='launch_presentation_return_url']").length.should == 1
    return_url = html.css("input[name='launch_presentation_return_url']")[0]['value']
    rand_id = return_url.split(/\//)[-1]

    msg = CGI.escape("Who's going to save you, Junior?!")
    get_with_session "/tool_return/return_redirect/3/#{rand_id}?lti_errormsg=#{msg}"
    html = Nokogiri::HTML(last_response.body)
    json = JSON.parse(html.css('#result_data').text)
    json['correct'].should == true


    get_with_session "/launch/return_redirect/3", {}
    post_with_session "/test/return_redirect/3", {'launch_url' => 'http://www.example.com/launch'}
    html = Nokogiri::HTML(last_response.body)
    html.css("input[name='launch_presentation_return_url']").length.should == 1
    return_url = html.css("input[name='launch_presentation_return_url']")[0]['value']
    rand_id = return_url.split(/\//)[-1]

    msg = "Who%27s%20going%20to%20save%20you%2C%20Junior%3F!"    
    get_with_session "/tool_return/return_redirect/3/#{rand_id}?lti_errormsg=#{msg}"
    html = Nokogiri::HTML(last_response.body)
    json = JSON.parse(html.css('#result_data').text)
    json['correct'].should == true


    get_with_session "/launch/return_redirect/3", {}
    post_with_session "/test/return_redirect/3", {'launch_url' => 'http://www.example.com/launch'}
    html = Nokogiri::HTML(last_response.body)
    html.css("input[name='launch_presentation_return_url']").length.should == 1
    return_url = html.css("input[name='launch_presentation_return_url']")[0]['value']
    rand_id = return_url.split(/\//)[-1]

    msg = "Who%27s+going+to+save+you%2C+Junior%3F%21"    
    get_with_session "/tool_return/return_redirect/3/#{rand_id}?rand=1234&lti_errormsg=#{msg}"
    html = Nokogiri::HTML(last_response.body)
    json = JSON.parse(html.css('#result_data').text)
    json['correct'].should == true
  end
end
