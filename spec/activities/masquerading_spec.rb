require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'Masquerading Tests' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  it "should check for correct masquerading error message" do
    fake_launch({'farthest_for_masquerading_and_ids' => 10})
    get_with_session "/launch/masquerading_and_ids/0", {}
    answer = "Invalid as_user_id"
    post_with_session "/validate/masquerading_and_ids/0", {'answer' => answer}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == true

    post_with_session "/validate/masquerading_and_ids/0", {'answer' => answer + "a"}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == false
  end
  
  it "should check for correct SIS id parameter" do
    fake_launch({'farthest_for_masquerading_and_ids' => 10})
    get_with_session "/launch/masquerading_and_ids/1", {}
    answer = "/api/v1/users/sis_user_id:user_1/profile"
    Api.any_instance.should_receive(:get).with('/api/v1/users/self/profile').and_return({'id' => 1})
    post_with_session "/validate/masquerading_and_ids/1", {'answer' => answer}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == true      
  end
  
  it "should check for correctly-encoded SIS id parameter" do
    fake_launch({'farthest_for_masquerading_and_ids' => 10})
    get_with_session "/launch/masquerading_and_ids/2", {}
    answer = "hex:sis_user_id:312f626f62406578616d706c652e636f6d"
    Api.any_instance.should_receive(:get).with('/api/v1/users/self/profile').and_return({'id' => 1, 'primary_email' => 'bob@example.com'})
    post_with_session "/validate/masquerading_and_ids/2", {'answer' => answer}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == true      
  end
end

#   masquerading.api_test :sis_id_hex_encoding, :setup => lambda{|api|
#     json = api.get('/api/v1/users/self/profile')
#     "#{json['id']}/#{json['primary_email']}"
#   }, :lookup => lambda{|api|
#     json = api.get('/api/v1/users/self/profile')
#     str = "#{json['id']}/#{json['primary_email']}"
#     "hex:sis_user_id:" + str.unpack("H*")[0]
#   }, :explanation => <<-EOF
#     <p>Canvas IDs are always numeric, but SIS IDs can sometimes be some pretty
#     crazy strings with non-alphanumeric characters. Often it's not an issue, but 
#     if there's any chance you're dealing with SIS IDs containing "/" or "." characters,
#     then you're going to need to support the hex encoding format we support for
#     complex SIS IDs.</p>
#     <p>This is done by converting each UTF-8 byte to a hex-encoded digit and then 
#     displayed as ASCII, high nibble first. In ruby, this is easy using 
#     <code>str.unpack("H*")[0]</code>. "/" will end up as <code>2f</code>, 
#     "." will be <code>2e</code>, "0" becomes <code>30</code>, "1"
#     becomes <code>31</code>, etc.</p>
#     <p>Once you have the hex value, you enter it as <code>hex:sis_user_id:&lt;sis_id&gt;</code>
#     or <code>hex:sis_course_id:&lt;sis_id&gt;</code>, just like you would have
#     entered <code>sis_user_id&lt;sis_id&gt;</code> before.</p>
#     <p>For this test, I want you to tel me the value you'd enter for
#     <code>&lt;user_id&gt;</code> if all you knew were the users's SIS ID,
#     <code class='setup_result'>...</code>.</p>
#   EOF
#   
#   
#   masquerading.api_test :self_ids, :lookup => lambda {|api|
#     json = api.get("/api/v1/users/self/enrollments")
#     json[-1]['id'].to_s
#   }, :explanation => <<-EOF
#     <p>Last, let's make sure we cover one you're already been using. When
#     making API calls asking for a <code>&lt;user_id&gt;</code> you can substitube
#     <code>self</code> for the user ID. This will then use the ID of the user 
#     associated with the current access token. If you use the access token you 
#     generated in your profile then it allows you to make requests for your own
#     information without having to remember your user ID, but it also applies for
#     any other access tokens.</p>
#     <p>Let's see if you can use it. get_with_session the 
#     <a href="https://canvas.instructure.com/doc/api/all_resources.html#method.enrollments_api.index">list of
#     enrollments</a> tied to your personal account and enter the ID of the last enrollment
#     provided in the first page of results using the default number of results per page.</p>
#   EOF
