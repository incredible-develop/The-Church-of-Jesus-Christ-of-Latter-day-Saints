(() => {
    "use strict";
    angular.module("LDSP", []);
    var ts = angular.module("LDSP");
    ts.component("titanSearch", {
        templateUrl: sharedPrefix + "/ice/resources/ajax/titanSearch.html",
        controller: function ($http) {
            var self = this;
            self.search = {
                term: "",
            };
            self.sharedPrefix = sharedPrefix;
            self.getResults = (term, page, selected, path) => {
                var type = titanInput.getAttribute("data-type");
                if (type === "generic") {
                    type = "";
                }
                document.getElementsByTagName("html")[0].classList +=
                    " loading";
                $http
                    .get(
                        sharedPrefx +
                            "/ice/titan-search?lang=eng&term=" +
                            term +
                            "&page=" +
                            page +
                            "&selected=" +
                            selected +
                            "&type=" +
                            type +
                            "&path=" +
                            path
                    )
                    .then(function (data) {
                        self.results = data.data;
                        self.pages = data.data.pages[0];
                        document
                            .getElementsByTagName("html")[0]
                            .classList.remove("loading");
                        self.updatePagination(data.data.pages[0]);
                    });
            };
            self.getChildren = (path) => {
                document.getElementsByTagName("html")[0].classList +=
                    " loading";
                $http
                    .get(
                        sharedPrefx +
                            "/ice/titan-item-children?lang=eng&path=" +
                            path
                    )
                    .then(function (data) {
                        self.buildChildCollectionAssests(data.data);
                        document
                            .getElementsByTagName("html")[0]
                            .classList.remove("loading");
                    });
            };
            self.hide = () => {
                var otherModal = document.getElementById("modal1");
                if (self.selected && self.selected != "") {
                    var type = titanInput.getAttribute("data-type"),
                        collection = titanInput.getAttribute("data-collection"),
                        availInputs =
                            titanInput.parentElement.parentElement.getElementsByTagName(
                                "input"
                            ),
                        setInput;
                    for (var i = 0; i < availInputs.length; i++) {
                        if (availInputs[i].hasAttribute("data-type")) {
                            setInput = availInputs[i];
                        }
                    }
                    var input =
                            setInput ||
                            titanInput.parentElement.getElementsByTagName(
                                "ul"
                            )[0] ||
                            availInputs[0],
                        name = titanInput.getAttribute("data-name"),
                        inputId;

                    if (input !== undefined && input.hasAttribute("id")) {
                        inputId = input.getAttribute("id");
                    } else {
                        inputId = "";
                    }
                    if (collection == "collection") {
                        var ul =
                                titanInput.parentElement.getElementsByTagName(
                                    "ul"
                                )[0],
                            liCount = ul.getElementsByTagName("li").length + 1;
                        ul.innerHTML +=
                            '<li class="repeated-item"><dl><span class="correlation-not-approved warning float-left" style="display:none;"><span class="ldse-icon-ko-warning ldse-icon ldse-info-banner-icon">Warning</span>' +
                            '<label>Cor-IP / Cor-Eval not approved for publishing</label></span></span><a href="#d" class="sprite delete ldse-icon-ko-remove bottom float-right deleteListItem"></a><input type="hidden" name="' +
                            name +
                            '-child" class="child" value="' +
                            liCount +
                            '"/>' +
                            '<div class="correlation-not-approved" style="display:none;">&nbsp;</div><div>Type: ' +
                            type +
                            '</div><fieldset class="table"><dl><dd><input type="hidden" name="' +
                            name +
                            "-" +
                            liCount +
                            '" value="' +
                            self.selected.id +
                            '"></input>' +
                            '<input type="hidden" name="' +
                            name +
                            "-" +
                            liCount +
                            '" value="' +
                            self.selected.title +
                            '"></input><input type="hidden" name="' +
                            name +
                            "-" +
                            liCount +
                            '" value="' +
                            type +
                            '"></input><h3><a href="' +
                            self.selected.id +
                            '">' +
                            self.selected.title +
                            "</a></h3></dd></dl></fieldset></li>";
                    } else {
                        switch (type) {
                            case "image":
                                titanInput.parentElement.parentElement
                                    .querySelector(
                                        "img#" + inputId + "-preview"
                                    )
                                    .setAttribute("src", self.selected.image);
                                document.getElementById(
                                    inputId + "-titan-image-hidden"
                                ).value = self.selected.image;
                                /*                                document.getElementById(inputId + '-preview').setAttribute('src', content-api-url + '/id/' + self.selected.id);*/
                                if (
                                    self.selected.id != "" &&
                                    self.selected.id != undefined
                                ) {
                                    input.value = self.selected.id;
                                }
                                break;
                            case "audio":
                                document.getElementById(
                                    inputId + "-track-title-hidden"
                                ).value = self.selected.title;
                                document.getElementById(
                                    inputId + "-track-title-preview"
                                ).innerHTML = self.selected.title;
                                if (
                                    self.selected.id != "" &&
                                    self.selected.id != undefined
                                ) {
                                    input.value = self.selected.id;
                                }
                                break;
                            case "video":
                                document.getElementById(
                                    inputId + "-title-hidden"
                                ).innerHTML = self.selected.title;
                                document.getElementById(
                                    inputId + "-title-preview"
                                ).innerHTML = self.selected.title;
                                if (
                                    self.selected.id !== "" &&
                                    self.selected.id !== undefined
                                ) {
                                    input.value = self.selected.id;
                                }
                                break;
                            case "pdf":
                                document.getElementById(
                                    inputId + "-title-hidden"
                                ).value = self.selected.title;
                                document.getElementById(
                                    inputId + "-title-preview"
                                ).innerHTML = self.selected.title;
                                if (
                                    self.selected.id != "" &&
                                    self.selected.id != undefined
                                ) {
                                    input.value = self.selected.id;
                                }
                                break;
                            case "html5":
                                document.getElementById(
                                    inputId + "-preview"
                                ).innerHTML = self.selected.title;
                                document.getElementById(
                                    inputId + "-hidden"
                                ).value = self.selected.title;
                                document.getElementById(
                                    inputId + "-uri-hidden"
                                ).value = self.selected.uri;
                                document.getElementById(
                                    inputId + "-lang-hidden"
                                ).value = self.selected.lang;
                                if (
                                    self.selected.id != "" &&
                                    self.selected.id != undefined
                                ) {
                                    input.value = self.selected.id;
                                }
                                break;
                            case "collection":
                                document
                                    .getElementById(inputId + "-preview")
                                    .setAttribute(
                                        "src",
                                        ICE.apiVars.contentApiUrl +
                                            "/id/" +
                                            self.selected.id
                                    );
                                if (
                                    self.selected.id != "" &&
                                    self.selected.id != undefined
                                ) {
                                    input.value = self.selected.id;
                                }
                                self.getCollectionAssets(self.selected.path);
                                break;
                            case "generic":
                                var idElm = $(titanInput)
                                    .parent()
                                    .siblings("dd")
                                    .find('[id="' + inputId + '"]');
                                var inputElm = $(titanInput)
                                    .parent()
                                    .siblings("dd")
                                    .find(
                                        '[id="' +
                                            (inputId + "-title-hidden") +
                                            '"]'
                                    );
                                var thumbElm = $(titanInput)
                                    .parent()
                                    .siblings("dd")
                                    .find(
                                        '[id="' +
                                            (inputId + "-thumb-hidden") +
                                            '"]'
                                    );
                                var previewElm = $(titanInput)
                                    .parent()
                                    .siblings("dd")
                                    .find(
                                        '[id="' +
                                            (inputId + "-title-preview") +
                                            '"]'
                                    );
                                var typeElm = $(titanInput)
                                    .parent()
                                    .siblings("dd")
                                    .find(
                                        '[id="' +
                                            (inputId + "-type-hidden") +
                                            '"]'
                                    );
                                var typeSpan = $(titanInput)
                                    .parent()
                                    .siblings("dt")
                                    .find("span[data-type-generic]");
                                var img = $(titanInput)
                                    .parent()
                                    .siblings("dd")
                                    .find("img");
                                var genericType =
                                    self.selected.type.toLowerCase();
                                if (genericType !== "image") {
                                    $(previewElm).html(self.selected.title);
                                    $(inputElm).attr(
                                        "value",
                                        self.selected.title
                                    );
                                    $(thumbElm).attr("value", "");
                                    $(img).attr("src", "");
                                } else {
                                    $(inputElm).attr("value", "");
                                    $(previewElm).html("");
                                    $(thumbElm).attr(
                                        "value",
                                        self.selected.image
                                    );
                                    $(img).attr("src", self.selected.image);
                                }
                                $(typeElm).attr("value", genericType);
                                $(typeSpan).html(
                                    genericType.replace(/^\w/, (c) =>
                                        c.toUpperCase()
                                    )
                                );
                                $(idElm).attr("data-type", genericType);
                                if (
                                    self.selected.id != "" &&
                                    self.selected.id != undefined
                                ) {
                                    input.value = self.selected.id;
                                }
                                break;
                            default:
                                document
                                    .getElementById(inputId + "-preview")
                                    .setAttribute(
                                        "src",
                                        ICE.apiVars.contentApiUrl +
                                            "/id/" +
                                            self.selected.id
                                    );
                                if (
                                    self.selected.id != "" &&
                                    self.selected.id != undefined
                                ) {
                                    input.value = self.selected.id;
                                }
                        }
                        // call the changed event when programmatically changing the value, where a change event won't normally fire
                        var event = new Event("change");

                        // Dispatch it.
                        input.dispatchEvent(event);
                    }
                }
                document.getElementById("titanModal").style.display = "none";
                if (otherModal.getAttribute("style").indexOf("display") > -1) {
                    document.getElementsByClassName(
                        "ldse-modal-backdrop"
                    )[0].style.display = "none";
                }
                self.results = [];
                self.search.term = "";
            };
            self.updatePagination = (pages) => {
                var page = pages.selected;
                var count = 5;
                var totalPages = Math.ceil(pages.total / pages.rows);
                if (
                    (totalPages == page ||
                        totalPages == page - 1 ||
                        totalPages == page - 2) &&
                    totalPages > 5
                ) {
                    self.pages.next = false;
                    self.pages.previous = true;
                    self.pages.pages = [];
                    var num = page;
                    for (var i = 0; i < count && i < totalPages; i++) {
                        self.pages.pages.push({ page: num - 1 });
                        num--;
                    }
                } else if (page == 1 || page == 2 || page == 3) {
                    self.pages.previous = false;
                    self.pages.next = totalPages > count ? true : false;
                    self.pages.pages = [];
                    var num = 0;
                    for (var i = 0; i < count && i < totalPages; i++) {
                        self.pages.pages.push({ page: num + 1 });
                        num++;
                    }
                } else {
                    self.pages.previous = true;
                    self.pages.next = true;
                    self.pages.pages = [];
                    var start = page - 2;
                    for (var i = 0; i < count && i < totalPages; i++) {
                        self.pages.pages.push({ page: start });
                        start++;
                    }
                }
            };
            self.pageChange = (page, selected) => {
                self.getResults(self.search.term, page, selected, "");
            };
            self.setSelected = (item) => {
                self.selected = item;
            };
            self.getCollectionAssets = (path) => {
                self.getChildren(path);
            };
            self.buildChildCollectionAssests = (items) => {
                var inputs = document.getElementsByClassName("titanFormItem"),
                    ul,
                    name,
                    count;
                for (var i = 0; i < items.length; i++) {
                    for (var n = 0; n < inputs.length; n++) {
                        if (inputs[n].getAttribute("data-name")) {
                            ul =
                                inputs[n].parentElement.getElementsByTagName(
                                    "ul"
                                )[0];
                            name = inputs[n].getAttribute("data-name");
                        }
                    }
                    count = i + 1;
                    ul.innerHTML +=
                        '<li class="repeated-item"><dl><span class="correlation-not-approved warning float-left" style="display:none;"><span class="ldse-icon-ko-warning ldse-icon ldse-info-banner-icon">Warning</span>' +
                        '<label>Cor-IP / Cor-Eval not approved for publishing</label></span></span><a href="#d" class="sprite delete ldse-icon-ko-remove bottom float-right deleteListItem"></a><input type="hidden" name="' +
                        name +
                        '-child" class="child" value="' +
                        count +
                        '"/>' +
                        '<div class="correlation-not-approved" style="display:none;">&nbsp;</div><div>Type: ' +
                        items[i].result.type +
                        '</div><fieldset class="table"><dl><dd><input type="hidden" name="' +
                        name +
                        "-" +
                        count +
                        '" value="' +
                        items[i].result.id +
                        '"></input>' +
                        '<input type="hidden" name="' +
                        name +
                        "-" +
                        count +
                        '" value="' +
                        items[i].result.title +
                        '"></input><input type="hidden" name="' +
                        name +
                        "-" +
                        count +
                        '" value="' +
                        items[i].result.type +
                        '"></input><h3><a href="' +
                        items[i].result.id +
                        '">' +
                        items[i].result.title +
                        "</a></h3></dd></dl></fieldset></li>";
                }
            };
        },
    });
})();
