var confirmResult;
$(document).ready(function() {
  $("#launch").submit(function() {
    $("#answer").show();
    $("#answer .hideable").show();
    $("#results").hide();
    $("#answer input").each(function() {
      if($(this).attr('type') == 'checkbox') {
        $(this).attr('checked', false);
      } else {
        $(this).val("");
      }
    });
  });
  confirmResult = function(data) {
    $("#results").show().attr('class', '');
    $("#answer .btn,#answer .waiting").hide();
    if(data.error) {
      $("#results").text("Error: " + data.error).addClass('alert alert-error');
    } else if(data.correct) {
      if(data.times_left > 0) {
        $("#results").html("Right! Launch " + data.times_left + " more time(s) to finish this test.").addClass('alert alert-info');
      } else if(data.next) {
        $("#results").html("Right! <a class='btn btn-primary' href='" + data.next + "'>On to the next lesson!</a>").addClass('alert alert-success');
      } else {
        $("#results").text("Right! You're done with this section!").addClass('alert alert-success');
      }
    } else {
      $("#answer .hideable").hide();
      if(data.explanation) {
        $("#answer .btn").show();
        $("#results").html("Sorry, that's wrong. " + data.explanation).addClass('alert alert-error');
      } else if(data.valid === true) {
        $("#results").html("Sorry, that's wrong. The value <code>" + data.answer + "</code> was actually valid. Re-launch to try again.").addClass('alert alert-error');
      } else if(data.valid === false) {
        $("#results").html("Sorry, that's wrong. The value <code>" + data.answer + "</code> was actually correct. Re-launch to try again.").addClass('alert alert-error');
      } else {
        $("#results").html("Sorry, that's wrong. The correct value was <code>" + data.answer + "</code>. Re-launch to try again.").addClass('alert alert-error');
      }
    }
  };
  console.log(window.parent);
  if($("#result_data").length) {
    window.parent.confirmResult(JSON.parse($("#result_data").val()));
  }
  $("#answer").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();
    $("#results").text("checking...").show().attr('class', '');
    var data = $("#answer").serializeArray();
    $.ajax({
      url: $("#answer").attr('action'),
      type: 'POST',
      dataType: 'json',
      data: data,
      success: function(data) {
        confirmResult(data);
      },
      error: function() {
        $("#results").text("check failed").addClass('alert alert-error');
      }
    });
  });
});