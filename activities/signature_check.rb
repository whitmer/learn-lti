signature_check = Activity.add(:signature_check)
  signature_check.intro = <<-EOF
    Make sure you know how to verify signatures and other security parameters
  EOF
  
  # use session to make sure both states are tried at least once
  signature_check.add_test :nonce_check, :param => :oauth_nonce, :pick_valid => true, :allow_blank => true, :allow_repeats => true, :iterations => 5, :explanation => <<-EOF
    <p>Before we get to verifying signatures, let's make sure you're checking
    the other parameters related to good security. First, every LTI launch 
    should come across with the <code>oauth_nonce</code> parameter (
    <a href='http://en.wikipedia.org/wiki/Cryptographic_nonce'>what is a nonce?</a>). 
    If it's not
    set then your site should return a friendly error message to the user
    (remember, it's not the user's fault, it's the learning platform's fault,
    so don't get mad at the user, tell them something nice like that they 
    should contact their sysadmin).</p>
    <p>If it *is* there then you should check to make sure it's a fresh
    nonce. There's no official guideline on this, but the idea is to 
    make sure you're not getting the same nonce repeatedly from a 
    specific learning platform, since that would weaken the security of the
    launch. Honestly you should be finding a library to do this work for you.
    If you're coding up OAuth signature verification from scratch then you're
    probably doing it wrong.</p>
    <p>For this test you'll need to launch 5 times. If you get no nonce
    or a bad nonce you should fail friendlily, otherwise you should 
    succeed. Tell us which you're doing each time.</p>
  EOF
  # use session to make sure both states are tried at least once
  signature_check.add_test :timestamp_check, :param => :oauth_timestamp, :pick_valid => true, :allow_blank => true, :allow_old => true, :iterations => 5, :explanation => <<-EOF
    <p>Nice. Now let's check validity of the <code>oauth_timestamp</code>
    parameter. This should be a Unix timestamp (seconds since Jan 1, 1970 GMT),
    and should have happened in a reasonable time window before the
    current time.</p>
    <p>Found a library yet? You probably should.</p>
    <p>For this test you'll need to launch 5 times. Sometimes we'll
    send a valid timestamp, other times an old or blank timestamp.
    You should fail gracefully for the end-user.</p>
  EOF
  signature_check.add_test :signature_check, :param => :oauth_signature, :pick_valid => true, :allow_invalid => true, :iterations => 5, :explanation => <<-EOF
    <p>If you're using a library this should all be pretty
    straightforward. If not, then you just got to the really
    fun part.</p>
    <p><code>oauth_signature</code> is an
    <a href='http://oauth.googlecode.com/svn/code/javascript/example/signature.html'>
    oauth 1.0 request signature</a> generated based on the POST parameters
    sent, including the nonce and timestamp just discussed. That link will
    guide you to a signature generator and the OAuth documentation for
    how to generate these signatures.</p>
    <p>To test this you'll need to launch 5 times. Some launches will
    have a valid signature, others won't.</p>
  EOF
  signature_check.add_test :signature_check2, :param => :oauth_signature, :pick_valid => true, :allow_invalid => true, :all_params => true, :iterations => 3, :explanation => <<-EOF
    <p>Great! Now let's send over some additional parameters to 
    make sure you're not hard-coding your signature generation. Any number
    of parameters can come across, including custom parameters, so you'll
    need to make sure you can handle them appropriately.</p>
    <p>Three more launches should do the trick.</p>
  EOF

