post_launch = Activity.add(:post_launch)
  post_launch.intro = <<-EOF
    At their simplest level LTI launches are
    just POST requests. There are some standard parameters
    that you should expect to come across on all launches,
    and also some option parameters you'll potentially want 
    to look for. Let's make sure you can retrieve these correctly.
  EOF
  post_launch.done = <<-EOF
  EOF
  
  post_launch.add_test :lti_message_type, :param => :lti_message_type, :explanation => <<-EOF
    <p>Every LTI launch should send across the 
    <code>lti_message_type</code> parameter. As of
    right now the value for this parameter should always
    be <code>basic-lti-launch-request</code>. In other words,
    this is a freebie.</p>
    <p>Let's use this chance to make sure you're set up
    correctly. Enter the URL of the location where you'd like
    to receive the POST request for LTI launches (localhost
    is fine, <i>make sure it can render in an iframe, i.e. check X-Frame-Options</i>) and click "Launch" to test.</p>
    <p>P.S. Don't be sad if your interface doesn't fit in the little iframe
    we've set up for you, it just means you don't have a responsive 
    design. You don't *have* to build a UI that fits in those dimensions
    since most users will have a larger window on their computer,
    but you *should* feel a little bad if you don't know how to 
    <a href='http://en.wikipedia.org/wiki/Responsive_web_design'>support
    both sizes with a single interface</a>.
    </p>
  EOF
  
  post_launch.add_test :lti_version, :param => :lti_version, :explanation => <<-EOF
    <p>This is another freebie. <code>lti_version</code> should
    be sent on all LTI launches. Right now this value will
    always be <code>LTI-1p0</code>, but this may change in the
    near future.</p>
    <p>Launch again and then enter the value sent to you
    for this parameter.</p>
  EOF

  post_launch.add_test :resource_link_id, :param => :resource_link_id, :explanation => <<-EOF
    <p>Moving along! The next parameter we're going to look at it
    <code>resource_link_id</code>. This is the unique identifier 
    representing the "placement" of your app in the LMS. If a teacher
    adds your app multiple times in the same course, each spot will have
    its own link id. Every time your app is launched from that spot,
    regardless of who launched it, you will receive the same link id.</p>
    <p><b>This should not be considered a human-readable value</b>, it 
    will often be a hash value.</p>
    <p>Something about typical use cases.</p>
    <p>Now launch again and enter the value sent for this parameter.</p>
  EOF
  post_launch.add_test :context_id, :param => :context_id, :explanation => <<-EOF
    <p><code>context_id</code> is a unique identifier for the course, group 
    or other setting from which your app was launched. It will be consistent
    regardless of who launches your app or from which placement within the
    course they launch from.</p>
    <p><b>This should not be considered a human-readable value</b>, it 
    will often be a hash value.</p>
    <p>You should be picking up the pattern, now. Show me what you've got.</p>
  EOF
  post_launch.add_test :user_id, :param => :user_id, :explanation => <<-EOF
    <p><code>user_id</code> is a unique identifier representing the user
    who just launched your app. This id will be the same for the same user
    across courses or groups, but not across platforms or systems.</p>
    <p><b>This should not be considered a human-readable value</b>, it 
    will often be a hash value. If you're looking for the user's id within
    Canvas for API calls, look for <code>custom_canvas_user_id</code>.</p>
  EOF
  post_launch.add_test :roles, :param => :roles, :pick_roles => true, :iterations => 3, :explanation => <<-EOF
    <p><code>roles</code> is another important parameter for you to check. It'll
    tell you how a person is tied to the course or group, which should help you
    determine permissions and access for the user. For example, you may want to
    let teachers have edit privileges but not students..</p>
    <p>There are a number of different role types available, and users can
    have more than one role type attached, they'll come across as a comma-separated
    list in this single parameter. There are also some shortcut values meant
    to make it easier on everyone, but you should probably check for both
    the shortcuts and longer versions in case someone doesn't support them.
    </p>
    <p>Also, there are <a href='http://www.imsglobal.org/lti/blti/bltiv1p0/ltiBLTIimgv1p0.html#_Toc261271984'>
    a lot of role types available</a> but since their mapping isn't well-defined,
    the best I can do is point you to the obvious ones, and tell you how
    Canvas handles these roles.
    Possibilities listed below:</p>
    
    <table class='table table-striped'>
      <thead>
        <tr>
          <th>Person</th>
          <th>Description</th>
          <th>Role Alias(es)</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>Nobody</td>
          <td style='font-size: 10px;'>This user has no association with the course/group. Think of
          this as an unauthenticated user who launched your app from
          a publicly-visible page.
          </td>
          <td><code>None</code> or <code>urn:lti:sysrole:ims/lis/None</code></td>
        </tr>
        <tr>
          <td>Teacher/Instructor</td>
          <td style='font-size: 10px;'>This is a teacher in the course.
          </td>
          <td><code>Instructor</code> or <code>urn:lti:instrole:ims/lis/Instructor</code></td>
        </tr>
        <tr>
          <td>Student/Learner</td>
          <td style='font-size: 10px;'>This is a student in the course.
          </td>
          <td><code>Learner</code>, <code>urn:lti:instrole:ims/lis/Learner</code>, <code>Student</code> or <code>urn:lti:instrole:ims/lis/Student</code></td>
        </tr>
        <tr>
          <td>Designer</td>
          <td style='font-size: 10px;'>This is an instructional designer or content designer for the course.
          </td>
          <td><code>ContentDeveloper</code> or <code>urn:lti:role:ims/lis/ContentDeveloper</code></td>
        </tr>
        <tr>
          <td>Admin</td>
          <td style='font-size: 10px;'>This is an account manager with permission over the course. I typically
          map this role to the same permissions as an instructor.
          </td>
          <td><code>Administrator</code> or <code>urn:lti:instrole:ims/lis/Administrator</code></td>
        </tr>
        <tr>
          <td>Teaching Assistant</td>
          <td style='font-size: 10px;'>This is a TA for the course. <b>Note: Canvas sends TAs across with the <code>Instructor</code>
          role, not the <code>TeachingAssistant</code> role</b> since it
          wasn't clear how well the TA role was supported by third parties.
          </td>
          <td><code>TeachingAssistant</code> or <code>urn:lti:role:ims/lis/TeachingAssistant</code>.
          I've also seen this as <code>Mentor</code> or <code>urn:lti:instrole:ims/lis/Mentor</code>.</td>
        </tr>
        <tr>
          <td>Observer/Auditor</td>
          <td style='font-size: 10px;'>This is someone associated with the course who is not a teacher
          or student. In Canvas this could be an auditor, a parent, a counselor,
          or any other person with the observer role in Canvas.
          </td>
          <td><code>Observer</code> or <code>urn:lti:instrole:ims/lis/Observer</code></td>
        </tr>
      </tbody>
    </table>
    <p>This time rather than pasting in the value you get, you'll need to 
    parse it out and select the matching roles for the currently-launched
    user. I'm going to make you do it three times to make sure you've 
    got it down. Enjoy :-).</p>
  EOF
  post_launch.add_test :oauth_consumer_key, :param => :oauth_consumer_key, :explanation => <<-EOF
    <p>This should be another easy one, but it's important. <code>oauth_consumer_key</code>
    is an attribute that you are responsible to give to the learning platform 
    along with a shared secret to make sure launches are coming from the correct
    source. Typically you'll give the key and secret to the end-user and they'll
    paste it into a config on the learning platform side. You'll need to store
    these within your system and find the shared secret for an account
    by looking up the account's consumer key. This value should be unique.</p>
    <p><b>It's important that you give each account its own consumer key</b>. Don't
    give in to the temptation to just create a single key and secret and share
    it with everyone. That will cause you big problems should those credentials
    ever get compromised.</p>
    <p>We'll talk about the shared secret parameter shortly.</p>
  EOF
  post_launch.add_test :oauth_nonce, :param => :oauth_nonce, :explanation => <<-EOF
    <p><code>oauth_nonce</code> is a random string generated by the learning 
    platform. It's used to add randomness to the launch signature (I'll talk
    about that in a minute) to improve security.</p>
    <p>LTI docs say that your app should keep a history of used nonces and
    not allow reuse of the same nonce for multiple launches within a reasonable
    window of time (say, 90 minutes).</p>
  EOF
  post_launch.add_test :oauth_timestamp, :param => :oauth_timestamp, :explanation => <<-EOF
    <p><code>oauth_timestamp</code> is a unix timestamp (seconds since Jan 1, 1970 GMT)
    used along with the nonce to prevent replay attacks. The time window isn't
    explicitly defined, but you should make sure that timestamps aren't too
    old for app launches.</p>
  EOF
  # for signature, they just need to return the value at this point
  # I'll talk about verifying later on
  post_launch.add_test :oauth_signature, :param => :oauth_signature, :explanation => <<-EOF
    <p><code>oauth_signature</code> is a value that's generated based on all the other
    parameters sent across with the launch. I'm not going to check your ability
    to verify signatures at this point, I just want to make sure you know
    how to check for them. We'll get to signature verification later on.</p>
    
    http://tools.ietf.org/html/rfc5849#section-3.4
  EOF
  post_launch.add_test :lis_person_name_full, :param => :lis_person_name_full, :explanation => <<-EOF
    <p>Isn't this fun? Next we'll look at some parameters that can optionally
    come across to identify the user. LTI configurations can have different
    levels of privacy, so you will receive between zero and all of these 
    parameters depending on the app configuration. The user information
    parameters you'll care about are <code>lis_person_name_full</code>,
    <code>lis_person_contact_email_primary</code>, <code>lis_person_name_given</code>,
    and <code>lis_person_name_family</code>.</p>
    <p>You can encourage people
    to configure your app with a certain level of privacy (typical privacy
    levels include "public", "name only", "email only" and "anonymous"), 
    but there's
    technically no guarantee that they'll listen (you could always fail to
    launch unless all the parameters you need are there, but if you do be
    sure to do so in a nice way, since often the people who see that error
    won't be able to do anything about it other than notify their admin of
    a problem).
    <p>It'd be overkill to check all of these, so let's just make sure
    you can read <code>list_person_name_full</code> and call it good.</p>
  EOF
  post_launch.add_test :custom_params, :param => :custom_bacon, :explanation => <<-EOF
    <p>LTI launches can also optionally provide custom parameters. These could
    be sent across by the learning platform to give you service-specific
    information, or <b>you can also specify custom parameters at config-time
    that will get sent across with every launch</b>. Apps use these parameters
    to send over information that is app-specific but URL-agnostic
    (I don't have good examples because I personally don't like this ability,
    but I'll try to find some soon).</p>
    <p>Custom parameters are always prepended with <code>custom_</code> if 
    it's not already present (there are additional rules around allowed
    characters in custom_ parameter names, if you're curious you can 
    <a href="http://www.imsglobal.org/lti/blti/bltiv1p0/ltiBLTIimgv1p0.html#_Toc261271975">check
    the official spec</a>).</p>
  EOF
  
  # TODO: test presence of this parameter in addition to its value
  post_launch.add_test :lis_outcome_service_url, :param => :lis_outcome_service_url, :assignment => true, :explanation => <<-EOF
    <p>LTI has an optional extension calls "outcomes", which essentially lets
    you write back grades from your app to the learning platform's gradebook
    in a standardized way. I'm not going to test your ability to pass back
    grades in this lesson, but I do want to make sure you know how to check
    for this value.</p>
    <p>If <code>lis_outcome_service_url</code> comes across then you can 
    assume you can write back to the gradebook for the current launch. If it 
    doesn't come across then you can't.</p>
  EOF

