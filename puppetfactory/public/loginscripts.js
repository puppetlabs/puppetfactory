$(document).ready(function(){
  $('#show-alternate').click( function(e) {
    e.preventDefault();

    $( "#alternate" ).dialog({
      buttons: {
        Ok: function() {
          $( this ).dialog( "close" );
        }
      },
      open: function () {
        $(this).parent().find('button:nth-child(1)').focus();
      },
      width: '500px',
    });
  });
});
