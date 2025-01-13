function updateFullUri(verify) {
	"use strict";
	try {
		var uriContext = document.getElementById("uriContext").value.toLowerCase();
		var path = document.getElementById("path").value.toLowerCase();
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
		document.getElementById("uri").value = path;
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
    var locale = ICE.formVars.$lang;
    var fullUrl = document.getElementById("uri").value;
    var isValid = false;
    $.ajax({
        url:    sharedPrefix + "/content-admin/ajax/isUniqueSlug?" + ICE.langParam(locale) + '&url=' +  fullUrl,
        success: function(result) {
			var delim = result.indexOf("\n");
			var valid = result
			if (delim !== -1) {
				valid = result.substring(0, delim);
			}
			if (valid === 'true') {
				$("#uri").closest('dl').removeClass('error');
				$("#uri").closest('dd').find('label').hide();
				document.getElementById("action-save").removeAttribute('disabled');
				document.getElementById("action-publish").removeAttribute('disabled')
				isValid = true;
			}
			if (isValid === false) {
                $("#uri").closest('dl').addClass('error');
                $("#uri").addClass('error');
                event.target.classList.add('error');
                $("#uri").closest('dd').append('<label for="permalink" class="error">Duplicate URI</label>');
                $("#uri").closest('dd').find('label').text('Duplicate URI');
                document.getElementById("action-save").setAttribute('disabled', "");
                document.getElementById("action-publish").setAttribute('disabled', "");
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
	document.getElementById("uri").onchange = function() { verifyUrl() }
});