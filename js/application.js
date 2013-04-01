$(document).ready(function() {
	$('#registrations-table i').tooltip();

	$('#registrations-table .details').on("click", function(event){
		$('#detailsModal').modal('show')
	});

	$('#registrations-table .delete').on("click", function(event){
	  var addValue = $(this).hasClass('icon-remove-circle');
	  $(this).toggleClass('icon-remove-circle icon-trash icon-large text-error')
	  $(this).closest('tr').toggleClass('error')
	  var id = $(this).data("id")
	  var vals = $('#delete_ids').val().split(",");
	  
	  if (addValue) {
	    vals.push(id);
	    // remove empty element, if there was one
	    var position = vals.indexOf("");
	    if (~position){
	      vals.splice(position, 1);
	    }
	  }
	  else {
	    var position = vals.indexOf(id);
	    vals.splice(position, 1);
	  }
	  
	  var newval = "";
	  if (vals.length == 1) {
	    newval = vals[0];
	  }
	  else if (vals.length > 1) {
	    newval = vals.join(",");
	  }
	  $('#delete_ids').val(newval);
	  if (vals.length == 0){
	    $('#delete-button').addClass('disabled').attr('disabled');
	  }
	  else {
	    $('#delete-button').removeClass('disabled').removeAttr('disabled');
	  }
	});

	$('#tags').tagsInput();
});