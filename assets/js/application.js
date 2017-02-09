$(function() {
  // Remove flash notifications from dom after 2.5 seconds
  if ($('#flash_notifications').length) {
    setTimeout(function() {
      $('#flash_notifications').animate({
        height: '0'
      }, 500, function() {
        $(this).remove();
      })
    }, 2500);
  }
});
