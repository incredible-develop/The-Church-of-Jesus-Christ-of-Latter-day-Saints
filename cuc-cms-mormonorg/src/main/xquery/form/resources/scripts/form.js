var _origButton = {};
var submitHandlers = [];
var modal = $("#modal1").trigger("close");
var SYNC = false;
var FORM_DATA = {};
var correlationEnabled = $("#cor-ip").length > 0,
    contentId = $("#content-id").val(),
    formOptions = $("#option").val(),
    formName = $("#content-form-name").val();

var once = true;
CKEDITOR.on("instanceReady", function (event) {
    if (once) {
        once = false;
        var form = $(event.editor.element.$).closest("form");
        saveFormInMemory(form);
    }
});

// Add border highlight to elements in the form
var lastActiveEl = null;
var activeElTypes = new Set(["INPUT", "SELECT", "IFRAME", "A", "TEXTAREA"]);

// Both focus & blur are triggered when focus changed, with iframe using only blur
function detectFocus() {
    var activeEl = document.activeElement;
    activeElChanged(activeEl);
}

function detectBlur() {
    var activeEl = document.activeElement;
    activeElChanged(activeEl);
}

// Requests to change highlight behavior of the focused element
function activeElChanged(el) {
    var nodeName = $(el).get(0).nodeName;
    // Form Element has Focus & requires highlight
    if (activeElTypes.has(nodeName) && lastActiveEl !== el) {
        if (lastActiveEl !== null) {
            setHighlightOnElement(
                $(lastActiveEl).get(0).nodeName,
                lastActiveEl
            );
        }
        lastActiveEl = el;
        setHighlightOnElement(nodeName, el);
    } else {
        // Form Element Lost Focus
        if (lastActiveEl !== null) {
            setHighlightOnElement(
                $(lastActiveEl).get(0).nodeName,
                lastActiveEl
            );
            lastActiveEl = null;
        }
    }
}

// Removes or applies a css to highlight a focused element
function setHighlightOnElement(nodeName, el) {
    var selector;
    var className = "ldse-active-element";
    switch (nodeName) {
        case "INPUT":
            selector = $(el);
            break;
        case "SELECT":
            if ($(el).parent().is("span.select")) {
                selector = $(el).parent();
            }
            break;
        case "TEXTAREA":
            selector = $(el);
            break;
        case "IFRAME":
            var elParent = $(el).parents("dd").get(0);
            selector = $(elParent).children("div").get(0);
            break;
        case "A":
            var elParent = $(el).parent().get(0);
            if ($(elParent).is("dd")) {
                var elChildren = $(elParent).children().get(0);
                if ($(elChildren).is("input")) {
                    className = "ldse-active-element-button";
                } else {
                    className = "ldse-active-element-icon";
                }
                selector = $(el);
            } else if ($(elParent).is("dl")) {
                selector = $(el);
                className = "ldse-active-element-icon";
            } else if ($(elParent).is("h3")) {
                selector = $(el);
                className = "ldse-active-element-icon";
            }
            break;
        default:
    }
    if (selector) {
        $(selector).toggleClass(className);
    }
}

// Request to listen to changes of focus in elements.
function attachActiveElEvents() {
    window.addEventListener
        ? window.addEventListener("focus", detectFocus, true)
        : window.attachEvent("onfocusout", detectFocus);
    window.addEventListener
        ? window.addEventListener("blur", detectBlur, true)
        : window.attachEvent("onblur", detectBlur);
}

attachActiveElEvents();

function clearInputField(name, el = "") {
    if (el === "") {
        document.getElementsByName(name)[0].value = "";
    } else {
        // data-type-generic clearing
        var inputEl = $(el).parent().siblings("dd").find("input");
        var spanImg = $(el).parent().siblings("dd").find("span");
        var img = $(el).parent().siblings("dd").find("img");
        var spanTitle = $(el).parent().siblings("dt").find("span");
        $(inputEl).each(function () {
            $(this).attr("value", "");
            if (
                $(this).attr("data-type") !== undefined &&
                $(this).attr("data-type") !== ""
            )
                $(this).attr("data-type", "");
        });
        $(spanImg).html("");
        $(img).attr("src", "");
        $(spanTitle).html("");
    }
}

function updatePreview(imageId, input) {
    var url = ICE.apiVars.contentApiUrl + "/id/" + input.value;
    document.getElementById(imageId).setAttribute("src", url);
}

function updateTitanPreview(
    titanHiddenInputId,
    titanPreviewId,
    element,
    titanHiddenType = "",
    titanHiddenThumb = ""
) {
    var labelError = "[for=" + $(element).attr("name") + "][class=error]";
    var type = element.getAttribute("data-type");
    if (element.value !== "") {
        if (element.getAttribute("data-type-generic") !== null) type = "";
        let promise = updateTitanDetails(element.value, type);
        promise
            .then((data) => {
                if (data === null) {
                    throw new Error("no data");
                } else if (type !== "" && type !== data.type) {
                    throw new Error("different type");
                }
                return data;
            })
            .then((data) => {
                $(element).removeClass("invalid-titan-id");
                $(element).siblings(".warning").remove();
                if (data.mimeType.includes("png")) {
                    element.dataset.warning =
                        "PNG images should not normally be used. Please replace with a JPG image, unless you know this is an appropriate use for a PNG file. PNG files should not be photos or have significant variances in color (texture). Appropriate PNG files are usually illustrations or otherwise simple images.";
                } else if (data.fileSize > 400000) {
                    element.dataset.warning =
                        "PNG images should not normally be used. Please replace with a JPG image, unless you know this is an appropriate use for a PNG file. PNG files should not be photos or have significant variances in color (texture). Appropriate PNG files are usually illustrations or otherwise simple images.";
                } else if (data.fileSize > 400000) {
                    element.dataset.warning = `Image file is larger than <strong style="color: #330400">400kb</strong> for the <strong style="color: #330400">${data.dimensions.width} X ${data.dimensions.height}</strong> resolution which we test. 
                        This will adversely impact load times. Please consider the following options:<br/>
                        <ol style="text-align: left">
                            <li>Go to the <a href="https://titan.churchofjesuschrist.org/?assetId=${data.id}" rel="noreferrer noopener" target="_blank">
                                titan page for the image</a> 
                                and click 'Recreate Titan Renditions' to have the titan system try to re-optimize them</li>
                            <li>Try to find a different rendition of the same image within the titan library</li>
                            <li>Choose a different image</li>
                        </ol>
                        `;
                } else {
                    element.removeAttribute("data-warning");
                }
                return data;
            })
            .then((data) => {
                var url =
                    ICE.apiVars.contentApiUrl +
                    "/id/" +
                    (data.thumbnail === "" ? element.value : data.thumbnail);
                var asset =
                    ICE.apiVars.contentApiAsset +
                    "/" +
                    (data.thumbnail === "" ? element.value : data.thumbnail);
                updateTitanElementHTML(
                    data.type,
                    element,
                    titanHiddenInputId,
                    titanPreviewId,
                    titanHiddenType,
                    titanHiddenThumb,
                    false,
                    url,
                    data.title,
                    asset,
                    data.type
                );
            })
            .catch((error) => {
                if ($(element).siblings("label.warning")) {
                    element.removeAttribute("data-warning");
                    $(element).siblings("label.warning").remove();
                }
                $(element).addClass("invalid-titan-id");
                updateTitanElementHTML(
                    type,
                    element,
                    titanHiddenInputId,
                    titanPreviewId,
                    titanHiddenType,
                    titanHiddenThumb,
                    true
                );
            });
    } else {
        if ($(element).siblings("label.warning")) {
            element.removeAttribute("data-warning");
            $(element).siblings("label.warning").remove();
        }
        $(element).removeClass("invalid-titan-id");
        updateTitanElementHTML(
            type,
            element,
            titanHiddenInputId,
            titanPreviewId,
            titanHiddenType,
            titanHiddenThumb,
            false
        );
    }
}

function updateTitanDetails(value, type) {
    if (value !== null && type !== null) {
        return new Promise((resolve, reject) => {
            $.ajax({
                type: "POST",
                dataType: "json",
                url: sharedPrefix + "/ice/resources/ajax/getTitanDetails",
                data: {
                    id: value,
                    type: type,
                },
                success: function (data) {
                    resolve(data);
                },
                error: function (error) {
                    reject(error);
                },
            });
        });
    } else {
        return Promise.reject(new Error("Element or Type is null"));
    }
}

