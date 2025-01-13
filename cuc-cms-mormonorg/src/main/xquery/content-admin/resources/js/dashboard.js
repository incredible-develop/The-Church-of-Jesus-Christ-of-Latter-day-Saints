var modal = document.getElementById("modal1");
(function ($) {
    $.fn.hasScrollBar = function () {
        return this.get(0)
            ? this.get(0).scrollHeight > this.innerHeight(true)
            : false;
    };
    $.each($("region-div"), function (index, value) {
        var id = $(value).attr("id");

        $("#" + id + " section section .sortable-items").multisortable({
            items: ".content-grouping",
            handle: "h2.node-title",
            connectWith: ".content-grouping",
            selectedClass: "selected",
            stop: function (e) {
                $(".sortable-items")
                    .children(".selected")
                    .each(function (i, selected) {
                        updatePage();
                    });
            },
        });
    });

    markNav();
    $("#nodes > div.content-grouping").multisortable();
    $("#nodes > div.content-grouping").sortable(
        "option",
        "connectWith",
        ".sort-items"
    );

    var checkboxes = document.getElementsByClassName("collection-checkbox");
    for (var i = 0; i < checkboxes.length; i++) {
        checkboxes[i].addEventListener("change", function () {
            for (var i = 0; i < checkboxes.length; i++) {
                if (checkboxes[i].checked) {
                    document.getElementById(
                        "publish-collections-button"
                    ).style.display = "block";
                    document.getElementById(
                        "unpublish-collections-button"
                    ).style.display = "block";
                    document.getElementById(
                        "remove-collections-button"
                    ).style.display = "block";
                    return;
                }
            }
            document.getElementById(
                "publish-collections-button"
            ).style.display = "none";
            document.getElementById(
                "unpublish-collections-button"
            ).style.display = "none";
            document.getElementById("remove-collections-button").style.display =
                "none";
        });
    }
})(jQuery);

var debug = false, //print debug code to console
    nodesToPull = 20, //Number of nodes to pull each time
    maxNodes = 500, //highest number of nodes to display at one time
    initialized = false, //Is this a new requst?
    startNode = 0, //Current node to pull (incremented by nodesToPull)
    loading = false, //is ajax currently requeting?
    timeStamp = Math.round(+new Date() / 1000), //Unix timestamp for ajax requests
    modal = $("#modal1").trigger("close"); // modal for viewing content

/*	updateTimestamp

 Updates timestamp to current time (unix)
 to send with an ajax pagination request.
 Updated when filters are applied or reset
 */
function updateTimestamp() {
    timeStamp = Math.round(+new Date() / 1000);
}

function performActionOnItems(action, uri, lang, site, findItems, id) {
    if (action.indexOf("delete") != -1) {
        var options = {
            okText: "Delete",
            okClass: "destructive ldse-icon-trash",
        };
    } else if (action.indexOf("unpublish") != -1) {
        var options = {
            okText: "Unpublish",
            okClass: "destructive ldse-icon-unpublish",
        };
    } else if (action.indexOf("publish") != -1) {
        var options = {
            okText: "Publish",
            okClass: "primary ldse-icon-send",
            id: id,
        };
    }
    function complete() {
        publishResources();
        $("html").addClass("loading");
        $.ajax({
            dataType: "json",
            url:
                sharedPrefix +
                "/content-admin/ajax/action?lang=" +
                getUrlParameter("lang"),
            data: {
                action: action,
                site: site,
                uri: uri,
                id: id,
                getItems: findItems,
            },
            error: function (data) {
                $("html").removeClass("loading");
                alertText("Error", "Error Performing Action. Try Again Later");
            },
            success: function (data) {
                $("html").removeClass("loading");
                alertText("Success", "Action Performed Successfully");
            },
        });
    }
    function publishResources() {
        if (action.indexOf("publish") !== -1) {
            $.ajax({
                url:
                    sharedPrefix +
                    "/string-manager/ajax/publishBundles?lang=" +
                    getUrlParameter("lang"),
                data: {
                    id: id,
                },
                error: function (data) {
                    alertText("Error", "Error Publishing Resource Bundles.");
                },
            });
        }
    }

    if (
        action.indexOf("publish") !== -1 &&
        $("." + id).attr("data-bundle-missing") === "true"
    ) {
        var missingCount = $("." + id).attr("data-bundle-missing-count");
        displayBundleModal(missingCount);
    } else {
        ICE.alertText(
            "Warning",
            "Are you sure you want to " +
                options.okText +
                " <b>ALL</b> these items?",
            complete,
            options
        );
    }
}

