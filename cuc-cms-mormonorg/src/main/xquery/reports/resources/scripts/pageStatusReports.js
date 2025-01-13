Array.prototype.clean = function(deleteValue) {
    for (var i = 0; i < this.length; i++) {
        if (this[i] === deleteValue) {
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
    appliedFilters : {},
    currentFilters : {},
    emptyFilters : {
        siteLangs: []
    },
    elements:{
        infoDiv : $('#details'),
        filterBody : $("#filter-body"),
        siteLangSelect : $("#siteLangFilterBox > div > select"),
        paramList : $("#paramList")
    },

    setup : function(){
        SM.appliedFilters = $.extend({}, SM.emptyFilters);
        SM.currentFilters = $.extend({}, SM.emptyFilters);
        SM.applyFilters();
        SM.addListeners();
        SM.elements.paramList.show();
    },

    addListeners : function(){
        var updateFunction = function(){
            clearTimeout(SM.timeOut);
            SM.timeOut = setTimeout(SM.updateCurrentFilters,50);
        };

        SM.elements.filterBody.keyup(updateFunction).change(updateFunction);
        SM.elements.siteLangSelect.data().multiSelect.options.onDelete = updateFunction;

        $('.filters header a').click(function(){
            var filter = $(this).closest('.filters');
            if (filter.hasClass('ldse-open')) {
                SM.closeFilter(filter);
            }
        });
        $(".remover").click(function(){
            $(this).find("input:text").val("");
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
        if(!(sessionStorage.getItem('filters') === null))
        {
            SM.appliedFilters = JSON.parse(sessionStorage.getItem('filters'));
            SM.currentFilters = JSON.parse(sessionStorage.getItem('filters'));

            var siteLangSelect = $("#siteLangFilterBox select").first();
            var siteLangOptions = siteLangSelect.data().multiSelect.options;
            siteLangSelect.children().removeAttr("selected").end().val(
                SM.appliedFilters.siteLangs || []).multiSelect("destroy").multiSelect(
                siteLangOptions);
            if(SM.appliedFilters.siteLangs.length > 0)
            {
                $("#siteLangFilter > a").click();
            }

            sessionStorage.removeItem('filters');
        }
        else
        {
            SM.appliedFilters = $.extend({},SM.currentFilters);
        }

        var filterEqual =(JSON.stringify(SM.appliedFilters) === JSON.stringify(SM.emptyFilters));
    },

    updateCurrentFilters : function(){
        var siteLangInput = SM.elements.siteLangSelect.val();
        SM.currentFilters.siteLangs = (siteLangInput != null ? siteLangInput.clean(""):[]);
        SM.compareFilters();
    },

    compareFilters : function(){
        var filterEqual =(JSON.stringify(SM.currentFilters) === JSON.stringify(SM.appliedFilters));
    },

    closeFilter:function(filter) {
        filter.find('input').val('');
        if(filter.find("select").hasClass("multiselect"))
        {
            var select = filter.find('select').first();
            SM.updateMultiselect(select, []);
        }
        SM.updateCurrentFilters();
    },

    updateMultiselect:function(select, value){
        var options = select.data().multiSelect.options;
        var currVal = value || [];
        select.children().removeAttr("selected").end().val(currVal).multiSelect("destroy").multiSelect(options);
        if(currVal.length !== 0)
        {
            select.closest(".filters:not(.ldse-open)").find("header a").click();
        }
        SM.updateCurrentFilters();
    },

    updatePageStatusExportType : function(){
        SM.exportType = "xml";
    },

    pageStatusReportExport : function(){
        if (SM.currentFilters.siteLangs.length !== 0) {
            LDSE.post(sharedPrefix + "/reports/ajax/page-status-report-export", {
                "siteLangs[]": SM.currentFilters.siteLangs,
                "export_type": SM.exportType
            });
        }
    },

    siteInventoryReportExport : function(){
        if (SM.currentFilters.siteLangs.length !== 0) {
            LDSE.post(sharedPrefix + "/reports/ajax/site-inventory-report-export", {
                "siteLangs[]": SM.currentFilters.siteLangs,
                "export_type": SM.exportType
            });
        }
    }

}//end of SM object
$.ajaxSetup({
    beforeSend : SM.showLoading,
    complete : SM.clearLoading
});
