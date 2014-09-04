module Sinatra
  module LessonLaunch
    def self.registered(app)
      app.helpers LessonLaunch::Helpers
      app.get '/fake_launch' do
        return error("Denied") if ENV['RACK_ENV'] == 'production'
        launch_url = session['launch_url']
        session.clear
        session["user_id"] = '1234'
        @user = User.first_or_create(:user_id => session['user_id'])
        @user.generate_tokens
        @user.settings ||= {}
        @user.settings['api_host'] ||= "https://canvas.instructure.com"
        @user.save
        
        session["key"] = Samplers.random_string(true)
        session["secret"] = Samplers.random_string(true)
        session['name'] = 'Fake User'
        session['launch_url'] = launch_url
        redirect to("/launch/post_launch/0")
      end
      
      app.post '/launch/:activity' do
        # fired by the real LMS, confirm LTI params
        # set session variables
        # render page with button to load test launch in an iframe
        key = params['oauth_consumer_key']
        tool_config = LtiConfig.first(:consumer_key => key)
        if !tool_config
          return error("Invalid tool launch - unknown tool consumer")
        end
        secret = tool_config.shared_secret
        provider = IMS::LTI::ToolProvider.new(key, secret, params)
        session.clear
        if provider.valid_request?(request)
          user_id = params['custom_canvas_user_id'] || params['user_id']
          # find or create user/activity record, including grade passback url
          if !params['tool_consumer_instance_guid'] || !params['context_id'] || !user_id || !params['launch_presentation_return_url']
            return error("Invalid tool launch - missing parameters (tool_consumer_instance_guid, user_id and context_id, and launch_presentation_return_url are required)")
          end
          session['user_id'] = params['tool_consumer_instance_guid'] + "." + params['context_id'] + "." + user_id
          session['is_canvas'] = params['tool_consumer_info_product_family_code'] == 'canvas'
          ugly_host = params['tool_consumer_instance_guid'].split(/\./)[1..-1].join(".") if session['is_canvas'] && params['tool_consumer_instance_guid'] && params['tool_consumer_instance_guid'].match(/\./)
          session['api_host'] = "https://" + (params['custom_canvas_api_domain'] || ugly_host || 'canvas.instructure.com')
          @user = User.first_or_create(:user_id => session['user_id'], :lti_config_id => tool_config.id)
          @user.settings ||= {}
          @user.settings['api_host'] ||= session['api_host']
          
          @user.generate_tokens
          @user.save
          session["key"] = Samplers.random_string(true)
          session["secret"] = Samplers.random_string(true)
          session['name'] = params['lis_person_name_full']
          # check if they're a teacher or not
          # session["permission_for_#{params['custom_canvas_course_id']}"] = 'edit' if provider.roles.include?('instructor') || provider.roles.include?('contentdeveloper') || provider.roles.include?('urn:lti:instrole:ims/lis/administrator') || provider.roles.include?('administrator')
          
          if params['activity'] == 'init'
             redirect to("/pick_activity?return_url=" + CGI.escape(params['launch_presentation_return_url']))
          else        
            activity = Activity.find(params['activity'])
            return error("Invalid activity") unless activity
            if params['lis_outcome_service_url']
              @user.settings ||= {}
              @user.settings["outcome_url"] = params['lis_outcome_service_url']
              @user.settings["outcome_for_#{params['activity']}"] = params['lis_result_sourcedid']
              @user.save
            end
            redirect to("/launch/#{params['activity']}/0")
          end
        else
          return error("Invalid tool launch - invalid parameters, please check your key and secret")
        end
      end
      
      app.get "/canvas_oauth" do
        halt 500, error("User session lost") unless session['user_id'] && session['activity'] && session['activity_index'] && session['api_host']
        return_url = "#{protocol}://#{request.host_with_port}/canvas_oauth"
        code = params['code']
        url = "#{session['api_host']}/login/oauth2/token"
        uri = URI.parse(url)
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = protocol == "https"
        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data({
          :client_id => oauth_config.consumer_key,
          :code => code,
          :client_secret => oauth_config.shared_secret,
          :redirect_uri => CGI.escape(return_url)
        })
        response = http.request(request)
        json = JSON.parse(response.body)
        
        if json && json['access_token']
          user = User.first(:user_id => session['user_id'])
          if user
            user.settings ||= {}
            user.settings['access_token'] = json['access_token']
            user.save
            redirect to("/launch/#{session['activity']}/#{session['activity_index']}")
          else
            halt 400, error("User not found")
          end
        else
          halt 400, error("There was a problem retrieving permission to access Canvas on your behalf. Without this permission we can't test your ability to use the Canvas API. Please reload the page and re-authorize to continue.")
        end
        
      end
    end
    module Helpers
      def protocol
        TestLti.environment == :production ? "https" : "http"
      end
      
      def oauth_config
        @oauth_config ||= LtiConfig.first(:app_name => 'canvas_oauth')
        halt 500, error("Missing oauth config") unless @oauth_config
        @oauth_config
      end
         
      def oauth_dance
        halt 500, error("Missing api host") unless session['api_host']
        session['activity'] = params['activity']
        session['activity_index'] = params['index']
        return_url = "#{protocol}://#{request.host_with_port}/canvas_oauth"
        redirect to("#{session['api_host']}/login/oauth2/auth?client_id=#{oauth_config.consumer_key}&response_type=code&redirect_uri=#{CGI.escape(return_url)}")
      end
    end
  end
  
  register LessonLaunch
end