function updateTitanElementHTML(
    type,
    elm,
    inputId,
    previewId,
    typeId,
    thumbId,
    error,
    url = "",
    title = "",
    asset = "",
    genericType = ""
) {
    var inputElm = $(elm)
        .parent()
        .siblings("dd")
        .find('[id="' + inputId + '"]');
    var previewElm = $(elm)
        .parent()
        .siblings("dd")
        .find('[id="' + previewId + '"]');

    $(elm).valid();
    if (elm.dataset.warning) {
        $(elm).siblings("label").remove();
        $(elm).after(
            `<label for="image-URL" class="warning">${elm.dataset.warning}</label>`
        );
    }
    if (type !== "image") {
        $(inputElm).attr("src", url);
        $(previewElm).html(title);
        $(inputElm).attr("value", title);
    } else {
        $(inputElm).attr("value", asset);
        $(previewElm).attr("src", asset);
    }
    if (elm.getAttribute("data-type-generic") !== null) {
        var typeElm = $(elm)
            .parent()
            .siblings("dd")
            .find('[id="' + typeId + '"]');
        var thumbElm = $(elm)
            .parent()
            .siblings("dd")
            .find('[id="' + thumbId + '"]');
        var typeSpan = $(elm)
            .parent()
            .siblings("dt")
            .find("span[data-type-generic]");
        var img = $(elm).parent().siblings("dd").find("img");
        $(typeElm).attr("value", genericType);
        $(typeSpan).html(genericType.replace(/^\w/, (c) => c.toUpperCase()));
        $(elm).attr("data-type", genericType);
        if (type === "image") {
            $(thumbElm).attr("value", asset);
            $(img).attr("src", asset);
            $(previewElm).html("");
            $(inputElm).attr("value", "");
        } else {
            $(thumbElm).attr("value", "");
            $(img).attr("src", "");
        }
    }
}

if (versify === "true") {
    CKEDITOR.on("instanceCreated", function (e) {
        e.editor.on("key", function (evt) {
            if (evt.data.keyCode === 13) {
                // if we call getStartElement too soon, we get the wrong element
                setTimeout(function () {
                    var se = e.editor.getSelection().getStartElement();
                    while (se.getName() !== "p") {
                        // possible infinite loop danger
                        if (
                            se.getName() === "li" ||
                            se.getName() === "p" ||
                            se.getName() === "div" ||
                            se.getName() === "h1" ||
                            se.getName() === "h2" ||
                            se.getName() === "h3" ||
                            se.getName() === "h4"
                        ) {
                            se.$.removeAttribute("data-id");
                            se.$.removeAttribute("index");
                            se.$.removeAttribute("xpath");
                            se.removeAttribute("data-id");
                            se.removeAttribute("index");
                            se.removeAttribute("xpath");
                            return se;
                        } else {
                            se = se.getParent();
                        }
                    }
                    if (se.getName() === "span") {
                        var text = se.getText(); // Store text, we are about to nuke the spans
                        while (se.getName() === "span") {
                            // possible infinite loop danger
                            se = se.getParent();
                        }
                        if (text.length === 0) se.setHtml("&nbsp;");
                        // It's important that this is not empty
                        else se.setHtml(text);
                    }
                    se.$.removeAttribute("data-id");
                    se.$.removeAttribute("index");
                    se.$.removeAttribute("xpath");
                    se.removeAttribute("data-id");
                    se.removeAttribute("index");
                    se.removeAttribute("xpath");
                    window.bla = se; // useful for debugging
                }, 10);
            }
        });
    });
}

function saveFormInMemory(form) {
    updateCkeditors();
    var index = form.attr("form-index");
    var f = (FORM_DATA.forms[index] = form.serializeArray());
}

function hasChanges(form) {
    var index = form.attr("form-index");
    var f = FORM_DATA.forms[index];
    var changed = false;
    var arrays = []; // list of arrays to loop through later
    changed =
        JSON.stringify(f).replace(/(\\r\\n\\t|\\r\\n|\\n|\\r|\\t)/gm, "") !==
            JSON.stringify(form.serializeArray()).replace(
                /(\\r\\n\\t|\\r\\n|\\n|\\r|\\t)/gm,
                ""
            ) || $("#save-version").is(":visible");
    return changed;
}

function updateCkeditors() {
    for (var instanceName in CKEDITOR.instances)
        try {
            /*        	CKEDITOR.instances[instanceName].setData($('#' + CKEDITOR.instances[instanceName].element.$.id).data("value"))*/
            CKEDITOR.instances[instanceName].updateElement();
        } catch (e) {
            CKEDITOR.instances[instanceName].destroy();
        }
}

function promptDelete(statusValue) {
    var msg = "";
    if (locale === "eng") {
        msg =
            "You are about to " +
            $(statusValue).text() +
            " this item." +
            "<br/>";
    } else {
        msg =
            "You are about to " +
            $(statusValue).text() +
            " this item." +
            "<br/>";
    }
    modal.find("div").remove();
    confirmDestructive("Warning", msg, statusValue);
    return false;
}

function promptChanges(href, changed) {
    var goToPage = referer;
    if (href && href !== "") {
        goToPage = href;
    }

    if (newDynamic) {
        goToPage = removeURLParameter(goToPage, "childID");
        if (parentID) {
            goToPage = goToPage + "&childID=" + ICE.formVars.id;
            var redirectToID = null,
                newParentID;
            //Check the last entry in the list.
            if (typeof parentID === "string") {
                redirectToID = parentID;
                newParentID = "";
            } else {
                redirectToID = parentID.pop();
                newParentID = parentID.join("_");
            }
            goToPage = removeURLParameter(goToPage, "option");
            goToPage = removeURLParameter(goToPage, "id");
            goToPage = removeURLParameter(goToPage, "parentID");
            goToPage =
                goToPage + "&id=" + redirectToID + "&parentID=" + newParentID;
        } else {
            //ParentID Absent. Redirect to original PubHubReferrer.
            if (pubHubReferer) goToPage = pubHubReferer;
        }
    }

    modal.find("div").remove();
    updateCkeditors();
    var h;
    if (changed || false) {
        h = true;
    } else {
        h = hasChanges($("form:first"));
    }
    try {
        ICE.addCKEditor();
    } catch (e) {}
    if (
        h &&
        (($("#is-submitter").val() === "true" &&
            $("#is-submitted").val() === "false") ||
            $("#is-submitter").val() === "false")
    ) {
        var msg = "You have unsaved changes." + "<br/>";
        var fn = "";
        var success = function (status) {
            if (goToPage === "") window.close();
            else window.location.href = goToPage;
        };
        confirmAction("Warning", msg, success);
    } else {
        if (goToPage === "") window.close();
        else {
            if (goToPage.startsWith(host) && goToPage.indexOf("") > -1) {
                ICE.post(goToPage, { pubHubReferer: pubHubReferer });
            } else {
                window.location.href = goToPage;
            }
        }
    }
    return;
}

function clonePage(lang, currentPage, action, currentID, recurse) {
    modal.trigger("close");
    modal.find("div").remove();
    $('<div class="ldseForm ldse-page"></div>').appendTo("body");
    var recursive = recurse || false;
    $.ajax({
        type: "POST",
        url:
            sharedPrefix +
            "/ice/resources/ajax/clone-page/clonePageForm?" +
            ICE.langParam(lang),
        data: {
            currentPage: currentPage,
            action: action,
            recurse: recurse,
            currentID: currentID,
        },
        success: function (html) {
            modal.append("<div>" + html + "</div>").trigger("open");
        },
    });
    $("#langSelects span.select").css("width", "200px");
}

function confirmAction(title, text, fn) {
    var display =
        '<div class="confirmation"><header class="ldse-section--header"><h2>' +
        title +
        '</h2></header><div class="ldse-section--body ldse-form"><dl><dt><label for="reason">' +
        text +
        '</label></dt></dl><div class="ldse-form-buttons"><input type="submit" class="ldse-button primary" value="Discard Changes" /><input type="button" class="ldse-button ldse-icon-ko-x ldse-modal-close" value="Continue Editing" /></div></div></div>';
    modal.find("div").remove();
    modal.append(display).trigger("open");
    modal.find(".ldse-button.primary").click(function () {
        fn(status);
        modal.trigger("close");
        return false;
    });
}

