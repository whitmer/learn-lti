require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'Content Extensions Activity' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  it "should succeed with the correct parameters" do
    fake_launch({"farthest_for_content_test" => 10})
    get "/launch/content_test/4", {}
    post "/test/content_test/4", {'launch_url' => 'http://www.example.com/launch'}
    html = Nokogiri::HTML(last_response.body)
    html.css("input[name='launch_presentation_return_url']").length.should == 1
    return_url = html.css("input[name='launch_presentation_return_url']")[0]['value']
    rand_id = return_url.split(/\//)[-1]
    
    get "/tool_return/content_test/4/#{rand_id}?embed_type=file&url=http%3A%2F%2Fwww.bacon.com%2Fbacon.docx&content_type=application%2Fvnd.openxmlformats-officedocument.wordprocessingml.document"
    html = Nokogiri::HTML(last_response.body)
    json = JSON.parse(html.css('#result_data').text)
    json['correct'].should == true
  end
  
  it "should succeed even with extra parameters" do
    fake_launch({"farthest_for_content_test" => 10})
    get "/launch/content_test/4", {}
    post "/test/content_test/4", {'launch_url' => 'http://www.example.com/launch'}
    html = Nokogiri::HTML(last_response.body)
    html.css("input[name='launch_presentation_return_url']").length.should == 1
    return_url = html.css("input[name='launch_presentation_return_url']")[0]['value']
    rand_id = return_url.split(/\//)[-1]
    
    get "/tool_return/content_test/4/#{rand_id}?embed_type=file&url=http%3A%2F%2Fwww.bacon.com%2Fbacon.docx&content_type=application%2Fvnd.openxmlformats-officedocument.wordprocessingml.document&friends=2&alt=hope"
    html = Nokogiri::HTML(last_response.body)
    json = JSON.parse(html.css('#result_data').text)
    json['correct'].should == true
  end
  
  it "should fail with incorrect parameters" do
    fake_launch({"farthest_for_content_test" => 10})
    get "/launch/content_test/4", {}
    post "/test/content_test/4", {'launch_url' => 'http://www.example.com/launch'}
    html = Nokogiri::HTML(last_response.body)
    html.css("input[name='launch_presentation_return_url']").length.should == 1
    return_url = html.css("input[name='launch_presentation_return_url']")[0]['value']
    rand_id = return_url.split(/\//)[-1]
    
    get "/tool_return/content_test/4/#{rand_id}?embed_type=files&url=http%3A%2F%2Fwww.bacon.com%2Fbacon.docx&content_type=application%2Fvnd.openxmlformats-officedocument.wordprocessingml.document&friends=2&alt=hope"
    html = Nokogiri::HTML(last_response.body)
    json = JSON.parse(html.css('#result_data').text)
    json['correct'].should == false
  end
  
  it "should fail with no parameters" do
    fake_launch({"farthest_for_content_test" => 10})
    get "/launch/content_test/4", {}
    post "/test/content_test/4", {'launch_url' => 'http://www.example.com/launch'}
    html = Nokogiri::HTML(last_response.body)
    html.css("input[name='launch_presentation_return_url']").length.should == 1
    return_url = html.css("input[name='launch_presentation_return_url']")[0]['value']
    rand_id = return_url.split(/\//)[-1]
    
    get "/tool_return/content_test/4/#{rand_id}"
    html = Nokogiri::HTML(last_response.body)
    json = JSON.parse(html.css('#result_data').text)
    json['correct'].should == false
  end
end
