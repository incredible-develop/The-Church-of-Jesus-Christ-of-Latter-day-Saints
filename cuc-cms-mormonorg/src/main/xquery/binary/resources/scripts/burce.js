var burke = new Burke_model(),
    details = new Details_view(),
    imageCropper = new ImageCropper(),
    imageCropperLoaded = false,
    modal = $('#modal1').trigger('close');
    main = null; // Used for keeping the main html from inside the wrapper class in memory.

function includeCSS(src) {
    var element = document.createElement("link");
    element.rel = "stylesheet";
    element.type = "text/css";
    element.href = src;
    document.head.appendChild(element);
}

function includeJS(src) {
    var element = document.createElement("script");
    element.type = "text/javascript";
    element.src = src;
    document.head.appendChild(element);
}



function createBC(config) {
    'use strict';
    //Config breakdown
    //REQUIRED
    // adminLibrary = Boolean, whether this is a stand alone page or modal
    // apiUrl = the base URL for the API that it will be communicating with
    // wrapperSelector = The class that will act as the wrapper for the system
    // libraryUrl = the location of the admin library (for manage library link)
    // updateArticle = This must be a boolean that if true indicates we are editing/updating an existing article !IMPORTANT!

    // OPTIONAL
    // contentType = the Tab that defaults to being open (not needed in the stand alone which has no tabs)
    // articleURI = the URI if this is a modal with a specific article
    // baseURI = The base URI for the first bucket of content
    // noArticle = boolean for when you want ckEditor to work without articleURI
    // textareaID = ID of the textarea that is being turned into CKEDITOR. Uses the first one on the page
    // inputID = the id of the input to update
    // allowedFileExtensions = the file extension to filter on
    // hideTabs = boolean for hiding the not shown tab.
    // scrollBatch = size of each batch when loading while scrolling
    //      if this is not passed in



    //setup storage for burke
    burke = new Burke_model();
    // Remove trailling slash
    if(config.apiUrl.substr(-1) == '/') {
        config.apiUrl = config.apiUrl.substr(0, config.apiUrl.length - 1);
    }
    burke.set('adminLibrary', config.adminLibrary);
    burke.set('wrapperSelector', config.wrapperSelector);
    burke.set('apiUrl', config.apiUrl);
    burke.set('libraryUrl', config.libraryUrl);
    burke.set('noArticle', config.noArticle);
    burke.set('updateArticle', config.updateArticle);
    burke.set('fileRoot', config.fileRoot);

  //set the textarea that is ckeditor, if not passed in use the first one
    if(!burke.get('adminLibrary') && typeof config.inputID === 'undefined' && config.inputID === undefined){
        if(typeof config.textareaID !== 'undefined'){
            burke.set('textareaID', config.textareaID);
        }else{
            for(var i in CKEDITOR.instances){
                burke.set('textareaID', i);
                break;
            }
        }
    }else {
        burke.set('textareaID', null);
    }

    if (burke.get('adminLibrary')) {
        burke.set('activeTab', 'all');
    }

    if (typeof config.articleURI !== 'undefined' && config.articleURI !== undefined) {
        burke.set('articleURI', config.articleURI);
    } else {
        burke.set('articleURI', '');
    }

    if (typeof config.scrollBatch !== 'undefined' && config.scrollBatch !== undefined) {
        burke.set('scrollBatch', config.scrollBatch);
    } else {
        burke.set('scrollBatch', 1000);
    }

    if (typeof config.contentType !== 'undefined' && config.contentType !== undefined) {
        burke.set('contentType', config.contentType);
        if (config.contentType === "image" || config.contentType === "other") {
            burke.set('activeTab', config.contentType);
        }
    } else {
        burke.set('contentType', '');
    }

    if (typeof config.baseURI !== 'undefined') {
        burke.set('baseURI', config.baseURI);
    }

    if (typeof config.hideTabs !== 'undefined' && config.hideTabs !== undefined) {
        burke.set('hideTabs', config.hideTabs);
    }

    if (typeof config.inputID !== 'undefined' && config.inputID !== undefined) {
        burke.set('inputID', config.inputID);
    } else {
        burke.set('inputID', '');
    }
    burke.set('activeURI', burke.get('baseURI'));

    burke.set('allowedHeight', config.allowedHeight || "");
    burke.set('allowedWidth', config.allowedWidth || "");
    burke.set('minHeight', config.minHeight);
    burke.set('minWidth', config.minWidth);
    //setup allowed File Types
    if (typeof config.allowedFileExtensions !== 'undefined' && config.allowedFileExtensions !== undefined && config.allowedFileExtensions.length !== 0) {
        burke.set('allowedFileExtensions', config.allowedFileExtensions);
    } else {
        burke.set('allowedFileExtensions', [
            "pdf", "xls", "xlsx", "xltm", "doc", "docx", "pps", "ppsx", "ppt", "ppx", "xltx",
            "bmp", "gif", "jpg", "jpeg", "png", "tif"]);

        $.ajax({
            type: "POST",
            dataType: "json",
            url: burke.get('apiUrl') + "?lang=eng&fn=types",
            success: function (data) {
                burke.set('allowedFileExtensions', data.ext);
            }
        });
    }

    //MAYBE TODO switch to JSONp?
    $('.' + burke.get('wrapperSelector')).html(
            '<div class="bc-tools"><a href="#image" class="bc-tab active">Images</a><a href="#other" class="bc-tab">Other</a><a href="#close" class="close-cancel tr">Close</a><a href="' + burke.get('libraryUrl') + '" class="btn">Manage Library</a><form id="bc-tools-form" class="search"><input type="text" name="bc-tools-search" id="bc-tools=search" class="search" /><input type="submit" class="bc-search-button" value=" " /></form></div><div class="bc-column-header-wrapper cf"><div class="bc-column-header"><a href="#back" class="back-button tr inactive">Back</a><a href="#next" class="next-button tr inactive">Next</a></div><div class="bc-column-header"></div></div><div class="bc-column-window"><div class="bc-column-wrapper"><div class="bc-column"><div class="bc-column-content"><div class="bc-column-new-folder"></div></div></div><div class="bc-column"><div class="bc-column-content"><div class="bc-column-new-folder"></div></div></div></div></div><div class="bc-details" id="bc-details-pane"></div><div class="bc-target" id="bc-drop-zone"><div class="bc-drop-zone-pre"><p>Please choose a folder to upload files into</p></div><div class="bc-drop-zone-decor hidden"><p>Drop one or more files here</p><p>or</p><button name="uploadFile" class="upload">Select Files</button><input type="file" id="bc-drop-zone-input" name="files[]" multiple="true" /></div></div>');

    if (burke.get('hideTabs')) {
        $('.bc-tools a.bc-tab').show();
        if (burke.get('contentType') === 'image') {
            $('.bc-tools a.bc-tab[href="#other"]').hide();
        } else if (burke.get('contentType') === 'other') {
            $('.bc-tools a.bc-tab[href="#image"]').hide();
        }
    }
    var domChecker = function () {
        if ($('#bc-drop-zone').length > 0) {
            bcInit();
        } else {
            setTimeout(domChecker, 100);
        }
    };
    setTimeout(domChecker, 100);
}

function resetBC(config) {
    'use strict';
    //set the textarea that is ckeditor, if not passed in use the first one
    if(!burke.get('adminLibrary') && typeof config.inputID === 'undefined' && config.inputID === undefined){
        if(typeof config.textareaID !== 'undefined'){
            burke.set('textareaID', config.textareaID);
        }else{
            for(var i in CKEDITOR.instances){
                burke.set('textareaID', i);
                break;
            }
        }
    }else {
        burke.set('textareaID', null);
    }

    if (typeof config.inputID !== 'undefined' && config.inputID !== undefined) {
        burke.set('inputID', config.inputID);
    } else {
        burke.set('inputID', '');
    }
    burke.set('allowedHeight', config.allowedHeight);
    burke.set('allowedWidth', config.allowedWidth);
    burke.set('minHeight', config.minHeight);
    burke.set('minWidth', config.minWidth);
    //setup allowed File Types
    if (typeof config.allowedFileExtensions !== 'undefined' && config.allowedFileExtensions !== undefined && config.allowedFileExtensions.length !== 0) {
        burke.set('allowedFileExtensions', config.allowedFileExtensions);
    } else {
        $.getJSON(burke.get('apiUrl'), { lang: 'eng', fn: 'types'  }, function (data) {
            burke.set('allowedFileExtensions', data.ext);
        });
    }
    if (typeof config.contentType !== 'undefined' && config.contentType !== undefined) {
        if (burke.get('contentType') !== config.contentType) {
            burke.set('contentType', config.contentType);
            $(".bc-tools a[href*='" + config.contentType + "']").click();
        }
        if (config.contentType === "image" || config.contentType === "other") {
            burke.set('activeTab', config.contentType);
        }
    } else {
        burke.set('contentType', '');
    }
    if (typeof config.hideTabs !== 'undefined' && config.hideTabs !== undefined) {
        burke.set('hideTabs', config.hideTabs);
    }
    if (burke.get('hideTabs')) {
        $('.bc-tools a.bc-tab').show();
        if (burke.get('contentType') === 'image') {
            $('.bc-tools a.bc-tab[href="#other"]').hide();
        } else if (burke.get('contentType') === 'other') {
            $('.bc-tools a.bc-tab[href="#image"]').hide();
        }
    }

    if(details !== null){
        details.render();
    }
}

