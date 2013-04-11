module Sinatra
  module Lessons
    def self.registered(app)
      app.helpers Lessons::Helpers
      
      app.get '/launch/:activity/:index' do
        load_user_and_activity
        if !session["answer_count_for_#{params['activity']}_#{@index}"] || session["answer_count_for_#{params['activity']}_#{@index}"] == 0
          session["answers_for_#{params['activity']}_#{@index}"] = ""
        end
        if @activity.category == :api && !@user.settings['access_token']
          oauth_dance
        end
        if @test[:type] == :local_api || @test[:type] == :file
          @user.generate_tokens 
          @user.save
        end
        erb :activity
      end
      
      app.get "/pick_activity" do
        load_user
        erb :pick_activity
      end
      
      # OAuth Test Endpoints
      app.post '/oauth_start/:activity/:index' do
        load_user_and_activity
        return error("valid url required") unless params['url'] && (URI.parse(params['url']) rescue nil)
        session['oauth_url'] = params['url']
        session['oauth_redirect_domain'] = URI.parse(params['url']).host
        session['access_denied'] = @test[:args][:pick_access_denied] && Samplers.random(2) == 0
        session['last_oauth'] = rand(99999)
        @user.settings.delete('fake_code')
        @user.settings.delete('fake_token')
        @user.save
        redirect to(params['url'])
      end
      
      app.get '/login/oauth2/auth' do
        if params['code'] || params['error']
          return "Users shouldn't see this page"
        end
        @user = User.first(:id => params['client_id'])
        url = params['redirect_uri']
        if !@user || @user.user_id != session['user_id']
          return error("Client ID doesn't match current user information")
        elsif !params['redirect_uri']
          return error("redirect_uri parameter required")
        elsif params['redirect_uri'] == 'urn:ietf:wg:oauth:2.0:oob'
          url = nil
        elsif !session['oauth_redirect_domain']
          return error("Missing the launch step")
        elsif session['oauth_redirect_domain'] != URI.parse(params['redirect_uri']).host
          return error("Redirect URI domain doesn't match the launch domain")
        elsif params['response_type'] != 'code'
          return error("Incorrect response_type parameter")
        elsif params['client_secret']
          return error("You shouldn't be sending the client_secret in this request!")
        end
        url ||= "/login/oauth2/auth"
        url += (url.match(/\?/) ? "&" : "?")
        @user.settings ||= {}
        @user.settings['last_oauth'] = session['last_oauth']
        if session['access_denied']
          url += "error=access_denied"
        else
          @user.regenerate_access_token
          @user.settings.delete('fake_token')
          @user.settings['last_redirect_uri'] = params['redirect_uri']
          url += "code=#{@user.settings['fake_code']}"
        end
        @user.save
        redirect to(url)
      end
      
      app.post '/login/oauth2/token' do
        @user = User.first(:id => params['client_id'])
        url = params['redirect_uri']
        if !params['redirect_uri']
          return error("redirect_uri parameter required")
        elsif params['redirect_uri'] != @user.settings['last_redirect_uri']
          return error("redirect_uri doesn't match previous request")
        elsif !params['client_secret']
          return error("Missing client_secret parameter")
        elsif params['client_secret'] != @user.settings['fake_secret']
          return error("Incorrect client_secret")
        elsif params['code'] != @user.settings['fake_code']
          return error("Incorrect code")
        end
        @user.regenerate_access_token
        @user.save
        {
          :access_token => @user.settings['fake_token']
        }.to_json
      end
      
      app.delete '/login/oauth2/token' do
        load_user
        @user.settings ||= {}
        @user.settings.delete 'fake_secret'
        @user.settings.delete 'fake_token'
        @user.settings.delete 'fake_code'
        @user.save
        {
          :logged_out => true
        }.to_json
      end
      
      # Local Api Call Endpoints
      app.get '/api/v1/secret/:activity/:index/:user_id/:code' do
        load_user_and_activity
        @user.settings['expired'] = false
        @user.settings['throttled'] = false
        @user.save
        if @test[:args][:allow_expired] && Samplers.random(2) == 0
          @user.settings['expired'] = true
          @user.save
          halt 400, {"status" => "unauthorized","message" => "Invalid access token."}.to_json
        end
        if @test[:args][:allow_throttling] && Samplers.random(2) == 0
          @user.settings['throttled'] = true
          @user.save
          halt 429, {"status" => "throttled", "message" => "Too Many Requests."}.to_json
        end
        {:secret => "You will buy your weather from me! And by God you'll pay for it."}.to_json
      end
      
      # File Upload Endpoints
      app.post '/api/v1/preflight/:activity/:index/:user_id/:code' do
        load_user_and_activity
        if @test[:args][:phase] == :step_url
          if params['name'] != 'monkey.brains'
            json_error "Bad!"
          elsif params['url'] != "http://www.example.com/files/monkey.brains"
            json_error "Incorrect url parameter"
          elsif params['content_type'] != "application/chilled-dessert"
            json_error "Incorrect content_type parameter"
          elsif params['size'] != "12345"
            json_error "Incorrect size parameter"
          end
          @user.settings ||= {}
          @user.settings["settings_for_file_upload"] = {
            :error => Samplers.random(2) == 0,
            :lookups => (Samplers.random(3) + 1),
            :message_index => Samplers.random(5),
            :id => rand(99999)
          }
          @user.save
          {
            :id => @user.settings["settings_for_file_upload"][:id],
            :upload_status => 'pending',
            :status_url => host + "/api/v1/file_status/#{params['user_id']}/#{params['code']}"
          }.to_json
        else
          if params['name'] != 'this_whole_place_is_slithering.txt'
            json_error("Incorrect filename")
          end
          @user.settings ||= {}
          @user.settings["settings_for_file_upload"] = {
            'a' => "abcd",
            'b' => rand(999999),
            'c' => "ghjkl_#{rand(99)}",
            "d_#{rand(999)}" => "zyxw"
          }
          @user.save
          {
            :upload_url => host + "/api/v1/file_upload/#{params['user_id']}/#{params['code']}?b=#{@user.settings["settings_for_file_upload"]['b']}",
            :upload_params => @user.settings["settings_for_file_upload"]
          }.to_json
        end
      end
      
      app.post '/api/v1/file_upload/:user_id/:code' do
        load_user(true)
        keys = request.env['rack.request.form_hash'].keys
        expected_keys = @user.settings["settings_for_file_upload"].keys + ['file']
        error = nil
        if keys.last != 'file'
          json_error "File parameter must come last"
        elsif (keys - expected_keys).length > 0
          json_error "Unexpected keys present"
        elsif (expected_keys - keys).length > 0
          json_error "Missing expected keys"
        elsif keys != expected_keys
          json_error "Invalid keys"
        end
        @user.settings["settings_for_file_upload"].each do |key, val|
          json_error "Wrong value for #{key}" if params[key].to_s != val.to_s
        end
        if params['file'].is_a?(String)
          json_error "File was sent as a string, not a file. Make sure enctype='multipart/form-data' on the form element."
        elsif !params['file'].is_a?(Hash)
          json_error "File was not sent as the correct type. Make sure enctype='multipart/form-data' on the form element."
        elsif params['file'][:filename] != 'this_whole_place_is_slithering.txt'
          json_error "Incorrect filename"
        elsif !params['file'][:tempfile]
          json_error "Invalid file upload"
        end
        
        redirect to "/api/v1/file_finalize/#{params['user_id']}/#{params['code']}?c=#{@user.settings["settings_for_file_upload"]['c']}"
      end
      
      app.post '/api/v1/file_finalize/:user_id/:code' do
        load_user
        @user.settings ||= {}
        @user.settings["settings_for_file_upload"] = {
          :id => rand(99999),
          :url => 'http://www.example.com/files/this_whole_place_is_slithering.txt',
          "content-type" => 'text/snakes',
          :display_name => 'this_whole_place_is_slithering.txt',
          :size => 12345
        }
        @user.save
        @user.settings["settings_for_file_upload"].to_json
      end
      
      app.get '/api/v1/file_status/:user_id/:code' do
        load_user
        opts = @user.settings['settings_for_file_upload']
        if !opts || opts['error'] == nil || !opts['lookups'] || !opts['message_index'] || !opts['id']
          # ERROR!
          return {
            :api_error => true,
            :message => 'invalid signature'
          }.to_json
        end
        if opts['lookups'] <= 1
          if opts['error']
            msg = Samplers::UPLOAD_ERROR_MESSAGES[opts['message_index']]
            {
              :upload_status => 'error',
              :message => msg
            }.to_json
          else
            {
              :upload_status => 'success',
              :attachment => {
                :id => opts['id']
              }
            }.to_json
          end
        else
          h = {}
          opts.each {|k, v| h[k] = v}
          h['lookups'] = opts['lookups'] - 1
          @user.settings['settings_for_file_upload'] = h
          @user.save
          {
            :upload_status => 'pending'
          }.to_json
        end
      end
      
      # Api Setup Endpoints
      app.post '/setup/:activity/:index' do
        load_user_and_activity
        @error = nil
        if @test[:args][:setup]
          begin
            api = Api.new(@api_host, @token)
            @res = @test[:args][:setup].call(api)
          rescue ApiError => e
            @error = e.to_s
          end
        end
        if @error
          {:ready => false, :error => @error}.to_json
        else
          {:ready => true, :result => @res.to_s}.to_json
        end
      end
      
      # LTI Launch Endpoints
      app.post '/test/:activity/:index' do
        load_user_and_activity
        if !params['launch_url']
          return error("Launch URL required")
        end
        session['launch_url'] = params['launch_url']
      
        tc = tool_config
        rand_id = rand(1000).to_s
        @consumer = tool_consumer(tc, rand_id)
        if @test[:args][:assignment] || @test[:args][:all_params]
          sourced_id = Samplers.random_string
          @launch = Launch.generate(session['key'], session['secret'], sourced_id, @test[:args][:score], @test[:args][:submission_text], @test[:args][:submission_url])
          @consumer.lis_outcome_service_url = host + '/grade_passback/' + @launch.id.to_s
          @consumer.lis_result_sourcedid = sourced_id
        end
        
        param = @test[:args][:param].to_s
        if @test[:args][:pick_return_types]
          session["answers_for_#{params['activity']}_#{@index}"] ||= ""
          so_far = session["answers_for_#{params['activity']}_#{@index}"].split(/,/)
          use_selection_directive = so_far.length == (@test[:args][:iterations] + 1) && !so_far.include?("selection_directive")
          use_selection_directive ||= Samplers.random(3) == 0
          types = nil
          if @test[:args][:lti_return] && @test[:args][:lti_return][:embed_type]
            types = @test[:args][:lti_return][:embed_type]
            @consumer.set_ext_param('content_return_types', types)
            so_far << "return_types"
          elsif use_selection_directive
            types = Samplers.pick_selection_directive
            @consumer.set_non_spec_param('selection_directive', types)
            so_far << "selection_directive"
          else
            types = Samplers.pick_return_types
            @consumer.set_ext_param('content_return_types', types)
            so_far << "return_types"
          end
          @answer = types
          session["answers_for_#{params['activity']}_#{@index}"] = (so_far[0 - @test[:args][:iterations], @test[:args][:iterations]] || []).join(",")
        end
        @launch_data = @consumer.generate_launch_data
        k, v = @launch_data.each_pair.detect{|k, v| k == param} if @test[:args][:param]
        session['last_sig'] = @launch_data['oauth_signature']
      
        if @test[:args][:assignment] && @test[:args][:score]
          v = @launch.id
        elsif @test[:args][:pick_return_types]
          v = @launch_data['ext_content_return_types'] || Samplers::DIRECTIVES[@launch_data['selection_directive']]
        elsif @test[:args][:pick_valid]
          session["answers_for_#{params['activity']}_#{@index}"] ||= ""
          so_far = session["answers_for_#{params['activity']}_#{@index}"].split(/,/)
          can_be_blank = true
          new_answer = v
          if @test[:args][:allow_repeats]
            uniques = so_far - ["_blank_"]
            make_repeat = (so_far.length == @test[:args][:iterations] - 2) && uniques.length == uniques.uniq.length
            make_repeat ||= uniques.length > 0 && (Samplers.random(3.1) == 0)
            if make_repeat
              can_be_blank = false
              new_answer = uniques[0]
              @launch_data[k] = new_answer
            end
          end
          if @test[:args][:allow_invalid]
            make_invalid = so_far.length == @test[:args][:iterations] - 2 && !so_far.include?("_bad_")
            make_invalid ||= Samplers.random(3) == 0
            if make_invalid
              can_be_blank = false
              new_answer = "_bad_"
              @launch_data[k] = @consumer.generate_launch_data['oauth_signature']
            end
          end
          if @test[:args][:allow_old]
            old_time = (Date.today - 50 - rand(50)).to_time.to_i.to_s
            compare_time = (Date.today - 50).to_time.to_i
            make_old = (so_far.length == @test[:args][:iterations] - 2) && !so_far.any?{|s| s.to_i < compare_time }
            make_old ||= Samplers.random(3.1) == 0
            if make_old
              can_be_blank = false
              new_answer = old_time
              @launch_data[k] = new_answer
            end
          end
          if @test[:args][:allow_blank]
            make_blank = so_far.length == @test[:args][:iterations] - 1 && !so_far.include?("_blank_")
            make_blank ||= can_be_blank && Samplers.random(3) == 0
            if make_blank
              new_answer = "_blank_"
              @launch_data[k] = ""
            end
          end
          so_far << (new_answer || "_blank_")
          session["answers_for_#{params['activity']}_#{@index}"] = so_far.reverse[0, @test[:args][:iterations]].reverse.join(",")
          valid = v == new_answer
          session["valid_for_#{params['activity']}_#{@index}"] = valid
        end
      
        if @test[:type] == :redirect
          return_hash = hash_key(rand_id, @test, @test[:args][:lti_return])
          v = return_hash
        end
        
        @answer = v || @answer || ""
        raise "Misconfigured activity: #{params['activity']}/#{@index}" unless @answer
        session["answer_for_#{params['activity']}_#{@index}"] = @answer
        
        erb :auto_launch
      end
    end
    
    module Helpers
      def json_error(str)
        halt(400, {
          :api_error => true,
          :message => str
        }.to_json)
      end
      
      def tool_config
        tc = IMS::LTI::ToolConfig.new(:title => "Test Tool", :launch_url => params['launch_url'])
        if @test[:args][:param] && @test[:args][:param].to_s.match(/custom_/)
          tc.set_custom_param(@test[:args][:param].to_s.sub(/custom_/, ''), Samplers.random_string)
        end
        if @test[:args][:all_params]
          tc.set_custom_param('hoops', Samplers.random_string)
          tc.set_custom_param('yoyo', Samplers.random_string)
        end
        tc
      end
      
      def tool_consumer(tc, rand_id)
        consumer = IMS::LTI::ToolConsumer.new(session['key'], session['secret'])
        consumer.extend IMS::LTI::Extensions::OutcomeData::ToolConsumer
        consumer.set_config(tc)
        
        consumer.resource_link_id = Samplers.random_string
        consumer.launch_presentation_return_url = "#{host}/tool_return/#{params['activity']}/#{params['index']}/#{rand_id}"
        if @test[:args][:include_query_string]
          consumer.launch_presentation_return_url = "#{host}/tool_return/#{params['activity']}/#{params['index']}/#{rand_id}" + "?rand=" + rand(10000).to_s
        end
        consumer.lis_person_name_full = Samplers.random_name
        consumer.user_id = Samplers.random_string
        consumer.roles = Samplers.random_roles || ""
        consumer.context_id = Samplers.random_string
        consumer.context_title = Samplers.random_instance_name
        consumer.tool_consumer_instance_name = Samplers.random_instance_name
        consumer
      end
    end
  end
  
  register Lessons
end