function alertAction(title, text) {
    var display =
        '<div class="confirmation"><header class="ldse-section--header"><h2>' +
        title +
        '</h2></header><div class="ldse-section--body ldse-form"><dl><dt><label for="reason">' +
        text +
        '</label></dt></dl><div class="ldse-form-buttons"><input type="submit" class="ldse-button primary" value="Ok" /></div></div></div>';
    modal.find("div").remove();
    modal.append(display).trigger("open");
    modal.find(".ldse-button.primary").click(function () {
        modal.trigger("close");
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
    modal.find("div").remove();
    modal.append(display).trigger("open");
    modal.find(".ldse-button.primary").click(function () {
        buttonClicked(statusValue);
        modal.trigger("close");
        return false;
    });
}

function syncMeta() {
    SYNC = true;
    $("<img/>")[0].src = "/ice/resources/images/loading_huge.gif";
    var display =
        '<div><header class="ldse-section--header"><h2>Sync Meta</h2></header><div class="ldse-section--body ldse-form"><dl><dt style="text-align: center;"><label for="reason">Syncing...</label></dt><dt><img src="/ice/resources/images/loading_huge.gif"></dt></dl></div></div>';
    modal.html(display).trigger("open");
    $("form.form-data").append(
        '<input type="hidden" name="sync-meta" value="true" />'
    );
    $("#action-save").click();
}

function buttonClicked(statusValue) {
    _origButton = statusValue;
    var status = $(statusValue).attr("status");
    continueSubmit("yes", status);
    console.log({ statusValue });
    console.log({ status });
    /*
    if(status == "ldse:publish")
    {
        if($(".correlation-not-approved:visible").length > 0)
        {
            var html = '' +
                '<div>'+
                    '<header class="ldse-section--header">' +
                        '<h2>Cor-IP / Cor-Eval</h2>' +
                    '</header>' +
                    '<form class="ldse-section--body ldse-form">' +
                    '<dl>' +
                        '<dt>' +
                            '<label>' +
                                '<div>' +
                                    'Some of the items in the collection are not approved for publishing.<br/><br/>Do you want to continue publishing without these items?' +
                                '</div>' +
                            '</label>' +
                        '</dt>' +
                    '</dl>' +
                    '<div class="ldse-form-buttons">' +
                        '<input type="button" onclick="continueSubmit(\'yes\', \'' + status + '\')" value="Yes" class="ldse-button primary"/>' +
                        '<input type="button" onclick="continueSubmit(\'no\', \'' + status + '\')" value="No" class="ldse-button primary"/>' +
                    '</div>' +
                '</form>' +
            '<div>';

            modal.html(html).trigger("open")
        }
        else
        {
            continueSubmit("yes", status);
        }
    }
    else
    {
        continueSubmit("yes", status);
    }
    */
}

function continueSubmit(submit, status) {
    modal.trigger("close");

    if (submit === "yes") {
        $("#status").val(status);

        var corStatus = $("#correlation-status").text();

        //Send document to Cor-IP if it has not been sent yet. This will only happen if a Super or Admin is logged in,
        //because they will have the Publish button available if the document has not yet been sent to Cor-IP.
        //If a Publisher is logged in, the will not have the Publish button available if the document has not yet been sent to Cor-IP.
        //Editors cannot publish, so the Publish button will not be available at all.
        if (status === "ldse:publish" || status === "ldse:publish-all") {
            if (
                (/(Declined)|(Approved)/.test(corStatus) &&
                    /Modified/.test($("#correlation-status").text())) ||
                /Not Sent/.test(corStatus)
            ) {
                var currentbutton = $(".tile.depressed");
                $("#correlation-button").click();
                if (Correlation.validate()) {
                    $("#send-to-correlation-input").val("true");
                }
                currentbutton.click();
            }
        }

        /*		for (var instanceName in CKEDITOR.instances){
                    $('#' + CKEDITOR.instances[instanceName].element.$.id).data("value", CKEDITOR.instances[instanceName].getData())
                }*/
        cleanupDisplayDependency();
        $("form.form-data").submit();
    }
}

/* Activates a CSS loading (waiting) spinning wheel */
function loadSpinner() {
    var div = '<div id="loader-on"></div><br/>';
    $("#loader-off").replaceWith(div);
}

function confirmSaveDone(title, text, fn, displayConfirmation) {
    if (displayConfirmation) {
        var display =
            '<div class="confirmation"><header class="ldse-section--header"><h2>' +
            title +
            '</h2></header><div class="ldse-section--body ldse-form"><dl><dt><label for="reason">' +
            text +
            '</label></dt></dl><div id="loader-off"></div><div class="ldse-form-buttons"><input type="submit" class="ldse-button primary" value="Save Changes" /><input type="button" class="ldse-button ldse-icon-ko-x ldse-modal-close" value="Continue Editing" /></div></div></div>';
        modal.find("div").remove();
        modal.append(display).trigger("open");
        modal.find(".ldse-button.primary").click(function () {
            fn(); // Ajax Post
            loadSpinner(); // Spinning Wheel while waiting instead of closing modal.
            //modal.trigger('close');
        });
    } else {
        fn(); // Ajax Post
    }
    return false;
}

function buttonClickedSaveDone() {
    var isValid = true;
    // Refresh/Update content of wysiwyg ckeditors
    updateCkeditors();
    if (!($("#status").val() === "ldse:delete")) {
        $(submitHandlers).each(function () {
            isValid = isValid && this();
        });
    }
    removeBlankDynamicItems();
    if (!isValid) {
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
                $("html,body").scrollTop(
                    first.closest(":visible").offset().top - 150
                );
            }, 100);
        }
        return false;
    } else {
        cleanupDisplayDependency();
        var form = $("form.form-data")[0];
        var action = $(form).attr("action");
        // Create an FormData object
        var data = new FormData(form);
        var msg = "You are about to save changes and finish editing." + "<br/>";
        var fn = function () {
            $.ajax({
                type: "POST",
                enctype: "multipart/form-data",
                url: action,
                data: data,
                processData: false,
                contentType: false,
                cache: false,
                timeout: 600000,
                success: function (data) {
                    var goToPage = referer;
                    if (goToPage === "") window.close();
                    else window.location.href = goToPage;
                },
                error: function (e) {
                    //console.log("Form Post: Ajax Error: ", e);
                },
            });
        };
        confirmSaveDone("Confirm Save and Done", msg, fn, false);
    }
}

function getTranslations(id, form) {
    $.ajax({
        type: "POST",
        contentType: "application/x-www-form-urlencoded",
        dataType: "html",
        url: sharedPrefix + "/form/ajax/translation?lang=eng",
        data: {
            id: contentId,
            form: formName,
            option: formOptions,
            site: site,
        },
        success: function (data) {
            var trs = $(data).filter("tr"),
                numbers;
            if (trs.length > 0) {
                numbers = trs.length - 1;
            } else {
                numbers = trs.length;
            }
            $("table#detail-table tbody").append(trs);
            $("#translations .ldse-information span").html(numbers);
        },
        error: function () {
            //console.log('error');
        },
    });
}

function submitSensitive() {
    $("#action-submit-approval").attr("disabled", "disabled");
    var sensitive = $(".ldse-sensitive-content").val(),
        stakeholder = $(".ldse-sensitive-stakeholder").val();
    if (stakeholder) {
        $.ajax({
            type: "POST",
            contentType: "application/x-www-form-urlencoded",
            dataType: "json",
            url: sharedPrefix + "/form/ajax/submit-for-approval?lang=eng",
            data: {
                sensitive: sensitive,
                stakeholder: stakeholder,
                locale: locale,
                id: contentId,
            },
            success: function (data) {
                approvalSent = data.approvalSent;
                if (approvalSent === "yes") {
                    alert("Approval has been sent to stakeholder");
                    $("#action-submit-approval").hide();
                    $("#action-submit-approval").removeAttr("disabled");
                }
            },
            error: function () {
                $("#action-submit-approval").removeAttr("disabled");
                alert("Error - Approval has not been sent");
                //console.log("Error getting history");
            },
        });
    } else {
        alert("Please enter your stakeholder's username");
    }
}

function getHistory(button, depressed) {
    if (depressed) {
        var id = $(button).data("id"),
            locale = $(button).data("locale");
        $.ajax({
            type: "POST",
            contentType: "application/x-www-form-urlencoded",
            dataType: "json",
            url: sharedPrefix + "/form/ajax/get-history?lang=eng",
            data: {
                locale: locale,
                id: id,
            },
            success: function (data) {
                H.events = data;
                H.setup();
            },
            error: function () {
                //console.log("Error getting history");
            },
        });
    }
}

/* R&D ENRICH */
function getEnrich(button, depressed) {
    if (depressed) {
        var id = $(button).data("id"),
            locale = $(button).data("locale");
        form = $("#enrich-info").closest("form");
        saveForm = !hasChanges(form);

        $.ajax({
            type: "POST",
            contentType: "application/x-www-form-urlencoded",
            dataType: "html",
            url: sharedPrefix + "/form/ajax/enrich?lang=eng",
            data: {
                locale: locale,
                id: id,
            },
            success: function (data) {
                $("#enrich-info .ldse-section--body").replaceWith(data);
                Enrich.updateChecked();
                if (saveForm) {
                    saveFormInMemory(form);
                }
            },
            error: function () {
                //console.log("Error Enriching");
            },
        });
    }
}