function setupDropZone() {
    'use strict';
    var dz = document.getElementById("bc-drop-zone");

    // init event handlers
    dz.addEventListener("dragenter", noopHandler, false);
    dz.addEventListener("dragexit", noopHandler, false);
    dz.addEventListener("dragover", noopHandler, false);
    dz.addEventListener("drop", drop, false);

    $('.bc-drop-zone-pre').addClass('hidden');
    $('.bc-drop-zone-decor').removeClass('hidden');

    $('.bc-drop-zone-decor .upload').on('click', function () {
        $('#bc-drop-zone-input').click();
    });
    $('#bc-drop-zone-input').on('change', function (evt) {
        var files = evt.target.files,
            fileHolder = [],
            i;

        for (i = 0; i < files.length; i++) {
            fileHolder[i] = new File_model();
            fileHolder[i].init(files[i]);
            fileHolder[i].readFile();
        }
        $(this).val('');
    });
}
function setupSearchBox() {
    'use strict';
    if (!burke.get('searchSetup')) {
        if (burke.get('adminLibrary')) {
            $('#filter-box').val('');
            $('#filter-box').on('keyup', function (e) {
                var query = $(this).val();
                if (e.keyCode === 13) {
                    handleSearch(query);
                    //store the search in the left hand bar
                    $('.folder.active').removeClass('active');
                    $('.bc-column:first').find('ul').append('<li class="search-folder folder active" data-uri="' + query + '"><a href="' + query + '"><span class="search"></span>' + query.truncate(30) + '</a></li>');

                    return false;
                }
            });
            burke.set('searchSetup', true);
        } else {
            $('.bc-tools form').unbind('submit');

            $('.bc-tools form').submit(function () {
                //form processing stuff goes here
                var query = $('.bc-tools form input.search').val();

                handleSearch(query);

                //store the search in the left hand bar
                $('.folder.active').removeClass('active');
                $('.bc-column:first').find('ul').append('<li class="search-folder folder active" data-uri="' + query + '"><a href="' + query + '"><span class="search"></span>' + query.truncate(30) + '</a></li>');

                return false;
            });
        }
    }
}
function bcInit() {
    'use strict';
    //enhances objects as needed
    String.prototype.truncate = function (len) {
        var rtn = this.slice(0,len);

        if (this.length > len) {
            rtn += '...';
        }

        return rtn;
    };

  //set deep zoom in burke data something like this --> {exists:[true/false], properties{name:[name],ns:[namespace],path:[path]}}
    window.deepZoomAjax = $.ajax({
        url:burke.get('apiUrl') + '?lang=eng&fn=deepZoom',
        dataType:"json"
    });
    setDeepZoom();
    //this gets the deep zoom from the cropSettings file
    function setDeepZoom(){
        var deepZoomResponse = window.deepZoomAjax.responseText;
        if(deepZoomResponse){
            burke.set("deepZoom",($.parseJSON(deepZoomResponse)));
        }
        else{
            setTimeout(function(){setDeepZoom(),20});
        }
    }



    if (!imageCropperLoaded) {
        includeCSS(sharedPrefix + '/binary/resources/styles/imageCropper.css');
        includeCSS(cdnPath + '/scripts/jquery/plugins/jcrop/0.9.9/jquery.Jcrop.css');
        includeJS(cdnPath + '/scripts/jquery/plugins/jcrop/0.9.9/jquery.Jcrop.min.js');
        imageCropperLoaded = true;
    }


    //extend that reader so we can access the File_model THIS
    FileReader.prototype.addThat = function (that) {
        this.that = that;
        return this;
    };

    if (burke.get('adminLibrary')) {
        $('.close-cancel').hide();
        $('.btn[href="/admin/content/binary"]').hide();
    }

    //check to see if we are running in the binary content admin or in a modal
    //    if we are in a modal is there a content URI?
    //    TODO remove strings for i18N
    /* if (!burke.get('adminLibrary') && !burke.get('updateArticle')) {
        $('.bc-drop-zone-pre').addClass('hidden');
        $('#bc-drop-zone .bc-drop-zone-decor').html('<p>Please Save this Content<p><p>before uploading new files</p>').removeClass('hidden');
    } */

    //init the details pane
    details = new Details_view();

    //init the first column
    $('.bc-column:first').data('view', new Column_view());
    $('.bc-column:first').data().view.init($('.bc-column:first'),burke.get('baseURI'),false,false).update(true, function () {
        if (burke.get('articleBCURI')) {
            $('[data-uri="' + burke.get('articleBCURI') + '"]').find('a').click();
        }
    });

    //base settings for the search boxes
    if (burke.get('adminLibrary')) {
        $('#filter-box').val('Please select a folder to search...');
    } else {
        $('.bc-tools form').submit(function () {
            alert('Please select a folder to search');
            return false;
        });
    }

    //handle tab clicks
    $('.bc-tab').click(function (event) {
        var i = false,
            width;
        noopHandler(event);

        if (!$(this).hasClass('active')) {
            $('.bc-tab.active').removeClass('active');
            $(this).addClass('active');

            details.clear();

            $('.bc-column').not(':first').each(function () {
                if (!i) {
                    if (typeof $(this).data('view') !== 'undefined') {
                        $(this).data('view').clear();
                    }
                    i = true;
                } else {
                    $(this).remove();
                    $('.bc-column-wrapper').width($('.bc-column-wrapper').outerWidth(false) - 277);
                }
            });

            $('.bc-column-window').animate({scrollLeft : 0,queue: true},450, function () {
                updateNavButtons();
            });


            burke.set('activeTab', $(this).attr('href').split('#')[1]);
            $('.bc-column:first').data('view').init($('.bc-column:first'),burke.get('baseURI'),false,false).update(true);
        }
    });

    $('.' + burke.get('wrapperSelector')).on('click', '.bc-column-content .search-folder a', function (event) {
        event.stopImmediatePropagation();
        noopHandler(event);

        handleSearch($(this).parents('li').attr('data-uri'));
        $('.bc-column .active').removeClass('active');
        $(this).parents('li').addClass('active');

    }).on('click', '.bc-column-content .folder a', function () {
        //load into the right column and remove files, move this one to the left column
        //and remove the files from it
        var uri = $(this).parents('li').attr('data-uri'),
            p = $(this).parents('.bc-column'),
            newCol;
        buildBreadCrumb(uri);
        //$('#workDir').html(uri);
        $(p).find('.folder.active').removeClass('active');

        if ((burke.get('adminLibrary') || burke.get('noArticle') || burke.get('updateArticle')) && !burke.get('dropZoneSetup')) {
            setupDropZone();
            burke.set('dropZoneSetup', true);
        }
        if (!burke.get('searchSetup')) {
            setupSearchBox();
        }

        $(this).parents('li').addClass('active');

        $('.bc-new-folder-small').removeClass('bc-new-folder-small');
        $('#newFolder').remove();

        burke.set('activeURI', uri);

        if ($(p).next('.bc-column').length > 0 && typeof $(p).next('.bc-column').data().view !== 'undefined') {
            //next column exists and has a view setup
            var colView = $(p).next('.bc-column').data().view;
            colView.set('uri', uri);
            colView.set('readOnly', false);
            colView.update(true);

            //remove any extra elements from the DOM (like paths that we won't be going down again)
            while($(p).next('.bc-column').next('.bc-column').length) {
                $(p).next('.bc-column').next('.bc-column').remove();
                $('.bc-column-wrapper').width($('.bc-column-wrapper').outerWidth(false) - 277);
            }

            $('.bc-column-window').animate({queue: true,scrollLeft : $('.bc-column-window').scrollLeft() + (p.offset().left - $('.bc-column-window').offset().left)},450, function () {
                updateNavButtons();
            });
        } else if ($(p).next('.bc-column').length > 0) {
            //column exists but lacks a view
            var thisCol = $(this).parents('.bc-column').next('.bc-column');
            $(thisCol).data('view', new Column_view());
            $(thisCol).data().view.init($(thisCol), uri, false, false).update();
        } else {
            //no column and no view
            //make the magic happen



            newCol = $(p).clone();
            $(newCol).data('view',new Column_view());
            $(newCol).data('uri',uri);
            $(newCol).data().view.init($(newCol), uri, false, false).update();
            $('.bc-column-wrapper').css('width', $('.bc-column-wrapper').outerWidth(false) + 277).append(newCol);
            $('.bc-column-window').animate({queue: true, scrollLeft :$('.bc-column-window').scrollLeft() + 277},450, function () {
                updateNavButtons();
            });
        }
        return false;
    }).on('click', '.bc-column-content .file a', function () {
        //load into the details pain
        var id = $(this).parents('li').attr('data-uri');
        $('.bc-new-folder-small').removeClass('bc-new-folder-small');
        $('#newFolder').remove();

        $('.file.active').removeClass('active');
        $(this).parents('.file').addClass('active');
        details.init(id).update();
        //details.set('fileURI',$(this).attr('href'));

        return false;
    }).on('click', '.close-cancel', function () {
        $('.modal-background').hide();
        return false;
    }).on('click', '.bc-new-folder', function () {
        if ($(this).hasClass('active')) {
            if ($(this).siblings('#newFolder').length) {
                var data = {
                            lang: 'eng',
                            fn: 'create',
                            name: $(this).siblings('#newFolder').val(),
                            folderPath: $(this).parents('.bc-column').data('uri'),
                            action: 'create'
                    },
                    that = $(this);
                if (data.name !== '') {
                    $.get(burke.get('apiUrl'), data, function () {
                        //refresh the view
                        that.parents('.bc-column').data().view.update(true);
                    });
                } else {
                    that.parents('.bc-column').data().view.update();
                }
            } else {
                $(this).addClass('bc-new-folder-small').before('<input name="newFolder" id="newFolder"/>');
                $('#newFolder').focus();
            }
        }
        return false;
    }).on('click', '.bc-details .edit', function (event) {
        var details = $('.bc-details');
        $(this).hide();
        $(this).siblings('.btn').show();
        $('.bc-details .btn.green').addClass('inactive');

        $(details).find('p').each(function () {
            $(this).hide();

            if ($(this).parent('#bc-asset-title').length) {
                //asset title
                $(this).parent('div').append('<input type="text" id="title_input" value="'+ $(this).text().split(".")[0] + '"/><input type="hidden" id="title_type_input" value="'+ $(this).text().split(".")[1] + '"/>');
            } else if ($(this).parent('#bc-tags').length) {
                $(this).parent('div').append('<textarea id="tags_input">' + $(this).text() + '</textarea>').val($(this).text());
            } else if ($(this).parent('#bc-asset-url').length) {
                $(this).show();
            } else if ($(this).parent('#bc-asset-size').length) {
                $(this).show();
            } else if ($(this).parent('#bc-description').length) {
                $(this).parent('div').append('<textarea id="description_input">' + $(this).text() + '</textarea>').val($(this).text());
            } else $(this).parent('div').append('<input type="text" id="telescope_id_input" value="'+ $(this).text() + '"/>');
        });

        $("#deepZoomCheckBox label, #deepZoomCheckBox input").removeClass("unclickable");

        return false;
    }).on('click', '.bc-details .btn.done', function () {
        var binaryContent = details.get("detailData")["binary-content"];
        var data = {
            lang : "eng",
            fn : "save",
            url : binaryContent["path"],
            fileName : binaryContent["file-name"],
            folder : binaryContent["folder"],
            title: $.trim($('#title_input').val()),
            tags: quoteTags($('#tags_input').val().replace(/[ ]/g,',')),
            description: $('#description_input').val(),
            telescope: $('#telescope_id_input').val(),
            fileId: details.get('fileID'),
            deepZoom:($("#deepZoomCheckBox input").attr("checked") == "checked")
        };
        $.get(burke.get('apiUrl'), data, function (newFile) {
            if ( newFile.error !== undefined ) {
                errorNotice(newFile.error);
            } else {
                details.update();
            }
            $('li.file[data-uri="' + newFile.id + '"] a').html('<span class="file"></span>' + newFile.title);

        });
       var checkedAttr = $("#deepZoomCheckBox input").attr("checked");
       if(!checkedAttr){
           window.deepZoomChecked = false;
       }
       else{
           window.deepZoomChecked = true;
       }
       return false;

    }).on('click', '.bc-details .crop', function (event) {
        // TODO: Pull cropper into modal

        var data = {
            fileId: details.get('fileID'),
            lang: 'eng',
            allowedHeight: burke.get("allowedHeight"),
            allowedWidth: burke.get("allowedWidth")
        };
        $.ajax({
            url: sharedPrefix + '/binary/resources/ajax/imageCropper',
            data: data,
            success: function (data) {
                //main = $('div.' + burke.get('wrapperSelector')).html();
                var wrapperSelector = burke.get('wrapperSelector');
                var wrapper = $('div.' + wrapperSelector);
                wrapper.addClass("imageCropperOpen");
                //wrapper.children().hide();
                wrapper.append($("<div class='imageCropper'></div>").html(data));
                $("#search,#workingDir").hide();
                //$("div." + wrapperSelector + " div.imageCropper").html(data);
                //$('div.' + burke.get('wrapperSelector')).html(data);
                //$('div.' + burke.get('wrapperSelector')).addClass('imageCropper');
                imageCropper.init();
            }
        });
        return false;
    }).on('click', '.bc-details .deleteIcon', function () {
        var data = {
                fileId: details.get('fileID')
            };
        var thisLI = $('.file[data-uri="' + data.fileId + '"]');
        var fn = function () { $.post(burke.get('apiUrl') + '?lang=eng&fn=delete',data, function () { $(thisLI).hide(); details.clear(); }) };
        var conf = LDSE.confirm('I would like to delete this file permenantly', "Are you sure you want to delete this file?", fn);
/*            conf = LDSE.confirm('I would like to delete this file permenantly', "Are you sure you want to delete this file?");*/
        //TODO move delete into a method of the File_model?
    }).on('click','.bc-details .downloadBtn',function(){

    }).on('click', '.bc-details #image-options-link', function () {
        if(!window.optionsDisplayed){
            $(".bc-details #image-options-link").html("Hide Insert Options");
            $('#imageOptions').show();
            window.optionsDisplayed=true;
        }
        else{
            $(".bc-details #image-options-link").html("Show Insert Options");
            $('#imageOptions').hide();
            window.optionsDisplayed=false;
        }
    }).on('click', '.bc-details .btn.green', function () {
        //insert code happens to go here it would seem

        var insertedHTML,
            uri = details.get('fileURI'),
            linkText,
            alt = $('#image-options-alt').val();

        var postData = {
                fn:"saveInsert",
                bcID: details.get("fileID"),
                docID: ICE.formVars.id,

        };

        $.ajax({
            type:"post",
            data: postData,
            url: burke.get("apiURL"),
            success: function(response){
                //alert("Successful insert ajax call! ->" + response);
            },
            fail: function(){
                alert("Failed!");
            }
        });


        if (burke.get('inputID') !== '') {
            $(burke.get('inputID')).val(uri);
            $(burke.get('inputID') + '-preview').attr('src','').attr('src',uri);
            $('.close-cancel').click();
        } else if (burke.get('activeTab') === 'image' && burke.isImage(uri)) {
            //it is an image it seems...
            insertedHTML = '<img alt="' + alt + '" src="' + uri + '" data-id="' + details.get('fileID') + '"/>';

            $('.close-cancel').click();
            CKEDITOR.instances[burke.get('textareaID')].insertHtml(insertedHTML);
        } else {
            //something other than an image here... need to do some more checking to see what kind of file
            try {
                linkText = CKEDITOR.instances[burke.get('textareaID')].getSelection();
                linkText = linkText.getNative();
            } catch (e) {
                linkText = '';
            }

            insertedHTML = $('<a href="' + uri + '">' + linkText + '</a>');


            if (insertedHTML.text().length === 0) {
                insertedHTML = '<a href="' + uri + '" data-id="' + details.get('fileID') + '">' + $('#bc-asset-title').find('p').text() + '</a>';
            } else {
                insertedHTML = '<a href="' + uri + '" data-id="' + details.get('fileID') + '">' + linkText + '</a>';
            }



            CKEDITOR.instances[burke.get('textareaID')].insertHtml(insertedHTML);
            $('.close-cancel').click();
        }

        return false;
    }).on('click', '.bc-column-header .back-button', function () {
       var activeURI, activeURIString;
        if ($('.bc-column-window:animated').length === 0) {
            if ($('.bc-column-window').scrollLeft() >= 273) {
                $('.bc-column-window').animate({queue: true,scrollLeft :$('.bc-column-window').scrollLeft() - 276},450, function () {
                    updateNavButtons();
                });
                activeURI = burke.get('activeURI').split('/');
                activeURIString = '';
                for (var i = 1; i < activeURI.length; i++) {
                    if (i <= activeURI.length -3) {
                        activeURIString += '/' + activeURI[i];
                    }
                }

                burke.set('activeURI',activeURIString + '/');
            }
        }
        return false;
    }).on('click', '.bc-column-header .next-button', function () {
        if ($('.bc-column-window:animated').length === 0) {
            if ($('.bc-column-window').scrollLeft() < $('.bc-column-wrapper').outerWidth(false) - 600) {
                $('.bc-column-window').animate({queue: true, scrollLeft :$('.bc-column-window').scrollLeft() + 276},450, function () {
                    updateNavButtons();
                });
            }
        }
        return false;
    /*}).on('blur', '.two-col textarea, .two-col input', function () {
        var data = {
                lang: 'eng',
                fn : 'save',
                title: $.trim($('#title_input').val()),
/\*             url: $('#url_input').val(),*\/
                telescope: $('#telescope_id_input').val(),
                tags: quoteTags($('#tags_input').val().replace(/[ ]/g, ',')),
                description: $('#description_input').val(),
                fileId: details.get('fileID')
            };

        $.get(burke.get('apiUrl'),data, function () {
            autoSaveNotice();
        });*/
    }).on('keyup', '#newFolder', function (e) {
        if (e.keyCode === 13) {
            var data = {
                    lang: 'eng',
                    fn: 'create',
                    name: $(this).val(),
                    folderPath: $(this).parents('.bc-column').data('uri'),
                    action: 'create'
            },that = $(this);

            $.get(burke.get('apiUrl'), data, function () {
                //refresh the view
                that.parents('.bc-column').data().view.update(true);
            });
        }
    }).on('dragstart', '.file a', function (e) {
        e.originalEvent.dataTransfer.setData('text/html', $('<div>').append($(this).parent('li').clone()).remove().html());
        e.originalEvent.dataTransfer.setData('text/plain', $(this).parents('.bc-column').data('uri'));
    }).on('dragenter, dragover', '.bc-column ul, .bc-column ul .folder', function (e) {
        if (e.preventDefault) {
            e.preventDefault();
        }
        return false;
    }).on('drop', '.bc-column ul, .bc-column ul .folder', function (e) {
        var domFragment = $(e.originalEvent.dataTransfer.getData('text/html')),
            thisFolder = $(this).has('.folder').attr('data-uri') || $(this).parents('.bc-column').data('uri'),
            thisList = this,
            isFolder = $(this).hasClass('folder'),
            data;

        if (e.preventDefault) {
            e.preventDefault();
        }
        if(thisFolder !== burke.get('baseURI')){
            //move stuff in the backend
            data = {
                lang: 'eng',
                fn: 'move',
                fileId: $(domFragment).attr('data-uri'),
                newPath: thisFolder + '/' + $(domFragment).children('a').attr('href').split('/').pop()
            };

            if(burke.get('activeURI') && thisFolder === burke.get('articleBCURI')){
                data.newArticleUri = burke.get('articleURI');
            }

            $.ajax({
                    url: burke.get('apiUrl'),
                    data: data,
                    dataType: 'json',
                    success: function(){
                        if(isFolder){
                            $('[data-uri="' + $(domFragment).attr('data-uri') + '"]').remove();
                            if($(thisList).parents('.bc-column').next().length && $(thisList).parents('.bc-column').next().data().uri === thisFolder){
                                $(thisList).parents('.bc-column').next().is(':visible');
                                $(thisList).parents('.bc-column').next().data().view.update(true);
                            }
                        }else{
                            $('[data-uri="' + $(domFragment).attr('data-uri') + '"]').remove();
                            $(thisList).append(domFragment);
                        }
                    },
                    error: function(){
                        return false;
                    }
            });
        }
        return false;
    });
    setupSearchBox();
    if (!burke.get('adminLibrary')) {
        $('.' + burke.get('wrapperSelector')).draggable({
            handle: ".bc-tools"
        });
    }
}
var autoSaveNotice = function () {
    'use strict';
    if ($('#bc-details-pane').children('.save-notice').length === 0) {
        //add the auto save notice DOM element
        $('#bc-details-pane').append('<div class="save-notice" style="display:none">Changes auto-saved</div>');
    }
    $('#bc-details-pane').children('.save-notice').fadeIn(300).delay(1000).fadeOut(600);
};
var errorNotice = function (text) {
    'use strict';
    if ($('#bc-details-pane').children('.error-notice').length === 0) {
        //add the auto save notice DOM element
        $('#bc-details-pane').append('<div class="error-notice" style="display:none">' + text + '</div>');
    }
    $('#bc-details-pane').children('.error-notice').fadeIn(300).delay(1000).fadeOut(600);
};
var quoteTags = function(tags){
    var localTags = tags.split(','),
        i,
        tagString = '';

    for(i = 0; i < localTags.length; i++){
        tagString += '\'' + localTags[i] + '\'' + ',';
    }

    return tagString;
};
var updateNavButtons = function () {
    'use strict';


    //This section of code is to fix the off-by-one pixel issue
    $(".bc-column").each(function(){
        $(this).width(276);
    });

    if($(".bc-column-window").scrollLeft() % 277 !== 0){
        $(".bc-column").last().width(277);
        $(".bc-column-window").animate({queue:true,scrollLeft: $(".bc-column-window").scrollLeft() + 1},1,function(){});
    }


    //back arrow
    if ($('.bc-column-window').scrollLeft() <= 273) {
        $('.bc-column-header .back-button').not('.inactive').addClass('inactive');
    }
    if ($('.bc-column-wrapper').outerWidth(false) > 555 && $('.bc-column-window').scrollLeft() >= 273) {
        $('.bc-column-header .back-button.inactive').removeClass('inactive');
    }

    //forward arrow
    if ($('.bc-column-window').scrollLeft() < $('.bc-column-wrapper').outerWidth(false) - 600) {
        $('.bc-column-header .next-button.inactive').removeClass('inactive');
    } else {
        $('.bc-column-header .next-button').not('.inactive').addClass('inactive');
    }
};
var handleSearch = function (query) {
    'use strict';
    var data,
        i = false;
    //there are several columns need to clean them out and set the last one to the search
    $('.bc-column').not(':first').each(function () {
        if (!i) {
            i = true;
        } else {
            $(this).remove();
            $('.bc-column-wrapper').width($('.bc-column-wrapper').outerWidth(false) - 277);
        }
    });

    //down to 2 columns yo!
    data = $('.bc-column:last').data();
    if (typeof data.view !== 'undefined') {
        //existing column with data for a view
        data.view.clear();
        data.view.set('readOnly', true);
        data.view.updateWithSearch(query);
    } else {
        $('.bc-column:last').data('view',new Column_view());
        $('.bc-column:last').data().view.set('readOnly', true);
        $('.bc-column:last').data().view.set('column',$('.bc-column:last'));
        $('.bc-column:last').data().view.updateWithSearch(query);
    }
    updateNavButtons();
};

