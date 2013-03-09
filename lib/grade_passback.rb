module Sinatra
  module GradePassback
    post '/grade_passback/:launch_id' do
      # Need to find the consumer key/secret to verify the post request
      # If your return url has an identifier for a specific tool you can use that
      # Or you can grab the consumer_key out of the HTTP_AUTHORIZATION and look up the secret
      # Or you can parse the XML that was sent and get the lis_result_sourcedid which
      # was set at launch time and look up the tool using that somehow.
    
      req = IMS::LTI::OutcomeRequest.new
      req.extend IMS::LTI::Extensions::OutcomeData::OutcomeRequest
      req.process_post_request(request)
      sourcedid = req.lis_result_sourcedid
    
      # todo - create some simple key management system
      launch = Launch.first(:id => params['launch_id'])
      throw_oauth_error unless launch
      consumer = IMS::LTI::ToolConsumer.new(launch.consumer_key, launch.shared_secret)
    
      if consumer.valid_request?(request)
        if consumer.request_oauth_timestamp.to_i - Time.now.utc.to_i > 60*60
          throw_oauth_error
        end
        # this isn't actually checking anything like it should, just want people
        # implementing real tools to be aware they need to check the nonce
        if was_nonce_used_in_last_x_minutes?(consumer.request_oauth_nonce, 60)
          throw_oauth_error
        end
    
        res = IMS::LTI::OutcomeResponse.new
        res.message_ref_identifier = req.message_identifier
        res.operation = req.operation
        res.code_major = 'success'
        res.severity = 'status'
    
        if launch.sourced_id != req.lis_result_sourcedid
          res.code_major = 'unsupported'
          res.severity = 'status'
          res.description = "Invalid sourced_id"
        elsif req.replace_request?
          res.description = "Your old score has been replaced with #{req.score}"
          res.score = req.score
        elsif req.read_request?
          res.description = "You score is #{req.score}"
          res.score = req.score.to_i
        elsif req.delete_request?
          res.description = "You score has been cleared"
        else
          res.code_major = 'unsupported'
          res.severity = 'status'
          res.description = "#{req.operation} is not supported"
        end
        launch.score_received(req.lis_result_sourcedid, req.score, req.outcome_text, req.outcome_url)
    
        headers 'Content-Type' => 'text/xml'
        res.generate_response_xml
      else
        throw_oauth_error
      end
    end
    
    helpers do
      def throw_oauth_error
        response['WWW-Authenticate'] = "OAuth realm=\"http://#{request.env['HTTP_HOST']}\""
        throw(:halt, [401, "Not authorized\n"])
      end
      
      def was_nonce_used_in_last_x_minutes?(nonce, minutes=60)
        # some kind of caching solution or something to keep a short-term memory of used nonces
        false
      end
    end
  end 
  register GradePassback
end