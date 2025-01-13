var hash = window.location.hash.split("=")[1];
var permalinkValue = {};
var titanInput;

if (typeof ICE === "undefined") {
    /* jQuery Case-Insensitive :containsNC */
    $.extend($.expr[":"], {
        containsNC: function (elem, i, match, array) {
            return (
                (elem.textContent || elem.innerText || "")
                    .toLowerCase()
                    .indexOf((match[3] || "").toLowerCase()) >= 0
            );
        },
    });

    CKEDITOR_BASEPATH =
        location.protocol + cdnPath + "/lds-edit/scripts/ckeditor/";

    var ICE = {
        modal: $("#modal1"),
        ckeditor_loaded: false,
        page: null,
        uri: null,
        carousel: true /* Current status of rotating carousels */,
        formVars: "" /* SET when form opens */,
        actions: {
            "ldse:publish": "Preview",
            "ldse:unpublish": "Unpublish",
            "ldse:remove": "Remove",
            "ldse:delete": "Delete",
        },
        post: function (path, params, method) {
            method = method || "post";
            var form = $("<form/>"),
                hiddenField;
            if (
                params &&
                params.id &&
                params.id != "" &&
                path.indexOf("/form") != -1 &&
                path.indexOf("&id=") == -1
            ) {
                path += "&id=" + params.id;
                delete params.id;
            }
            form.attr("method", method).attr("action", path).hide();
            for (var key in params) {
                if ($.isArray(params[key])) {
                    for (var i = 0; i < params[key].length; i++) {
                        hiddenField = $("<input/>");
                        hiddenField
                            .attr("type", "hidden")
                            .attr("name", key)
                            .attr("value", params[key][i]);
                        form.append(hiddenField);
                    }
                } else {
                    hiddenField = $("<input/>");
                    hiddenField
                        .attr("type", "hidden")
                        .attr("name", key)
                        .attr("value", params[key]);
                    form.append(hiddenField);
                }
            }
            $("body").append(form);
            form.submit();
            return false;
        },
        postLink: function (link) {
            link = $(link);
            var data = link.data();
            var postData = {};
            for (key in data) {
                if (data.hasOwnProperty(key) && key.indexOf("post.") == 0) {
                    postData[key.replace(/post\./, "")] = data[key];
                }
            }
            ICE.post(link.attr("href"), postData);
            return false;
        },
        openForm: function (locale, id, action, form, uri, page, options) {
            if ($(".ldseForm").length > 0) {
                $(".ldseForm").remove();
            }
            $('<div class="ldseForm"></div>').appendTo("body");
            this.uri = uri;
            this.page = page != undefined ? page : uri;
            $.ajax({
                type: "POST",
                url: sharedPrefix + "/ice/form?" + ICE.langParam(locale),
                data: {
                    id: id,
                    page: this.page,
                    uri: uri,
                    action: action,
                    option: options,
                    ixf: true,
                    site: getUrlParameter("site"),
                },
                success: function (html) {
                    $(".ldseForm")
                        .html(html)
                        .dialog({
                            position: [$(window).width() / 2 - 910 / 2, 150],
                            dialogClass: "ldseForm ldse-modal",
                            height: "auto",
                            width: 910,
                            zIndex: 4000,
                            draggable: true,
                            modal: true,
                            title: $(".ldseForm #ice-dialog").attr("title"),
                            beforeClose: function () {
                                //ICE.destoryCKEditor();
                            },
                            close: function () {
                                $(".ldseForm").remove().dialog("close");
                            },
                            open: function () {
                                ICE.fixCKEditors();
                                $(".confirm").click(function () {
                                    if (
                                        $("#status").attr("value") == "delete"
                                    ) {
                                        $(this).removeClass("confirm");
                                        return confirm(
                                            "This article will be permanently deleted, are you sure you want to continue?"
                                        );
                                    }
                                });
                            },
                        });
                },
            });
        },
        createComponent: function (link) {
            var uri = $(link).data("post.uri"),
                options = $(link).data("post.option"),
                country = $(link).data("post.country"),
                type = $(link).data("post.content-type"),
                located = $(link).data("post.location");
            parent = $(link).data("post.parent-id");
            if ($(".ldseForm").length > 0) {
                $(".ldseForm").remove();
            }
            $('<div class="ldseForm ldse-page"></div>').appendTo("body");
            $(".actionImage").append("creating");
            ICE.buildComponentModal(type);
            $.ajax({
                type: "POST",
                url:
                    sharedPrefix +
                    "/ice/resources/ajax/component/create?" +
                    ICE.langParam(locale),
                data: {
                    uri: uri,
                    locale: locale,
                    option: options,
                    country: country,
                    type: type,
                    location: located,
                    parentId: parent,
                },
                success: function (data) {
                    $(".actionImage").html(
                        '<span class="ldse-publish-dialog ldse-icon-check2"></span><div id="status_teaser" class="publishStatus">Created Component</div>'
                    );
                },
                error: function (data) {
                    $(".actionImage").html(
                        '<span class="ldse-publish-dialog ldse-icon-ko-warning"></span><div id="status_teaser" class="publishStatus">Error Creating Component</div>'
                    );
                },
            });
        },
        buildComponentModal: function (type) {
            "use strict";
            ACT.TRIES = {};
            var div = $(
                '<div class="actionModal ldseForm"><link rel="stylesheet" media="screen" type="text/css" href="' +
                    sharedPrefix +
                    '/ice/resources/styles/screen.css"/></div>'
            );
            if (type) {
                div.append(
                    $(
                        '<div class="ldse-clearfix">' +
                            '<div class="actionLabel">' +
                            type +
                            ": </div>" +
                            '<div id="image_' +
                            type +
                            '" class="actionImage">' +
                            '<span class="ui-finder-loader">&nbsp;</span><div id="status_' +
                            type +
                            '" class="actionStatus"/>' +
                            "</div>" +
                            "</div>" +
                            "</div>"
                    )
                );
            }
            // Close button
            div.append(
                $('<div class="actionClose">').append(
                    $('<button id="" class="ldse-button">Close</button>').click(
                        function () {
                            $(".actionItems").remove().dialog("close");
                            if (ICE.teaserManagerActive === false) {
                                if (ACT.RELOAD !== "") {
                                    location = ACT.RELOAD;
                                } else {
                                    location.reload();
                                }
                            } else {
                                $(".actionModal").remove().dialog("close");
                            }
                        }
                    )
                )
            );
            $(".actionModal").remove().dialog("close");
            div.dialog({
                position: [$(window).width() / 2 - 500 / 2, 150],
                dialogClass: "ldseForm ldse-modal",
                height: "auto",
                width: 500,
                zIndex: 4000,
                draggable: true,
                modal: true,
                title: "Creating Component",
                close: function () {
                    $(".actionModal").remove().dialog("close");
                },
            });
        },
        setupForm: function () {
            ICE.loadDatePickers();
            ICE.addSortable();
            ICE.fixSelects();
            ICE.addOnClicks();
            ICE.addDynamicFormItem();
            if ($.validator) {
                $.validator.setDefaults({
                    onfocusout: function (element) {
                        $(element).valid();
                        $(":input.valid + label.error").remove();
                    },
                    ignore: ":hidden",
                    ignoreTitle: true,
                    success: function () {
                        var inputs = $(":input.error"),
                            first = inputs.first();
                        if (inputs.length > 0) {
                            inputs.each(function () {
                                var input = $(this),
                                    group = input.closest(".ldse-group");
                                if (group.hasClass("closed")) {
                                    group
                                        .removeClass("closed")
                                        .find(".ldse-section--body")
                                        .show();
                                }
                            });
                            setTimeout(function () {
                                if ($(first.closest(":visible")).length > 0) {
                                    $("html,body").scrollTop(
                                        first.closest(":visible").offset().top -
                                            150
                                    );
                                }
                            }, 10000);
                        }
                        $(":input.valid + label.error").remove();
                    },
                });
                $.validator.addMethod(
                    "titan-asset",
                    function (value, element) {
                        var isValid = true;
                        if (value.length > 0) {
                            var titanAsset = $(element);
                            var titanType = $(titanAsset).attr("data-type");
                            var span = $(titanAsset)
                                .closest("dl")
                                .find("dd>span");
                            var titanInputName = $(titanAsset).attr("name");
                            var titanHiddenAsset = $(titanAsset)
                                .closest("dl")
                                .find(
                                    "dd>input[name=" + titanInputName + "]"
                                )[1];
                            if (
                                $(titanAsset).val().length > 0 &&
                                titanType !== "image"
                            ) {
                                if (
                                    $(titanHiddenAsset).val() !== $(span).text()
                                ) {
                                    $(titanHiddenAsset).attr(
                                        "value",
                                        $(span).text()
                                    );
                                }
                            }
                            if ($(titanAsset).hasClass("invalid-titan-id")) {
                                isValid = isValid && false;
                            }
                        }
                        return isValid;
                    },
                    "Invalid ID."
                );
            }
            if ($("form.ldse-form .required").length > 0) {
                $("form.ldse-form").validate({
                    onfocusout: function (element) {
                        $(element).valid();
                    },
                });
            }
            ICE.addCKEditor();
            ICE.minEvaluate();
            $(".iceForm form").submit(function () {
                ICE.updateCKEditors();
                return true;
            });

            //Add any dynamically created children.
            if (childID && newDynamic == "true") {
                //Check the list before adding.
                var ids = [];
                var list = $("li.repeated-item")
                    .find("h3")
                    .each(function () {
                        var a = $(this).children("a").attr("data-id");
                        ids.push(a);
                    });
                if (ids.indexOf(childID) == -1) {
                    $.ajax({
                        type: "POST",
                        dataType: "json",
                        url:
                            sharedPrefix +
                            "/ice/resources/ajax/get-content?lang=" +
                            ICE.formVars.lang,
                        data: {
                            id: childID,
                        },
                        success: function (data) {
                            var newData = null;
                            data.some(function (ele, idx, arr) {
                                var mainData = ele.ldswebml;
                                if (mainData.id === childID) {
                                    newData = mainData;
                                    return true;
                                } else {
                                    return false;
                                }
                            });
                            if (newData) {
                                data = newData;

                                //Find the home for this child
                                var allDynamicContainers = $("ul.sortable")
                                    .parent()
                                    .siblings("dt")
                                    .children("label");
                                var filteredContainer =
                                    allDynamicContainers.filter(function () {
                                        var title = $(this)[0].innerHTML;
                                        return title.includes(
                                            "Component:" + data.type
                                        );
                                    });

                                var buttonObj = $(
                                    $(
                                        "a[data-childcount][class*='ldse-button']"
                                    )[0]
                                );
                                if (filteredContainer.length)
                                    buttonObj = $(
                                        $(filteredContainer[0])
                                            .parent()
                                            .siblings("dd")
                                            .children("a[data-childcount]")[0]
                                    );

                                var newItem = buttonObj.data("item");
                                var childIndex =
                                    parseInt(buttonObj.data("childcount")) + 1;
                                buttonObj.data("childcount", childIndex);
                                newItem = newItem.replace(
                                    /INDEXHERE/g,
                                    childIndex
                                );
                                buttonObj.siblings("ul").append(newItem);
                                var newItem = buttonObj
                                    .siblings("ul")
                                    .find("li")
                                    .last();
                                var itemName =
                                    data["doc-title"]["_value"] ||
                                    data["doc-title"] ||
                                    data.id;
                                var newEditLink =
                                    '<h3><a href="#d" class="editFormItem" data-id=' +
                                    data.id +
                                    " data-form=" +
                                    data["component-title"] +
                                    ">" +
                                    itemName +
                                    "</a></h3>";
                                newItem.find("h3").replaceWith(newEditLink);
                                newItem.find("fieldset input").val(data.id);
                                ICE.addOnClicks();
                                ICE.addCKEditor(newItem);
                                ICE.fixSelects();
                                ICE.loadDatePickers();
                                if ($("form.ldse-form .required").length > 0) {
                                    $("form.ldse-form").validate({
                                        onfocusout: function (element) {
                                            $(element).valid();
                                        },
                                    });
                                }
                            }
                        },
                    });
                }
            }
        },
        minEvaluate: function () {
            var minValue = $("ul.sortable").data("min");
            if (minValue && minValue !== undefined) {
                for (var i = 0; i >= minValue; i++) {
                    ICE.alertText("Test", "This is a test", function () {
                        window.close();
                    });
                    $("ul.sortable").closest("dd").find("a.ldse-add").click();
                }
            } else {
            }
        },
        addCKEditor: function (newItem) {
            // Only load a new ckeditor instance if the ckeditor has already run its on load functions.
            if (typeof CKEDITOR !== "undefined") {
                var $editors = $(".iceForm textarea.ckeditor");
                if (newItem != null) {
                    $editors = $(newItem).find(".ckeditor");
                }
                if ($editors.length) {
                    $editors.each(function () {
                        var editorID = $(this).attr("id");
                        var instance = CKEDITOR.instances[editorID];
                        if (instance) {
                            try {
                                if (instance.getData() !== "") {
                                    instance.updateElement();
                                }
                            } catch (e) {}
                            instance.destroy(true);
                        }
                        CKEDITOR.replace(this);
                    });
                }
            }
        },
        alertText: function (title, text, onOk, options) {
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
                    '">' +
                    options.okText +
                    "</button>" +
                    '<button id="alert-cancel" class="ldse-button ' +
                    options.cancelClass +
                    ' float-right">' +
                    options.cancelText +
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
        },
        fixCKEditors: function () {
            var $editors = $(".iceForm textarea.ckeditor");
            $editors.each(function () {
                var editorID = $(this).attr("id");
                var instance = CKEDITOR.instances[editorID];
                try {
                    instance.updateElement();
                    instance.setMode("wysiwyg");
                    //instance.execCommand( 'source' );
                } catch (e) {}
            });
        },
        updateCKEditors: function () {
            for (var instanceName in CKEDITOR.instances)
                CKEDITOR.instances[instanceName].updateElement();
        },
        addListItem: function (button) {
            if (
                button.classList.contains("top") ||
                button.classList.contains("bottom")
            ) {
                let index = $(button).closest("li").index();
                index = button.classList.contains("top") ? index : index + 1;
                this.createListItem(button, index);
            } else {
                this.createListItem(
                    button,
                    $(button)
                        .closest(".ldse-section--body")
                        .children("ul")
                        .children().length
                );
            }
        },
        createListItem: function (button, index) {
            let inputType = $(button.closest("dl.ldse-section")).find(
                ".ldse-dynamic-input-types"
            )[0];
            let newItem = inputType
                ? $(button).data(inputType.value)
                : $(button)
                      .closest(".ldse-section--body")
                      .find("> .addToContainer a")
                      .first()
                      .data("item");
            let hash = $(button)
                .closest(".ldse-section--body")
                .find("> .addToContainer a")
                .first()
                .data("hash");
            let childIndex =
                parseInt(
                    $(button)
                        .closest(".ldse-section--body")
                        .find("> .addToContainer a")
                        .first()
                        .data("childcount")
                ) + 1;
            let max = $(button)
                .closest(".ldse-section--body")
                .find("> ul:first")
                .data("max");
            let liCount = $(button)
                .closest(".ldse-section--body")
                .find("> ul")
                .children("li").length;
            let regex = new RegExp(hash, "g");
            let otherAddButtons = $(button)
                .closest(".ldse-section--body")
                .find("> .addToContainer .ldse-add");
            if (max) {
                if (liCount < max) {
                    $(button).data("childcount", childIndex);
                    newItem = newItem.replace(regex, childIndex);
                    otherAddButtons.each((i, other) => {
                        $(other).data("childcount", childIndex);
                    });
                    if (liCount == index) {
                        $(button)
                            .closest(".ldse-section--body")
                            .find("> ul")
                            .append(newItem);
                    } else if (index == 0) {
                        $(button)
                            .closest(".ldse-section--body")
                            .find("> ul")
                            .prepend(newItem);
                    } else {
                        $(button)
                            .closest(".ldse-section--body")
                            .find(`> ul > li:eq(${index})`)
                            .before(newItem);
                    }
                    newItem = $(button)
                        .closest(".ldse-section--body")
                        .find(`> ul > li:eq(${index})`);
                    ICE.addOnClicks();
                    ICE.addCKEditor(newItem);
                    ICE.fixSelects(newItem);
                    ICE.loadDatePickers();
                    $(newItem).microMixin();
                    if ($(".required", newItem).length > 0) {
                        newItem.closest("form").validate({
                            onfocusout: function (element) {
                                $(element).valid();
                            },
                        });
                    }
                    $("#newIndex").attr("max", liCount + 1);
                } else {
                    alert(
                        "Error this is the max number you can add",
                        function () {
                            window.close();
                        }
                    );
                }
            } else {
                $(button).data("childcount", childIndex);
                newItem = newItem.replace(regex, childIndex);
                otherAddButtons.each((i, other) => {
                    $(other).data("childcount", childIndex);
                });
                if (liCount == index) {
                    $(button)
                        .closest(".ldse-section--body")
                        .find("> ul")
                        .append(newItem);
                } else if (index == 0) {
                    $(button)
                        .closest(".ldse-section--body")
                        .find("> ul")
                        .prepend(newItem);
                } else {
                    $(button)
                        .closest(".ldse-section--body")
                        .find(`> ul > li:eq(${index})`)
                        .before(newItem);
                }
                newItem = $(button)
                    .closest(".ldse-section--body")
                    .find(`> ul > li:eq(${index})`);
                ICE.addOnClicks();
                ICE.addCKEditor(newItem);
                ICE.fixSelects(newItem);
                ICE.loadDatePickers();
                $(newItem).microMixin();
                if ($(".required", newItem).length > 0) {
                    newItem.closest("form").validate({
                        onfocusout: function (element) {
                            $(element).valid();
                        },
                    });
                }
                $("#newIndex").attr("max", liCount + 1);
            }
            newItem.children("fieldset")[0].querySelector("input").focus();
        },
        editFormItemNew: function (button) {
            var buttonObj = $(button);
            var itemId = buttonObj.data("id");
            var newParentID = ICE.formVars.id;
            if (parentID) {
                if (typeof parentID === "string") {
                    newParentID = parentID + "_" + newParentID;
                } else {
                    newParentID = parentID.join("_") + "_" + newParentID;
                }
            }
            var url =
                sharedPrefix +
                "/form?" +
                ICE.langParam(locale) +
                "&id=" +
                itemId +
                "&parentID=" +
                newParentID +
                "&site=" +
                getUrlParameter("site");
            if (hasChanges($("form.form-data")) || !ICE.formVars.id) {
                promptChanges(url, true);
            } else {
                ICE.post(url, { pubHubReferer: pubHubReferer });
            }
        },
        editFormItem: function (button) {
            var buttonObj = $(button);
            var modal = $("#modal1").trigger("close");
            modal.addClass("large");
            var formName = buttonObj.data("form");
            var itemId = buttonObj.data("id");
            var itemOptions = buttonObj.data("options");
            $.ajax({
                type: "POST",
                url: sharedPrefix + "/ice/form?" + ICE.langParam(locale),
                data: {
                    id: itemId,
                    uri: ICE.uri,
                    page: ICE.page,
                    action: "edit",
                    option: itemOptions,
                    site: getUrlParameter("site"),
                },
                success: function (html) {
                    modal.html(html).trigger("open");
                    $("#ldse-toolbar-buttons").hide();
                    var inlineDiv = modal.find(".ldse-form:first");
                    $("html,body").scrollTop(modal.offset().top - 100);
                    ICE.addOnClicks();
                    ICE.fixSelects();
                    ICE.loadDatePickers();
                    ICE.addCKEditor(modal);
                    var inlineForm = modal.find("form");
                    $(inlineForm).microMixin();
                    // Setup the ajaxForm submit
                    var options = {
                        data: {
                            ajax: "true",
                        },
                        dataType: "json",
                        beforeSerialize: function () {
                            ICE.updateCKEditors();
                            if (
                                !(
                                    $("#modal1 form").valid() &&
                                    validateWysiwyg("#modal1 form")
                                )
                            ) {
                                return false;
                            }
                        },
                        success: function (data, statusText, xhr, $form) {
                            $("#ldse-toolbar-buttons").show();
                            ICE.destoryCKEditor(modal);
                            $(inlineDiv).remove();
                            buttonObj.text(data.title);
                            ICE.addOnClicks();
                            ICE.fixSelects();
                            ICE.loadDatePickers();
                            if ($("form.ldse-form .required").length > 0) {
                                $("form.ldse-form").validate({
                                    onfocusout: function (element) {
                                        $(element).valid();
                                    },
                                });
                            }
                            $(".iceForm.ui-dialog-content > div").show();
                            $("#modal1").trigger("close");
                            $("#modal1").find("div").remove();
                            $("html,body").scrollTop(
                                buttonObj.offset().top - 150
                            );
                            var count = buttonObj.siblings("ul").length;
                            if (count >= max) {
                                $(buttonObj).parent().find("a").hide();
                            }
                        },
                    };
                    inlineForm.ajaxForm(options);
                    if ($(".required", modal).length > 0) {
                        $("form.ldse-form", modal).validate({
                            onfocusout: function (element) {
                                $(element).valid();
                            },
                        });
                    }

                    var cancelBtn = $(inlineForm).find(
                        'input[type="button"].cancel'
                    );
                    // Remove other click events from the Cancel button so it won't close the previous form
                    cancelBtn.unbind("click");
                    // Add a new click event to the Cancel button so it will close the current form and show the previous one
                    cancelBtn.bind("click", function (evt) {
                        $("#ldse-toolbar-buttons").show();
                        ICE.destoryCKEditor(modal);
                        $(inlineDiv).remove();
                        $("#modal1").trigger("close").removeClass("large");
                        ICE.addOnClicks();
                        ICE.fixSelects();
                        ICE.loadDatePickers();
                        if ($("form.ldse-form .required").length > 0) {
                            $("form.ldse-form").validate({
                                onfocusout: function (element) {
                                    $(element).valid();
                                },
                            });
                        }
                        $("html,body").scrollTop(buttonObj.offset().top - 150);
                        return false;
                    });
                },
            });
        },
        addDynamicFormItem: function () {
            $(document).ready(function () {
                if ($(".dynamicFormsSelect").length) {
                    $(".dynamicFormsSelect").on("change", function () {
                        var formName = $(this).val();
                        var parent = $(this).parentsUntil("dl");
                        var addButton = parent.find("a.ldse-icon-search");
                        var newButton = parent.find("a.ldse-icon-ko-add");

                        var regex = /data-options="(.*?)"/;
                        var siteParam = getUrlParameter("site");
                        var siteOption = "";
                        if (
                            null != siteParam &&
                            "" != siteParam &&
                            undefined != siteParam
                        ) {
                            siteOption =
                                "%2Csite-context%3A" + getUrlParameter("site");
                        }
                        var str = newButton
                            .attr("data-item")
                            .replace(
                                regex,
                                'data-options="form%3A' +
                                    formName +
                                    siteOption +
                                    '"'
                            );
                        newButton.data("item", str);
                        addButton.data("form", formName);
                    });
                }
            });
        },
        addFormItem: function (button) {
            var parser = new DOMParser(),
                buttonObj = $(button),
                formItem = parser.parseFromString(
                    buttonObj.data("item"),
                    "text/html"
                ),
                elements = formItem.firstChild,
                dataItems = $(elements).find("a.editFormItem").data("options"),
                modal = $("#modal1").trigger("close"),
                max = $(button).data("max");
            modal.addClass("large");
            $.ajax({
                type: "POST",
                url: sharedPrefix + "/ice/form?" + ICE.langParam(locale),
                data: {
                    id: "new",
                    uri: ICE.uri,
                    page: ICE.page,
                    action: "add",
                    option: dataItems,
                    site: getUrlParameter("site"),
                },
                success: function (html) {
                    $("#ldse-toolbar-buttons").hide();
                    modal.html(html).trigger("open");
                    var inlineDiv = modal.find(".ldse-form:first");
                    $("html,body").scrollTop(modal.offset().top - 100);
                    ICE.addOnClicks();
                    ICE.fixSelects();
                    ICE.loadDatePickers();
                    ICE.addCKEditor(modal);

                    var inlineForm = modal.find("form");
                    $(inlineForm).microMixin();
                    // Setup the ajaxForm submit
                    var options = {
                        data: {
                            ajax: "true",
                        },
                        dataType: "json",
                        beforeSerialize: function () {
                            ICE.updateCKEditors();
                            if (
                                !(
                                    $("#modal1 form").valid() &&
                                    validateWysiwyg("#modal1 form")
                                )
                            ) {
                                return false;
                            }
                        },
                        success: function (data, statusText, xhr, $form) {
                            $("#ldse-toolbar-buttons").show();
                            ICE.destoryCKEditor(modal);
                            $(inlineDiv).remove();
                            var newItem = buttonObj.data("item");
                            var childIndex =
                                parseInt(buttonObj.data("childcount")) + 1;
                            buttonObj.data("childcount", childIndex);
                            newItem = newItem.replace(/INDEXHERE/g, childIndex);
                            buttonObj.siblings("ul").append(newItem);
                            var newItem = buttonObj
                                .siblings("ul")
                                .find("li")
                                .last();
                            var title = "";
                            if (data.title) {
                                title = data.title;
                            } else if (data.search) {
                                title = data.search;
                            } else {
                                title = data.id;
                            }
                            var newEditLink =
                                '<h3><a href="#d" class="editFormItem" data-id=' +
                                data.id +
                                " data-form=" +
                                formName +
                                " data-options=" +
                                dataItems +
                                ">" +
                                title +
                                "</a></h3>";
                            newItem.find("h3").replaceWith(newEditLink);
                            newItem.find("fieldset input").val(data.id);
                            ICE.addOnClicks();
                            ICE.addCKEditor(newItem);
                            ICE.fixSelects();
                            ICE.loadDatePickers();
                            if ($("form.ldse-form .required").length > 0) {
                                $("form.ldse-form").validate({
                                    onfocusout: function (element) {
                                        $(element).valid();
                                    },
                                });
                            }
                            $("#modal1").trigger("close");
                            $("html,body").scrollTop(
                                buttonObj.offset().top - 150
                            );
                            ICE.coripCanPublish();
                            var count = buttonObj.siblings("ul").length;
                            if (count >= max) {
                                $(buttonObj).parent().find("a").hide();
                            }
                        },
                    };
                    inlineForm.ajaxForm(options);

                    if ($(".required", modal).length > 0) {
                        $("form.ldse-form", modal).validate({
                            onfocusout: function (element) {
                                $(element).valid();
                            },
                        });
                    }

                    var cancelBtn = $(inlineForm).find(
                        'input[type="button"].cancel'
                    );
                    // Remove other click events from the Cancel button so it won't close the previous form
                    cancelBtn.unbind("click");
                    // Add a new click event to the Cancel button so it will close the current form and show the previous one
                    cancelBtn.bind("click", function (evt) {
                        $("#ldse-toolbar-buttons").show();
                        ICE.destoryCKEditor(modal);
                        $(inlineDiv).remove();
                        $("#modal1").trigger("close").removeClass("large");
                        ICE.addOnClicks();
                        ICE.fixSelects();
                        ICE.loadDatePickers();
                        if ($("form.ldse-form .required").length > 0) {
                            $("form.ldse-form").validate({
                                onfocusout: function (element) {
                                    $(element).valid();
                                },
                            });
                        }
                        $("html,body").scrollTop(buttonObj.offset().top - 150);
                        return false;
                    });
                },
            });
        },
        addFormItemNew: function (button) {
            var parser = new DOMParser(),
                buttonObj = $(button),
                formItem = parser.parseFromString(
                    buttonObj.data("item"),
                    "text/html"
                ),
                elements = formItem.firstChild,
                dataItems = $(elements).find("a.editFormItem").data("options"),
                max = $(button).closest("dl").find("ul:first").data("max"),
                liCount = $(button)
                    .closest("dl")
                    .children("dd")
                    .children("ul")
                    .children("li")
                    .filter(function () {
                        return $(this).html();
                    }).length;

            if (max && max <= liCount) {
                alert("Error this is the max number you can add", function () {
                    window.close();
                });
            } else {
                var newParentID = ICE.formVars.id;
                if (parentID) {
                    if (typeof parentID === "string") {
                        newParentID = parentID + "_" + newParentID;
                    } else {
                        newParentID = parentID.join("_") + "_" + newParentID;
                    }
                }

                var url =
                    sharedPrefix +
                    "/form?" +
                    ICE.langParam(locale) +
                    "&option=" +
                    dataItems +
                    "&uri=" +
                    ICE.uri +
                    "&parentID=" +
                    newParentID +
                    "&site=" +
                    getUrlParameter("site");
                if (hasChanges($("form.form-data")) || !ICE.formVars.id) {
                    promptChanges(url, true);
                } else {
                    ICE.post(url, { pubHubReferer: pubHubReferer });
                }
            }
        },
        coripCanPublish: function () {
            $(".correlation-not-approved-new").each(function () {
                var $this = $(this);
                $this
                    .removeClass("correlation-not-approved-new")
                    .addClass("correlation-not-approved");
                var $li = $this.closest("li");
                var $fieldset = $li.find("fieldset");
                var $dd = $fieldset.find("dd");
                var $input = $dd.find("input[type='hidden']");
                var id = $input.val();
                $.ajax({
                    url:
                        sharedPrefix +
                        "/ice/resources/ajax/ice-can-publish?" +
                        ICE.langParam(locale),
                    data: {
                        id: id,
                    },
                    success: function (response) {
                        if (response == "false") {
                            $this.show();
                        }
                    },
                });
            });
        },
        searchFormItem: function (button) {
            var searchItem = $(button).data("item");
            (modal = $("#modal1").trigger("close").addClass("large")),
                (formName = $(button).data("form")),
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
                alert(
                    "Error " + max + " is the max number you can add",
                    function () {
                        window.close();
                    }
                );
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
                            $(this)
                                .closest("li")
                                .find(".ldse-block--body")
                                .toggle(0);
                            $(this).closest("section").toggleClass("ldse-open");
                        }
                    );
                    $("#modal1").on("click", ".addFromSearch", function () {
                        var buttonObj = $(button).prev(); // mising ; produces other behavior?
                        var newItem = buttonObj.data("item");
                        var childIndex =
                            parseInt(buttonObj.data("childcount")) + 1;
                        buttonObj.data("childcount", childIndex);
                        newItem = newItem.replace(/INDEXHERE/g, childIndex);
                        buttonObj.siblings("ul").append(newItem);
                        ICE.fixedWidth(
                            buttonObj
                                .siblings("ul")
                                .find("li > dl > dt > label")
                        );
                        //ICE.setupForm();
                        var newItem = buttonObj
                            .siblings("ul")
                            .find("li")
                            .last();
                        var newItemText = $(this).data("title");
                        var newItemId = $(this).data("id");
                        var newEditLink =
                            '<h3><a href="#d" class="editFormItem" data-id=' +
                            newItemId +
                            " data-form=" +
                            formName +
                            " data-options=" +
                            "form:" +
                            formName +
                            ">" +
                            newItemText +
                            "</a></h3>";
                        newItem.find("h3").replaceWith(newEditLink);
                        newItem.find("fieldset input").val(newItemId);
                        if (!$(button).hasClass("clone-requested")) {
                            newItem
                                .find("fieldset input")
                                .attr("id", newItemId);
                        }
                        if ($(button).hasClass("clone-requested")) {
                            // Cloning is a combination of AJAX Create New and Edit, but without user interaction.
                            var itemOptions = escape(
                                newItem
                                    .find("a.editFormItem")
                                    .data("options")
                                    .concat(
                                        ",",
                                        "site-context:",
                                        ICE.formVars["site-context"]
                                    )
                            );
                            // Functionality similar to Edit
                            $.ajax({
                                type: "POST",
                                url:
                                    sharedPrefix +
                                    "/ice/form?" +
                                    ICE.langParam(locale),
                                data: {
                                    clone: "true",
                                    id: newItemId,
                                    uri: ICE.uri,
                                    page: ICE.page,
                                    action: "edit",
                                    option: itemOptions,
                                    site: getUrlParameter("site"),
                                },
                                success: function (html) {
                                    // Temporary Modal for cloning a form item
                                    $("#modal1").before(
                                        '<section id="clone-form-item" />'
                                    );
                                    // Functionality similar to Create New
                                    var cloneModal = $("#clone-form-item");
                                    cloneModal.html(html);
                                    ICE.addCKEditor(cloneModal);
                                    var inlineForm = cloneModal.find("form");
                                    // Setup the ajaxForm submit

                                    var options = {
                                        data: {
                                            ajax: "true",
                                            cloneFromId: newItemId,
                                        },
                                        dataType: "json",
                                        beforeSerialize: function () {
                                            ICE.updateCKEditors();
                                        },
                                        success: function (
                                            data,
                                            statusText,
                                            xhr,
                                            $form
                                        ) {
                                            ICE.destoryCKEditor(cloneModal);
                                            // Functionality for Edit after clone if requested
                                            newItem
                                                .find("fieldset input")
                                                .val(data.id);
                                            newItem
                                                .find("fieldset a")
                                                .attr("data-id", data.id);
                                            var dataOptions = escape(
                                                newItem
                                                    .find("fieldset a")
                                                    .data("options")
                                                    .concat(
                                                        ",",
                                                        "site-context:",
                                                        ICE.formVars[
                                                            "site-context"
                                                        ]
                                                    )
                                            );
                                            newItem
                                                .find("fieldset a")
                                                .attr(
                                                    "data-options",
                                                    dataOptions
                                                );
                                            newItem
                                                .find("fieldset a")
                                                .data("options", dataOptions);
                                            // Temporary Modal is gone
                                            $("#clone-form-item").remove();
                                        },
                                    };
                                    inlineForm.ajaxSubmit(options);
                                },
                            });
                        }

                        ICE.addOnClicks();
                        ICE.addCKEditor(newItem);
                        ICE.fixSelects();
                        ICE.loadDatePickers();
                        if (
                            $("li.repeated-item").length >=
                            $(".add-existing-button").attr("data-max")
                        ) {
                            $("button.addFromSearch").hide();
                            button.parentElement.querySelector(
                                "a.ldse-icon-ko-add"
                            ).style.display = "none";
                            button.parentElement.querySelector(
                                "a.add-existing-button"
                            ).style.display = "none";
                        }
                        if ($("form.ldse-form .required").length > 0) {
                            $("form.ldse-form").validate({
                                onfocusout: function (element) {
                                    $(element).valid();
                                },
                            });
                        }

                        // $(this).parent().remove();
                        $(this).hide();
                        ICE.coripCanPublish();
                    });
                    $("#modal1").on(
                        "click",
                        "#ldse-collection-modal-done",
                        function () {
                            /* remove listeners */
                            $("#modal1").off(
                                "click",
                                "#ldse-collection-modal-done"
                            );
                            $("#modal1").off("click", ".addFromSearch");
                            $("#modal1").off(
                                "click",
                                "ul.collection-modal-list li header a"
                            );

                            $("#inline-" + formName + "-search")
                                .siblings()
                                .remove();
                            $("#inline-" + formName + "-search").remove();
                            var modal = $("#modal1")
                                .trigger("close")
                                .removeClass("large");
                            $(".iceForm > div").show();
                            ICE.fixSelects();
                        }
                    );
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
                        site: $("#site").val(),
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
                                    searchContainer.html(
                                        seaTemplate(json.results)
                                    );
                                } else {
                                    $(".search-results").html(
                                        "There are no results"
                                    );
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
        },
        addOnClicks: function () {
            $(".iceForm .deleteListItem")
                .click(function (e) {
                    e.preventDefault();
                    ICE.deleteListItem(this);
                })
                .removeClass("deleteListItem");
            $(".iceForm .addListItem")
                .click(function (e) {
                    e.preventDefault();
                    ICE.addListItem(this);
                })
                .removeClass("addListItem");
            $(".iceForm .editFormItem")
                .click(function () {
                    if (newDynamic == "true") {
                        ICE.editFormItemNew(this);
                    } else {
                        ICE.editFormItem(this);
                    }
                })
                .removeClass("editFormItem");
            $(".iceForm .addFormItem")
                .click(function () {
                    if (newDynamic == "true") {
                        ICE.addFormItemNew(this);
                    } else {
                        ICE.addFormItem(this);
                    }
                })
                .removeClass("addFormItem");
            $(".searchFormItem")
                .click(function () {
                    var result = ICE.searchFormItem(this);
                    if (result) {
                        var modal = $("#modal1");
                        modal.trigger("open");
                        $(document).keydown(function (event) {
                            // Close the modal if the user clicks `esc`
                            if (event.keyCode == 27) {
                                modal.trigger("close");
                            }
                        });
                        $("html,body").scrollTop(
                            $("#inline-image-search").offset()
                        );
                    }
                })
                .removeClass("searchFormItem");
            $(".iceForm .titanFormItem").click(function () {
                titanInput = this;
                var modal = $("#titanModal");
                modal.trigger("open");
                $(document).keydown(function (event) {
                    // Close the modal if the user clicks `esc`
                    if (event.keyCode == 27) {
                        modal.trigger("close");
                    }
                });
                $("html,body").scrollTop($("#inline-image-search").offset());
            });
            $(".iceForm .titan-type").on("change", function () {
                var val = $(".titan-type-select").val();
                this.parentElement
                    .getElementsByClassName("titanFormItem")[0]
                    .setAttribute("data-type", val);
            });
            $(".iceForm .closeForm")
                .click(function () {
                    ICE.closeForm();
                })
                .removeClass("closeForm");
            $(".iceForm .binary-manager")
                .click(function (e) {
                    e.preventDefault();
                    ICE.binaryManger(this);
                    return false;
                })
                .removeClass("binary-manager");

            hideIfSubcomponents();
        },
        addSortable: function () {
            $(".sortable").each(function () {
                $(this).sortable({
                    start: function (event, ui) {
                        ICE.fixCKEditors();
                    },
                    stop: function (event, ui) {
                        ICE.addCKEditor($(this));
                    },
                    create: function (event, ui) {
                        ICE.fixedWidth($(this).find("li > dl > dt > label"));
                    },
                });
            });
            $("ul.sortable")
                .find("li.repeated-item")
                .find("ul")
                .each(function () {
                    $(this).sortable({
                        start: function (event, ui) {
                            ICE.fixCKEditors();
                        },
                        stop: function (event, ui) {
                            ICE.addCKEditor($(this));
                        },
                        create: function (event, ui) {
                            ICE.fixedWidth(
                                $(this).find("li > dl > dt > label")
                            );
                        },
                    });
                });
            hideIfSubcomponents();
        },
        closeForm: function () {
            $(".iceForm").dialog("close");
            ICE.addedCkEditor = false;
            //$('.iceForm').dialog( "destroy" );
            //$('.iceForm').remove();
        },
        deleteListItem: function (child) {
            var min = $(child).closest("ul").data("min"),
                liCount = $(child).closest("ul").find("li").length,
                tagUsed =
                    child.parentElement.parentElement.parentElement.getAttribute(
                        "has-tags"
                    ),
                max = $(child).closest("ul").data("max"),
                parent = $(child).closest(".ldse-section"),
                lis = $(child.parentElement.parentElement.parentElement).find(
                    "li.repeated-item"
                );
            if (
                lis.length >= max &&
                child.parentElement.parentElement.parentElement
            ) {
                parent.find("a.addFormItem").style.display = "none";
                parent.find("a.searchFormItem").style.display = "none";
            } else {
                parent.find("a.ldse-icon-ko-add")
                    ? (parent.find(".ldse-icon-ko-add").style.display = "")
                    : "";
                var addButton = parent.find("a.add-existing-button");
                if (addButton) {
                    addButton.style.display = "";
                }
            }
            if (min && min !== undefined) {
                if (liCount > min) {
                    $(child).closest("li").remove();
                    $("#newIndex").attr("max", liCount - 1);
                } else {
                    alert(
                        "Error you cannot delete any more. A minimum of " +
                            min +
                            " is required",
                        function () {
                            window.close();
                        }
                    );
                }
            } else if (tagUsed == "true" && tagUsed !== undefined) {
                ICE.deleteTag($(child).closest("li"));
            } else {
                ICE.extraPayload(child, "delete");
                $(child).closest("li").remove();
            }
            ICE.updateCKEditors();
            hideIfSubcomponents();
        },
        extraPayload: function (child, payloadAction) {
            // Strategy: Add nested components as extra payload/action represented as <input> to be send on submit
            var payloadElements = [];
            var parentForm = $(child).closest("form.iceForm");
            var extraPayload = $(parentForm).find("input#extra-payload");

            if ($(extraPayload).length > 0) {
                payloadElements = $(extraPayload).val().split(",");
            } else {
                var payloadFieldHTML =
                    '<input type="hidden" id="extra-payload" name="extra-payload" value="" autocomplete="off">';
                var payloadActionHTML =
                    '<input type="hidden" id="extra-payload-action" name="extra-payload-action" value="' +
                    payloadAction +
                    '" autocomplete="off">';
                $(parentForm).append(payloadFieldHTML);
                $(parentForm).append(payloadActionHTML);
            }
            var payloadItem = $(child)
                .closest("li")
                .find("fieldset a[data-id]");
            if ($(payloadItem).length > 0) {
                payloadElements.push($(payloadItem).attr("data-id"));
            } else {
                console.log(
                    "Graceful extra payload failure: Unable to locate nested component's id for payload action"
                );
            }
            extraPayload = $(parentForm).find("input#extra-payload");
            if ($(extraPayload).length > 0) {
                $(extraPayload).val(payloadElements.join());
            }
        },
        deleteTag: function (tag) {
            var number;
            $.ajax({
                type: "GET",
                dataType: "json",
                data: {
                    locale: locale,
                    site: ICE.formVars["site-context"],
                    tag: $(tag).find("input").val(),
                },
                url: sharedPrefix + "/form/ajax/get-content-tags?lang=eng",
                success: function (data) {
                    number = data.count;
                    if (number > 0) {
                        ICE.removeItem(
                            "Are you sure you want to delete this tag?",
                            "There are " +
                                number +
                                " articles using this tag <br/>",
                            tag
                        );
                    } else {
                        $(tag).remove();
                    }
                },
                error: function () {},
            });
        },
        removeItem: function (title, text, tag) {
            var display =
                '<div class="confirmation"><header class="ldse-section--header"><h2>' +
                title +
                '</h2></header><div class="ldse-section--body ldse-form"><dl><dt><label for="reason">' +
                text +
                '</label></dt></dl><div class="ldse-form-buttons"><input type="submit" class="ldse-button primary" value="OK" /><input type="button" class="ldse-button ldse-icon-ko-x ldse-modal-close" value="Cancel" /></div></div></div>';
            modal.find("div").remove();
            modal.append(display).trigger("open");
            modal.find(".ldse-button.primary").click(function () {
                modal.trigger("close");
                $(tag).remove();
                return false;
            });
        },
        destoryCKEditor: function (section) {
            for (var instanceName in CKEDITOR.instances) {
                var instance = CKEDITOR.instances[instanceName];
                var remove = true;
                if (section != null) {
                    remove = $(instance.element.$).closest(section).length != 0;
                }
                if (remove) {
                    instance.destroy(true);
                }
            }
        },
        fixSelects: function (context) {
            context =
                context != undefined ? context : $(".iceForm, .ldse-form");
            $("select:not(.select select)", context).each(function (
                index,
                div
            ) {
                try {
                    $(this).fixSelect({
                        deriveWidth: true,
                    });
                } catch (e) {}
            });
        },
        fixedWidth: function (selector) {
            var listWidth = [];
            $(selector).each(function () {
                listWidth.push($(this).outerWidth(false) + 1);
            });
            $(selector).width(Math.max.apply(Math, listWidth));
        },
        langParam: function (locale) {
            var split = locale.split("-");
            if (split.length > 1) {
                return "lang=" + split[0] + "&country=" + split[1];
            } else {
                return "lang=" + locale;
            }
        },
        linkToItem: function (href, id) {
            sessionStorage.markedItem = id;
            //$.cookie('lds-item-id', id, {expire: .1, path : '/'});

            $.newWindow(href);
        },
        loadDatePickers: function () {
            $(".iceForm .datePicker").each(function (index, input) {
                var format =
                    $(input).data("format") == undefined
                        ? "yy-mm-dd"
                        : $(input).data("format");
                $(input).datepicker({
                    showButtonPanel: false,
                    dayNamesMin: ["S", "M", "T", "W", "T", "F", "S"],
                    dateFormat: format,
                    altFormat: format,
                    showAnim: "fadeIn",
                });
                $(input).removeClass("datePicker");
            });
        },
        markItem: function () {
            var id = sessionStorage.markedItem;
            if (id !== null && typeof id !== "undefined") {
                id = id.replace(/\//g, "");
            }
            if (id != undefined) {
                id = "." + id;
                if (id != ".") {
                    var button = $(id);
                    if (button.length > 0) {
                        showIce();
                        setTimeout(function () {
                            $("html, body").scrollTop(
                                button.offset().top - 100
                            );
                            button.addClass("ldse-highlight");
                        }, 500);
                    }
                }
            }
        },
        carouselCheck: function () {
            if ($.cookie("lds-carousel") == "false") {
                $(document).ready(function () {
                    ICE.toggleCarousel();
                });
            }
        },
        toggleCarousel: function () {
            if ($("#toggleCarousel").length > 0) {
                if (ICE.carousel == true) {
                    $("#toggleCarousel").html("Start Carousel");
                    /* stop carousels */
                    var carousels = $("#toggleCarousel")
                        .data("carousel")
                        .split(",");
                    for (var i in carousels) {
                        $(carousels[i]).cycle("pause");
                    }
                    /* set cookie */
                    $.cookie("lds-carousel", "false", {
                        path: "/",
                        expires: 365,
                    });
                    ICE.carousel = false;
                } else {
                    $("#toggleCarousel").html("Stop Carousel");
                    /* Start carousels */
                    var carousels = $("#toggleCarousel")
                        .data("carousel")
                        .split(",");
                    for (var i in carousels) {
                        $(carousels[i]).cycle("resume");
                    }
                    /* Set Cookie */
                    $.cookie("lds-carousel", null);
                    ICE.carousel = true;
                }
            }
        },
        workflowCheck: function (input) {
            if ($(input).is(":checked")) {
                /* $('#globalCheckbox').removeAttr('disabled'); */
                $("#globalCheckbox").attr("checked", "checked");
            } else {
                /*
                 $('#globalCheckbox').removeAttr("checked");
                 $('#globalCheckbox').attr("disabled", true);
                 */
            }
        },
        pageSettings: function (currentPage, locale) {
            if ($(".ldseForm").length > 0) {
                $(".ldseForm").remove();
            }
            $('<div class="ldseForm"></div>').appendTo("body");
            $.ajax({
                type: "POST",
                url:
                    sharedPrefix +
                    "/ice/resources/ajax/customPage/pageSettingsForm?" +
                    ICE.langParam(locale),
                data: {
                    page: currentPage,
                },
                success: function (html) {
                    $(".ldseForm")
                        .html(html)
                        .dialog({
                            position: [$(window).width() / 2 - 450 / 2, 150],
                            dialogClass: "ldseForm ldse-modal",
                            height: 500,
                            width: 450,
                            zIndex: 4000,
                            draggable: true,
                            title: "Page Settings",
                            modal: true,
                            close: function () {
                                $(".ldseForm").remove().dialog("close");
                            },
                        });
                    ICE.fixSelects();
                },
            });
        },
        subChannelForm: function (
            navName,
            channelName,
            channelSequence,
            currentPage,
            lang,
            isCustom
        ) {
            if (currentPage === "") {
                currentPage = decodeURIComponent(window.location.pathname);
            }
            if (isCustom === undefined) {
                isCustom = false;
            }
            if ($(".ldseForm").length > 0) {
                $(".ldseForm").remove();
            }
            $('<div class="ldseForm"></div>').appendTo("body");
            $.ajax({
                type: "POST",
                url:
                    sharedPrefix +
                    "/ice/resources/ajax/navigation/channelForm?" +
                    ICE.langParam(locale),
                data: {
                    navName: navName,
                    channelSequence: channelSequence,
                    channelName: channelName,
                    curPage: currentPage,
                    isCustom: isCustom,
                    referer: location.href,
                },
                success: function (html) {
                    $(".ldseForm")
                        .html(html)
                        .append(
                            $(
                                '<link rel="stylesheet" media="screen" type="text/css" href="' +
                                    sharedPrefix +
                                    '/ice/resources/styles/screen.css"/>'
                            )
                        )
                        .dialog({
                            dialogClass: "ldseForm ldse-modal",
                            position: [$(window).width() / 2 - 1200 / 2, 150],
                            height: "auto",
                            maxHeight: 900,
                            width: 1200,
                            zIndex: 4000,
                            draggable: true,
                            title: "Edit Channels",
                            modal: "true",
                            close: function () {
                                $(".ldseForm").remove().dialog("close");
                            },
                        });
                },
            });
        },
        clonePage: function (lang, currentPage, action, id) {
            if ($(".ldseForm").length > 0) {
                $(".ldseForm").remove();
            }
            $('<div class="ldseForm ldse-page"></div>').appendTo("body");
            $.ajax({
                type: "POST",
                url:
                    sharedPrefix +
                    "/ice/resources/ajax/clone-page/clonePageForm?" +
                    ICE.langParam(lang),
                data: {
                    currentPage: currentPage,
                    action: "clone",
                    currentID: id,
                },
                success: function (html) {
                    $(".ldseForm")
                        .html(html)
                        .dialog({
                            dialogClass: "ldseForm ldse-modal",
                            maxHeight: 400,
                            width: 500,
                            zIndex: 4000,
                            draggable: true,
                            title: "Clone Page",
                            modal: true,
                            close: function () {
                                $(".ldseForm").remove().dialog("close");
                            },
                        });
                    $(".ldseForm select").fixSelect({
                        deriveWidth: false,
                    });
                    //ICE.fixSelects();
                },
            });
            $("#langSelects span.select").css("width", "300px");
        },
        duplicateComponent: function (site, lang, uri, id) {
            $.ajax({
                type: "POST",
                url: sharedPrefix + "/ice/resources/ajax/duplicateComponent?",
                data: {
                    site: site,
                    lang: lang,
                    uri: uri,
                    id: id,
                },
                success: function (data) {
                    window.location.reload();
                },
                error: function (data) {
                    alert("Unable to duplicate component.");
                },
            });
        },
        teaserManager: function (
            fileid,
            locale,
            formName,
            currentPage,
            publishType,
            options
        ) {
            if ($(".iceForm").length > 0) {
                $(".iceForm").remove();
            }
            $('<div class="iceForm"></div>').appendTo("body");
            $.ajax({
                type: "POST",
                url:
                    sharedPrefix +
                    "/ice/resources/ajax/teaser/manageTeaserList?" +
                    ICE.langParam(locale),
                data: {
                    fileid: fileid,
                    formName: formName,
                    currentPage: currentPage,
                    publishType: publishType,
                    option: options,
                },
                success: function (html) {
                    $(".iceForm")
                        .html(html)
                        .dialog({
                            position: [$(window).width() / 2 - 910 / 2, 150],
                            dialogClass: "iceForm",
                            height: "auto",
                            width: 910,
                            zIndex: 4000,
                            draggable: true,
                            title: $(".iceForm #ice-dialog").attr("title"),
                            beforeClose: function () {
                                //ICE.destoryCKEditor();
                                ICE.teaserManagerActive = false;
                                if (ICE.teaserManagerChange)
                                    window.location.reload();
                            },
                            close: function () {
                                $(".iceForm").remove().dialog("close");
                                ICE.teaserManagerActive = false;
                                if (ICE.teaserManagerChange)
                                    window.location.reload();
                            },
                        });
                    $(".iceForm .teaserManager").bind(
                        "sortupdate",
                        ICE.teaserManagerSortChange
                    );
                    ICE.teaserManagerActive = true;
                },
            });
        },
        teaserManagerSortChange: function (event, ui) {
            var newOrder = "";
            $(".iceForm .teaserManager li").each(function () {
                if (newOrder.length > 0) newOrder += ",";
                newOrder += $(this).attr("data-id");
            });
            $("#manageTeaser-newOrder").val(newOrder);
        },
        /*These functions are not being called anymore outside of the ice.js file*/
        teaserManagerReorder: function (save) {
            var saveOrder = save === "save";
            ICE.teaserManagerSortChange();
            $.ajax({
                type: "POST",
                url:
                    sharedPrefix +
                    "/ice/resources/ajax/teaser/manageTeaserUpdate?lang=eng",
                data: {
                    newOrder: $("#manageTeaser-newOrder").val(),
                    save: saveOrder,
                },
                dataType: "text",
                success: function (data) {
                    window.location.reload();
                },
                error: function (data) {
                    alert(
                        "The teasers could not be saved. Please reload the page and try again."
                    );
                },
            });
        },
        teaserManagerDR: function () {
            if (ICE.teaserManagerDRHold.length > 0) {
                $(
                    ".iceForm .teaserManager li[data-id='" +
                        ICE.teaserManagerDRHold +
                        "']"
                ).remove();
            }
        },
        teaserManagerDRHold: "",
        teaserManagerActive: false,
        teaserManagerChange: false,
        teaserSequenceForm: function (id, lang, currentPage) {
            if (currentPage === "") {
                currentPage = decodeURIComponent(window.location.pathname);
            }
            if ($(".ldseForm").length > 0) {
                $(".ldseForm").remove();
            }
            $('<div class="ldseForm"></div>').appendTo("body");
            $.ajax({
                type: "POST",
                url:
                    sharedPrefix +
                    "/ice/resources/ajax/teaser/editSequence?" +
                    ICE.langParam(locale),
                data: {
                    id: id,
                    curPage: currentPage,
                },
                success: function (html) {
                    $(".ldseForm")
                        .html(html)
                        .dialog({
                            position: [$(window).width() / 2 - 450 / 2, 150],
                            dialogClass: "ldseForm ldse-modal",
                            height: 250,
                            width: 450,
                            zIndex: 4000,
                            draggable: true,
                            modal: true,
                            title: $(".ldseForm #edit-sequence").attr("title"),
                            close: function () {
                                $(".ldseForm").remove().dialog("close");
                            },
                        });
                },
            });
        },
        binaryManger: function (button) {
            //add in some DOM elements for the modal etc. this intrduces a jQuery dependency for now
            if ($(".modal-background").length == 0) {
                $("bc-wrapper").remove();
                var modalDom = $(
                    '<div class="modal-background hidden"><div class="bc-wrapper">Binary Manger Loading</div></div>'
                );
                $("body").append(modalDom);
                $(".modal-background").on("click", function () {
                    $(this).hide();
                });
                $(".bc-wrapper").on("click", function (event) {
                    event.stopPropagation();
                });
            }
            if (
                window.File &&
                window.FileReader &&
                window.FileList &&
                window.Blob
            ) {
                var binaryType = $(button).data("binary-type"),
                    inputID = $(button).data("binary-input"),
                    minHeight = $(button).data("image-min-height"),
                    minWidth = $(button).data("image-min-width"),
                    allowedHeight = $(button).data("image-height"),
                    allowedWidth = $(button).data("image-width"),
                    fileExts = $(button).data("binary-ext").split(","),
                    updateArticle = ICE.formVars.action === "edit",
                    hideTabs = false;
                if (binaryType !== "" && fileExts.length > 0) {
                    hideTabs = true;
                }
                //open modal
                $(".bc-wrapper").parents(".modal-background").show();
                //write in the js file if it hasn't already been loaded
                if (typeof jsloaded === "undefined") {
                    jsloaded = true;

                    //load in the main control file
                    function createBinaryManager() {
                        createBC({
                            adminLibrary: false,
                            apiUrl: sharedPrefix + "/ice/burce/",
                            wrapperSelector: "bc-wrapper",
                            libraryUrl: sharedPrefix + "/binary?lang=eng",
                            noArticle: true,
                            updateArticle: updateArticle,
                            contentType: binaryType,
                            inputID: inputID,
                            minHeight: minHeight,
                            minWidth: minWidth,
                            allowedHeight: allowedHeight,
                            allowedWidth: allowedWidth,
                            allowedFileExtensions: fileExts,
                            hideTabs: hideTabs,
                        });
                    }
                    if (typeof yourFunctionName == "function") {
                        $.getScript(
                            sharedPrefix + "/binary/resources/scripts/burce.js",
                            function (data) {
                                createBinaryManager();
                            }
                        );
                    } else {
                        createBinaryManager();
                    }
                } else {
                    resetBC({
                        contentType: binaryType,
                        inputID: inputID,
                        minHeight: minHeight,
                        minWidth: minWidth,
                        allowedHeight: allowedHeight,
                        allowedWidth: allowedWidth,
                        allowedFileExtensions: fileExts,
                        hideTabs: hideTabs,
                    });
                }
            } else {
                alert(
                    "We're sorry but the browser you are using is not supported for this operation"
                );
            }
        },
        showOmniture: function () {
            if ($(".ldseForm").length > 0) {
                $(".ldseForm").remove();
            }
            $('<div id="omnitureContainer" class="ldseForm"></div>').appendTo(
                "body"
            );
            var name = s.pageName || pageName;
            var urlTxt = sharedPrefix + "/omniture?lang=eng";
            $.ajax({
                type: "POST",
                url: urlTxt,
                data: {
                    pageName: name,
                    dateRange: 30,
                },
                success: function (response) {
                    $(".ldseForm")
                        .html(response)
                        .dialog({
                            position: [$(window).width() / 2 - 878 / 2, 150],
                            dialogClass: "omnitureModal ldseForm ldse-modal",
                            width: 878,
                            height: 552,
                            title: "Omniture Stats for page:" + name,
                            resizable: false,
                            modal: true,
                        });
                },
                error: function (html) {
                    //alert("ajax failed");
                },
            });
        },
        showSEOMoz: function () {
            var returnURL = window.location;
            var forwardURL = sharedPrefix + "/seomoz?lang=eng";
            var form = $(
                '<form id="seoForm" action="' +
                    forwardURL +
                    '" method="post"></form>'
            );
            $("body").append(form);
            form.hide();

            form.html(
                '<input type="text" name="returnURL" value="' +
                    returnURL +
                    '" />'
            );
            form.submit();
        },
        translationMark: function (status, action, id, button) {
            var title = $(button).text();
            if ($(".iceForm").length > 0) {
                $(".iceForm").remove();
            }
            var html =
                '<div class="ldse-clearfix">' +
                '<div class="actionLabel">' +
                title +
                ": </div>" +
                '<div id="translationMarked" class="publishImage">' +
                '<span class="ui-finder-loader">&nbsp;</span>' +
                '<div id="status_teaser" class="publishStatus"> </div>' +
                "</div>" +
                "</div>" +
                '<div class="publishClose"><button id="" class="ldse-button close">Close</button></div>';
            $('<div class="actionModal iceForm"></div>')
                .html(html)
                .appendTo("body");
            $(".iceForm .close").click(function () {
                $(".iceForm").remove().dialog("close");
                location.reload();
            });
            $(".iceForm").dialog({
                position: [$(window).width() / 2 - 320 / 2, 150],
                dialogClass: "ldseForm ldse-modal",
                width: 320,
                height: "auto",
                title: title,
                zIndex: 4000,
                resizable: true,
            });
            $.ajax({
                url: sharedPrefix + "/translation/ajax/apply-action?lang=eng",
                type: "POST",
                contentType: "application/x-www-form-urlencoded",
                dataType: "json",
                data: {
                    status: status,
                    action: action,
                    "id[]": id,
                },
                success: function (response) {
                    if (response.success) {
                        $("#translationMarked").html(
                            '<span class="ldse-publish-dialog ldse-icon-check2"></span><div id="status_teaser" class="publishStatus">Successfully marked <b>1</b> item(s)</div>'
                        );
                    } else {
                        $("#translationMarked").html(
                            '<span class="ldse-publish-dialog ldse-icon-ko-warning"></span><div id="status_teaser" class="publishStatus">Failed to marked <b>1</b> item(s)</div>'
                        );
                    }
                },
                error: function (jqXHR) {
                    $("#translationMarked").html(
                        '<div id="status_teaser" class="publishStatus">Failed to marked <b>1</b> item(s)</div>'
                    );
                },
            });
        },
        translationReady: function (status, action, locale, id, button) {
            var title = $(button).text();
            if ($(".iceForm").length > 0) {
                $(".iceForm").remove();
            }
            var html =
                '<div class="ldse-clearfix">' +
                '<div class="actionLabel">' +
                title +
                ": </div>" +
                '<div id="translationMarked" class="publishImage">' +
                '<span class="ui-finder-loader">&nbsp;</span>' +
                '<div id="status_teaser" class="publishStatus"> </div>' +
                "</div>" +
                "</div>" +
                '<div class="publishClose"><button id="" class="ldse-button close">Close</button></div>';
            $('<div class="actionModal iceForm"></div>')
                .html(html)
                .appendTo("body");
            $(".iceForm .close").click(function () {
                $(".iceForm").remove().dialog("close");
                location.reload();
            });
            $(".iceForm").dialog({
                position: [$(window).width() / 2 - 320 / 2, 150],
                dialogClass: "ldseForm ldse-modal",
                width: 320,
                height: "auto",
                title: title,
                zIndex: 4000,
                resizable: true,
            });
            $.ajax({
                url:
                    sharedPrefix +
                    "/translation/ajax/mark-ready?lang=" +
                    locale,
                type: "POST",
                contentType: "application/x-www-form-urlencoded",
                dataType: "json",
                data: {
                    status: status,
                    action: action,
                    id: id,
                },
                success: function (response) {
                    if (response.success) {
                        $("#translationMarked").html(
                            '<span class="ldse-publish-dialog ldse-icon-check2"></span><div id="status_teaser" class="publishStatus">Successfully marked <b>1</b> item(s)</div>'
                        );
                    } else {
                        $("#translationMarked").html(
                            '<span class="ldse-publish-dialog ldse-icon-ko-warning"></span><div id="status_teaser" class="publishStatus">Failed to marked <b>1</b> item(s)</div>'
                        );
                    }
                },
                error: function (jqXHR) {
                    $("#translationMarked").html(
                        '<div id="status_teaser" class="publishStatus">Failed to marked <b>1</b> item(s)</div>'
                    );
                },
            });
        },
        translationReadyAll: function (status, action, locale, id, button) {
            var title = $(button).text();
            var site = getUrlParameter("site");
            if ($(".iceForm").length > 0) {
                $(".iceForm").remove();
            }
            var html =
                '<div class="ldse-clearfix">' +
                '<div class="actionLabel">' +
                title +
                ": </div>" +
                '<div id="translationMarked" class="publishImage">' +
                '<span class="ui-finder-loader">&nbsp;</span>' +
                '<div id="status_teaser" class="publishStatus"> </div>' +
                "</div>" +
                "</div>" +
                '<div class="publishClose"><button id="" class="ldse-button close">Close</button></div>';
            $('<div class="actionModal iceForm"></div>')
                .html(html)
                .appendTo("body");
            $(".iceForm .close").click(function () {
                $(".iceForm").remove().dialog("close");
                location.reload();
            });

            $(".iceForm").dialog({
                position: [$(window).width() / 2 - 320 / 2, 150],
                dialogClass: "ldseForm ldse-modal",
                width: 320,
                height: "auto",
                title: title,
                zIndex: 4000,
                resizable: true,
            });
            $.ajax({
                url:
                    sharedPrefix +
                    "/content-admin/ajax/mark-all-items?lang=" +
                    locale,
                type: "POST",
                contentType: "application/x-www-form-urlencoded",
                dataType: "json",
                data: {
                    status: status,
                    action: action,
                    site: site,
                    id: id,
                },
                success: function (response) {
                    if (response.success) {
                        $("#translationMarked").html(
                            '<span class="ldse-publish-dialog ldse-icon-check2"></span><div id="status_teaser" class="publishStatus">Successfully marked ' +
                                response.marked +
                                " item(s)</div>"
                        );
                    } else {
                        $("#translationMarked").html(
                            '<span class="ldse-publish-dialog ldse-icon-ko-warning"></span><div id="status_teaser" class="publishStatus">Failed to marked item(s)</div>'
                        );
                    }
                },
                error: function (jqXHR) {
                    $("#translationMarked").html(
                        '<div id="status_teaser" class="publishStatus">Failed to marked item(s)</div>'
                    );
                },
            });
        },
        translationSend: function (
            status,
            action,
            locale,
            id,
            button,
            excludeReferencedComponents
        ) {
            var title = $(button).text();
            var site = getUrlParameter("site");
            if ($(".iceForm").length > 0) {
                $(".iceForm").remove();
            }
            var html =
                '<div class="ldse-clearfix">' +
                '<div class="actionLabel">' +
                title +
                ": </div>" +
                '<div id="translationMarked" class="publishImage">' +
                '<span class="ui-finder-loader">&nbsp;</span>' +
                '<div id="status_teaser" class="publishStatus"> </div>' +
                "</div>" +
                "</div>" +
                '<div class="publishClose"><button id="" class="ldse-button close">Close</button></div>';
            $('<div class="actionModal iceForm"></div>')
                .html(html)
                .appendTo("body");
            $(".iceForm .close").click(function () {
                $(".iceForm").remove().dialog("close");
                location.reload();
            });
            $(".iceForm").dialog({
                position: [$(window).width() / 2 - 320 / 2, 150],
                dialogClass: "ldseForm ldse-modal",
                width: 320,
                height: "auto",
                title: title,
                zIndex: 4000,
                resizable: true,
            });
            $.ajax({
                url: sharedPrefix + "/translation/ajax/mark-ready?lang=eng",
                type: "POST",
                contentType: "application/x-www-form-urlencoded",
                dataType: "json",
                data: {
                    status: status,
                    action: action,
                    site: site,
                    locale: locale,
                    id: id,
                },
                success: function (response) {
                    if (response.success) {
                        $("#translationMarked").html(
                            '<span class="ldse-publish-dialog ldse-icon-check2"></span><div id="status_teaser" class="publishStatus">Successfully marked ' +
                                response.marked +
                                " item(s)</div>"
                        );
                        // Redirect to Translate Send Form
                        var lang = getUrlParameter("lang");
                        var redirectUrl =
                            sharedPrefix +
                            "/translation?" +
                            "lang=" +
                            lang +
                            "&site=" +
                            site +
                            "&send=true&sendid=" +
                            id +
                            "&excludeReferencedComponents=" +
                            excludeReferencedComponents;
                        window.location.href = redirectUrl;
                    } else {
                        $("#translationMarked").html(
                            '<span class="ldse-publish-dialog ldse-icon-ko-warning"></span><div id="status_teaser" class="publishStatus">Failed to mark item(s)</div>'
                        );
                    }
                },
                error: function (jqXHR) {
                    $("#translationMarked").html(
                        '<div id="status_teaser" class="publishStatus">Failed to marked <b>1</b> item(s)</div>'
                    );
                },
            });
        },
    };

    function linkChecker() {
        var parent = this,
            notSelectors = [
                '[href^="#"]',
                '[href*="signmeout"]',
                "#ldse-toolbar-container a",
                ".ldse-ice-menu-container a",
                ".pf-header a",
                ".pf-footer a",
            ],
            notString = "";

        if (typeof LINKCHECKER_NOT_SELECTORS !== "undefined") {
            notSelectors.concat(LINKCHECKER_NOT_SELECTORS);
        }
        for (var k = 0; k < notSelectors.length; k++) {
            notString += ":not(" + notSelectors[k] + ")";
        }

        this.servicUrl =
            sharedPrefix + "/ice/resources/ajax/check-links?lang=eng";

        this.isExternal = function (url) {
            var match = url.match(
                /^([^:\/?#]+:)?(?:\/\/([^\/?#]*))?([^?#]+)?(\?[^#]*)?(#.*)?/
            );
            if (
                typeof match[1] === "string" &&
                match[1].length > 0 &&
                match[1].toLowerCase() !== location.protocol
            )
                return true;
            if (
                typeof match[2] === "string" &&
                match[2].length > 0 &&
                match[2].replace(
                    new RegExp(
                        ":(" +
                            {
                                "http:": 80,
                                "https:": 443,
                            }[location.protocol] +
                            ")?$"
                    ),
                    ""
                ) !== location.host
            )
                return true;
            return false;
        };

        this.getLinks = function () {
            // [href] Only gets links with an href element
            // [href!=""] Removes any links with a blank href
            // :not([href^="#"]) Removes any links that start with a #
            // :not(.ldse-checked-link) Removes any links that have already been checked (for starting, stopping, and restarting)
            // :not(#ldse-toolbar-container a) Removes any links in the toolbar
            // :not(.ldse-ice-menu-container a) Removes any links in an ICE menu
            // :not([href*="signmeout"]):not([href*="signmein"]) Removes signin/out links
            // LINKCHECKER_NOT_SELECTORS = [];
            this.externalLinks = [];

            this.links = $('a[href][href!=""]' + notString).each(function () {
                var link = $(this);
                var href = this.href + "";
                var external = parent.isExternal(href);
                link.data("checker", {
                    url: href,
                    external: external,
                    preview: null,
                    live: null,
                    unknown: null,
                });
                if (external) {
                    parent.externalLinks.push(link);
                }
            });
        };

        this.links = [];
        this.externalLinks = [];
        this.checker = $("#ldse-link-checker");
        this.button = $("#ldse-check-links");
        this.toggleButton = $("#ldse-check-links-toggle");
        this.checkerStatus = $("#ldse-check-links-status");
        this.progressBar = $("#ldse-link-progress-bar-color");

        this.goodCount = $(".ldse-link-count.ldse-good span");
        this.prodCount = $(".ldse-link-count.ldse-broken-prod span");
        this.previewCount = $(".ldse-link-count.ldse-broken-preview span");
        this.unknownCount = $(".ldse-link-count.ldse-unknown span");
        this.uncheckedCount = $(".ldse-link-count.ldse-unchecked span");

        this.total;

        this.hasGood = 0;
        this.hasPreview = 0;
        this.hasUnknown = 0;
        this.hasLeft;

        this.goodClicks = 0;
        this.prodClicks = 0;
        this.previewClicks = 0;
        this.unknownClicks = 0;

        this.running = false;
        var internalDone = false;
        var externalDone = false;

        this.currentIndex = 0;
        this.externalXHR = null;

        this.reset = function () {
            this.button.removeClass(
                "ldse-links-broken-link-preview ldse-links-broken-link-prod ldse-links-good ldse-links-unknown"
            );
            $(".ldse-image-link").remove();
            $(this.links).removeClass(
                "ldse-checked-link ldse-broken-link-preview ldse-broken-link-prod ldse-good-link ldse-unknown-link"
            );
            this.hasGood = 0;
            this.hasProd = 0;
            this.hasPreview = 0;
            this.hasUnknown = 0;
            this.running = false;
            internalDone = false;
            externalDone = false;
            this.currentIndex = 0;
            this.start();
        };

        this.start = function () {
            if (this.button.length > 0) {
                this.goodClicks = 0;
                this.previewClicks = 0;
                this.unknownClicks = 0;
                this.getLinks();
                this.total = this.links.length;
                this.hasLeft = this.total - this.currentIndex;

                this.goodCount.html(this.hasGood);
                this.previewCount.html(this.hasPreview);
                this.uncheckedCount.html(this.hasLeft);

                sessionStorage.linkChecking = "on";
                this.toggleButton
                    .removeClass("primary ldse-icon-check2 ldse-icon-loop")
                    .addClass("ldse-icon-x")
                    .html("Stop Checking");
                this.running = true;
                this.checker
                    .addClass("ldse-link-in-progress")
                    .removeClass("ldse-link-check-done");
                this.updateCounts();
                this.updateProgress();
                this.checkExternalLinks();
                this.checkLinks();
            }
        };

        this.stop = function () {
            try {
                this.externalXHR.abort();
            } catch (e) {}
            sessionStorage.linkChecking = "off";
            this.toggleButton
                .removeClass("ldse-icon-x")
                .addClass("primary ldse-icon-check2")
                .html("Start Checking");
            this.running = false;
            this.checker.removeClass("ldse-link-in-progress");
        };

        this.updateProgress = function () {
            var percent = ((this.total - this.hasLeft) / this.total) * 100;
            this.progressBar.css("width", percent + "%");
        };

        this.checkExternalLinks = function () {
            var urls = [];
            for (var i = 0; i < this.externalLinks.length; i++) {
                var link = this.externalLinks[i];
                var data = link.data("checker");
                urls.push(data.url);
            }

            this.externalXHR = $.ajax({
                url: this.servicUrl,
                type: "POST",
                dataType: "json",
                data: {
                    url: urls,
                    "location-host": location.host,
                    "location-protocol": location.protocol,
                    "location-origin": location.origin,
                },
                success: function (json) {
                    if (json != null) {
                        for (var k = 0; k < json.results.length; k++) {
                            var link = parent.externalLinks[k];
                            var data = link.data("checker");
                            var code = json.results[k].code;
                            if (code == 1000) {
                                data.unknown = true;
                            } else if (code >= 400) {
                                data.preview = false;
                            } else {
                                data.preview = true;
                            }
                            data.checked = true;
                            parent.updateLink(link, data);
                        }
                    }
                },
                complete: function () {
                    parent.updateCounts();
                    parent.updateProgress();
                    parent.done("external");
                },
            });
        };

        this.checkLinks = function () {
            var link = this.links.eq(this.currentIndex);
            var data = link.data("checker");
            function readResponse(http) {
                if (http.status >= 400) {
                    data.preview = false;
                } else if (http.status < 400) {
                    data.preview = true;
                }
                data.checked = true;
                parent.updateLink(link, data);
            }

            if (data !== undefined) {
                if (!data.external) {
                    $.ajax({
                        type: "HEAD",
                        async: true,
                        url: data.url,
                        success: function (a, b, http) {
                            readResponse(http);
                        },
                        error: function (http) {
                            readResponse(http);
                        },
                        complete: function () {
                            parent.currentIndex++;
                            parent.updateCounts();
                            parent.updateProgress();
                            if (
                                parent.running &&
                                parent.currentIndex < parent.total
                            ) {
                                setTimeout(function () {
                                    parent.checkLinks();
                                }, 100);
                            } else if (parent.currentIndex >= parent.total) {
                                parent.done("internal");
                            }
                        },
                    });
                } else {
                    parent.currentIndex++;
                    if (parent.running && parent.currentIndex < parent.total) {
                        parent.checkLinks();
                    } else if (parent.currentIndex >= parent.total) {
                        parent.updateProgress();
                        parent.done("internal");
                    }
                }
            }
        };

        this.updateLink = function (link, data) {
            this.hasLeft--;
            if (data.preview === true) {
                if (this.hasGood == 0) {
                    this.button.addClass("ldse-links-good");
                }
                this.updateLinkClass(link, "ldse-good-link");
                this.hasGood++;
            } else if (data.preview === false) {
                if (this.hasPreview == 0) {
                    this.button.addClass("ldse-links-broken-link-preview");
                }
                this.hasPreview++;
                this.updateLinkClass(link, "ldse-broken-link-preview");
            } else {
                if (this.hasUnknown == 0) {
                    this.button.addClass("ldse-links-unknown");
                }
                this.hasUnknown++;
                this.updateLinkClass(link, "ldse-unknown-link");
            }
        };

        this.updateCounts = function () {
            this.goodCount.html(this.hasGood);
            this.previewCount.html(this.hasPreview);
            this.unknownCount.html(this.hasUnknown);
            this.uncheckedCount.html(this.hasLeft);
        };

        this.done = function (type) {
            if (type === "internal") {
                internalDone = true;
            } else if (type === "external") {
                externalDone = true;
            }
            if (internalDone && externalDone) {
                this.checker
                    .removeClass("ldse-link-in-progress")
                    .addClass("ldse-link-check-done");
                this.toggleButton
                    .removeClass("primary ldse-icon-check2")
                    .addClass("ldse-icon-loop")
                    .html("Recheck Links");
            }
        };

        this.updateLinkClass = function (link, className) {
            link.addClass("ldse-checked-link").addClass(className);
            var images = link.children("img");
            if (images.length > 0) {
                images.each(function () {
                    var image = $(this),
                        span = $(
                            '<span class="ldse-image-link"></span>'
                        ).insertAfter(image);
                    span.width(image.outerWidth())
                        .height(image.outerHeight())
                        .css("top", image.position().top)
                        .css("margin-top", image.css("margin-top"))
                        .css("left", image.position().left)
                        .css("margin-left", image.css("margin-left"));
                });
            }
        };
    }

    /*    var linkChecker;*/

    function seoChecker(frame) {
        var _ = this;
        this.context = frame || document;

        this.getImgs = function () {
            return $("img", _.context).filter(function () {
                return (
                    $(this).closest(
                        ".resourceIce,.edit-resource,#beta-feedback"
                    ).length == 0
                );
            });
        };

        this.getMetaTitle = function () {
            if (_.context == document) {
                return $("head title", _.context).text();
            } else {
                return $((/<title.*?>/.exec(_.context) || "")[0]).text();
            }
        };

        this.getMetaDescription = function () {
            if (_.context == document) {
                return $('head meta[name="DESCRIPTION"]', _.context).attr(
                    "content"
                );
            } else {
                return $(
                    (/<meta.*name="DESCRIPTION".*?>/.exec(_.context) || "")[0]
                ).attr("content");
            }
        };

        this.contains = function (x, y) {
            return (
                x != undefined &&
                y != undefined &&
                x.toUpperCase().indexOf(y.toUpperCase()) != -1
            );
        };

        this.startsWith = function (x, y) {
            return (
                x != undefined &&
                y != undefined &&
                x.toUpperCase().indexOf(y.toUpperCase()) == 0
            );
        };

        this.substringAfterLast = function (x, y) {
            if (x != undefined && y != undefined) {
                if (x.indexOf(y) != -1) {
                    return x.substring(x.lastIndexOf(y));
                } else {
                    return x;
                }
            }
        };

        this.score = function () {
            var title = _.getMetaTitle(),
                desc = _.getMetaDescription(),
                imgs = _.getImgs(),
                validTitle = typeof title != "undefined" && title != "",
                validDesc = typeof desc != "undefined" && desc != "",
                validAltCount = 0;
            Score = {
                validTitle: validTitle,
                validDesc: validDesc,
            };

            imgs.each(function () {
                if ($(this).attr("alt") != "") {
                    validAltCount++;
                }
            });

            var validImgs = imgs.length == validAltCount;

            Score.validImgs = validImgs;
            Score.imgs = imgs.length;
            Score.validAltCount = validAltCount;

            if (validTitle && validDesc && validImgs) {
                Score.score = "good";
            } else if (
                !validTitle &&
                !validDesc &&
                (!validImgs || imgs.length == 0)
            ) {
                Score.score = "bad";
            } else {
                Score.score = "warning";
            }

            return Score;
        };

        this.analyze = function (text) {
            var title = _.getMetaTitle(),
                desc = _.getMetaDescription(),
                imgs = _.getImgs(),
                altMatch = false,
                fileMatch = false;

            var score = {
                title: 0,
                firstTitle: 0,
                description: 0,
                body: 0,
                filename: 0,
                altText: 0,
                total: 0,
            };

            if (_.contains(title, text)) {
                score.title = 30;
                if (_.startsWith(title, text)) {
                    score.firstTitle = 20;
                }
            }

            if (_.contains(desc, text)) {
                score.description = 15;
            }

            if (
                $('body *:containsNC("' + text + '"):last', _.context).length >
                0
            ) {
                score.body = 15;
            }

            imgs.each(function () {
                var img = $(this),
                    altMatch = false,
                    fileMatch = false;

                if (!altMatch) {
                    var alt = img.attr("alt");
                    if (_.contains(alt, text)) {
                        score.altText = 15;
                        altMatch = true;
                    }
                }

                if (!fileMatch) {
                    var src = img.attr("data-src") || img.attr("src"),
                        filename = _.substringAfterLast(src, "/");

                    if (_.contains(filename, text)) {
                        score.filename = 5;
                        fileMatch = true;
                    }
                }

                if (altMatch && fileMatch) {
                    return false;
                }
            });
            score.total =
                score.title +
                score.firstTitle +
                score.description +
                score.body +
                score.filename +
                score.altText;
            score.keyword = text;
            return score;
        };

        this.updateToolbar = function () {
            var score = _.score(),
                className = "ldse-seo-" + score.score,
                checker = $("#ldse-seo-checker");
            $(
                "#ldse-check-seo, #ldse-seo-checker #ldse-seo-page-score .ldse-seo-scored"
            ).addClass(className);
            $("#ldse-seo-checker #ldse-seo-page-score .ldse-seo-scored").html(
                score.score
            );
            if (
                checker.data("saveable") &&
                checker.data("score") != score.score
            ) {
                _.saveScore(checker.data("uri"), score, checker.data("locale"));
            }
            if (score.validTitle) {
                $(
                    "#ldse-seo-checker .ldse-seo-found-title .ldse-seo-scored"
                ).addClass("ldse-icon-check1");
            } else {
                $(
                    "#ldse-seo-checker .ldse-seo-found-title .ldse-seo-scored"
                ).addClass("ldse-icon-x");
            }
            if (score.validDesc) {
                $(
                    "#ldse-seo-checker .ldse-seo-found-description-title-score .ldse-seo-scored"
                ).addClass("ldse-icon-check1");
            } else {
                $(
                    "#ldse-seo-checker .ldse-seo-found-description-title-score .ldse-seo-scored"
                ).addClass("ldse-icon-x");
            }
            $(
                "#ldse-seo-checker .ldse-seo-found-alt-score .ldse-seo-scored"
            ).html(score.validAltCount);
            $(
                "#ldse-seo-checker .ldse-seo-found-alt-score .ldse-seo-out-of"
            ).html("/" + score.imgs);
        };

        this.currentPageAnalyze = function () {
            var text = $("#ldse-seo-keyword").val();
            var score = _.analyze(text);

            $("#ldse-seo-checker .ldse-seo-title-score .ldse-seo-scored").html(
                score.title
            );
            $(
                "#ldse-seo-checker .ldse-seo-first-title-score .ldse-seo-scored"
            ).html(score.firstTitle);
            $("#ldse-seo-checker .ldse-seo-meta-score .ldse-seo-scored").html(
                score.description
            );
            $(
                "#ldse-seo-checker .ldse-seo-page-content-score .ldse-seo-scored"
            ).html(score.body);
            $(
                "#ldse-seo-checker .ldse-seo-filename-score .ldse-seo-scored"
            ).html(score.filename);
            $("#ldse-seo-checker .ldse-seo-alt-score .ldse-seo-scored").html(
                score.altText
            );
            $("#ldse-seo-checker .ldse-seo-total .ldse-seo-scored").html(
                score.total
            );

            $(".ldse-seo-scoring").show();
        };

        this.getSeoObj = function (url, onComplete) {
            $.ajax({
                type: "GET",
                url: url,
                dataType: "text",
                success: function (data) {
                    data = data.replace(/src=/gm, "data-src=");
                    var SEO = new seoChecker(data);
                    onComplete(SEO);
                },
                error: function (x, y, z) {
                    var SEO = new seoChecker({});
                    SEO.error = true;
                    onComplete(SEO);
                },
            });
        };

        this.saveScore = function (url, Score, locale) {
            $.ajax({
                url: sharedPrefix + "/resources/ajax/save-seo-score?lang=eng",
                type: "POST",
                data: {
                    url: url,
                    score: Score,
                    locale: locale,
                },
            });
        };
    }

    // Manages: 1. display-dependency attribute for hidden/show form fields
    //          2. add-required attribute to tag a CSS required class on form fields
    // Usage front-end: $('form selector').microMixin()
    //                   it will manage only the elements of the form selector
    // Usage back-end:
    //  ICE XML Forms Syntax has been updated.
    //  Notes:
    //  1. Use html element ids always on 'display-dependency' and 'add-required'
    //  2. Input fields with empty values "" are always trigger to:
    //       A. hidden dependents fields
    //       B. toggle off (remove) required class
    //  3. White spaces are ignored. "bg-color,level" and " bg-color , level " are the same. It applies to 'display-dependency-value' and
    //     'add-required-value' too.
    //
    //  4. display-dependency Examples
    //  - Legacy Syntax:
    //       <input display-dependency="bg-color">  means show on ANY values except Emtpy ""
    //       <input display-dependency="bg-color" display-dependency-value="Blue40, Green10" means show only when values are Blue40 or Green10
    //  - New Syntax AND:
    //      <input display-dependency="bg-color, level">  means show when any value of "bg-color" AND any value of "level" (except Empty in both cases)
    //      <input display-dependency="bg-color AND level">  means show when any value of "bg-color" AND any value of "level" (except Empty in both cases)
    //      <input display-dependency="bg-color, level" display-dependency-value="bg-color:{Blue40, Green10}">
    //                              means show when "bg-color" has Blue40 or Green10 AND any value of "level" (except empty)
    //      <input display-dependency="bg-color, level" display-dependency-value="bg-color:{Blue40, Green10}, level: {h1, h2}">
    //                              means show when "bg-color" has Blue40 or Green10 AND "level" has h1 or h2 values.
    //  - New OR Syntax
    //      <input display-dependency="bg-color | level" display-dependency-value="bg-color:{Blue40, Green10}">
    //      <input display-dependency="bg-color OR level" display-dependency-value="bg-color:{Blue40, Green10}">
    //                              means show when "bg-color" has Blue40 or Green10, or if "level" has any value except Empty
    //
    //  5. add-required Examples
    //  - Legacy Syntax:
    //       <input add-required="bg-color">  means add CSS class 'required' for ANY values except Emtpy ""
    //       <input add-required="bg-color" add-required-value="Blue40, Green10" means add CSS class 'required' only when values are Blue40 or Green10
    //  - New Syntax AND:
    //      <input add-required="bg-color, level">  means add CSS class 'required' for ANY values of "bg-color" AND any value of "level" (except Empty in both cases)
    //      <input add-required="bg-color AND level">  means add CSS class 'required' for ANY values of "bg-color" AND any value of "level" (except Empty in both cases)
    //      <input add-requiredy="bg-color, level" add-required-value="bg-color:{Blue40, Green10}">
    //                              means means add CSS class 'required' when "bg-color" has Blue40 or Green10 AND any value of "level" (except empty)
    //      <input add-required="bg-color, level" add-required-value="bg-color:{Blue40, Green10}, level: {h1, h2}">
    //                              means means add CSS class 'required' when "bg-color" has Blue40 or Green10 AND "level" has h1 or h2 values.
    //  - New OR Syntax
    //      <input add-required="bg-color | level" add-required-value="bg-color:{Blue40, Green10}">
    //      <input add-required="bg-color OR level" add-required-value="bg-color:{Blue40, Green10}">
    //                              means add CSS class 'required' when "bg-color" has Blue40 or Green10, or if "level" has any value except Empty
    //
    $.widget("ldse.microMixin", {
        options: {
            mixin: new Map(),
        },
        _create: function () {
            this.options.mixin.set("dependency", {
                name: "display-dependency",
                value: "display-dependency-value",
                type: "hide-element",
                typeValue: "",
                observers: [],
            });
            this.options.mixin.set("required", {
                name: "add-required",
                value: "add-required-value",
                type: "toggle-class",
                typeValue: "required",
                observers: [],
            });

            // Alias to be able to use it later, to avoid errors inside local .each operators that use $(this)
            // Often, it's the current Form. mixinRoot.element == this.element
            var mixinRoot = this;
            mixinRoot.options.mixin.forEach(function (mixin, key) {
                // observers: for each form element which has a 'dependency-value' or 'add-required'
                var mixinElement = mixinRoot.element.find(
                    "[" + mixin.name + "]"
                );
                for (var index = 0; index < mixinElement.length; index++) {
                    // Becomes true if | is detected
                    var isOR = false;
                    var tokenArray = [];
                    var token = $(mixinElement[index]).attr(mixin.name);
                    if (
                        token.includes("|") ||
                        token.includes(" OR ") ||
                        token.includes(" or ")
                    ) {
                        // OR
                        if (token.includes("|"))
                            tokenArray = token.split(/\s*(?:\|)\s*/);
                        else if (token.includes(" OR "))
                            tokenArray = token.split(/\s*(?: OR )\s*/);
                        else tokenArray = token.split(/\s*(?: or )\s*/);
                        isOR = true;
                    } else {
                        // AND
                        if (token.includes(" AND "))
                            tokenArray = token.split(/\s*(?: AND )\s*/);
                        else if (token.includes(" and "))
                            tokenArray = token.split(/\s*(?: and )\s*/);
                        else tokenArray = token.split(/\s*(?:,)\s*/);
                    }
                    // Clean up of spaces and others
                    tokenArray = mixinRoot._clean(tokenArray);
                    // Parsing returns an object of elements which $(this) is dependent of, and their values
                    // depObj {el1 {values:{}, all:true/false}, el2 {values:{}, all:true/false}}
                    var tokenizedObj = mixinRoot._parse(
                        tokenArray,
                        $(mixinElement[index]).attr(mixin.value)
                    );
                    //  watched: get the dependencies/required of the form element
                    var watchedObj = {};
                    for (
                        var arrayIndex = 0;
                        arrayIndex < tokenArray.length;
                        arrayIndex++
                    ) {
                        // Get location of mixin element container <input> and token being processed
                        const observerIndex = index;
                        const tokenIndex = arrayIndex;
                        // Work on the corresponding form by using 'fieldset'
                        var watched = $(mixinElement[index])
                            .closest("fieldset")
                            .find("#" + tokenArray[arrayIndex]);
                        if (watched.length > 0) {
                            // Bind it to get updates of content changed
                            watched[0].addEventListener("change", (e) => {
                                mixinRoot.notify(e.target, observerIndex, key);
                            });
                            watchedObj[tokenArray[tokenIndex]] = $(watched)[0];
                        }
                    }
                    mixin.observers.push({
                        selector: $(mixinElement[index]),
                        tokenValues: tokenizedObj,
                        watched: watchedObj,
                        isOR: isOR,
                    });
                }
            });
            this._init();
        },
        _parse: function (tokenArray, value) {
            // tokenArray = display-dependency, value = display-dependency-value
            var tokenizedObj = {};
            tokenArray.forEach(function (id) {
                if (id.length > 0) {
                    // making sure is not "" because of bad syntax
                    if (value) {
                        var regexObj = new RegExp(
                            "\\s*" + id + "\\s*:\\s*{(.*?)}"
                        );
                        var valueRegex = value.match(regexObj);
                        if (valueRegex) {
                            tokenizedObj[id] = {
                                values: valueRegex[1].split(/\s*(?:,|$)\s*/),
                                all: false,
                            };
                        } else {
                            // legacy syntax check
                            if (tokenArray.length == 1) {
                                tokenizedObj[id] = {
                                    values: value.split(/\s*(?:,|$)\s*/),
                                    all: false,
                                };
                            } else {
                                // all values
                                tokenizedObj[id] = { values: [], all: true };
                            }
                        }
                    } else {
                        // display-dependency-value is absent, implying 'all' values
                        tokenizedObj[id] = { values: [], all: true };
                    }
                }
            });
            return tokenizedObj;
        },
        // Reduces an array to valid elements
        // Example Input: [" image-URL ", " l evel ", ""])
        // Example Return: ["image-URL"]
        _clean: function (array2clean) {
            var newArray = array2clean.map((arrEl) => arrEl.trim());
            newArray = newArray.filter(Boolean);
            newArray = newArray.filter((arrEl) => !/\s/.test(arrEl));
            return newArray;
        },
        // After creation, init is initialized to start mixin the html
        _init: function () {
            // This will initialize toggle/hide the 1st time
            var mixinRoot = this;
            // observer: for each display-dependency, etc
            this.options.mixin.forEach(function (mixin, key) {
                var observers = mixin.observers;
                mixin.observers.forEach(function (observer) {
                    mixinRoot._update(observer, mixin.type, mixin.typeValue);
                });
            });
        },
        _update: function (observer, actionType, actionTypeValue) {
            // if dependency doesn't satisfy then hide element, if required no present don't mark it.
            var isMixinDisable = false;
            // OR Evaluator Stack
            var evalOR = [];
            // get the current value of the token
            Object.keys(observer.tokenValues).forEach(function (key) {
                var token = observer.tokenValues[key];
                var watched = $(observer.watched[key]);
                if (watched.length > 0) {
                    var currentValue =
                        $(watched).attr("type") === "checkbox" &&
                        !$(watched).attr("checked")
                            ? 0
                            : $(watched).attr("value");
                    // currentValue == 0 means has no value, therefore it must be hidden
                    if (currentValue.length == 0) {
                        isMixinDisable = true;
                    } else {
                        if (!(token.all == true)) {
                            // if no display-dependency-value = all values, otherwise check acceptable values
                            if (!token.values.includes(currentValue)) {
                                isMixinDisable = true;
                            }
                        }
                    }
                } else {
                    console.log(
                        "warning display-dependency/required id doesn't exists"
                    );
                }
                // Recollecting ORs
                if (observer.isOR) {
                    // Store it to evaluate as a whole
                    evalOR.push(isMixinDisable);
                    // Reset hidden for next dependency processing
                    isMixinDisable = false;
                }
            });
            if (observer.isOR) {
                var isFirstEval = true;
                // Reset hidden to start final OR tally.
                isMixinDisable = null;
                // Technique: if [true, false, true], stack pop() and eval with &&
                while (evalOR.length > 0) {
                    if (isFirstEval) {
                        isMixinDisable = evalOR.pop();
                        isFirstEval = false;
                    } else {
                        // Use AND && because mustApply == true only if all were true,
                        // but at least 1 false, will make it false satisfying OR
                        isMixinDisable = evalOR.pop() && isMixinDisable;
                    }
                }
            }
            if (isMixinDisable) {
                if (actionType === "hide-element") {
                    //$(observer.selector).closest('[data-group]').hide();
                    $(observer.selector)
                        .closest("[data-group]")
                        .attr("style", "display: none !important");
                } else if (actionType === "toggle-class") {
                    $(observer.selector).removeClass(actionTypeValue);
                    var emToRemove = $(observer.selector)
                        .closest("[data-group]")
                        .find("dt.label > em");
                    if (emToRemove.length > 0) {
                        $(observer.selector)
                            .closest("[data-group]")
                            .find("dt.label > em")
                            .remove();
                        $(observer.selector).blur();
                    }
                }
            } else {
                if (actionType === "hide-element") {
                    $(observer.selector).closest("[data-group]").show();
                } else if (actionType === "toggle-class") {
                    $(observer.selector).addClass(actionTypeValue);
                    var emToAdd = $(observer.selector)
                        .closest("[data-group]")
                        .find("dt.label > em");
                    if (emToAdd.length == 0) {
                        $(observer.selector)
                            .closest("[data-group]")
                            .find("dt.label")
                            .append("<em>*</em>");
                    }
                }
            }
        },
        notify: function (watchedData, observerIndex, key) {
            var mixin = this.options.mixin.get(key);
            this._update(
                mixin.observers[observerIndex],
                mixin.type,
                mixin.typeValue
            );
        },
        status: function () {
            return this.options;
        },
    });

    $("form.iceForm").microMixin();
    var SEO = new seoChecker();

    $(document).ready(function () {
        if (hash) {
            sessionStorage.markedItem = hash;
        }
        checkCookie();
        var ice = getCookie("ice"),
            iceComps = getCookie("iceComps");
        iceHover();
        resizeNodes();
        displayDisable();
        updateDisabledUI();
        if (ice == "off") {
            hideIce();
        } else {
            showIce();
        }
        if (iceComps == "off") {
            hideComps();
        } else {
            showComps();
        }
        $("html").attr("id", "ldse-show-ice");
        if (
            self === top ||
            sessionStorage.forceIce == true ||
            $.getUrlVar("forceIce") == "true"
        ) {
            // show/hide ICE menu
            addIceEvents(false);
            try {
                CKEDITOR.replaceByClassEnabled = false;
            } catch (e) {}
            $(document).keydown(function (e) {
                if (e.which == 73 && e.altKey) {
                    // alt + i
                    $("#ldse-ice-toggle").click();
                }
            });
            if (sessionStorage.ldseToolbar == "collapsed") {
                $("#ldse-toolbar-container").addClass("ldse-collapsed");
            }

            /* SEO CHECKER */
            SEO.updateToolbar();
            $("#ldse-seo-checker .ldse-seo-dropdown").click(function (e) {
                e.preventDefault();
                e.stopPropagation();
                return false;
            });
            $("#ldse-seo-rank-page").click(function (e) {
                e.preventDefault();
                e.stopPropagation();
                SEO.currentPageAnalyze();
                return false;
            });
            $("#ldse-seo-keyword").keypress(function (e) {
                // Enter pressed?
                if (e.which == 10 || e.which == 13) {
                    SEO.currentPageAnalyze();
                }
            });
            /* END OF SEO CHECKER */

            createLinkChecker();

            if (sessionStorage.linkChecking == "on") {
                setTimeout(function () {
                    linkChecker.start();
                }, 3000);
            } else {
                sessionStorage.linkChecking = "off";
                linkChecker.stop();
            }

            // if(sessionStorage.linkChecking == "off") {
            //     linkChecker.stop();
            // } else {
            //     sessionStorage.linkChecking = "on";
            //     linkChecker.start();
            // }

            $("#ldse-ice-toggle").click(function (e) {
                e.preventDefault();
                var ice = getCookie("ice");
                if (ice == "on") {
                    hideIce();
                } else {
                    showIce();
                }
                return false;
            });

            $("#ldse-component-toggle").click(function (e) {
                e.preventDefault();
                var iceComps = getCookie("iceComps");
                if (iceComps == "on") {
                    hideComps();
                } else {
                    showComps();
                }
                return false;
            });

            $("body").click(function (e) {
                closeOpenItems();
            });

            if (typeof s === "undefined" || s.pageName == "") {
                $("#omnitureOption").remove();
            }

            // show browser support message if IE
            // Detecting Internet Explorer More Effectively - http://msdn.microsoft.com/en-us/library/ms537509(v=vs.85).aspx
            if (
                navigator.appName
                    .toLowerCase()
                    .match("microsoft internet explorer") != null
            ) {
                if ($.cookie && $.cookie("ie-warning") != "off") {
                    $("#ice-overlay-header").show();
                    $(".notify-close").click(closeSupportMessage);
                }
            }
            // Collapse or expand the toolbar
            $("#ldse-toolbar-container.front .ldse-toolbar-toggle").on(
                "click",
                function (e) {
                    $("#ldse-toolbar-container.front").toggleClass(
                        "ldse-collapsed"
                    );
                    if (
                        $("#ldse-toolbar-container.front").hasClass(
                            "ldse-collapsed"
                        )
                    ) {
                        sessionStorage.ldseToolbar = "collapsed";
                    } else {
                        sessionStorage.ldseToolbar = "shown";
                    }
                    $(".ldse-alert").toggleClass("ldse-collapsed");
                }
            );
            // Display or hide the dropdown menu from the toolbar
            $("#ldse-toolbar-container.front .ldse-dropdownMenu-trigger").on(
                "click",
                function (e) {
                    e.stopPropagation();
                    var cur = $(this),
                        parent = cur.parent(".ldse-toolbar-item"),
                        list = parent.find("ul.ldse-menu").not("ul li ul");
                    closeOpenItems(list);
                    //$(".ldse-toolbar-item.ldse-open .ldse-dropdownMenu-trigger").not(cur).click();
                    list.toggle(0, function () {
                        parent.toggleClass("ldse-open");
                        list.css({
                            "overflow-y": "auto",
                            "overflow-x": "hidden",
                            "max-height":
                                window.innerHeight -
                                $("#ldse-toolbar").height() +
                                "px",
                        });
                    });
                }
            );
            var resizeTimer;
            var window_width = document.width;
            $(window)
                .on(
                    "resize.ldse-front orientationchange.ldse-front",
                    function (e) {
                        if (window_width != document.width) {
                            clearTimeout(resizeTimer);
                            resizeTimer = setTimeout(function () {
                                closeOpenItems();
                                window_width = document.width;
                            }, 30);
                        }
                        $(
                            "#ldse-toolbar-container.front .ldse-toolbar-item ul.ldse-menu"
                        )
                            .find("ul")
                            .css({
                                "overflow-y": "auto",
                                "overflow-x": "hidden",
                                "max-height": window.innerHeight + "px",
                            });
                    }
                )
                .trigger("resize.ldse-front");
            $("#ldse-toolbar-container.front #ldse-toolbar-buttons")
                .delay("slow")
                .show();
            // Fix ice-menus over lapping
            fixOverlappingIceMenus();
            // Show or hide dropdown with buttons
            $("#ldse-toolbar-container.front .ldse-button.dropdown-right").on(
                "click",
                function (e) {
                    var btn = $(this).closest("button");
                    listItem = btn.closest("li");
                    subList = listItem.find("ul");
                    if (btn.hasClass("depressed")) {
                        btn.removeClass("depressed");
                        subList.hide();
                    } else {
                        var otherBtn = $(
                            ".ldse-button.dropdown-right.depressed"
                        ).closest("button");
                        n = otherBtn.length;
                        if (n != 0) {
                            otherBtn.removeClass("depressed");
                            otherBtn.closest("li").find("ul").hide();
                        }

                        btn.addClass("depressed");
                        subList.show();
                        e.stopPropagation();

                        $(document).one("click", function () {
                            btn = $(
                                ".ldse-button.dropdown-right.depressed"
                            ).closest("button");
                            subList = btn.closest("li").find("ul");
                            btn.toggleClass("depressed");
                            subList.hide();
                        });
                    }
                }
            );
            // Change the Check Links Toggle button appropriately
            $("#ldse-check-links-toggle").on("click", function (e) {
                if (sessionStorage.linkChecking == "on") {
                    if ($(this).hasClass("ldse-icon-loop")) {
                        linkChecker.reset();
                    } else {
                        linkChecker.stop();
                    }
                } else {
                    linkChecker.reset();
                }
                e.stopPropagation();
            });
            //Jump to the first link of the type selected
            $(".ldse-link-count:not(.no-link)").on("click", function (e) {
                var target = $(this).data("target"),
                    index = 0;
                if (target == ".ldse-broken-link-preview") {
                    linkChecker.previewClicks =
                        linkChecker.previewClicks == linkChecker.hasPreview
                            ? 0
                            : linkChecker.previewClicks;
                    index = linkChecker.previewClicks;
                    linkChecker.previewClicks++;
                } else if (target == ".ldse-good-link") {
                    linkChecker.goodClicks =
                        linkChecker.goodClicks == linkChecker.hasGood
                            ? 0
                            : linkChecker.goodClicks;
                    index = linkChecker.goodClicks;
                    linkChecker.goodClicks++;
                } else if (target == ".ldse-unknown-link") {
                    linkChecker.unknownClicks =
                        linkChecker.unknownClicks == linkChecker.hasUnknown
                            ? 0
                            : linkChecker.unknownClicks;
                    index = linkChecker.unknownClicks;
                    linkChecker.unknownClicks++;
                }
                /* else if(target == ".ldse-broken-link-prod") {
                 linkChecker.prodClicks = linkChecker.prodClicks == linkChecker.hasProd ? 0 : linkChecker.prodClicks;
                 index = linkChecker.prodClicks;
                 linkChecker.prodClicks++;
                 } */

                var link = $(target).eq(index);

                if (link.length > 0) {
                    if (link.is(":hidden")) {
                        link = link.parents(":visible").first();
                    }
                    var position = link.offset().top - 60,
                        distance = Math.abs(window.pageYOffset - position),
                        rate = distance * 0.4;
                    rate = rate > 200 ? rate : 200;
                    $("html,body").animate(
                        {
                            scrollTop: position,
                        },
                        rate
                    );
                }
                return false;
            });
            permalinkValue.permalink = $("#permalink").val();
            var permaRoot = $("#permalink").data("root");
            var permalink = $("#permalink");
            var timer;
            if (permalink.length > 0 && permalink.is(":not([readonly])")) {
                $(":input[name=" + permalink.attr("generate-from") + "]").on(
                    "blur keyup",
                    function (e) {
                        permalinkUpdateFullUri($(this), true, permaRoot);
                    }
                );
                $("#permalink").on("blur keyup", function (e) {
                    timer && clearTimeout(timer);
                    timer = setTimeout(permalinkVerifyUrl(), 300);
                });
            }
        } else {
            $("#ldse-toolbar-container").hide();
        }
        $("dt h3.ldse-group-header").on("click", (e) => {
            $(e.currentTarget).closest("dl.ldse-section").toggleClass("closed");
            if (
                $(e.currentTarget).closest("dl.ldse-section").hasClass("closed")
            ) {
                $(e.currentTarget)
                    .parent()
                    .siblings()
                    .each((index, element, n) => {
                        $(element).attr("style", "display: none !important"); // jquery can't use `!important` in css()
                    });
            } else {
                $(e.currentTarget)
                    .parent()
                    .siblings()
                    .each((index, element, n) => {
                        $(element).css("display", "");
                    });
            }
        });
    });

    function checkCookie() {
        var ice = getCookie("ice"),
            iceComps = getCookie("iceComps");
        if (ice == "" && ice != null) {
            icey = "on";
            setCookie("ice", icey, 30);
        }
        if (iceComps == "" && iceComps != null) {
            comps = "off";
            setCookie("iceComps", comps, 30);
        }
    }

    function setCookie(name, value, days) {
        var d = new Date();
        d.setTime(d.getTime() + days * 24 * 60 * 60 * 1000);
        var expires = "expires=" + d.toGMTString();
        document.cookie = name + "=" + value + "; " + expires;
    }

    function getCookie(name) {
        var name = name + "=",
            cookie = document.cookie.split(";");
        for (var i = 0; i < cookie.length; i++) {
            var cook = cookie[i].trim();
            if (cook.indexOf(name) == 0)
                return cook.substring(name.length, cook.length);
        }
        return "";
    }

    function permalink_sanitize(value) {
        return value
            .replace(/[`~!@#\$%\^|''""\\\*\(\)\+={}\[\]:;'<>,\.\?\&]/g, "-")
            .replace(/[-]+/g, "-")
            .replace(/^-(.*)$/g, "$1")
            .replace(/(.*)-$/g, "$1");
    }

    function permalinkUpdateFullUri(source, verify, permaRoot) {
        "use strict";
        try {
            var path = source.val().toLowerCase();
            if (path.indexOf(permaRoot) !== 0) {
                path = permaRoot + path;
            }
            if (path[0] !== "/") {
                path = "/" + path;
            }
            if (path.indexOf(sharedPrefix) === -1) {
                path = sharedPrefix + path;
            }
            path = permalinkCleanPath(path);

            $("#permalink").val(path);
            $("#permalink").change();
            if (verify) {
                permalinkVerifyUrl();
            }
        } catch (e) {}
    }

    function permalinkCleanPath(path) {
        "use strict";
        return $.trim(path)
            .replace(/\ /g, "-")
            .replace(/(-)\1+/g, "-")
            .toLowerCase()
            .replace(/[`~!@#\$%\^|''""\\\*\(\)\+={}\[\]:;'<>,\.\?\&]/g, "");
    }

    function permalinkVerifyUrl() {
        "use strict";
        var permalink = $("#permalink");
        if (
            permalink.is(":not([readonly])") &&
            permalinkValue.permalink != $(permalink).val()
        ) {
            var fullUrl = $("#permalink").val();
            var isValid = false;
            $.ajax({
                url:
                    sharedPrefix +
                    "/ice/resources/ajax/validateUrl?" +
                    ICE.langParam(locale) +
                    "&url=" +
                    fullUrl,
                success: function (result) {
                    var delim = result.indexOf("\n");
                    var valid = result;
                    if (delim !== -1) {
                        valid = result.substring(0, delim);
                    }
                    //Clean Up any old Errors
                    if (jQuery("label[for='permalink']").filter(".error")) {
                        jQuery("label[for='permalink']")
                            .filter(".error")
                            .remove();
                    }

                    if (valid === "true") {
                        jQuery("#permalink").closest("dl").removeClass("error");
                        var icePostVars =
                            ICE.postVars[ICE.formVars.formName] ||
                            ICE.postVars[ICE.formVars.form] ||
                            ICE.postVars["form"];
                        icePostVars["uri"] = $("#permalink").val();
                        $("#action-save").prop("disabled", false);
                        $("#action-publish").prop("disabled", false);
                        isValid = true;
                    }
                    if (isValid === false) {
                        jQuery("#permalink").closest("dl").addClass("error");
                        jQuery("#permalink").removeClass("valid");
                        $("#action-save").prop("disabled", true);
                        $("#action-publish").prop("disabled", true);
                        jQuery("#permalink").after(
                            '<label for="permalink" class="error" id="permaLinkError">This URI is invalid or already in use.</label>'
                        );
                        //.append("<span class='error'>Unavailable</span>");
                    }
                },
                async: false,
                dataType: "text",
            });
            return isValid;
        } else {
            return true;
        }
    }

    function fixOverlappingIceMenus() {
        // Fix ice-menus over lapping
        var buttons = $(
            ".ldse-ice-menu-container:visible > .ldse-ice-status, .edit-resource:visible > img"
        ).sort(function (a, b) {
            var $a = $(a),
                $b = $(b),
                ao = $a.offset(),
                bo = $b.offset();
            if ($a.parent().hasClass("edit-resource")) return -1;
            else if ($b.parent().hasClass("edit-resource")) return 1;
            else if (ao.top < bo.top) return -1;
            else if (ao.top > bo.top) return 1;
            else if (ao.left < bo.left) return -1;
            else return 0;
        });

        for (var i = 0; i < buttons.length; i++) {
            var button = $(buttons[i]);
            var offset = button.offset();
            var height = button.outerHeight(false);
            var width = button.outerWidth(false);

            for (var j = i + 1; j < buttons.length; j++) {
                var button2 = $(buttons[j]);
                var offset2 = button2.offset();
                var w = button2.outerWidth(false);
                var h = button2.outerHeight(false);
                var currentTop = button2.parent().css("top");
                if (
                    boxesIntersect(
                        offset.left,
                        offset.top,
                        height,
                        width,
                        offset2.left,
                        offset2.top,
                        w,
                        h
                    )
                ) {
                    if (currentTop == "auto") {
                        button2.parent().css("top", height + 10 + "px");
                    } else {
                        button2.parent().css("top", "+=" + (height + 10));
                    }
                }
            }
        }
    }

    function createLinkChecker() {
        linkChecker = new linkChecker();
    }

    function boxesIntersect(ax, ay, aw, ah, bx, by, bw, bh) {
        return (
            Math.abs(ax - bx) * 2 < aw + bw && Math.abs(ay - by) * 2 < ah + bh
        );
    }

    function closeOpenItems(notItem) {
        $("#ldse-ice-menu-clone").remove();
        $(".workflow-table.active").not(notItem).removeClass("active");
        $(
            "#ldse-toolbar-container.front .ldse-toolbar-item.ldse-open ul.ldse-menu"
        )
            .not(notItem)
            .hide()
            .parents(".ldse-toolbar-item.ldse-open")
            .removeClass("ldse-open");
    }

    function closeSupportMessage(evt) {
        evt.preventDefault();
        evt.stopPropagation();
        if ($.cookie) {
            $.cookie("ie-warning", "off");
        }
        $("#ice-overlay-header").hide();
    }

    function addIceEvents(ajax) {
        var controls = ".ldse-ice-menu-container";
        if (ajax) {
            controls += ".ajax";
        }

        $(controls + " .ldse-ice-status").click(function (event) {
            var self = $(this);
            var parent = self.parent();
            closeOpenItems(parent);
            //parent.toggleClass("ldse-open");
            var offset = self.offset();
            var clone = parent.clone();
            if (offset.left < 208) {
                clone = clone.addClass("ldse-menu-left");
            }
            clone
                .addClass("ldse-open ldse-absolute")
                .attr("id", "ldse-ice-menu-clone")
                .click(function (event) {
                    event.preventDefault();
                    event.stopPropagation();
                    closeOpenItems();
                })
                .appendTo("body")
                .offset(offset);
            clone.find("ul.ldse-menu").click(function (e) {
                e.stopPropagation();
            });
            //$('.ldse-ice-menu-container.ldse-open').not(parent).removeClass('ldse-open');
            event.stopPropagation();
            event.preventDefault();
            return false;
        });
        //&& $(!'.workflow-table').hasClass('active')
        if (ajax) {
            $(controls).removeClass("ajax");
        }
        ICE.markItem();
    }

    function hideIce() {
        /*      $("html").removeAttr("id");*/
        $("body").removeClass("ice");
        if (getCookie("iceComps") == "on") {
            $("body").find("ice-div:not(.ice-component)").hide();
            showComps();
            /*            var components = $('body').find('ice-div.ice-component');
             components.parent().show();*/
        } else {
            $("body").find("ice-div:not(.ice-component)").hide();
        }
        $("body")
            .find("a.edit-resource")
            .attr("style", "display:none !important;");
        setCookie("ice", "off", 30);
        $(".resourceIce.html5editable").removeAttr("contenteditable");
    }

    function showIce() {
        /*      $("html").attr("id", "ldse-show-ice");*/
        $("body").addClass("ice");
        $("body").find("ice-div:not(.ice-component)").show();
        setCookie("ice", "on", 30);
        $("body")
            .find("a.edit-resource")
            .attr("style", "display:inline !important;");
        $(".resourceIce.html5editable").attr("contenteditable", "true");
        fixOverlappingIceMenus();
    }

    function hideComps() {
        /*      $("html").removeAttr("id");*/
        $("body").removeClass("iceComps");
        setCookie("iceComps", "off", 30);
        if (!$("body").hasClass("ice")) {
            $("body").find("ice-div").hide();
        } else {
            var components = $("body").find("ice-div.ice-component");
            components.hide();
        }
    }

    function getUrlParameter(sParam) {
        var sPageURL = decodeURIComponent(window.location.search.substring(1)),
            sURLVariables = sPageURL.split("&"),
            sParameterName,
            i;

        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split("=");

            if (sParameterName[0] === sParam) {
                return sParameterName[1] === undefined
                    ? true
                    : sParameterName[1];
            }
        }
    }
    function showComps() {
        /*      $("html").attr("id", "ldse-show-ice");*/
        $("body").addClass("iceComps");
        var components = $("body").find("ice-div.ice-component");
        components.show();
        setCookie("iceComps", "on", 30);
        /*        if ( !$('body').hasClass('ice') ) {
         components.parent().show();
         }*/
        fixOverlappingIceMenus();
    }

    function permalink_sanitize(value) {
        return value
            .replace(/[!@#\$%\^&\*\(\)\+\\|{}\[\]\/\.\,\<\>=:; ]/g, "-")
            .replace(/[-]+/g, "-")
            .replace(/^-(.*)$/g, "$1")
            .replace(/(.*)-$/g, "$1");
    }

    function permalink_stripHTML(html) {
        var tmp = document.createElement("DIV");
        tmp.innerHTML = html;
        return tmp.textContent || tmp.innerText;
    }

    function permalink_generate(source_field_id, permalink_field_id, gen_root) {
        var sourceInput = $("#" + source_field_id);
        var permalinkInput = $("#" + permalink_field_id);
        if (sourceInput != null && permalinkInput != null) {
            permalinkInput.val(
                (
                    gen_root +
                    permalink_sanitize(permalink_stripHTML(sourceInput.val()))
                ).toLowerCase()
            );
        }
        permalinkInput.blur();
    }

    function permalink_generate_from_ck(
        source_field_id,
        permalink_field_id,
        gen_root
    ) {
        var sourceInput = CKEDITOR.instances[source_field_id]
            .getData()
            .replace("\n", "")
            .replace(".", "");
        var permalinkInput = $("#" + permalink_field_id);
        if (sourceInput != null && permalinkInput != null) {
            permalinkInput.val(
                (
                    gen_root +
                    permalink_sanitize(permalink_stripHTML(sourceInput))
                ).toLowerCase()
            );
        }

        permalinkInput.blur();
    }

    /* Hover to know what ice item goes with what content piece */
    function iceHover() {
        $("ice-div .ldse-ice-menu-container a").hover(
            function () {
                var id = $(this).attr("data-target");
                //  $('[data-gear=' + id + ']').css('background-color','#00BAD3')
            },
            function () {
                var id = $(this).attr("data-target");
                $("[data-gear=" + id + "]").css("background-color", "");
            }
        );
        $("ice-div").each(function () {
            var id = guid();
            $(this).find("a").attr("data-target", id);
            $(this).parent().attr("data-gear", id);
        });
    }

    function guid() {
        function s4() {
            return Math.floor((1 + Math.random()) * 0x10000)
                .toString(16)
                .substring(1);
        }
        return (
            s4() +
            s4() +
            "-" +
            s4() +
            "-" +
            s4() +
            "-" +
            s4() +
            "-" +
            s4() +
            s4() +
            s4()
        );
    }
    function permalink_validate() {
        "use strict";
        var locale = $("#locale").val();
        var fullUrl = $("#fullUri").val();
        var validateUrl = $("#permalink").val();
        var isValid = false;
        $.ajax({
            url: validateUrl + "&url=" + fullUrl,
            success: function (result) {
                var delim = result.indexOf("\n");
                var valid = result;
                if (delim !== -1) {
                    valid = result.substring(0, delim);
                }

                if (valid === "true") {
                    jQuery("#fullUri").closest("dl").removeClass("error");
                    isValid = true;
                }
                if (isValid === false) {
                    jQuery("#fullUri").closest("dl").addClass("error");
                    //.append("<span class='error'>Unavailable</span>");
                }
            },
            async: false,
            dataType: "text",
        });
        return isValid;
    }

    // RICE
    var RICE = {
        HIDDEN_RESOURCES: [],
        // Populated by each page
        CURRENT_URI: "",
        // Populated by each page
        HIDE_TITLE: false,
        SEO_TITLE: "",
        onChange: function () {
            var anyEmptyValue = false;
            $(".rice-text").each(function () {
                var hasEmptyValue = !this.value || this.value === "";
                var hasErrorText =
                    $(this).parent().children("span.error").length > 0;

                // Add or remove the error text
                if (hasEmptyValue) {
                    if (!hasErrorText) {
                        $(this)
                            .parent()
                            .append("<span class='error'>Required</span>");
                    }
                } else {
                    if (hasErrorText) {
                        $(this).parent().children("span.error").remove();
                    }
                }
                anyEmptyValue = anyEmptyValue || hasEmptyValue;
            });
            if (anyEmptyValue) {
                $("#saveResource").attr("disabled", "disabled");
            } else {
                $("#saveResource").removeAttr("disabled");
            }
        },
        editResource: function (lang, bundle, key) {
            var currentPage = decodeURIComponent(document.location.pathname);
            var path =
                sharedPrefix +
                "/ice/resources/ajax/resource/editResourceForm?lang=eng";

            if ($(".ldseForm").length > 0) {
                $(".ldseForm").remove();
            }
            $('<div class="ldseForm"></div>').appendTo("body");
            $.ajax({
                type: "POST",
                url: path,
                data: {
                    locale: lang,
                    bundle: bundle,
                    key: key,
                    currentPage: currentPage,
                    uri: RICE.CURRENT_URI,
                },
                success: function (html) {
                    $(".ldseForm")
                        .html(html)
                        .append(
                            $(
                                '<link rel="stylesheet" media="screen" type="text/css" href="' +
                                    sharedPrefix +
                                    '/ice/resources/styles/screen.css"/>'
                            )
                        )
                        .dialog({
                            dialogClass: "ldseForm ldse-modal",
                            maxHeight: windowHeight(),
                            width: "90%",
                            zIndex: 4000,
                            draggable: true,
                            modal: true,
                            title: "Resource Editing",
                            close: function () {
                                $(".ldseForm").remove().dialog("close");
                            },
                        });
                },
            });
        },
        editHiddenResources: function (lang) {
            if (RICE.HIDDEN_RESOURCES.resources) {
                var bundles = [];
                var keys = [];
                $.each(
                    RICE.HIDDEN_RESOURCES.resources.resource,
                    function (key, value) {
                        bundles.push(escape(value.bundle));
                        keys.push(escape(value.key));
                    }
                );
                var pageUri = getUrlParameter("uri");
                var currentPage = decodeURIComponent(
                    document.location.pathname
                );
                var path =
                    sharedPrefix +
                    "/ice/resources/ajax/resource/editResourceForm?lang=eng";
                if ($(".ldseForm").length > 0) {
                    $(".ldseForm").remove();
                }
                $('<div class="ldseForm"></div>').appendTo("body");
                $.ajax({
                    type: "POST",
                    url: path,
                    data: {
                        locale: lang,
                        bundle: bundles.join(","),
                        key: keys.join(","),
                        currentPage: currentPage,
                        uri: RICE.CURRENT_URI,
                        hideTitle: RICE.HIDE_TITLE,
                        seoTitle: RICE.SEO_TITLE,
                        pageUri: pageUri,
                    },
                    success: function (html) {
                        $(".ldseForm")
                            .html(html)
                            .append(
                                $(
                                    '<link rel="stylesheet" media="screen" type="text/css" href="' +
                                        sharedPrefix +
                                        '/ice/resources/styles/screen.css"/>'
                                )
                            )
                            .dialog({
                                dialogClass: "ldseForm ldse-modal",
                                height: windowHeight(),
                                maxHeight: windowHeight(),
                                maxWidth: 1000,
                                width: "90%",
                                zIndex: 4000,
                                draggable: true,
                                title: "Resource Editing",
                                modal: true,
                                close: function () {
                                    $(".ldseForm").remove().dialog("close");
                                },
                            });
                        $(".ldse-show-seoT-info").click(function () {
                            $(".ldse-infoT-text").toggle();
                        });
                        $(".ldse-show-seoD-info").click(function () {
                            $(".ldse-infoD-text").toggle();
                        });
                        var seoTitle = {},
                            seoUrl = $("form").find(
                                "table.iceEditor tr td textarea"
                            )[0],
                            seoDesc = $("form").find(
                                "table.iceEditor tr td textarea"
                            )[0],
                            titleCount = "",
                            descCount = "";
                        if (RICE.HIDE_TITLE !== "true") {
                            (seoTitle = $("form").find(
                                "table.iceEditor tr td input"
                            )[2]),
                                (titleCount = 70 - $(seoTitle).val().length),
                                (descCount = 156 - $(seoDesc).val().length);
                            $(".ldse-seo-title-message").append(
                                "Title display in search engines is limited to 70 chars, <span class='ldse-seo-title-number'>" +
                                    titleCount +
                                    "</span> chars left."
                            );
                            if (titleCount >= 0) {
                                $(".ldse-seo-title-number").css(
                                    "color",
                                    "green"
                                );
                            } else {
                                $(".ldse-seo-title-number").css("color", "red");
                            }
                            $(".ldse-seo-title").append(
                                $(seoTitle).val().substring(0, 70)
                            );
                        } else {
                            $(".ldse-seo-title-message").append(
                                "This field is read only for this page."
                            );
                        }
                        $(".ldse-seo-desc-message").append(
                            "The meta description will be limited to 156 chars, <span class='ldse-seo-desc-number'>" +
                                descCount +
                                "</span> chars left."
                        );
                        if (descCount >= 0) {
                            $(".ldse-seo-desc-number").css("color", "green");
                        } else {
                            $(".ldse-seo-desc-number").css("color", "red");
                        }
                        $(".ldse-seo-description").append(
                            $(seoDesc).val().substring(0, 156)
                        );
                        $(seoTitle).on("keyup blur", function () {
                            var newCount = 70 - $(seoTitle).val().length;
                            $(".ldse-seo-title-number").text(newCount);
                            if (newCount >= 0) {
                                $(".ldse-seo-title-number").css(
                                    "color",
                                    "green"
                                );
                            } else {
                                $(".ldse-seo-title-number").css("color", "red");
                            }
                            $(".ldse-seo-title").text(
                                $(seoTitle).val().substring(0, 70)
                            );
                        });
                        $(seoDesc).on("keyup blur", function () {
                            var newCount = 156 - $(seoDesc).val().length;
                            $(".ldse-seo-desc-number").text(newCount);
                            if (newCount >= 0) {
                                $(".ldse-seo-desc-number").css(
                                    "color",
                                    "green"
                                );
                            } else {
                                $(".ldse-seo-desc-number").css("color", "red");
                            }
                            $(".ldse-seo-description").text(
                                $(seoDesc).val().substring(0, 156)
                            );
                        });
                    },
                });
            } else {
                alert("No hidden text on this page.");
            }
        },
    };

    iRICE = {
        delay: 600, //only fire save after an adequate delay
        time: "", //saves time pointer, so it can be cleared
        setup: function () {
            //add listeners to all html5 editable rice strings
            $("#ldse-show-ice").on("keyup", ".html5editable", function (e) {
                clearTimeout(iRICE.time);
                var $this = $(this);

                var saveFunction = function () {
                    iRICE.save($this);
                };

                iRICE.time = setTimeout(saveFunction, iRICE.delay);
                e.stopPropagation();
            });
            $(".html5editable").each(function () {
                //if parent is an a tag, we need to prevent it from linking out, but only when ice is enabled
                var $this = $(this);
                $this.click(function (e) {
                    var src = $(e.target);
                    if (
                        $("html").attr("id") == "ldse-show-ice" &&
                        !e.shiftKey
                    ) {
                        e.preventDefault();
                    } else if (src.is("a")) {
                        window.location = src.attr("href");
                        e.preventDefault();
                    } else {
                        var a = $this.closest("a");
                        if (a.length > 0) {
                            window.location = a.attr("href");
                            e.preventDefault();
                        }
                    }
                });
            });
        },
        save: function ($this) {
            //on keypress save the new value up to the server
            var newValue = $this.text();
            $.ajax({
                type: "POST",
                url: "/ice/resources/ajax/resource/updateInlineResource",
                dataType: "json",
                data: {
                    lang: $this.data("lang"),
                    locale: $this.data("locale"),
                    country: $this.data("country"),
                    currentPage: $this.data("currentPage"),
                    currentUri: $this.data("currentUri"),
                    bundle: $this.data("bundle"),
                    key: $this.data("key"),
                    newValue: $this.html(),
                },
                success: function (data, status, request) {
                    if (data.data === "success") {
                        //find and update any other strings that match locale bundle and
                        $(
                            "span[data-locale = '" +
                                $this.data("locale") +
                                "'][data-bundle= '" +
                                $this.data("bundle") +
                                "'][data-key= '" +
                                $this.data("key") +
                                "']"
                        )
                            .not($this)
                            .text(newValue);
                    } else {
                        alert(data.message);
                    }
                },
                error: function (request, status, error) {
                    //need better api for saving, with messages.
                    //no rights, failed save, emtpy text...
                    alert(
                        "There was an error updating the resource. Refresh the page and try again."
                    );
                },
            });
        },
    };
    $(function () {
        iRICE.setup();
    });

    // Lang/Locale
    function getUrlParams() {
        var vars = [],
            hash;
        var url = window.location.href;
        url = url.split("#")[0];
        var hashes = url.slice(url.indexOf("?") + 1).split("&");
        for (var i = 0; i < hashes.length; i++) {
            hash = hashes[i].split("=");
            if (hash.length > 0) {
                vars.push(hash[0]);
                vars[hash[0]] = hash[1];
            }
        }
        return vars;
    }

    function getLocaleFromParams() {
        var urlParams = getUrlParams();
        var params = "";
        if (urlParams.country !== "" && urlParams.country !== undefined) {
            params = urlParams.lang + "&country=" + urlParams.country;
        } else {
            params = urlParams.lang;
        }
        return params;
    }

    function splitLocale(locale) {
        if (locale != undefined) {
            var split = locale.split("-");
            var lang = "";
            if (split.length > 1) {
                lang = split[0] + "&country=" + split[1];
            } else {
                lang = locale;
            }
            return lang;
        } else {
            return lang;
        }
    }

    function getLang(locale) {
        var split = locale.split("-");
        var lang = "";
        if (split.length > 1) {
            lang = split[0];
        } else {
            lang = locale;
        }
        return lang;
    }

    function getLangForCloning(locale) {
        var split = locale.split(" | ");
        var lang = "";
        if (split.length > 1) {
            lang = split[split.length - 1];
        } else {
            lang = locale;
        }
        return lang;
    }

    function getCountry(locale) {
        var split = locale.split("-");
        var country = "";
        if (split.length > 1) {
            country = split[1];
        } else {
            country = "";
        }
        return country;
    }

    function getCountryForCloning(locale) {
        var split = locale.split(" | ");
        var country = "";
        if (split.length > 1) {
            country = split[0];
        } else {
            country = "";
        }
        return country;
    }

    function getCurrentUrl() {
        var url = document.location.toString();
        var index = url.lastIndexOf("#");
        if (index == -1) {
            index = url.length;
        }
        url = url.substring(0, index);
        return url;
    }

    function fixNullInput() {
        $("input.dynamicInput").each(function () {
            if ($(this).val() === "") {
                $(this).val(" ");
            }
        });
    }

    function teaserSearch(type, page, currentPage, pageLocation, lang) {
        var path =
            sharedPrefix +
            "/ice/resources/ajax/browse?lang=" +
            splitLocale(lang) +
            "&type=teaser&teaserType=" +
            type +
            "&page=" +
            page +
            "&currentPage=" +
            currentPage +
            "&pageLocation=" +
            pageLocation;
        window.open(
            path,
            "teaser_browse",
            "width=980,height=378,toolbar=no,status=no,menubar=no,toolbar=no"
        );
    }

    function getCurrentPage() {
        return decodeURIComponent(window.location.pathname);
    }

    function inlineTeaser(editor) {
        CKEDITOR.currentInstanceName = editor.name;
        window.open(
            sharedPrefix +
                "/ice/resources/ajax/browse?lang=" +
                getLocaleFromParams() +
                "&currentPage=" +
                getCurrentPage() +
                "&type=teaser&source=wysiwyg",
            "teaser_browse",
            "width=1000,height=378,toolbar=no,status=no,menubar=no,toolbar=no"
        );
    }

    function pdfBrowse(editor) {
        CKEDITOR.currentInstanceName = editor.name;
        window.open(
            sharedPrefix +
                "/ice/resources/ajax/browse?lang=" +
                getLocaleFromParams() +
                "&currentPage=" +
                getCurrentPage() +
                "&type=pdf&source=wysiwyg",
            "pdf_browse",
            "width=1024,height=378,toolbar=no,status=no,menubar=no"
        );
    }

    function embedVideo(editor) {
        CKEDITOR.currentInstanceName = editor.name;
        window.open(
            sharedPrefix +
                "/ice/resources/ajax/browse?lang=" +
                getLocaleFromParams() +
                "&currentPage=" +
                getCurrentPage() +
                "&type=video&source=wysiwyg",
            "teaser_browse",
            "width=1000,height=378,toolbar=no,status=no,menubar=no,toolbar=no"
        );
    }

    function embedAudio(editor) {
        CKEDITOR.currentInstanceName = editor.name;
        window.open(
            sharedPrefix +
                "/ice/resources/ajax/browse?lang=" +
                getLocaleFromParams() +
                "&currentPage=" +
                getCurrentPage() +
                "&type=audio&source=wysiwyg",
            "teaser_browse",
            "width=1000,height=378,toolbar=no,status=no,menubar=no,toolbar=no"
        );
    }

    function embedBrightCove(editor) {
        CKEDITOR.currentInstanceName = editor.name;
        window.open(
            sharedPrefix +
                "/ice/resources/ajax/browse?lang=" +
                getLocaleFromParams() +
                "&currentPage=" +
                getCurrentPage() +
                "&type=brightcove&source=wysiwyg",
            "teaser_browse",
            "width=1000,height=378,toolbar=no,status=no,menubar=no,toolbar=no"
        );
    }

    function embedBrightCoveGallery(editor) {
        CKEDITOR.currentInstanceName = editor.name;
        window.open(
            sharedPrefix +
                "/ice/resources/ajax/browse?lang=" +
                getLocaleFromParams() +
                "&currentPage=" +
                getCurrentPage() +
                "&type=gallery&source=wysiwyg",
            "teaser_browse",
            "width=1000,height=378,toolbar=no,status=no,menubar=no,toolbar=no"
        );
    }

    function windowHeight() {
        if (navigator.appName.indexOf("Microsoft") != -1) {
            return document.documentElement.clientHeight - 150;
        } else {
            return window.innerHeight - 200;
        }
    }

    function updateUriTitle(titleId, uriTitleId) {
        var titleTxt = $("#" + titleId).val();
        var uriTitleTxt = titleTxt.replace(/\ /g, "-").toLowerCase();
        uriTitleTxt = uriTitleTxt.replace(
            /[`~!@#\$%\^\*\(\)\+={}\[\]:;'<>,\.\?\&]/g,
            ""
        );
        $("#" + uriTitleId).val(uriTitleTxt);
    }

    // New Window plugin
    (function (jQuery) {
        jQuery.extend(jQuery, {
            defined: function (value) {
                return typeof value !== typeof undefined;
            },
            empty: function (value) {
                return (
                    !jQuery.defined(value) ||
                    value === null ||
                    (typeof value === "string" && value === "")
                );
            },
            getPath: function (url) {
                return url
                    ? jQuery("<a/>")
                          .attr("href", url)[0]
                          .pathname.replace(/^[^\/]/, "/")
                    : "";
            },
            urlVars: [],
            getUrlVars: function () {
                if ($.urlVars.length == 0) {
                    var hashes = window.location.search.substr(1).split("&");
                    for (var i = 0; i < hashes.length; i++) {
                        hash = hashes[i].split("=");
                        $.urlVars.push(hash[0]);
                        $.urlVars[hash[0]] = hash[1];
                    }
                }
                return $.urlVars;
            },
            getUrlVar: function (name) {
                return $.getUrlVars()[name];
            },
            newWindow: function (url, options) {
                options = options || {};
                var name = options.name || "_blank";
                var w = window.open(url, name);
                if (window.focus) {
                    w.focus();
                }
                return w;
            },
        });
    })(jQuery);

    /*  Returns the parent id, the index of the nested component
        in  relation to its siblings, and a status of whether it is a nested component. */
    function getNestedComponentData(el, items) {
        var result = false;
        var nestedParentId = "";
        var nestedComponentIdx = -1;
        try {
            var dataId = $(el).attr("data-target"); // get the unique/random id
            var findIt = `.ldse-status-disable.[data-target='${dataId}']`; // build the selector
            var nestedComponent = $(findIt)[0]; // find the nested component
            // the following traverses the diverse divs/classes and will return data when it is a
            // nested component, otherwise it will fail to find it.
            if ($(el).hasClass("ldse-status-disable")) {
                var parentId = $(nestedComponent)
                    .parents("[data-parent-ref]")
                    .attr("data-parent-ref");
                if (parentId.length > 0 && parentId !== items[0].ids[0]) {
                    nestedParentId = parentId;
                    result = true;
                }
            } else {
                nestedParentId = $(nestedComponent)
                    .parents(".lead-sub-component")
                    .parents(".sub-component")
                    .parents(".content-grouping")
                    .attr("data-id");
                nestedComponentIdx = $(nestedComponent)
                    .parents(".sub-component")
                    .find(".lead-sub-component")
                    .index($(nestedComponent).parents(".lead-sub-component"));
            }
            if (
                nestedParentId !== undefined &&
                nestedParentId.length > 0 &&
                nestedComponentIdx > -1
            )
                result = true;
        } finally {
            return {
                nestedParentId: nestedParentId,
                nestedId: items[0].ids[0],
                nestedComponentIdx: nestedComponentIdx,
                isNestedComponent: result,
            };
        }
    }

    /* Updates the icon/text of ICE Menu to Enable when component has status disabled */
    function updateDisabledUI() {
        var iceMenu = $(".component-status-disabled").closest(
            ".title-component, .lead-sub-component"
        );
        iceMenu.each(function (index) {
            var disabledButton = $(this).find(".ldse-status-disable");
            $(disabledButton).text("Enable");
            $(disabledButton).removeClass("ldse-icon-unpublish");
            $(disabledButton).addClass("ldse-icon-star");
        });
    }

    /* Resizes node/square containers to improve usability when minimal visualization is required by
       reducing their sizes */
    function resizeNodes() {
        $("region-div .nodeContainer .node").addClass("node-resize-outside"); // Outside square box
        $(".nodeContainer .node-content header img").addClass(
            "node-resize-inside"
        ); // Inside gray square box
        $(".nodeContainer .node-content header div").addClass(
            "node-resize-inside"
        );
        $("region-div .nodeContainer .node-content header + .content").addClass(
            "node-resize-label"
        ); // Bottom squares
        $(
            "region-div .nodeContainer .node-content header + section .content"
        ).addClass("node-resize-label");
    }

    /* Displays disabled tag */
    function displayDisable() {
        $("[data-enable]").each(function (index) {
            var span = $(this).find("span.component-status-enabled");
            if ($(this).attr("data-enable") === "disabled") {
                $(span).removeClass("component-status-enabled");
                $(span).addClass("component-status-disabled");
                $(span).html("Disabled");
                if ($(this).attr("data-parent-ref") !== "")
                    $("<br/>").insertBefore(span);
            } else {
                $(span).remove();
            }
        });
    }

    /*  Returns the index(position) of the component to remove or disable. If first component then idx == 0
        Constraining by using "ldse:remove-from-page", "ldse:disable-from-page" action to verify that this work only on removal or disable
        el == this (So we can get the ldse:remove-from-page that triggered the deletion or disable)
        It will return -1 for removal/disable behaviour of components from the right side (sub-components/nested components)
        It will return -2 if not found or error */
    function indexOfCompToRemove(action, el) {
        var idx = -2;
        if (
            el !== undefined &&
            (action == "ldse:remove-from-page" ||
                action == "ldse:disable-from-page")
        ) {
            // Building a jquery selector of the form: $("li[data-gear='2f...8df']")
            // The ldse:remove-from-page/disable has a data-target that should match the
            //  <li data-gear> holding the component
            var componentDataTarget = $(
                "li[data-gear='" + $(el).attr("data-target") + "']"
            );
            // We get the index of that component by combining several selectors.
            var idx = $(
                "div.ldse-section--body > section > div.content-grouping > ul.nodeContainer li.node"
            ).index(componentDataTarget);
            if (idx < 0) {
                idx = -1; // Removal requested for nested component of the right panel
            }
        }
        return idx;
    }

    /*
          Gets the list of components which depend on the component to be deleted, and displays
          them inside the modal dialog window of confirmation for deletion to alert the user.
     */
    function showComponentDependencies(action, uri, locale, items, pageUri) {
        if (action.indexOf("delete") != -1) {
            var compID = items[0].ids[0];
            var compName = items[0].name;
            $("div#alertModal form .ldse-form-buttons").append(
                '<div class="alert-modal-description"/>'
            );
            $("div.alert-modal-description").append(
                '<style type="text/css">.alert-modal-description{font-size:65%}.alert-modal-description ul{list-style-type: none;}</style>'
            );
            var url =
                sharedPrefix +
                "/ice/resources/ajax/getDependencies?lang=" +
                locale;
            var data = {
                action: action,
                uri: uri,
                locale: locale,
                pageUri: pageUri,
                compID: compID,
                compName: compName,
            };
            $.ajax({
                type: "POST",
                url: url,
                dataType: "json",
                cache: false,
                data: data,
                success: function (data) {
                    if (data.length > 0) {
                        var dependencies =
                            "<h3>Components depending on this component:</h3><ul>";
                        data.forEach(function (item) {
                            dependencies += "<li>" + item + "</li>";
                        });
                        dependencies += "</ul>";
                        $("div.alert-modal-description").append(dependencies);
                    }
                },
                error: function () {
                    console.log("Querying component dependencies failed");
                },
            });
        }
    }

    /*
     * Gets the parentId of component and true/false if present to be utilized by ldse:delete
     */
    function getParentData(rawId) {
        var isChildComponent = false;
        var parentId = "";
        var id = `.${rawId}`;

        var regexObj = new RegExp("\\s*(\\d+-\\D{3})");
        var regexResult = null;
        var parentContainer = null;

        if ($(id).parents(".lead-sub-component").length > 0) {
            // try lead-sub-component
            parentContainer = $(id)
                .parents(".lead-sub-component")
                .parents(".sub-component")
                .parents(".sub-component")
                .find(".ice-media-block")
                .find(".ldse-ice-menu-container");
            if (parentContainer.length > 0) {
                if ($(parentContainer).attr("class") != undefined) {
                    regexResult = $(parentContainer)
                        .attr("class")
                        .match(regexObj);
                    if (regexResult != null) {
                        parentId = regexResult[1];
                        isChildComponent = true;
                    }
                }
            }
        } else {
            // try sub-component
            parentContainer = $(id)
                .parents(".sub-component")
                .parents(".content-grouping");
            if (parentContainer.length > 0) {
                if ($(parentContainer).attr("data-id") != undefined) {
                    parentId = $(parentContainer).attr("data-id");
                    isChildComponent = true;
                }
            }
        }

        return { parentDataId: parentId, isChildComponent: isChildComponent };
    }

    var ACT = {
        ACTIONS: {},
        TRIES: {},
        ITEMS: {},
        //Holds standard items used from the TYPE property
        DYNAMIC_ITEMS: {},
        //Hold all dynamic items.
        CLEAR_URLS: [],
        RELOAD: "",
        TYPE: {
            customPage: {
                name: "Custom Page (page.xml)",
                folder: "customPage",
                id: "staticCustomPage",
                ids: [],
            },
            rewriteRule: {
                name: "Rewrite Rule",
                folder: "rewriteRule",
                id: "staticRewriteRule",
                ids: [],
            },
            resource: {
                name: "Resources",
                folder: "resource",
                id: "staticResource",
                ids: [],
            },
            navigation: {
                name: "Navigation",
                folder: "navigation",
                id: "staticNavigation",
                ids: [],
            },
            jericho: {
                name: "Jericho Menu",
                folder: "jericho",
                id: "staticJericho",
                ids: [],
            },
            cache: {
                name: "Clear Cache",
                folder: "cache",
                id: "staticCache",
                ids: [],
            },
            translation: {
                name: "Translation",
                folder: "translation",
                id: "staticTranslation",
                ids: [],
            },
        },
        IS_TEMPLATE: false,
        MODAL_TITLE: "Publishing",
        IMAGE: {
            PUBLISHING: "ldse-publish-dialog ui-finder-loader",
            SUCCESS: "ldse-publish-dialog ldse-icon-check2",
            ERROR: "ldse-publish-dialog ldse-icon-ko-warning",
        },
        addItems: function (items) {
            //pass in array of strings ["customPage", "rewriteRule"]
            "use strict";
            for (var i = 0; i < items.length; i++) {
                ACT.addItem(items[i]);
            }
        },
        addItem: function (item) {
            "use strict";
            if (
                !ACT.ITEMS.hasOwnProperty(item) &&
                ACT.TYPE.hasOwnProperty(item)
            ) {
                ACT.ITEMS[item] = ACT.TYPE[item];
            }
        },
        addDynamicItems: function (items) {
            //pass in array of objects [{id:"someType", ids:"12345-eng"}]
            "use strict";
            for (var key in items) {
                if (items.hasOwnProperty(key)) {
                    var item = items[key];
                    ACT.addDynamicItem(item.name, item.ids);
                }
            }
        },
        addDynamicItem: function (name, ids) {
            "use strict";
            var id = name.replace(/[^a-zA-Z]+/g, "_");
            if (!$.isArray(ids)) {
                ids = [ids];
            }
            if (ACT.DYNAMIC_ITEMS.hasOwnProperty(id)) {
                $.each(ACT.DYNAMIC_ITEMS[id].ids, function (index, item) {
                    if (ACT.DYNAMIC_ITEMS[id].ids.indexOf(item) == -1) {
                        ACT.DYNAMIC_ITEMS[id].ids.push(item);
                    }
                });
            } else {
                ACT.DYNAMIC_ITEMS[id] = {
                    name: name,
                    folder: "dynamic-item",
                    id: id,
                    ids: ids,
                };
            }
        },
        getDynamicItems: function () {
            "use strict";
            var items = [];
            for (var key in ACT.DYNAMIC_ITEMS) {
                if (ACT.DYNAMIC_ITEMS.hasOwnProperty(key)) {
                    items.push(ACT.DYNAMIC_ITEMS[key]);
                }
            }
            return items;
        },
        getItems: function () {
            "use strict";
            var items = [];
            for (var key in ACT.ITEMS) {
                if (ACT.ITEMS.hasOwnProperty(key)) {
                    items.push(ACT.ITEMS[key]);
                }
            }
            return items;
        },
        getItem: function (response) {
            "use strict";
            var ids = [];
            if (response.ids && response.ids !== "") {
                ids = response.ids.split(",");
            }
            return {
                name: response.name,
                folder: response.folder,
                id: response.id,
                ids: ids,
                status: response.status,
            };
        },
        buildModal: function (items) {
            "use strict";
            ACT.TRIES = {};
            var div = $(
                '<div class="actionModal ldseForm"><link rel="stylesheet" media="screen" type="text/css" href="' +
                    sharedPrefix +
                    '/ice/resources/styles/screen.css"/></div>'
            );
            for (var i = 0; i < items.length; i++) {
                var item = items[i];
                if (item) {
                    div.append(
                        $(
                            '<div class="ldse-clearfix">' +
                                '<div class="actionLabel">' +
                                item.name +
                                ": </div>" +
                                '<div id="image_' +
                                item.id +
                                '" class="actionImage">' +
                                '<span class="ui-finder-loader">&nbsp;</span><div id="status_' +
                                item.id +
                                '" class="actionStatus"/>' +
                                "</div>" +
                                "</div>" +
                                "</div>"
                        )
                    );
                }
            }
            // Close button
            div.append(
                $('<div class="actionClose">').append(
                    $('<button id="" class="ldse-button">Close</button>').click(
                        function () {
                            $(".actionItems").remove().dialog("close");
                            if (ICE.teaserManagerActive === false) {
                                if (ACT.RELOAD !== "") {
                                    location = ACT.RELOAD;
                                } else {
                                    location.reload();
                                }
                            } else {
                                $(".actionModal").remove().dialog("close");
                            }
                        }
                    )
                )
            );
            $(".actionModal").remove().dialog("close");
            div.dialog({
                position: [$(window).width() / 2 - 500 / 2, 150],
                dialogClass: "ldseForm ldse-modal",
                height: "auto",
                width: 500,
                zIndex: 4000,
                draggable: true,
                modal: true,
                title: ACT.MODAL_TITLE,
                close: function () {
                    $(".actionModal").remove().dialog("close");
                },
            });
        },
        page: function (action, uri, locale) {
            "use strict";

            function complete() {
                if (ACT.IS_TEMPLATE) {
                    ACT.addItems(["customPage", "rewriteRule", "resource"]);
                }
                // Items to ACT on
                var items = ACT.getItems().concat(ACT.getDynamicItems());
                if (items.length === 0) {
                    items = [
                        ACT.TYPE.customPage,
                        ACT.TYPE.rewriteRule,
                        ACT.TYPE.resource,
                    ];
                }
                if (
                    action === "ldse:delete" &&
                    window.location.pathname.indexOf("shared/lds-edit") == -1
                ) {
                    if (sharedPrefix !== "") {
                        ACT.RELOAD = sharedPrefix + "?" + ICE.langParam(locale);
                    } else {
                        ACT.RELOAD = "/";
                    }
                }
                items.push(ACT.TYPE.cache);

                ACT.checkForCorrelationNotApproved(action, uri, locale, items);
            }

            /* warn user before publishing page content */
            if (action === "ldse:publish") {
                var options = {
                    okText: "Publish",
                    okClass: "primary ldse-icon-send",
                };
                ICE.alertText(
                    "Warning",
                    "Are you sure you want to publish all page content?",
                    complete,
                    options
                );
            } else {
                complete();
            }
        },

        checkForCorrelationNotApproved: function (action, uri, locale, items) {
            if (action == "ldse:publish") {
                if ($(".correlation-not-approved").length > 0) {
                    ACT.buildCorrelationModal(action, uri, locale, items);
                } else {
                    ACT.continueAction(action, uri, locale, items);
                }
            } else {
                ACT.continueAction(action, uri, locale, items);
            }
        },

        buildCorrelationModal: function (action, uri, locale, items) {
            "use strict";

            ACT.correlationAction = action;
            ACT.correlationUri = uri;
            ACT.correlationLocale = locale;
            ACT.correlationItems = items;

            var $div = $(
                '<div class="correlationModal ldseForm">' +
                    '<link rel="stylesheet" media="screen" type="text/css" href="' +
                    sharedPrefix +
                    '/ice/resources/styles/screen.css"/>' +
                    "</div>"
            );

            var titleList = [];
            $(".correlation-not-approved").each(function () {
                titleList.push($(this).attr("data-correlation-document-title"));
            });
            titleList = titleList.join("<br/><br/>");

            $div.append(
                $(
                    '<div class="ldse-clearfix" style="margin:10px;">' +
                        "<span>There are one or more items on this page that are not approved for publishing and will not be published. <br/><br/> Do you wish to continue?</span><br/><hr/>" +
                        '<div style="overflow:auto;height:100px;">' +
                        titleList +
                        "</div>" +
                        "</div>"
                )
            );

            var $divButtons = $(
                '<div class="correlationModalButtons"><br/></div>'
            );

            // No button
            $divButtons.append(
                $(
                    '<div class="correlationModalClose" style="float:right; margin-left">'
                ).append(
                    $('<button id="" class="ldse-button">No</button>').click(
                        function () {
                            $(".correlationModal").remove().dialog("close");
                        }
                    )
                )
            );

            // Yes button
            $divButtons.append(
                $(
                    '<div class="correlationModalOK" style="float:right;">'
                ).append(
                    $('<button id="" class="ldse-button">Yes</button>').click(
                        function () {
                            ACT.continueAction(
                                ACT.correlationAction,
                                ACT.correlationUri,
                                ACT.correlationLocale,
                                ACT.correlationItems
                            );
                            $(".correlationModal").remove().dialog("close");
                        }
                    )
                )
            );

            $div.append($divButtons);

            $(".correlationModal").remove().dialog("close");

            $div.dialog({
                position: [$(window).width() / 2 - 500 / 2, 150],
                dialogClass: "ldseForm ldse-modal",
                height: "auto",
                width: 500,
                zIndex: 4000,
                draggable: true,
                modal: true,
                title: "Cor-IP / Cor-Eval",
                close: function () {
                    $(".correlationModal").remove().dialog("close");
                },
            });
        },

        continueAction: function (action, uri, locale, items, site) {
            ACT.performAction(action, uri, locale, items, site);
        },

        item: function (action, uri, locale, name, id, site, el) {
            "use strict";
            var pageUri = getUrlParameter("uri");
            var ID = name.replace(/[^a-zA-Z]+/g, "_");
            var indexOfComponent = indexOfCompToRemove(action, el);
            var items = [
                {
                    name: name,
                    folder: "dynamic-item",
                    id: ID,
                    ids: [id],
                    index: indexOfComponent,
                },
            ];
            if (
                action === "ldse:publish" &&
                $(".page-bundle-missing").length > 1
            ) {
                displayBundleModal(
                    $("[data-bundle-missing-count]").attr(
                        "data-bundle-missing-count"
                    )
                );
            } else {
                if (action === "ldse:publish") {
                    publishResourceBundles();
                }

                if (action === "ldse:delete") {
                    var parentData = getParentData(id);
                    if (parentData.isChildComponent) {
                        items[0] = $.extend(items[0], parentData);
                    }
                }

                var nestedData = getNestedComponentData(el, items);
                if (nestedData.isNestedComponent) {
                    items[0] = $.extend(items[0], nestedData);
                }
                if (ACT.IS_TEMPLATE && action === "ldse:publish") {
                    items.push(ACT.TYPE.customPage);
                    items.push(ACT.TYPE.rewriteRule);
                }
                items.push(ACT.TYPE.cache);
                ACT.performAction(action, uri, locale, items, site, pageUri);
            }
        },
        publishNav: function (uri, locale, navName) {
            "use strict";
            ACT.TYPE.navigation.ids = [navName];
            var items = [ACT.TYPE.navigation, ACT.TYPE.cache];
            ACT.performAction("ldse:publish", uri, locale, items);
        },
        publishJericho: function (uri, locale) {
            "use strict";
            var items = [ACT.TYPE.jericho, ACT.TYPE.cache];
            ACT.performAction("ldse:publish", uri, locale, items);
        },
        publishMeta: function (uri, locale) {
            "use strict";
            var items = [
                ACT.TYPE.customPage,
                ACT.TYPE.rewriteRule,
                ACT.TYPE.resource,
            ];
            ACT.performAction("ldse:publish", uri, locale, items);
        },
        publishResources: function (locale) {
            "use strict";
            var items = [ACT.TYPE.resource];
            ACT.performAction("ldse:publish", "/", locale, items);
        },
        translation: function (status, action, uri, locale, id, button) {
            "use strict";
            ACT.TYPE.translation.ids = [id];
            ACT.TYPE.translation.title = $(button).text();
            ACT.TYPE.translation.status = status;
            var items = [ACT.TYPE.translation];
            ACT.performAction(action, uri, locale, items);
        },
        performAction: function (action, uri, locale, items, site, pageUri) {
            "use strict";

            function complete() {
                ACT.MODAL_TITLE = items[0].title || ACT.ACTIONS[action];
                ACT.buildModal(items);
                for (var i = 0; i < items.length; i++) {
                    var item = items[i];
                    if (item) {
                        ACT.ajaxAction(
                            action,
                            uri,
                            locale,
                            item,
                            site,
                            pageUri
                        );
                    }
                }
            }
            if (action.indexOf("delete") != -1) {
                var options = {
                    okText: "Delete",
                    okClass: "destructive ldse-icon-trash",
                };
                ICE.alertText(
                    "Warning",
                    "Are you sure you want to delete?",
                    complete,
                    options
                );
                showComponentDependencies(action, uri, locale, items, pageUri);
            } else if (action.indexOf("remove") != -1) {
                var options = {
                    okText: "Remove",
                    okClass: "destructive ldse-icon-ko-remove",
                };
                ICE.alertText(
                    "Warning",
                    "Are you sure you want to remove?",
                    complete,
                    options
                );
            } else {
                complete();
            }
        },
        ajaxAction: function (action, uri, locale, item, site, pageUri) {
            "use strict";
            if (item.folder === "cache") {
                ACT.submitClearCache(action, uri, locale, item, site, pageUri);
            } else if (item.folder === "translation") {
                ACT.submitTranslation(action, uri, locale, item);
            } else {
                var url =
                    sharedPrefix +
                    "/ice/resources/ajax/" +
                    item.folder +
                    "/action?lang=" +
                    locale;
                var data = {
                    action: action,
                    uri: uri,
                    locale: locale,
                    site: site,
                    pageUri: pageUri,
                };
                data = $.extend(data, item);
                $.ajax({
                    type: "POST",
                    url: url,
                    dataType: "json",
                    cache: false,
                    data: data,
                    success: ACT.ajaxComplete,
                    error: function () {
                        var json = {
                            response: data,
                        };
                        json.response.success = false;
                        json.response.error = "500";
                        json.response.ids = json.response.ids.join(",");
                        ACT.ajaxComplete(json);
                    },
                });
            }
        },
        retryViaAjax: function (action, uri, locale, item, site, pageUri) {
            "use strict";
            $("#image_" + item.id + " > span").attr("class", ACT.IMAGE.ACTING);
            $("#status_" + item.id).html("");
            ACT.ajaxAction(action, uri, locale, item, site, pageUri);
        },
        ajaxComplete: function (data) {
            "use strict";
            if (data && data.response) {
                var message = "",
                    image = "",
                    action = data.response.action,
                    uri = data.response.uri,
                    locale = data.response.locale,
                    pageUri = getUrlParameter("uri"),
                    site = getUrlParameter("site"),
                    item = ACT.getItem(data.response),
                    success = data.response.success || "false",
                    error = data.response.error || "",
                    count = data.response.count || 0,
                    tries = ACT.TRIES[item.id];
                var retry = function () {
                    ACT.retryViaAjax(action, uri, locale, item, site, pageUri);
                    return false;
                };
                if (success === "true") {
                    if (data.response.hasOwnProperty("message")) {
                        message = data.response.message;
                    } else {
                        message =
                            "Action Completed <b>" + count + "</b> item(s)";
                    }
                    image = ACT.IMAGE.SUCCESS;
                } else if (!tries || tries < 3) {
                    tries = tries ? tries + 1 : 1;
                    ACT.TRIES[item.id] = tries;
                    message = "Action Failed...retrying...attempt: " + tries;
                    image = ACT.IMAGE.ACTING;
                    setTimeout(retry, 3000);
                } else {
                    ACT.TRIES[data.response.type] = null;
                    message = 'Action failed (<a href="#d">Retry</a>)';
                    image = ACT.IMAGE.ERROR;
                }
                $("#status_" + item.id).html(message);
                $("#status_" + item.id + " a").click(function (e) {
                    e.preventDefault();
                    retry();
                    return false;
                });
                $("#image_" + item.id + " > span").attr("class", image);
            }
        },
        submitClearCache: function (action, uri, locale, item, site, pageUri) {
            "use strict";
            var url = sharedPrefix + "/clear-cache/clear-cache-post?lang=eng";
            var locationObj = window.location;
            var browserUrl =
                locationObj.pathname + locationObj.search + locationObj.hash;
            var uris =
                encodeURIComponent(browserUrl) +
                "**" +
                encodeURIComponent(browserUrl);
            var json = {
                response: {
                    action: action,
                    uri: uri,
                    locale: locale,
                    site: site,
                    pageUri: pageUri,
                    success: "",
                    error: "",
                    name: item.name,
                    folder: item.folder,
                    id: item.id,
                    ids: item.ids.join(","),
                },
            };
            if (
                decodeURIComponent(window.location.pathname) !== uri &&
                typeof uri !== "undefined" &&
                uri !== "undefined"
            ) {
                uris += "**" + uri;
            }
            $.each(ACT.CLEAR_URLS, function (index, value) {
                uris += "**" + encodeURIComponent(value);
            });
            $.ajax({
                type: "POST",
                url: url,
                data: {
                    lang: "eng",
                    locale: locale,
                    uris: uris,
                    pageUri: pageUri,
                    site: site,
                },
                cache: false,
                success: function () {
                    json.response.success = "true";
                    json.response.message = "Successfully submitted request.";
                    ACT.ajaxComplete(json);
                },
                error: function () {
                    json.response.success = "false";
                    json.response.error = "error";
                    ACT.ajaxComplete(json);
                },
            });
        },
        archiveContent: function (currentPage, fileId, form, site, status) {
            "use strict";
            var json = {
                response: {
                    action: status,
                    uri: currentPage,
                    locale: locale,
                    success: "",
                    error: "",
                    status: status,
                    id: fileId,
                },
            };

            function complete() {
                $.ajax({
                    url:
                        sharedPrefix +
                        "/content-admin/ajax/archive?" +
                        ICE.langParam(locale),
                    type: "POST",
                    dataType: "json",
                    cache: false,
                    data: {
                        uri: currentPage,
                        form: form,
                        id: fileId,
                        site: site,
                        archiveStatus: status,
                    },
                    success: function (response) {
                        json.response.success = "true";
                        json.response.message = "Content " + status + ".";
                        ACT.ajaxComplete(json);
                        window.location = response.redirect;
                    },
                    error: function () {
                        json.response.success = "false";
                        json.response.error = "error";
                        ACT.ajaxComplete(json);
                    },
                });
            }
            if (status === "archive") {
                var options = {
                    okText: status,
                    okClass: "destructive ldse-icon-edit",
                };
                ICE.alertText(
                    "Warning",
                    "Are you sure you want to " + status + " this content?",
                    complete,
                    options
                );
            } else if (status === "unarchive") {
                var options = {
                    okText: status,
                    okClass: "primary ldse-icon-edit",
                };
                ICE.alertText(
                    "Warning",
                    "Are you sure you want to " + status + " this content?",
                    complete,
                    options
                );
            } else {
            }
        },
        submitTranslation: function (action, uri, locale, item) {
            "use strict";
            var json = {
                response: {
                    action: action,
                    uri: uri,
                    locale: locale,
                    success: "",
                    error: "",
                    status: item.status,
                    name: item.name,
                    folder: item.folder,
                    id: item.id,
                    ids: item.ids.join(","),
                },
            };
            $.ajax({
                url: sharedPrefix + "/translation/ajax/apply-action?lang=eng",
                type: "POST",
                dataType: "json",
                cache: false,
                data: {
                    status: item.status,
                    action: action,
                    "id[]": item.ids,
                },
                success: function (response) {
                    if (response.success) {
                        json.response.success = "true";
                        ACT.ajaxComplete(json);
                    } else {
                        json.response.success = "false";
                        json.response.error = "error";
                        ACT.ajaxComplete(json);
                    }
                },
                error: function () {
                    json.response.success = "false";
                    json.response.error = "error";
                    ACT.ajaxComplete(json);
                },
            });
        },
        addClearUrl: function (url) {
            "use strict";
            if (!$.isArray(url)) {
                url = [url];
            }
            $.each(url, function (index, value) {
                if ($.inArray(value, ACT.CLEAR_URLS) == -1) {
                    ACT.CLEAR_URLS.push(value);
                }
            });
        },
    };
    $(document).ajaxSend(function (event, request, settings) {
        if (
            settings.type != "HEAD" &&
            settings.url.indexOf("/") == -1 &&
            settings.url.indexOf(".css") == -1 &&
            settings.url.indexOf(".js") == -1
        ) {
            ACT.addClearUrl(settings.url);
        }
    });

    (function ($) {
        if ($.fn.style) {
            return;
        }

        // Escape regex chars with \
        var escape = function (text) {
            return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
        };

        // For those who need them (< IE 9), add support for CSS functions
        var isStyleFuncSupported =
            !!CSSStyleDeclaration.prototype.getPropertyValue;
        if (!isStyleFuncSupported) {
            CSSStyleDeclaration.prototype.getPropertyValue = function (a) {
                return this.getAttribute(a);
            };
            CSSStyleDeclaration.prototype.setProperty = function (
                styleName,
                value,
                priority
            ) {
                this.setAttribute(styleName, value);
                var priority = typeof priority != "undefined" ? priority : "";
                if (priority != "") {
                    // Add priority manually
                    var rule = new RegExp(
                        escape(styleName) +
                            "\\s*:\\s*" +
                            escape(value) +
                            "(\\s*;)?",
                        "gmi"
                    );
                    this.cssText = this.cssText.replace(
                        rule,
                        styleName + ": " + value + " !" + priority + ";"
                    );
                }
            };
            CSSStyleDeclaration.prototype.removeProperty = function (a) {
                return this.removeAttribute(a);
            };
            CSSStyleDeclaration.prototype.getPropertyPriority = function (
                styleName
            ) {
                var rule = new RegExp(
                    escape(styleName) +
                        "\\s*:\\s*[^\\s]*\\s*!important(\\s*;)?",
                    "gmi"
                );
                return rule.test(this.cssText) ? "important" : "";
            };
        }

        // The style function
        $.fn.style = function (styleName, value, priority) {
            // DOM node
            var node = this.get(0);
            // Ensure we have a DOM node
            if (typeof node == "undefined") {
                return this;
            }
            // CSSStyleDeclaration
            var style = this.get(0).style;
            // Getter/Setter
            if (typeof styleName != "undefined") {
                if (typeof value != "undefined") {
                    // Set style property
                    priority = typeof priority != "undefined" ? priority : "";
                    style.setProperty(styleName, value, priority);
                    return this;
                } else {
                    // Get style property
                    return style.getPropertyValue(styleName);
                }
            } else {
                // Get CSSStyleDeclaration
                return style;
            }
        };
    })(jQuery);

    /*
        var dependencyArray = [];
        document.querySelectorAll('[display-dependency]') && document.querySelectorAll('[display-dependency]').forEach(
            function(e){
                dependencyArray.push(e.getAttribute('display-dependency'));
            }
        );
        var reducedArray = dependencyArray.reduce((x, y) => x.includes(y) ? x : [...x, y], []);

        reducedArray.forEach(function(dependency){
            $(document).on('blur','[id="'+dependency+'"]',function(e){
                var group = e.currentTarget.closest('fieldset');
                var value = e.currentTarget.value;
                toggleDependents(group, dependency, value);
            });
        });
    */

    /*
     * Shows an information modal when publishing fails due to resources bundles missing.
     * Requires count of missing resource bundles.
     */
    function displayBundleModal(missingCount) {
        var html =
            '<div class="ldse-clearfix">' +
            '<div class="actionLabel">' +
            "Page has " +
            missingCount +
            " resource bundles missing." +
            "</div>" +
            "</div>" +
            '<div class="publishClose"><button id="" class="ldse-button close">Close</button></div>';
        $('<div class="actionModal iceForm"></div>')
            .html(html)
            .appendTo("body");
        $(".iceForm .close").click(function () {
            $(".iceForm").remove().dialog("close");
        });
        $(".iceForm").dialog({
            position: [$(window).width() / 2 - 480 / 2, 150],
            dialogClass: "ldseForm ldse-modal",
            width: 480,
            height: "auto",
            title: "Can't Publish Page - Missing Bundles",
            zIndex: 4000,
            resizable: true,
        });
    }

    function publishResourceBundles() {
        var bundles = [];
        var locales = [];
        $(".page-bundle-div li").each(function () {
            bundles.push($(this).attr("data-bundle-id"));
            locales.push(locale);
        });
        if (bundles.length > 0) {
            $.ajax({
                url:
                    sharedPrefix +
                    "/string-manager/ajax/publishBundles?lang=" +
                    locale,
                type: "POST",
                dataType: "json",
                data: { bundles: bundles, locales: locales },
                success: function (data) {
                    console.log("bundles published");
                },
            });
        }
    }

    function hideIfSubcomponents() {
        $("[hide-if-subcomponent]").each(function () {
            var elem = $(this);
            var hideif = elem.attr("hide-if-subcomponent");
            var array = hideif.split(",");
            var found = false;
            $.each(array, function (i, value) {
                var exists = $(
                    '[data-form="' +
                        value +
                        '"], [data-options="form%3A' +
                        value +
                        '"]'
                ).length;
                if (exists > 0) {
                    elem.closest("[data-group]").hide();
                    found = true;
                } else {
                    if (found == false) {
                        elem.closest("[data-group]").show();
                    }
                }
            });
        });
    }
}
