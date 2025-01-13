function addChannel(element, curIndex) {
	var subInput = $("#count" + curIndex);
	var n = parseInt(subInput.val()) + 1;
	subInput.val(n);
	var ajaxPath = sharedPrefix + "/ice/resources/ajax/navigation/getChannelEntry";
    $.ajax({
        type: "GET"
      ,  url: ajaxPath
      , data: {lang: "eng", 
    	       request: "channel",
    	       index: curIndex,
    	       count: n}
      , success: function(data) {
    	  $(data).insertBefore($(element));
      }
    });
}

function addSub(element, curIndex) {
	var li = $(element).closest('li');
	var ajaxPath = sharedPrefix + "/ice/resources/ajax/navigation/getChannelEntry";
    $.ajax({
        type: "GET"
      ,  url: ajaxPath
      , data: {lang: "eng", 
    	       request: "subchannel",
    	       index: curIndex}
      , success: function(data) {
    	  $(li).append($(data));
      }
    });
    $(element).remove();
}

function deleteEntry(element) {
	$(element).closest('li').remove();
}

function validateChannelForm(submit) {
	var noEmpty = true;
	$('#channelForm tr:not(.hidden) .required').each(function(index) {
		var name = $(this).attr('name').toLowerCase();
		var nan = false;
		if (name.indexOf('sequence') != -1) {
			var value = parseInt($(this).val())
			if (value != $(this).val() ) {
				nan = true;
			}
		}
		if ($(this).val() == '' || nan) {
			noEmpty = false;
			$(this).css( 'background-color', '#FF9288');
		} else {
			$(this).css( 'background-color', '#FFFFFF');
		}
	});
	
	if (noEmpty) {
		$('#message').html('');
		return true;
	} else {
		$('#message').html('Error: There are some required inputs without valid values.');
		return false;
	}
}

function isCustomNavigation(element) {
	if ($(element).val() == '') {
		$(element).closest('tr').nextAll('tr').removeClass('hidden');
	} else {
		$(element).closest('tr').nextAll('tr').addClass('hidden');
	}
}

function addChannelEntry(channelName) {
    if (channelName === '') {
        $('table.iceEditor').append('<tr><td class="delImage">&nbsp;</td><td><input type="text" name="sequence" size="2"/></td><td><input type="text" name="name" size="45"/></td><td><input type="text" name="url" size="45"/></td></tr>');
    } else {
        $('table.iceEditor').append('<tr><td class="delImage">&nbsp;</td><td><input type="text" name="sequence" size="3"/></td><td><input type="text" name="name" size="35"/></td><td><input type="text" name="url" size="35"/></td><td><input type="text" name="attrName" size="13"/></td></tr>');
    }
}