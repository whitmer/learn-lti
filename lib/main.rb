module Sinatra
  module Main
    def self.registered(app)
      app.helpers Main::Helpers
    
      app.get '/' do
        erb :index
      end
      
      app.get '/config.xml' do
        response.headers['Content-Type'] = "text/xml"
        erb :config_xml, :layout => false
      end
      
      app.get '/api/v1/status' do
        {
          :code => Digest::MD5.hexdigest(Date.today.iso8601)[1, 15],
          :status => 'running'
        }.to_json
      end
    end
    
    module Helpers
      def session_secret
        get :session_secret
      end
    
      def load_token
        if @user && @user.settings['fake_token'] && @user.settings['fake_token'] != params['access_token']
          halt 400, error("Invalid access token")
        end
      end
      
      def load_user(ignore_token=false)
        @user = session['user_id'] && User.first(:user_id => session['user_id'])
        @user ||= !ignore_token && User.first(:fake_token => params['access_token']) if params['access_token']
        if params['user_id'] && params['code']
          @user = User.first(:id => params['user_id'])
          @user = nil if @user && @user.settings['verification'] != params['code']
          load_token unless ignore_token
        end
        if !@user
          halt 400, error("No user information found")
        end
        @user.settings ||= {}
        @token = @user.settings['access_token']
        @api_host = @user.settings['api_host']
        
        @user
      end
      
      def load_activity
        @activity = Activity.find(params['activity'])
        halt error("Invalid activity") if !@activity
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
        puts hash.to_json
        Digest::MD5.hexdigest(hash.to_json)[0, 10]
      end
      
      def host
        request.scheme + "://" + request.host_with_port
      end
    end    
  end
  
  register Main
end