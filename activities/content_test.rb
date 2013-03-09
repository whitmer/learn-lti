content_test = Activity.add(:content_test)
  content_test.intro = <<-EOF
    Make sure you know how to use <a href="#">the content 
    extensions in Canvas</a> to return resources
  EOF
  
  # add tests for checking allowed return types 
  content_test.add_test :return_types, :pick_roles => true, :iterations => 5, :explanation => <<-EOF
  content_test.pick_types <<-EOF
    <p>Standard LTI is nice for getting users from the learning
    platform into the app, but doesn't do so well at getting content
    back from the app into the learning platform. We've built a
    content extension to LTI to make this easier. This extension
    makes it possible to build apps that let you browse third-party
    content and send it back to the learning platform for things
    like content creation or homework submission.</p>
    <p>There are two possible ways that the learning platform will
    tell you what return types are valid. The first way is the 
    <code>selection_directive</code> parameter.
    Different options for this parameter mean a different set of
    return types are allowed (we'll go into how to return each
    type after this lesson). Possible types are:</p>
    <dl>
      <dt><code>embed_content</code></dt>
      <dd><code>image,iframe,link,basic_lti,oembed</code></dd>
      <dt><code>select_link</code></dt>
      <dd><code>basic_lti</code></dd>
      <dt><code>submit_homework</code></dt>
      <dd><code>link,file</code></dd>
    </dl>
    <p>Alternatively, the learning platform may instead use the 
    <code>ext_content_return_types</code> parameter to send a comma-separated
    list of valid return types. Possible types are:</p>
    <ul>
      <li><code>image</code></li>
      <li><code>iframe</code></li>
      <li><code>link</code></li>
      <li><code>file</code></li>
      <li><code>basic_lti</code></li>
      <li><code>oembed</code></li>
    </ul>
    <p>
      Now I'm going to send over different combinations of return types
      or a selection directive (I'll only ever send over one parameter or
      the other, not both), and you get to tell me which return types
      are allowed. Fun, right? After this we'll go over each return type
      one at a time.
    </p>
  EOF
  
  args = {
    :embed_type => 'link',
    :url => 'http://www.bacon.com',
    :title => 'bacon'
  }
  content_test.add_redirect_test :link, :lti_return => args, :explanation => <<-EOF
    <p>Awright, now let's get to the good stuff. We've built an
    extension to LTI called the content extension that makes it
    possible for LTI apps to send content back to the learning
    platform for use in content, navigation, etc. The basic gist
    is that the learning platform will send additional parameters
    if the launch accepts content returns, and the LTI app can
    the return content by adding more query parameters to the
    return URL (<code>launch_presentation_return_url</code>).</p>
    <p>In your app you'll want to check for the following parameters:</p>
    <p>When you return, you'll send different query parameters back
    depending on the content you're returning. We'll start by just
    sending a link back since that's the easiest. You tell the learning
    platform you're sending a link by sending the parameter
    <code>embed_type</code> with the value <code>link</code>, as well as
    two additional required parameters. For the parameter
    <code>url</code> send back the value <code>http://www.bacon.com</code>, 
    and for the parameter <code>text</code> send back the value
    <code>bacon</code>.</p>
    <p>Give it a go :-).</p>
  EOF
  args = {
    :embed_type => 'image',
    :url => 'http://www.bacon.com/bacon.png',
    :alt => 'bacon',
    :width => '200',
    :height => '100'
  }
  content_test.add_redirect_test :image, :lti_return => args, :explanation => <<-EOF
    <p>Nice. Next let's try an image. The <code>embed_type</code>
    should be <code>image</code> this time. Here's a table of all
    the values you'll need to return. All of these values are required, 
    thought <code>alt</code> can have an empty string value ("") if
    the image is purely for decoration (alt tags are important for
    accessibility, if you didn't know).</p>
    <dl>
      #{args.each_pair{|k, v| "<dt><code>#{k}</code></dt><dd><code>#{v}</code></dd>\n"}}
    </dl>
  EOF
  args = {
    :embed_type => 'iframe',
    :url => 'http://www.bacon.com',
    :width => '200',
    :height => '100'
  }
  content_test.add_redirect_test :iframe, :lti_return => args, :explanation => <<-EOF
    <p>Next, an iframe. The iframe will be embedded in any rich
    content, or potentially shown on its own page, so the width
    and height parameters are recommendations more than
    requirements. Here's all the parameters you should send across:</p>
    <dl>
      #{args.each_pair{|k, v| "<dt><code>#{k}</code></dt><dd><code>#{v}</code></dd>\n"}}
    </dl>
  EOF
  args = {
    :embed_type => 'file',
    :url => 'http://www.bacon.com/bacon.docx',
    :content_type => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  }
  content_test.add_redirect_test :file, :lti_return => args, :explanation => <<-EOF
    <p>Files can be sent as well. The file URL should be accessible
    without any sessions or cookies, since in some cases it will be
    retrieved by a server-side background job. Note that 
    <code>content_type</code> is a required parameter.
    Parameters below:</p>
    <dl>
      #{args.each_pair{|k, v| "<dt><code>#{k}</code></dt><dd><code>#{v}</code></dd>\n"}}
    </dl>
    <p>You should also know there's a possible additional parameter
    you'll receive, <code>ext_content_file_extensions</code>, which 
    gives you a comma-separated list of file
    types which are acceptable as return values. If you return an invalid
    file type your return will be ignored, the user will be sad, and
    a fairy will lose its wings.</p>
  EOF
  args = {
    :embed_type => 'basic_lti',
    :url => 'http://www.bacon.com/bacon_launch'
  }
  content_test.add_redirect_test :basic_lti, :lti_return => args, :explanation => <<-EOF
    <p>Next is a cool one. In addition to regular content, you
    can also return LTI launch URLs as return values. This makes it
    possible for you to show an interface where a user is setting up
    the launch that they want to have happen.</p>
    <p>In standard LTI one of two things typically happens, either (1)
    the teacher has to launch the tool right away after placing it and 
    use that launch to pick content, or (2) the teacher has to browse
    content on some other site, find the launch URL and then paste it
    by hand into an LTI config. LTI return types adds a third option,
    where the admin installs a tool with a generic "picker" launch, and
    when teachers go to add the tool to their course they're presented
    with the picker, which then takes care of inserting the specific URL
    for them. Much better user experience. If you're really interested
    here's a blog post with more details.</p>
    <p>Anyway, LTI return values only have a couple parameters, listed
    below. Side note: it's assumed that any launch URL you return will be launched
    with the same consumer key and secret that were used in the initial
    launch.</p>
    <dl>
      #{args.each_pair{|k, v| "<dt><code>#{k}</code></dt><dd><code>#{v}</code></dd>\n"}}
    </dl>
  EOF
  # give them a helper in case they don't have oembed set up (since this
  # isn't a class on learning how to build oembed, that's optional)
  args = {
    :embed_type => 'oembed',
    :url => 'http://www.flickr.com/photos/bees/2341623661/',
    :endpoint => 'http://www.flickr.com/services/oembed/'
  }
  content_test.add_redirect_test :oembed, :lti_return => args, :explanation => <<-EOF
    <p>The last return type is OEmbed. This one is meant as a catchall, so
    if you're trying to embed some rich content that doesn't fit any of 
    the previous molds, OEmbed is your new friend. I'm not going to teach
    you how to implement OEmbed because hopefully most people won't need
    to, the other return types should work for most cases. But if you want
    to get crazy, this is how.</p>
    <p>Return parameters listed below:</p>
    <dl>
      #{args.each_pair{|k, v| "<dt><code>#{k}</code></dt><dd><code>#{v}</code></dd>\n"}}
    </dl>
  EOF
