require 'sinatra'
require 'ims/lti'
require 'ims/lti/extensions'
require 'digest/md5'
# must include the oauth proxy object
require 'oauth/request_proxy/rack_request'
require 'pp'
require 'json'
require 'nokogiri'
require './activities/activities.rb'
require './lib/samplers.rb'
require './lib/models.rb'
require './lib/grade_passback.rb'
require './lib/validation.rb'
require './lib/lesson_launch.rb'
require './lib/lessons.rb'

# sinatra wants to set x-frame-options by default, disable it
disable :protection

enable :sessions

get '/' do
  erb :index
end

get '/config.xml' do
  response.headers['Content-Type'] = "text/xml"
  erb :config_xml, :layout => false
end

def load_user
  @user = User.first(:user_id => session['user_id'])
  if !session['user_id'] || !@user
    halt error("Session lost")
  end
end

def load_user_and_activity
  load_user
  @index = params[:index].to_i
  @activity = Activity.find(params['activity'])
  halt error("Invalid activity") if !@activity || !@activity.tests[@index]
  @next_enabled = @activity.tests[@index + 1] && @user.farthest_for(params['activity']) >= @index
  if @index > @user.farthest_for(params['activity']) + 1
    halt error("Too far too soon!")
  end
  @test = @activity.tests[@index]
end

def hash_key(id, test, args)
  hash = {:rand_id => id}
  args ||= {}
  (test[:args][:lti_return] || {}).keys.each do |arg|
    hash[arg] = args[arg] || args[arg.to_s]
  end
  Digest::MD5.hexdigest(hash.to_json)[0, 10]
end

def host
  request.scheme + "://" + request.host_with_port
end