/* R&D ENRICH */
function followContent(item, username) {
    var id = $(item).data("id"),
        locale = $(item).data("locale"),
        flag = $(item).find("span").hasClass("ldse-following-content");
    $.ajax({
        type: "POST",
        contentType: "application/x-www-form-urlencoded",
        dataType: "json",
        url: sharedPrefix + "/form/ajax/follow-content?lang=eng",
        data: {
            locale: locale,
            id: id,
            username: username,
            flag: flag,
        },
        success: function (data) {
            if (flag) {
                $("span.ldse-follow-content .ldse-icon-flag").removeClass(
                    "ldse-following-content"
                );
                //$('.ldse-follow-text').text('Follow This Content');
            } else {
                $("span.ldse-follow-content .ldse-icon-flag").addClass(
                    "ldse-following-content"
                );
                //$('.ldse-follow-text').text('Following This Content');
            }
        },
        error: function () {
            //console.log("Error getting comments");
        },
    });
}

function unfollowContent(item) {
    var id = $(item).data("id"),
        locale = $(item).data("locale");
    $.ajax({
        type: "POST",
        contentType: "application/x-www-form-urlencoded",
        dataType: "json",
        url: sharedPrefix + "/form/ajax/follow-content?lang=eng",
        data: {
            locale: locale,
            id: id,
        },
        success: function (data) {
            $("span.ldse-follow-content .ldse-icon-flag").removeClass(
                "ldse-following-content"
            );
        },
        error: function () {
            //console.log("Error getting comments");
        },
    });
}

function getComments(button, depressed) {
    if (depressed) {
        var id = $(button).data("id"),
            locale = $(button).data("locale");
        $.ajax({
            type: "POST",
            contentType: "application/x-www-form-urlencoded",
            dataType: "json",
            url: sharedPrefix + "/form/ajax/get-comments?lang=eng",
            data: {
                locale: locale,
                id: id,
            },
            success: function (data) {
                comment.comments = data;
                comment.setup();
            },
            error: function () {
                //console.log("Error getting comments");
            },
        });
    }
}

function previewItem(button) {
    var uri = $(button).closest("tr").data("uri");
    var locale = $(button).closest("tr").data("locale");
    window.location =
        frontEndHost + sharedPrefix + uri + "?" + ICE.langParam(locale);
}

function updateTranslations(button) {
    var success = 0;
    var checked = $(".rowSelect:checked");

    function allSuccess() {
        if (success === checked.length) {
            sessionStorage.message = $(button).text() + " Successful.";
            var postData = ICE.postVars[ICE.formVars.form];
            ICE.post(window.location.href, postData);
        }
    }

    var ids = [];
    checked.each(function () {
        ids.push($(this).closest("tr").data("fileid"));
    });
    $("html").addClass("loading");
    $.ajax({
        type: "POST",
        contentType: "application/x-www-form-urlencoded",
        dataType: "json",
        url: sharedPrefix + "/ice/resources/ajax/dynamic-item/action?lang=eng",
        data: {
            action: $(button).attr("data-action"),
            ids: ids,
            collection: collection,
            site: site,
        },
        success: function (data) {
            $("html").removeClass("loading");
            if (data.response.success && data.response.count > 0) {
                success++;
                allSuccess();
                window.location.reload();
            } else {
                alert("Failed publishing: " + ids[0]);
            }
        },
        error: function () {
            alert("Failed publishing: " + ids[0]);
            $("html").removeClass("loading");
        },
    });
}

function actionButtons(button) {
    var action = $(button).data("action");

    switch (action) {
        case "ldse:schedule-publish":
        case "ldse:schedule-unpublish":
            showSchedulingModal(button);
            break;
        default:
            updateTranslations(button);
    }
}

function cancelSchedulingModal() {
    var $modal = $("#scheduling-modal");
    //blank out input fields
    $modal.trigger("close");
}

function showSchedulingModal(button) {
    var $button = $(button).clone(),
        $modal = $("#scheduling-modal");
    $modal.find("header h2").text("Schedule " + $button.data("label"));
    $modal.find(".schedule-label").text($button.data("label"));
    $modal.find("#scheduling-variables").html($button[0]);
    $modal.trigger("open");
}

function saveSchedulingModal() {
    if (validateScheduling()) {
        $("html").addClass("loading");

        var $modal = $("#scheduling-modal"),
            $button = $modal.find("#scheduling-variables button"),
            $checked = $(".rowSelect:checked"),
            action = $button.data("action"),
            row,
            checked = $(".rowSelect:checked"),
            ids = [],
            locale = $(".rowSelect:checked").closest("tr").data("locale");

        checked.each(function () {
            (row = $(this).closest("tr")), ids.push($(row).data("fileid"));
        });

        $.ajax({
            type: "post",
            url: sharedPrefix + "/form/ajax/schedule?lang=eng",
            data: {
                ids: ids,
                action: action,
                futureDate: $("#futureDateModal").val(),
                futureHour: $("#futureHourModal").val(),
                futureMin: $("#futureMinModal").val(),
                unpubfutureDate: $("#futureDateModal").val(),
                unpubfutureHour: $("#futureHourModal").val(),
                unpubfutureMin: $("#futureMinModal").val(),
                locale: locale,
                site: site,
            },
            success: function (data) {
                $("html").removeClass("loading");
                reload("Scheduling Successful!");
            },
            error: function () {
                $("html").removeClass("loading");
            },
        });
    }
}

function reload(successMessage) {
    sessionStorage.message = successMessage || "";
    var postData = ICE.postVars["form"] || {};
    if (typeof (postData["uri"] !== "undefined")) {
        delete postData["uri"];
    }
    ICE.post(window.location.href, postData, "POST");
}

function validateScheduling() {
    var futureDate = $("#futureDateModal"),
        futureHour = $("#futureHourModal"),
        futureMin = $("#futureMinModal"),
        now = new Date(),
        serverNow = new Date(),
        clientTimeZone = -new Date().getTimezoneOffset() / 60,
        offset = serverTimeZone - clientTimeZone,
        valid = true;

    if (futureDate.length > 0) {
        var futureDateArray = futureDate.val().split("-");
        var futureDateYear = parseFloat(futureDateArray[0]);
        var futureDateMonth = parseFloat(futureDateArray[1]) - 1;
        var futureDateDay = parseFloat(futureDateArray[2]);

        serverNow.setHours(serverNow.getHours() + offset);

        var serverNowStr = serverNow.toString(),
            prettyDate = serverNowStr.substr(0, serverNowStr.indexOf(" GMT"));

        $("#futureDateModal, .schedule-time").removeClass("error");
        $("#schedule-error").hide();

        if (futureDate.val() !== "" && futureDate.length !== 0) {
            var futureDateTime = new Date(
                futureDateYear,
                futureDateMonth,
                futureDateDay,
                parseFloat(futureHour.val()),
                parseFloat(futureMin.val())
            );

            valid = futureDateTime >= serverNow;

            if (!valid) {
                $("#futureDateModal, .schedule-time").addClass("error");
                $("#pretty-date").text(prettyDate);
                $("#schedule-error").show();
            }
        }
    }

    return valid;
}

function sortColumn(column) {
    var columnHead = $(column).closest("th.sorts"),
        columnName = columnHead.attr("data-name"),
        hasDesc = columnHead.hasClass("desc"),
        hasAsc = columnHead.hasClass("asc"),
        hasSort = columnHead.hasClass("sort"),
        sortDir;
    if (!hasDesc && !hasAsc && !hasSort) {
        columnHead.addClass("sort desc");
        sortDir = false;
    } else if (hasDesc) {
        columnHead.addClass("asc").removeClass("desc");
        sortDir = true;
    } else if (hasAsc) {
        columnHead.addClass("desc").removeClass("asc");
        sortDir = false;
    }

    columnHead.siblings().removeClass("sort asc desc");
    //  applyFilters();
    var translations = $(".originalTR:visible").clone(),
        originalTranslation = $(translations).slice(0, 1),
        translations = $(translations).slice(1);

    function sortRow(a, b) {
        var $dataA = $(a).find('td[data-sort="' + columnName + '"]'),
            $dataB = $(b).find('td[data-sort="' + columnName + '"]'),
            dataA = $dataA.text(),
            dataB = $dataB.text();

        if ($dataA.hasClass("datesort")) {
            dataA = new Date(dataA);
        }

        if ($dataB.hasClass("datesort")) {
            dataB = new Date(dataB);
        }

        if ((sortDir && dataB > dataA) || (!sortDir && dataA > dataB)) {
            return 1; /*-1 is b before a*/
        } else if ((sortDir && dataA > dataB) || (!sortDir && dataB > dataA)) {
            return -1;
            /*a before b*/
        } else {
            return 0;
            /*no sort*/
        }
    }

    translations.sort(sortRow);
    $("#translation-info tbody").html(originalTranslation);
    $("#translation-info tbody").append(translations);
    translations = [];
}

