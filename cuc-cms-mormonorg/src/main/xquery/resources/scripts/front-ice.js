var hash = window.location.hash.split("=")[1];
var permalinkValue = {};
if (typeof (ICE) === "undefined") {
  /* jQuery Case-Insensitive :containsNC */
  $.extend($.expr[ ":"], {
    "containsNC": function (elem, i, match, array) {
      return (elem.textContent || elem.innerText || "").toLowerCase().indexOf((match[3] || "").toLowerCase()) >= 0;
    }
  });

  CKEDITOR_BASEPATH = location.protocol + cdnPath + '/lds-edit/scripts/ckeditor/';

  var ICE = {
    modal: $('#modal1'),
    ckeditor_loaded: false,
    page: null,
    uri: null,
    carousel: true, /* Current status of rotating carousels */
    formVars: '', /* SET when form opens */
    actions: {
      "ldse:publish": "Preview",
      "ldse:unpublish": "Unpublish",
      "ldse:remove": "Remove",
      "ldse:delete": "Delete"
    },
    post: function (path, params, method) {
      method = method || "post";
      var form = $("<form/>"),
      hiddenField;
      if (params && params.id && params.id != "" && path.indexOf('/shared/lds-edit/form') != -1 && path.indexOf('&id=') == -1) {
        path += '&id=' + params.id;
        delete params.id;
      }
      form.attr("method", method).attr("action", path).hide();
      for (var key in params) {
        if ($.isArray(params[key])) {
          for (var i = 0; i < params[key].length; i++) {
            hiddenField = $("<input/>");
            hiddenField.attr("type", "hidden").attr("name", key).attr("value", params[key][i]);
            form.append(hiddenField);
          }
        } else {
          hiddenField = $("<input/>");
          hiddenField.attr("type", "hidden").attr("name", key).attr("value", params[key]);
          form.append(hiddenField);
        }
      }
      $('body').append(form);
      form.submit();
      return false;
    },

    postLink: function (link) {
      link = $(link);
      var data = link.data();
      var postData = {
      };
      for (key in data) {
        if (data.hasOwnProperty(key) && key.indexOf('post.') == 0) {
          postData[key.replace(/post\./, '')] = data[key];
        }
      }
      ICE.post(link.attr('href'), postData);
      return false;
    },
        createComponent: function (link) {
            var uri = $(link).data('post.uri'),
                options = $(link).data('post.option'),
                country = $(link).data('post.country'),
                type = $(link).data('post.content-type'),
                located = $(link).data('post.location');
                parent = $(link).data('post.parent-id');
      if ($('.ldseForm').length > 0) {
        $('.ldseForm').remove();
      }
      $('<div class="ldseForm ldse-page"></div>').appendTo('body');
      $('.actionImage').append('creating');
      ICE.buildComponentModal(type);
            $.ajax({
                type: "POST",
                url: sharedPrefix + '/shared/lds-edit/ice/resources/ajax/component/create?' + ICE.langParam(locale),
                data: {
                    uri: uri, locale: locale, option: options, country: country, type: type, location: located, parentId: parent
                },
                success: function (data) {
          $('.actionImage').html('<span class="ldse-publish-dialog ldse-icon-check2"></span><div id="status_teaser" class="publishStatus">Created Component</div>');
                },
                error: function (data) {
          $('.actionImage').html('<span class="ldse-publish-dialog ldse-icon-ko-warning"></span><div id="status_teaser" class="publishStatus">Error Creating Component</div>');
                }
            })
        },
    buildComponentModal: function (type) {
      "use strict";
      ACT.TRIES = {};
      var div = $('<div class="actionModal ldseForm"><link rel="stylesheet" media="screen" type="text/css" href="' + sharedPrefix + '/shared/lds-edit/ice/resources/styles/screen.css"/></div>');
      if (type) {
        div.append(
        $('<div class="ldse-clearfix">' +
        '<div class="actionLabel">' + type + ': </div>' +
        '<div id="image_' + type + '" class="actionImage">' +
        '<span class="ui-finder-loader">&nbsp;</span><div id="status_' + type + '" class="actionStatus"/>' +
        '</div>' +
        '</div>' +
        '</div>'));
      }
      // Close button
      div.append(
      $('<div class="actionClose">').append(
          $('<button id="" class="ldse-button">Close</button>').click(function () {
            $('.actionItems').remove().dialog("close");
            if (ICE.teaserManagerActive === false) {
              if (ACT.RELOAD !== "") {
                location = ACT.RELOAD;
              } else {
                location.reload();
              }
            } else {
              $('.actionModal').remove().dialog("close");
            }
          }))
      );
      $('.actionModal').remove().dialog("close");
      div.dialog({
        position:[($(window).width() / 2) - (500 / 2), 150],
        dialogClass: "ldseForm ldse-modal",
        height: 'auto',
        width: 500,
        zIndex: 4000,
        draggable: true,
        modal: true,
        title: 'Creating Component',
        close: function () {
          $('.actionModal').remove().dialog("close");
        }
      });
    },
    minEvaluate: function () {
      var minValue = $('ul.sortable').data('min');
      if (minValue && minValue !== undefined) {
        for (var i = 0; i >= minValue; i++) {
          ICE.alertText("Test", "This is a test", function () {
            window.close();
          });
          $('ul.sortable').closest('dd').find('a.ldse-add').click();
        }
      } else {
      }
    },
    alertText: function (title, text, onOk, options) {
      var defaults = {
        okText: "OK",
        okClass: "primary ldse-icon-check2",
        cancelText: "Cancel",
        cancelClass: "ldse-icon-x"
      };
      options = $.extend({
      },
      defaults, options);
      $('#alertModal').remove().dialog('close');
      var modal = $(
      '<div id="alertModal" class="ldseForm">' +
      '<form class="ldse-section--body ldse-form">' +
      '<dl><dt><label>' + text + '</label></dt></dl>' +
      '<div class="ldse-form-buttons">' +
      '<button id="alert-ok" class="ldse-button ' + options.okClass + '">' + options.okText + '</button>' +
      '<button id="alert-cancel" class="ldse-button ' + options.cancelClass + ' float-right">' + options.cancelText + '</button>' +
      '</div>' +
      '</form>' +
      '</div>');
      modal.find('#alert-ok').click(function (e) {
        e.preventDefault();
        e.stopPropagation();
        $('#alertModal').remove().dialog('close');
        if (typeof onOk !== "undefined") {
          onOk();
        }
        return false;
      });
      modal.find('#alert-cancel').click(function (e) {
        e.preventDefault();
        e.stopPropagation();
        $('#alertModal').remove().dialog('close');
      });
      //$('body').append(modal);
      modal.dialog({
        position:[(window.innerWidth / 2) - 150, 150],
        dialogClass: "ldse-modal ldse-form ldseForm",
        height: 'auto',
        width: '350',
        zIndex: 99999999,
        draggable: true,
        modal: true,
        title: title,
        close: function () {
          $('#alertModal').remove().dialog("close");
        }
      });
    },
    fixedWidth: function (selector) {
      var listWidth =[];
      $(selector).each(function () {
        listWidth.push($(this).outerWidth(false) + 1);
      });
      $(selector).width(Math.max.apply(Math, listWidth));
    },
    langParam: function (locale) {
      var split = locale.split('-');
      if (split.length > 1) {
        return 'lang=' + split[0] + '&country=' + split[1];
      } else {
        return 'lang=' + locale;
      }
    },
    linkToItem: function (href, id) {
      sessionStorage.markedItem = id;
      //$.cookie('lds-item-id', id, {expire: .1, path : '/'});

      $.newWindow(href);
    },
    markItem: function () {
      var id = sessionStorage.markedItem;
      if (id !== null && typeof id !== "undefined") {
        id = id.replace(/\//g, "");
      }
      if ( id != undefined ) {
          id = "." + id
           if ( id != ".") {
                    var button = $(id);
                if (button.length > 0) {
                  showIce();
                  setTimeout(function () {
                    $('html, body').scrollTop(button.offset().top - 100);
                    button.addClass('ldse-highlight');
                  },
                  500);
                }
           }
      }
    },
    carouselCheck: function () {
      if ($.cookie('lds-carousel') == "false") {
        $(document).ready(function () {
          ICE.toggleCarousel();
        });
      }
    },
    toggleCarousel: function () {
      if ($('#toggleCarousel').length > 0) {
        if (ICE.carousel == true) {
          $('#toggleCarousel').html('Start Carousel');
          /* stop carousels */
          var carousels = $('#toggleCarousel').data('carousel').split(',');
          for (var i in carousels) {
            $(carousels[i]).cycle('pause');
          }
          /* set cookie */
          $.cookie("lds-carousel", "false", {
            path: "/", expires: 365
          });
          ICE.carousel = false;
        } else {
          $('#toggleCarousel').html('Stop Carousel');
          /* Start carousels */
          var carousels = $('#toggleCarousel').data('carousel').split(',');
          for (var i in carousels) {
            $(carousels[i]).cycle('resume');
          }
          /* Set Cookie */
          $.cookie("lds-carousel", null);
          ICE.carousel = true;
        }
      }
    },

    workflowCheck: function (input) {
      if ($(input).is(':checked')) {
        /* $('#globalCheckbox').removeAttr('disabled'); */
        $('#globalCheckbox').attr('checked', 'checked');
      } else {
        /*
        $('#globalCheckbox').removeAttr("checked");
        $('#globalCheckbox').attr("disabled", true);
         */
      }
    },
    subChannelForm: function (navName, channelName, channelSequence, currentPage, lang, isCustom) {
      if (currentPage === '') {
        currentPage = decodeURIComponent(window.location.pathname);
      }
      if (isCustom === undefined) {
        isCustom = false;
      }
      if ($('.ldseForm').length > 0) {
        $('.ldseForm').remove();
      }
      $('<div class="ldseForm"></div>').appendTo('body');
      $.ajax({
        type: "POST",
        url: sharedPrefix + '/shared/lds-edit/ice/resources/ajax/navigation/channelForm?' + ICE.langParam(locale),
        data: {
          "navName": navName, "channelSequence": channelSequence, "channelName": channelName, "curPage": currentPage, "isCustom": isCustom, referer: location.href
        },
        success: function (html) {
          $('.ldseForm').html(html).append(
          $('<link rel="stylesheet" media="screen" type="text/css" href="' + sharedPrefix + '/shared/lds-edit/ice/resources/styles/screen.css"/>')).dialog({
            dialogClass: "ldseForm ldse-modal",
            position:[($(window).width() / 2) - (1200 / 2), 150],
            height: 'auto',
            maxHeight: 900,
            width: 1200,
            zIndex: 4000,
            draggable: true,
            title: 'Edit Channels',
            modal: 'true',
            close: function () {
              $('.ldseForm').remove().dialog("close");
            }
          });
        }
      });
    },
    clonePage: function (lang, currentPage, action) {
      if ($('.ldseForm').length > 0) {
        $('.ldseForm').remove();
      }
      $('<div class="ldseForm ldse-page"></div>').appendTo('body');
      $.ajax({
        type: "POST",
        url: sharedPrefix + "/shared/lds-edit/ice/resources/ajax/clone-page/clonePageForm?" + ICE.langParam(lang),
        data: {
          "currentPage": currentPage, "action": action
        },
        success: function (html) {
          $('.ldseForm').html(html).dialog({
            dialogClass: "ldseForm ldse-modal",
            maxHeight: 400,
            width: 500,
            zIndex: 4000,
            draggable: true,
            title: 'Clone Page',
            modal: true,
            close: function () {
              $('.ldseForm').remove().dialog("close");
            }
          });
          $('.ldseForm select').fixSelect({
            deriveWidth: false
          });
          //ICE.fixSelects();
        }
      });
      $("#langSelects span.select").css("width", "300px");
    },
    showOmniture: function () {
      if ($('.ldseForm').length > 0) {
        $('.ldseForm').remove();
      }
      $('<div id="omnitureContainer" class="ldseForm"></div>').appendTo('body');
      var name = s.pageName || pageName;
      var urlTxt = sharedPrefix + '/shared/lds-edit/omniture?lang=eng';
      $.ajax({
        type: "POST",
        url: urlTxt,
        data: {
          pageName: name,
          dateRange: 30
        },
        success: function (response) {

          $('.ldseForm').html(response).dialog({
            position:[($(window).width() / 2) - (878 / 2), 150],
            dialogClass: "omnitureModal ldseForm ldse-modal",
            width: 878,
            height: 552,
            title: "Omniture Stats for page:" + name,
            resizable: false,
            modal: true
          });
        },
        error: function (html) {
          //alert("ajax failed");
        }
      });
    },
    showSEOMoz: function () {
      var returnURL = window.location;
      var forwardURL = sharedPrefix + "/shared/lds-edit/seomoz?lang=eng";
      var form = $('<form id="seoForm" action="' + forwardURL + '" method="post"></form>');
      $("body").append(form);
      form.hide();

      form.html('<input type="text" name="returnURL" value="' + returnURL + '" />');
      form.submit();
    }
  };

  function linkChecker () {
    var parent = this,
    notSelectors =[
    '[href^="#"]',
    '[href*="signmeout"]',
    '#ldse-toolbar-container a',
    '.ldse-ice-menu-container a',
    '.pf-header a',
    '.pf-footer a'],
    notString = "";

    if (typeof LINKCHECKER_NOT_SELECTORS !== "undefined") {
      notSelectors.concat(LINKCHECKER_NOT_SELECTORS);
    }
    for (var k = 0; k < notSelectors.length; k++) {
      notString += ':not(' + notSelectors[k] + ')';
    }



    this.servicUrl = sharedPrefix + "/shared/lds-edit/ice/resources/ajax/check-links?lang=eng";

    this.isExternal = function (url) {
      var match = url.match(/^([^:\/?#]+:)?(?:\/\/([^\/?#]*))?([^?#]+)?(\?[^#]*)?(#.*)?/);
      if (typeof match[1] === "string" && match[1].length > 0 && match[1].toLowerCase() !== location.protocol) return true;
      if (typeof match[2] === "string" && match[2].length > 0 && match[2].replace(new RegExp(":(" + {
        "http:": 80, "https:": 443
      }[location.protocol] + ")?$"), "") !== location.host) return true;
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
      this.externalLinks =[];

      this.links = $('a[href][href!=""]' + notString).each(function () {
        var link = $(this);
        var href = this.href + "";
        var external = parent.isExternal(href);
        link.data('checker', {
          url: href,
          external: external,
          preview: null,
          live: null,
          unknown: null
        });
        if (external) {
          parent.externalLinks.push(link);
        }
      });
    };

    this.links =[];
    this.externalLinks =[];
    this.checker = $('#ldse-link-checker');
    this.button = $('#ldse-check-links');
    this.toggleButton = $('#ldse-check-links-toggle');
    this.checkerStatus = $('#ldse-check-links-status');
    this.progressBar = $('#ldse-link-progress-bar-color');

    this.goodCount = $('.ldse-link-count.ldse-good span');
    this.prodCount = $('.ldse-link-count.ldse-broken-prod span');
    this.previewCount = $('.ldse-link-count.ldse-broken-preview span');
    this.unknownCount = $('.ldse-link-count.ldse-unknown span');
    this.uncheckedCount = $('.ldse-link-count.ldse-unchecked span');

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
      this.button.removeClass("ldse-links-broken-link-preview ldse-links-broken-link-prod ldse-links-good ldse-links-unknown");
      $(".ldse-image-link").remove();
      $(this.links).removeClass("ldse-checked-link ldse-broken-link-preview ldse-broken-link-prod ldse-good-link ldse-unknown-link");
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
        this.toggleButton.removeClass("primary ldse-icon-check2 ldse-icon-loop").addClass("ldse-icon-x").html("Stop Checking");
        this.running = true;
        this.checker.addClass('ldse-link-in-progress').removeClass('ldse-link-check-done');
        this.updateCounts();
        this.updateProgress();
        this.checkExternalLinks();
        this.checkLinks();
      }
    };

    this.stop = function () {
      try {
        this.externalXHR.abort();
      }
      catch (e) {
      }
      sessionStorage.linkChecking = "off";
      this.toggleButton.removeClass("ldse-icon-x").addClass("primary ldse-icon-check2").html("Start Checking");
      this.running = false;
      this.checker.removeClass('ldse-link-in-progress');
    };

    this.updateProgress = function () {
      var percent = ((this.total - this.hasLeft) / this.total) * 100;
      this.progressBar.css('width', percent + '%');
    };



    this.checkExternalLinks = function () {
      var urls =[];
      for (var i = 0; i < this.externalLinks.length; i++) {
        var link = this.externalLinks[i];
        var data = link.data('checker');
        urls.push(data.url);
      }

      this.externalXHR = $.ajax({
        url: this.servicUrl,
        type: "POST",
        dataType: "json",
        data: {
          "url": urls,
          "location-host": location.host,
          "location-protocol": location.protocol,
          "location-origin": location.origin
        },
        success: function (json) {
          if (json != null) {
            for (var k = 0; k < json.results.length; k++) {
              var link = parent.externalLinks[k];
              var data = link.data('checker');
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
        }
      });
    };

    this.checkLinks = function () {
      var link = this.links.eq(this.currentIndex);
      var data = link.data('checker');
      function readResponse(http) {
        if (http.status >= 400) {
          data.preview = false;
        } else if (http.status < 400) {
          data.preview = true;
        }
        data.checked = true;
        parent.updateLink(link, data);
      }

      if ( data !== undefined ) {
          if ( !data.external ) {
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
                if (parent.running && parent.currentIndex < parent.total) {
                  setTimeout(function () {
                    parent.checkLinks();
                  },
                  100);
                } else if (parent.currentIndex >= parent.total) {
                  parent.done("internal");
                }
              }
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
          this.button.addClass('ldse-links-good');
        }
        this.updateLinkClass(link, 'ldse-good-link');
        this.hasGood++;
      } else if (data.preview === false) {
        if (this.hasPreview == 0) {
          this.button.addClass('ldse-links-broken-link-preview');
        }
        this.hasPreview++;
        this.updateLinkClass(link, 'ldse-broken-link-preview');
      } else {
        if (this.hasUnknown == 0) {
          this.button.addClass('ldse-links-unknown');
        }
        this.hasUnknown++
        this.updateLinkClass(link, 'ldse-unknown-link');
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
        this.checker.removeClass('ldse-link-in-progress').addClass('ldse-link-check-done');
        this.toggleButton.removeClass("primary ldse-icon-check2").addClass("ldse-icon-loop").html("Recheck Links");
      }
    };

    this.updateLinkClass = function (link, className) {
      link.addClass('ldse-checked-link').addClass(className);
      var images = link.children('img');
      if (images.length > 0) {
        images.each(function () {
          var image = $(this),
          span = $('<span class="ldse-image-link"></span>').insertAfter(image);
          span.width(image.outerWidth()).height(image.outerHeight()).css('top', image.position().top).css('margin-top', image.css('margin-top')).css('left', image.position().left).css('margin-left', image.css('margin-left'));
        });
      }
    };
  }

  var linkChecker;

  function seoChecker(frame) {
    var _ = this;
    this.context = frame || document;

    this.getImgs = function () {
      return $('img', _.context).filter(function () {
        return $(this).closest('.resourceIce,.edit-resource,#beta-feedback').length == 0;
      });
    };

    this.getMetaTitle = function () {
      if ( _.context == document ) {
        return $('head title', _.context).text();
      } else {
        return $((/<title.*?>/.exec(_.context) || "")[0]).text();
      }
    };

    this.getMetaDescription = function () {
      if ( _.context == document ) {
        return $('head meta[name="DESCRIPTION"]', _.context).attr('content');
      } else {
        return $((/<meta.*name="DESCRIPTION".*?>/.exec(_.context) || "")[0]).attr("content");
      }
    };

    this.contains = function (x, y) {
      return x != undefined && y != undefined && x.toUpperCase().indexOf(y.toUpperCase()) != -1;
    };

    this.startsWith = function (x, y) {
      return x != undefined && y != undefined && x.toUpperCase().indexOf(y.toUpperCase()) == 0;
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
      validTitle = typeof (title) != "undefined" && title != "",
      validDesc = typeof (desc) != "undefined" && desc != "",
      validAltCount = 0;
      Score = {
        validTitle: validTitle,
        validDesc: validDesc
      };

      imgs.each(function () {
        if ($(this).attr('alt') != "") {
          validAltCount++;
        }
      });

      var validImgs = imgs.length == validAltCount;

      Score.validImgs = validImgs;
      Score.imgs = imgs.length;
      Score.validAltCount = validAltCount;

      if (validTitle && validDesc && validImgs) {
        Score.score = "good";
      } else if (! validTitle && ! validDesc && (! validImgs || imgs.length == 0)) {
        Score.score = "bad";
      } else {
        Score.score = "warning";
      }

      return Score;
    };

    this.analyze = function(text) {
      var title = _.getMetaTitle(),
        desc = _.getMetaDescription(),
        imgs = _.getImgs(),
        altMatch = false,
        fileMatch = false;

      var score = {
        title : 0,
        firstTitle : 0,
        description : 0,
        body : 0,
        filename : 0,
        altText : 0,
        total : 0
      }

      if ( _.contains(title, text) ) {
        score.title = 30;
        if ( _.startsWith(title, text) ) {
          score.firstTitle = 20;
        }
      }

      if ( _.contains(desc, text) ) {
        score.description = 15;
      }

      if ( $('body *:containsNC("' + text + '"):last', _.context).length > 0 ) {
        score.body = 15;
      }

      imgs.each(function(){
        var img = $(this),
          altMatch = false,
          fileMatch = false;

        if ( !altMatch ) {
          var alt = img.attr('alt');
          if ( _.contains(alt, text) ) {
            score.altText = 15;
            altMatch = true;
          }
        }

        if ( !fileMatch ) {
          var src = img.attr('data-src') || img.attr("src"),
            filename = _.substringAfterLast(src, '/');

          if ( _.contains(filename, text) ) {
            score.filename = 5;
            fileMatch = true;
          }
        }

        if (altMatch && fileMatch) {
          return false;
        }

      });
      score.total = score.title + score.firstTitle + score.description + score.body + score.filename + score.altText;
      score.keyword = text;
      return score;

    };

    this.updateToolbar = function() {
      var score =  _.score(),
        className = "ldse-seo-" + score.score,
        checker = $('#ldse-seo-checker');
      $('#ldse-check-seo, #ldse-seo-checker #ldse-seo-page-score .ldse-seo-scored').addClass(className);
      $('#ldse-seo-checker #ldse-seo-page-score .ldse-seo-scored').html(score.score);
      if (checker.data('saveable') && checker.data('score') != score.score ) {
        _.saveScore(checker.data('uri'), score, checker.data('locale'));
      }
      if (score.validTitle) {
        $('#ldse-seo-checker .ldse-seo-found-title .ldse-seo-scored').addClass('ldse-icon-check1');
      } else {
        $('#ldse-seo-checker .ldse-seo-found-title .ldse-seo-scored').addClass('ldse-icon-x');
      }
      if (score.validDesc) {
        $('#ldse-seo-checker .ldse-seo-found-description-title-score .ldse-seo-scored').addClass('ldse-icon-check1');
      } else {
        $('#ldse-seo-checker .ldse-seo-found-description-title-score .ldse-seo-scored').addClass('ldse-icon-x');
      }
      $('#ldse-seo-checker .ldse-seo-found-alt-score .ldse-seo-scored').html(score.validAltCount);
      $('#ldse-seo-checker .ldse-seo-found-alt-score .ldse-seo-out-of').html("/" + score.imgs);
    };

    this.currentPageAnalyze = function() {
      var text = $('#ldse-seo-keyword').val();
      var score = _.analyze(text);

      $('#ldse-seo-checker .ldse-seo-title-score .ldse-seo-scored').html(score.title);
      $('#ldse-seo-checker .ldse-seo-first-title-score .ldse-seo-scored').html(score.firstTitle);
      $('#ldse-seo-checker .ldse-seo-meta-score .ldse-seo-scored').html(score.description);
      $('#ldse-seo-checker .ldse-seo-page-content-score .ldse-seo-scored').html(score.body);
      $('#ldse-seo-checker .ldse-seo-filename-score .ldse-seo-scored').html(score.filename);
      $('#ldse-seo-checker .ldse-seo-alt-score .ldse-seo-scored').html(score.altText);
      $('#ldse-seo-checker .ldse-seo-total .ldse-seo-scored').html(score.total);

      $('.ldse-seo-scoring').show();
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
          var SEO = new seoChecker({
          });
          SEO.error = true;
          onComplete(SEO);
        }
      });
    };

    this.saveScore = function (url, Score, locale) {
      $.ajax({
        url: sharedPrefix + "/shared/lds-edit/resources/ajax/save-seo-score?lang=eng",
        type: "POST",
        data: {
          url: url,
          score: Score,
          locale: locale
        }
      });
    };
  }

  var SEO = new seoChecker();

  $(document).ready(function () {
    if ( hash ) {
            sessionStorage.markedItem = hash;
        }
        checkCookie();
        var ice = getCookie("ice"),
            iceComps = getCookie("iceComps");
        iceHover();
        if ( ice == 'off' ) { hideIce(); } else { showIce(); }
        if ( iceComps == 'off' ) { hideComps(); } else { showComps(); }
    $("html").attr("id", "ldse-show-ice");
    if (self === top || sessionStorage.forceIce == true || $.getUrlVar('forceIce') == 'true') {
      // show/hide ICE menu
      addIceEvents(false);
      try {
        CKEDITOR.replaceByClassEnabled = false;
      }
      catch (e) {
      }
      $(document).keydown(function (e) {
        if (e.which == 73 && e.altKey) {
          // alt + i
          $('#ldse-ice-toggle').click();
        }
      });
      if (sessionStorage.ldseToolbar == "collapsed") {
        $("#ldse-toolbar-container").addClass("ldse-collapsed");
      }

        /* SEO CHECKER */
        SEO.updateToolbar();
        $('#ldse-seo-checker .ldse-seo-dropdown').click(function(e){
          e.preventDefault();
          e.stopPropagation();
          return false;
        });
        $('#ldse-seo-rank-page').click(function(e){
          e.preventDefault();
          e.stopPropagation();
          SEO.currentPageAnalyze();
          return false;
        });
        $('#ldse-seo-keyword').keypress(function(e) {
              // Enter pressed?
              if(e.which == 10 || e.which == 13) {
                SEO.currentPageAnalyze();
              }
          });
        /* END OF SEO CHECKER */

      createLinkChecker();

      if (sessionStorage.linkChecking == "on") {
        setTimeout(function () {
          linkChecker.start();
        },
        3000);
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

      $('#ldse-ice-toggle').click(function (e) {
        e.preventDefault();
                var ice = getCookie("ice");
        if ( ice == 'on' ) {
          hideIce();
        } else {
          showIce();
        }
        return false;
      });

      $('#ldse-component-toggle').click(function (e) {
        e.preventDefault();
                var iceComps = getCookie("iceComps");
            if ( iceComps == 'on' ) {
                        hideComps();
            } else {
                        showComps();
            }
            return false;
          });

      $('body').click(function (e) {
        closeOpenItems();
      });

      if (typeof s === "undefined" || s.pageName == "") {
        $("#omnitureOption").remove();
      }


      // show browser support message if IE
      // Detecting Internet Explorer More Effectively - http://msdn.microsoft.com/en-us/library/ms537509(v=vs.85).aspx
      if (navigator.appName.toLowerCase().match('microsoft internet explorer') != null) {
        if ($.cookie && $.cookie("ie-warning") != "off") {
          $("#ice-overlay-header").show();
          $(".notify-close").click(closeSupportMessage);
        }
      }
      // Collapse or expand the toolbar
      $("#ldse-toolbar-container.front .ldse-toolbar-toggle").on("click", function (e) {
        $("#ldse-toolbar-container.front").toggleClass("ldse-collapsed");
        if ($("#ldse-toolbar-container.front").hasClass("ldse-collapsed")) {
          sessionStorage.ldseToolbar = "collapsed";
        } else {
          sessionStorage.ldseToolbar = "shown";
        }
        $(".ldse-alert").toggleClass("ldse-collapsed");
      });
      // Display or hide the dropdown menu from the toolbar
      $("#ldse-toolbar-container.front .ldse-dropdownMenu-trigger").on("click", function (e) {
        e.stopPropagation();
        var cur = $(this),
        parent = cur.parent(".ldse-toolbar-item"),
        list = parent.find("ul.ldse-menu").not("ul li ul");
        closeOpenItems(list);
        //$(".ldse-toolbar-item.ldse-open .ldse-dropdownMenu-trigger").not(cur).click();
        list.toggle(0, function () {
          parent.toggleClass("ldse-open");
          list.css({
            'overflow-y': 'auto',
            'overflow-x': 'hidden',
            'max-height': (window.innerHeight - $('#ldse-toolbar').height()) + "px"
          });
        });
      });
      var resizeTimer;
      var window_width = document.width;
      $(window).on("resize.ldse-front orientationchange.ldse-front", function (e) {
        if (window_width != document.width) {
          clearTimeout(resizeTimer);
          resizeTimer = setTimeout(function () {
            closeOpenItems();
            window_width = document.width;
          },
          30);
        }
        $("#ldse-toolbar-container.front .ldse-toolbar-item ul.ldse-menu").find("ul").css({
          'overflow-y': 'auto',
          'overflow-x': 'hidden',
          'max-height': window.innerHeight + "px"
        });
      }).trigger("resize.ldse-front");
      $("#ldse-toolbar-container.front #ldse-toolbar-buttons").delay('slow').show();
      // Fix ice-menus over lapping
      fixOverlappingIceMenus();
      // Show or hide dropdown with buttons
      $("#ldse-toolbar-container.front .ldse-button.dropdown-right").on("click", function (e) {
        var btn = $(this).closest("button");
        listItem = btn.closest("li");
        subList = listItem.find("ul");
        if (btn.hasClass("depressed")) {
          btn.removeClass("depressed");
          subList.hide();
        } else {
          var otherBtn = $(".ldse-button.dropdown-right.depressed").closest("button");
          n = otherBtn.length;
          if (n != 0) {
            otherBtn.removeClass("depressed");
            otherBtn.closest("li").find("ul").hide();
          }

          btn.addClass("depressed");
          subList.show();
          e.stopPropagation();

          $(document).one('click', function () {
            btn = $(".ldse-button.dropdown-right.depressed").closest("button");
            subList = btn.closest("li").find("ul");
            btn.toggleClass("depressed");
            subList.hide();
          });
        }
      });
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
          linkChecker.previewClicks = linkChecker.previewClicks == linkChecker.hasPreview ? 0: linkChecker.previewClicks;
          index = linkChecker.previewClicks;
          linkChecker.previewClicks++;
        } else if (target == ".ldse-good-link") {
          linkChecker.goodClicks = linkChecker.goodClicks == linkChecker.hasGood ? 0: linkChecker.goodClicks;
          index = linkChecker.goodClicks;
          linkChecker.goodClicks++;
        } else if (target == ".ldse-unknown-link") {
          linkChecker.unknownClicks = linkChecker.unknownClicks == linkChecker.hasUnknown ? 0: linkChecker.unknownClicks;
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
          if (link.is(':hidden')) {
            link = link.parents(':visible').first();
          }
          var position = link.offset().top -60,
          distance = Math.abs(window.pageYOffset - position),
          rate = distance * .4;
          rate = rate > 200 ? rate: 200;
          $("html,body").animate({
            scrollTop: position
          },
          rate);
        }
        return false;
      });
          permalinkValue.permalink = $('#permalink').val();
      var permaRoot = $("#permalink").data('root');
      var permalink = $("#permalink");
      if (permalink.length > 0 && permalink.is(':not([readonly])')) {
        $(':input[name=' + permalink.attr('generate-from') + ']').on("blur keyup", function (e) {
          permalinkUpdateFullUri($(this), true, permaRoot);
        })
        $('#permalink').on("blur keyup", function (e) {
          permalinkVerifyUrl();
        });
      }
  }
  else
  {
    $("#ldse-toolbar-container").hide()
  }
});
function checkCookie() {
    var ice = getCookie('ice'),
        iceComps = getCookie('iceComps');
    if ( ice == "" && ice != null ) {
        icey = 'on'
        setCookie('ice', icey, 30);
    }
    if ( iceComps == "" && iceComps != null ) {
        comps = 'off';
        setCookie('iceComps', comps, 30);
    }
};

