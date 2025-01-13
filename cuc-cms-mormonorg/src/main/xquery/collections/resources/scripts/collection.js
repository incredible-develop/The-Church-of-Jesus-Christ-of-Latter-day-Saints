$.ajaxSetup({
    beforeSend: showLoading,
    complete: clearLoading,
});
var modal = $("#modal1").trigger("close");

function promptDelete(statusValue) {
    var msg =
        "You are about to " +
        $(statusValue).text() +
        " this item." +
        "<br/>" +
        "<br/>" +
        "Click ok to discard the changes, or cancel to continue editing.";
    modal.find("div").remove();
    confirmDestructive("Warning", msg, statusValue);
    return false;
}

function missingImage(img) {
    $(img).replaceWith(
        '<span class="ldse-logo-image ldse-icon-logo ldse-icon ">&nbsp;</span>'
    );
}

function previewButtonClicked(href) {
    var success = function (status) {
        window.location.href = href;
    };

    if (hasChanges()) {
        var msg =
            "You have unsaved changes." +
            "<br/>" +
            "<br/>" +
            "Click ok to discard the changes, or cancel to continue editing.";
        modal.find("div").remove();
        confirmAction("Warning", msg, success);
    } else {
        window.location.href = href;
    }
}

function buttonClicked(statusValue) {
    var status = $(statusValue).attr("status");
    if (
        status === "ldse:publish" &&
        $("#collection-list").find(".ldse-info-banner.warning").length > 0
    ) {
        var newhtml =
            '<div class="confirmation"><header class="ldse-section--header"><h2>Collection Contains Unpublishable Items</h2></header><div class="ldse-section--body ldse-form"><dl><dt><label for="reason">Some items need approval by Cor-IP/Cor-Eval and cannot be published. Continue?</label></dt></dl>' +
            '<div class="ldse-form-buttons"><button class="ldse-button primary" onclick="finalSubmit(&quot;' +
            status +
            '&quot;); modal.trigger(&quot;close&quot;);">OK</button><button class="ldse-button" onclick="modal.trigger(&quot;close&quot;);">Cancel</button></div></div></div>';
        modal.html("").append(newhtml).trigger("open");
        return false;
    } else finalSubmit(status);
}

function finalSubmit(status) {
    var status = status;
    var saveOrder = true;
    teaserManagerSortChange();
    $.ajax({
        type: "POST",
        url: sharedPrefix + "/collections/ajax/update-files?lang=eng",
        data: {
            location: teaserLocation,
            uri: uri,
            newOrder: $("#manageTeaser-newOrder").val(),
            newFiles: $("#manageTeaser-newItems").val(),
            save: saveOrder,
            status: status,
        },
        dataType: "text",
        success: function (data) {
            postData.referer = referer;
            ICE.post(curPage, postData, "POST");
        },
        error: function (data) {
            alert(
                "Error",
                "The teasers could not be saved. Please reload the page and try again."
            );
        },
    });
}

function cancelChanges(uri, locale) {
    var h = hasChanges();
    var success = function (status) {
        window.location.href = uri + "?" + ICE.langParam(locale);
    };
    if (h) {
        var msg =
            "You have unsaved changes." +
            "<br/>" +
            "<br/>" +
            "Click ok to discard the changes, or cancel to continue editing.";
        var fn = "";
        modal.find("div").remove();
        confirmAction("Warning", msg, success);
    } else {
        success();
    }
    return false;
}

function searchTeasers(locale) {
    teaserManagerSortChange();
    var text = $("#filter-search").val();
    if (text == "") {
        return false;
    }
    var type = $(".collection-item").first().data("type");
    $.ajax({
        type: "POST",
        datatype: "json",
        data: {
            search: text,
            searchLocale: locale,
            type: type,
            referer: referer,
            ids: $("#manageTeaser-newOrder").val(),
        },
        url: sharedPrefix + "/collections/ajax/teaser-search?lang=eng",
        success: function (data) {
            if ($("#toggle-btn").text() == "Collapse All") {
                $("#toggle-btn").text("Expand All");
                $("#toggle-btn").removeClass("ldse-icon-ko-tri-right");
                $("#toggle-btn").addClass("ldse-icon-ko-tri-down");
            }
            SR.buildSearchResults(data);
            $(window).resize();
        },
        error: function (x, y, z) {
            var hole = 0;
        },
    });
}

