var checkboxes = $(":checkbox"),
    modal = $('#modal1');
$(function () {
    modal.append("<div class='ldse-iframe-container'><iframe class='ldse-iframe' src=''></iframe></div>")
    $( '#sensitive-table-body input[type="checkbox"]' ).prop('checked', "");
    $('#details-checkall').prop("checked", "");
    $('#details-checkall').click(function(event) {
        $( '#sensitive-table-body input[type="checkbox"]' ).prop('checked', this.checked);
        
/*        if(this.checked) {
            // Iterate each checkbox
            checkboxes.each(function() {
                this.checked = true;                        
            });
        } else {
            checkboxes.each(function() {
                this.checked = false;                        
            });
        }*/
    });
    $(".rowSelect, #details-checkall").on("change, click", function (){
        if ( $("#sensitive-table-body :checkbox:checked").length > 0 ) {
            $("#action-approve").show();
        } else {
            $("#action-approve").hide();
        }
    });
});

function approveSensitive() {
    $("#action-approve").attr("disable", "disable");
    var ids = [];
    $("#sensitive-table-body :checkbox:checked").each(function () {
        ids.push($(this).val());
    })
    $("html").addClass('loading');
    $.ajax({
        type: "POST",
    	contentType: "application/x-www-form-urlencoded",
    	dataType: "json",
		url: sharedPrefix + "/shared/lds-edit/sensitive/resources/ajax/approve-item?lang=eng",
        data: {
            ids: ids,
            locale: locale
        },
        success: function (data) {
            window.location.reload();
        },
        error: function (data) {
            $("html").removeClass('loading');
            $("#action-approve").attr("disable", "");
        }
    });
};

function unpublishSensitive() {
    var ids = [];
    $("#sensitive-table-body :checkbox:checked").each(function () {
        ids.push($(this).val());
    })
    $.ajax({
        type: "POST",
    	contentType: "application/x-www-form-urlencoded",
    	dataType: "json",
		url: sharedPrefix + "/shared/lds-edit/sensitive/resources/ajax/unpublish-item?lang=eng",
        data: {
            ids: ids,
            locale: locale
        },
        success: function (data) {
            window.location.reload();
        },
        error: function (data) {
            
        }
    });
};

function openItem(url) {
/*    var url = $(item).attr("location");*/
    $(".ldse-iframe").attr("src", url);
    $(".ldse-iframe-container").css("width", "100%").css("height", "100%");
    $(".ldse-iframe").css("width", "100%").css("height", "100%");
    $(modal).css("width", "98%").css("height", "80%");
    
    $(".ldse-page").prepend("<button onclick='closeModal(); return false;' class='ldse-icon ldse-icon-x ldse-button secondary ldse-close-modal-button' style='z-index:100000; position:absolute; right: 0px; top: 0px; margin:60px 15px 0 0;'><button>");
    $(modal).trigger('open');
    
};

function closeModal() {
    modal.trigger('close');
    $(".ldse-iframe").attr("src", "");
    $(".ldse-close-modal-button").remove();
    $(".ldse-page button").remove();
};