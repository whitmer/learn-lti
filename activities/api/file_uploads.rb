files = Activity.add(:file_uploads, :api)
  files.intro = <<-EOF
    Teach you how to upload files to Canvas from a local location or a remote URL
  EOF
  
  files.file_test :preflight, :phase => :step_1, :explanation => <<-EOF
    <p>Uploading files to Canvas takes a couple steps. The
    main reason for that is to keep Canvas performant even 
    when uploading potentially large files (we offload the
    upload step to Amazon S3, or potentially some other
    file server).</p>
    <p>Step one when uploading files is the preflight step.
    In this step you'll tell Canvas some information about
    the file. You'll do a POST request to one of the 
    file-accepting endpoints with a bunch of parameters.
    You can find the parameters you'll need (and some 
    example endpoints) in 
    <a href="https://canvas.instructure.com/doc/api/file.file_uploads.html">Canvas
    API documentation</a>.</p>
    <p>For this and the next few tests you'll be talking to a fake
    Canvas server rather than a real one while you learn all three
    steps involved in uploading files to Canvas. Once you're good we'll
    do a final test against real Canvas.</p>
    <p>I want you to do just step one, POST a preflight call to
    the preflight URL with a <code>name</code>
    of <code>this_whole_place_is_slithering.txt</code> and whatever
    <code>size</code> and <code>content_type</code> attributes you think
    make sense. You'll get back a JSON response. Tell me the value of
    the <code>upload_url</code> parameter.</p>
  EOF
  
  files.file_test :uploading, :phase => :step_2, :explanation => <<-EOF
    <p>Step two is the hardest part of the file upload process. When 
    you successfully make a preflight call you'll get back a JSON object
    with a bunch of parameters. You must now make a POST request to
    whatever URL you get back in <code>upload_url</code> (note that
    this URL may be on a different domain than the one you've been
    talking to for API calls, such as Amazon S3. We have CORS enabled
    on the cloud instance of Canvas so you can execute client-side
    uploads if your system supports that, so you won't have to proxy
    the upload if you don't want to).</p>
    <p>The parameters of the POST request are important, and <b>order
    is important</b>. You must first send all the parameters sent
    in the <code>upload_params</code> attribute from the response you
    got in step one, and <i>then</i> send the <code>file</code> parameter
    with the contents of your file. If the <code>file</code> parameter is
    not the last parameter sent then Amazon S3 will reject your
    request. Don't send any other parameters (like access_token) or
    the request will also fail.</p>
    <p>I'm not going to explain how to
    generate a multipart form POST body since you really shouldn't be
    doing that yourself, just find a library that supports it. Like,
    seriously. 
    <a href="https://github.com/instructure/canvas-lms/blob/stable/public/javascripts/jquery.instructure_forms.js#L498">I wrote on once</a>, 
    it was gross and took a long time to get the bugs out.</p>
    <p>If your upload succeeds then you'll get a <code>301 Moved Permanently</code>
    response from the server. The <code>Location</code> header in this request
    is the final URL you'll need to hit in order to finish the upload
    process.</p>
    <p>For this test I want you to run through the same preflight as before
    and this time follow it up with step two. When you've succeeded 
    tell me the URL you get back in the <code>Location</code> header from
    step two.</p>
  EOF
  
  files.file_test :confirmation, :phase => :step_3, :explanation => <<-EOF
    <p>The final step in the upload process is to make a final call back to
    Canvas. The URL you got back from step 2 is an API endpoint where you'll
    need to make a final POST request. You don't need to send any additional
    parameters (other than your <code>access_token</code>, since this is a
    Canvas API call again) in the POST.</p>
    <p>Remember that the file won't be active until you make this final call,
    even if the upload in step 2 was successful.</p>
    <p>The response to this final call will give you the file's
    <code>id</code>, <code>url</code> and some additional attributes.</p>
    <p>Let's see you go through the whole flow, and tell me the <code>id</code>
    of the newly-created file.</p>
  EOF
  
  files.file_test :url_upload, :phase => :step_url, :iterations => 3, :explanation => <<-EOF
    <p>Last test in fake Canvas. In addition to doing file uploads by hand,
    you can also upload files from a publicly-available URL. Step one is the same
    as before, except you'll send an additional parameter,
    <code>url</code> that is the publicly-available location of the file
    you want to add to Canvas. Canvas will download the file at this location
    using a background job that won't have any user session information, so 
    be sure it include whatever tokens are necessary to let a cookie-less request
    download the file correctly.</p>
    <p>Step two is different for URL uploads. In the response from step one
    instead of getting a <code>upload_url</code>, you'll get a 
    <code>status_url</code> that you can use to check the status of the upload.
    Status checking is not required, the upload will either finish or fail without
    you checking the status, but you'll have no idea if the upload succeeded 
    unless you check status, so it's probably a good idea.</p>
    <p>To check status, you make a GET request to the <code>status_url</code>
    endpoint using a standard Canvas API call (include the <code>access_token</code>).
    The response will have a parameter, <code>upload_status</code> that will be
    either <code>pending</code>, <code>read</code>, or <code>error</code>. On error
    you will get an additional <code>message</code> attribute with the error
    message received. On success you will get an additional <code>attachment</code>
    object which includes file attributes for the successfully-added file.</p>
    <p>For this test you'll need to submit a file using the URL upload
    mechanism. The URL for the file should be 
    <code>http://www.example.com/files/monkey.brains</code> with a 
    <code>content_type</code> of <code>application/chilled-dessert</code>, a
    <code>size</code> of <code>12345</code> (which is 12345 bytes, btw) and a
    <code>name</code> of <code>monkey.brains</code>. You'll
    upload the file three times, and each time tell me either the id of 
    the successfully-added file, or the message returned on error.</p>
  EOF
  
  files.api_test :upload_personal_file, :lookup => lambda{|api|
    root = api.get('/api/v1/users/self/folders/root')
    next_path = "/api/v1/folders/#{root['id']}/files"
    while next_path
      files = api.get(next_path)
      file = files.detect{|f| f['size'] > 100 && f['name'] == 'call_him_dr_jones.doll' && f['content_type'] == 'application/short-round' }
      return file['id'].to_s if file
      raise ApiError.new("Couldn't find the file") unless files.next_url
      next_path = "/" + files.next_url.split(/\//, 4)[-1]
    end
  }, :explanation => <<-EOF
    <p>Semi-practical application time! This time you're back to
    talking to Canvas directly. I want you to upload
    a file to the root folder in your personal files area in Canvas. 
    The file should be at least 100 bytes in size, 
    be named <code>call_him_dr_jones.doll</code> and have a 
    content type of <code>application/short-round</code>. Once you've
    uploaded the file tell me its <code>id</code> attribute.</p>
    <p>Note that if your personal file area is full you'll need
    to clear out some existing files.</p>
    <p>Hint: to get the id of the root folder, call
    <code>/api/v1/users/self/folders/root</code>.</p>
  EOF