function setCookie (name, value, days) {
    var d = new Date();
    d.setTime(d.getTime() + (days*24*60*60*1000));
    var expires = "expires=" + d.toGMTString();
    document.cookie = name + "=" + value + "; " + expires;
};

function getCookie(name) {
    var name = name + "=",
        cookie = document.cookie.split(';');
    for(var i = 0; i < cookie.length; i++)
    {
        var cook = cookie[i].trim();
        if (cook.indexOf(name) == 0) return cook.substring(name.length, cook.length);
    }
    return "";
};

  function fixOverlappingIceMenus() {
    // Fix ice-menus over lapping
    var buttons = $('.ldse-ice-menu-container:visible > .ldse-ice-status, .edit-resource:visible > img').sort(function (a, b) {
      var $a = $(a),
      $b = $(b),
      ao = $a.offset(),
      bo = $b.offset();
      if ($a.parent().hasClass("edit-resource"))
      return -1; else if ($b.parent().hasClass("edit-resource"))
      return 1; else if (ao.top < bo.top)
      return -1; else if (ao.top > bo.top)
      return 1; else if (ao.left < bo.left)
      return -1; else return 0;
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
        var currentTop = button2.parent().css('top');
        if (boxesIntersect(offset.left, offset.top, height, width, offset2.left, offset2.top, w, h)) {
          if (currentTop == "auto") {
            button2.parent().css('top', (height + 10) + "px");
          } else {
            button2.parent().css('top', "+=" + (height + 10));
          }
        }
      }
    }
  }

  function createLinkChecker() {
    linkChecker = new linkChecker();
  }

  function boxesIntersect(ax, ay, aw, ah, bx, by, bw, bh) {
    return (Math.abs(ax - bx) * 2 < (aw + bw)) &&
    (Math.abs(ay - by) * 2 < (ah + bh));
  }

  function closeOpenItems(notItem) {
    $('#ldse-ice-menu-clone').remove();
    $('.workflow-table.active').not(notItem).removeClass('active');
    $("#ldse-toolbar-container.front .ldse-toolbar-item.ldse-open ul.ldse-menu").not(notItem).hide().parents('.ldse-toolbar-item.ldse-open').removeClass('ldse-open');
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
    var controls = '.ldse-ice-menu-container';
    if (ajax) {
      controls += '.ajax';
    }

    $(controls + ' .ldse-ice-status').click(function (event) {
      var self = $(this);
      var parent = self.parent();
      closeOpenItems(parent);
      //parent.toggleClass("ldse-open");
      var offset = self.offset();
      var clone = parent.clone();
      if (offset.left < 208) {
        clone = clone.addClass('ldse-menu-left');
      }
      clone.addClass('ldse-open ldse-absolute').attr('id', 'ldse-ice-menu-clone').click(function (event) {
        event.preventDefault();
        event.stopPropagation();
        closeOpenItems();
      }).appendTo('body').offset(offset);
      clone.find('ul.ldse-menu').click(function (e) {
        e.stopPropagation();
      });
      //$('.ldse-ice-menu-container.ldse-open').not(parent).removeClass('ldse-open');
      event.stopPropagation();
      event.preventDefault();
      return false;
    });
    //&& $(!'.workflow-table').hasClass('active')
    if (ajax) {
      $(controls).removeClass('ajax');
    }
    ICE.markItem();
  }


  function hideIce() {
/*		$("html").removeAttr("id");*/
    $("body").removeClass("ice");
    if ( getCookie("iceComps") == 'on' ) {
            $('body').find('ice-div:not(.ice-component)').hide();
            showComps();
/*            var components = $('body').find('ice-div.ice-component');
            components.parent().show();*/
    } else {
            $('body').find('ice-div:not(.ice-component)').hide();
    }
    $("body").find('a.edit-resource').attr("style", "display:none !important;");
        setCookie('ice', 'off', 30);
    $('.resourceIce.html5editable').removeAttr("contenteditable");
  }

  function showIce() {
/*		$("html").attr("id", "ldse-show-ice");*/
    $("body").addClass("ice");
        $('body').find('ice-div:not(.ice-component)').show();
        setCookie('ice', 'on', 30);
    $("body").find('a.edit-resource').attr("style", "display:inline !important;");
    $('.resourceIce.html5editable').attr("contenteditable", "true");
    fixOverlappingIceMenus();
  }

  function hideComps() {
/*		$("html").removeAttr("id");*/
    $("body").removeClass("iceComps");
        setCookie('iceComps', 'off', 30);
        if ( !$('body').hasClass('ice') ) {
            $('body').find('ice-div').hide();
        } else {
             var components = $('body').find('ice-div.ice-component');
             components.hide();
        }
  }

  function showComps() {
/*		$("html").attr("id", "ldse-show-ice");*/
    $("body").addClass("iceComps");
    var components = $('body').find('ice-div.ice-component');
    components.show();
        setCookie('iceComps', 'on', 30);
/*        if ( !$('body').hasClass('ice') ) {
            components.parent().show();
        }*/
    fixOverlappingIceMenus();
  }