function markNav() {
    var headers = document.querySelector(".nav-header");
    var tempSibling;

    for (var i = 0; i < headers.length; i++) {
        tempSibling = headers[i];

        while (tempSibling.nextSibling)
            if ((tempSibling = tempSibling.nextSibling).nodeName == "A")
                tempSibling.style.display = "block";
    }
}

function collapseHeaders(item) {
    var div = document.getElementsByClassName(item.getAttribute("id"))[0];
    if (div.style.display == "block" || div.style.display == "") {
        div.style.display = "none";
        item.classList.add("ldse-icon-tri-down");
        item.classList.remove("ldse-icon-tri-up");
    } else {
        item.classList.add("ldse-icon-tri-up");
        item.classList.remove("ldse-icon-tri-down");
        div.style.display = "block";
    }
}

function alertText(title, text, onOk, options) {
    var defaults = {
        okText: "OK",
        okClass: "primary ldse-icon-check2",
        cancelText: "Cancel",
        cancelClass: "ldse-icon-x",
    };
    options = $.extend({}, defaults, options);
    $("#alertModal").remove().dialog("close");
    var modal = $(
        '<div id="alertModal" class="ldseForm">' +
            '<form class="ldse-section--body ldse-form">' +
            "<dl><dt><label>" +
            text +
            "</label></dt></dl>" +
            '<div class="ldse-form-buttons">' +
            '<button id="alert-ok" class="ldse-button ' +
            options.okClass +
            '" onclick="window.location.reload();">' +
            options.okText +
            "</button>" +
            "</div>" +
            "</form>" +
            "</div>"
    );
    modal.find("#alert-ok").click(function (e) {
        e.preventDefault();
        e.stopPropagation();
        $("#alertModal").remove().dialog("close");
        if (typeof onOk !== "undefined") {
            onOk();
        }
        return false;
    });
    modal.find("#alert-cancel").click(function (e) {
        e.preventDefault();
        e.stopPropagation();
        $("#alertModal").remove().dialog("close");
    });
    //$('body').append(modal);
    modal.dialog({
        position: [window.innerWidth / 2 - 150, 150],
        dialogClass: "ldse-modal ldse-form ldseForm",
        height: "auto",
        width: "350",
        zIndex: 99999999,
        draggable: true,
        modal: true,
        title: title,
        close: function () {
            $("#alertModal").remove().dialog("close");
        },
    });
}

function addItemToPage(id, region, clone) {
    // -- Adding cloning option
    var cloneRequested = clone === undefined ? "" : "&clone=clone";
    // --
    $.ajax({
        dataType: "json",
        url:
            sharedPrefix +
            "/content-admin/ajax/add-to-page?lang=" +
            getUrlParameter("lang") +
            "&uri=" +
            getUrlParameter("uri") +
            "&site=" +
            getUrlParameter("site") +
            cloneRequested,
        data: {
            id: id,
            region: region[0].getAttribute("id"),
        },
        error: function (data) {
            if (debug) {
                console.log("Error Posting Positions");
                console.log(data);
            }
        },
        success: function (data) {
            // build the video gallery via json/handlebars
            if (debug) {
                console.log("Ajax success: json/videoGallery");
                console.log(data);
            }
        },
    });
}

