require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'File Upload Tests' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  it "should succeed on preflight for step 1" do
    fake_launch({'farthest_for_file_uploads' => 10})
    get_with_session "/launch/file_uploads/0", {}
    post_with_session "/preflight/file_uploads/0/#{@user.id}/#{@user.settings['verification']}", {'name' => 'this_whole_place_is_slithering.txt', 'size' => 1, 'content_type' => 'text/plain', 'access_token' => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    answer = json['upload_url']
    post_with_session "/validate/file_uploads/0", {'answer' => answer}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == true      
  end
  
  it "should handle valid uploads" do
    fake_launch({'farthest_for_file_uploads' => 10})
    get_with_session "/launch/file_uploads/0", {}
    post_with_session "/preflight/file_uploads/0/#{@user.id}/#{@user.settings['verification']}", {'name' => 'this_whole_place_is_slithering.txt', 'size' => 1, 'content_type' => 'text/plain', 'access_token' => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    url = json['upload_url'].sub(/http:\/\/example.org/, '')
    hash = @user.reload.settings['settings_for_file_upload']
    hash['file'] = {:filename => "this_whole_place_is_slithering.txt", :tempfile => ""}

    post_with_session url, hash
    last_response.body.should == ""
    last_response.location.should == "http://example.org/api/v1/file_finalize/#{@user.id}/#{@user.settings['verification']}?c=#{@user.settings['settings_for_file_upload']['c']}"
    
    post_with_session "/validate/file_uploads/1", {'answer' => last_response.location}
    json = JSON.parse(last_response.body)
    json['correct'].should == true      
  end
  
  it "should error on invalid uploads" do
    fake_launch({'farthest_for_file_uploads' => 10})
    get_with_session "/launch/file_uploads/0", {}
    post_with_session "/preflight/file_uploads/0/#{@user.id}/#{@user.settings['verification']}", {'name' => 'this_whole_place_is_slithering.txt', 'size' => 1, 'content_type' => 'text/plain', 'access_token' => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    url = json['upload_url'].sub(/http:\/\/example.org/, '')
    hash = @user.reload.settings['settings_for_file_upload']
    hash['file'] = {:filename => "this_whole_place_is_slithering.txts", :tempfile => ""}

    post_with_session url, hash
    json = JSON.parse(last_response.body)
    json['message'].should == "Incorrect filename"

    fake_launch({'farthest_for_file_uploads' => 10})
    get_with_session "/launch/file_uploads/0", {}
    post_with_session "/preflight/file_uploads/0/#{@user.id}/#{@user.settings['verification']}", {'name' => 'this_whole_place_is_slithering.txt', 'size' => 1, 'content_type' => 'text/plain', 'access_token' => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    url = json['upload_url'].sub(/http:\/\/example.org/, '')
    hash = @user.reload.settings['settings_for_file_upload']
    hash['file'] = "this_whole_place_is_slithering.txt"

    post_with_session url, hash
    json = JSON.parse(last_response.body)
    json['message'].should == "File was sent as a string, not a file. Make sure enctype='multipart/form-data' on the form element."
    fake_launch({'farthest_for_file_uploads' => 10})
    get_with_session "/launch/file_uploads/0", {}
    post_with_session "/preflight/file_uploads/0/#{@user.id}/#{@user.settings['verification']}", {'name' => 'this_whole_place_is_slithering.txt', 'size' => 1, 'content_type' => 'text/plain', 'access_token' => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    url = json['upload_url'].sub(/http:\/\/example.org/, '')
    hash = @user.reload.settings['settings_for_file_upload']
    hash['file'] = {:filename => "this_whole_place_is_slithering.txts"}

    post_with_session url, hash
    json = JSON.parse(last_response.body)
    json['message'].should == "Incorrect filename"
  end
  
  it "should error on upload params in wrong order" do
    fake_launch({'farthest_for_file_uploads' => 10})
    get_with_session "/launch/file_uploads/0", {}
    post_with_session "/preflight/file_uploads/0/#{@user.id}/#{@user.settings['verification']}", {'name' => 'this_whole_place_is_slithering.txt', 'size' => 1, 'content_type' => 'text/plain', 'access_token' => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    url = json['upload_url'].sub(/http:\/\/example.org/, '')
    hash = {'file' => {:filename => "this_whole_place_is_slithering.txts", :tempfile => ""}}
    hash.merge!(@user.reload.settings['settings_for_file_upload'])
    hash.keys.last.should_not == "file"
    
    post_with_session url, hash
    json = JSON.parse(last_response.body)
    json['message'].should == "File parameter must come last"
  end
  
  it "should error on extra upload params" do
    fake_launch({'farthest_for_file_uploads' => 10})
    get_with_session "/launch/file_uploads/0", {}
    post_with_session "/preflight/file_uploads/0/#{@user.id}/#{@user.settings['verification']}", {'name' => 'this_whole_place_is_slithering.txt', 'size' => 1, 'content_type' => 'text/plain', 'access_token' => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    url = json['upload_url'].sub(/http:\/\/example.org/, '')
    hash = @user.reload.settings['settings_for_file_upload']
    hash['friends'] = 'cool'
    hash['file'] = {:filename => "this_whole_place_is_slithering.txt", :tempfile => ""}

    post_with_session url, hash
    json = JSON.parse(last_response.body)
    json['message'].should == "Unexpected keys present"
  end
  
  it "should error when missing upload params" do
    fake_launch({'farthest_for_file_uploads' => 10})
    get_with_session "/launch/file_uploads/0", {}
    post_with_session "/preflight/file_uploads/0/#{@user.id}/#{@user.settings['verification']}", {'name' => 'this_whole_place_is_slithering.txt', 'size' => 1, 'content_type' => 'text/plain', 'access_token' => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    url = json['upload_url'].sub(/http:\/\/example.org/, '')
    hash = @user.reload.settings['settings_for_file_upload']
    hash.delete('a')
    hash['file'] = {:filename => "this_whole_place_is_slithering.txt", :tempfile => ""}

    post_with_session url, hash
    json = JSON.parse(last_response.body)
    json['message'].should == "Missing expected keys"
  end

  it "should succeed on valid confirmation" do
    fake_launch({'farthest_for_file_uploads' => 10})
    get_with_session "/launch/file_uploads/0", {}
    post_with_session "/preflight/file_uploads/0/#{@user.id}/#{@user.settings['verification']}", {'name' => 'this_whole_place_is_slithering.txt', 'size' => 1, 'content_type' => 'text/plain', 'access_token' => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    url = json['upload_url'].sub(/http:\/\/example.org/, '')
    hash = @user.reload.settings['settings_for_file_upload']
    hash['file'] = {:filename => "this_whole_place_is_slithering.txt", :tempfile => ""}

    post_with_session url, hash
    last_response.body.should == ""
    last_response.location.should == "http://example.org/api/v1/file_finalize/#{@user.id}/#{@user.settings['verification']}?c=#{@user.settings['settings_for_file_upload']['c']}"
    
    url = last_response.location.sub(/http:\/\/example.org/, '')
    post_with_session url, {:access_token => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    json.should == @user.reload.settings['settings_for_file_upload']
  end
  it "should error on invalid confirmation" do
    fake_launch({'farthest_for_file_uploads' => 10})
    get_with_session "/launch/file_uploads/2", {}
    post_with_session "/preflight/file_uploads/0/#{@user.id}/#{@user.settings['verification']}", {'name' => 'this_whole_place_is_slithering.txt', 'size' => 1, 'content_type' => 'text/plain', 'access_token' => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    url = json['upload_url'].sub(/http:\/\/example.org/, '')
    hash = @user.reload.settings['settings_for_file_upload']
    hash['file'] = {:filename => "this_whole_place_is_slithering.txt", :tempfile => ""}

    post_with_session url, hash
    last_response.body.should == ""
    last_response.location.should == "http://example.org/api/v1/file_finalize/#{@user.id}/#{@user.settings['verification']}?c=#{@user.settings['settings_for_file_upload']['c']}"
    
    url = last_response.location.sub(/http:\/\/example.org/, '')
    post_with_session url, {:access_token => @user.settings['fake_token'] + "a"}
    last_response.body.should == 'Invalid access token'
  end
  it "should succeed when correct id is entered after valid confirmation" do
    fake_launch({'farthest_for_file_uploads' => 10})
    get_with_session "/launch/file_uploads/2", {}
    post_with_session "/preflight/file_uploads/0/#{@user.id}/#{@user.settings['verification']}", {'name' => 'this_whole_place_is_slithering.txt', 'size' => 1, 'content_type' => 'text/plain', 'access_token' => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    url = json['upload_url'].sub(/http:\/\/example.org/, '')
    hash = @user.reload.settings['settings_for_file_upload']
    hash['file'] = {:filename => "this_whole_place_is_slithering.txt", :tempfile => ""}

    post_with_session url, hash
    last_response.body.should == ""
    last_response.location.should == "http://example.org/api/v1/file_finalize/#{@user.id}/#{@user.settings['verification']}?c=#{@user.settings['settings_for_file_upload']['c']}"
    
    url = last_response.location.sub(/http:\/\/example.org/, '')
    post_with_session url, {:access_token => @user.settings['fake_token']}
    json = JSON.parse(last_response.body)
    json.should == @user.reload.settings['settings_for_file_upload']
    id = json['id']

    post_with_session "/validate/file_uploads/2", {'answer' => id.to_s}
    json = JSON.parse(last_response.body)
    json['answer'].should == id.to_s
    json['correct'].should == true      
  end
  
  it "should accept upload urls and return status url" do
    fake_launch({'farthest_for_file_uploads' => 10})
    get_with_session "/launch/file_uploads/3", {}

    Samplers.should_receive(:random).with(2).and_return(1)
    Samplers.should_receive(:random).with(3).and_return(2)
    Samplers.should_receive(:random).with(5).and_return(2)
    post_with_session "/preflight/file_uploads/3/#{@user.id}/#{@user.settings['verification']}", {'url' => 'http://www.example.com/files/monkey.brains', 'name' => 'monkey.brains', 'size' => 12345, 'content_type' => 'application/chilled-dessert', 'access_token' => @user.settings['fake_token']}
    last_session = session
    @user.reload.settings['settings_for_file_upload']['error'].should_not be_nil
    @user.settings['settings_for_file_upload']['id'].should_not be_nil
    @user.settings['settings_for_file_upload']['lookups'].should == 3
    
    json = JSON.parse(last_response.body)
    url = json['status_url'].sub(/http:\/\/example.org/, '')

    get(url + "?access_token=" + @user.settings['fake_token'])
    json = JSON.parse(last_response.body)
    json['upload_status'].should == 'pending'
    @user.reload.settings['settings_for_file_upload']['lookups'].should == 2

    get(url + "?access_token=" + @user.settings['fake_token'])
    json = JSON.parse(last_response.body)
    json['upload_status'].should == 'pending'
    @user.reload.settings['settings_for_file_upload']['lookups'].should == 1

    get(url + "?access_token=" + @user.settings['fake_token'])
    json = JSON.parse(last_response.body)
    json['upload_status'].should == 'success'
    id = json['attachment']['id']

    post "/validate/file_uploads/3", {'answer' => id.to_s}, 'rack.session' => last_session
    json = JSON.parse(last_response.body)
    json['answer'].should == id.to_s
    json['correct'].should == true      
  end
  
  it "should return error message when error is specified" do
    fake_launch({'farthest_for_file_uploads' => 10})
    get_with_session "/launch/file_uploads/3", {}

    Samplers.should_receive(:random).with(2).and_return(0)
    Samplers.should_receive(:random).with(3).and_return(0)
    Samplers.should_receive(:random).with(5).and_return(2)
    post_with_session "/preflight/file_uploads/3/#{@user.id}/#{@user.settings['verification']}", {'url' => 'http://www.example.com/files/monkey.brains', 'name' => 'monkey.brains', 'size' => 12345, 'content_type' => 'application/chilled-dessert', 'access_token' => @user.settings['fake_token']}
    last_session = session
    @user.reload.settings['settings_for_file_upload']['error'].should_not be_nil
    @user.settings['settings_for_file_upload']['id'].should_not be_nil
    @user.settings['settings_for_file_upload']['lookups'].should == 1
    
    json = JSON.parse(last_response.body)
    url = json['status_url'].sub(/http:\/\/example.org/, '')

    get(url + "?access_token=" + @user.settings['fake_token'])
    json = JSON.parse(last_response.body)
    json['upload_status'].should == 'error'
    json['message'].should == "Why did it have to be snakes?"

    post "/validate/file_uploads/3", {'answer' => "Why did it have to be snakes?"}, 'rack.session' => last_session
    json = JSON.parse(last_response.body)
    json['answer'].should == "Why did it have to be snakes?"
    json['correct'].should == true      
  end
  
  it "should find user-generated file when created through the api" do
    fake_launch({'farthest_for_file_uploads' => 10})
    get_with_session "/launch/file_uploads/4", {}
    res = ArrayWithPagination.new([])
    res.next_url = "http://www.example.com/api/v1/folders/123/files?page=2"
    res2 = ArrayWithPagination.new([{'id' => 98765, 'size' => 500, 'name' => 'call_him_dr_jones.doll', 'content_type' => 'application/short-round'}])
    Api.any_instance.should_receive(:get).with('/api/v1/users/self/folders/root').and_return({'id' => 123})
    Api.any_instance.should_receive(:get).with('/api/v1/folders/123/files').and_return(res)
    Api.any_instance.should_receive(:get).with('/api/v1/folders/123/files?page=2').and_return(res2)
    answer = "98765"
    post_with_session "/validate/file_uploads/4", {'answer' => answer}
    json = JSON.parse(last_response.body)
    json['answer'].should == answer
    json['correct'].should == true      
    
  end
  
  context "preflight" do
    it "should require valid user"
    it "should error on incorrect parameters"
    it "should stash user settings on url preflight"
    it "should stash upload parameters on file preflight"
  end
  
  context "file_upload" do
    it "should require valid user token"
    it "should error on incorrect keys"
    it "should error on invalid file"
    it "should redirect on success"
  end
  
  context "file_finalize" do
    it "should require valid user token"
    it "should set user settings on success"
  end
  
  context "file_status" do
    it "should require valid user token"
    it "should error when missing stashed user information"
    it "should return pending when iterations left"
    it "should error when iterations met and set to error"
    it "should succeed when iterations met and not set to error"
  end
end

#   
#   files.api_test :upload_personal_file, :lookup => lambda{|api|
#     next_path = '/api/v1/files/'
#     while next_path
#       files = api.get(next_path)
#       file = files.detect{|f| f['size'] > 100 && f['name'] == 'call_him_dr_jones.doll' && f['content_type'] == 'application/short-round' }
#       return file['id'] if file
#       raise "Couldn't find the file" unless files.next_url
#       next_path = "/" + files.next_url.split(/\//, 4)[-1]
#     end
#   }, :explanation => <<-EOF
#     <p>Semi-practical application time! This time you're back to
#     talking to Canvas directly. I want you to upload
#     a file to the root folder in your personal files area in Canvas. 
#     The file should be at least 100 bytes in size, 
#     be named <code>call_him_dr_jones.doll</code> and have a 
#     content type of <code>application/short-round</code>. Once you've
#     uploaded the file tell me its <code>id</code> attribute.</p>
#     <p>Note that if your personal file area is full you'll need
#     to clear out some existing files.</p>
#   EOF
