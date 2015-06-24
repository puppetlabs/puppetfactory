$(document).ready(function(){

  function validate(fld) {
    var error = "";
    var legalChars = /^[a-z][a-z0-9]{2,}$/; // Allow only letters for first character and then alphanumeric

    if (fld.value == "") {
      if (!legalChars.test(fld.value)) {
        fld.style.background = 'Yellow';
        error = "Only alphanumeric characters are allowed in usernames.\n";
        alert(error);
        return '';
      }
      // Return an empty string if username is invalid
      return fld;
    };
  };

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

    // Validate the user input and replace with blank if invalid
    username = validate(username);

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
