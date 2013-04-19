require 'sinatra/base'

module Sinatra
  module Stats
    def self.registered(app)
      app.helpers Stats::Helpers
      
      app.get '/stats' do 
        erb :stats
      end
      
      app.get '/api/v1/stats/:activity' do
        load_activity
        progresses = User.all.map{|u| (u.settings || {})["farthest_for_#{params['activity']}"]}.compact
        counts = {}
        progresses.each do |n|
          counts[n] ||= 0
          counts[n] += 1
        end
        names = @activity.tests.map{|t| t[:args][:key] }
        {:counts => counts, :max => @activity.tests.length, :total => progresses.length, :names => names}.to_json
      end
    end
    
    module Helpers
    end
  end 
  register Stats
end