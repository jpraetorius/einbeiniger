$(document).ready(function() {
	// enable tooltips on the icons in the table
	$('#registrations-table i').tooltip();

	// enable popovers for thw whole text
	$('#registrations-table .po').popover();

	 // make the details button trigger the modal
    $('#registrations-table .details').on("click", function(event){
    	var id = $(this).data("id");
    	$('#detailsModal-'+id).modal('show');
    });

	// handle the delete icons to mark the tables to delete
	$('#registrations-table .delete').on("click", function(event){
	  var addValue = $(this).hasClass('icon-remove-circle');
	  $(this).toggleClass('icon-remove-circle icon-trash icon-large text-error');
	  $(this).closest('tr').toggleClass('error');
	  var id = $(this).data("id");
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

	$('.tags').tagsInput();

	$('.tag-store').on('click', function(event){
		var id = $(this).data("id")
		var token = $('#xhr_token').text();
		var tags = $('#tags-'+id).val();
		$('#message-'+id).removeClass('textSuccess').text('');
		$.post('/tags', 
			jQuery.param({xhr_csrf: token, id: id, tags: tags})
		).done(function(data){
			$('#xhr_token').text(data);
			$('#message-'+id).addClass('text-success').text('Tags gespeichert!');
		}).fail(function(data){
			$('#message-'+id).addClass('text-error').text('Speichern fehlgeschlagen!');
		});
	});
});