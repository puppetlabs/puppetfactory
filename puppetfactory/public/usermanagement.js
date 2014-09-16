$(document).ready(function(){

  // toggle hide the newuser dialog
  $('#showuser').click(function(){
    $(this).hide();
    $('#newuserwrapper').addClass("open");
    $('#newuser').slideDown("fast");
    $('#user').focus();
  });
  $('#hideuser').click(function(){
    $('#showuser').show();
    $('#newuserwrapper').removeClass("open");
    $('#newuser').hide();
  });

   // save the new user
  $('#save').click(function(){
    var username  = $('#user').val();
    var password  = $('#password').val();
    var password2 = $('#password2').val();

    console.log(" username:"+username);
    console.log(" password:"+password);
    console.log("password2:"+password2);

    // reset warnings
    $('#user').removeClass("fail");
    $('#password').removeClass("fail");
    $('#password2').removeClass("fail");

    if(username == '') {
      $('#user').attr("value", "");
      $('#user').addClass("fail");
      $('#user').focus();
    }
    else if(password == '' || password != password2) {
      $('#password').attr("value", "");
      $('#password').addClass("fail");

      $('#password2').attr("value", "");
      $('#password2').addClass("fail");

      $('#password').focus();
    }
    else {
      $('#newuser input[type=button]').attr("disabled", "disabled");
      $('#newuser').addClass("processing");
      $('#newuser table').activity({width: 5.5, space: 6, length: 13});

/*
      $.get("/new/"+username, function(data) {
        console.log(data);
        var results = jQuery.parseJSON(data);
        if(results.status == 'success') {
          location.reload();
        }
        else {
          alert('Could not create user: ' + results.message);
          $('#newuser').removeClass("processing");
          $('#newuser table').activity(false);
        }
      });
*/
      $.post('/new', {username: username, password: password}, function(data) {
        console.log(data);
        var results = jQuery.parseJSON(data);
        if(results.status == 'success') {
          location.reload();
        }
        else {
          alert('Could not create user: ' + results.message);
          $('#newuser').removeClass("processing");
          $('#newuser table').activity(false);
        }
      });

    }

  });
});