function updatePage() {
    var regions = $("region-div");
    var ids = "";
    var contents = $(".content-grouping");
    $.each(regions, function (key, value) {
        var regionIds = $(value).find(
            "div.content-grouping, div.page-grouping"
        );
        for (var i = 0; i <= regionIds.length; i++) {
            if (regionIds[i] !== undefined) {
                ids += regionIds[i].getAttribute("data-id") + " ";
            }
        }
    });
    $.ajax({
        dataType: "json",
        type: "POST",
        url:
            sharedPrefix +
            "/content-admin/ajax/update-custom-page?lang=" +
            getUrlParameter("lang") +
            "&uri=" +
            getUrlParameter("uri") +
            "&site=" +
            getUrlParameter("site"),
        data: {
            ids: ids,
        },
        error: function (data) {
            if (debug) {
                console.log("Error Posting Positions");
                console.log(data);
            }
        },
        success: function (data) {
            // Update menu status
            if (
                $(".page-grouping ul.nodeContainer .ldse-status-published")
                    .length > 0
            )
                $(".page-grouping ul.nodeContainer .ldse-ice-menu-container")
                    .removeClass("ldse-status-published")
                    .addClass("ldse-status-modified");
            // build the video gallery via json/handlebars
            if (debug) {
                console.log("Ajax success: json/videoGallery");
                console.log(data);
            }
        },
    });
}

/*	populateNodes

 Builds a request URL, and makes the page request.
 Sends date to ajaxCallback function
 */
function populateNodes(storyCount, filters) {
    requestUrl =
        sharedPrefix +
        "/ajax/get-content?" +
        filters +
        "&start=" +
        startNode +
        "&count=" +
        nodesToPull +
        "&timestamp=" +
        timeStamp;
    if (debug) {
        //		console.log(storyCount);
        //		console.log(filters);
        //		console.log(requestUrl);
    }
    $.ajax({
        dataType: "json",
        url: requestUrl,
        error: function (data) {
            if (debug) {
                console.log("Ajax node json call failed");
                console.log(data);
            }
        },
        success: function (data) {
            // build the video gallery via json/handlebars
            if (debug) {
                console.log("Ajax success: json/videoGallery");
                console.log(data);
            }
            ajaxCallback(data);
        },
    });
}

function updateAsset(status) {
    var checkboxes = document.getElementsByClassName("collection-checkbox"),
        ids = [];
    for (var i = 0; i < checkboxes.length; i++) {
        if (checkboxes[i].checked) {
            ids.push(checkboxes[i].value);
        }
    }

    $.ajax({
        dataType: "json",
        url:
            sharedPrefix +
            "/content-admin/ajax/update-collection-asset?lang=" +
            getUrlParameter("lang"),
        data: {
            ids: ids,
            assetId: getUrlParameter("asset-id"),
            site: getUrlParameter("site"),
            status: status,
        },
        error: function (data) {},
        success: function (data) {
            window.location.reload();
        },
    });
}

function ajaxCallback(data) {
    if (data.total && data.total < maxNodes) {
        maxNodes = data.total;
    }
    buildNodes(data);
    buildChart(data.published.data.values, data.published.data.startDate);
}

/*	buildNodes

 Compiles handlebars node templates,
 Runs templates with json data,
 inserts nodes into .nodeContainer (when needed)
 */
function closeModal() {
    modal.trigger("close");
    $(".ldse-iframe").attr("src", "");
    $(".ldse-close-modal-button").remove();
}
function viewItem(item) {
    var url = $(item).attr("location");
    $(".ldse-iframe").attr("src", url);
    $(".ldse-page").prepend(
        "<button onclick='closeModal(); return false;' class='ldse-icon ldse-icon-x ldse-button secondary ldse-close-modal-button' style='z-index:100000; position:absolute; right: 0px; top: 0px; margin:60px 15px 0 0;'><button>"
    );
    $(modal).trigger("open");
}

function fixImage(image) {
    $(image).replaceWith(
        "<span class='ldse-logo-image ldse-icon ldse-icon-logo' style='margin: 40px 100px; font-size: 4em;'></span>"
    );
    return false;
}

function openSearchModal(button, id) {
    var result = searchData(button, id);
    if (result) {
        var modal = document.getElementById("modal1");
        modal.style.display = "block";
        document.getElementById("ldse-modal-backdrop").style.display = "block";
        $("html,body").scrollTop($("#inline-image-search").offset());
    }
}

