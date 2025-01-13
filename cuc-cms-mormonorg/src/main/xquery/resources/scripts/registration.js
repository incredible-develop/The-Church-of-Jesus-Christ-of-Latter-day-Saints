
var siteName = $("#site-name");
$(document).ready(function(){
/*    appendage();
   $(".ldse-info-button").click( function(e) {
		e.preventDefault();
		$(this).toggleClass("ldse-show-info");
	});
	$(".ldse-toggle-content").on("click", function(e){
	   e.preventDefault();
		var info = $(this).data("selector");
		if($(info).hasClass("ldse-hidden")) {
			$(info).removeClass("ldse-hidden");
			$(info).css('display', 'none');				
		}
		$(info).slideToggle(function() {
			$(info).css('overflow', 'visible');
			LDSE.resizeCallbacks.makeCols();
		});
	});*/

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
    $(".read-write").closest("dd").prepend("<div class='site-user-name' style='float:left; padding-top: 10px;'>" + siteName.val() + "-" + "</div>");
    $(".read-only").closest("dd").prepend("<div class='site-user-name' style='float:left; padding-top: 10px;'>" + siteName.val() + "-" + "</div>");
    $("fieldset").removeClass("table");
    /*$(".translation-check").val("Translation Services")*/
    if($(".translation").attr("checked")){
        $(".translation-fields").show();
    } else {
        $(".translation-fields").hide();
    }
    if($(".services").attr("checked")){
        $(".services-fields").show();
    } else {
        $(".services-fields").hide();
    }
    $('.ldse-form').find('span').css('width', '')
    $(".translation").change(function(){
        $(".translation-fields").toggle();
    });
    $(".services").on('click', function(){
        $(".services-fields").toggle();
        if ( $(".services:checked").val() !== undefined ) {
            $('#server').val(server);
            $('#port').val(port);
            $('#post-to-zip').val('/services/lds-edit/uploadZip?lang=eng');
            changeUserName();
        } else {
            $('#server').val("");
            $('#port').val("");
            $('#post-to-zip').val('/shared/lds-edit/translation/from/uploadZip?lang=eng');
        }
    });
/*    $('.iceForm').submit(function(e) {
        $("html").addClass("loading");
        e.preventDefault();
        $('.iceForm').ajaxSubmit({
            dataType: "json",
            success: function (data) {
                if (data.success == true) {
                    if($('.save-button').val() === 'Register'){
                        document.location = "/register?lang=eng&register=success";
                    } else {
                        document.location = "/register?lang=eng&save=success";
                    }
                } else {
                    markErrors(data.error);
                    appendage();
                    $("html").removeClass("loading");
                }
            },
            error: function (jqXHR, textStatus, errorThrown) {
                if (jqXHR.status === 421) {
    				var response = $.parseJSON(jqXHR.getResponseHeader("json"));
    				if (!response.success) {
    					markErrors(response.error);
                        $("html").removeClass("loading");
    				}
                } else {
                    alert('Submission Error! Double Check your information to verify it is correct');
                    $("#action-save").removeAttr("disabled");
                    $("html").removeClass("loading");
                }
            }
        });
        return false;
    });
    */
});

$(document).ready(function(changeUserName){
    $('input.nospaces').keypress(function( e ) { 
        if(e.which === 32) 
            return false;    
    });
});

function appendage (){
/*    $('#server').closest('dl').find('dt').append("<span class='ldse-info-button ldse-icon-ko-info ldse-icon ldse-toggle-content' data-selector='#tags-info-text'>Show Info</span>");
    $('#port').closest('dl').find('dt').append("<span class='ldse-info-button ldse-icon-ko-info ldse-icon ldse-toggle-content' data-selector='#tags-info-text2'>Show Info</span>");
    $('#post-to-zip').closest('dl').find('dt').append("<span class='ldse-info-button ldse-icon-ko-info ldse-icon ldse-toggle-content' data-selector='#tags-info-text3'>Show Info</span>");
    $('#post-to-zip').closest('dl').find('dt').append("<div class='ldse-info-text ldse-hidden' id='tags-info-text3'>This field is completed for you if registering for LDS-Publisher Services</div>");
    $('#server').closest('dl').find('dt').append("<div class='ldse-info-text ldse-hidden' id='tags-info-text'>This field is completed for you if registering for LDS-Publisher Services</div>");
    $('#port').closest('dl').find('dt').append("<div class='ldse-info-text ldse-hidden' id='tags-info-text2'>This field is completed for you if registering for LDS-Publisher Services</div>");*/
};

function changeUserName() {
    var newWidth = "";
    siteName.val(siteName.val().toLowerCase());
    $(".site-user-name").html(siteName.val() + "-");
    newWidth = siteName.width() - $(".site-user-name").width();
    $("input.read-write").width(newWidth);
    $("input.read-only").width(newWidth);
};

siteName.bind('input', changeUserName);

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