$(".rowSelect").bind("input", function () {
    if ($(this).attr("selected") === true) {
        alert("checked");
    }
});

function editFile() {
    var row = $(".rowSelect:checked").closest("tr"),
        params = {
            page: row.data("uri"),
            option: row.data("options"),
            uri: row.data("uri"),
            id: row.data("fileid"),
            status: "edit",
        },
        lang = ICE.langParam(row.data("locale")),
        method = "post",
        path = sharedPrefix + "/form?" + lang + "&site=" + site;
    LDSE.post(path, params, method);
}

var editFileLinkValue = {};

function editFileLink(value) {
    editFileLinkValue = value;

    if (hasChanges($("form.form-data"))) {
        var msg = "You have unsaved changes." + "<br/>";
        var fn = "";
        var success = function (status) {
            continueToFileLink();
        };
        confirmAction("Warning", msg, success);
    } else {
        continueToFileLink();
    }
}

function continueToFileLink() {
    var row = $(editFileLinkValue).closest("tr"),
        params = {
            page: row.data("uri"),
            option: row.data("options"),
            uri: row.data("uri"),
            id: row.data("fileid"),
            status: "edit",
        },
        lang = ICE.langParam(row.data("locale")),
        method = "post",
        path = sharedPrefix + "/form?" + lang + "&site=" + site;

    LDSE.post(path, params, method);
}

function previewButtonClicked(href) {
    window.open(href, "preview");
}

function validateSchedulePublish() {
    var publishingBtn = $("#publishing"),
        pubDate = $("#futureDate"),
        pubHour = $("#futureHour"),
        pubMin = $("#futureMin"),
        unpubDate = $("#unpubFutureDate"),
        unpubHour = $("#unpubFutureHour"),
        unpubMin = $("#unpubFutureMin"),
        now = new Date(),
        serverNow = new Date(),
        offset = serverTimeZone - clientTimeZone,
        pubValid = true,
        unpubValid = true;
    if (pubDate.length > 0 && unpubDate.length > 0) {
        var pubDateArray = pubDate.val().split("-");
        var pubDateYear = parseFloat(pubDateArray[0]);
        var pubDateMonth = parseFloat(pubDateArray[1]) - 1;
        var pubDateDay = parseFloat(pubDateArray[2]);

        var unpubDateArray = unpubDate.val().split("-");
        var unpubDateYear = parseFloat(unpubDateArray[0]);
        var unpubDateMonth = parseFloat(unpubDateArray[1]) - 1;
        var unpubDateDay = parseFloat(unpubDateArray[2]);

        serverNow.setHours(serverNow.getHours() + offset);

        var serverNowStr = serverNow.toString(),
            prettyDate = serverNowStr.substr(0, serverNowStr.indexOf(" GMT")),
            error =
                '<label generated="true" class="error scheduleError" style="">Not a valid future date and time.<br/>Server time is ' +
                prettyDate +
                "</label>";

        $(
            "#publishing-info dl.error, #publishing-info dd.error, #publishing-info :input.error"
        ).removeClass("error");
        $("#publishing-info label.scheduleError").remove();

        $(
            "#publishing-info dl.error, #publishing-info dd.error, #publishing-info :input.error"
        ).removeClass("error");
        $("#publishing-info label.scheduleError").remove();

        if (pubDate.val() !== "" && pubDate.length !== 0) {
            var pubDateTime = new Date(
                pubDateYear,
                pubDateMonth,
                pubDateDay,
                parseFloat(pubHour.val()),
                parseFloat(pubMin.val())
            );
            pubValid = pubDateTime >= serverNow;
            if (!pubValid) {
                pubDate.closest("dd").addClass("error");
                pubMin.closest("dl").append(error).addClass("error");
            }
        }

        if (unpubDate.val() !== "" && pubDate.length !== 0) {
            var unpubDateTime = new Date(
                unpubDateYear,
                unpubDateMonth,
                unpubDateDay,
                parseFloat(unpubHour.val()),
                parseFloat(unpubMin.val())
            );
            unpubValid = unpubDateTime >= serverNow;
            if (!unpubValid) {
                unpubDate.closest("dd").addClass("error");
                unpubMin.closest("dl").append(error).addClass("error");
            }
        }
    }
    if (pubValid === false || unpubValid === false) {
        if (location.hash !== "#publishing") {
            publishingBtn.click();
        }
        return false;
    } else {
        $("#send-to-correlation").attr("disabled", "disabled");

        return true;
    }
}

function translationButtonShow() {
    alert("Showing");
}

function checkTranslationEngOnly() {
    var checkboxCount = $(".rowSelect:checked").length;
    $("#translation-action-publish")
        .removeAttr("disabled")
        .attr("onclick", translationActionPublishOnClick);
    if (checkboxCount === 1) {
        if ($(".rowSelect:checked").closest("tr").data("locale") === "eng") {
            if ($("#correlation-is-prepublisher").val() !== "true") {
                $("#translation-action-publish")
                    .attr("disabled", "disabled")
                    .attr("onclick", "return false;");
            }
        }
    }
}

var translationActionPublishOnClick = "";

function processLineBreaks() {
    $(".ldse-history-entry-text").each(function () {
        var text = $(this).text();
        var textArray = text.split("!LINE-BREAK!");
        var html = textArray.join("</span><br/><span>");
        html = "<span>" + html + "</span>";
        $(this).html(html);
    });
}

function returnSubmission() {
    $("form.form-data")
        .append("<input type='hidden' name='return-submission' value='true'/>")
        .submit();
}

function returnSubmission() {
    $("form.form-data")
        .append("<input type='hidden' name='return-submission' value='true'/>")
        .submit();
}

function toggleDynamicXml(button) {
    $(button).closest("section").find("fieldset.table").toggle();
    /*$('#toggle-btn').on('click', function() {
        $('.dynamic-xml-toggle').find('fieldset').toggle();
    });*/
}

function checkParent(id) {
    document
        .querySelectorAll("input[type='checkbox'][value='" + id + "']")[0]
        .setAttribute("checked", "");
    document.querySelectorAll(
        "input[type='checkbox'][value='" + id + "']"
    )[0].checked = "true";
}

function unClickChildren() {
    var isChecked = event.target.checked === "false";
    if (!isChecked) {
        var children = event.target.getAttribute("data-children").split(" ");
        for (var i = 0; i < children.length; i++) {
            document
                .querySelectorAll(
                    "input[type='checkbox'][value='" + children[i] + "']"
                )[0]
                .removeAttribute("checked");
            document.querySelectorAll(
                "input[type='checkbox'][value='" + children[i] + "']"
            )[0].checked = false;
        }
    }
}

function removeBlankDynamicItems() {
    let items = Array.from(document.querySelectorAll("li.repeated-item"));
    let blankItems = items
        .filter((item) => {
            let spans = Array.from(
                item
                    .querySelector("fieldset")
                    .querySelectorAll("dd input, dd select, dd h3 a")
            );
            return (
                spans.filter((input) => {
                    //catch text inputs
                    if (input.type === "text" || input.type === "hidden") {
                        return input.value !== "";
                    }
                    //catch select inputs
                    else if (input.type.includes("select")) {
                        switch (input.value.toLowerCase()) {
                            case "":
                                return false;
                            case "please select":
                                return false;
                            case "post":
                                return false;
                            case "primary-color-background":
                                return false;
                            case "big":
                                return false;
                            default:
                                return true;
                        }
                    }
                    //catch checkbox inputs
                    else if (input.type === "checkbox") {
                        return input.checked;
                    } else {
                        // catch predefined questions
                        return input.dataset.form !== "";
                    }
                }).length === 0
            );
        })
        .map((item) => {
            return item.firstElementChild.lastElementChild;
        });

    while (blankItems.length > 0) {
        ICE.deleteListItem(blankItems.shift());
    }
}

