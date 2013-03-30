$(document).ready(function() {
  var state="ready";
  var startdate = null;
  var timeline_container = $("#timeline");
   $("#start").click(function() {
     switch(state){
      case "ready":
        startdate = new XDate();
        state = "running";
        timeline_container.prepend('<h3>Tracking session started at ' + startdate.toString('dd.MM.yyyy HH:mm:ss') + '</h3>');
        timeline_container.append(addRow(formatDateDiff(startdate, startdate), 'Intro', startdate.getTime()));
        $("#start").html("<i class='icon-bookmark-empty icon-large'> </i>Add new Timestamp...");
        $("#stop").removeClass('hide');
        break;
      case "running":
        var now = new XDate();
        timeline_container.append(addRow(formatDateDiff(startdate, now), '', now.getTime()));
        break;
      case "finished":
        break;
     }
   });
   
   $("#stop").click(function() {
    var now = new XDate();
    timeline_container.append(addRow(formatDateDiff(startdate, now), 'End', now.getTime()));
    state = "finished";
    startdate = null;
    timeline_container.append('<h3>Tracking session stopped at ' + now.toString('dd.MM.yyyy HH:mm:ss') + '</h3>');
    $("#control-buttons").addClass('hide');
    $("#dl-buttons").removeClass('hide');
    $("#help").addClass('help-show');
   });

   $("#reload").click(function() {
    location.reload();
   });

   $("#auphonic").click(function() {
    
   });

   $("#podlove").click(function(e) {
      $.fileDownload('/podlove', {
        httpMethod: "POST",
        data: $("#timeline input").serialize()
      });
      e.preventDefault(); //otherwise a normal form submit would occur
   });

   $(document).on("click", "a.delete", function(){
    var div = $(this).closest('div.row-fluid').remove();
    return false;
   });


 });

// Diffs all Timefields of two XDates and returns a Timestring containing the result
function formatDateDiff(startdate, now) {
  var hours = Math.floor(startdate.diffHours(now));
  var minutes = Math.floor(startdate.diffMinutes(now));
  minutes = minutes - hours * 60; // subtract all elapsed hours
  var seconds = Math.floor(startdate.diffSeconds(now));
  seconds = seconds - ((hours * 3600) + (minutes * 60)); // subtract all elapsed hours and minutes
  var milliseconds = startdate.diffMilliseconds(now);
  milliseconds = milliseconds - ((hours * 3600000) + (minutes * 60000) + (seconds * 1000)); // subtract all elapsed hours, minutes and seconds

  if (hours < 10) { hours = "0" + hours; }
  if (minutes < 10) { minutes = "0" + minutes; }
  if (seconds < 10) { seconds = "0" + seconds; }
  if (milliseconds < 10) { milliseconds = "00" + milliseconds; }
  else if (milliseconds < 100) { milliseconds = "0" + milliseconds; }
  
  return hours + ":" + minutes + ":" + seconds + "." + milliseconds;
}

function addRow(diff, text, id) {

  var template = '<div class="row-fluid">' +
    '<div class="span3">' +
      '<input type="text" class="input-block-level" placeholder="Timecode" name="timecode_'+ id +'" value="'+ diff +'" />' +
      '<input type="hidden" name="timecode_absolute_'+ id +'" value="'+ id +'" />' +
    '</div>' + 
    '<div class="span8">' +
      '<input type="text" class="input-block-level" placeholder="Please enter a description..." name="text_'+ id +'" value="' + text + '" />' +
    '</div>' + 
    '<div class="span1">' + 
      '<a href="#" title="delete this entry" class="icon-remove icon-2x delete" id="'+ id +'"> </a>' + 
    '</div>' + 
  '</div>';

  return template;
}

