require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'Activity Rendering' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end

  it "should not let the user sneak ahead in the flow" do
    fake_launch
    get "/launch/post_launch/1"
    last_response.body.should == "Too far too soon!"
    post "/test/post_launch/1"
    last_response.body.should == "Too far too soon!"
  end
  
  it "should require launch url for post tests" do
    fake_launch({"farthest_for_post_launch" => 1})
    post "/test/post_launch/1", {}
    last_response.body.should == "Launch URL required"
  end
  
  Activity.all(:lti).each do |activity|
    describe "#{activity.id} render checks" do  
      activity.tests.each_with_index do |test, idx|
        it "should allow checking for #{test[:args][:param]}" do
          fake_launch({"farthest_for_#{activity.id}" => activity.tests.length})
          get "/launch/#{activity.id}/#{idx}", {}
          last_response.body[activity.tests[idx][:args][:explanation][0, 100]].should_not == nil
          html = Nokogiri::HTML(last_response.body)
          if test[:type] == :fill_in
            html.css('form#answer').length.should == 1
            if test[:args][:pick_valid]
              html.css("form#answer select[name='valid']").length.should == 1
            elsif test[:args][:pick_roles]
              html.css("form#answer ul li input[type='checkbox']").length.should > 1
            else
              html.css("form#answer input[name='answer']").length.should == 1
            end
          elsif test[:type] == :xml
            html.css('form#answer').length.should == 1
            html.css("form#answer textarea[name='answer']").length.should == 1
          elsif test[:type] == :redirect
            html.css('#answer .waiting').length.should == 1
          elsif test[:type] == :grade_passback
            html.css('form#answer').length.should == 1
            html.css('form#answer input').length.should == 0
          end
        end
        if test[:type] == :fill_in || test[:type] == :redirect || test[:type] == :grade_passback
          it "should allow posting to launch for #{test[:args][:param]}" do
            fake_launch({"farthest_for_#{activity.id}" => activity.tests.length})
            post "/test/#{activity.id}/#{idx}", {'launch_url' => 'http://www.example.com/launch/it/up'}
            last_response.should be_ok
            html = Nokogiri::HTML(last_response.body)
            html.css('form#ltiLaunchForm').length.should == 1
            html.css('form#ltiLaunchForm')[0]['action'].should == 'http://www.example.com/launch/it/up'
          end
        end
      end
    end
  end
  
end