function File_model() { //file class
    'use strict';
    //properties
    var dataStore = {
            size: 0,
            name: '',
            file: '',
            postUrl: burke.get('apiUrl') + '?lang=eng&fn=upload',
            fileData: '',
            allowedFileExtensions: burke.get('allowedFileExtensions'),
            allowedWidth: burke.get('allowedWidth'),
            allowedHeight: burke.get('allowedHeight'),
            minWidth: burke.get('minWidth'),
            minHeight: burke.get('minHeight'),
            activeURI: ''
    };

    this.get = function (key) {
        return dataStore[key];
    };
    this.set = function (key, value) {
        dataStore[key] = value;
    };

    //reader
    this.reader = new FileReader();

    this.reader.addThat(this);

    //methods
    this.init = function (file, postUrlParam) {
        var that = this;
        that.set('file', file);
        that.set('name', file.name);
        that.set('size', file.size);
        that.set('activeURI', burke.get('activeURI'));

        //if there is a postUrl passed in use it other wise default
        if (typeof postUrlParam !== 'undefined' && postUrlParam) {
            that.set('postUrl', postUrlParam);
        }

        //bind events to the reader
        that.reader.onprogress = that.readerProgress;
        //that.reader.addEventListener('progress', that.readerProgress, true);

        that.reader.onloadend = that.fileReadComplete;
        //that.reader.addEventListener('loadend', that.fileReadComplete, false);

        return that;
    };
    this.readFile = function () {
        var that = this,
            extension = that.get('name').split('.').pop();

        if (that.legalFileType(extension)) {
            that.reader.readAsDataURL(that.get('file'));
        } else {
            //display the error notice
            errorNotice('This file type is not allowed');
        }
    };
    this.fileReadComplete = function (evt) {
        var parent = this.that;

        //write the data to the object for later
        parent.set('fileData',evt.target.result);

        var postData = {
                upath: burke.get('activeURI') + '/' + parent.get('name'),
                fileName: parent.get('name'),
                file: parent.get('fileData')
            },
            postUrl = parent.get('postUrl'),
            extensions = ["bmp", "gif", "jpg", "jpeg", "png", "tif"],
            filename = parent.get('name'),
            ext = filename.split('.').pop().toLowerCase();

        if (burke.get('activeURI') === burke.get('articleBCURI')) {
            postData.articleUri = burke.get('articleURI');
        }

        if ($.inArray(ext,extensions) > -1) {
            var newImage = new Image();
            newImage.style.display = "none";
            newImage.onload = function () {
                var oMyForm = new FormData();
                //oMyForm = $.extend(oMyForm,postData);
                oMyForm.append( "height", this.height );
                oMyForm.append( "width", this.width );
                oMyForm.append( "upath", burke.get('activeURI') + '/' + parent.get('name'));
                oMyForm.append( "fileName", parent.get('name') );
                oMyForm.append( "file", parent.get('fileData') );
                oMyForm.append( "allowedWidth", parent.get('allowedWidth') );
                oMyForm.append( "allowedHeight", parent.get('allowedHeight') );
                oMyForm.append( "minWidth", parent.get('minWidth') );
                oMyForm.append( "minHeight", parent.get('minHeight') );

                $.ajax({
                        url: postUrl,
                        data: oMyForm,
                        cache: false,
                        contentType: false,
                        processData: false,
                        dataType: "json",
                        type: 'POST',
                        success: function(data){
                            //yeah
                            if (!data.error) {
                                var text = cleanURI(postData.upath,true);
                                if (typeof data.title !== "undefined" && data.title !== '') {
                                    text = data.title;
                                }
                                //succesful upload
                                $('li.file[data-uri="' + data.id + '"]').remove();
                                $('#' + liHash).children('.status-bar').hide();
                                $('#' + liHash).removeClass('upload');
                                $('#' + liHash).attr('data-uri', data.id);
                                $('#' + liHash).children('a').attr('href',cleanURI(postData.upath));
                                $('#' + liHash).children('a').text(text);
                                $('#' + liHash).children('a').prepend('<span class="file"></span>');

                                if (!details.get('fileID') && parent.get('activeURI') === burke.get('activeURI')) {
                                    $('#' + liHash).children('a').click();
                                }

                                //clearCacheForUris([data.path]);
                            } else {
                                $('#' + liHash).children('.status-bar').hide();
                                $('#' + liHash).html( $('#' + liHash).children('a').html() + " " + data.error );
                                $('#' + liHash).removeClass('upload').addClass('error');
                            }
                        }
                    });
            };
            newImage.src = evt.target.result;
            $('body').append(newImage);
        } else {
            var oMyForm = new FormData();
            //oMyForm = $.extend(oMyForm,postData);
            oMyForm.append( "upath", burke.get('activeURI') + '/' + parent.get('name'));
            oMyForm.append( "fileName", parent.get('name') );
            oMyForm.append( "file", parent.get('fileData') );
            $.ajax({
                    url: postUrl,
                    data: oMyForm,
                    cache: false,
                    contentType: false,
                    processData: false,
                    dataType: "json",
                    type: 'POST',
                    success: function(data){
                        if (!data.error) {
                            var text = cleanURI(postData.upath,true);
                            if (typeof data.title !== "undefined" && data.title !== '') {
                                text = data.title;
                            }
                            //succesful upload
                            $('li.file[data-uri="' + data.id + '"]').remove();
                            $('#' + liHash).children('.status-bar').hide();
                            $('#' + liHash).removeClass('upload');
                            $('#' + liHash).attr('data-uri', data.id);
                            $('#' + liHash).children('a').attr('href',cleanURI(postData.upath));
                            $('#' + liHash).children('a').text(text);
                            $('#' + liHash).children('a').prepend('<span class="file"></span>');

                            if (!details.get('fileID') && parent.get('activeURI') === burke.get('activeURI')) {
                                $('#' + liHash).children('a').click();
                            }
                            //clearCacheForUris([data.path]);
                        } else {
                            $('#' + liHash).children('.status-bar').hide();
                            $('#' + liHash).html( $('#' + liHash).children('a').html() + " " + data.error );
                            $('#' + liHash).removeClass('upload').addClass('error');
                        }
                    }
                });
        }

        var activeColumn = '',
            liHash = '',
            dateObj = new Date();

        $('.bc-column').each(function () {
            if (burke.get('activeURI') === $(this).data('uri')) {
                activeColumn = $(this);
            }
        });

        liHash = 'id_' + cleanID(this.that.get('name').replace(/[\. ]/g,'')) + dateObj.getUTCMilliseconds();

        //set the hash so we can get to the status bar and stuff
        this.that.set('thisID',liHash);

        if ($(activeColumn).find('li.folder:last').length === 1) {
            $(activeColumn).find('li.folder:last').after('<li class="file upload" id="' + liHash + '"><span class="status-bar"><img alt="" src="data:image/gif;base64,R0lGODlhEAALAPQAAP///y6Tx+Du9tjq9O31+TKVyC6Tx1Om0JjJ43y728bh70mhzmqy15/N5H+93Mnj8E2jzzGUx22z1+rz+N7t9fX5+1uq0+Lv9vT4+8Pf7rHW6dPo8vD3+gAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh/hpDcmVhdGVkIHdpdGggYWpheGxvYWQuaW5mbwAh+QQJCwAAACwAAAAAEAALAAAFLSAgjmRpnqSgCuLKAq5AEIM4zDVw03ve27ifDgfkEYe04kDIDC5zrtYKRa2WQgAh+QQJCwAAACwAAAAAEAALAAAFJGBhGAVgnqhpHIeRvsDawqns0qeN5+y967tYLyicBYE7EYkYAgAh+QQJCwAAACwAAAAAEAALAAAFNiAgjothLOOIJAkiGgxjpGKiKMkbz7SN6zIawJcDwIK9W/HISxGBzdHTuBNOmcJVCyoUlk7CEAAh+QQJCwAAACwAAAAAEAALAAAFNSAgjqQIRRFUAo3jNGIkSdHqPI8Tz3V55zuaDacDyIQ+YrBH+hWPzJFzOQQaeavWi7oqnVIhACH5BAkLAAAALAAAAAAQAAsAAAUyICCOZGme1rJY5kRRk7hI0mJSVUXJtF3iOl7tltsBZsNfUegjAY3I5sgFY55KqdX1GgIAIfkECQsAAAAsAAAAABAACwAABTcgII5kaZ4kcV2EqLJipmnZhWGXaOOitm2aXQ4g7P2Ct2ER4AMul00kj5g0Al8tADY2y6C+4FIIACH5BAkLAAAALAAAAAAQAAsAAAUvICCOZGme5ERRk6iy7qpyHCVStA3gNa/7txxwlwv2isSacYUc+l4tADQGQ1mvpBAAIfkECQsAAAAsAAAAABAACwAABS8gII5kaZ7kRFGTqLLuqnIcJVK0DeA1r/u3HHCXC/aKxJpxhRz6Xi0ANAZDWa+kEAA7AAAAAAAAAAAA" /></span><a href="#uploading"><span class="file"></span>' + postData.fileName.truncate(30) + '</a></li>');
        } else if ($(activeColumn).find('li.file:first').length === 1) {
            $(activeColumn).find('li.file:first').before('<li class="file upload" id="' + liHash + '"><span class="status-bar"><img alt="" src="data:image/gif;base64,R0lGODlhEAALAPQAAP///y6Tx+Du9tjq9O31+TKVyC6Tx1Om0JjJ43y728bh70mhzmqy15/N5H+93Mnj8E2jzzGUx22z1+rz+N7t9fX5+1uq0+Lv9vT4+8Pf7rHW6dPo8vD3+gAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh/hpDcmVhdGVkIHdpdGggYWpheGxvYWQuaW5mbwAh+QQJCwAAACwAAAAAEAALAAAFLSAgjmRpnqSgCuLKAq5AEIM4zDVw03ve27ifDgfkEYe04kDIDC5zrtYKRa2WQgAh+QQJCwAAACwAAAAAEAALAAAFJGBhGAVgnqhpHIeRvsDawqns0qeN5+y967tYLyicBYE7EYkYAgAh+QQJCwAAACwAAAAAEAALAAAFNiAgjothLOOIJAkiGgxjpGKiKMkbz7SN6zIawJcDwIK9W/HISxGBzdHTuBNOmcJVCyoUlk7CEAAh+QQJCwAAACwAAAAAEAALAAAFNSAgjqQIRRFUAo3jNGIkSdHqPI8Tz3V55zuaDacDyIQ+YrBH+hWPzJFzOQQaeavWi7oqnVIhACH5BAkLAAAALAAAAAAQAAsAAAUyICCOZGme1rJY5kRRk7hI0mJSVUXJtF3iOl7tltsBZsNfUegjAY3I5sgFY55KqdX1GgIAIfkECQsAAAAsAAAAABAACwAABTcgII5kaZ4kcV2EqLJipmnZhWGXaOOitm2aXQ4g7P2Ct2ER4AMul00kj5g0Al8tADY2y6C+4FIIACH5BAkLAAAALAAAAAAQAAsAAAUvICCOZGme5ERRk6iy7qpyHCVStA3gNa/7txxwlwv2isSacYUc+l4tADQGQ1mvpBAAIfkECQsAAAAsAAAAABAACwAABS8gII5kaZ7kRFGTqLLuqnIcJVK0DeA1r/u3HHCXC/aKxJpxhRz6Xi0ANAZDWa+kEAA7AAAAAAAAAAAA" /></span><a href="#uploading"><span class="file"></span>' + postData.fileName.truncate(30) + '</a></li>');
        } else {
            $(activeColumn).find('ul').append('<li class="file upload" id="' + liHash + '"><span class="status-bar"><img alt="" src="data:image/gif;base64,R0lGODlhEAALAPQAAP///y6Tx+Du9tjq9O31+TKVyC6Tx1Om0JjJ43y728bh70mhzmqy15/N5H+93Mnj8E2jzzGUx22z1+rz+N7t9fX5+1uq0+Lv9vT4+8Pf7rHW6dPo8vD3+gAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh/hpDcmVhdGVkIHdpdGggYWpheGxvYWQuaW5mbwAh+QQJCwAAACwAAAAAEAALAAAFLSAgjmRpnqSgCuLKAq5AEIM4zDVw03ve27ifDgfkEYe04kDIDC5zrtYKRa2WQgAh+QQJCwAAACwAAAAAEAALAAAFJGBhGAVgnqhpHIeRvsDawqns0qeN5+y967tYLyicBYE7EYkYAgAh+QQJCwAAACwAAAAAEAALAAAFNiAgjothLOOIJAkiGgxjpGKiKMkbz7SN6zIawJcDwIK9W/HISxGBzdHTuBNOmcJVCyoUlk7CEAAh+QQJCwAAACwAAAAAEAALAAAFNSAgjqQIRRFUAo3jNGIkSdHqPI8Tz3V55zuaDacDyIQ+YrBH+hWPzJFzOQQaeavWi7oqnVIhACH5BAkLAAAALAAAAAAQAAsAAAUyICCOZGme1rJY5kRRk7hI0mJSVUXJtF3iOl7tltsBZsNfUegjAY3I5sgFY55KqdX1GgIAIfkECQsAAAAsAAAAABAACwAABTcgII5kaZ4kcV2EqLJipmnZhWGXaOOitm2aXQ4g7P2Ct2ER4AMul00kj5g0Al8tADY2y6C+4FIIACH5BAkLAAAALAAAAAAQAAsAAAUvICCOZGme5ERRk6iy7qpyHCVStA3gNa/7txxwlwv2isSacYUc+l4tADQGQ1mvpBAAIfkECQsAAAAsAAAAABAACwAABS8gII5kaZ7kRFGTqLLuqnIcJVK0DeA1r/u3HHCXC/aKxJpxhRz6Xi0ANAZDWa+kEAA7AAAAAAAAAAAA" /></span><a href="#uploading"><span class="file"></span>' + postData.fileName.truncate(30) + '</a></li>');
        }
    };
    this.readerProgress = function (evt) {
        if (evt.lengthComputable) {
            var percentToPixels = ((evt.loaded / evt.total) * 200) - 600;

            $("#" + this.that.get('thisID')).children('.status-bar').css('background-position', '-' + percentToPixels + 'px');

                return percentToPixels;
        }

        return false;
    };
    this.legalFileType = function (fileType) {
        var that = this;
        return (that.get('allowedFileExtensions').indexOf(fileType.toLowerCase()) !== -1);
    };
}

