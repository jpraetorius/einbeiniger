$(document).ready(function() {
	$('#registrations-table tr.data').on("click", function(event){
		if (event.target.tagName != "A") {
			// show the modal only on non link elements to keep their default behaviour
			$('#detailsModal').modal('show')
		}
	});
	$('#tags').tagsInput();
});