function searchData(button, id) {
    var searchItem = $(button).data("item");
    (modal = $("#modal1").trigger("close").addClass("large")),
        (formName = document
            .getElementById(id)
            .selectedOptions[0].getAttribute("name")),
        (fileId = $(button).data("file-id")),
        (max = $(button).closest("dl").find("ul:first").data("max")),
        (liCount = $(button)
            .closest("dl")
            .children("dd")
            .children("ul")
            .children("li")
            .filter(function () {
                return $(this).html();
            }).length);

    if (max && max <= liCount) {
        alert("Error " + max + " is the max number you can add", function () {
            window.close();
        });
        return false;
    }

    var colTemplate, seaTemplate;
    $.ajax({
        url: sharedPrefix + "/collections/ajax/collectionMain.html",
        type: "GET",
        dataType: "html",
        success: function (data) {
            colTemplate = Handlebars.compile(data);
            buildColSearModal();

            //set up all the listeners on the form
            $("#modal-form").submit(function (e) {
                e.preventDefault();
                searchCollection(fileId);
            });
            $("#modal-search-button").click(function (e) {
                e.preventDefault();
                searchCollection(fileId);
            });
            $("#modal1").on(
                "click",
                "ul.collection-modal-list li header a",
                function () {
                    $(this).closest("li").find(".ldse-block--body").toggle(0);
                    $(this).closest("section").toggleClass("ldse-open");
                }
            );
            $("#modal1").on("click", ".addFromSearch", function () {
                var buttonObj = $(button).prev();
                var parent =
                    buttonObj[0].parentElement.parentElement.parentElement;
                var newItem = buttonObj.data("item");
                var region = $(parent).closest("region-div"),
                    id = this.getAttribute("data-id");
                //                    var childIndex = parseInt(buttonObj.data('childcount')) + 1;
                //                    buttonObj.data('childcount', childIndex);
                //                    newItem = newItem.replace(/INDEXHERE/g, childIndex);
                //                    buttonObj.siblings('ul').append(newItem);
                //                    ICE.fixedWidth(buttonObj.siblings('ul').find('li > dl > dt > label'));
                //                    //ICE.setupForm();
                //                    var newItem = buttonObj.siblings('ul').find('li').last();
                //                    var newItemText = $(this).data("title");
                //                    var newItemId = $(this).data("id");
                //                    var newEditLink = '<h3><a href="#d" class="editFormItem" data-id=' + newItemId + ' data-form=' + formName + ' data-options=' + 'form:' + formName + '>' + newItemText + '</a></h3>';
                //                    newItem.find('h3').replaceWith(newEditLink);
                //                    newItem.find('fieldset input').val(newItemId);
                //                    newItem.find('fieldset input').attr("id", newItemId);
                //                    ICE.addOnClicks();
                //                    ICE.addCKEditor(newItem);
                //                    ICE.fixSelects();
                //                    ICE.loadDatePickers();
                //                    if ( $('li.repeated-item').length >= $('.add-existing-button').attr('data-max') ) {
                //                        $('button.addFromSearch').hide();
                //                        $('.add-existing-button').hide();
                //                    }
                //                    if ($('form.ldse-form .required').length > 0) {
                //                        $("form.ldse-form").validate({
                //                            onfocusout: function (element) {
                //                                $(element).valid();
                //                            }
                //                        });
                //                    }

                // $(this).parent().remove();
                $(this).hide();
                ICE.coripCanPublish();
                // User has requested a clone of the component (yes/no)
                if ($(button).attr("class").includes("clone-existing-button"))
                    addItemToPage(id, region, "clone");
                else addItemToPage(id, region);
            });
            document
                .getElementById("ldse-collection-modal-done")
                .addEventListener("click", function () {
                    document.getElementById("modal1").style.display = "none";
                    document.getElementById(
                        "ldse-modal-backdrop"
                    ).style.display = "none";
                    window.location.reload();
                });
            //            $("#modal1").on("click", "#ldse-collection-modal-done", function () {
            //                /* remove listeners */
            //                $("#modal1").off("click", "#ldse-collection-modal-done");
            //                $('#modal1').off("click", '.addFromSearch');
            //                $('#modal1').off("click", "ul.collection-modal-list li header a");
            //
            //                $('#inline-' + formName + '-search').siblings().remove();
            //                $('#inline-' + formName + '-search').remove()
            //                var modal = $('#modal1').trigger('close').removeClass('large');
            //                $('.iceForm > div').show();
            //                ICE.fixSelects();
            //            });
        },
        error: function () {
            //TEMPLATE ISSUE, but don't tell the user
            alert("Search modal could not be loaded");
        },
    });

    var buildColSearModal = function () {
        $("#modal1")
            .html("")
            .append(
                $(
                    '<div id="inline-' +
                        formName +
                        '-search" style="max-height: 700px; overflow:auto;"><header class="ldse-section--header"><h2>Search</h2></header>'
                )
            )
            .append(colTemplate({}))
            .append(
                '<link rel="stylesheet" type="text/css" href="' +
                    sharedPrefix +
                    '/resources/css/collection-manager.css">'
            );
    };
    var searchCollection = function (fileId) {
        var searchContainer = $("#modal-search-results"),
            collections = $("ul.sortable fieldset input");
        (ids = []), (id = "");
        searchContainer.html("");

        for (var i = 0; i < collections.length; i++) {
            ids.push($(collections[i]).attr("id"));
        }
        $.ajax({
            type: "POST",
            url: sharedPrefix + "/ice/search?" + ICE.langParam(locale),
            data: {
                option: "form:" + formName,
                query: $("#modal-search").val(),
                site: getUrlParameter("site"),
                id: fileId,
                ids: ids,
            },
            dataType: "json",
            success: function (json) {
                $.ajax({
                    url:
                        sharedPrefix +
                        "/collections/ajax/collectionSearchResults.html",
                    type: "GET",
                    dataType: "html",
                    success: function (data) {
                        seaTemplate = Handlebars.compile(data);
                        if (json !== null) {
                            searchContainer.html(seaTemplate(json.results));
                        } else {
                            $(".search-results").html("There are no results");
                        }
                        $(window).resize();
                    },
                    error: function () {
                        //TEMPLATE ISSUE, but don't tell the user
                        alert("Search modal could not be loaded");
                    },
                });
            },
        });
    };
    $("#modal1").show();
    return true;
}