function buildBreadCrumb(uri) {
    var tokens = uri.substring(1).split('/');
    var crumbs = $('#workDir').html('');
    $.each(tokens, function(index, value) {
        if (value !== '') {
            var curUri = "/" + tokens.slice(0, index + 1).join('/');
            var crumb = $('<a/>').attr('link', curUri).attr("href","#").addClass('crumb').html(value);
            crumb.click(function (e){
                var uri = $(this).attr('link');
                $('.folder a[href="' + uri + '"]').click();
                //event.stopImmediatePropagation();
                event.preventDefault();
                return false;
            });
            crumbs.append('/').append(crumb);
        }
    });
    return crumbs;
}
function roundNumber(num, dec) {
    var result = Math.round(num*Math.pow(10,dec))/Math.pow(10,dec);
    return result;
}
function cleanID(id){
    return id.replace(/([`~!@#\$%\^\*\(\)\+={}\[\]:;'Ã¢â‚¬â„¢Ã¢â‚¬ï¿½Ã¢â‚¬Å“Ã¢â‚¬Â¦<>,\.\?"])/g, '').replace(/(\.\.\.)|(&amp\;)|([Ã¢â‚¬â€�Ã¢â‚¬Â¦Ã¢â‚¬â€œ:\Ã‚Â¦\/\\Ã¢â‚¬â€œ\|Ã¢â‚¬â€�&])/, '-');
}

function cleanURI(uri,rtnFileName) {
    'use strict';
    var fileName = uri.split('/')[uri.split('/').length - 1].split('.'),
        fileExt = uri.split('/')[uri.split('/').length - 1].split('.').pop(),
        localURI = uri.split('/'),
        i,
        tempURI = '';

    //remove the file name from the URI
    localURI.pop();
    fileName.pop();
    fileName = fileName.join('.');

    //rebuild the URI
    for (i = 0; i < localURI.length; i++) {
        tempURI += localURI[i] + '/';
    }
    localURI = tempURI;

    //regex the filename and lowercase
    fileName = fileName.replace(/([`~!@#\$%\^\*\(\)\+={}\[\]:;'Ã¢â‚¬â„¢Ã¢â‚¬ï¿½Ã¢â‚¬Å“Ã¢â‚¬Â¦<>,\.\?"])/g, '');
    fileName = fileName.replace(/(\.\.\.)|(&amp\;)|([Ã¢â‚¬â€�Ã¢â‚¬Â¦Ã¢â‚¬â€œ:\Ã‚Â¦\/\\Ã¢â‚¬â€œ\|Ã¢â‚¬â€�&])/g, '-');
    //rebuild the filename
    localURI = localURI + fileName + '.' + fileExt;

    if (typeof rtnFileName !== 'undefined' && rtnFileName) {
        return fileName + '.' + fileExt;
    } else {
        return localURI;
    }
}

function noopHandler(evt) {
    'use strict';
    evt.stopPropagation();
    evt.preventDefault();
}

function drop(evt) {
    'use strict';
    noopHandler(evt);

    var files = evt.dataTransfer.files,
        fileHolder = [],
        i;

    for (i = 0; i < files.length; i++) {
        fileHolder[i] = new File_model();
        fileHolder[i].init(files[i]);
        fileHolder[i].readFile();
    }
}

function Burke_model() {
    'use strict';
    this.storage = {
        activeTab: 'image',
        apiUrl: '/ice/burce/',

        baseURI: 'first-buckets/',
        activeURI: '',
        articleURI: '',
        dropZoneSetup: false,
        otherImage: 'data:;base64,iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAMAAABHPGVmAAADAFBMVEXFvqjFvqifmIWooo7BuqXEvafFvqfDvKa6s52fmYa9tqCuqJSsppK7tJ+0rZjDvKahm4jBuqW1r5q/uKK3sZyqpJC3sZyjnYq7tJ6/t6GZk4Cmn4yxqpacloOWkH3FvqgAAADi4NS/uKTNybvEvqrU0cPQzL28taHDv6++uam/uarZ1cfDvq/Z1sjOyrm+uaq7tKDCvKjNybrHwrPNybnU0MLBuqfHwrLSzsDc2cvk4dTSzb3KxrbSzr7e283Iw7PV0cTLxrfMxrLBvKnSzr/e3M7Au6vBvK3BvKzMx7fW08Xi39Hj39PJxLS7tqa6taXi3tHTz8DOyrvj4NPm49bi39Lb2MrY08a5sp7KxbbQzL7X1Ma/uqvW0sW6tJ/GwbHFwLDNyLrX08W4s6PEvanLxrnPy73GwKzRzb/Tz8G6tKTCvq/KxbfOy7za18nY1cfDvai8t6fl4dXNyLjf3dDk4NS9uKjf3M/h3dDd2szTzr/JxLbRzL3TzsDSzb7X08azrZigmoirpZGqo5CdloOup5Oxq5aln4ugmoezrJejnImclYOfmIWvqZSfmoeinImln4y0rZicloOXkX+tppKxqpaspZGknYquqJSxq5efmYasppKemYajnYqtp5OjnouemIWxqpW9tqDDvKa6s566s53AuaTCu6bCu6W4sZy7tJ7BuqS5sp2/t6LBuqW8taCqpJCXkX6hm4iooo6wqZWblYKZk4Cpo4+Zkn+noI2alIGmn4ydl4TPyrq3sJu3sZy7tJ+/uKK+t6Hr6d7s6uDv7eTt6+Hw7uTx7+XPybbu7OLv7ePu7OHs6+G1r5q0rZm2r5rFvqjDvKfd2c3n5drm5Njj4NXf3NDl49fg3NHb18vo5tvm49jj39Te287s6+Dr6t/v7eLw7uW0rpmWkH7Evafp59zx7+by8Ofp59vc2Mzc18vk4dbg3NDo5trh3tLb18rj4NTk4dXh3tHl4tbm49fd2czq6N2UjnyVj33e2s7i39Pn5Nnf28/a1snZ1cjM9pElAAAAIXRSTlMwYEBAYGBAQEBAYEBAQEBgQEBAYGBAQEBgQEBAQEBAvwBC45m6AAAD6klEQVR42sXPeZiVcxjG8ZYppCgtjhbtJIok0qZ9oibRMkbRvu81aZoSWrQRskR2okJlj4oWlaV9X00lQiSapVUv933NH83VM7/znHl+Nd8/Zs77nue6P9fJUQaxHKUjLmcZVWcheTdGXs6IkV+yUB4LYldk5KJNWeryyJC3UcPvVTXkMYOiR2ah1N9UpfJ4EP9C0SKFZiMtwuPaPfkvKgJkHmqjQ9rwODG2J/9H6ZH3UcqvqlJ4nBjEVuCHKDXyLhqiQ4bwODEIHqnAT4WVyFXLkBbhcWLwv9KNH6GokVrfqaqVjgiKG5mLhv2kahiP6wYBFT7kUyHLkRbhMRAog/hUWI20/lZVax6PBgFlEx/zKZC3UIuVqlrwmAiVanyG4kYKzEdtV6tqy2Mi6QpfhMIiS1Hz/aqa8xhIel1u5ZuQCmmlQ1qlI4LiRt5DyT+oSuYxEEalHN+FnMjFM1HCGlUJPAbC2D3X8mXIibyDDq9SlcDjUUFGZT7fhlzIByh+rap4HgM5u4dv4usimSPF5qD4vaqG8xhIRuVBvqciI0vQcCXCYyIZlZn8AooLWaFKQARFQL5GTfapasJjIOco9/GrIi4kSYck8fiawKGIyBUbUL1vVNXbEDYZWYdGHFM1Yl3YROSyA0iLHAibA0nTIWlZRdYjLbI+bDLyDLr9oKqyXzlqxCUZeRQdOmivKpdkZBJq97u9qlwSkZIvIR/ILVySkcfRgN32hnJJRp5HA/6yN5RLMvIm8oJwSUY+RVW22LuTSw4kOG2vQebIpU8iLwiXZORFdL0HpA6XZGQ8GrjVXh0uiUj+19DAPfbiuCQjz6HYVHtxXJKRl1F7D0gMl2TkBdR+h70YLolI0THorhR7MVySkQ+RD+QOLjmQB/60V92BjEVeEC6JSO4FqP5Re7dxSf4lFwLJ/QmquM1eRy65kH/sOZASX6IaHpBOXHIhP9pzIYtQ71P2KnHpPCOdHMjTyMsv4ZKMTEA1j9i7gUsicuXryAfSl0syMh01TrbXl0sy8irq5QGJ5pKMTEa9dtqL5pKIFHwK3X/YXjSXZORj5ANpxiUXst2eC3kM9fjXXlMuicglE5EXhEsyMhX5QDpwSUZmoP5J9jpwSUZeQf1P2ruRSyKS6wl0rwekMpdk5A1U3gNyHZdEpNRiVH6zvYe45EBuTrPnQsahzj4QLsnINNT5kL3BXJKRKcgLwiUZ+Qx1/8PeYC6dZ6Rl5kjxhaj7LnstueRC/rbnQj5HDTwgd3PJgfQ7Y8+FfIF8IH24lH3I1c+iOA9IVy7JyEdoZGCvK5eyEfkZeUG45ED8JSMn/JaNyHG/XWDkP5e2T0CAPSVpAAAAAElFTkSuQmCC',
        contentType: '',
        searchSetup: false,
        hideTabs: false,
        allowedFileExtensions: [],
        allowedHeight: '',
        allowedWidth: ''
    };

    //public generic getter
    this.get = function (key) {
        return this.storage[key];
    };

    //public generic setter
    this.set = function (key, value) {
        this.storage[key] = value;
    };

    this.isImage = function (url) {
        return this.isExtension(url, ["bmp", "gif", "jpg", "jpeg", "png", "tif"]);
    };

    this.isCroppable = function(url){
        return this.isExtension(url, ["bmp","gif", "jpg", "jpeg", "png"]);
    };

    this.isExtension = function(url,extensions){
        var ext = url.split('.').pop();
        return (extensions.indexOf(ext.toLowerCase()) !== -1);
    };

}

function Column_view() { //column view
    'use strict';
    this.dataStore = {
        columnId: '',
        columnData: '',
        leftColumn: true,
        readOnly: false,
        uri: '',
        column: '',
        loadingMore: false
    };

    //public generic getter
    this.get = function (key) {
        return this.dataStore[key];
    };

    //public generic setter
    this.set = function (key, value) {
        this.dataStore[key] = value;
    };

    //methods
    this.init = function (columnObj, uri) {
         this.set('column',columnObj);
         this.set('uri', uri);

         if (uri == 'first-buckets/') {
            this.set('readOnly', false);
            this.set('uri', '');
         } else if (burke.get('baseURI') === uri || burke.get('articleURI') === uri || burke.get('articleBCURI') === uri) {
             this.set('readOnly', true);
         }

         return this;
    };

    this.update = function (getFresh, callBack) {
        var that=this,
            data;
        var column = that.get('columnData');

        data = {
            lang: 'eng',
            fn : 'directory',
            locale: locale,
            cpath: that.get('uri'),
            fileType: burke.get('activeTab'),
            contentType: burke.get('contentType'),
            fileExt: burke.get('allowedFileExtensions'),
            start: 1,
            end: 100
        };

        if (burke.get('activeURI') === burke.get('articleBCURI')) {
            that.set('readOnly', true);
        }

        if (burke.get('articleURI') && burke.get('baseURI') === that.get('uri')) {
            data.articleUri = burke.get('articleURI');
        }

        if (getFresh || column === '') {
            $.ajax({
              url: burke.get('apiUrl'),
              async: false,
              dataType: 'json',
              data: data,
              success: function (data) {
                that.set('columnData',data);
                that.render(callBack);
              }
            });
        } else if (column.end < column.total) {
            that.loadMore();
        } else {
            that.render(callBack);
        }
    };

    this.updateWithSearch = function (query) {
        var that=this,
        data;

        data = {
            lang: 'eng',
            fn: 'search',
            query: query,
            fileType: burke.get('activeTab'),
            currentPath: burke.get('activeURI'),
            fileExt: burke.get('allowedFileExtensions'),
            search: true

        };

        $.getJSON(burke.get('apiUrl'), data, function (data) {
            data.search = true;
            that.set('columnData',data);
            that.render();
        });
    };

    this.render = function (callBack) {
        var rl = $('<ul></ul>'),
            nf = $('<div class="bc-column-new-folder"><a href="#new" class="bc-new-folder">New Folder</a></div>'),
            files = '',
            folders = '',
            column = '',
            end = '',
            total = '',
            that=this,
            i,
            cnt;
        column = that.get('columnData');
        folders = column.Folders || [];
        files = column.Files || [];
        end = column.end;
        total = column.total;
        that.set('loadingMore', false);
        rl.scroll(function() {
            that.loadMore();
        });
        if (!that.get('readOnly')) {
            $(nf).children('.bc-new-folder').addClass('active');
        } else {
            $(nf).children('.bc-new-folder').css({'display': 'none'});
        }

        if (typeof folders !== 'undefined') {

           if (typeof folders.length == 'undefined' && folders.path != 'undefined') {
                $(rl).append('<li class="folder" data-uri="' + folders.path + '"><a href="' + folders.path + '"><span class="folder"></span>' + folders.name.truncate(30) + '<span class="navArrow"></span></a></li>');
           }
            for (i = 0; i < folders.length; i++) {
                 if (typeof folders[i].flag !== 'undefined') {
                     //this is the article specfic BC URI
                     burke.set('articleBCURI',folders[i].path);
                 }

                 $(rl).append('<li class="folder" data-uri="' + folders[i].path + '"><a href="' + folders[i].path + '"><span class="folder"></span>' + folders[i].name.truncate(30) + '<span class="navArrow"></span></a></li>');
             }
         }


        if (typeof files !== 'undefined') {
             for (cnt = 0; cnt < files.length; cnt++) {
                 if(   (burke.get("activeTab") == "image" && burke.isImage(files[cnt].path)) ||
                      (burke.get("activeTab") == "other" && !burke.isImage(files[cnt].path)) ||
                      burke.get("activeTab") == "all"){
                         $(rl).append('<li class="file" data-uri="' + files[cnt].Id + '"><a href="' + files[cnt].path + '" draggable="true"><span class="file"></span>' + files[cnt].name + '</a></li>');
                   }
               }
           }
        if (column.search && typeof files !== 'undefined' && typeof folders !== 'undefined' && files.length === 0 && folders.length === 0) {
            $(rl).append('<li class="" ><a><span class=""></span>No Results Found</a></li>');
        }



        //write out the result
        $(that.get('column')).children('.bc-column-content').html('').append(nf).append(rl);
        $(that.get('column')).data('uri',that.get('uri'));

        if (typeof callBack === 'function') {
            //execute the callback function
            callBack();
        }
    };
    this.loadMore = function () {
        if (!this.get('loadingMore')) {
            var that = this,
                data;
            that.set('loadingMore', true);
            var columnData = that.get('columnData'),
                files = columnData.Files,
                total = columnData.total,
                end = columnData.end,
                start = columnData.start,
                batch = burke.get('scrollBatch'),
                ul = $(that.get('column')).children('.bc-column-content').children('ul');

                data = {
                    lang: 'eng',
                    fn: 'directory',
                    locale: locale,
                    cpath: that.get('uri'),
                    fileType: burke.get('activeTab'),
                    contentType: burke.get('contentType'),
                    fileExt: burke.get('allowedFileExtensions'),
                    start: end + 1,
                    end: end + batch
                };
                $.ajax({
                  url: burke.get('apiUrl'),
                  async: true,
                  dataType: 'json',
                  data: data,
                  success: function (data) {
                    var newFiles = data.Files;
                    files = files.concat(newFiles);
                    end = data.end;
                    start = data.start;
                    total = data.total;
                    that.set('columnData',data);
                    for (var cnt = 0; cnt < newFiles.length; cnt++) {
                        ul.append('<li class="file" data-uri="' + newFiles[cnt].Id + '"><a href="' + newFiles[cnt].path + '" draggable="true"><span class="file"></span>' + newFiles[cnt].name.truncate(30) + '</a></li>');
                    }
                    if (end < total) {
                        that.set('loadingMore', false);
                    }
                  }
                });
        }
    };
    this.clear = function () {
        var that = this,
            rl = $('<ul></ul>').scroll(function() {
                that.loadMore();
            }),
            nf = $('<div class="bc-column-new-folder"></div>');
        that.set('loadingMore', false);

        $(that.get('column')).children('.bc-column-content').html('').append(nf).append(rl);
    };
}

function Details_view() { //detail view
    'use strict';

    this.dataStore = {
        detailData: '',
        uri: '',
        fileID: '',
        id: 'bc-details-pane'
    };

    //public generic getter
    this.get = function (key) {
        return this.dataStore[key];
    };

    //public generic setter
    this.set = function (key, value) {
        this.dataStore[key] = value;
        return this;
    };

    //methods
    this.init = function (id) {
         this.set('uri', burke.get('apiUrl') + '?lang=eng&fn=file&fileId=' + id);
         this.set('fileID',id);



         //store it in the details pane
         //$('#' + this.get('id')).data(this);

         return this;
    };
    this.update = function () {
        var that=this;

        $.getJSON(that.get('uri'), function (data) {
            that.set('detailData',data);
            if (typeof data === 'object' && typeof data['binary-content'] === 'object') {
                that.render();
            } else {
                that.clear();
            }
        });

        return that;
    };
    this.render = function () {

        /*Setting crop button HTML according to whether file extension is image extension */
        var cropBtn = '<li id="cropLink"><a href="#crop" class="crop">Crop</a></li>';
        var that = this;
        var file = that.get('detailData'),
            hasCrop = false,
            allowedWidth = burke.get("allowedWidth"),
            allowedHeight = burke.get("allowedHeight"),
            minWidth = burke.get("minWidth"),
            minHeight = burke.get("minHeight"),
            fileName;
        if ( file !== undefined ) {
           fileName = file['binary-content']['file-name'];
        }
        if(!burke.isCroppable(fileName)){
            cropBtn = '';
        }


        /* Build Crop Options Here */

        var binaryContent = file['binary-content'];
        var imageProcessingData = binaryContent['image-processing'];
        var cropOptions = "<option value='"+ file['binary-content'].path +"'>Original</option>";

        var checkedAttr = "";
        if(binaryContent.deepZoom !== null){
            checkedAttr = "checked='checked'";
            cropOptions += "<option value='"+binaryContent.deepZoom+"'>Deep Zoom</option>";
        }

        if(imageProcessingData){
            var cropData = imageProcessingData.crop;
            if(cropData !==undefined && cropData.length === undefined){ //if not an array than wrap in array so for loop works with single element
                cropData = [cropData];
            }

            for(var i=0; cropData!==undefined && i<cropData.length; i++){
                var cropDataObj = cropData[i];
                window.cropData = cropDataObj;
                cropOptions += "<optgroup label="+cropDataObj.jsonAttributes['aspect-ratio-name']+">";
                var resizeData = cropDataObj.resize;
                if( resizeData!==undefined && resizeData.length === undefined){ //if not an array than wrap in array so for loop works with single element
                    resizeData = [resizeData];
                }

                for(var j=0; resizeData!==undefined && j<resizeData.length; j++){
                    var dimensions = resizeData[j].jsonAttributes.options;
                    var url = binaryContent.path.substr(0,binaryContent.path.lastIndexOf("/")) + "/" + dimensions + "/" + fileName;
                    var selected = "";
                    var optionClass = "";
                    if ( allowedWidth + "x" + allowedHeight == dimensions ) {
                        selected = 'selected="selected"';
                        optionClass = 'class="forcedDimensions"';
                        hasCrop = true;
                    }
                    cropOptions+= "<option value='" + url + "' " + selected + optionClass + ">" + dimensions + "</option>";
                }
                cropOptions += "</optgroup>";
            }
        }

        var deepZoomHtml = '<div class="two-col clear" id="deepZoomCheckBox"><strong>Deep Zoom:</strong><input type="checkbox" class="unclickable" id="deepzoom" '+checkedAttr+'></input><label for="deepzoom" class="unclickable"></label></div>';

        if(!burke.get("deepZoom").exists || burke.get("deepZoom").exists == "false"){
            deepZoomHtml = "";
            window.deepZoomChecked=false;
        }

        var fileURL = file['binary-content'].path;
        /* Removed Height & Width option
         *      <label for="image-option-width">Width: </label><input type="text" id="image-options-width"/>
         *      <label for="image-option-height">Height: </label><input type="text" id="image-options-height"/> */
        var altOptionHTML = '<label for="image-option-alt">Alt: </label><input type="text" id="image-options-alt"/>';
        if(burke.get("textareaID") === undefined){
            altOptionHTML = "";
        }

        var fileName = file['binary-content']['file-name'];
        var rdetail = $('<h3></h3><p class="cropNeeded" style="display:none;"><span class="ldse-icon ldse-icon-ko-warning"></span>&nbsp;<span class="errorText"></span></p><p class="minImageSizeNeeded" style="display:none;"><span class="ldse-icon ldse-icon-ko-warning"></span>&nbsp;<span class="errorText"></span></p><ul><li><a href="#edit" class="edit">Edit</a><a href="#done" class="btn done" style="display:none">Done</a></li>'+cropBtn+'<li><a href="#delete" class="deleteIcon">Delete</a></li><li><a href="'+fileURL+'?download=true" download="'+fileName+'" class="downloadBtn">Download</a></li></ul><a href="" target="_blank" class="bc-preview-link"><img class="bc-image-preview" onerror="$(\'.bc-details #cropLink\').hide()";/></a><div class="clear"><button href="" class="btn green">Insert into article</button><a href="#options" onclick="return false;" id="image-options-link" style="display:none">Show Insert Options</a></div><div id="imageOptions" style="display:none"><form><label for="thumbnailSelect">Image Dimensions:</label><select id=\'thumbnailSelect\'>'+cropOptions+'</select><br />'+ altOptionHTML +'</form></div><div id="bc-asset-size" class="two-col clear"><strong>Size:</strong><p>&nbsp;</p></div><div id="bc-asset-title" class="two-col clear"><strong>File Name:</strong><p>&nbsp;</p></div><div id="bc-asset-url" class="two-col clear"><strong>URL:</strong><p><a href="" target="_blank" id="imageURLLink" class="bc-preview-link">&nbsp;</a></p></div><div id="bc-telescope-id" class="two-col clear"><strong>Telescope Id:</strong><p></p></div><div id="bc-tags" class="two-col clear"><strong>Tags:</strong><p></p></div><div id="bc-description" class="two-col clear"><strong>Description:</strong><p></p></div>'+deepZoomHtml+'<div class="known-usage clear"></div>'),
        
            that=this,
            file = that.get('detailData'),
            fileName = file['binary-content']['file-name'],
            title = file['binary-content']['title-block']['binary-title'],
            assetTitle = file['binary-content']['title-block']['binary-title'],
            description = file['binary-content']['title-block'].description,
            telescope = file['binary-content']['title-block'].telescope,
            fileSize = parseFloat(file['binary-content']['file-size']) / 1024,
            // default width and height to 0 so they fail min-width/height test for images missing width/height dimensions
            width = file['binary-content'].dimensions && file['binary-content'].dimensions.width ? parseInt(file['binary-content'].dimensions.width) : 0,
            height = file['binary-content'].dimensions && file['binary-content'].dimensions.height ? parseInt(file['binary-content'].dimensions.height) : 0,
            size = "",

            img = (file['binary-content'].thumbnail) ? file['binary-content'].thumbnail : file['binary-content'].path,
            tagString = '',

            i,
            href = window.location.protocol + '//' + window.location.host + fileURL;


            that.set('fileURI', fileURL);

            if (file['binary-content'].meta.subjects !== undefined && file['binary-content'].meta.subjects !== null) {
                var tags = file['binary-content'].meta.subjects.subject;
                if (typeof tags === 'object') {
                    for (i in tags) {
                        if (tags.hasOwnProperty(i)) {
                            tagString += tags[i].replace(/'/g,'') + ',';
                        }
                    }
                } else {tagString = tags.replace(/'/g,'');}
            }
            if (isNaN(fileSize)) {
                $(rdetail).siblings('#bc-asset-size').hide();
            } else if (fileSize > 1024) {
                size = roundNumber(fileSize / 1024, 2) + " MB";
            } else {
                size = roundNumber(fileSize, 2) + " KB";
            }



            $(rdetail).siblings('h3').text(title);
            $(rdetail).siblings('#bc-asset-size').children('p').text(size);
            if ( assetTitle.indexOf(".") != -1 ){
                $(rdetail).siblings('#bc-asset-title').children('p').text(assetTitle);
            } else {
                $(rdetail).siblings('#bc-asset-title').children('p').text(assetTitle + "." + fileName.split(".")[1]);
            }

            $(rdetail).siblings('#bc-description').children('p').text(description);
            $(rdetail).siblings('#bc-telescope-id').children('p').text(telescope);
            $(rdetail).siblings('#bc-asset-url').children('p').children('a').text(href);
            $(rdetail).find('.bc-preview-link').attr('href', href);
            $(rdetail).siblings('.bc-preview-link').attr('href', href);
            $(rdetail).siblings('#bc-tags').children('p').text(tagString);
            if (burke.get('activeTab') === 'image' || fileName.toLowerCase().match(/\.(bmp|jpg|gif|png|jpeg|tif)$/)) {
                $(rdetail).find('.bc-image-preview').attr('src', fileURL + "?x="+ randString());
            } else {
                $(rdetail).find('.bc-image-preview').attr('src', burke.get('otherImage'));
            }
            if ( !hasCrop && allowedWidth && allowedHeight ) {
                $(rdetail).find(".btn.green").attr('disabled', 'disabled').addClass("inactive");
                $(rdetail).siblings(".cropNeeded").find(".errorText").text("You need to crop this image before inserting!");
                $(rdetail).siblings(".cropNeeded").show();
            }
            var rdetailImage = $(rdetail).find("img")[0];
            if ((minWidth && minWidth >= width) || (minHeight && minHeight >= height)) {
                $(rdetail).find(".btn.green").attr('disabled', 'disabled').addClass("inactive");
                $(rdetail).siblings(".minImageSizeNeeded").find(".errorText").text("An image with a minimum width of " + minWidth + " and a minimum height of " + minHeight + " is required.");
                $(rdetail).siblings(".minImageSizeNeeded").show();
            }
            function randString(){
                var randStr = "";
                var strLength = 20;
                var chars = "abcdefghijklmnopqrstuvwxyz1234567890".split('');
                for(var i=0; i<strLength; i++){
                    randStr += chars[Math.floor(Math.random()*chars.length)];
                }
                return randStr;
            }

        //write out the result
        $('#' + that.get('id')).html('').append(rdetail);



        $('#' + that.get('columnId')).data('fileID', that.get('fileID'));

        /* Load in options for dimension drop down */
      /*  $.ajax({
            type: "POST",
            url: '/binary/resources/ajax/getCropOptions?lang=eng',
            data: '',
            success:
                function(response){
                    $("#thumbnailSelect").html(response);
                },
            error:
                function(){
                    alert("oh no! couldn't get options");
                }
        });
        */

        /* Add listener to change file path */
        $("#thumbnailSelect").on("change", function(e){
            if ( hasCrop && allowedWidth && allowedHeight && $("#thumbnailSelect").val().indexOf(allowedWidth + "x" + allowedHeight) == -1 ) {
                $(".btn.green").attr("disabled", "disabled").addClass("inactive");
                $(".cropNeeded").find(".errorText").text("You can only use the image dimensions " + allowedWidth + 'x' + allowedHeight);
                $(".cropNeeded").show();
            } else if ( hasCrop && allowedWidth && allowedHeight && $("#thumbnailSelect").val().indexOf(allowedWidth + "x" + allowedHeight) != -1 ) {
                $(".cropNeeded").hide();
                $(".btn.green").removeAttr("disabled", "disabled").removeClass("inactive");
            }
            var newSrc = $("#thumbnailSelect").val();
            $(rdetail).find('.bc-image-preview').attr('src', newSrc+"?x="+randString());
            $('a.bc-preview-link').attr('href',newSrc);
            $("#imageURLLink").html(newSrc);
            $(".bc-details .downloadBtn").attr("href",newSrc);
            details.set('fileURI',newSrc);
        }).change();

        //that.getKnownUsage();
        if (burke.get('activeTab') === 'image') {
            $('#image-options-link').show();
        }



        return that;
    };
    this.getKnownUsage = function () {
        var uri = burke.get('apiUrl') + 'usage?id=',
        that = this;

        $.get(uri + that.get('fileID'), function (data) {
            that.set('usage', data);
            that.renderUsage();
        });

        return that;
    };
    this.renderUsage = function () {
        var that = this,
            targetDiv = $('#' + that.get('id')).children('.known-usage'),
            data = that.get('usage').Usage,
            i,
            content = $('<h5>Known Usage</h5><table><thead><th>ARTICLE TITLE</th><th>LAST MODIFIED</th><th>MODIFIED BY</th><th></th></thead><tbody></tbody></table>');

        for (i = 0; i < data.length; i++) {
            $(content).children('tbody').append('<tr><td><a href="' +data[i].link + '">' + data[i].title.truncate(15) + '</a></td><td>' + data[i].modifiedDate + '</td><td>' + data[i].modifiedBy.truncate(16) + '</td><td><span class="status ' + data[i].status + '" title="' + data[i].status + '"></span></td></tr>');
        }
        $(targetDiv).html(content);

        if (burke.get('activeTab') === 'image') {
            $('#image-options-link').show();
        }

        return that;
    };
    this.clear = function () {
        var that = this;

        $('#' + that.get('id')).html('');
    };
}


function clearCacheForImages(){
    var binaryContent = details.get('detailData')['binary-content'];
    if(!binaryContent){
        return;
    }
    var fileName = binaryContent['file-name'];
    var uris = [binaryContent.path]; //start with original path to image initially
    var imageProcessingData = binaryContent['image-processing'];
    if(imageProcessingData){ //if imageProcessingData add cropped uris to have cache cleared for them as well
        var cropData = imageProcessingData.crop;
        for(var i=0; i<cropData.length; i++){
            var cropDataObj = cropData[i];
            var resizeData = cropDataObj.resize;
            if(resizeData){
                for(var j=0; j<resizeData.length; j++){
                    var dimensions = resizeData[j].jsonAttributes.options;
                    var url = binaryContent.path.substr(0,binaryContent.path.lastIndexOf("/")) + "/" + dimensions + "/" + fileName;
                    uris.push(url);
                }
            }
        }
    }

    clearCacheForUris(uris);

}

/*Takes an array of uris and clears cache for all of them */
function clearCacheForUris(uris){
    var clearCacheURL = sharedPrefix + '/clear-cache/clear-cache-post';
    var urisString = uris.join("**");
    $.ajax({
        type:"POST",
        data: {
                locale:"eng",
                lang:"eng",
                uris:urisString
              },
        url: clearCacheURL,
        success:function(response){
            //console.log("Clear Cache Response for these uris:\n" + uris.join("\n") + " -> :" + response );
        }

    });
}



function ImageCropper() {
    'use-strict';



    this.storage = {
        aspectRatio: 1,
        canvases: null,
        height: 0,
        image: null,
        jcrop: null,
        selectedCanvas: null,
        width: 0
    }

    // public generic getter
    this.get = function(key) {
        return this.storage[key];
    };

    // public generic setter
    this.set = function(key, value) {
        this.storage[key] = value;
    };

    // methods
    this.setCanvasOpacity = function(canvas, alpha) {
        var that = this;
        var x = canvas.attr('data-selection-x1');
        var y = canvas.attr('data-selection-y1');
        var w = canvas.attr('data-selection-x2') - x;
        var h = canvas.attr('data-selection-y2') - y;
        var ctx = canvas[0].getContext("2d");
        ctx.clearRect(0, 0, canvas.width(), canvas.height());
        ctx.globalAlpha = alpha;
        ctx.drawImage(that.get('image'), x, y, w, h, 0, 0, canvas.width(), canvas.height());
    };

    this.disableCanvas = function(canvas) {
        this.setCanvasOpacity(canvas, 0.4);
    };

    this.enableCanvas = function(canvas) {
        this.setCanvasOpacity(canvas, 1);
    };

    this.addCanvasDataToForm = function(canvas) {
        this.get('canvases').each(function() {
            var name = $(this).attr('data-aspect-ratio-name');
            var x1 = $(this).attr('data-selection-x1');
            var y1 = $(this).attr('data-selection-y1');
            var x2 = $(this).attr('data-selection-x2');
            var y2 = $(this).attr('data-selection-y2');
            var w = x2 - x1;
            var h = y2 - y1;
            $('#imageCropperForm').append('<input name="' + name + '" type="hidden" value="' + w + 'x' + h + '+' + x1 + '+' + y1 + '"/>');
        });
    };

    this.drawCanvas = function(canvas, x, y, w, h) {
        var that = this;
        var ctx = canvas[0].getContext('2d');
        ctx.fillStyle = "white";
        ctx.fillRect(0,0,canvas.width(),canvas.height());
        ctx.drawImage(that.get('image'), x, y, w, h, 0, 0, canvas.width(), canvas.height());
        canvas.attr('data-selection-x1', x);
        canvas.attr('data-selection-y1', y);
        canvas.attr('data-selection-x2', x * 1 + w * 1);
        canvas.attr('data-selection-y2', y * 1 + h * 1);
    };

    this.drawCanvasAlpha = function(canvas, x, y, w, h, alpha) {
        var that = this;
        var ctx = canvas[0].getContext('2d');
        ctx.clearRect(0, 0, canvas.width(), canvas.height());
        ctx.globalAlpha = alpha;
        ctx.drawImage(that.get('image'), x, y, w, h, 0, 0, canvas.width(), canvas.height());
        canvas.attr('data-selection-x1', x);
        canvas.attr('data-selection-y1', y);
        canvas.attr('data-selection-x2', x * 1 + w * 1);
        canvas.attr('data-selection-y2', y * 1 + h * 1);
    };

    this.drawCanvasFromJcrop = function(canvas, selection) {
        /* Ensure that values are not out of bounds */
        var imgWidth = $("#cropperMainImage").width();
        var imgHeight = $("#cropperMainImage").height();
        if(selection.x < 0){
            selection.x = 0;
        }
        if(selection.x + selection.w > imgWidth){
            selection.w = imgWidth - selection.x;
        }
        if(selection.y <0){
            selection.y =0;
        }
        if(selection.y + selection.h > imgHeight){
            selection.h = imgHeight - selection.y;
        }

        this.drawCanvas(canvas, selection.x, selection.y, selection.w, selection.h);
        this.updateValidDimensions(selection);
    };

    this.updateValidDimensions = function(selection){

          $("canvas.selected").parent().find(".dimensionList li").each( function(){
              var dimensionHtml = $(this).html();
              var dimensions = dimensionHtml.split("x");
              if(selection.w < dimensions[0] || selection.h < dimensions[1]){
                  $(this).addClass("tooLarge");
                  hasTooLarge = true;
              }
              else{
                  $(this).removeClass("tooLarge");
              }
          });

          if($(".tooLarge").length > 0){
            //show legend
              $("#dimensionLegend").show();
          }
          else{
             //hide legend
              $("#dimensionLegend").hide();
          }
    };

    this.init = function() {

        var that = this;
        that.set('image', new Image());
        that.get('image').src = $('#cropperMainImage').attr('src');
        $('#cropperMainImage').load(load);
        $(".jcrop-holder img").hide();
        $('#cropperMainImage').hide();
        function load(){
            $('#cropperMainImage').show();
            $(".jcrop-holder img").show();
            that.set('selectedCanvas', $('#canvases').find('canvas').first());
            that.get('selectedCanvas').addClass('selected');
            that.set('aspectRatio', that.get('selectedCanvas').attr('data-aspect-ratio'));
            that.set('width', $('#cropperMainImage').width());
            that.set('height', $('#cropperMainImage').height());
            that.set('jcrop', $.Jcrop('#cropperMainImage', {
                aspectRatio: that.get('aspectRatio'),
                bgColor: 'white',
                bgOpacity: 0.3,
                boxWidth: 500,
                boxHeight: 400,
                onSelect: function(selection) {
                    that.drawCanvasFromJcrop(that.get('selectedCanvas'), selection)
                }
            }));


            $('.imageCropper .thumbnail canvas').mouseover(function() {
                if ($(this).attr('class') != 'selected') {
                    addCropIcon($(this));
                }
            });
            $('.imageCropper .thumbnail canvas').mouseout(function() {
                removeCropIcon($(this));
            });

            $('.imageCropper .thumbnail canvas').click(function() {


                if ($(this).attr('class') != 'selected') {
                    removeCropIcon($(this));
                    that.get('selectedCanvas').removeClass('selected');
                    that.disableCanvas(that.get('selectedCanvas'));
                    $(this).addClass('selected');
                    that.set('selectedCanvas', $(this));
                    that.enableCanvas(that.get('selectedCanvas'));
                    that.jcropSelectFromCanvas(that.get('selectedCanvas'));
                    that.updateValidDimensions(that.get('jcrop').tellSelect());
                }
            });
            $('.imageCropper #saveCropBtn').click(function() {
                that.addCanvasDataToForm();
                var data = $('#imageCropperForm').serialize();
                $("#saveCropBtn").addClass("disabled");
                $("body").append("<div class='cropperLoading'></div>");
                $.ajax({
                    type: "POST",
                    url: sharedPrefix + '/binary/resources/ajax/saveCroppedImages?lang=eng',
                    data: data,
                    success:
                        function(){
                            $(".cropperLoading").remove();
                            $("div." + burke.get('wrapperSelector') + " div.imageCropper").remove();
                            $('div.' + burke.get('wrapperSelector')).removeClass("imageCropperOpen");
                            $("#search,#workingDir").show();
                            details.update();
                            //clearCacheForImages();
                        },
                    error:
                        function(){
                            $(".cropperLoading").remove();
                            alert("An error occured while trying to crop!");
                            $("#saveCropBtn").removeClass("disabled");

                        }

                    });

            });
            $('.imageCropper #cancelCropBtn').click(function() {
                $("div." + burke.get('wrapperSelector') + " div.imageCropper").remove();
                $('div.' + burke.get('wrapperSelector')).removeClass("imageCropperOpen");
                $("#search,#workingDir").show();
            });

            setTimeout(function(){thumbnailLoad()},50);
            function thumbnailLoad(){
                if(that.get('jcrop').tellSelect().h==0){
                    setTimeout(function(){thumbnailLoad()},50);
                }
                that.updateValidDimensions(that.get('jcrop').tellSelect());
                that.initCanvases();
                $('#canvases').find('canvas').last().click();
                $('#canvases').find('canvas').first().click();
                that.jcropSelectFromCanvas(that.get('selectedCanvas'));
            }
        }


        function addCropIcon(canvas){
            var hoverIcon = canvas.parent().find(".hover-icon");
            if(hoverIcon[0] == undefined){
                canvas.parent().append("<div class='hover-icon'></div>");
                canvas.parent().find(".hover-icon").width(canvas.width()).height(canvas.height());
            }
            else{
                hoverIcon.show();
            }
        }

        function removeCropIcon(canvas){
            canvas.parent().find(".hover-icon").hide();
        }


    };

    this.initCanvases = function() {
        var that = this;
        var width = that.get('width');
        var height = that.get('height');
        that.set('canvases', $('#canvases').find('canvas'));
        var alpha = 1;
        that.get('canvases').each(function() {
            var x1 = $(this).attr('data-selection-x1');
            var y1 = $(this).attr('data-selection-y1');
            var x2 = $(this).attr('data-selection-x2');
            var y2 = $(this).attr('data-selection-y2');
            var drawHeight, drawWidth, drawX, drawY;
            if (x1 == '' || y1 == '' || x2 == '' || y2 == '') {
                var temp = height * $(this).attr('data-aspect-ratio');
                if (temp <= width) {
                    drawWidth = temp;
                    drawHeight = height;
                } else {
                    drawWidth = width;
                    drawHeight = height * width / temp;
                }
                drawX = 0;
                drawY = 0;
            } else {
                drawX = x1;
                drawY = y1;
                drawWidth = x2 - x1;
                drawHeight = y2 - y1;
            }
            that.drawCanvasAlpha($(this), drawX, drawY, drawWidth, drawHeight, alpha);
            alpha = 0.5;
        });
    };

    this.jcropCenter = function() {
        var that = this;
        var selection = that.get('jcrop').tellSelect();
        if (selection.w > 0 && selection.h > 0) {
            var newSelectionX1 = that.get('width') / 2 - selection.w / 2;
            var newSelectionY1 = that.get('height') / 2 - selection.h / 2;
            that.get('jcrop').setSelect([newSelectionX1, newSelectionY1, newSelectionX1 + selection.w, newSelectionY1 + selection.h])
        }
        that.drawCanvasFromJcrop(that.get('selectedCanvas'), that.get('jcrop').tellSelect());
    };

    this.jcropSelectFromCanvas = function(canvas) {
        this.get('jcrop').setSelect([
            canvas.attr('data-selection-x1'),
            canvas.attr('data-selection-y1'),
            canvas.attr('data-selection-x2'),
            canvas.attr('data-selection-y2')
        ]);
        this.get('jcrop').setOptions({
            aspectRatio: canvas.attr('data-aspect-ratio')
        });
    }

    this.jcropMaximize = function() {
        var that = this;
        var height = that.get('height');
        var width = that.get('width');
        var temp = height * that.get('aspectRatio');
        if (temp <= width) {
            that.get('jcrop').setSelect([0, 0, temp, height])
        } else {
            that.get('jcrop').setSelect([0, 0, width, height * width / temp])
        }
        that.drawCanvasFromJcrop(that.get('selectedCanvas'), that.get('jcrop').tellSelect());
    };
}
