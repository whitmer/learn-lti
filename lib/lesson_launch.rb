module Sinatra
  module LessonLaunch
    def self.registered(app)
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
          if !params['tool_consumer_instance_guid'] || !params['context_id'] || !user_id
            return error("Invalid tool launch - missing parameters")
          end
          session["user_id"] = params['tool_consumer_instance_guid'] + "." + params['context_id'] + "." + user_id
          @user = User.first_or_create(:user_id => session['user_id'], :lti_config_id => tool_config.id)
          @user.settings ||= {}
          @user.settings['api_host'] ||= 'https://canvas.instructure.com'
          @user.generate_tokens
          @user.save
          session["key"] = Samplers.random_string(true)
          session["secret"] = Samplers.random_string(true)
          session['name'] = params['lis_person_name_full']
          session['is_canvas'] = params['tool_consumer_info_product_family_code'] == 'canvas'
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
          return error("Invalid tool launch - invalid parameters")
        end
      end
    end
  end
  
  register LessonLaunch
end