/*
Handlebars.registerHelper('isImage', function(passedString) {
    if ( this.img ) {
        return "<img src='" + this.img + "' class='ldse-calendar-image' onerror='fixImage(this);'></img>";
    } else { return "<span class='ldse-logo-image ldse-icon ldse-icon-logo' style='margin: 40px 100px; font-size: 4em;'></span>"}
});
var nodePublished_tmpl = Handlebars.compile("<li id='publishedNode' class='node node-stats '><header><h2 class='node-title'>{{title}}</h2><!--<span class='site'>{{site}}</span>--></header><section><div class='node-row'><span class='node-left node-title large'>{{subtitle}}</span><span class='node-right large'>{{count}}</span></div><div id='published-chart' class='node-chart'></div></section></li>");
var nodeTranslation_tmpl = Handlebars.compile("<li id='translationNode' class='node node-stats'><header><h2 class='node-title'>{{title}}</h2><!--<span class='site'>{{site}}</span>--></header><section><div class='count-of-sent'><div class='node-row'><span class='node-left node-title large'>Sent</span><span class='node-right large'>{{sent.count}}</span></div><div class='node-row'><span class='node-left'>TGP</span><span class='node-right'>{{sent.tgp}}</span></div><div class='node-row'><span class='node-left'>Word Count</span><span class='node-right'>{{sent.wordcount}}</span></div></div><div class='count-of-returned'><div class='node-row node-space'><span class='node-left node-title large'>Returned</span><span class='node-right large'>{{returned.count}}</span></div><div class='node-row'><span class='node-left'>TGP</span><span class='node-right'>{{returned.tgp}}</span></div><div class='node-row'><span class='node-left'>Word Count</span><span class='node-right'>{{returned.wordcount}}</span></div></div></section></li>");
var nodeIpeval_tmpl = Handlebars.compile("<li id='ipevalNode' class='node node-stats'><header><h2 class='node-title'>{{title}}</h2><!--<span class='site'>{{site}}</span>--></header><section><span class='node-left node-title large'>Sent</span><span class='node-right large'>{{sent}}</span><div class='node-row'><div class='node-row node-space'><span class='node-left large node-title'>Approved</span><span class='node-right large'>{{approved.approved}}</span></div><div class='progressbar'><div id='progressApproved' style='width:{{approved.percent}}%'></div></div></div><div class='node-row'><span class='node-left'>Average Approval Time</span><span class='node-right'>{{approved.time}}</span></div><div class='node-row node-space'><span class='node-left large node-title'>Declined</span><span class='node-right large'>{{declined.declined}}</span></div><div class='node-row'><div class='progressbar'><div id='progressDeclined' style='width:{{declined.percent}}%'></div></div></div></section></li>");
var nodeTop_tmpl = Handlebars.compile("<li id='topNode' class='node node-stats'><header><h2 class='node-title'>{{title}}</h2><span class='site'>{{subtitle}}</span></header><section class='rows-shaded'>{{#each sites}}<div class='node-row'><span class='node-left'>{{title}}</span><span class='node-right'>{{count}}</span></div>{{/each}}</section></li>");
var nodeStory_tmpl = Handlebars.compile("{{#each stories}}<li class='node node-content'><header><a href='javascript:void(0)' onclick='viewItem(this);' location='{{url}}' return false;' class='node-vignet'>{{#isImage}}{{/isImage}}</a></header><section><div class='table'><span class='site'>{{site}}</span><span class='lang'>{{lang}}</span></div><div class='content node-row'>{{description}}</div><div class='content node-row content-type' title='{{type}}'>{{type}}</div></section><footer class='content'><span class='date node-left'><span class='day'>{{date.day}}</span>{{date.month}}<br/>{{date.year}}</span><span class='status published node-right'>{{status}}</span><br/><span class='time node-right'>{{date.time}}</span></footer></li>{{/each}}");
*/

