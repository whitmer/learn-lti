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
    $("#answer .btn.hideable,#answer .waiting").hide();
    if(data.error) {
      $("#results").text("Error: " + data.error).addClass('alert alert-error');
    } else if(data.correct) {
      if(data.times_left > 0) {
        $("#results").html("Right! Launch " + data.times_left + " more time(s) to finish this test.").addClass('alert alert-info');
      } else if(data.next) {
        $("#results").html("Right! <a class='btn btn-primary' href='" + data.next + "'>On to the next lesson!</a>").addClass('alert alert-success');
      } else {
        $("#results").text("Right! You're done with this activity!").addClass('alert alert-success');
      }
    } else {
      $("#answer .hideable").hide();
      if(data.explanation) {
        $("#answer .btn").show();
        $("#results").html("Sorry, that's wrong. " + data.explanation).addClass('alert alert-error');
      } else if(data.valid === true) {
        if(data.answer) {
          $("#results").html("Sorry, that's wrong. The value <code>" + data.answer + "</code> was actually valid. Re-launch to try again.").addClass('alert alert-error');
        } else {
          $("#results").html("Sorry, that's wrong. The response was actually valid. Re-launch to try again.").addClass('alert alert-error');
        }
      } else if(data.valid === false) {
        if(data.answer) {
          $("#results").html("Sorry, that's wrong. The value <code>" + data.answer + "</code> was not valid. Re-launch to try again.").addClass('alert alert-error');
        } else {
          $("#results").html("Sorry, that's wrong. The response was not valid. Re-launch to try again.").addClass('alert alert-error');
        }
      } else if(data.answer === "not telling") {
        $("#results").html("Sorry, that's wrong. I can't tell you the correct answer because it doesn't change often enough. Please try again.").addClass('alert alert-error');
      } else {
        $("#results").html("Sorry, that's wrong. The correct value was <code>" + data.answer + "</code>. Re-launch to try again.").addClass('alert alert-error');
      }
    }
  };
  if($("#result_data").length && window.parent && window.parent.confirmResult) {
    window.parent.confirmResult(JSON.parse($("#result_data").val()));
  }
  if($("#answer").attr('rel')) {
    $.ajax({
      url: $("#answer").attr('rel'),
      type: 'POST',
      dataType: 'json',
      success: function(data) {
        if(data.ready == false) {
          $("#results").show().text("setup failed: " + data.error).addClass('alert alert-error');
          $(".setup_result").text("!error!");
          console.log(data);
        } else {
          $(".setup_result").text(data.result);
          $("#answer").show();
        }
      },
      error: function(data) {
        $("#results").show().text("setup failed: unknown error").addClass('alert alert-error');
        console.log(data);
      }
    });
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
  
  $(".activity").each(function() {
    var $obj = $(this);
    $.getJSON($(this).attr('rel'), function(data) {
      var tally = 0;
      for(var idx = data.max - 1; idx >= 0; idx--) {
        var count = data.counts[idx] || 0;
        tally = tally + count;
        var html = "<li><a>" + tally + "</a></li>";
        var $li = $(html);
        $li.attr('title', "Learners who have made it to lesson " + idx).css('cursor', 'default');
        if(tally > 0 && tally > data.total / 2) {
          $li.find("a").addClass('label label-info');
        }
        $obj.find("ul").prepend($li);
      }
    });
  });
});