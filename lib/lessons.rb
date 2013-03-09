module Sinatra
  module Lessons
    get '/launch/:activity/:index' do
      load_user_and_activity
      erb :activity
    end
    
    get "/pick_activity" do
      load_user
      erb :pick_activity
    end
    
    post '/test/:activity/:index' do
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
        use_selection_directive = so_far.length == @test[:args][:iterations] = 1 && !so_far.include?("selection_directive")
        use_selection_directive ||= Samplers.random(3) == 0
        if @test[:args][:lti_return][:embed_type]
          types = @test[:args][:lti_return][:embed_type]
          @consumer.set_ext_variable('ext_content_return_types', types)
          so_far << "return_types"
        elsif use_selection_directive
          @consumer.selection_directive = Samplers.pick_selection_directive
          so_far << "selection_directive"
        else
          @consumer.set_ext_variable('ext_content_return_types', Samplers.pick_return_types)
          so_far << "return_types"
        end
        session["answers_for_#{params['activity']}_#{@index}"] = (so_far[0 - @test[:args][:iterations], @test[:args][:iterations]] || []).join(",")
      end
      @launch_data = @consumer.generate_launch_data
      k, v = @launch_data.each_pair.detect{|k, v| k == param}
    
      if @test[:args][:assignment]
        v = @launch.id
      elsif @test[:args][:pick_return_types]
        v = @launch_data['ext_content_return_types'] || Samplers::DIRECTIVES[@launch_data['selection_directive']]
      elsif @test[:args][:pick_valid]
        session["answers_for_#{params['activity']}_#{@index}"] ||= ""
        so_far = session["answers_for_#{params['activity']}_#{@index}"].split(/,/)
        new_answer = v
        if @test[:args][:allow_repeats]
          uniques = so_far - ["_blank_"]
          make_repeat = so_far.length == @test[:args][:iterations] - 2 && uniques.length == uniques.uniq.length
          make_repeat ||= uniques.length > 0 && Samplers.random(3.1) == 0
          if make_repeat
            new_answer = uniques[0]
          end
        end
        if @test[:args][:allow_invalid]
          make_invalid = so_far.length == @test[:args][:iterations] - 2 && !so_far.include?("_bad_")
          make_invalid ||= Samplers.random(3) == 0
          if make_invalid
            new_answer = "_bad_"
            @launch_data[k] = v.reverse
          end
        end
        if @test[:args][:allow_old]
          old_time = (Date.today - 50 - rand(50)).to_time.to_i.to_s
          compare_time = (Date.today - 50).to_time.to_i
          make_old = so_far.length == @test[:args][:iterations] - 2 && !so_far.any?{|s| s.to_i < compare_time }
          make_old ||= Samplers.random(3.1) == 0
          if make_old
            new_answer = old_time
          end
        end
        if @test[:args][:allow_blank]
          make_blank = so_far.length == @test[:args][:iterations] - 1 && !so_far.include?("_blank_")
          make_blank ||= Samplers.random(3) == 0
          if make_blank
            new_answer = "_blank_"
          end
        end
        so_far << (new_answer || "_blank_")
        session["answers_for_#{params['activity']}_#{@index}"] = (so_far[0 - @test[:args][:iterations], @test[:args][:iterations]] || []).join(",")
        valid = v == new_answer
        session["valid_for_#{params['activity']}_#{@index}"] = valid
      end
    
      if @test[:type] == :redirect
        return_hash = hash_key(rand_id, @test, @test[:args][:lti_return])
        v = return_hash
      end
      
      @answer = v || ""
      raise "Misconfigured activity: #{params['activity']}/#{@index}" unless @answer
      session["answer_for_#{params['activity']}_#{@index}"] = @answer
      
      erb :auto_launch
    end
    
    helpers do
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