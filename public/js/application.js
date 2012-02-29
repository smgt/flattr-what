$(document).ready(function() {

  $('.form-search').on('submit', function() {
    var modalelement = $('#myModal');
    var opts = {
      lines: 8, // The number of lines to draw
      length: 14, // The length of each line
      width: 7, // The line thickness
      radius: 20, // The radius of the inner circle
      color: '#000', // #rgb or #rrggbb
      speed: 0.9, // Rounds per second
      trail: 41, // Afterglow percentage
      shadow: false, // Whether to render a shadow
      hwaccel: false, // Whether to use hardware acceleration
      className: 'spinner', // The CSS class to assign to the spinner
      zIndex: 2e9, // The z-index (defaults to 2000000000)
      top: 'auto', // Top position relative to parent in px
      left: 'auto' // Left position relative to parent in px
    };

    var options = {
      backdrop: true,
      keyboard: false,
      show: true
    }
    modalelement.modal(options);
    modalelement.show();
    var spinner = new Spinner(opts).spin($('.modal-spinner')[0]);
  });
});