function buildNodes(data) {
    var lang = $("#langSelector").val();
    var site = $("#siteSelector").val();
    var nodePublished_html = nodePublished_tmpl(data.published);
    var nodeTranslation_html = nodeTranslation_tmpl(data.translation);
    if (lang === "eng" || lang === "") {
        var nodeIpeval_html = nodeIpeval_tmpl(data.ipeval);
    }

    if (site === "") {
        var nodeTop_html = nodeTop_tmpl(data.top);
    }
    var nodeStory_html = nodeStory_tmpl(data);

    if (!initialized) {
        $(".nodeContainer").html(nodePublished_html);
        $(".nodeContainer").append(nodeTranslation_html);
        if (lang === "eng" || lang === "") {
            $(".nodeContainer").append(nodeIpeval_html);
        }
        $(".nodeContainer").append(nodeTop_html);
        $(".nodeContainer").append(nodeStory_html);
        applyIsotope();
    } else {
        $(".nodeContainer").isotope("insert", $(nodeStory_html), function () {
            console.log("Nodes Appended");
            $("#loadingGif").hide();
            loading = false;
        });
    }
    if (lang !== "eng" && lang !== "") {
        $("div.count-of-sent").css("visibility", "hidden");
    } else {
        $("div.count-of-sent").css("visibility", "visible");
    }
    if (lang == "eng") {
        $("div.count-of-returned").css("visibility", "hidden");
    } else {
        $("div.count-of-returned").css("visibility", "visible");
    }
}

/*	applyIsotope

 Initiates the jquery.isotope plugin over story nodes
 */

function applyIsotope() {
    $(".nodeContainer").isotope({
        // options
        itemSelector: ".node",
        masonry: { columnWidth: 270 },
        containerStyle: {},
        animationOptions: { duration: 100, easing: "linear", queue: false },
        animationEngine: "jquery",
        transformsEnabled: false,
    });
    initialized = true;
    fixNodeListHeightWidth();
}
function reLayout() {
    $(".nodeContainer").isotope("reLayout");
    fixNodeListHeightWidth();
}

