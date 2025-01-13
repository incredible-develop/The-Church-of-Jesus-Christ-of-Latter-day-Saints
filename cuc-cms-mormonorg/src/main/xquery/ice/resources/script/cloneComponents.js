Array.prototype.clean = function(deleteValue) {
    for (var i = 0; i < this.length; i++) {
        if (this[i] == deleteValue) {
            this.splice(i, 1);
            i--;
        }
    }
    return this;
};

var modal = $('#modal1').trigger('close');

$(document).ready(function(){
    Handlebars.registerHelper('loop', function(context, options) {
        var fn = options.fn, inverse = options.inverse;
        var ret = "";

        if (context && context.length > 0) {
            for ( var i = 0, j = context.length; i < j; i++) {
                ret = ret + fn($.extend({}, context[i], {
                    i : i,
                    iPlus1 : i + 1
                }));
            }
        } else {
            ret = inverse(this);
        }
        return ret;
    });
    Handlebars.registerHelper('json', function(context) {
        return JSON.stringify(context);
    });
    Handlebars.registerHelper('page', function(context) {
        return Math.ceil(context.iPlus1 / SM.pageLength);
    });
    $(".handlebars-template").each(function() {
        window[$(this).attr('id')] = Handlebars.compile($(this).html());
    });
    SM.setup();
    $(".start-hidden").hide();
});

var SM = {
    exportType : "xml",
    components : [],
    toPage: '',
    page : 1,
    maxPage : 1,
    pageLength : 25,
    timeOut : 0,
    elements:{
        infoDiv : $('#details'),
        componentstable : $('#detail-table-body'),
        nextArrow : $('#details-Next'),/*arrow link right*/
        prevArrow : $('#details-Previous'),/*arrow link left*/
        currentPage : $('#details-CurrentPage'),/*current pagination span*/
        maxPage : $('#details-MaxPage'),/*total pagination span*/
        toPageSelect : $("#toPageFilterBox > div > select"),
        fromPageSelect : $("#fromPage"),
    },

    setup : function(){
        SM.applyFilters();
        SM.renderPage();
        SM.addListeners();
    },

    addListeners : function(){
        var updateFunction = function(){
            clearTimeout(SM.timeOut);
        };
        $('#fromPage').change(function(e){
            e.preventDefault();
            SM.showLoading();
            return SM.applyFilters();
        });
    },
    html : $('html'),
    showLoading : function() {
        SM.html.addClass('loading');
    },
    clearLoading : function() {
        SM.html.removeClass('loading');
    },

    applyFilters : function(){
        SM.loadComponents();
        $('#action-clone').hide();
        $('#action-clone-mult').hide();
        SM.updateMaxPage();
        SM.changePage(1);
        SM.renderPage();
    },

    getParam : function(sParam) {
        var sPageURL = decodeURIComponent(window.location.search.substring(1)),
            sURLVariables = sPageURL.split('&'),
            sParameterName,
            i;
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('=');
            if (sParameterName[0] === sParam) {
                return sParameterName[1] === undefined ? true : sParameterName[1];
            }
        }
    },
    loadComponents : function(text) {
        var site = SM.getParam('site');
        var lang = SM.getParam('lang');
        var uri = "";

        uri = SM.elements.fromPageSelect.val()

        $.ajax({
            type:"post",
            async : false,
            url: sharedPrefix + "/ice/resources/ajax/clone-page/load-components?site="+site+"&lang="+lang+"&uri="+uri,
            beforeSend : function() {
                return true;
            },
            success:function(data) {
                SM.components = data;
            },
            error : function(x,y,z) {
                var hole = 0;
            }
        });
        SM.clearLoading();
    },

    renderPage : function () {
        var start = (SM.page - 1) * SM.pageLength;
        var end = (SM.page * SM.pageLength);
        var data = { components : SM.components };
        SM.updatePagination();
        SM.elements.currentPage.html(SM.page);
        SM.updateMaxPage();
        SM.elements.maxPage.html(SM.maxPage);
        SM.elements.componentstable.html(buildComponentListForCloning(data));
        SM.changePage(1);
    },

    updateMaxPage : function() {
        SM.maxPage = Math.ceil( SM.components.length / SM.pageLength);
        SM.elements.maxPage.html(SM.maxPage);
    },

    updatePagination : function () {
        if (SM.page === SM.maxPage) {
            SM.elements.nextArrow.addClass('faded');
            SM.elements.nextArrow.addClass('disabled');
        } else {
            SM.elements.nextArrow.removeClass('faded');
        }
        if (SM.page === 1) {
            SM.elements.prevArrow.addClass('faded');
            SM.elements.prevArrow.addClass('disabled');
        } else {
            SM.elements.prevArrow.removeClass('faded');
        }
    },

    changePageSize : function (value) {
        if (SM.pageLength !== value) {
            SM.pageLength = value;
            SM.updatePageLink();
            SM.updateMaxPage();
            SM.changePage(1);
            SM.renderPage();
        }
    },

    updatePageLink : function() {
        var pageSizeElement = $("span.ldse-pagination--shownum a[data-count=" + SM.pageLength + "]")[0];
        $("span.ldse-pagination--shownum a").not("[href]").attr("href", "#d");
        $(pageSizeElement).removeAttr("href");
    },

    changePage : function (value) {
        $("#box-all").attr("checked", false);
        SM.page = value;
        SM.elements.currentPage.html(SM.page);

        SM.elements.componentstable.find('tr').hide();
        SM.elements.componentstable.find('tr.page'+value).show();
    },
    purgeArray : function (ar)
    {
        var obj = {};
        var temp = [];
        for(var i=0;i<ar.length;i++)
        {
            obj[ar[i]] = ar[i];
        }
        for (var item in obj)
        {
            temp.push(obj[item]);
        }
        return temp;
    },
    nextPage : function () {
        if (SM.page < SM.maxPage) {
            SM.changePage(SM.page + 1);
        }
    },

    previousPage : function () {
        if (SM.page > 1) {
            SM.changePage(SM.page - 1);
        }
    },

    cloneContent : function(){
        var language = SM.getParam('lang');
        var site = SM.getParam('site');
        var cloneToPage = "";
        var componentIds = [];

        $("input.bundleSelect:checked").each(function(){
            var bundle = $(this).closest('tr').data('bundle');
            componentIds.push(bundle.id);
        });
        cloneToPage = SM.elements.toPageSelect.val()
        $.ajax({
            url : sharedPrefix + "/ice/resources/ajax/clone-page/clone-selected-components",
            type : "POST",
            dataType: 'json',
            data : {'site':site,
                'language':language, 'componentIds':componentIds, 'cloneToPage':cloneToPage},
            success : function (data) {
                alert(data.response)
            },
            error : function(data) {
                alert('Unable to clone.');
            }
        });
    },

}

$.ajaxSetup({
    beforeSend : SM.showLoading,
    complete : SM.clearLoading
});
