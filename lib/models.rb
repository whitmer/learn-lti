require 'dm-core'
require 'dm-migrations'
require 'dm-aggregates'
require 'dm-types'
require 'sinatra/base'

class LtiConfig
  include DataMapper::Resource
  property :id, Serial
  property :app_name, String
  property :app_contact, String
  property :consumer_key, String, :length => 1024
  property :shared_secret, String, :length => 1024
  
  def self.generate(name)
    conf = LtiConfig.new
    conf.app_name = name
    conf.consumer_key = Digest::MD5.hexdigest(Time.now.to_i.to_s + rand.to_s)
    conf.shared_secret = Digest::MD5.hexdigest(Time.now.to_i.to_s + rand.to_s)
    conf.save
    conf
  end
end

class User
  include DataMapper::Resource
  property :id, Serial
  property :user_id, String, :length => 4096
  property :settings, Json
  property :fake_token, String
  property :lti_config_id, Integer
  belongs_to :lti_config
  
  def farthest_for(activity)
    self.settings ||= {}
    self.settings["farthest_for_#{activity.to_s}"] || -1
  end
  
  def regenerate_access_token
    self.settings ||= {}
    self.settings['fake_token'] = nil
    self.settings['fake_secret'] = nil
    self.settings['fake_code'] = nil
    set_missing_tokens
  end
  
  def set_missing_tokens
    self.settings ||= {}
    self.settings['fake_token'] ||= Digest::MD5.hexdigest("Api token" + Time.now.to_i.to_s + rand(99999).to_s)[0, 20] + (self.id ? "_#{self.id}" : "_0")
    self.settings['fake_secret'] ||= Digest::MD5.hexdigest("Api token" + Time.now.to_i.to_s + rand(99999).to_s)[0, 20]
    self.settings['fake_code'] ||= Digest::MD5.hexdigest("Api token" + Time.now.to_i.to_s + rand(99999).to_s)[0, 20]
    self.fake_token = self.settings['fake_token']
  end
  
  def generate_tokens
    self.settings ||= {}
    self.settings['verification'] ||= Digest::MD5.hexdigest(Time.now.to_i.to_s + rand(99999).to_s)[0, 20]
    set_missing_tokens
  end
  
  def set_farthest(activity, index)
    self.settings["farthest_for_#{activity.to_s}"] ||= index
    self.settings["farthest_for_#{activity.to_s}"] = [index, self.settings["farthest_for_#{activity.to_s}"]].max
    self.save
    self.update_score(activity, index)
    self.settings["farthest_for_#{activity.to_s}"]
  end
  
  def update_score(activity_id, index)
    finished = (index || -1) + 1
    activity = Activity.find(activity_id)
    if activity && self.lti_config && self.settings['outcome_url'] && self.settings["outcome_for_#{activity_id}"]
      url = self.settings['outcome_url']
      id = self.settings["outcome_for_#{activity_id}"]
      key = self.lti_config.consumer_key
      secret = self.lti_config.shared_secret
      percent = (finished.to_f / activity.tests.length.to_f).round(3)
      # POST the grade back
      provider = IMS::LTI::ToolProvider.new(key, secret, {
        'lis_outcome_service_url' => self.settings['outcome_url'],
        'lis_result_sourcedid' => self.settings["outcome_for_#{activity_id}"]
      })
      provider.extend IMS::LTI::Extensions::OutcomeData::ToolProvider
      provider.post_replace_result_with_data!(percent, "text" => "Finished #{finished} of #{activity.tests.length} lessons")
    end
  end
end

class Launch
  include DataMapper::Resource
  property :id, Serial
  property :created_at, DateTime
  property :consumer_key, String, :length => 1024
  property :shared_secret, String, :length => 1024
  property :sourced_id, String, :length => 1024
  property :submission_text, String, :length => 1024
  property :submission_url, String, :length => 4096
  property :expected_score, String
  property :explanation, String
  property :status, String
  
  def self.generate(key, secret, sourced_id, expected_score, text, url)
    Launch.all(:created_at.gt => (Date.today - 21)).destroy
    Launch.create(:consumer_key => key, :shared_secret => secret, :sourced_id => sourced_id, :expected_score => expected_score.to_s, :submission_text => text, :submission_url => url, :created_at => Time.now)
  end
  
  def score_received(sourced_id, score, text, url)
    score = score.to_s.to_f
    self.status = 'success'
    if sourced_id != self.sourced_id
      self.explanation = "The <code>lis_result_sourcedid</code> value should be <code>#{self.sourced_id}</code>, not <code>#{sourced_id}</code>"
      self.status = 'error'
    elsif self.expected_score != "any" && score.to_f != self.expected_score.to_f
      self.explanation = "The <code>score</code> value should be <code>#{self.expected_score.to_f}</code>, not <code>#{score.to_f}</code>"
      self.status = 'error'
    elsif self.submission_text && text != self.submission_text
      self.explanation = "The <code>text</code> value should be <code>#{self.submission_text}</code>, not <code>#{text}</code>"
      self.status = 'error'
    elsif self.submission_url && url != self.submission_url
      self.explanation = "The <code>url</code> value should be <code>#{self.submission_url}</code>, not <code>#{url}</code>"
      self.status = 'error'
    end
    self.save
  end
end
