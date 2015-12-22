$(document).ready(function(){

  function setWarning(message) {
    $("#notifications").addClass("fail");
    $("#notifications").text("Error: " + message);
    //alert("Dashboard update failed:\n" + message);
  }

  function pokeServer(url, handler) {
    $.get(url, function(data) {
      console.log(data);
      var results = jQuery.parseJSON(data);
      if(results.status == 'success') {
        if (typeof handler === 'function') {
          handler.call();
        }
      }
      else {
        setWarning(results.message);
      }
    }).fail(function(jqXHR) {
      setWarning(jqXHR.responseText);
    });
  }

  function setSelected(selected) {
    if (selected == 'all') {
      $('.progressbar').show();
    }
    else {
      $('.progressbar').hide();
      if(selected) { $('.progressbar.'+selected).show(); }
    }

    return selected;
  }

  function updateResults() {
    // Unbind existing event handlers so they don't cascade when the content is updated
    $('#update').off();
    $('#current').off();
    updatePage();
  }

  function initializeView() {
    selected = $('#current').val();
    setSelected(selected);

    setTimeout(updateResults, 30 * 1000);
  }

  $('#update').button({
    icons: {
      primary: "ui-icon-refresh"
    }
  });

  $('#update').click(function(){
    $(this).button("disable");
    $("#notifications").text("Updating...");

    pokeServer('/dashboard/update', function(){
      updateResults();
    });
  });

  $('#current').change(function(){
    var selected = $(this).val();

    setSelected(selected);
    pokeServer('/dashboard/set/' + selected);
  });

  $('#show-explanation').click( function(e) {
    e.preventDefault();

    $( "#explanation" ).dialog({
      title: $(this).attr("title"),
      position: {
        my: "top",
        at: "top",
        of: window
      },
      buttons: {
        Ok: function() {
          $( this ).dialog( "close" );
        }
      },
      open: function () {
        $(this).scrollTop(0);
        $(this).parent().find('button:nth-child(1)').focus();
      },
      height: 500,
      width: 600,
    });
  });

  /*******************   Set up initial page state *****************/
  initializeView();
});
