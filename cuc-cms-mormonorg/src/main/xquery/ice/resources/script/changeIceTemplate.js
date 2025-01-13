jQuery(document).ready(function() {
	var types = unescape(ICE.formVars.switchTypes).split('|');    
    if (types.length > 0 && typeof ICE.formVars.switchTypes != "undefined") {
    	var currentForm = ICE.formVars.form;
    	var menu = '';
    	var label = '<dt id="changeTeaserId"><label for="changeTeaserButton">Change Teaser Type</label></dt>';
		for (var i = 0; i < types.length; i++) {
			var hash = types[i].split(':');
			var formName = hash[0];
			var style = "";
			if (formName == currentForm) {
				style = 'style="background: -moz-linear-gradient(center top , #AAAAAA, #AAAAAA) repeat scroll 0 0 #E8E5DE;" ';
			}
			if (hash.length > 1) { 
				var formTitle = hash[1];
			} else {
				formTitle = formName;
			}
			if (formName == currentForm) 
			{menu += '<option ' + style + 'class="changeForm" selected="selected" data-form="' + formName + '" id="formName' + formName + '">' + formTitle + '</option>';} else {
				menu += '<option ' + style + 'class="changeForm" data-form="' + formName + '" id="formName' + formName + '">' + formTitle + '</option>';
			}
	    }
    	var button = '<select id="changeTeaserButton"><options>' + menu + '</options></select><br /><br />';
        $('fieldset.content-section').prepend(button);
        $('fieldset.content-section').prepend(label);
        prepareChangeButtons();
    }
});

var menuShown = false;

function prepareChangeButtons() {
	jQuery('#changeTeaserButton').change(function() {
        var newFormType = $('#changeTeaserButton option:selected').data('form');
        var oldCurrentForm = ICE.formVars.form;
        var postValues = ICE.postVars[oldCurrentForm];
        postValues.option = postValues.option.replace(postValues.option.split("%3A")[1].split("%2C")[0], newFormType);
        ICE.post("/form?lang=" + ICE.formVars.lang + "&country=" + ICE.formVars.country, postValues);
    });
}