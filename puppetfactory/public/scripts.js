$(document).ready(function(){
  // activate tabs
  $('#tabs').tabs({
    beforeLoad: function (event, ui) {
      var keepLoading = true;

      // Is the <a> tag is classified with 'cache'?
      if (ui.tab.children("a").first().hasClass("cache")) {
        keepLoading = (ui.panel.html() == "");
      }

      if(ui.panel.html() == "") {
        ui.panel.html('Loading...');
      }

      return keepLoading;
    },
  });

  $('#login').button({
    icons: {
      primary: "ui-icon-locked"
    }
  });
});