$(document).ready(function () {
    $("#futureDateModal").datepicker({
        minDate: new Date(),
        dateFormat: "yy-mm-dd",
    });
    $(".ixf-option").hide();
    if ($("#isPageBuilder").val() === "false") {
        $("nav.ldse-nav li.active").removeClass("active");
        $("nav.ldse-nav li.ldse-open").removeClass("ldse-open");
    }
    if ($("section#content-info").attr("sensitive") === "true") {
        var buttons = $("#ldse-toolbar-buttons span");
        var sensitive = $(".ldse-sensitive-content"),
            sensitiveValue = sensitive.val(),
            stakeholderItem = $(".ldse-stakeholder-item"),
            stakeholderHere = $(".ldse-sensitive-stakeholder");
        if (sensitiveValue === "yes" && needsApproval !== "no") {
            $("#action-publish").closest("ul").hide();
            $("#action-publish").hide();
            stakeholderItem.css("display", "block");
            $(".ldse-sensitive-stakeholder").addClass("required");
            if (approvalSent !== "yes") {
                $(buttons[0]).prepend(
                    '<button class="ldse-button ldse-responsive-button secondary ldse-icon-send" onclick="submitSensitive(); return false;" id="action-submit-approval" status="ldse:submit-approval" name="ldse:submit-approval" i18n="">Submit for Approval</button>'
                );
            } else {
                $("#action-submit-approval").hide();
            }
        } else {
            $(".ldse-sensitive-stakeholder").removeClass("required");
        }
        sensitive.on("change", function () {
            if ($(this).val() === "yes" && needsApproval !== "no") {
                stakeholderItem.css("display", "block");
                $(".ldse-sensitive-stakeholder").addClass("required");
                $("#action-publish").closest("ul").hide();
                $("#action-publish").hide();
                if (approvalSent !== "yes" && needsApproval === "yes") {
                    $(buttons[0]).prepend(
                        '<button class="ldse-button ldse-responsive-button secondary ldse-icon-send" onclick="submitSensitive(); return false;" id="action-submit-approval" status="ldse:submit-approval" name="ldse:submit-approval" i18n="">Submit for Approval</button>'
                    );
                } else {
                    $("#action-submit-approval").hide();
                }
            } else {
                stakeholderItem.css("display", "none");
                $(".ldse-sensitive-stakeholder").removeClass("required");
                $("#action-publish").closest("ul").show();
                $("#action-publish").show();
                $("#ldse-toolbar-buttons span #action-submit-approval").hide();
            }
            $(".chosen").chosen();
        });
        stakeholderHere.on("change", function () {
            if (stakeholderHere.val() === "") {
                stakeholderItem.append(
                    "<label for='stakeholder' generated='true' class='error ldse-stakeholder-error-message' style='display:none;'>This field is required.</label>"
                );
            } else {
                $("label[for=stakeholder]").remove();
            }
        });
    }
    var publishIsDisabled = !(
        $("#action-publish").attr("disabled") === undefined
    );

    if (
        $("#is-submitter").val() === "true" ||
        $("#remove-publish-button").val() === "true"
    ) {
        $("#action-publish").hide();
    }

    translationActionPublishOnClick = $("#translation-action-publish").attr(
        "onclick"
    );
    $(".rowSelect, #box-all").live("click", function () {
        checkTranslationEngOnly();
    });
    $(".ldse-group-header").on("click", function () {
        var section = $(this).closest("section"),
            button = section.find("button#toggle-btn-collapse");
        if (!section.hasClass("closed")) {
            button.hide();
        } else {
            button.show();
        }
    });

    if (sessionStorage.message && sessionStorage.message !== "") {
        $("#save-alert").css("display", "block");
        $(".ldse-alert-text").text(sessionStorage.message);
        $("#ldse-toolbar-buttons button").removeAttr("disabled");
        if (publishIsDisabled) {
            $("#action-publish").attr("disabled", "disabled");
        }
        setTimeout(function () {
            $("#save-alert").hide();
        }, 5000);
        sessionStorage.message = "";
    }
    var repeatedItem = $(".dynamic-xml-header a.closed");
    repeatedItem.each(function () {
        var toggle = $(this),
            li = toggle.closest("li"),
            fieldset = li.children("fieldset.table"),
            title = fieldset
                .find("input[item-title]")
                .not(fieldset.find("ul :input[item-title]"));
        toggle.text(title.val());
    });
    // Expand or collapse section
    $(window).on("click", ".dynamic-xml-toggle", function (e) {
        e.preventDefault();
        e.stopPropagation();
        var cur = $(this),
            wrapper = cur.closest("li"),
            target = $(cur.attr("href")),
            guts = wrapper.children("fieldset.table"),
            header = cur,
            itemTitle = guts
                .find(":input[item-title]")
                .not(guts.find("ul :input[item-title]"))
                .first();
        guts.slideToggle(function () {
            //cur.toggleClass("closed");
            cur.toggleClass("ldse-icon-rev-tri-right").toggleClass(
                "ldse-icon-rev-tri-down"
            );
            if (cur.hasClass("ldse-icon-rev-tri-right")) {
                cur.addClass("closed");
            } else {
                cur.removeClass("closed");
            }
            if (cur.hasClass("closed")) {
                header.text(itemTitle.val());
            } else {
                header.text("");
            }
            LDSE.resizeCallbacks.makeCols();
            guts.css("overflow", "visible");
            if (cur.hasClass("closed")) {
                header.text(itemTitle.val());
            } else {
                header.text("");
            }
            LDSE.resizeCallbacks.makeCols();
            guts.css("overflow", "visible");
        });
    });
    $(window).on("click", "#toggle-btn-collapse", function (e) {
        e.preventDefault();
        var button = $(this),
            wrapper = button.closest("section");
        /*        $this.closest('div').toggleClass("closed");*/
        wrapper.each(function (e) {
            if (button.text() === "Collapse All") {
                $(this)
                    .find("a.dynamic-xml-toggle:not(.closed)")
                    .trigger("click");
            } else if (button.text() === "Expand All") {
                $(this).find("a.dynamic-xml-toggle.closed").trigger("click");
            } else {
            }
        });
        if (button.text() === "Collapse All") {
            button.text("Expand All");
            button.removeClass("ldse-icon-ko-tri-right");
            button.addClass("ldse-icon-ko-tri-down");
        } else {
            button.text("Collapse All");
            button.removeClass("ldse-icon-ko-tri-down");
            button.addClass("ldse-icon-ko-tri-right");
        }
    });
    $(".handlebars-template").each(function () {
        window[$(this).attr("id")] = Handlebars.compile($(this).html());
    });
    $("#publishing-info :input")
        .blur(validateSchedulePublish)
        .change(validateSchedulePublish);
    FORM_DATA.forms = {};
    var form = $("form");
    form.each(function (i, element) {
        var f = $(this).attr("form-index", i);
        FORM_DATA.forms[i] = {};
        saveFormInMemory(f);
    });
    $(".ldse-show-single").hide();

    $(".rowSelect").live("click", function () {
        if ($(this).is(":checked") && !$(this).closest("tr").data("editable"))
            $("#translation-action-edit").hide();
    });
    if (ICE.formVars.id && newDynamic && $("#permalink").val()) {
        //Disable the URI field since URI cant be change once set.
        $("#permalink").attr("readonly", "true");
    }
    var hash = window.location.hash;
    if (hash === "#saved") {
        window.location =
            sharedPrefix +
            "/error?errorTitle=We saved you!&errorMsg=You tried to use the back button in your browser to edit this content. Please only use the ICE controls to edit content.&referLink=/";
    } else if (hash && hash !== "#content") {
        var selectedTile = $(hash + " button");
        if (selectedTile.length) {
            setTimeout(function () {
                LDSE.slideToggleDuration = 0;
                selectedTile.trigger("click");
                delete LDSE.slideToggleDuration;
            }, 100);
        }
    }
    if ($("#formAction").val() === "edit") {
        getTranslations(contentId, formName);
    }
    submitHandlers.push(function () {
        var valid =
            $("form.form-data").valid() && validateWysiwyg("form.form-data");
        if (!valid && !(location.hash === "#content" || location.hash === "")) {
            $("#send-to-correlation").attr("disabled", "disabled");
        }
        return valid;
    });
    submitHandlers.push(validateSchedulePublish);
    if ($("#permalink").length !== 0) {
        submitHandlers.push(permalinkVerifyUrl);
    }
    submitHandlers.push(function () {
        var valid = validateTitan("form.form-data");
        return valid;
    });
    $("form.form-data").submit(function (e) {
        e.preventDefault();
        e.stopPropagation();
        e.stopImmediatePropagation();
        var isValid = true;
        updateCkeditors();
        if (!($("#status").val() === "ldse:delete")) {
            $(submitHandlers).each(function () {
                isValid = isValid && this();
            });
        }
        if (!isValid) {
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
                    $("html,body").scrollTop(
                        first.closest(":visible").offset().top - 150
                    );
                }, 100);
            }
            return false;
        }
        if (!isValid) {
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
                    $("html,body").scrollTop(
                        first.closest(":visible").offset().top - 150
                    );
                }, 100);
            }
            return false;
        }
        $("#ldse-toolbar-buttons button").attr("disabled", "disabled");
        $("#action-publish").attr("disabled", "disabled");
        $("#action-save").attr("disabled", "disabled");
        $("#action-destructive").attr("disabled", "disabled");
        $(".chosen").chosen();
        //Update CKEDITOR textareas
        //updateCkeditors();
        removeBlankDynamicItems();
        $("form.form-data").ajaxSubmit({
            dataType: "json",
            success: function (data) {
                var action = $('[name="action"]').val();
                var postData =
                    ICE.postVars[ICE.formVars.form] || ICE.postVars.form;
                postData.id = data.id || postData.id;
                postData.action = "edit";
                postData.pubHubReferer = pubHubReferer;
                if (SYNC) {
                    window.location.hash = "#translations";
                    sessionStorage.message = "Sync Successful!";
                } else if (
                    sessionStorage.sendingToCorrelation &&
                    sessionStorage.sendingToCorrelation === "true"
                ) {
                    sessionStorage.message = "Sent to Correlation";
                    sessionStorage.sendingToCorrelation = "";
                } else if ($("#status").val() === "ldse:publish") {
                    sessionStorage.message = "Publish Successful!";
                } else if ($("#status").val() === "ldse:publish-all") {
                    sessionStorage.message = "Publish All Successful!";
                } else if ($("#status").val() === "ldse:submitted") {
                    sessionStorage.message = "Submission Successful!";
                } else if ($("#status").val() === "ldse:unpublish") {
                    sessionStorage.message = "Unpublish Successful!";
                } else {
                    sessionStorage.message = "Save Successful!";
                }

                if (data.forceRedirect) {
                    if (data.redirect === "") {
                        $("#action-preview").click();
                    } else {
                        window.location = data.redirect;
                    }
                } else {
                    //$('#ldse-toolbar-buttons button').removeAttr("disabled");
                    //saveFormInMemory($("form.form-data"));
                    var postData =
                        ICE.postVars[ICE.formVars.form] || ICE.postVars.form;
                    if (data.uri !== undefined && data.uri !== "") {
                        postData.uri = data.uri;
                        postData.page = data.page;
                    }
                    if (data.redirect !== undefined && data.redirect !== "") {
                        postData.referer = data.redirect;
                    }
                    if (postData.childID) {
                        delete postData.childID;
                    }
                    var finalUrl = removeURLParameter(
                        window.location.href.split("#")[0],
                        "childID"
                    );
                    ICE.post(finalUrl, postData);
                }
                $("#action-cancel, #action-preview").removeAttr("disabled");
            },
            error: function () {
                $("#save-alert").css("display", "block");
                $(".ldse-alert-text").text("Error, changes not saved");
                $("#ldse-toolbar-buttons button").removeAttr("disabled");
            },
        });
        return false;
    });

    CKEDITOR.on("instanceReady", function () {
        updateCkeditors();
    });
    titanImageLoading();
    Preview.init();
    Enrich.init();
});

