require 'sinatra/base'
require 'ims/lti'
require 'ims/lti/extensions'
require 'digest/md5'
# must include the oauth proxy object
require 'oauth/request_proxy/rack_request'
require 'pp'
require 'json'
require 'nokogiri'
require './activities/activities.rb'
require './lib/main.rb'
require './lib/samplers.rb'
require './lib/models.rb'
require './lib/grade_passback.rb'
require './lib/validation.rb'
require './lib/lesson_launch.rb'
require './lib/lessons.rb'
require './lib/api.rb'

class TestLti < Sinatra::Base
  register Sinatra::Main
  register Sinatra::LessonLaunch
  register Sinatra::Lessons
  register Sinatra::GradePassback
  register Sinatra::Validation

  # sinatra wants to set x-frame-options by default, disable it
  disable :protection
  
  enable :sessions
  raise "session key required" if ENV['RACK_ENV'] == 'production' && !ENV['SESSION_KEY']
  set :session_secret, ENV['SESSION_KEY'] || "local_secret"
  
  env = ENV['RACK_ENV'] || settings.environment
  DataMapper.setup(:default, (ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/#{env}.sqlite3"))
  DataMapper.auto_upgrade!

  
end

class ApiError < StandardError
end
