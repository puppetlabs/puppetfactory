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
});

function updatePage(name) {
  if (name) {
    var idx = $("#tabs > ul > li:contains("+name+")").index();
  }
  else {
    var idx = $("#tabs").tabs("option","active");
  }

  $("#tabs").tabs('load', idx);
}
