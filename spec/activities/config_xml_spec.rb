require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'Config XML Activity' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  it "should succeed when it matches the lookups" do
    fake_launch({'farthest_for_config_xml' => 10})
    get "/launch/config_xml/1", {}
    post "/validate/config_xml/1", 'answer' => <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0"
    xmlns:blti = "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"
    xmlns:lticm ="http://www.imsglobal.org/xsd/imslticm_v1p0"
    xmlns:lticp ="http://www.imsglobal.org/xsd/imslticp_v1p0"
    xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation = "http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd
    http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0.xsd
    http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd
    http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
    <blti:title>app</blti:title>
    <blti:description></blti:description>
    <blti:icon></blti:icon>
    <blti:launch_url>http://www.example.com</blti:launch_url>
    <blti:extensions platform="canvas.instructure.com">
      <lticm:property name="tool_id">id</lticm:property>
      <lticm:property name="privacy_level">anonymous</lticm:property>
    </blti:extensions>
    <cartridge_bundle identifierref="BLTI001_Bundle"/>
    <cartridge_icon identifierref="BLTI001_Icon"/>
</cartridge_basiclti_link>  
    EOF
    json = JSON.parse(last_response.body)
    json['correct'].should == true
    json['next'].should == "/launch/config_xml/2"
  end
  
  it "should fail if invalid xml" do
    fake_launch({'farthest_for_config_xml' => 10})
    get "/launch/config_xml/1", {}
    post "/validate/config_xml/1", 'answer' => "coolness"
    json = JSON.parse(last_response.body)
    json['correct'].should == false
    json['explanation'].should == "You're missing the <code>cartridge_basiclti_link</code> tag."
  end
  
  it "should fail if it doesn't match the lookups" do
    fake_launch({'farthest_for_config_xml' => 10})
    get "/launch/config_xml/1", {}
    post "/validate/config_xml/1", 'answer' => <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0"
    xmlns:blti = "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"
    xmlns:lticm ="http://www.imsglobal.org/xsd/imslticm_v1p0"
    xmlns:lticp ="http://www.imsglobal.org/xsd/imslticp_v1p0"
    xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation = "http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd
    http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0.xsd
    http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd
    http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
    <blti:title>app</blti:title>
    <blti:description></blti:description>
    <blti:icon></blti:icon>
    <blti:launch_url>http://www.example.com/wrong</blti:launch_url>
    <blti:extensions platform="canvas.instructure.com">
      <lticm:property name="tool_id">id</lticm:property>
      <lticm:property name="privacy_level">anonymous</lticm:property>
    </blti:extensions>
    <cartridge_bundle identifierref="BLTI001_Bundle"/>
    <cartridge_icon identifierref="BLTI001_Icon"/>
</cartridge_basiclti_link>  
    EOF
    json = JSON.parse(last_response.body)
    json['correct'].should == false
    json['explanation'].should == "The value for the tag matching <code>blti|launch_url</code> should be <code>http://www.example.com</code>, not <code>http://www.example.com/wrong</code>"
  end
  
end
