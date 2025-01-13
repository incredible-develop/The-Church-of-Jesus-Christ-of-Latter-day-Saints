function updateFullUri(verify) {
	"use strict";
	try {
		var uriContext = $('#uriContext').val().toLowerCase();
		var path = $('#path').val().toLowerCase();
		if (uriContext[0] !== '/') {
		   uriContext = '/' + uriContext;
		}
		if (path[0] !== '/' && path !== '') {
			path = '/' + path;
		}
		path = uriContext + path;
		
		if (path.indexOf(sharedPrefix) === -1) {
			path = sharedPrefix + path;
		}
		path = cleanPath(path);
		$('#fullUri').val(path);
		$('#fullPath').val(path);
		if (verify) { verifyUrl(); }
	} catch (e) { }
}

function cleanPath(path) {
    "use strict";
    return $.trim(path).replace(/\ /g, '-').replace(/(-)\1+/g,'-').replace(/(\/)\1+/g, '/').toLowerCase().replace(/[`~!@#\$%\^\*\(\)\+={}\[\]:;'<>,\.\?\&]/g, '');
}

function verifyUrl() {
	"use strict";
    var locale = $('#locale').val();
    var fullUrl = $("#fullUri").val();
    var isValid = false;
    $.ajax({
        url:    sharedPrefix + "/ice/resources/ajax/validateUrl?" + ICE.langParam(locale) + '&url=' +  fullUrl,
        success: function(result) {
			var delim = result.indexOf("\n");
			var valid = result
			if (delim !== -1) {
				valid = result.substring(0, delim);
			}	
			
			if (valid === 'true') {
				$("#fullUri").closest('dl').removeClass('error');
				isValid = true;
			}
			if (isValid === false) {
                $("#fullUri").closest('dl').addClass('error');//.append("<span class='error'>Unavailable</span>");
			}
    	},
        async:   false,
		dataType: 'text'
   });
   return isValid;
}

function showLarge(url) {
	"use strict";
	newWindow(url);
}

function selectTemplate(templateId){
  var template = $('[id="' + templateId + '"]');
	template.attr('checked', 'checked');
	template.closest('section').siblings().removeClass('depressed');
}

$(function() {
	"use strict";
	var defaultContext = location.pathname.replace(/^\/([^\/]+)\/.*$/,'$1');
	if (defaultContext !== '/' && defaultContext !== '') {
		$('#uriContext').val(defaultContext).change();
	}
	
/*	$('#uriContext').change(function(e) { 
		updateFullUri(true);
	});*/
	$(".ixf-container").click(function() {
	//alert("Clicked Div")
	var rbutton = $(this).find(".template");
	if ($(rbutton).is(":checked"))
	{	
		$(rbutton).attr("checked", "");
	}
	else
	{
		$(rbutton).attr("checked", "checked");
	}
	});
	$('#path').blur(function(e) {
		updateFullUri(true);
	}).keyup(function(e){
		updateFullUri(false);
	});
	updateFullUri();
	$('#ldse-toolbar-buttons button:not("#action-save,#action-created,#action-submitted,.dropdown-right,#action-cancel")').remove();
	submitHandlers.push(
		function () {
			"use strict";
			var readOnly = $("#fullUri").data('readonly');
			var valid = true;
			if (readOnly === '' || readOnly === undefined) {
				valid = verifyUrl();
			}
			var template = $('.template:checked').val();
			$("#templateList").closest('dl').removeClass('error');
		    if (template === '' || template === undefined) {
				valid = false;
				$("#templateList").closest('dl').addClass('error');
				//jQuery("#templateList").prepend("<span class='error'>Please select a template.</span>");
		    }
			return valid;
		}
	);
});