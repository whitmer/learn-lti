require 'sinatra/base'

module Sinatra
  module Auth
    def self.registered(app)
      app.helpers Auth::Helpers
      
      app.get "/login" do
        request_token = consumer.get_request_token(:oauth_callback => "#{request.scheme}://#{request.host_with_port}/login_success")
        if request_token.token && request_token.secret
          session[:oauth_token] = request_token.token
          session[:oauth_token_secret] = request_token.secret
        else
          return "Authorization failed"
        end
        redirect to("https://api.twitter.com/oauth/authenticate?oauth_token=#{request_token.token}")
      end
  
      app.get "/login_success" do
        verifier = params[:oauth_verifier]
        if params[:oauth_token] != session[:oauth_token]
          return "Authorization failed"
        end
        request_token = OAuth::RequestToken.new(consumer,
          session[:oauth_token],
          session[:oauth_token_secret]
        )
        access_token = request_token.get_access_token(:oauth_verifier => verifier)
        screen_name = access_token.params['screen_name']
    
        if !screen_name
          return "Authorization failed"
        end
    
        @conf = LtiConfig.first(:consumer_key => screen_name)
        @conf ||= LtiConfig.generate("Twitter for @#{screen_name}", screen_name)
        erb :config_tokens
      end
      
    end
    
    module Helpers
      def consumer
        consumer ||= OAuth::Consumer.new(twitter_config.consumer_key, twitter_config.shared_secret, {
          :site => "http://api.twitter.com",
          :request_token_path => "/oauth/request_token",
          :access_token_path => "/oauth/access_token",
          :authorize_path=> "/oauth/authorize",
          :signature_method => "HMAC-SHA1"
        })
      end
    
      def twitter_config
        @@twitter_config ||= LtiConfig.first(:app_name => 'twitter_for_login')
      end
    end
  end

  register Auth
end
