class Activity
  # list of inputs the user will have to return
  #   correct values for these inputs should be stored
  #   in the session
  #   includes what type each is, and how to generate values
  # whether grade passback is enabled
  #   what value is expected for grade passback
  # content selection
  #   what content selection type(s)
  #   what file types
  # TODO: proxy stuff in LTI 2.0
  def self.add(id, category)
    obj = Activity.new(id, category)
    @activities ||= []
    @activities << obj
    obj
  end
  
  attr_accessor :intro
  attr_accessor :category
  attr_accessor :done
  
  def initialize(id, category)
    @id = id
    @category = category
  end
  
  def self.find(id)
    @activities ||= []
    @activities.detect{|a| a.id.to_s == id.to_s}
  end
  
  def self.all(category)
    @activities.select{|a| a.category == category}
  end
  
  def id
    @id
  end
  
  def tests
    @tests
  end
  
  def append_lti_test(type, args={})
    @tests ||= []
    @tests << {:type => type, :args => args}
  end
  
  def append_api_test(type, args={})
    @tests ||= []
    @tests << {:type => type, :args => args}
  end
  
  def add_test(key, args)
    args[:key] = key
    append_lti_test(:fill_in, args)
  end
  
  def add_redirect_test(key, args)
    args[:key] = key
    append_lti_test(:redirect, args)
  end
  
  def add_xml_test(key, lookups, args)
    args[:key] = key
    args[:lookups] = lookups
    append_lti_test(:xml, args)
  end
  
  def add_grade_test(key, args)
    args[:key] = key
    append_lti_test(:grade_passback, args)
  end
  
  def add_session_test
    append_lti_test(:session)
  end
  
  def api_test(key, args={})
    args ||= {}
    args[:key] = key
    type = :api_call
    type = :answer if args[:answer]
    append_api_test(type, args)
  end
  
  def local_api_test(key, args={})
    args ||= {}
    args[:key] = key
    append_api_test(:local_api, args)
  end
  
  def oauth_test(key, args={})
    args ||= {}
    args[:key] = key
    append_api_test(:oauth, args)
  end

  def file_test(key, args={})
    args ||= {}
    args[:key] = key
    append_api_test(:file, args)
  end
end

require './activities/lti/post_launch'
require './activities/lti/signature_check'
require './activities/lti/return_redirect'
require './activities/lti/config_xml'
require './activities/lti/content_test'
require './activities/lti/grade_passback'

require './activities/api/get_requests'
require './activities/api/non_get_requests'
require './activities/api/oauth'
require './activities/api/pagination'
require './activities/api/masquerading'
require './activities/api/file_uploads'

# IDEA: quizzes should be "open-bookmark" quizzes, meaning you can use any 
# page you have bookmarked or that can be navigated to without searching via your bookmarks

