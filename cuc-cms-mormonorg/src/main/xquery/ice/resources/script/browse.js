$(function(){
	$("#pdfFile").change(function(){
		if ($(this).val() !== '') {
			$('#pdfSave').removeAttr("disabled");
		} else {
			$('#pdfSave').attr("disabled", "true");
		}
	}).change();
});

function ajaxForm() {
	var form = $('.ldseForm form')
	if (form.length > 0) {
        var options = {
            data: { ajax: 'true' },
            dataType: 'json',
            success: function(data, statusText, xhr, $form) {
            	$('.ldseForm').remove().dialog( "close" );
            	$('.quicksearch').val(data.search);
            	$('.filters form').submit();
             	
            }
        };
		form.ajaxForm(options);
	} else {
		setTimeout("ajaxForm()", "1000");
	}
};

function moreInfo(id, locale) {
	if ($('.ldseForm').length > 0) { $('.ldseForm').remove(); }
	$('<div class="ldseForm"></div>').appendTo('body');
    	$.ajax({
    		type: "POST",
            url: sharedPrefix + '/ice/resources/ajax/viewXml?' + ICE.langParam(locale),
            data: { id : id },
            success: function (html) {
                $('.ldseForm').html(html).dialog({
                	position: [($(window).width() / 2) - (900 / 2), 150],
                    dialogClass: "ldseForm ldse-modal",
                    height: 450,
                    width: 900,
                    zIndex: 4000,
                    draggable: true,
                    title : "XML Viewer",
                    close: function() {
                        $('.ldseForm').remove().dialog( "close" );
                    }
                });
                ICE.fixSelects();
            }
    });
	// Should updated this to use /content/resources/ajax/viewXml
}

function selectTeaser(teaserType, id, page, currentPage, pageLocation, lang) {
	$.ajax({
		  url: sharedPrefix + '/ice/resources/ajax/teaser/pageAddTeaser',
		  data: { 
				lang: getLang(lang), 
				country: getCountry(lang), 
				teaserType: teaserType, 
				id: id, 
				page: page, 
				currentPage: currentPage, 
				pageLocation: pageLocation 
		  },
		  success: function(data) {
			  window.opener.location.reload();
			  alert('You may need to refresh the page for the changes to occur.');
			  window.close();
		  },
		  error: function(data) {
			  alert('Error: failed to add teaser to page.');
		  }
	});
}

function insertTeaserTag(type, currentId, currentPage, lang) {
	var id = copyTeaserToNewPage(currentId, lang, currentPage, 'inline');
	
	var editorName = window.opener.CKEDITOR.currentInstanceName;
	window.opener.CKEDITOR.instances[editorName].insertHtml('<br/><pre>['+ type + ':' + id + ']</pre><br/>');window.close();
}

function insertPdfLink(href, fileName) {
	var editorName = window.opener.CKEDITOR.currentInstanceName;
	window.opener.CKEDITOR.instances[editorName].insertHtml('<a href="' + href + '">'+ fileName + '</a>');window.close();
}

function selectImageUrl(newValue) {
	var inputs = window.opener.document.getElementsByTagName('input');
	for (var i = 0; i < inputs.length; i++){
		if(inputs[i].className == 'cke_dialog_ui_input_text'){
			inputs[i].value = newValue;
			break;
		}
	}
}

function copyTeaserToNewPage(currentId, lang, currentPage, pageLocation){
	var path = sharedPrefix + "/ice/resources/ajax/teaser/copy-teaser-to-page?" + ICE.langParam(lang) + '&currentId=' + currentId + '&pageLocation=' + pageLocation + '&currentPage=' + currentPage;
	var id = $.ajax({
		  url: path,
		  async: false
		}).responseText;
	return id
}


function insertVideoIntoList(videoHash) {
	var newVideo =  '<li>' +
						'<div onClick="deleteReference(this)" class="deleteButton" style="width:10px; color: red;">(X)</div>' +
						'<input type="text" name="videoHash" value="' + videoHash + '"/>' +
				    '</li>';
	var list = window.opener.document.getElementById("videoList");
	jQuery(list).append(newVideo);
	window.close();
}

function insertImageIntoList(imageHash) {
	var newImage =  '<li>' +
						'<div onClick="deleteReference(this)" class="deleteButton" style="width:10px; color: red;">(X)</div>' +
						'<input type="text" name="imageUri" value="' + imageHash + '"/>' +
					'</li>';
	var list = window.opener.document.getElementById("imageList");
	jQuery(list).append(newImage);
	window.close();
}

function insertAudioIntoList(audioHash) {
	var newImage =  '<li>' +
						'<div onClick="deleteReference(this)" class="deleteButton" style="width:10px; color: red;">(X)</div>' +
						'<input type="text" name="audioHash" value="' + audioHash + '"/>' +
					'</li>';
	var list = window.opener.document.getElementById("audioList");
	jQuery(list).append(newImage);
	window.close();
}