var Enrich = {
    init: function () {
        //toggle metatdata
        $("#enrich-info").on(
            "click",
            ".ldse-enrich-sidebar .enrich-list-name",
            Enrich.showMetadata
        );

        //toggle checked
        $("#enrich-info").on(
            "click",
            ".ldse-enrich-sidebar .enrich-list-form input",
            Enrich.toggleChecked
        );
    },
    updateChecked: function () {
        $("#enrich-info .ldse-enrich-sidebar .enrich-list-form input").each(
            Enrich.toggleChecked
        );
    },
    showMetadata: function () {
        var self = $(this),
            sibling = $(this).parent().siblings();
        if (sibling.length > 0) {
            sibling.toggle({
                duration: 0,
                complete: function () {
                    var enrichClass =
                        self
                            .closest("div")
                            .children(":input")
                            .attr("data-enrichClass") || "";
                    if (enrichClass !== "") {
                        if (sibling.is(":visible")) {
                            $(
                                "#enrich-info .ldse-enrich-text" +
                                    " ." +
                                    enrichClass
                            ).addClass("highlight");
                        } else {
                            $(
                                "#enrich-info .ldse-enrich-text" +
                                    " ." +
                                    enrichClass
                            ).removeClass("highlight");
                        }
                    }
                },
            });
        }
    },
    toggleChecked: function () {
        var enrichClass = $(this).attr("data-enrichClass") || "";
        var parent = $(this).closest(".enrich-list-form");

        //first toggle the class to show whether an item is checked or not
        //second remove the word highlight from the text area
        if ($(this).is(":checked")) {
            parent.removeClass("enrich-disabled");
            if (enrichClass !== "") {
                $(
                    "#enrich-info .ldse-enrich-text" + " ." + enrichClass
                ).removeClass("no-keyword");
            }
        } else {
            parent.addClass("enrich-disabled");
            if (enrichClass !== "") {
                $(
                    "#enrich-info .ldse-enrich-text" + " ." + enrichClass
                ).addClass("no-keyword");
            }
        }
    },
};

/* HISTORY FUNCTIONS*/
var H = {
    events: {},
    page: 1,
    maxPage: 1,
    pageLength: 25,
    maxPageDiv: $("#historyMaxPage"),
    elements: {
        infoDiv: $("#history-info"),
        listDiv: $("#history-list"),
        nextArrow: $("#historyNext"),
        prevArrow: $("#historyPrevious"),
        currentPage: $("#historyCurPage"),
        maxPage: $("#historyMaxPage"),
    },
    setup: function () {
        H.updateMaxPage();
        H.updatePageLink();
        H.renderPage();
    },
    renderPage: function () {
        var start = (H.page - 1) * H.pageLength;
        var end = H.page * H.pageLength;
        var data = {
            events: H.events.slice(start, end),
        };
        $(".ldse-history-information").html(H.events.length);
        H.elements.listDiv.html(historyEventsTemplate(data));
        processLineBreaks();
        H.updatePagination();
    },
    updateMaxPage: function () {
        H.maxPage = Math.ceil(H.events.length / H.pageLength);
        if (H.maxPage < 1) {
            H.maxPageDiv.html(1);
        } else {
            H.maxPageDiv.html(H.maxPage);
        }
    },
    updatePagination: function () {
        if (H.page === H.maxPage) {
            H.elements.nextArrow.addClass("faded");
            H.elements.nextArrow.addClass("disabled");
        } else {
            H.elements.nextArrow.removeClass("faded");
        }
        if (H.page === 1) {
            H.elements.prevArrow.addClass("faded");
            H.elements.prevArrow.addClass("disabled");
        } else {
            H.elements.prevArrow.removeClass("faded");
        }
    },
    changePageSize: function (value) {
        if (H.pageLength !== value) {
            H.pageLength = value;
            H.updatePageLink();
            H.updateMaxPage();
            H.changePage(1);
            H.renderPage();
        }
    },
    updatePageLink: function () {
        var pageSizeElement = $(
            "span.ldse-pagination--shownum a[data-count=" + H.pageLength + "]"
        )[0];
        $("span.ldse-pagination--shownum a").not("[href]").attr("href", "#d");
        $(pageSizeElement).removeAttr("href");
    },
    changePage: function (value) {
        if (H.page !== value) {
            H.page = value;
            H.elements.currentPage.html(H.page);
            H.renderPage();
        }
    },
    nextPage: function () {
        if (H.page < H.maxPage) {
            H.changePage(H.page + 1);
        }
    },
    previousPage: function () {
        if (H.page > 1) {
            H.changePage(H.page - 1);
        }
    },
};
var comment = {
    html: $("html"),
    page: 1,
    maxPage: 1,
    pageLength: 25,
    currentPage: $("#commentCurrentPage"),
    maxPageDiv: $("#commentMaxPage"),
    comments: [],
    currentComments: [],
    elements: {
        nextArrow: $("#string-managerNext") /*arrow link right*/,
        prevArrow: $("#string-managerPrevious") /*arrow link left*/,
        currentPage: $(
            "#string-managerCurrentPage"
        ) /*current pagination span*/,
        maxPage: $("#string-managerMaxPage") /*total pagination span*/,
        commentListDiv: $("#commentslist"),
    },
    renderPage: function () {
        var start = (comment.page - 1) * comment.pageLength;
        var end = comment.page * comment.pageLength;
        var data = { comments: comment.comments.slice(start, end) };
        $(".ldse-comments-information").html(comment.comments.length);
        comment.elements.commentListDiv.html(commentTemplate(data));
        comment.updatePagination();
    },
    setup: function () {
        comment.updateMaxPage();
        comment.updatePageLink();
        comment.renderPage();
        comment.currentPage.html("1");
    },
    trashCan: function (e) {
        var removeComment = $(e).closest(".ldse-comment").attr("id");
        var commentArea = $("#commentsBox");
        var id = commentArea.data("id");
        var locale = commentArea.data("locale");
        $.ajax({
            type: "post",
            dataType: "json",
            data: {
                locale: locale,
                id: id,
                commentId: removeComment,
            },
            url: sharedPrefix + "/form/ajax/remove-comment?lang=eng",
        });
        $(e).closest(".ldse-comment").remove();
        for (var i = 0; i < comment.comments.length; ++i) {
            if (comment.comments[i].commentId == removeComment) {
                comment.comments.splice(i, 1);
                comment.renderPage();
            }
        }
    },
    saveComment: function () {
        var commentArea = $("#commentsBox");
        var text = commentArea.val();
        if (text === "") {
            return false;
        }
        var id = commentArea.data("id");
        var locale = commentArea.data("locale");
        var uri = commentArea.data("uri");
        $.ajax({
            type: "post",
            dataType: "json",
            data: {
                comments: text,
                locale: locale,
                id: id,
            },
            url: sharedPrefix + "/form/ajax/save-comments?lang=eng",
            success: function (data) {
                comment.comments.unshift(data);
                comment.renderPage();
                commentArea.val("");
                commentArea.focus();
                $("#addComment").attr("disabled", "disabled");
            },
            error: function (x, y, z) {
                var hole = 0;
            },
        });
    },
    toggleAddCommentButton: function () {
        if ($("#commentsBox").val().trim() !== "") {
            $("#addComment").removeAttr("disabled");
        } else {
            $("#addComment").attr("disabled", "disabled");
        }
    },
    changePage: function (value) {
        if (comment.page !== value) {
            comment.page = value;
            comment.currentPage.html(comment.page);
            comment.renderPage();
        }
    },
    updateMaxPage: function () {
        comment.maxPage = Math.ceil(
            comment.comments.length / comment.pageLength
        );
        if (comment.maxPage < 1) {
            comment.maxPageDiv.html(1);
        } else {
            comment.maxPageDiv.html(comment.maxPage);
        }
    },
    updatePageLink: function () {
        var pageSizeElement = $(
            "span.ldse-pagination--shownum a[data-count=" +
                comment.pageLength +
                "]"
        )[0];
        $("span.ldse-pagination--shownum a").not("[href]").attr("href", "#d");
        $(pageSizeElement).removeAttr("href");
    },
    nextPage: function () {
        if (comment.page < comment.maxPage) {
            comment.changePage(comment.page + 1);
        }
    },
    previousPage: function () {
        if (comment.page > 1) {
            comment.changePage(comment.page - 1);
        }
    },
    updatePagination: function () {
        if (comment.page === comment.maxPage) {
            comment.elements.nextArrow.addClass("faded");
            comment.elements.nextArrow.addClass("disabled");
        } else {
            comment.elements.nextArrow.removeClass("faded");
        }
        if (comment.page === 1) {
            comment.elements.prevArrow.addClass("faded");
            comment.elements.prevArrow.addClass("disabled");
        } else {
            comment.elements.prevArrow.removeClass("faded");
        }
    },
    changePageSize: function (value) {
        if (comment.pageLength !== value) {
            comment.pageLength = value;
            comment.updatePageLink();
            comment.updateMaxPage();
            comment.changePage(1);
            comment.renderPage();
        }
    },
    showLoading: function () {
        comment.html.addClass("loading");
    },
    clearLoading: function () {
        comment.html.removeClass("loading");
    },
};
//$.ajaxSetup({
//	beforeSend : comment.showLoading,
//	complete : comment.clearLoading
//});

