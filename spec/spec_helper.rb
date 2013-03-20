ENV['RACK_ENV']='test'
RACK_ENV='test'
require 'rspec'
require 'rack/test'
require 'json'
require './test_lti'

RSpec.configure do |config|
  config.before(:each) { DataMapper.auto_migrate! }
end

def lti_config
  @config = LtiConfig.generate("Test App")
end

def assert_error_page(msg)
  last_response.body.should match(msg)
end

def get_with_session(path, hash={}, args={})
  args['rack.session'] = session.merge(args['rack.session'] || {})
  get path, hash, args
end

def post_with_session(path, hash={}, args={})
  args['rack.session'] = session.merge(args['rack.session'] || {})
  post path, hash, args
end

def session
  last_request.env['rack.session']
end

def fake_launch(settings={})
  get "/fake_launch"
  session['user_id'].should_not be_nil
  @user = User.last
  @user.settings = settings
  @user.generate_tokens
  @user.save
  @user
end

def user(settings={})
  @user = User.new(:user_id => '1234')
  @user.settings = settings
  @user.save
  @user
end