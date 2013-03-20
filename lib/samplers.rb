module Samplers
  DIRECTIVES = {
    'submit_homework' => 'link,file',
    'embed_content' => 'image,iframe,link,basic_lti,oembed',
    'select_link' => 'basic_lti'
  }
  RETURN_TYPES = ['link', 'file', 'image', 'iframe', 'link', 'basic_lti', 'oembed']
  UPLOAD_ERROR_MESSAGES = ["Germany has declared war on the Jones boys.", "Fly, yes. Land, no.", "Why did it have to be snakes?", "\"X\" never, ever marks the spot.", "You are named after the dog?"]
  
  def self.pick_return_types
    RETURN_TYPES.sample(rand(4)).join(',')
  end
  
  def self.pick_selection_directive
    DIRECTIVES.keys.sample(1)
  end
  
  def self.map_return_types(str)
    types = DIRECTIVES[str] || str
    types.split(',').sort.uniq.join(',')
  end

  def self.map_roles(str)
    roles = (str || "").split(/,/)
    roles_hash = {
      'learner' => 'Student', 
      'instructor' => 'Teacher', 
      'contentdeveloper' => 'Designer', 
      'urn:lti:instrole:ims/lis/observer' => 'Observer', 
      'urn:lti:instrole:ims/lis/administrator' => 'Admin'
    }
    roles.map{|r| roles_hash[r.downcase] }.uniq.sort.join(",")
  end
  
  def self.random_string(full=false)
    res = Digest::MD5.hexdigest(Time.now.to_i.to_s + rand.to_s)
    full ? res : res[0, 10]
  end
  
  def self.random_name
    first_name = ["Mohamed", "Youssef" "Hamza", "Abdel-Rahman", "Fatma", "Maha", "Sahar", "Suha", "An", "Dong", "Jian", "Wei", "Dan", "Juan", "Qian"]
    last_name = ["Jones", "Miller", "Washington", "Hansen", "Rands", "Williams", "Johnson", "Lippman", "Abel"]
    first_name.sample + " " + last_name.sample
  end
  
  def self.random_roles
    roles = ['Learner', 'Instructor', 'ContentDeveloper', 'urn:lti:instrole:ims/lis/Observer', 'urn:lti:instrole:ims/lis/Administrator']
    roles.sample(rand(4)).join(",")
  end
  
  def self.random_instance_name
    names = ["Course", "Account", "Club", "Organization", "Org", "Hippo", "Class", "Section", "Lesson", "Semester"]
    names.sample + " " + rand(1000).to_s
  end
  
  def self.random(range)
    rand(range)
  end
end