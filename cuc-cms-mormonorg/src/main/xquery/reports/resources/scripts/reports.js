$(function(){
	ixf.popup.show.solo = true;
	ixf.setup();
	$('.ui-layout-west .ixf-table').masterDetail({
			cacheResults:false, 
			loadFirst: false,
			onloaddetail:function(){
				if ($('#detail:has(meta)').length != 0) {
					location.reload();
				}; 
				ixf.setup($("#detail"));
			}
	});
	$('.sortable').sortable();
});


$('.breakdown').live('click', function(){
	var row = $(this).closest('tr');
	var level = row.data('level');
	var nextLevel = level + 1;
	var looping = true;
	var next = row.next("tr");
	var listing = $(this).hasClass('list');
	if (listing) {
		$(this).removeClass('list').addClass('remove');
	} else {
		$(this).removeClass('remove').addClass('list');
	}
	var curLevel = next.data('level');
	while (looping && next.length >= 1) {
		if (curLevel == nextLevel) {
			if (listing) {
				next.removeClass('close').addClass('show');
			} else {
				next.removeClass('show').addClass('close');
				next.find('.breakdown').removeClass('remove').addClass('list');
			}
			
		} else if (!listing && curLevel > nextLevel) {
			next.removeClass('show').addClass('close');
			next.find('.breakdown').removeClass('remove').addClass('list');
		}
		next = next.next("tr");
		curLevel = next.data('level');
		if (curLevel == level) {
			looping = false;
			break;
		}
	}
	return false;
});