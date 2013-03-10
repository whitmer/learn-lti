module Sinatra
  module Validation
    get '/tool_return/:activity/:index/:id' do
      load_user_and_activity
      user_answer = hash_key(params['id'], @test, params)
      answer = session["answer_for_#{params['activity']}_#{@index}"]
      correct = (answer && user_answer == answer)
      res = {}
      res[:answer] = session["answer_for_#{params['activity']}_#{@index}"]
      res[:correct] = correct
      res[:error] = "Session lost" unless answer
      @res = handle_result(res)
      erb :redirect_result
    end
    
    post '/validate/:activity/:index' do
      load_user_and_activity
      answer = session["answer_for_#{params['activity']}_#{@index}"]
      correct = (answer && params['answer'] == answer)
      res = {}
      res[:answer] = session["answer_for_#{params['activity']}_#{@index}"]
      if @test[:type] == :xml
        xml = Nokogiri::XML(params['answer'])
        validate_xml(xml)
        correct = @correct
        answer = @answer
        res.delete(:answer)
        res[:explanation] = @explanation
      elsif @test[:type] == :grade_passback
        launch = Launch.first(:id => answer)
        correct = launch.status == 'success'
        res[:explanation] = launch.explanation || "No valid grade passback received"
        res.delete(:explanation) if correct
      elsif @test[:args] && @test[:args][:pick_roles]
        roles = Array(params['role'] || []).sort.join(',')
        mapped_roles = Samplers.map_roles(session["answer_for_#{params['activity']}_#{@index}"])
        res[:answer] = mapped_roles
        correct = (roles == mapped_roles)
        correct = false if !answer
      elsif @test[:args] && @test[:args][:pick_return_types]
        return_types = (params['return_type'] || []).sort.join(',')
        mapped_return_types = Samplers.map_return_types(session["answer_for_#{params['activity']}_#{@index}"])
        res[:answer] = mapped_return_types
        correct = (return_types == mapped_return_types)
      elsif @test[:args] && @test[:args][:pick_valid]
        valid = session["valid_for_#{params['activity']}_#{@index}"]
        res[:valid] = valid
        correct = valid ? (params['valid'] == "Yes") : (params['valid'] == "No")
      end
      res[:correct] = correct
      res[:error] = "Session lost" unless answer
      handle_result(res).to_json
    end
    
    helpers do
      def handle_result(res)
        res[:correct] ||= false
        if res[:correct]
          session["answer_count_for_#{params['activity']}_#{@index}"] ||= 0
          session["answer_count_for_#{params['activity']}_#{@index}"] += 1
          @user.set_farthest(params['activity'], @index)
          if @test[:args][:iterations] && @test[:args][:iterations] > session["answer_count_for_#{params['activity']}_#{@index}"] 
            res[:times_left] = @test[:args][:iterations] - session["answer_count_for_#{params['activity']}_#{@index}"]
          else
            session.delete "answers_for_#{params['activity']}_#{@index}"
            session.delete "answer_count_for_#{params['activity']}_#{@index}"
            res[:done] = !@activity.tests[@index + 1]
            res[:next] = "/launch/#{params['activity']}/#{@index + 1}" if res[:correct] && !res[:done]
          end
        elsif @test[:args][:iterations]
          session["answer_count_for_#{params['activity']}_#{@index}"] = 0
        end
        session.delete "valid_for_#{params['activity']}_#{@index}"
        session.delete "answer_for_#{params['activity']}_#{@index}"
        res
        # update grade for the activity
        # pass back to the gradebook if changed  
      end
      
      def validate_xml(xml)
        @correct = true
        @answer = "xml"
        @explanation = "Everything looks good!"
    
        if xml.css('cartridge_basiclti_link').length == 0
          @correct = false
          @explanation = "You're missing the <code>cartridge_basiclti_link</code> tag."
        elsif xml.css('cartridge_bundle').length == 0
          @correct = false
          @explanation = "You're missing the <code>cartridge_bundle</code> tag."
        elsif xml.css('cartridge_bundle')[0]['identifierref'] != 'BLTI001_Bundle'
          @correct = false
          @explanation = "The value for <code>cartridge_basiclti_link</code> should be <code>BLTI001_Bundle</code>, not <code>#{xml.css('cartridge_bundle')[0]['identifierref']}</code>."
        elsif xml.css('cartridge_icon').length == 0
          @correct = false
          @explanation = "You're missing the <code>cartridge_icon</code> tag."
        elsif xml.css('cartridge_icon')[0]['identifierref'] != 'BLTI001_Icon'
          @correct = false
          @explanation = "The value for <code>cartridge_icon</code> should be <code>BLTI001_Icon</code>, not <code>#{xml.css('cartridge_icon')[0]['identifierref']}</code>."
        end
        if @correct
          (@test[:args][:lookups] || {}).each_pair do |k, v|
            if xml.css(k).length == 0
              @correct = false
              @explanation = "You're missing the tag matching <code>#{k}</code>."
            elsif xml.css(k)[0].text != v
              @correct = false
              @explanation = "The value for the tag matching <code>#{k}</code> should be <code>#{v}</code>, not <code>#{xml.css(k)[0].text}</code>"
            end
          end
        end
      end
    end    
  end
  
  register Validation
end