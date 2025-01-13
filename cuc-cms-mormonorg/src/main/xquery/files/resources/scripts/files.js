var modal = $('#modal1').trigger('close');
var editor;

$(document).ready(function () {
    $('.ldse-modal-backdrop').on('click', function () {
        $(modal).trigger('close');
    });
});
function getFilesById(button) {
    var id = $(button).closest('form').find('input.searchId').val(),
        uri = $(button).closest('form').find('input.searchUri').val(),
        locale = $(button).closest('form').find('input.searchLocale').val();
    $.ajax({
        type: "POST",
        url: sharedPrefix + "/files/ajax/get-files-by?lang=eng",
        data: {
            "id" : id,
            "uri": uri,
            "locale": locale
        },
        success: function (data) {
            $(modal).trigger('close');
            $('table#detail-table tbody').children().remove();
        	var trs = $(data).filter('tr');
            $('table#detail-table tbody').append(trs);
        }
    });
};

function getFilesByIdForm() {
    $(modal).find('section').remove();
    $(modal).append('<section><header class="ldse-section--header"><h2>File Query</h2></header>' + 
                    '<form class="ldse-section--body content-table ldse-form iceForm form-data">' + 
                    '<dl><dt><label for="file-id">File Id</label></dt><dd><input type="text" class="searchId" name="file-id"/></dd></dl>' +
                    '<dl><dt><label for="file-id">File Uri</label></dt><dd><input type="text" class="searchUri" name="uri"/></dd></dl>' +
                    '<dl><dt><label for="file-id">File Locale</label></dt><dd><input type="text" class="searchLocale" name="locale"/></dd></dl>' +
                    '<button class="ldse-button primary" onclick="getFilesById(this); return false;">Run</button><button class="ldse-button ldse-modal-close">Cancel</button></form></section>');
    $(modal).trigger('open');
};

function getAllDuplicateFiles(button) {
    var directory = $(button).closest('form').find('input').val();
    $('html').addClass('loading');
    $.ajax({
        type: "POST",
        url: sharedPrefix + "/files/ajax/get-all-duplicate-files?lang=eng",
        data: {
            "directory" : directory
        },
        success: function (data) {
            $(modal).trigger('close');
            $('html').removeClass('loading');
            /*$('table#detail-table tbody').children().remove();
        	var trs = $(data).filter('tr');
            $('table#detail-table tbody').append(trs);*/
            alert('This process may take a while. Please refresh the page to see results');
        },
        error: function () {
            $(modal).trigger('close');
            $('html').removeClass('loading');
            alert('Error querying files...please try again');
        }
    });
};

function getAllDuplicateFilesForm() {
    $(modal).find('section').remove();
    $(modal).append('<section><header class="ldse-section--header"><h2>File Query</h2></header>' + 
                    '<form class="ldse-section--body content-table ldse-form iceForm form-data"><dl><dt><label for="file-id">Directory</label></dt><dd><input type="text" name="directory"/></dd></dl><button class="ldse-button primary" onclick="getAllDuplicateFiles(this); return false;">Run</button><button class="ldse-button ldse-modal-close">Cancel</button></form></section>');
    $(modal).trigger('open');
};

function viewXml(uri) {
    $('html').addClass('loading');
    $.ajax({
        type: "POST",
        url: sharedPrefix + "/files/ajax/get-xml?lang=eng",
        data: {
            "uri" : uri
        },
        success: function (data) {
            $('html').removeClass('loading');
            $(modal).find('section').remove();
            $(modal).append('<section><header class="ldse-section--header"><h2>Edit File</h2></header><form class="ldse-section--body content-table ldse-form iceForm form-data"><textarea ui-codemirror="editor" class="file-item" id="code">' + data + '</textarea></form><button onclick="saveXml(' + "'" + uri + "'" +')" class="ldse-button primary ldse-responsive-button ldse-icon-check2">Save</button><button class="ldse-button ldse-responsive-button ldse-icon-ko-x ldse-modal-close">Cancel</button></section>');
            
            $(modal).trigger('open');
            editor = CodeMirror.fromTextArea(document.getElementById("code"), {
                styleActiveLine: true,
                matchBrackets: true,
                lineNumbers: true,
                width: "100px",
                mode: "application/xml",
                value: data
            });
            $(modal).trigger('close');
            $(modal).trigger('open');
        },
        error: function () {
            $(modal).trigger('close');
            $('html').removeClass('loading');
        }
    });
};

function saveXml(uri) {
    $.ajax({
        type: "POST",
        contentType: "application/x-www-form-urlencoded",
        dataType: "html",
        url: sharedPrefix + "/files/ajax/save-xml?lang=eng",
        data: {
            "uri" : uri,
            "xml" : newXml
        },
        success: function (data) {
            $('html').removeClass('loading');
            $(modal).find('section').remove();
			sessionStorage.message = "Save Successful.";
      		$("#save-alert").css("display", "block");
      		$(".ldse-alert-text").text(sessionStorage.message);
            $(modal).trigger('close');
        },
        error: function () {
            $(modal).trigger('close');
            $('html').removeClass('loading');
			sessionStorage.message = "Error Saving.";
      		$("#save-alert").css("display", "block");
      		$(".ldse-alert-text").text(sessionStorage.message);
        }
    });
};