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
  def self.add(id)
    obj = Activity.new(id)
    @activities ||= []
    @activities << obj
    obj
  end
  
  attr_accessor :intro
  attr_accessor :done
  
  def initialize(id)
    @id = id
  end
  
  def self.find(id)
    @activities ||= []
    @activities.detect{|a| a.id.to_s == id.to_s}
  end
  
  def self.all
    @activities
  end
  
  def id
    @id
  end
  
  def tests
    @tests
  end
  
  def append_test(type, args={})
    @tests ||= []
    @tests << {:type => type, :args => args}
  end
  
  def add_test(key, args)
    args[:key] = key
    append_test(:fill_in, args)
  end
  
  def add_redirect_test(key, args)
    args[:key] = key
    append_test(:redirect, args)
  end
  
  def add_xml_test(key, lookups, args)
    args[:key] = key
    args[:lookups] = lookups
    append_test(:xml, args)
  end
  
  def add_grade_test(key, args)
    args[:key] = key
    append_test(:grade_passback, args)
  end
  
  def add_session_test
    append_test(:session)
  end
end

require './activities/post_launch'
require './activities/signature_check'
require './activities/return_redirect'
require './activities/config_xml'
require './activities/content_test'
require './activities/grade_passback'

# IDEA: quizzes should be "open-bookmark" quizzes, meaning you can use any 
# page you have bookmarked or that can be navigated to without searching via your bookmarks

#session_test = Activity.add(:session_test)
#  session_test.intro = <<-EOF
#    Make sure you know how to set up session correctly so it sticks even after page loads
#  EOF
#  session_test.add_session_test