/* Hover to know what ice item goes with what content piece */
function iceHover() {
    $("ice-div .ldse-ice-menu-container a").hover(
      function(){
        var id = $(this).attr('data-target')
        $('[data-gear=' + id + ']').css('background-color','#00BAD3')
      },
      function(){
        var id=$(this).attr('data-target');
        $('[data-gear=' + id + ']').css('background-color','')
        }
    );
    $("ice-div").each(function(){
      var id = guid();
      $(this).find('a').attr('data-target', id)
      $(this).parent().attr('data-gear', id);
    });
};

function guid() {
    function s4() {
        return Math.floor((1 + Math.random()) * 0x10000)
            .toString(16).substring(1);
    }
    return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
        s4() + '-' + s4() + s4() + s4();
};
  function permalink_validate() {
    "use strict";
    var locale = $('#locale').val();
    var fullUrl = $("#fullUri").val();
    var validateUrl = $("#permalink").val();
    var isValid = false;
    $.ajax({
      url: validateUrl + '&url=' + fullUrl,
      success: function (result) {
        var delim = result.indexOf("\n");
        var valid = result
        if (delim !== -1) {
          valid = result.substring(0, delim);
        }

        if (valid === 'true') {
          jQuery("#fullUri").closest('dl').removeClass('error');
          isValid = true;
        }
        if (isValid === false) {
          jQuery("#fullUri").closest('dl').addClass('error');
          //.append("<span class='error'>Unavailable</span>");
        }
      },
      async: false,
      dataType: 'text'
    });
    return isValid;
  }

  // RICE
  var RICE = {
    HIDDEN_RESOURCES:[],
    // Populated by each page
    CURRENT_URI: '',
    // Populated by each page
    HIDE_TITLE: false,
    SEO_TITLE: '',
    onChange: function () {
      var anyEmptyValue = false;
      $(".rice-text").each(function () {
        var hasEmptyValue = ! this.value || this.value === '';
        var hasErrorText = $(this).parent().children('span.error').length > 0;

        // Add or remove the error text
        if (hasEmptyValue) {
          if (! hasErrorText) {
            $(this).parent().append("<span class='error'>Required</span>");
          }
        } else {
          if (hasErrorText) {
            $(this).parent().children('span.error').remove();
          }
        }
        anyEmptyValue = anyEmptyValue || hasEmptyValue;
      });
      if (anyEmptyValue) {
        $('#saveResource').attr('disabled', 'disabled');
      } else {
        $('#saveResource').removeAttr('disabled');
      }
    },
    editResource: function (lang, bundle, key) {
      var currentPage = decodeURIComponent(document.location.pathname);
      var path = sharedPrefix + '/shared/lds-edit/ice/resources/ajax/resource/editResourceForm?lang=eng';

      if ($('.ldseForm').length > 0) {
        $('.ldseForm').remove();
      }
      $('<div class="ldseForm"></div>').appendTo('body');
      $.ajax({
        type: "POST",
        url: path,
        data: {
          "locale": lang, "bundle": bundle, "key": key, "currentPage": currentPage, "uri": RICE.CURRENT_URI
        },
        success: function (html) {
          $('.ldseForm').html(html).append(
          $('<link rel="stylesheet" media="screen" type="text/css" href="' + sharedPrefix + '/shared/lds-edit/ice/resources/styles/screen.css"/>')).dialog({

            dialogClass: "ldseForm ldse-modal",
            maxHeight: windowHeight(),
            width: '90%',
            zIndex: 4000,
            draggable: true,
            modal: true,
            title: 'Resource Editing',
            close: function () {
              $('.ldseForm').remove().dialog("close");
            }
          });
        }
      });
    },
    editHiddenResources: function (lang) {
      if (RICE.HIDDEN_RESOURCES.resources) {
        var bundles =[];
        var keys =[];
        $.each(RICE.HIDDEN_RESOURCES.resources.resource, function (key, value) {
          bundles.push(escape(value.bundle));
          keys.push(escape(value.key));
        });
        var currentPage = decodeURIComponent(document.location.pathname);
        var path = sharedPrefix + '/shared/lds-edit/ice/resources/ajax/resource/editResourceForm?lang=eng';
        if ($('.ldseForm').length > 0) {
          $('.ldseForm').remove();
        }
        $('<div class="ldseForm"></div>').appendTo('body');
        $.ajax({
          type: "POST",
          url: path,
          data: {
            "locale": lang, "bundle": bundles.join(","), "key": keys.join(","), "currentPage": currentPage, "uri": RICE.CURRENT_URI, "hideTitle": RICE.HIDE_TITLE, "seoTitle": RICE.SEO_TITLE
          },
          success: function (html) {
            $('.ldseForm').html(html).append(
            $('<link rel="stylesheet" media="screen" type="text/css" href="' + sharedPrefix + '/shared/lds-edit/ice/resources/styles/screen.css"/>')).dialog({

              dialogClass: "ldseForm ldse-modal",
              height: windowHeight(),
              maxHeight: windowHeight(),
              maxWidth: 1000,
              width: '90%',
              zIndex: 4000,
              draggable: true,
              title: 'Resource Editing',
              modal: true,
              close: function () {
                $('.ldseForm').remove().dialog("close");
              }
            });
            $(".ldse-show-seoT-info").click(function () {
              $(".ldse-infoT-text").toggle();
            });
            $(".ldse-show-seoD-info").click(function () {
              $(".ldse-infoD-text").toggle();
            });
            var seoTitle = {},
                seoUrl = $("form").find('table.iceEditor tr td textarea')[0],
                     seoDesc = $("form").find('table.iceEditor tr td textarea')[0],
                     titleCount = "",
                     descCount = "";
            if ( RICE.HIDE_TITLE !== 'true' ) {
                       seoTitle = $("form").find('table.iceEditor tr td input')[2],
                        titleCount = 70 - $(seoTitle).val().length,
                        descCount = 156 - $(seoDesc).val().length;
                $(".ldse-seo-title-message").append("Title display in search engines is limited to 70 chars, <span class='ldse-seo-title-number'>" + titleCount + "</span> chars left.");
                if (titleCount >= 0) {
                  $(".ldse-seo-title-number").css("color", "green");
                } else {
                  $(".ldse-seo-title-number").css("color", "red");
                }
                $(".ldse-seo-title").append($(seoTitle).val().substring(0, 70));
            } else {
                            $(".ldse-seo-title-message").append("This field is read only for this page.");
            }
            $(".ldse-seo-desc-message").append("The meta description will be limited to 156 chars, <span class='ldse-seo-desc-number'>" + descCount + "</span> chars left.");
            if (descCount >= 0) {
              $(".ldse-seo-desc-number").css("color", "green");
            } else {
              $(".ldse-seo-desc-number").css("color", "red");
            }
            $(".ldse-seo-description").append($(seoDesc).val().substring(0, 156));
            $(seoTitle).on("keyup blur", function () {
              var newCount = 70 - $(seoTitle).val().length;
              $(".ldse-seo-title-number").text(newCount);
              if (newCount >= 0) {
                $(".ldse-seo-title-number").css("color", "green");
              } else {
                $(".ldse-seo-title-number").css("color", "red");
              }
              $(".ldse-seo-title").text($(seoTitle).val().substring(0, 70));
            });
            $(seoDesc).on("keyup blur", function () {
              var newCount = 156 - $(seoDesc).val().length;
              $(".ldse-seo-desc-number").text(newCount);
              if (newCount >= 0) {
                $(".ldse-seo-desc-number").css("color", "green");
              } else {
                $(".ldse-seo-desc-number").css("color", "red");
              }
              $(".ldse-seo-description").text($(seoDesc).val().substring(0, 156));
            });
          }
        });
      } else {
        alert('No hidden text on this page.');
      }
    }
  };

  iRICE = {
    delay: 600,//only fire save after an adequate delay
    time: "", //saves time pointer, so it can be cleared
    setup: function () {
      //add listeners to all html5 editable rice strings
      $("#ldse-show-ice").on("keyup", ".html5editable", function (e) {
        clearTimeout(iRICE.time);
        var $this = $(this)

        var saveFunction = function () {
          iRICE.save($this);
        }

        iRICE.time = setTimeout(saveFunction, iRICE.delay);
        e.stopPropagation();
      });
      $(".html5editable").each(function () {
        //if parent is an a tag, we need to prevent it from linking out, but only when ice is enabled
        var $this = $(this);
        $this.click(function (e) {
          var src = $(e.target);
          if ($("html").attr("id") == "ldse-show-ice" && ! e.shiftKey) {
            e.preventDefault();
          } else if (src.is('a')) {
            window.location = src.attr('href');
            e.preventDefault();
          } else {
            var a = $this.closest('a');
            if (a.length > 0) {
              window.location = a.attr('href');
              e.preventDefault();
            }
          }
        });
      });
    },
    save: function ($this) {
      //on keypress save the new value up to the server
      var newValue = $this.text()
      $.ajax({
        type: "POST",
        url: "/shared/lds-edit/ice/resources/ajax/resource/updateInlineResource",
        dataType: "json",
        data: {
          lang: $this.data("lang"),
          locale: $this.data("locale"),
          country: $this.data("country"),
          currentPage: $this.data("currentPage"),
          currentUri: $this.data("currentUri"),
          bundle: $this.data("bundle"),
          key: $this.data("key"),
          newValue: $this.html()
        },
        success: function (data, status, request) {
          if (data.data === 'success') {
            //find and update any other strings that match locale bundle and
            $("span[data-locale = '" + $this.data("locale") + "'][data-bundle= '" + $this.data("bundle") + "'][data-key= '" + $this.data("key") + "']").not($this).text(newValue);
          } else {
            alert(data.message);
          }
        },
        error: function (request, status, error) {
          //need better api for saving, with messages.
          //no rights, failed save, emtpy text...
          alert("There was an error updating the resource. Refresh the page and try again.")
        }
      });
    }
  }
  $(function () {
    iRICE.setup();
  });

  // Lang/Locale
  function getUrlParams() {
    var vars =[],
    hash;
    var url = window.location.href;
    url = url.split('#')[0];
    var hashes = url.slice(url.indexOf('?') + 1).split('&');
    for (var i = 0; i < hashes.length; i++) {
      hash = hashes[i].split('=');
      if (hash.length > 0) {
        vars.push(hash[0]);
        vars[hash[0]] = hash[1];
      }
    }
    return vars;
  }

  function getLocaleFromParams() {
    var urlParams = getUrlParams();
    var params = '';
    if (urlParams.country !== '' && urlParams.country !== undefined) {
      params = urlParams.lang + '&country=' + urlParams.country;
    } else {
      params = urlParams.lang;
    }
    return params;
  }


  function splitLocale(locale) {
    if (locale != undefined) {
      var split = locale.split('-');
      var lang = '';
      if (split.length > 1) {
        lang = split[0] + '&country=' + split[1];
      } else {
        lang = locale;
      }
      return lang;
    } else {
      return lang;
    }
  }

  function getLang(locale) {
    var split = locale.split('-');
    var lang = '';
    if (split.length > 1) {
      lang = split[0];
    } else {
      lang = locale;
    }
    return lang;
  }

  function getCountry(locale) {
    var split = locale.split('-');
    var country = '';
    if (split.length > 1) {
      country = split[1];
    } else {
      country = '';
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
    $('input.dynamicInput').each(function () {
      if ($(this).val() === "") {
        $(this).val(" ");
      }
    });
  }

  function getCurrentPage() {
    return decodeURIComponent(window.location.pathname);
  }

  function windowHeight() {
    if (navigator.appName.indexOf("Microsoft") != -1) {
      return document.documentElement.clientHeight - 150;
    } else {
      return window.innerHeight - 200;
    }
  }

  // New Window plugin
  (function (jQuery) {
    jQuery.extend(jQuery, {
      defined: function (value) {
        return (typeof (value) !== typeof (undefined));
      },
      empty: function (value) {
        return ! jQuery.defined(value) || value === null || (typeof (value) === "string" && value === "");
      },
      getPath: function (url) {
        return url ? jQuery('<a/>').attr('href', url)[0].pathname.replace(/^[^\/]/, '/'): '';
      },
      urlVars:[],
      getUrlVars: function () {
        if ($.urlVars.length == 0) {
          var hashes = window.location.search.substr(1).split('&');
          for (var i = 0; i < hashes.length; i++) {
            hash = hashes[i].split('=');
            $.urlVars.push(hash[0]);
            $.urlVars[hash[0]] = hash[1];
          }
        }
        return $.urlVars
      },
      getUrlVar: function (name) {
        return $.getUrlVars()[name];
      },
      newWindow: function (url, options) {
        options = options || {
        };
        var name = options.name || "_blank";
        var w = window.open(url, name);
        if (window.focus) {
          w.focus();
        }
        return w;
      }
    });
  })(jQuery);

  var ACT = {
    ACTIONS: {
    },
    TRIES: {
    },
    ITEMS: {
    },
    //Holds standard items used from the TYPE property
    DYNAMIC_ITEMS: {
    },
    //Hold all dynamic items.
    CLEAR_URLS:[],
    RELOAD: "",
    TYPE: {
      customPage: {
        name: 'Custom Page (page.xml)',
        folder: 'customPage',
        id: 'staticCustomPage',
        ids:[]
      },
      rewriteRule: {
        name: 'Rewrite Rule',
        folder: 'rewriteRule',
        id: 'staticRewriteRule',
        ids:[]
      },
      resource: {
        name: 'Resources',
        folder: 'resource',
        id: 'staticResource',
        ids:[]
      },
      navigation: {
        name: 'Navigation',
        folder: 'navigation',
        id: 'staticNavigation',
        ids:[]
      },
      jericho: {
        name: 'Jericho Menu',
        folder: 'jericho',
        id: 'staticJericho',
        ids:[]
      },
      cache: {
        name: 'Clear Cache',
        folder: 'cache',
        id: 'staticCache',
        ids:[]
      },
      translation: {
        name: 'Translation',
        folder: 'translation',
        id: 'staticTranslation',
        ids:[]
      }
    },
    IS_TEMPLATE: false,
    MODAL_TITLE: 'Publishing',
    IMAGE: {
      PUBLISHING: ('ldse-publish-dialog ui-finder-loader'),
      SUCCESS: ('ldse-publish-dialog ldse-icon-check2'),
      ERROR: ('ldse-publish-dialog ldse-icon-ko-warning')
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
      if (! ACT.ITEMS.hasOwnProperty(item) && ACT.TYPE.hasOwnProperty(item)) {
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
      if (! $.isArray(ids)) {
        ids =[ids];
      }
      if (ACT.DYNAMIC_ITEMS.hasOwnProperty(id)) {
                $.each(ACT.DYNAMIC_ITEMS[id].ids, function (index, item) {
                    if ( ACT.DYNAMIC_ITEMS[id].ids.indexOf(item) == -1 ) {
                        ACT.DYNAMIC_ITEMS[id].ids.push(item);
                    }
                });
      } else {
        ACT.DYNAMIC_ITEMS[id] = {
          name: name,
          folder: "dynamic-item",
          id: id,
          ids: ids
        };
      }
    },
    getDynamicItems: function () {
      "use strict";
      var items =[];
      for (var key in ACT.DYNAMIC_ITEMS) {
        if (ACT.DYNAMIC_ITEMS.hasOwnProperty(key)) {
          items.push(ACT.DYNAMIC_ITEMS[key]);
        }
      }
      return items;
    },
    getItems: function () {
      "use strict";
      var items =[];
      for (var key in ACT.ITEMS) {
        if (ACT.ITEMS.hasOwnProperty(key)) {
          items.push(ACT.ITEMS[key]);
        }
      }
      return items;
    },
    getItem: function (response) {
      "use strict";
      var ids =[];
      if (response.ids && response.ids !== "") {
        ids = response.ids.split(',');
      }
      return {
        name: response.name,
        folder: response.folder,
        id: response.id,
        ids: ids,
        status: response.status
      };
    },
    buildModal: function (items) {
      "use strict";
      ACT.TRIES = {
      };
      var div = $('<div class="actionModal ldseForm"><link rel="stylesheet" media="screen" type="text/css" href="' + sharedPrefix + '/shared/lds-edit/ice/resources/styles/screen.css"/></div>');
      for (var i = 0; i < items.length; i++) {
        var item = items[i];
        if (item) {
          div.append(
          $('<div class="ldse-clearfix">' +
          '<div class="actionLabel">' + item.name + ': </div>' +
          '<div id="image_' + item.id + '" class="actionImage">' +
          '<span class="ui-finder-loader">&nbsp;</span><div id="status_' + item.id + '" class="actionStatus"/>' +
          '</div>' +
          '</div>' +
          '</div>'));
        }
      }
      // Close button
      div.append(
      $('<div class="actionClose">').append(
      $('<button id="" class="ldse-button">Close</button>').click(function () {
        $('.actionItems').remove().dialog("close");
        if (ICE.teaserManagerActive === false) {
          if (ACT.RELOAD !== "") {
            location = ACT.RELOAD;
          } else {
            location.reload();
          }
        } else {
          $('.actionModal').remove().dialog("close");
        }
      })));
      $('.actionModal').remove().dialog("close");
      div.dialog({
        position:[($(window).width() / 2) - (500 / 2), 150],
        dialogClass: "ldseForm ldse-modal",
        height: 'auto',
        width: 500,
        zIndex: 4000,
        draggable: true,
        modal: true,
        title: ACT.MODAL_TITLE,
        close: function () {
          $('.actionModal').remove().dialog("close");
        }
      });
    },
    page: function (action, uri, locale) {
      "use strict";
      if (ACT.IS_TEMPLATE) {
        ACT.addItems([ "customPage", "rewriteRule", "resource"]);
      }
      // Items to ACT on
      var items = ACT.getItems().concat(ACT.getDynamicItems());
      if (items.length === 0) {
        items =[ACT.TYPE.customPage, ACT.TYPE.rewriteRule, ACT.TYPE.resource];
      }
      if (action === "ldse:delete" && window.location.pathname.indexOf("shared/lds-edit") == -1) {
        if (sharedPrefix !== "") {
          ACT.RELOAD = sharedPrefix + "?" + ICE.langParam(locale);
        } else {
          ACT.RELOAD = "/";
        }
      }
      items.push(ACT.TYPE.cache);

      ACT.checkForCorrelationNotApproved(action, uri, locale, items);
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

      var $div = $('<div class="correlationModal ldseForm">' +
      '<link rel="stylesheet" media="screen" type="text/css" href="' + sharedPrefix + '/shared/lds-edit/ice/resources/styles/screen.css"/>' +
      '</div>');

      var titleList =[];
      $(".correlation-not-approved").each(function () {
        titleList.push($(this).attr("data-correlation-document-title"));
      })
      titleList = titleList.join("<br/><br/>");

      $div.append(
      $('<div class="ldse-clearfix" style="margin:10px;">' +
      '<span>There are one or more items on this page that are not approved for publishing and will not be published. <br/><br/> Do you wish to continue?</span><br/><hr/>' +
      '<div style="overflow:auto;height:100px;">' +
      titleList +
      '</div>' +
      '</div>'));

      var $divButtons = $('<div class="correlationModalButtons"><br/></div>');

      // No button
      $divButtons.append(
      $('<div class="correlationModalClose" style="float:right; margin-left">').append(
      $('<button id="" class="ldse-button">No</button>').click(function () {
        $('.correlationModal').remove().dialog('close');
      })));

      // Yes button
      $divButtons.append(
      $('<div class="correlationModalOK" style="float:right;">').append(
      $('<button id="" class="ldse-button">Yes</button>').click(function () {
        ACT.continueAction(ACT.correlationAction, ACT.correlationUri, ACT.correlationLocale, ACT.correlationItems);
        $('.correlationModal').remove().dialog('close');
      })));

      $div.append($divButtons);

      $('.correlationModal').remove().dialog("close");

      $div.dialog({
        position:[($(window).width() / 2) - (500 / 2), 150],
        dialogClass: "ldseForm ldse-modal",
        height: 'auto',
        width: 500,
        zIndex: 4000,
        draggable: true,
        modal: true,
        title: "Cor-IP / Cor-Eval",
        close: function () {
          $('.correlationModal').remove().dialog("close");
        }
      });
    },

    continueAction: function (action, uri, locale, items) {
      ACT.preformAction(action, uri, locale, items);
    },
    item: function (action, uri, locale, name, id) {
      "use strict";
      var ID = name.replace(/[^a-zA-Z]+/g, "_");
      var items =[ {
        name: name,
        folder: "dynamic-item",
        id: ID,
        ids:[id]
      }];
      if (ACT.IS_TEMPLATE && action === "ldse:publish") {
        items.push(ACT.TYPE.customPage);
        items.push(ACT.TYPE.rewriteRule);
      }
      items.push(ACT.TYPE.cache);
      ACT.preformAction(action, uri, locale, items);
    },
    publishNav: function (uri, locale, navName) {
      "use strict";
      ACT.TYPE.navigation.ids =[navName];
      var items =[ACT.TYPE.navigation, ACT.TYPE.cache];
      ACT.preformAction('ldse:publish', uri, locale, items);
    },
    publishJericho: function (uri, locale) {
      "use strict";
      var items =[ACT.TYPE.jericho, ACT.TYPE.cache];
      ACT.preformAction('ldse:publish', uri, locale, items);
    },
    publishMeta: function (uri, locale) {
      "use strict";
      var items =[ACT.TYPE.customPage, ACT.TYPE.rewriteRule, ACT.TYPE.resource];
      ACT.preformAction('ldse:publish', uri, locale, items);
    },
    publishResources: function (locale) {
      "use strict";
      var items =[ACT.TYPE.resource];
      ACT.preformAction('ldse:publish', '/', locale, items);
    },
    translation: function (status, action, uri, locale, id, button) {
      "use strict";
      ACT.TYPE.translation.ids =[id];
      ACT.TYPE.translation.title = $(button).text();
      ACT.TYPE.translation.status = status;
      var items =[ACT.TYPE.translation];
      ACT.preformAction(action, uri, locale, items);
    },
    preformAction: function (action, uri, locale, items) {
      "use strict";
      function complete() {
        ACT.MODAL_TITLE = items[0].title || ACT.ACTIONS[action];
        ACT.buildModal(items);
        for (var i = 0; i < items.length; i++) {
          var item = items[i];
          if (item) {
            ACT.ajaxAction(action, uri, locale, item);
          }
        }
      }
      if (action.indexOf('delete') != -1) {
        var options = {
          okText: "Delete",
          okClass: "destructive ldse-icon-trash"
        };
        ICE.alertText("Warning", "Are you sure you want to delete?", complete, options);
      } else if (action.indexOf('remove') != -1) {
        var options = {
          okText: "Remove",
          okClass: "destructive ldse-icon-ko-remove"
        };
        ICE.alertText("Warning", "Are you sure you want to remove?", complete, options);
      } else {
        complete();
      }
    },
    ajaxAction: function (action, uri, locale, item) {
      "use strict";
      if (item.folder === "cache") {
        ACT.submitClearCache(action, uri, locale, item);
      } else if (item.folder === "translation") {
        ACT.submitTranslation(action, uri, locale, item);
      } else {
        var url = sharedPrefix + '/shared/lds-edit/ice/resources/ajax/' + item.folder + '/action?lang=eng';
        var data = {
          action: action,
          uri: uri,
          locale: locale
        };
        data = $.extend(data, item);
        $.ajax({
          type: "POST",
          url: url,
          dataType: 'json',
          cache: false,
          data: data,
          success: ACT.ajaxComplete,
          error: function () {
            var json = {
              response: data
            };
            json.response.success = false;
            json.response.error = "500";
            json.response.ids = json.response.ids.join(',');
            ACT.ajaxComplete(json);
          }
        });
      }
    },
    retryViaAjax: function (action, uri, locale, item) {
      "use strict";
      $('#image_' + item.id + ' > span').attr('class', ACT.IMAGE.ACTING);
      $('#status_' + item.id).html('');
      ACT.ajaxAction(action, uri, locale, item);
    },
    ajaxComplete: function (data) {
      "use strict";
      if (data && data.response) {
        var message = "",
        image = "",
        action = data.response.action,
        uri = data.response.uri,
        locale = data.response.locale,
        item = ACT.getItem(data.response),
        success = data.response.success || "false",
        error = data.response.error || "",
        count = data.response.count || 0,
        tries = ACT.TRIES[item.id];
        var retry = function () {
          ACT.retryViaAjax(action, uri, locale, item);
          return false;
        };
        if (success === "true") {
          if (data.response.hasOwnProperty('message')) {
            message = data.response.message;
          } else {
            message = 'Action Completed <b>' + count + '</b> item(s)';
          }
          image = ACT.IMAGE.SUCCESS;
        } else if (! tries || tries < 3) {
          tries = (tries ? tries + 1: 1);
          ACT.TRIES[item.id] = tries;
          message = 'Action Failed...retrying...attempt: ' + tries;
          image = ACT.IMAGE.ACTING;
          setTimeout(retry, 3000);
        } else {
          ACT.TRIES[data.response.type] = null;
          message = 'Action failed (<a href="#d">Retry</a>)';
          image = ACT.IMAGE.ERROR;
        }
        $('#status_' + item.id).html(message);
        $('#status_' + item.id + ' a').click(function (e) {
          e.preventDefault();
          retry();
          return false;
        });
        $('#image_' + item.id + ' > span').attr('class', image);
      }
    },
    submitClearCache: function (action, uri, locale, item) {
      "use strict";
      var url = sharedPrefix + '/shared/lds-edit/clear-cache/clear-cache-post?lang=eng';
      var locationObj = window.location;
      var browserUrl = locationObj.pathname + locationObj.search + locationObj.hash;
      var uris = encodeURIComponent(browserUrl) + '**' + encodeURIComponent(browserUrl);
      var json = {
        response: {
          action: action,
          uri: uri,
          locale: locale,
          success: "",
          error: "",
          name: item.name,
          folder: item.folder,
          id: item.id,
          ids: item.ids.join(',')
        }
      };
      if (decodeURIComponent(window.location.pathname) !== uri && typeof uri !== 'undefined' && uri !== 'undefined') {
        uris += '**' + uri;
      }
      $.each(ACT.CLEAR_URLS, function (index, value) {
        uris += '**' + encodeURIComponent(value);
      });
      $.ajax({
        type: "POST",
        url: url,
        data: {
          lang: 'eng',
          locale: locale,
          uris: uris
        },
        cache: false,
        success: function () {
          json.response.success = 'true';
          json.response.message = 'Successfully submitted request.';
          ACT.ajaxComplete(json);
        },
        error: function () {
          json.response.success = 'false';
          json.response.error = 'error';
          ACT.ajaxComplete(json);
        }
      });
    },
    addClearUrl: function (url) {
      "use strict";
      if (! $.isArray(url)) {
        url =[url];
      }
      $.each(url, function (index, value) {
        if ($.inArray(value, ACT.CLEAR_URLS) == -1) {
          ACT.CLEAR_URLS.push(value);
        }
      });
    }
  };
  $(document).ajaxSend(function (event, request, settings) {
    if (settings.type != "HEAD" && settings.url.indexOf('/shared/lds-edit/') == -1 && settings.url.indexOf('.css') == -1 && settings.url.indexOf('.js') == -1) {
      ACT.addClearUrl(settings.url);
    }
  });
}
