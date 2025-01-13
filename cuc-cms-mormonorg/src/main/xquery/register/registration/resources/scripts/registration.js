var childID;
var siteName = $("#site-name");
$(document).ready(function(){
    var getRequestParam = function(name){
        var pairs = window.location.search.substring(1).split("&");
        for(var p in pairs) {
            var item = pairs[p];
            var v = item.split("=");
            if (v[0] == name)
                return v[1];
        }
        return "";
    }
    if (getRequestParam('register') == 'success'){
        $('.ldse-alert-container').fadeIn('slow');
        $(".ldse-alert-text").text("Site Registered");
    } else if (getRequestParam('save') == 'success'){
        $('.ldse-alert-container').fadeIn();
    }
    else {
        $('.ldse-alert-container').css('display', 'none');
    }
    $('.ldse-alert-close').click(function(){
        $('.ldse-alert-container').fadeOut();
    });
    $("fieldset").removeClass("table");
    /*$(".translation-check").val("Translation Services")*/
    if($(".translation-services").attr("checked")){
        $(".translation-fields").show();
        $('#post-to-zip').val('/' + siteName.val() + '/shared/lds-edit/translation/from/uploadZip?lang=eng');
    } else {
        $(".translation-fields").hide();
    }
    $('.ldse-form').find('span').css('width', '')
    $(".translation").change(function(){
        $(".translation-fields").toggle();
        $('#post-to-zip').val('/' + siteName.val() + '/shared/lds-edit/translation/from/uploadZip?lang=eng');
    });
    $('.iceForm').submit(function(e) {
        $("html").addClass("loading");
        e.preventDefault();
        $('.iceForm').ajaxSubmit({
            dataType: "json",
            success: function (data) {
                if (data.success == true) {
                    if ($('.save-button').val() === 'Register') {
                        document.location = "/register?lang=eng&register=success";
                    } else {
                        document.location = "/register?lang=eng&save=success";
                    }
                } else {
                    markErrors(data.error);
                    /*                appendage();*/
                    $("html").removeClass("loading");
                }
            },
            error: function (data) {
                $("#action-save").removeAttr("disabled");
                $("html").removeClass("loading");
                return false;
            }
        });
    });
});

$(document).ready(function(changeUserName){
    $('input.nospaces').keypress(function( e ) {
        if ( e.which === 32 ) {
            return false;
        }
        var siteName = document.getElementById("site-name").value;
        var newSiteName = cleanPath(siteName);
        document.getElementById("site-name").value = newSiteName;
        document.getElementById("post-to-zip").value = '/' + newSiteName + '/shared/lds-edit/translation/from/uploadZip?lang=eng';
    });
});

function cleanPath(path) {
    "use strict";
    return $.trim(path).replace(/\ /g, '-').replace(/(-)\1+/g,'-').replace(/(\/)\1+/g, '/').toLowerCase().replace(/[`~!@#\$%\^\*\(\)\+={}\[\]:;'<>,\.\?\&]/g, '');
}

function markErrors(error) {
    $("#basic-info dl.error, #basic-info form tr.error").removeClass("error");
    $("#basic-info dl").find('span').remove();
    $.each(error, function(index, obj) {
        $("#basic-info form input[name='" + obj.name + "']").closest('dl').find('span')
            .remove();
        $("#basic-info form input[name='" + obj.name + "']")
            .closest('dl,dt').addClass("error");
        $("#basic-info form input[name='" + obj.name + "']").closest('dl').find('label')
            .append("<span class='error'>  - " + obj.text + "</span>");
    });
    $("#action-save").removeAttr("disabled");
};
function submitForm(form){
    jQuery(form).submit();
    $("#action-save").attr("disabled", "disabled");
};