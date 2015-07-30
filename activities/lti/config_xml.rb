config_xml = Activity.add(:config_xml, :lti)
  config_xml.intro = <<-EOF
    Make sure you know how to <a href="https://lti-examples.heroku.com/build_xml.html">build config XML</a>
  EOF
  config_xml.add_xml_test :basics, {}, :explanation => <<-EOF
    <p>When you're having users configure LTI apps in Canvas, the easiest way
    is using XML configurations. You can either provide people with
    raw XML to paste in, or give them a URL that links to your
    configuration XML (very much preferred, hopefully for obvious
    reasons).</p>
    <p>Wherever possible I recommend building a standard
    XML file and hosting it on your own server. If you need custom
    options that's not the end of the world, but it does make it a little
    harder to get it listed in our 
    <a href="https://www.eduappcenter.com/">app directory</a>.</p>
    <p>I could teach you about the IMS LTI XML format, but examples
    are probably much easier, since neither one of us is all that
    concerned about the namespaces. Even easier than that would be
    <a href="https://www.eduappcenter.com/tools/xml_builder#/new">a tool to build
    the XML for you</a>, right? Done and done.</p>
    <p>Let's make sure you can build a barebones XML config. I don't
    care if you use our builder or write it yourself, but 
    paste it in the box to the right for validation.</p>
  EOF
  config_xml.add_xml_test :launch_url, {'blti|launch_url' => 'http://www.example.com'}, :explanation => <<-EOF
    <p>Saweet. Now let's see if you can set the launch URL to
    <code>http://www.example.com</code>. Again, don't feel bad
    about using 
    <a href="https://lti-examples.heroku.com/build_xml.html">our XML
    builder</a> </p>
  EOF
  config_xml.add_xml_test :icon, {'blti|icon' => 'http://www.example.com/icon.png'}, :explanation => <<-EOF
    <p>Next, the icon. This isn't a required parameter, but it'll
    make your life easier when building some extensions, and it will
    probably be added as a standard thing in Canvas in the future. Set
    the icon URL to
    <code>http://www.example.com/icon.png</code>. Again, don't feel bad
    about using 
    <a href="https://lti-examples.heroku.com/build_xml.html">our XML
    builder</a> </p>
  EOF
  config_xml.add_xml_test :custom_fields, {"blti|custom lticm|property[name='custom_password']" => "sherbert lemon", "blti|custom lticm|property[name='custom_house_elf']" => "dobby"}, :explanation => <<-EOF
    <p>Custom fields is up next. You remember I tested you before
    on receiving <code>custom_</code> parameters in the LTI launch?
    Those can come from the learning platform, or also from the configuration
    that you define. If there are additional settings you need to
    send across that you don't want on the launch URL as query
    parameters (for example if you have a domain-level config with
    lots of different launch URLs attached) then custom fields is
    the thing for you. You can define as many as you need.</p>
    <p>For this test, let's have you send over 
    <code>custom_password</code> as <code>sherbert lemon</code> and
    <code>custom_house_elf</code> as <code>dobby</code>.
    Again, don't feel bad
    about using 
    <a href="https://lti-examples.heroku.com/build_xml.html">our XML
    builder</a> </p>
  EOF
  config_xml.add_xml_test :tool_id, {"blti|extensions[platform='canvas.instructure.com'] lticm|property[name='tool_id']" => "i_am_the_last_one"}, :explanation => <<-EOF
    <p>You're on a roll. Next is <code>tool_id</code>. This is
    a value that's used by Canvas to track multiple installations
    of the same app. It is a Canvas-specific configuration option,
    so it goes in as an extension. I'm not going to provide examples
    here, you really should check out 
    <a href="https://lti-examples.heroku.com/build_xml.html">our XML
    builder</a> if you haven't already.</p>
    <p>
    It's important to select a tool_id that is
    unique since there's no enforcing body for preventing
    collisions. Just be a good citizen, for goodness' sake.</p>
    <p>Send over a tool ID of <code>i_am_the_last_one</code>
    Again, don't feel bad
    about using 
    <a href="https://lti-examples.heroku.com/build_xml.html">our XML
    builder</a> </p>
  EOF
  config_xml.add_xml_test :privacy_level, {"blti|extensions[platform='canvas.instructure.com'] lticm|property[name='privacy_level']" => "anonymous"}, :explanation => <<-EOF
    <p><code>privacy_level</code> is another Canvas-specific 
    setting, but it's very similar to a setting used in other
    learning platforms. This option defines how much information
    will be sent over to your app at launch time. Here's the
    definitions:</p>
    <dl>
      <dt>Anonymous</dt><dd>No name information, you won't get anything other than an opagque identifier.</dd>
      <dt>Name Only</dt><dd>Send the user name, but not email</dd>
      <dt>Publi</dt><dd>Sends name, email, Canvas IDs, etc.</dd>
    </dl>
    <p>If you don't need certain information then don't ask for
    it. For this test, send over a privacy_level of
    <code>anonymous</code>.
    Feel free to use
    <a href="https://lti-examples.heroku.com/build_xml.html">our XML
    builder</a>.</p>
    <p>
  EOF
  args = {
    "blti|extensions[platform='canvas.instructure.com'] lticm|options[name='course_navigation'] lticm|property[name='url']" => "http://www.example.com/unforgivables/1",
    "blti|extensions[platform='canvas.instructure.com'] lticm|options[name='course_navigation'] lticm|property[name='text']" => "Avada Kedavra"
  }
  config_xml.add_xml_test :course_navigation, args, :explanation => <<-EOF
    <p>The next Canvas-specific option I want to talk about lets
    you add your app to the navigation of a single course or all
    courses within an account. The extension is called 
    <code>course_navigation</code>. It should be easy to set
    up over on the <a href="https://lti-examples.heroku.com/build_xml.html">XML
    builder</a>.</p>
    <p>For this test set the course navigation launch URL to
    <code>http://www.example.com/unforgivables/1</code> with link text
    of <code>Avada Kedavra</code>.
    Feel free to use
    <a href="https://lti-examples.heroku.com/build_xml.html">our XML
    builder</a>.</p>
    <p>Note: You can do similar configurations for account and user
    navigation. Course navigation, however, is the only one that 
    has the additional options <code>visibility</code> for specifying
    what roles have access to the link, and <code>default</code> for
    specifying if the link should be on or off by default.</p>
  EOF
  args = {
    "blti|extensions[platform='canvas.instructure.com'] lticm|options[name='editor_button'] lticm|property[name='url']" => "http://www.example.com/undesirables/2",
    "blti|extensions[platform='canvas.instructure.com'] lticm|options[name='editor_button'] lticm|property[name='text']" => "Hermione Granger",
    "blti|extensions[platform='canvas.instructure.com'] lticm|options[name='editor_button'] lticm|property[name='selection_width']" => "500",
    "blti|extensions[platform='canvas.instructure.com'] lticm|options[name='editor_button'] lticm|property[name='selection_height']" => "350"
  }
  config_xml.add_xml_test :editor_button, args, :explanation => <<-EOF
    <p>One last option, this time <code>editor_button</code>. This
    along with a couple other extensions let you add your tool
    to things like the WYSIWYG editor, the module link selector,
    or the homework submission
    interface in Canvas. There's a content extension that goes with 
    this that we'll cover next.
    <p>For this test set the editor button launch URL to
    <code>http://www.example.com/undesirables/2</code> with link text
    of <code>Hermione Granger</code>. You'll also need to set the width
    (<code>500</code>) and height (<code>350</code>) of the dialog
    that will be opened to launch your app.
    Feel free to use
    <a href="https://lti-examples.heroku.com/build_xml.html">our XML
    builder</a>.</p>
  EOF