function editResourceForm(lang, bundle, key) {
    var currentPage = decodeURIComponent(document.location.pathname);
    var path =
        sharedPrefix + "/ice/resources/ajax/resource/editResourceForm?lang=eng";

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
            var div = $(
                '<div class="editResourceForm"><header class="ldse-section--header"><h2>Resource Editing</h2></header>' +
                    html +
                    "</div>"
            );
            div.find("input:submit").closest("tr").remove();

            div.find("table").after(
                "<div class='ldse-buttons'><button class='ldse-button ldse-icon-save primary' onclick='saveResourceForm(); return false;'>Save</button><button class='ldse-button ldse-icon-x cancel'>Cancel</button></div>"
            );
            div.find("td").css("width", "auto");
            modal.find("div").remove();
            modal.append(div).trigger("open");
            modal.find(".ldse-button.cancel").click(function () {
                modal.trigger("close");
                return false;
            });
        },
    });
}

function saveResourceForm() {
    var newValue = $("textarea[name='newValue']").val();
    var key = $("input[name='key']").val();
    var bundle = $("input[name='bundle']").val();

    modal.trigger("close");
    modal.find("div").remove();
    var div =
        "<div class='saving'><header class='ldse-section--header'><h2>Resource Editiing</h2></header><div>Saving...</div></div>";
    modal.append(div).trigger("open");

    $.ajax({
        type: "POST",
        url:
            sharedPrefix +
            "/ice/resources/ajax/resource/updateResource?lang=eng&locale=eng",
        data: {
            bundle: bundle,
            key: key,
            newValue: newValue,
        },
        success: function () {
            modal.trigger("close");
            $("a.edit-resourceForm.key-" + key)
                .closest("dt")
                .find("label")
                .text(newValue);
        },
        success: function () {
            modal.trigger("close");
            $("a.edit-resourceForm.key-" + key)
                .closest("dt")
                .find("label")
                .text(newValue);
        },
    });
}

function removeURLParameter(url, parameter) {
    var urlparts = url.split("?");
    if (urlparts.length >= 2) {
        var prefix = encodeURIComponent(parameter) + "=";
        var pars = urlparts[1].split(/[&;]/g);

        //reverse iteration as may be destructive
        for (var i = pars.length; i-- > 0; ) {
            //idiom for string.startsWith
            if (pars[i].lastIndexOf(prefix, 0) !== -1) {
                pars.splice(i, 1);
            }
        }

        url = urlparts[0] + "?" + pars.join("&");
        return url;
    } else {
        return url;
    }
}

function searchTitan() {
    var colTemplate;
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
    var newValue = $("textarea[name='newValue']").val();
    var key = $("input[name='key']").val();
    var bundle = $("input[name='bundle']").val();

    modal.trigger("close");
    modal.find("div").remove();
    var div =
        "<div class='saving'><header class='ldse-section--header'><h2>Resource Editiing</h2></header><div>Saving...</div></div>";
    modal.append(div).trigger("open");
}

/* Validates ckeditor of type wysiwyg of a form by explicit call to validation plugin
   Utilized to overcome validation pluging bug when dealing with ckeditors */
function validateWysiwyg(formSelector) {
    var isValid = true;
    var wysiwyg = $(formSelector).find('[type="wysiwyg"].required');
    if (wysiwyg.length > 0) isValid = $(wysiwyg).valid();
    return isValid;
}

function titanImageRefresh(image) {
    let inputEl = $(image)
        .parent()
        .siblings("dd")
        .find('input[type="hidden"]')
        .not("[data-type-generic]");
    let imgEl = $(image).parent().siblings("dd").find("img");
    if (image.value.length > 0) {
        if (
            $(inputEl).val() === undefined ||
            $(inputEl).val() === null ||
            $(inputEl).val() === ""
        ) {
            $(inputEl).val(ICE.apiVars.contentApiAsset + "/" + image.value);
        }
        if (
            $(imgEl).attr("src") === undefined ||
            $(imgEl).attr("src") === null ||
            $(imgEl).attr("src") === ""
        ) {
            $(imgEl).attr(
                "src",
                ICE.apiVars.contentApiAsset + "/" + image.value
            );
        }
    }
}

function titanImageLoading() {
    let titanImages = document.querySelectorAll('input[data-type="image"]');
    titanImages.forEach((image) => {
        titanImageRefresh(image);
    });
}

function validateTitan(formSelector) {
    var isValid = true;
    var titanAssets = $(formSelector).find("input[data-type]");
    if (titanAssets.length > 0) {
        titanAssets.each(function () {
            var titanAsset = $(this);
            var titanType = $(titanAsset).attr("data-type");
            var span = $(titanAsset).closest("dl").find("dd>span");
            var titanInputName = $(titanAsset).attr("name");
            var titanHiddenAsset = $(titanAsset)
                .closest("dl")
                .find("dd>input[name=" + titanInputName + "]")[1];
            if ($(titanAsset).val().length > 0 && titanType !== "image") {
                if ($(titanHiddenAsset).val() !== $(span).text()) {
                    $(titanHiddenAsset).attr("value", $(span).text());
                }
            }
            if (
                $(titanAsset).siblings('label[class="error"]:not:empty')
                    .length > 0
            ) {
                isValid = isValid && false;
            }
        });
    }
    return isValid;
}

function cleanupDisplayDependency() {
    document
        .querySelectorAll("[display-dependency-reset-value]")
        .forEach((e) => {
            const resetValue = e.getAttribute("display-dependency-reset-value");
            let container = $(e).closest("dl");
            if (container.css("display") === "none") {
                e.value = resetValue;
                container.find(".text")?.text(resetValue);
                container.find(".chosen-select")?.val(resetValue);
            }
        });
}
