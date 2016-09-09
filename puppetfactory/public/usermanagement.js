$(document).ready(function(){

  function validUsername(text) {
    var legalChars = /^[a-z][a-z0-9]{2,}$/; // Allow only letters for first character and then alphanumeric
    if (!legalChars.test(text)) {
      alert("Usernames must be at least 3 lowercase alphanumeric characters and start with a letter\n");
      return false;
    };
    return true;
  };

  function open() {
    $('#showuser').hide();
    $('#newuserwrapper').addClass("open");
    $('#newuser').slideDown("fast");
    $('#user').focus();
  }

  function close() {
    $('#showuser').show();
    $('#newuserwrapper').removeClass("open");
    $('#newuser').hide();
  }

  function start_processing() {
    $('#newuser input[type=button]').attr("disabled", true);
    $('#newuser').addClass("processing");
    $('#newuser table').activity({width: 5.5, space: 6, length: 13});
  }

  function stop_processing() {
    $('#newuser').removeClass("processing");
    $('#newuser input[type=button]').attr("disabled", false);
    $('#newuser table').activity(false);
  }

  function failing(item) {
    item.attr("value", "");
    item.addClass("fail");
    item.focus();
  }

  // toggle hide the newuser dialog
  $('#showuser').click(function(){
    open();
  });
  $('#hideuser').click(function(){
    close();
  });

  $('#users .select a').click(function(event){
    event.preventDefault();
    var action = $(this).attr('href');

    $.get(action, function(data) {
      updatePage();
    });
  });

  // save the new user
  $('#save').click(function(){
    var username  = $('#user').val();
    var password  = $('#password').val();
    var password2 = $('#password2').val();
    var session   = $('#session').val();

    // reset warnings
    $('#user').removeClass("fail");
    $('#password').removeClass("fail");
    $('#password2').removeClass("fail");
    $('#session').removeClass("fail");

    if(!validUsername(username)) {
      failing($('#user'));
    }
    else if(password == '' || password != password2) {
      failing($('#password'));
      failing($('#password2'));
    }
    else if(session == '') {
      failing($('#session'));
    }
    else {
      start_processing();

      $.post('/new', {username: username, password: password, session: session}, function(data) {
        console.log(data);
        var results = jQuery.parseJSON(data);
        if(results.status == 'success') {
          updatePage();
        }
        else {
          stop_processing();
          alert("Could not create user:\n" + results.message);
        }
      }).fail(function(jqXHR) {
        stop_processing();
        alert("Could not create user:\n" + jqXHR.responseText);
      });

    }

  });

  $('#deploy').click(function(){
    var button   = $(this);
    var activity = button.siblings('i');
    var username = button.attr("data-user");

    activity.addClass('fa-spinner fa-spin');
    button.attr("disabled", true);
    $.ajax({
      url: '/api/users/'+username,
      type: 'PUT',
      data: "action=deploy",
      success: function(response) {
        var results = jQuery.parseJSON(response);

        activity.removeClass('fa-spinner fa-spin');
        button.attr("disabled", false);

        if(results.status != 'success') {
          alert("Deploy failed. See logs for details.");
        }
      },
      error: function(response) {
        activity.removeClass('fa-spinner fa-spin');
        alert("Deploy failed:\n" + response.responseText);
      }
    });
  });

});
