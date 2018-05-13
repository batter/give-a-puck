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

function pageScroll() {
	window.scrollBy(0,35); // horizontal and vertical scroll increments
	scrolldelay = setTimeout('pageScroll()',200); // scrolls every 100 milliseconds
}

var delay = (function() {
  var timer = 0;
  return function(callback, ms) {
    clearTimeout (timer);
    timer = setTimeout(callback, ms);
  };
})();