function fixNodeListHeightWidth() {
    //$('#nodes').width('auto');
    //var height = window.innerHeight - $('.nodeContainer').offset(false).top - 15;
    //var width = window.innerWidth - $('.nodeContainer').offset(false).left;
    //$('.nodeContainer').attr('style','overflow-y:auto; height:' + height + 'px !important; width:' + width + 'px !important; min-height:' + height + 'px !important; min-width:' + width + 'px !important; max-height:' + height + 'px !important; max-width:' + width + 'px !important');
    //    $('#nodes').width(width);
}
/*	buildChart

 Applies the highchart jquery plugin to the published node
 chart element
 */

function buildChart(values, start) {
    $("#published-chart").highcharts({
        chart: {
            type: "area",
            zoomType: "x",
        },
        title: {
            text: "",
        },
        xAxis: {
            type: "datetime",
        },
        yAxis: {
            labels: {
                enabled: false,
            },
            title: {
                text: null,
            },
        },
        legend: {
            enabled: false,
        },
        credits: {
            enabled: false,
        },
        plotOptions: {
            series: {
                fillColor: "#d5d5d5",
                color: "#8AA6C8",
                marker: {
                    enabled: false,
                    states: {
                        hover: {
                            enabled: true,
                        },
                    },
                },
            },
        },
        series: [
            {
                name: "Published",
                data: values,
            },
        ],
    });
}

/*	stickyReLayout

 ReLayout of the sticky header -- nessecary because of
 sidebar collapse
 */

function stickyReLayout() {
    /*	if($("#page").hasClass("page-full")){
     $(".tagContainer").width("90%").css("margin-left", "50px");
     } else {
     $(".tagContainer").width($("#page").outerWidth());
     $(".tagContainer").css("margin-left", "0px");
     }*/
    fixNodeListHeightWidth();
}

/*	isScrolledIntoView

 Helper function to determine when to run ajax
 pagination requests
 */

function isScrolledIntoView(elem) {
    var docViewTop = $(".nodeContainer").scrollTop();
    var docViewBottom = $(".nodeContainer")[0].scrollHeight;

    var docViewHeight = $(".nodeContainer").height();

    var atBottom =
        docViewBottom - docViewTop <= docViewHeight + $(elem).height();

    if ($(elem).offset() == null) {
    } else {
        var elemTop = $(elem).offset().top;
    }

    var elemBottom = elemTop + $(elem).height();

    //return ((elemBottom <= docViewBottom) && (elemTop >= docViewTop));

    return atBottom;
}

/*
 DOCUMENT LOAD ACTIONS:
 */

