$(function() {
  // Remove flash notifications from dom after 2.5 seconds
  var flash_notifs = $('#flash_notifications');
  if (flash_notifs.length) {
    setTimeout(function() {
      flash_notifs.animate({
        height: '0'
      }, 500, function() {
        $(this).remove();
      });
    }, 2500);
  }
});
