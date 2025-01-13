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
    bundles : [],
    filteredBundles : [],
    appliedFilters : {},
    currentFilters : {},
    emptyFilters : {
        bundleName : [],
        searchstring : ""
    },
    toSite: '',
    checkedBundles : [],
    page : 1,
    maxPage : 1,
    pageLength : 25,
    timeOut : 0,
    elements:{
        infoDiv : $('#details'),
        bundletable : $('#detail-table-body'),
        nextArrow : $('#details-Next'),/*arrow link right*/
        prevArrow : $('#details-Previous'),/*arrow link left*/
        currentPage : $('#details-CurrentPage'),/*current pagination span*/
        maxPage : $('#details-MaxPage'),/*total pagination span*/
        filterBody : $("#filter-body"),
        toSiteSelect : $("#toSiteFilterBox > div > select"),
        applyButton : $("#applyFilterBtn"),
        cancelButton : $("#cancelFilterBtn"),
        clearButton : $("#clearFilterBtn"),
        searchString : $("#filter-search")
    },

    setup : function(){
        SM.appliedFilters = $.extend({}, SM.emptyFilters);
        SM.currentFilters = $.extend({}, SM.emptyFilters);
        SM.applyFilters();
        SM.renderPage();
        SM.addListeners();
    },

    addListeners : function(){
        var updateFunction = function(){
            clearTimeout(SM.timeOut);
            SM.timeOut = setTimeout(SM.updateCurrentFilters,50);
        };

        SM.elements.filterBody.keyup(updateFunction).change(updateFunction);
        SM.elements.applyButton.click(function(e){
            e.preventDefault();
            e.stopPropagation();
            $(".bundleSelect:checked").each(function(){
                $(this).prop("checked", false);
            });
            $(".ldse-table-buttons button").each(function(){
                $(this).hide();
            });
            SM.applyFilters();
            return false;
        });

        $("#questionButton").click(function(){
            SM.showLoading();
            return $('#applyFilterBtn').trigger("click");
        });
        SM.elements.cancelButton.click(function(){
            SM.cancelFilters();
        });
        $('#filter-search').keypress(function(e){
            if (e.which == 13)
            {
                e.preventDefault();
                SM.showLoading();
                return $('#applyFilterBtn').trigger("click");
            }
        });
        $(".bundleName").keypress(function(e){
            if (e.which == 13)
            {
                e.preventDefault();
                return $('#applyFilterBtn').trigger("click");
            }
        });

        SM.elements.clearButton.click(function(){
            SM.clearFilters();
            $("#clearFilterBtn").hide();
        });
        $('.filters header a').click(function(){
            var filter = $(this).closest('.filters');
            if (filter.hasClass('ldse-open')) {
                SM.closeFilter(filter);
            }
        });
        $(".remover").click(function(){
            $(this).find("input:text").val("");
            SM.elements.applyButton.show();
            SM.elements.cancelButton.hide();
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
            $("#filter-search").val(SM.appliedFilters.searchstring);
            SM.setInputFields($("#bundleNameBox"), SM.appliedFilters.bundleName);
            if(SM.appliedFilters.bundleName.length>0)
            {
                $("#bundleName > a").click();
            }

            sessionStorage.removeItem('filters');
        }
        else
        {
            SM.appliedFilters = $.extend({},SM.currentFilters);
        }

        if(!(sessionStorage.getItem('sortDirection') === null) && !(sessionStorage.getItem('sortColumn') === null))
        {
            if(sessionStorage['sortDirection']=="true")
            {
                var colName=sessionStorage['sortColumn'];
                sessionStorage.removeItem('sortDirection');
                sessionStorage.removeItem('sortColumn');
                $(".sortColumns th.sortable[data-name = "+colName+"] a").click().click();
            }
            else
            {
                var colName=sessionStorage['sortColumn'];
                sessionStorage.removeItem('sortDirection');
                sessionStorage.removeItem('sortColumn');
                $(".sortColumns th.sortable[data-name = '"+colName+"'] a").click();
            }
        }
        SM.filterBySearch(SM.appliedFilters.searchstring);
        SM.filteredBundles = SM.bundles.filter(SM.hasFilter).sort(SM.hasSort);
        SM.updateMaxPage();
        SM.changePage(1);
        SM.renderPage();
        SM.elements.applyButton.hide();
        SM.elements.cancelButton.hide();
        var filterEqual =(JSON.stringify(SM.appliedFilters) === JSON.stringify(SM.emptyFilters));
        if(!filterEqual)
        {
            SM.elements.clearButton.show();
        }
        else
        {
            SM.elements.clearButton.hide();
        }
    },

    setInputFields : function(filterBox, values) {
        var filterAddBtn = filterBox.find(".ldse-adder");
        var filterInputs = filterBox.find("input");
        var difference = values.length - filterInputs.length;
        if (difference > 0) { // more values than inputs - so add fields
            for ( var i = 0; i < difference; i++) {
                filterAddBtn.click();
            }
        } else if (difference < 0) { // more inputs than values so remove
            // inputs
            var removeBtns = filterBox.find(".remover");
            for ( var i = filterInputs.length - 1; i >= values.length; i--) {
                $(removeBtns[i]).click();
            }
        }
        filterInputs = filterBox.find("input"); // find input fields again

        for ( var i = 0; i < filterInputs.length; i++) {// set values for
            // each input
            // used reverse index because input fields were being reset in
            // reverse order
            var reverseIndex = filterInputs.length - 1 - i;
            $(filterInputs[reverseIndex]).val(values[i]);
        }

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
    filterBySearch : function(text) {
        var site = SM.getParam('site');
        var lang = SM.getParam('lang');

        $.ajax({
            type:"post",
            async : false,
            url: sharedPrefix + "/ice/resources/ajax/clone-page/search?site="+site+"&lang="+lang+"&search="+text,
            beforeSend : function() {
                return true;
            },
            success:function(data) {
                SM.bundles = data;
            },
            error : function(x,y,z) {
                var hole = 0;
            }
        });
        SM.clearLoading();
    },

    updateCurrentFilters : function(){
        var nameInput = [];
        $(".bundleName").each(function(){
            nameInput.push($(this).val());
        });
        SM.currentFilters.bundleName = (nameInput != null ? nameInput.clean(""):[]);
        SM.currentFilters.searchstring = SM.elements.searchString.val();
        SM.compareFilters();
    },

    compareFilters : function(){
        var filterEqual =(JSON.stringify(SM.currentFilters) === JSON.stringify(SM.appliedFilters));
        if (!filterEqual)
        {
            SM.elements.applyButton.show();
            SM.elements.cancelButton.show();
        }
        else
        {
            SM.elements.applyButton.hide();
            SM.elements.cancelButton.hide();
        }
    },

    renderPage : function () {
        var start = (SM.page - 1) * SM.pageLength;
        var end = (SM.page * SM.pageLength);
        var data = { bundles : SM.filteredBundles };
        SM.updatePagination();
        SM.elements.currentPage.html(SM.page);
        SM.updateMaxPage();
        SM.elements.maxPage.html(SM.maxPage);
        SM.elements.bundletable.html(BundlePageTemplateForCloning(data));
        SM.changePage(1);
    },

    saveFilters : function(){
        sessionStorage.setItem('filters', JSON.stringify(SM.appliedFilters));
        sessionStorage['sortDirection'] = SM.sortDir;
        sessionStorage['sortColumn'] = SM.sortColumnName;
    },

    updateMaxPage : function() {
        SM.maxPage = Math.ceil( SM.filteredBundles.length / SM.pageLength);
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

    clearFilters : function(){
        SM.currentFilters = $.extend({}, SM.emptyFilters);
        SM.appliedFilters = $.extend({}, SM.emptyFilters);
        SM.applyFilters();
        $(".bundleName").val("");
        if($(".bundleName").length > 1)
        {
            $(".bundleName").closest("dl").find("a.remover").click();
        }
        SM.elements.searchString.val("");
        $("#bundleName").closest(".filters.ldse-open").find("header a").click();
        $(".sortColumns th.sortable").removeClass("sort asc desc");
        SM.elements.applyButton.hide();
        SM.elements.cancelButton.hide();
        sessionStorage.removeItem('filters');
        sessionStorage.removeItem('sortDirection');
        sessionStorage.removeItem('sortColumn');
    },

    closeFilter:function(filter) {
        filter.find('input').val('');
        if(filter.find("select").hasClass("multiselect"))
        {
            var select = filter.find('select').first();
            SM.updateMultiselect(select, []);
        }
        if ( $(filter).attr('id') === 'bundleNameBox' ) {
            if($(".bundleName").length > 1) {
                $(".bundleName").closest("dl").find("a.remover").click();
            }
        }
        SM.updateCurrentFilters();
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

        SM.elements.bundletable.find('tr').hide();
        SM.elements.bundletable.find('tr.page'+value).show();
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

    cancelFilters : function(){
        SM.currentFilters = $.extend({}, SM.appliedFilters);
        if((JSON.stringify(SM.currentFilters) === JSON.stringify(SM.emptyFilters)))
        {
            $("#filter-search").val("");
            $("#bundleNameBox.ldse-open").find("a").click();
            $("#toSiteFilterBox.ldse-open").find("a").click();
            SM.elements.applyButton.hide();
            SM.elements.cancelButton.hide();
            return;
        }
        SM.elements.applyButton.hide();
        SM.elements.cancelButton.hide();
        SM.elements.searchString.val(SM.currentFilters.searchstring);
        if(SM.currentFilters.bundleName.length>1)
        {
            while($(".bundleName").length < SM.currentFilters.bundleName.length)
            {
                $(".add-bundle-name:first").click();
            }
            while($(".bundleName").length > SM.currentFilters.bundleName.length)
            {
                $(".remove-bundles:last").click();
            }
            for(var i = 0; i < SM.currentFilters.bundleName.length; ++i)
            {
                curr = $(".bundleName")[i];
                curr.value = (SM.currentFilters.bundleName[i]);
            }
        }
        else if(SM.currentFilters.bundleName.length==1)
        {
            $(".bundleName").val(SM.currentFilters.bundleName)
        }
        else
        {
            $("#bundleName").closest("div.ldse-open").find("a").click();
        }

    },

    hasFilter : function (bundle){
        var hasName = false;
        var matchSearch = false;
        if(SM.appliedFilters.bundleName.length > 0)
        {
            for(var i=0; i<SM.appliedFilters.bundleName.length; ++i)
            {
                if (bundle.name.toLowerCase().indexOf(SM.appliedFilters.bundleName[i].toLowerCase())>-1)
                {
                    hasName = true;
                }
            }
        }
        else
        {
            hasName = true;
        }

        return (hasName)
    },

    hasSort : function(a, b){

        if(SM.sortColumnName == "name")
        {
            if((SM.sortDir && b.name.toLowerCase() > a.name.toLowerCase())||(!SM.sortDir && a.name.toLowerCase() > b.name.toLowerCase()))
            {
                return 1/*-1 is b before a*/
            }
            else if((SM.sortDir && a.name.toLowerCase() > b.name.toLowerCase())||(!SM.sortDir && b.name.toLowerCase() > a.name.toLowerCase()))
            {
                return -1;/*a before b*/
            }
            else
            {
                return 0; /*no sort*/
            }
        }
        if(SM.sortColumnName == "type")
        {
            if((SM.sortDir && b.type.toLowerCase() > a.type.toLowerCase())||(!SM.sortDir && a.type.toLowerCase() > b.type.toLowerCase()))
            {
                return 1/*-1 is b before a*/
            }
            else if((SM.sortDir && a.type.toLowerCase() > b.type.toLowerCase())||(!SM.sortDir && b.type.toLowerCase() > a.type.toLowerCase()))
            {
                return -1;/*a before b*/
            }
            else
            {
                return 0; /*no sort*/
            }
        }

        return 0;
    },

    sortColumn : function(column){
        var columnName = $(column).closest("th.sortable").attr("data-name");
        var th = $(column).closest("th");
        $(".sortColumns th.sortable").not(th).removeClass("sort asc desc");

        if( (!th.hasClass("desc") && !th.hasClass("asc")) )
        {
            th.addClass("sort desc")
            SM.sortDir = false;
            SM.sortColumnName = columnName;
        }
        else if(th.hasClass("desc"))
        {
            th.removeClass("desc").addClass("sort asc");
            SM.sortDir = true;
            SM.sortColumnName = columnName;
        }
        else if(th.hasClass("sort asc"))
        {
            th.removeClass("sort asc");
            SM.sortDir = false;
            SM.sortColumnName = "";
        }
        SM.applyFilters();
    },

    cloneContent : function(){
        var fromLang = SM.getParam('lang');
        var fromSite = SM.getParam('site');
        var resourcesPages = [];
        var contentTypes = [];
        var cloneToSite = "";

        $("input.bundleSelect:checked").each(function(){
            var bundle = $(this).closest('tr').data('bundle');
            resourcesPages.push(bundle.name);
            contentTypes.push(bundle.type);
        });

        cloneToSite = SM.elements.toSiteSelect.val()


        $.ajax({
            url : sharedPrefix + "/ice/resources/ajax/clone-page/clone-resources-and-pages",
            type : "POST",
            dataType: 'json',
            data : {'resourcesPages':resourcesPages,'fromSite':fromSite,
                    'fromLang':fromLang, 'contentTypes':contentTypes, 'cloneToSite':cloneToSite},
            success : function (data) {
                if (data.response == 'true') {
                    alert('The requested contents have been successfully cloned');
                } else {
                    alert(data.response);
                }
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