$(document).ready(function () {
    //LDS Publisher UI fix
    $(".ldse-footer div.ldse-logo").hide();
    $("#night-mode-toggle").remove();
    $(".ldse-modal-backdrop").live("click", function () {
        closeModal();
    });
    modal.append(
        "<div class='ldse-iframe-container'><iframe class='ldse-iframe' src=''></iframe></div>"
    );
    //Build nodes from service
    //populateNodes(nodesToPull, $("#filter-form").serialize());
    /*    Preview.init();*/
    //Apply Datepicker
    var startDate = $("#date-start"),
        endDate = $("#date-end");

    startDate
        .datepicker({
            onSelect: function () {
                endDate.datepicker(
                    "option",
                    "minDate",
                    startDate.datepicker("getDate")
                );
            },
        })
        .change(function () {
            endDate.datepicker(
                "option",
                "minDate",
                startDate.datepicker("getDate")
            );
        });

    endDate
        .datepicker({
            onSelect: function () {
                startDate.datepicker(
                    "option",
                    "maxDate",
                    endDate.datepicker("getDate")
                );
            },
        })
        .change(function () {
            startDate.datepicker(
                "option",
                "maxDate",
                endDate.datepicker("getDate")
            );
        });
    var lang = $("#langSelector").val();
    //Apply Filters Button
    $("#apply-filters").click(function () {
        initialized = false;
        startNode = 0; //reset current node count
        updateTimestamp();
        $("#loadingGif").hide();
        $(".nodeContainer").isotope("destroy");
        if (lang !== "eng") {
            $("#ipevalNode").hide();
        }
        maxNodes = 500;
        //populateNodes(nodesToPull, $("#filter-form").serialize());
        var startDate = $("#date-start").val() || "beginning of time",
            endDate = $("#date-end").val() || "present";
        $(".tagContainer #site").text(
            $("#siteSelector option:selected").text()
        );
        $(".tagContainer #lang").text(
            $("#langSelector option:selected").text()
        );
        $(".tagContainer #fromDate").text(startDate);
        $(".tagContainer #toDate").text(endDate);
    });
    //Reset Filters Button
    $("#reset-filters").click(function () {
        initialized = false;
        startNode = 0; //reset current node count
        updateTimestamp();
        $(".nodeContainer").isotope("destroy");
        maxNodes = 500;
        $("#date-start").val("").change();
        $("#date-end").val("").change();
        $("#statusSelector").val("published").change();
        $("#langSelector").val("").change();
        $("#siteSelector").val("").change();
        $(".filtertags").html("<li>NONE</li>");
        $(".filtertags").fadeIn();
        $(".filtertags").fadeOut(function () {
            $("select").each(function () {
                $(this).val("");
            });
        });
        //populateNodes(nodesToPull, $("#filter-form").serialize());
        $(".tagContainer #site").text("All Sites");
        $(".tagContainer #lang").text("All Locales");
    });

    //Toggle (sidebar) Button
    $("#toggle").click(function () {
        $("nav").toggleClass("page-full");
        $("#page").toggleClass("page-full");
        $("#toggle").toggleClass("in");
        setTimeout(fixNodeListHeightWidth, 1000);
    });

    //Relayout the nodes in Isotope when the container is resized
    document.getElementById("page").addEventListener(
        "webkitTransitionEnd",
        function (event) {
            reLayout();
            stickyReLayout();
        },
        false
    );

    //watch the page nav area for scrolling, stickiness,
    //and infinite scrolling

    //Listen for scroll events to
    // - relayout the sticky header on full/collapsed state
    // - apply sticky behavior when scrolled away from top
    // - load more nodes when the bottom is reached
    var scrollTimer;
    $(".nodeContainer").scroll(function () {
        clearTimeout(scrollTimer);
        setTimeout(function () {
            //stickyReLayout();
            //stickyDistance = $("#ldse-toolbar-container").hasClass("ldse-collapsed") ? 0 : 50;
            //stickySpot = $("#ldse-toolbar-container").hasClass("ldse-collapsed") ? "0px" : "50px";

            //		if($(window).scrollTop() > stickyDistance){
            //			$(".tagContainer")
            //				.css("position","fixed")
            //				.css("top", stickySpot)
            //				.css("z-index","2000")
            //				.css("background", "#f9f9f9")
            //				.css("margin-left", "0")
            //				.width("100%");
            //		} else {
            //			$(".tagContainer")
            //				.css("position","inherit")
            //				.css("top", "");
            //		}

            if (isScrolledIntoView($(".nodeContainer li:last-child"))) {
                if (loading === false) {
                    if (startNode + nodesToPull <= maxNodes) {
                        $("#loadingGif").show();
                        loading = true;
                        startNode += nodesToPull;
                        //populateNodes(nodesToPull, $("#filter-form").serialize());
                    } else if (maxNodes >= 500) {
                        $("#noResults").show();
                    }
                }
            }
        }, 100);
    });

    function loadUntilScroll() {
        if (!$(".nodeContainer").hasScrollBar()) {
            $(".nodeContainer").trigger("scroll");
            setTimeout(loadUntilScroll, 100);
        }
    }
    loadUntilScroll();

    $(".nodeContainer").hasScrollBar();

    //Relayout the header when the page is resized
    $(window).resize(function () {
        stickyReLayout();
    });

    //Back-to-top Button Scrolling
    $("#btnTop, #lnkTop").click(function () {
        $(".nodeContainer").animate({ scrollTop: "0px" });
    });
});
