module Sinatra
  module Auth
    def self.registered(app)
      app.helpers Auth::Helpers
    
      app.get '/oauth_success' do
        load_user
        api = Api.new(@api_host, "ignore")
        json = api.post("/login/oauth2/token", {
          :client_id => auth_config.consumer_key,
          :redirect_uri => redirect_uri,
          :client_secret => auth_config.shared_secret,
          :code => params['code']
        })
        if json['access_token']
          @user.settings['access_token'] = json['access_token']
          @user.settings['api_host'] = @api_host
          @user.save
          redirect to(session['return_path'])
        else
          error("Authorization failed")
        end
      end
      
    end
    
    module Helpers
      def oauth_dance
        halt(400, "Missing authorization data") unless auth_config
        session['return_path'] = request.path
        url = @api_host + "/login/oauth2/auth?request_type=code&client_id=#{auth_config.consumer_key}&redirect_uri=#{CGI.escape(redirect_uri)}" 
        redirect to(url)
      end
      
      def redirect_uri
        host + "/oauth_success"
      end
      
      def auth_config
        @auth_config ||= LtiConfig.first(:app_name => "Canvas Auth")
      end
    end    
  end
  
  register Auth
end