function hasChanges() {
    teaserManagerSortChange();
    var currentOrder = $("#manageTeaser-newOrder").val();
    var changed = currentOrder != "" && currentOrder != originalOrder.join();
    return changed;
}

function confirmAction(title, text, fn, options) {
    var defaults = {
        refresh: true,
    };
    options = $.extend({}, defaults, options);
    modal.html("");
    var templateData = {
        title: title,
        text: text,
    };
    var display =
        '<div class="confirmation"><header class="ldse-section--header"><h2>' +
        title +
        '</h2></header><div class="ldse-section--body ldse-form"><dl><dt><label for="reason">' +
        text +
        '</label></dt></dl><div class="ldse-form-buttons"><input type="submit" class="ldse-button primary" value="OK" /><input type="button" class="ldse-button ldse-icon-ko-x ldse-modal-close" value="Cancel" /></div></div></div>';
    modal.append(display).trigger("open");
    modal.find(".ldse-button.primary").click(function () {
        fn(status);
        if (options.refresh) {
            window.location.href = referer;
        }
        modal.trigger("close");
        return false;
    });
}

function alert(title, text, callback) {
    modal.html("");
    var templateData = {
        title: title,
        text: text,
    };
    var display =
        '<div class="confirmation"><header class="ldse-section--header"><h2>' +
        title +
        '</h2></header><div class="ldse-section--body ldse-form"><dl><dt><label for="reason">' +
        text +
        '</label></dt></dl><div class="ldse-form-buttons"><input type="submit" class="ldse-button primary" value="OK" /></div></div></div>';
    modal.append(display).trigger("open");
    modal.find(".ldse-button.primary").click(function () {
        modal.trigger("close");
        if (callback) {
            callback();
        }
        return false;
    });
}

function confirmDestructive(title, text, statusValue) {
    var templateData = {
        title: title,
        text: text,
    };
    var display =
        '<div class="confirmation"><header class="ldse-section--header"><h2>' +
        title +
        '</h2></header><div class="ldse-section--body ldse-form"><dl><dt><label for="reason">' +
        text +
        '</label></dt></dl><div class="ldse-form-buttons"><input type="submit" class="ldse-button primary" value="OK" /><input type="button" class="ldse-button ldse-icon-ko-x ldse-modal-close" value="Cancel" /></div></div></div>';
    modal.append(display).trigger("open");
    modal.find(".ldse-button.primary").click(function () {
        buttonClicked(statusValue);
        modal.trigger("close");
        return false;
    });
}

function editFile(link) {
    if (hasChanges()) {
        confirmAction(
            "Warning",
            "You have unsaved changes." +
                "<br/>" +
                "<br/>" +
                "Click ok to discard the changes, or cancel to continue editing.",
            function () {
                ICE.postLink(link);
            },
            { refresh: false }
        );
    } else {
        ICE.postLink(link);
    }
    return false;
}

