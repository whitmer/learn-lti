module Sinatra
  module LessonLaunch
    get '/fake_launch' do
      return error("Denied") if ENV['RACK_ENV'] == 'production'
      launch_url = session['launch_url']
      session.clear
      session["user_id"] = '1234'
      session["key"] = Samplers.random_string(true)
      session["secret"] = Samplers.random_string(true)
      session['name'] = 'Fake User'
      session['launch_url'] = launch_url
      redirect to("/launch/post_launch/0")
    end
    
    post '/launch/:activity' do
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
        session["user_id"] = user_id
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
          redirect to("/launch/#{params['activity']}/0")
        end
      else
        return error("Invalid tool launch - invalid parameters")
      end
    end
  end
  
  register LessonLaunch
end