$(document).ready(function () {
    $(window).on("click", "#toggle-btn", function (e) {
        e.preventDefault();
        var $this = $(this),
            wrapper = $this.closest("section").find("li"),
            button = $("#toggle-btn");
        $this.closest("div").toggleClass("closed");
        wrapper.each(function (e) {
            if (
                $(this).find("section.ldse-block").hasClass("ldse-open") &&
                button.text() == "Collapse All"
            ) {
                $(this).find("a.ldse-icon-ko-tri-right").trigger("click");
            } else if (
                !$(this).find("section.ldse-block").hasClass("ldse-open") &&
                button.text() == "Expand All"
            ) {
                $(this).find("a.ldse-icon-ko-tri-right").trigger("click");
            } else {
            }
        });
        if (button.text() == "Expand All") {
            $("#toggle-btn").text("Collapse All");
            $("#toggle-btn").removeClass("ldse-icon-ko-tri-down");
            $("#toggle-btn").addClass("ldse-icon-ko-tri-right");
        } else {
            $("#toggle-btn").text("Expand All");
            $("#toggle-btn").removeClass("ldse-icon-ko-tri-right");
            $("#toggle-btn").addClass("ldse-icon-ko-tri-down");
        }
    });
    $(".clear-search").on("click", function (e) {
        e.preventDefault();
        $(".search-input").val("");
        $("#results-list").children().remove();
        $("#searchCurrentPage, #searchMaxPage").text("0");
    });
    Handlebars.registerHelper("forceBreak", function (passedString) {
        if (typeof passedString != "undefined") {
            passedString = passedString
                .replace(/\//g, "/&#8203;")
                .replace(/-/g, "-&#8203;")
                .replace(/_/g, "_&#8203;");
            return new Handlebars.SafeString(passedString);
        }
    });
    $(".handlebars-template").each(function () {
        window[$(this).attr("id")] = Handlebars.compile($(this).html());
    });
    $("#results-list, #collection-list")
        .sortable({
            connectWith: "#collection-list",
            forcePlaceholderSize: false,
            placeholder: "sortable-drop-zone ldse-clearfix",
            start: function (event, ui) {
                var width = ui.item.width() - 21;
                var height = ui.item.height();
                $(".sortable-drop-zone").width(width).height(height);
                $(".sortable").removeClass("ldse-rowFix ldse-makeCols");
            },
            change: function (event, ui) {},
            stop: function (event, ui) {
                $(".sortable").addClass("ldse-rowFix ldse-makeCols");
                $(window).resize();
            },
        })
        .disableSelection();
    $(".teaserManager").bind("sortupdate", teaserManagerSortChange);
    $("#results-list").on("click", "header a", function () {
        $(this).closest("li").find(".ldse-block--body").toggle(0);
        $(this).closest("section").toggleClass("ldse-open");
    });
    $("#collection-list").on(
        "click",
        "header a.collection-search-result",
        function () {
            $(this).closest("li").find(".ldse-block--body").toggle(0);
            $(this).closest("section").toggleClass("ldse-open");
        }
    );
    $(".add").live("click", function () {
        var open = false;
        var listItem = $(this).closest("li");
        if (
            listItem
                .find(".ldse-block-toggle")
                .hasClass("ldse-icon-ko-tri-down")
        ) {
            open = true;
        }
        var fileID = listItem.data("id");
        var newButton =
            '<button class="ldse-collection-button remove ldse-icon-x ldse-icon" data-uri="' +
            uri +
            '" data-locale="' +
            locale +
            '" data-fileid="' +
            fileID +
            '" id="remove-' +
            fileID +
            '">Remove</button>';
        listItem.find("button.add").replaceWith(newButton);
        $("#collection-list").append(listItem);
        if (open) {
            listItem.find(".ldse-block--body").show();
        }
        var newIds = $("#manageTeaser-newItems");
        newIds.val(newIds.val() + fileID + ",");
        teaserManagerSortChange();
    });
    $(".publish-item").click(function (e) {
        var action = "ldse:publish",
            item = $(this);
        if ($(item).hasClass("disabled")) {
            return false;
        }
        var file = $(item).data("fileid");
        var locale = $(item).data("locale");
        var uri = $(item).data("uri");
        var title = $(item).closest("li > section").find("h3").html();
        $.ajax({
            type: "POST",
            url:
                sharedPrefix +
                "/collections/ajax/collection-actions?" +
                ICE.langParam(locale),
            data: {
                locale: locale,
                action: action,
                id: file,
                uri: uri,
            },
            success: function (data) {
                alert(
                    "This item has successfuly been published",
                    title,
                    reload
                );
            },
            error: function (data) {
                alert(
                    "Error",
                    "The teasers could not be saved. Please reload the page and try again."
                );
            },
        });
    });

    $("#filter-search").keypress(function (e) {
        if (e.which == 13) {
            e.preventDefault();
            return $("#searchButton").trigger("click");
        }
    });

    $(".remove").live("click", function (e) {
        var whichButton = e.target.id;
        var itemName = $("#" + whichButton)
            .closest("header")
            .find("h3")
            .text();
        var index = $("#" + whichButton)
            .closest("li")
            .attr("index");
        var display =
            '<div class="confirmation"><header class="ldse-section--header"><h2>Remove Item from Collection</h2></header><div class="ldse-section--body ldse-form"><dl><dt>' +
            itemName +
            '</dt></dl><div class="ldse-form-buttons"><input type="button" class="ldse-button destructive" value="OK" ' +
            'onclick="removeItem(' +
            index +
            ",'" +
            whichButton +
            "'); modal.trigger('close'); return false;\"/>" +
            '<input type="button" class="ldse-button ldse-icon-ko-x ldse-modal-close" value="Cancel" /></div></div></div>';
        modal.find("div").remove();
        modal.append(display).trigger("open");
    });
});

function reload() {
    var data = postData;
    ICE.post(
        sharedPrefix + "/collections?" + ICE.langParam(locale),
        data,
        "POST"
    );
}

function removeItem(index, button) {
    var whichButton = $("#" + button),
        uri = whichButton.data("uri"),
        locale = whichButton.data("locale"),
        fileId = whichButton.data("fileid"),
        li = whichButton.closest("li"),
        isNew = li.data("new") == true;

    if (!isNew) {
        $.ajax({
            type: "post",
            datatype: "xml",
            data: {
                id: fileId,
            },
            async: true,
            url:
                sharedPrefix +
                "/collections/ajax/remove-item?" +
                ICE.langParam(locale),
            success: function () {
                li.remove();
                $(window).resize();
            },
        });
    } else {
        li.remove();
    }
}

function teaserManagerSortChange(event, ui) {
    var newOrder = "";
    $(".teaserManager li").each(function () {
        if (newOrder.length > 0) newOrder += ",";
        newOrder += $(this).attr("data-id");
    });
    $("#manageTeaser-newOrder").val(newOrder);

    if (ui && ui.item.has("button.add")) {
        var open = false;
        if (
            ui.item.find(".ldse-block-toggle").hasClass("ldse-icon-ko-tri-down")
        ) {
            open = true;
        }
        var fileID = ui.item.data("id");
        var newIds = $("#manageTeaser-newItems");
        newIds.val(newIds.val() + fileID + ",");
        var newButton =
            '<button class="ldse-collection-button remove ldse-icon-x ldse-icon" data-uri="' +
            uri +
            '" data-locale="' +
            locale +
            '" data-fileid="' +
            fileID +
            '" id="remove-' +
            fileID +
            '">Remove</button>';
        ui.item.find("button.add").replaceWith(newButton);
        if (open) {
            ui.item.find(".ldse-block--body").show();
        }
    }
}

function showLoading() {
    $("html").addClass("loading");
}
function clearLoading() {
    $("html").removeClass("loading");
}

var SR = {
    results: [],
    page: 1,
    maxPage: 1,
    pageLength: 24,
    elements: {
        nextArrow: $("#searchNext") /*arrow link right*/,
        prevArrow: $("#searchPrevious") /*arrow link left*/,
        currentPage: $("#searchCurrentPage") /*current pagination span*/,
        maxPage: $("#searchMaxPage") /*total pagination span*/,
    },

    buildSearchResults: function (data) {
        SR.results = data;
        SR.changePage(1);
        var results = $("#results").show();
        if (results.hasClass("closed")) {
            results.find("header h2 a").click();
        }
    },

    renderPage: function () {
        var start = (SR.page - 1) * SR.pageLength;
        var end = SR.page * SR.pageLength;
        var data = { results: SR.results.slice(start, end) };
        SR.updatePagination();
        SR.elements.currentPage.html(SR.page);
        SR.updateMaxPage();
        SR.elements.maxPage.html(SR.maxPage);
        if (SR.results.length == 0) {
            $("#results-list").html("<li>No Results Found</li>");
        } else {
            $("#results-list").html(listItemTemplate(data));
        }
        $(window).resize();
    },

    updateMaxPage: function () {
        SR.maxPage = Math.ceil(SR.results.length / SR.pageLength);
        SR.elements.maxPage.html(SR.maxPage);
    },

    updatePagination: function () {
        if (SR.page === SR.maxPage) {
            SR.elements.nextArrow.addClass("faded");
            SR.elements.nextArrow.addClass("disabled");
        } else {
            SR.elements.nextArrow.removeClass("faded");
        }
        if (SR.page === 1) {
            SR.elements.prevArrow.addClass("faded");
            SR.elements.prevArrow.addClass("disabled");
        } else {
            SR.elements.prevArrow.removeClass("faded");
        }
    },

    changePageSize: function (value) {
        if (SR.pageLength !== value) {
            SR.pageLength = value;
            SR.updatePageLink();
            SR.updateMaxPage();
            SR.changePage(1);
            SR.renderPage();
        }
    },

    updatePageLink: function () {
        var pageSizeElement = $(
            "span.ldse-pagination--shownum a[data-count=" + SR.pageLength + "]"
        )[0];
        $("span.ldse-pagination--shownum a").not("[href]").attr("href", "#d");
        $(pageSizeElement).removeAttr("href");
    },

    changePage: function (value) {
        SR.page = value;
        SR.elements.currentPage.html(SR.page);
        SR.renderPage();
    },

    nextPage: function () {
        if (SR.page < SR.maxPage) {
            SR.changePage(SR.page + 1);
        }
    },

    previousPage: function () {
        if (SR.page > 1) {
            SR.changePage(SR.page - 1);
        }
    },
}; //end search object
