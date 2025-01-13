"use strict";
Storage.prototype.setObject = function(key, value) {
	this.setItem(key, JSON.stringify(value));
}

Storage.prototype.getObject = function(key) {
	return JSON.parse(this.getItem(key));
}
var C = {
	/* ********************** constants ********************* */
	"ACTIONS" : [ "complete", "block", "back" ],
	"SETTINGS" : {}, // Set by page
	"EVENT" : {},
	/* ****************** end of constants ****************** */
	/* ********************** globals *********************** */
	"body" : $('#summary, #filters, #details'),
	"details" : $("#details"),
	"table" :$(".ldse-table"),
	"tableHead" :$(".ldse-table thead"),
	"buildTableHead" : true,
	"tableBody" :$(".ldse-table tbody"),
	"sensitiveSection" :$("section#sensitive-content-warning"),
	"pagination":$("div.ldse-pagination"),
	"pageTotal" :$("#pageTotal"),
	"tabDown" :$("div.ldse-tab-down dd"),
	"summaryAndDetails" : $('section.ldse-section'),
	"summarySectionBody" : $('.ldse-summary .ldse-section--body'),
	"allBtn" : $("#allBtn"),
	"odd" : true,
	"prevBtn" : $("div.ldse-pagination .ldse-icon-ko-tri-left"),
	"nextBtn" : $("div.ldse-pagination .ldse-icon-ko-tri-right"),
	"curAjax" : null,
	"buttons" : {
		"complete" : $('#action-complete'),
		"back" : $('#action-back'),
		"block" : $('#action-block'),
		"export" : $('#action-export')
	},
    "disablePublishing": null,
	"modal" : $('#modal1'),
	"window" : $(window),
	"defaultAscend" : true,
	"ascending" : true,// C.defaultAscend,
	"selectedColumnId" : "",
	"selectedPageSize" : 25,
	"pageIndex" : 1,
	"totalPages" : 0,
	"initialDatePickerShown" : false,
	"trimLength" : Math.floor($(document.body).width() / 25),
	"selectedStatus" : "",
	"dateElement" : "",
	"filterData" : {},
	"filterObject" : new FilterObject(),
	"summarySubText" : $("#summary .subtext"),
	"applyFilterBtn" : $("#applyFilterBtn"),
	"clearFilterBtn" : $("#clearFilterBtn"),
	"cancelFilterBtn" : $("#cancelFilterBtn"),
	"filterBtnWrapper" : $("#filterButtons"),
	"filterSubText" : "",
	"windowResizeTimeoutLimitSub" : null,
	"windowResizeLimitSubTime" : 50,
	"firstLoad": true,
	"keyTimeout" : null, /*
							 * This will hold the timeout variable set after key
							 * presses on input fields
							 */
	"keyTimeoutTime" : 250, /***************************************************
							 * How many milliseconds to wait after the key is
							 * pressed before calling function /
							 *  /* ****************** end of globals
							 * *******************
							 */
	/* ********************** functions ********************* */

	"ready" : function() {
		C.setupListeners();
		if ('content-filters' in sessionStorage) {
			var storedFilters = sessionStorage.getObject('content-filters');
			C.updatePageLink(storedFilters.pageSize);
			//C.pageIndex = storedFilters.pageIndex || 1;
			C.ascending = storedFilters.ascending || true;
			C.selectedColumnId = storedFilters.columnId || "";
			C.filterObject.updateSavedDate(new FilterDataObj(storedFilters));
			C.cancelFilters();
			C.updateButtons(C.selectedStatus);
		} else {
			C.updateButtons("");
			C.updateDateFilter("");
			C.updateUserFilter("");
			C.updateFilterData(true);
		}
		C.displayTContent(true);
		C.registerHandleBarHelpers();
		$(".handlebars-template").each(function() {
			window[$(this).attr('id')] = Handlebars.compile($(this).html());
		});
		C.setupDatePicker();
		C.filterCheck();
		if (C.PUBLISH) {
			C.publishFile();
		}
	},

	"registerHandleBarHelpers" : function() {
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
		Handlebars.registerHelper('href', function(content) {
			var href = '';
			if (content.uri.indexOf('?') !== -1) {
				href = content.uri;
			} else if (sharedPrefix !== '') {
				if (content.uri.indexOf(sharedPrefix) !== 0) {
					href += sharedPrefix;
				}
				href += content.uri + "?lang=" + splitLocale(content("previewLocale")); //splitLocale comes from ice.js
			} else {
				href = frontEndHost + content.uri + "?lang=" + splitLocale(content["previewLocale"]); //splitLocale comes from ice.js
			}
			return href;
		});
		Handlebars.registerHelper('checkedCount', function() {
			var count = $("#details .ldse-table tbody tr input:checked").length;
			if (count === 0) {
				count = 1;
			}
			return count;
		});
		Handlebars.registerHelper('userTitle', function(context) {
			return C.SETTINGS[context.status].user;
		});
		Handlebars.registerHelper('ifShown', function(item, block) {
			if (typeof item != "undefined") {
				return block(this);
			}
		});
		Handlebars.registerHelper('json', function(context) {
			return JSON.stringify(context);
		});

		Handlebars.registerHelper('tgp', function(context) {
			return numberWithCommas(C.wordsToTGP(Number(context)));
		});

		Handlebars.registerHelper('trimString', function(passedString) {
			if (typeof passedString != "undefined") {
				passedString = passedString.replace(/\//g, '/&#8203;').replace(
						/-/g, '-&#8203;').replace(/_/g, '_&#8203;').replace(
						/\w+$/, '').substring(0, C.trimLength);
				return new Handlebars.SafeString(passedString)
			}
		});
		Handlebars.registerHelper('isCommentStatus', function(passedString) {
			if (C.selectedStatus !== "comments" && this.name !== "comments") {
                return "<dt>Docs</dt><dd>" + numberWithCommas(this.docs) + "</dd><dt>Oldest</dt><dd>" + C.formatDate(this.oldest) + "</dd>";
			} else {
			    return "</dd><dt>Oldest</dt><dd>" + C.formatDate(this.oldest) + "</dd>";
			}
		});

		Handlebars.registerHelper('isSensitive', function(passedString) {
			if ( this.sensitive == "yes" ) {
                return "ldse-info-banner sensitive-content-warning";
			} else {
			    return "";
			}
		});
		Handlebars.registerHelper('sensitiveCount', function(passedString) {
            var count = 0;
            for (var i = 0; i < passedString.length; i++ ) {
        		if ( passedString[i].sensitive == "yes" ) {
                    count++;
        		}
            }
            if ( count > 0 && $("section.ldse-info-banner").length <= 0 ) {
                return '<section class="ldse-section ldse-info-banner warning"> <div class="ldse-section--body"><span class="ldse-icon-ko-warning ldse-icon ldse-info-banner-icon">Warning</span><div class="ldse-warning-messages-div"><div class="ldse-warning-message-div"><h3 class="ldse-warning-message-title">Sensitive Content</h3><div>There are sensitive items on this page. They are highlighted below and may not be approved for publishing.</div></div></div></div></section>';
            }
		});
		Handlebars.registerHelper('showSection', function(count) {
            var test = count;
		});
		Handlebars.registerHelper('forceBreak', function(passedString) {
			if (typeof passedString != "undefined") {
				passedString = passedString.replace(/\//g, '/&#8203;').replace(
						/-/g, '-&#8203;').replace(/_/g, '_&#8203;');
				return new Handlebars.SafeString(passedString)
			}
		});

		Handlebars.registerHelper('numberWithCommas', function(n) {
			return numberWithCommas(n);
		});

		Handlebars.registerHelper("formatDate", function(dateString) {
			if (dateString !== undefined) {
				return C.formatDate(dateString);
			}
			return ""
		});

		// placed in own function so could be used by TGP as well
		// (because I don't think you can put multiple helpers on one expression
		// in handlebars)
		function numberWithCommas(n) {
		    if ( n !== undefined ) {
     			var parts = n.toString().split(".");
     			return parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",")
     					+ (parts[1] ? "." + parts[1] : "");
			}
		}
	},
	"updateDetails" : function(a) {
		C.sumWords(a);
		C.updateButtons(C.getCheckedStatus());
	},
	"setupListeners" : function() {
		C.buttons.export.click(function(e) {
			e.preventDefault();
			DetailTable.export(document.title);
		});
		$(".ldse-icon-calendar").click(function() {
			$(this).prev().datepicker("show");
		});
		$("#end, #start").keydown(function(evt) {
			// evt.preventDefault();
			C.checkTabEnter($(this), evt);
		}).blur(function(evt) {
			C.datePickerLoseFocus($(this));
		});

		$("#filter-search").keypress(C.reloadOnEnter);
		$("#filter-search").keyup(C.refreshFilterOnKey);
		$('#filter-body').on("change", '#languageFilterBox select:first',
			function(e) {
				// C.applyFilters();
			}).on("change", ' #statusFilterBox select', function(e) {
			C.updateDateFilter($(this).val());
			C.updateUserFilter($(this).val());
			C.selectedStatus = $("#statusFilterBox select").val();
			C.updateFilterData();
			// C.applyFilters();
			C.filterCheck();
		}).on("change", ' #siteFilterBox select', function(e) {
			C.updateDateFilter($(this).val());
			C.updateUserFilter($(this).val());
			C.selectedSite = $("#siteFilterBox select").val();
			C.updateFilterData();
			C.applyFilters();
			C.filterCheck();

            $.ajax({
                url : sharedPrefix
                    + "/api/v1/disablepublishing",
                type : "GET",
                dataType : "json",
                data : {
                    "site" : C.selectedSite
                },
                success : function(response) {
                    C.disablePublishing = response.disablePublishing;
                },
                error : function() {
                    C.disablePublishing = 'false';
                }
            });



		});
		$('body').on("change", '.checkall', function(e) {
		/*
			var $selectAll = $(this);

			$selectAll.closest('table').find('tbody input[type="checkbox"]')
				.each(function() {
					if($(this).hasClass('always-check-all') || $(this).attr("id").split("-")[1] == C.pageIndex)
					{
						$(this).attr('checked', $selectAll[0].checked);
					}
				});
		*/
			C.updateDetails(this);
		});
		$("body").on("click",
				"input[type='checkbox'], input[type='checkbox']:parent",
				function() {
					C.updateDetails(this);
				});

		$("#filters").on("click", "#applyFilterBtn", function(event) {
			C.applyFilters(event);
		}).on("click", "#cancelFilterBtn", function(event) {
			C.cancelFilters(event);
		});
		$("#statusFilterBox header").on("click", "a", function() {
			C.toggleStatusFilter();
		});
		$("#languageFilterBox header").on("click", "a", function() {
			C.toggleLanguageFilter();
		});
		$("#uriFilterBox header").on("click", "a", function() {
			C.toggleUriFilter();
		});
		$("#categoryFilterBox header").on("click", "a", function() {
			C.toggleCategoryFilter();
		});
		$("#dateFilterBox header").on("click", "a", function() {
			C.toggleDateFilter();
		});
		$("#userFilterBox header").on("click", "a", function() {
			C.toggleUserFilter();
		});

		$("#userFilterBox").on("keyup", "input", function() {
			C.refreshFilterOnKey();
		});

		$("#uriFilterBox .repeater").data().repeater.options.onRemove = function() {
			C.updateFilterData();
		}
/*		$("#categoryFilterBox .repeater").data().repeater.options.onRemove = function() {
			C.updateFilterData();
		}*/

		$("#userFilterBox .repeater").data().repeater.options.onRemove = function() {
			C.updateFilterData();
		}
		$("#uriFilterBox").on("keyup", "input", function() {
			C.refreshFilterOnKey();
		});
		$("#categoryFilterBox").on("keyup", "input", function() {
			C.refreshFilterOnKey();
		});

		$("#languageFilterBox select").first().on("change", function() {
			C.updateFilterData();
		});

		$("#following").on("change", function() {
			C.updateFilterData();
		});

		$("#followingFilterBox header").on("click", "a", function() {
			$("#following").removeAttr('checked').change();
		});

		window["changeFilter"] = C.updateFilterData;

		$(C.clearFilterBtn).on("click", function(event) {
			C.clearFilters(event);
			C.applyFilters(event);
			C.selectedColumnId ="";
		});

		$("#filters header a").on(
				"click",
				function() {
					if (C.windowResizeTimeoutLimitSub) {
						clearTimeout(C.windowResizeTimeoutLimitSub);
					}
					C.windowResizeTimeoutLimitSub = setTimeout(C.limitSubText,
							C.windowResizeLimitSubTime);

					C.filterCheck();
				});
		window.onresize = function() {
			C.limitSubText();
		};


	},
	"setupDatePicker" : function() {

		$.datepicker.setDefaults({
			changeYear : true,
			changeMonth : true,
			dateFormat : "dd M yy",
			altFormat : "yy-mm-dd",
			// onChangeMonthYear:C.styleDatePickerDropDownBtnsTimeout,
			beforeShow : beforeShowFunc,
			onClose : closeDate
		});

		$('#start').datepicker({
			altField : "#startHidden",
			onSelect : selectDate
		});
		$('#end').datepicker({
			altField : "#endHidden",
			onSelect : selectDate
		});

		function beforeShowFunc(input, inst) {
			rightAlignWidget(input, inst);
			if (inst.id == "end") {
				end.datepicker("option", setMinDateForEndDate());
			}
			// setTimeout(C.styleDatePickerDropDownBtns,25)
		}

		function rightAlignWidget(input, inst) {
			var datepickerHeight = 240;
			var datepickerWidth = 230;

			var field = $(input);
			var x = field.outerWidth(false);
			var y = field.offset().top + field.outerHeight(false) + 3;

			var left = field.offset().left - (datepickerWidth - x) - 6;
			var top = y;
			setTimeout(function() {
				$('#ui-datepicker-div').css({
					'top' : top,
					'bottom' : '' + 'px',
					'left' : left + 'px'
				});
			}, 1);
		}

		var start = $("#start");
		var end = $("#end");
		function setMinDateForEndDate() {
			var d = start.datepicker('getDate');
			if (d)
				return {
					minDate : d
				}
		}

		function closeDate(dateText, inst) {
			function getParsed(dateTextPassed) {
				if (!isNaN(Number(dateTextPassed)))
					return;
				var date = Date.parse(dateTextPassed);
				if (isNaN(date) || date < 0)
					return;

				return $.datepicker.parseDate("@", date);
			}

			if (inst.id == "start") {
				var dateParsed = getParsed(start.val());
				start.datepicker("setDate", dateParsed)
				clearEndDate(dateText, inst);
				if (!dateParsed) {
					start.val("");
				}
			} else {
				var dateParsed = getParsed(inst.input.val());
				inst.input.datepicker("setDate", dateParsed)
				if (!dateParsed) {
					inst.input.val("");

				}

			}

		}

		function clearEndDate(dateText, inst) {

			if (start.datepicker("getDate") > end.datepicker("getDate")) {
				end.val('');
			}
		}

		function selectDate() {
			C.initialDatePickerShown = true;
			C.updateFilterData();
			// applyFiltersrs();
		}
		if (LDSE.isTouch) {
			$("#dateFilterBox input").attr("readonly", "readonly");
			$("a.ldse-icon-globe.ldse-popup").removeAttr("href");
		}
		C.addDatePicker();
	},
	"checkTabEnter" : function(input, evt) {
		if (evt.which == 13 || evt.which == 9) {
			input.datepicker("setDate", input.val());
			input.datepicker("hide");
		}
		if (evt.which == 13) {
			input.trigger("blur");
		}
	},
	"datePickerLoseFocus" : function(input) {
		input.trigger("hide");
	},
	"styleDatePickerDropDownBtnsTimeout" : function() {
		setTimeout(C.styleDatePickerDropDownBtns, 25)
	},
	"addDatePicker" : function() {
		var dp = $(".datepicker");
		dp.keydown(function(evt) {
			C.checkTabEnter($(this), evt);
		}).blur(function(evt) {
			C.datePickerLoseFocus($(this));
		});
		var hiddenField = ("#" + $(dp).attr("hiddenFldId"));
		dp.datepicker({
			minDate : new Date(),
			altField : hiddenField,
			altFormat : "yy-mm-dd"
		}).removeClass('datepicker');

		$(".ldse-icon-calendar").click(function() {
			$(this).prev().datepicker("show");
		});

	},
	/*
	 * This method checks to see if the filters have been changed if so the
	 * apply and clear buttons show up
	 */
	"filterCheck" : function() {
		if (C.filterObject.hasChanged()) {
			C.applyFilterBtn.show();
			C.cancelFilterBtn.show();

		} else {
			C.applyFilterBtn.hide();
			C.cancelFilterBtn.hide();
		}

		if (C.filterObject.isEmpty()) {
			C.clearFilterBtn.hide();
		} else {
			C.clearFilterBtn.show();
		}

		if ((!C.filterObject.isEmpty() || C.filterObject.hasChanged())
				&& !($("#filters").hasClass("closed"))) {
			C.filterBtnWrapper.show();
		} else {
			C.filterBtnWrapper.hide();
		}
		C.setSummarySubtext();
	},
	"setSummarySubtext" : function() {
		if (!C.filterObject.dataIsEmpty(C.filterObject.getSavedData())) {
			C.summarySubText.html("(Based on filters applied)");
		} else {
			C.summarySubText.html("");
		}
	},
	"refreshFilterOnKey" : function() {
		if (C.keyTimeout != null) {
			clearTimeout(C.keyTimeout);
		}
		C.keyTimeout = setTimeout(C.updateFilterData, C.keyTimeoutTime);
	},
	"disableNavBtns" : function() {
		C.prevBtn.removeClass("faded");
		C.nextBtn.removeClass("faded");
		if (C.pageIndex == 1) {
			C.prevBtn.addClass("faded");
		}
		if (C.pageIndex == C.totalPages) {
			C.nextBtn.addClass("faded");
		}
	},
	"loginIfRedirected" : function(response) {
		if (response.statusText === "abort") {
			return;
		}
		if (response.status === 0) {

			location.reload();
		}
	},
	"displayResults" : function(renderSummary, results) {
		if(C.EVENT != undefined && (C.EVENT.originalTarget != undefined || C.EVENT.target != undefined))
		{
			var target = C.EVENT.originalTarget || C.EVENT.target;

			if(!$(target).hasClass("saveWordCount"))
			{
				C.tabDown.html("0");
			}
		}
		else
		{
			C.tabDown.html("0");
		}

		C.EVENT = {};

		if (renderSummary) {
            DetailTable.Pagination.trs().remove();
			C.summarySectionBody.html(
					summaryTemplate(results));
			LDSE.resizeCallbacks.makeCols();
		}
		if(C.buildTableHead)
		{
			C.tableHead.html(detailsHeadTemplate(results));
			C.buildTableHead = true;
		}
		C.tableBody.append(detailsBodyTemplate(results));
		C.sensitiveSection.append(sensitiveItemTemplate(results));
		if(C.firstLoad) {
			var totalPages = parseInt(results[4] / DetailTable.Pagination.pageSize) + (results[4] % DetailTable.Pagination.pageSize > 0 ? 1: 0);
			DetailTable.RealCount.count = results[4];
			DetailTable.Pagination.totalPages = totalPages;
			$("#totalPages").text(totalPages);
			C.firstLoad = false;
			window["resultCount"] = results[4];
			DetailTable.Pagination.trCount = function(){return window["resultCount"];};
			DetailTable.Pagination.changePageSize(25);
			DetailTable.Checkboxes.wireup();
		} else {
			var totalPages = parseInt(results[4] / DetailTable.Pagination.pageSize) + (results[4] % DetailTable.Pagination.pageSize > 0 ? 1: 0);
			DetailTable.RealCount.count = results[4];
			DetailTable.Pagination.totalPages = totalPages;
			$("#totalPages").text(totalPages);
            DetailTable.Pagination.showPage(DetailTable.Pagination.currentPage);
        }
	},
	"reloadOnEnter" : function(evt) {
		if (evt.which == 13) {
			C.applyFilters();
		}
	},
/*	"nextPage" : function(e) {
		C.EVENT = e;
		if (C.pageIndex < C.totalPages) {
			C.pageIndex++;
			C.displayTContent(false);
			C.disableNavBtns();
		}
		C.setSelectAll();
		e.preventDefault();
	},
	"prevPage" : function(e) {
	    C.EVENT = e;
		if (C.pageIndex > 1) {
			C.pageIndex--;
			C.displayTContent(false);
			C.disableNavBtns();
		}
		C.setSelectAll();
		e.preventDefault();
	},
	"setSelectAll" : function() {
		var checked = 0;
		$("#details-checkall").closest("table").find("tbody input:checkbox:checked")
			.each(function(){
				if($(this).attr("id").split("-")[1] == C.pageIndex)
				{
					checked++;
				}
			});
		$("#details-checkall")[0].checked = checked == C.selectedPageSize;
		C.updateButtons(C.getCheckedStatus());
	},
	"changePageSize" : function(pageSize) {
		C.selectedPageSize = pageSize;
		C.updatePageLink(pageSize);
		C.pageIndex = 1;
		C.displayTContent(false);
		C.setSelectAll();
	},*/
	"updatePageLink" : function(pageSize) {
		var pageSizeElement = $("span.ldse-pagination--shownum a[data-count="
				+ pageSize + "]")[0];
		$("span.ldse-pagination--shownum a").not("[href]").attr("href", "#d");
		$(pageSizeElement).removeAttr("href");
	},
	"toggleLanguageFilter" : function() {
		C.clearLanguageBox();
	},
	"toggleDateFilter" : function() {
		C.clearDateBox();
	},
	"toggleStatusFilter" : function() {
		C.clearStatusBox();
	},
	"toggleUriFilter" : function() {
		C.clearUriBox();
	},
	"toggleCategoryFilter" : function() {
		C.clearCategoryBox();
	},
	"toggleUserFilter" : function() {
		C.clearUserBox();
	},
	"clearStatusBox" : function() {
		$("#statusFilterBox select").val("").change();
		C.selectedStatus = "";
		C.updateFilterData();
	},
	"clearUriBox" : function() {
		$("#uriFilterBox .ldse-adder").click();
		var numSelects = ("#languageFilterBox div div.ui-multiSelect").length;
		$("#uriFilterBox .ldse-icon.ldse-icon-ko-remove").each(function(index) {
			if (index != numSelects - 1) {
				$(this).click();
			}
		});
		C.filterObject.updateUris([]);
		C.updateFilterData();
	},
	"clearCategoryBox" : function() {
		$("#categoryFilterBox .ldse-adder").click();
		var numSelects = ("#languageFilterBox div div.ui-multiSelect").length;
		$("#categoryFilterBox .ldse-icon.ldse-icon-ko-remove").each(function(index) {
			if (index != numSelects - 1) {
				$(this).click();
			}
		});
		C.filterObject.updateCategories([]);
		C.updateFilterData();
	},
	"clearDateBox" : function() {
		if (C.initialDatePickerShown) {
			C.clearDates();
			C.filterObject.updateDates("", "");
			C.updateFilterData();
		}
	},
	"clearDates" : function() {
		$("#dateFilterBox input").datepicker("setDate", null);
		$("#end").datepicker("option", "minDate", null);
		$("#hiddenStart").val('');
		$("#hiddenEnd").val("");
		C.updateFilterData();
	},
	"clearLanguageBox" : function() {
		$("#languageFilterBox .ldse-icon.ldse-icon-ko-remove:not(:last)").click();
		$("#languageFilterBox select").children().removeAttr("selected").end()
				.val("").change();
		C.updateFilterData();
	},
	"clearUserBox" : function() {
		$("#userFilterBox .ldse-adder").click();
		var numSelects = ("#userFilterBox div div.ui-multiSelect").length;

		$("#userFilterBox .ldse-icon.ldse-icon-ko-remove").each(function(index) {
			if (index != numSelects - 1) {
				$(this).click();
			}
		});
		$("#userFilterBox :input").val("");
		C.updateFilterData();
	},
	"clearFilters" : function(e) {
		C.EVENT = e;
		C.clearUserBox();
		C.clearLanguageBox();
		C.clearDateBox();
		C.clearUriBox();
		C.clearCategoryBox();
		C.clearStatusBox();
		C.clearFollowing();
		$("#filter-search").val("");
		C.updateFilterData();
	},
	"clearFollowing": function() {
		$("#following").removeAttr("checked");
	},
	// this function will set the html back to previously saved filters
	"cancelFilters" : function(event) {
		var savedData = C.filterObject.getSavedData();
		$("#statusFilterBox select").val(savedData.status);
		C.selectedStatus = savedData.status;
		$("#statusFilterBox select").change();
		if (savedData.following == "true" ) {
			$("#following").attr('checked', 'checked');
		} else {
			$("#following").removeAttr('checked');
		}

		// language filter
		var langSelect = $("#languageFilterBox select").first();
		var options = langSelect.data().multiSelect.options;
		langSelect.children().removeAttr("selected").end().val(
				savedData.locales || []).multiSelect("destroy").multiSelect(
				options);
	/*	setTimeout(function() {
			langSelect.siblings(".ui-multiSelect").find("select").each(
					function() {
						var self = $(this);
						self.width(langSelect.width() + 30);
						self.fixSelect("updateWidths");
					});
		}, 500);*/

		// root/uri & user filter
		setInputFields($("#uriFilterBox"), savedData.uris)
		setInputFields($("#categoryFilterBox"), savedData.categories)
		setInputFields($("#userFilterBox"), savedData.users)

		// date filter
		$("#startHidden").val(savedData.startDate);
		$("#endHidden").val(savedData.endDate);
		$("#start").val(C.formatDate(savedData.startDate));
		$("#end").val(C.formatDate(savedData.endDate));

		function setInputFields(filterBox, values) {
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

		}

		$("#filter-search").val(savedData.searchString);

		// open necessary filterBoxes
		if (savedData.locales.length > 0) {
			$("#languageFilterBox").addClass("ldse-open");
		}
		if (savedData.users.length > 0) {
			$("#userFilterBox").addClass("ldse-open");
		}
		if (savedData.uris.length > 0) {
			$("#uriFilterBox").addClass("ldse-open");
		}
		if (savedData.categories.length > 0) {
			$("#categoryFilterBox").addClass("ldse-open");
		}
		if (savedData.status != "") {
			$("#statusFilterBox").addClass("ldse-open");
		}
		if (savedData.following != "") {
			$("#followingFilterBox").addClass("ldse-open");
		}
		if (savedData.startDate != "" || savedData.endDate != "") {
			$("#dateFilterBox").addClass("ldse-open");
		}

		C.updateFilterData();

	},
	"applyFilters" : function(e) {
		C.EVENT = e;
		C.pageIndex = 1;
		C.tableBody.find("tr").remove();
		C.updateFilterData(true);
		C.filterObject.save();
		C.filterCheck();
		C.displayTContent(true);
		//C.setSelectAll();
	},
	"sortByColumn" : function(columnId) {
		//C.pageIndex = 1;
		if (columnId == C.selectedColumnId) {
			C.ascending = !C.ascending; // toggle
		} else {
			C.ascending = C.defaultAscend;
		}
		C.selectedColumnId = columnId;
		C.displayTContent(false);
	},
	"clickSearch" : function(e) {
	    C.EVENT = e;
		C.pageIndex = 1;
		C.tableBody.find("tr").remove();
		C.applyFilters(e);
		//C.setSelectAll();
		// C.updateFilterData(true);
		// C.displayTContent(true);
	},
	"styleSortColumn" : function() {
		$("#details thead th").removeClass("sort");
		$("#details thead th").removeClass("asc");
		$("#details thead th").removeClass("desc");
		var directionString = "asc";
		if (!C.ascending) {
			directionString = "desc";
		}
		if (C.selectedColumnId != "") {
			$("#details thead th#" + C.selectedColumnId).addClass("sort");
			$("#details thead th#" + C.selectedColumnId).addClass(
					directionString);
		}

	},
	"clickStatus" : function(status) {
		C.updateUserFilter("");
		C.buildTableHead = true;
		var statusName = $(status).attr("data-name");
		C.selectedStatus = statusName;
		$("#statusFilterBox select").val(statusName)
		$("#statusFilterBox select").change();
		$("#filters").removeClass("closed");
		$("#statusFilterBox").addClass("ldse-open").find('.ldse-block--body').show();
		C.applyFilters();
	},
	// converts from yyyy-mm-dd to dd M yy ex. 2012-01-01 to 01 Jan 2012
	"formatDate" : function(dateStr) {
		if (dateStr !== undefined && dateStr != "" && dateStr != " ") {
			return $.datepicker.formatDate("dd M yy", $.datepicker.parseDate(
					'yy-mm-dd', dateStr));
		}
		return "";
	},
	"sumWords" : function(checkbox) {
		var form = $(checkbox).closest("div"), boxes = form
				.find('.ldse-table tbody tr input:checked');
		var sum = 0;
		boxes.each(function() {
			sum += Number($(this).data('words'));
		});
		form.find("div.ldse-tab-down dd").first().html(sum);
		form.find("div.ldse-tab-down dd").last().html(C.wordsToTGP(sum));
	},
	"updateFilterData" : function(renderSum) {
		var searchString = $("#filter-search").val();
		var uris = [], categories = [], users = [], a = $("#uriFilterBox input").get(), i = a.length, b = $("#categoryFilterBox input").get(), n = b.length;
		while (i--) {
			var uriValue = a[i].value;
			if (uriValue.substring(0, 1) == "/") { // remove slash if begins
													// with
				uriValue = uriValue.substring(1);
			}
			uris.push(uriValue);
		}
		while (n--) {
			var categoryValue = b[n].value;
			if (categoryValue.substring(0, 1) == "/") { // remove slash if begins
													// with
				categoryValue = categoryValue.substring(1);
			}
			categories.push(categoryValue);
		}
		function spliceBlanks(ar) {
			while (ar.indexOf("") != -1) {
				ar.splice(ar.indexOf(""), 1);
			}
			return ar;
		}
		a = $("#userFilterBox input").get();
		i = a.length;
		while (i--) {
			users.push(a[i].value);
		}
		users = spliceBlanks(users);
		uris = spliceBlanks(uris);
		categories = spliceBlanks(categories);
		var langs = $("#languageFilterBox select").first().val() || [];

		if (langs != null) {
			langs = spliceBlanks(langs);
			C.filterObject.updateLocales(langs.slice(0));
		}
		var startDate = $("#startHidden").val();
		var endDate = $("#endHidden").val();
		var following = $('#following:checked').val() || "";
		C.filterObject.updateFollowing(following);
		C.filterObject.updateDates(startDate, endDate);

		C.filterObject.updateSearchString(searchString);
		C.filterObject.updateStatus($("#statusFilterBox select").val());
		C.filterObject.updateSite($("#siteFilterBox select").val());
		C.filterObject.updateUris(uris);
		C.filterObject.updateCategories(categories);
		C.filterObject.updateUsers(users);
		C.filterCheck();

		// Make substring to show filters
		var filterStrings = [];
		if (searchString != "") {
			filterStrings.push("search:" + searchString + "");
		}
		if (C.selectedStatus != "") {
			filterStrings.push("status:" + C.selectedStatus + "");
		}
		if (langs != null && langs.length > 0) {
			filterStrings.push("locales:" + langs.join(",") + "");
		}
		if (uris.length > 0) {
			filterStrings.push("roots:" + uris.join(",") + "");
		}
		if (users.length > 0) {
			filterStrings.push("users:" + users.join(",") + "");
		}

		if (startDate != "") {
			filterStrings.push("start-date:" + C.formatDate(startDate));
		}
		if (endDate != "") {
			filterStrings.push("end-date:" + C.formatDate(endDate));
		}

		C.filterSubText = (" (" + filterStrings.join("; ") + ")");
		C.limitSubText();
	},
	"limitSubText" : function() {
		if (!$("#filters").hasClass("closed") || C.filterSubText == " ()") {
			$("#filters .subtext").html("");
			return;
		}
		var extraWidth = 115; // this is about how many pixels the collapse
								// button and filters label take up
		var subText = C.filterSubText;
		$("#filters .subtext").html(subText);

		var subWidth = ($("#filters").width() - extraWidth);
		var subTextWidth = $("#filters .subtext").width();

		if (subTextWidth > subWidth) {
			while ($("#filters .subtext").width() > subWidth
					&& subText.length >= 7) {
				subText = subText.substr(0, subText.length - 6) + " ...)";
				$("#filters .subtext").html(subText);
			}
		} else {
			$("#filters .subtext").html(subText);
		}

	},
	"displayTContent" : function(renderSum) {
		C.table.addClass("faded");
		if (C.curAjax) {
			C.curAjax.abort();
		}

       if ( C.selectedStatus == "comments" ) {
           $("form").find("input[id=filter-search]").attr('placeholder', "Search Comments");
           $("#filters").find("span.subtext").text("(Filters applied to all comments in conversation)");
       } else {
           $("form").find("input[id=filter-search]").attr('placeholder', "Search Content");
           $("#filters").find("span.subtext").text();
       }
		var jsonData = new FilterDataObj(C.filterObject.getSavedData());
		var tempSize = jsonData.pageSize;
		// made a copy of saved data rather than reference - this way editing
		// jsonData won't edit saved data
		jsonData.pageSize = 100;
		jsonData.pageIndex = DetailTable.Pagination.currentPage;
		jsonData.ascending = C.ascending;
		jsonData.columnId = C.selectedColumnId;
		jsonData.rSum = renderSum;
		//C.pageTotal.html(
		//		" Page " + C.pageIndex + " of " + C.totalPages + "&nbsp;");
		if ( $('#siteFilterBox select').val() === undefined ) {
            jsonData.site = getParameterByName('site');
		} else {
		    jsonData.site = $('#siteFilterBox select').val();
		};
		C.curAjax = $.ajax({
			type : "POST",
			async: true,
			contentType : "application/x-www-form-urlencoded",
			dataType : "json",
			url : sharedPrefix + "/content/ajax/search?lang=eng",
			data : jsonData,
			success : function(response, textStatus) {
				C.details.removeClass("closed");
				C.table.removeClass("faded");
				C.hideButtons();
				C.clearLoading();
				C.displayResults(renderSum, response);
				C.styleSortColumn();
				DetailTable.Checkboxes.wireup();
			},
			complete : C.clearLoading
		});
        jsonData.pageSize = tempSize;
        sessionStorage.setObject('content-filters', jsonData);
	},
	"updateDateFilter" : function(status) {
		if (status == "" || !C.SETTINGS[status]) {
			C.clearDates();
			$("#dateFilterBox").hide();
		} else {
			var dateTitle = C.SETTINGS[status]["date"];
			if (dateTitle) {
				C.clearDates();
				$("#dateFilterBox").show();
				$("#dateFilterTitle").html(dateTitle);
			} else {
				$("#userFilterBox").hide();
			}
		}
	},
	"updateUserFilter" : function(status) {
		if (status == "" || !C.SETTINGS[status]) {
			C.clearUserBox();
		    $("#userFilterBox").hide();
		} else {
			var userTitle = C.SETTINGS[status]["user"];
			if (userTitle) {
				C.clearUserBox();
				$("#userFilterBox").show();
				$(".userFilterTitle").html(userTitle);
			} else {
				$("#userFilterBox").hide();
			}
		}
	},
	"wordsToTGP" : function(words) {
		return (Math.round(words / 286 * 100) / 100).toFixed(2);
	},
	"disableButtons" : function() {
		$.each(C.buttons, function(key, button) {
			button.attr("disabled", "disabled");
		});
	},
	"enableButtons" : function() {
		$.each(C.buttons, function(key, button) {
			button.removeAttr("disabled");
		});
	},
	"showButtons" : function() {
		$.each(C.buttons, function(key, button) {
			button.show();
		});
	},
	"hideButtons" : function() {
		$.each(C.buttons, function(key, button) {
			button.hide();
		});
	},
	"setButtonClick" : function(status, action, statusActions) {
		var button = C.buttons[action].hide().unbind('click');
		var templateKey = action + '-template';

		if (statusActions && action in statusActions) {
			// boolean set to whether multiple items have been checked in from
			var multiCheckReview = (status == "preview"
					&& action == "complete" && C.getCheckedIds().length > 1);

			if (!(multiCheckReview)) {
				button.html(statusActions[action]).show();
				button.attr('title', statusActions[action]);
			}
			if (templateKey in statusActions) {
				var template = statusActions[templateKey];
				if (template.type === "form") {
					button.click(function() {
						C.applyTemplateAction(status, action, template);
						return false;
					});
				} else if (template.type === "reason") {
					button.click(function() {
						C.applyReasonAction(status, action, template);
						return false;
					});
				} else if (template.type === "delete") {
					button.click(function() {
						C.applyDeleteAction(status, action, template);
						return false;
					});
				}
			} else {
				button.click(function() {
					C.applyAction(status, action);
					return false;
				});
			}
		}
	},
	"updateButtons" : function(status) {
		if (status === '') {
			C.hideButtons();
		} else {
			if ( status === "published" ) {
                var statusActions = C.SETTINGS['publish'];
                status = 'publish'
            } else { var statusActions = C.SETTINGS[status]; }
			$.each(C.ACTIONS, function(index, action) {
				C.setButtonClick(status, action, statusActions);
			});
		}
		var ids = C.getCheckedIds();
		if (ids.length > 0) {
			C.buttons.export.show();
		} else {
			C.buttons.export.hide();
		}
		if (ids.length > 1) {
			$("#action-complete").hide();
		} else if (ids.length == 1
			&& ((isSubmitter && $("tr input:checked").closest("tr").data("file").status == "created")
				|| !isSubmitter)
) {
			$("#action-complete").show();
		}
		if ( ids.length == 0 || C.disablePublishing == 'true' ) {
		    C.buttons.back.hide();
		} else if (ids.length >= 1 && ( $("tr input:checked").closest("tr").data("file") !== undefined ) ) {
			if ( $("tr input:checked").closest("tr").data("file").status !== "created" ) {
			    C.buttons.back.show();
			}
		} else if ( $("tr input:checked").closest("tr").data("file") !== undefined ) {
            if ( $("tr input:checked").closest("tr").data("file").status !== "created" ) {
/*                C.buttons.back.hide();*/
            }

		}

	},
	"alert" : function(title, text, onOk) {
		var templateData = {
			title : title,
			text : text,
			noCancel : true
		};
		C.modal.empty().append(window["confirmTemplate"](templateData))
				.trigger('open');
		C.modal.find('form').submit(function() {
			C.modal.trigger('close');
			if (typeof onOk !== "undefined") {
				onOk();
			}
			return false;
		});
	},
	"confirm" : function(title, text, fn) {
		var templateData = {
			title : title,
			text : text
		};
		C.modal.empty().append(window["confirmTemplate"](templateData))
				.trigger('open');
		C.modal.find('form').submit(function() {
			fn();
			C.modal.trigger('close');
			return false;
		});
	},
	"html" : $('html'),
	"clearLoading" : function() {
		clearTimeout(C.timeoutID);
		C.html.removeClass('loading');
	},
	"showLoading" : function() {
		clearTimeout(C.timeoutID);
		C.timeoutID = setTimeout("C.html.addClass('loading')", 500);
	},
	"applyAction" : function(status, action) {
		if (status == "returned" && action == "complete") {
			var href = $(C.checkedBoxes()[0]).closest("td").nextAll(".title")
					.find("a").attr("href");
			ICE.linkToItem(href, C.getCheckedIds()[0]);
			return;
		}
		$.ajax({
            url : sharedPrefix
                + "/content/ajax/apply-action?lang=eng",
            type : "POST",
            contentType : "application/x-www-form-urlencoded",
            dataType : "json",
            data : {
                "status" : status,
                "action" : action,
                "id" : C.getCheckedIds()
            },
            success : function(response) {
                if (response.success) {
                    C.confirm("Content Delete", "Are you sure you want to delete the selected files?", function() { });
                    C.displayTContent(true);
                } else {
                    C.alert("Error", "Failed to perform desired action");
                }
            },
            error : function(jqXHR) {
                C.loginIfRedirected(jqXHR);
                if (jqXHR.status === 409) {
                    // var response = $.parseJSON(
                    // jqXHR.getResponseHeader("json") );
                    C.alert("Error",
                        "Failed to perform desired action");
                }
            }
        });
		return false;
	},
	"applyReasonAction" : function(status, action, templateData) {
		C.modal.empty().append(window["reasonTemplate"](templateData)).trigger(
				'open');
		C.modal
				.find('form')
				.submit(
						function() {
							$(this)
									.ajaxSubmit(
											{
												url : sharedPrefix
														+ "/content/ajax/apply-action?lang=eng",
												type : "POST",
												contentType : "application/x-www-form-urlencoded",
												dataType : "json",
												data : {
													"status" : status,
													"action" : action,
													"id" : C.getCheckedIds()
												},
												success : function(response) {
													if (response.success) {
														C.modal
																.trigger('close');
														C.displayTContent(true);
													} else {
														$(
																"#modal1 input[name='reason']")
																.closest('dl')
																.addClass(
																		"error");
													}
												},
												error : function(jqXHR) {
													C.loginIfRedirected(jqXHR);
													if (jqXHR.status === 409) {
														$(
																"#modal1 input[name='reason']")
																.closest('dl')
																.addClass(
																		"error");
													}
												}
											});
							C.clearLoading();
							return false;
						});
		C.clearLoading();
		return false;
	},
	"applyDeleteAction" : function(status, action, templateData) {
		C.modal.empty().append(window["deleteTemplate"](templateData)).trigger(
				'open');
		C.modal
				.find('form')
				.submit(
						function() {
							$(this)
									.ajaxSubmit(
											{
												url : sharedPrefix
														+ "/content/ajax/apply-action?lang=eng",
												type : "POST",
												contentType : "application/x-www-form-urlencoded",
												dataType : "json",
												data : {
													"status" : status,
													"action" : action,
													"id" : C.getCheckedIds()
												},
												success : function(response) {
													if (response.success) {
														C.modal
																.trigger('close');
														C.displayTContent(true);
													} else {
														$(
																"#modal1 input[name='reason']")
																.closest('dl')
																.addClass(
																		"error");
													}
												},
												error : function(jqXHR) {
													C.loginIfRedirected(jqXHR);
													if (jqXHR.status === 409) {
														$(
																"#modal1 input[name='reason']")
																.closest('dl')
																.addClass(
																		"error");
													}
												}
											});
							C.clearLoading();
							return false;
						});
		C.clearLoading();
		return false;
	},
	"publishFile" : function() {
		C.applyTemplateAction(C.PUBLISH.status, C.PUBLISH.action,
				C.PUBLISH.template, C.PUBLISH.file, function() {
					$('#formTemplate .cancel').click(function(e) {
						e.preventDefault();
						e.stopPropagation();
						window.close();
					});
				}, function() {
					C.alert("Publish Successful", "", function() {
						window.close();
					});
				});
	},
	"applyTemplateAction" : function(status, action, template, file, onOpen,
			onSuccess) {
		C.showLoading();
		var files, ids;
		if (typeof file === "undefined") {
			files = C.getCheckedJSON();
			ids = C.getCheckedIds();
		} else {
			files = [ file ];
			ids = [ file.id ];
		}
		function success(additionalData) {
			var referenceFiles = [];
			var languageFiles = [];
			var data = {
				SETTINGS : C.SETTINGS,
				words : 0,
				files : files,
				languageFiles : additionalData.languageFiles,
				referenceFiles : additionalData.referenceFiles
			};
			$
					.each(
							data.files,
							function(index, file) {
								referenceFiles = [];
								languageFiles = [];
								if (additionalData.referenceFiles) {
									if (file.id in additionalData.referenceFiles) {
										referenceFiles = additionalData.referenceFiles[file.id];
									}
								}
								if (additionalData.languageFiles) {
									if (file.id in additionalData.languageFiles) {
										languageFiles = additionalData.languageFiles[file.id];
									}
								}
								file.languageFiles = languageFiles;
								file.referenceFiles = referenceFiles;
								data.words += Number(file.words);

							});
			if (data.referenceFiles) {
				$.each(data.referenceFiles, function(index, value) {
					data.words += Number(value.words);
				});
			}
			$('#formTemplate').remove();
			C.body.hide();
			var html = $('<section id="formTemplate" class="ldse-section cf"/>')
					.append(window[template.id](data));
			$('body .ldse-page:first').append(html);
			$('#formTemplate .cancel').click(function(e) {
				e.preventDefault();
				$('#formTemplate').remove();
				C.body.show();

			});
			C.addDatePicker();
			$('#formTemplate form')
					.submit(
							function() {
								$(this)
										.ajaxSubmit(
												{
													url : sharedPrefix
															+ "/content/ajax/apply-action?lang=eng",
													type : "POST",
													contentType : "application/x-www-form-urlencoded",
													dataType : "json",
													data : {
														status : status,
														action : action
													},
													success : function(response) {
														if (response.success) {
															if (typeof onSuccess !== "undefined") {
																onSuccess();
															} else {
																C.updateSettings(response.SETTINGS);
																$('#formTemplate').remove();
																C.body.show();
																C.displayTContent(true);
															}
														} else {
															C.markErrors(response.error);
														}
													},
													error : function(jqXHR) {
														C.loginIfRedirected(jqXHR);
														if (jqXHR.status === 409) {
															var response = $.parseJSON(jqXHR.getResponseHeader("json"));
															if (!response.success) {
																C.markErrors(response.error);
															}
														}
													}
												});
								return false;
							});
			C.clearLoading();
			if (typeof onOpen !== "undefined") {
				onOpen();
			}
		}
		C.getAdditionFiles(status, action, template.additional, success, ids);

	},
	"markErrors" : function(errors) {
		$("#formTemplate form dl.error, #formTemplate form tr.error")
				.removeClass("error");
		$.each(errors, function(index, value) {
			$("#formTemplate form input[name='" + value + "']")
					.closest('dl,tr').addClass("error");
			$("#formTemplate form select[name='" + value + "']").closest(
					'dl,tr').addClass("error");
			$("#formTemplate form textarea[name='" + value + "']").closest(
					'dl,tr').addClass("error");
		});
		$('html, body').animate({
			scrollTop : $("form dl.error, form tr.error").first().offset().top
		}, 0);
	},
	"updateSettings" : function(newSettings) {

		C.SETTINGS = $.extend(C.SETTINGS, newSettings);

	},
	"getAdditionFiles" : function(status, action, additional, success, ids) {
		if (C.curAjax) {
			C.curAjax.abort();
		}
		if (typeof ids === "undefined") {
			ids = C.getCheckedIds();
		}
		C.curAjax = $
				.ajax({
					async : true, // must wait for response
					type : "POST",
					contentType : "application/x-www-form-urlencoded",
					dataType : "json",
					url : sharedPrefix
							+ "/content/ajax/additional-files?lang=eng",
					data : {
						"status" : status,
						"action" : action,
						"id" : ids,
						"additions" : additional
					},
					beforeSend : function() {
					},
					success : success,
					complete : function() {
					}
				});
	},
	"checkedBoxes" : function() {
		return $("#details .ldse-table tbody tr input:checked");
	},
	"getCheckedIds" : function() {
		var ids = [];
		$.each(C.checkedBoxes(), function() {
			ids.push($(this).val());
		});
		return ids;
	},
	"getCheckedStatus" : function() {
		var status = "", curStatus;
		if (C.filterObject.getSavedData().status !== "") {
			if (C.checkedBoxes().length) {
				status = C.filterObject.getSavedData().status;
			} else {
				status = "";
			}
		} else {
			$.each(C.checkedBoxes(), function() {
				curStatus = $(this).closest('tr').data('file').status || "";
				if (curStatus === "") {
					status = "";
					return false;
				} else if (status === "" && curStatus !== "") {
					status = curStatus;
				} else if (status !== curStatus) {
					status = "";
					return false;
				}
			});
		}
		return status;
	},
	"getCheckedJSON" : function() {
		var files = [];
		$.each(C.checkedBoxes(), function() {
			files.push($(this).closest('tr').data('file'));
		});
		return files;
	},
	"export" : function() {
		var checkedIds = C.getCheckedIds();
		var success = function() {
			var params = "&id=" + checkedIds.join(",");
			var data = C.filterObject.getSavedData();
			$.each(data, function(key, value) {
				params += "&" + key + "=" + value;
			});
			document.location.href = sharedPrefix
					+ "/content/ajax/export?lang=eng"
					+ params;
		};
		if (checkedIds.length == 0) {
			C.alert("Error", "Please check the documents you'd like to export.");
		} else if (checkedIds.length > 500) {
			var message = "You've selected " + checkedIds.length
					+ " documents to export. "
					+ "This may take some time. Continue?";
			C.confirm("Warning", message, success);
		} else {
			success();
		}

	},
	"nonExistantOptions" : function(href, element) {
		var type = $(element).closest('tr').data('file').fileType || ""
		if (type == "resources"){
			redirectToFrontEnd(href);
		} else {
			C.confirm("Problem Editing Content", "You are attempting to edit content that was created using a previous version of LDS Publisher. Click OK to view this content in context and then choose to edit it.", function() { redirectToFrontEnd(href)});
		}

	}

};

function redirectToFrontEnd(href){
    document.location = href;
}

function editContent(){
    var method = "post",
        tr = $('tbody input:checked').closest('tr'),
        a = $(tr).find('td.title a'),
        path = a.attr('href'),
        params = $(tr).data('file');
    if (params.option) {
    	ICE.post(path, params, method);
    } else {
    	C.nonExistantOptions(path, a)
    }

}

// / ***** END OF T OBJECT************////
$.ajaxSetup({
	beforeSend : C.showLoading,
	complete : C.clearLoading
});

// ** -- Filter Object -- **\\
/*
 * The Filter Object has two sets of data - current and saved it has public
 * methods for updating the values of the current data and a public method
 * "hasChanged" that returns a boolean value of whether the saved data and
 * current data are identical. It also has a method for saving the currentData.
 */
function FilterObject() {
	var savedData = new FilterDataObj();
	var currentData = new FilterDataObj();
	var emptyData = new FilterDataObj(); // simply for testing if emtpy

	this.save = function() {
		savedData = new FilterDataObj(currentData)
	}

	function isSame(data1, data2) {
		if (data1.searchString != data2.searchString
				|| !arraysEqual(data1.uris, data2.uris)
				|| !arraysEqual(data1.users, data2.users)
				|| !arraysEqual(data1.locales, data2.locales)
				|| !arraysEqual(data1.categories, data2.categories)
				|| data1.status != data2.status
				|| data1.startDate != data2.startDate
				|| data1.endDate != data2.endDate
				|| data1.following != data2.following) {
			return false;
		}
		return true;
	}

	this.hasChanged = function() {
		return !isSame(savedData, currentData);
	}

	this.isEmpty = function() {
		return isSame(currentData, emptyData);
	}

	this.dataIsEmpty = function(data) {
		return isSame(data, emptyData);
	}

	this.updateStatus = function(statusString) {
		currentData.status = statusString;
	}

	this.updateSite = function(siteString) {
		currentData.site = $('#siteFilterBox select').val();
	}

	this.updateUris = function(uris) {
		currentData.uris = uris;
	}

	this.updateCategories = function(categories) {
		currentData.categories = categories;
	}
	this.updateUsers = function(users) {
		currentData.users = users;
	}

	this.updateLocales = function(locales) {
		currentData.locales = locales;
	}

	this.updateDates = function(start, end) {
		currentData.startDate = start;
		currentData.endDate = end;
	}

	this.updateSearchString = function(searchString) {
		currentData.searchString = searchString;
	}
	this.updateSavedDate = function(data) {
		savedData = $.extend(savedData, data);
	}
	this.getSavedData = function() {
		return savedData;
	}

	this.getCurrentData = function() {
		return currentData;
	}

	this.updateFollowing = function(f) {
		currentData.following = f;
	}

	function arraysEqual(ar1, ar2) {
		if (ar1.length != ar2.length) {
			return false;
		}
		for ( var i = 0; i < ar1.length; i++) {
			if (ar1[i] != ar2[i]) {
				return false;
			}
		}
		return true;
	}
}

function FilterDataObj(dataObj) {
	var data = {
		searchString : "",
		uris : [],
		users : [],
		locales : [],
		categories : [],
		status : "",
		startDate : "",
		endDate : "",
		following: "",
		site: $('#siteFilterBox select').val()
	};
	return $.extend(this, data, dataObj);
}
$(function() {
	C.ready();
});
LDSE.resizeCallbacks.languageBox = function() {
/*	$("#languageFilterBox > div > div > span").width(
			$("#languageFilterBox > div").width() - 30);*/
	if (C.odd) {
		C.summaryAndDetails.width("100%");
		$('.ldse-modal').css('width', 'auto');
	} else {
		C.summaryAndDetails.width("100.00001%");
		$('.ldse-modal').css('width', 'auto');
	}
	C.odd = !C.odd;
};

function getParameterByName(name) {
    name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]");
    var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
        results = regex.exec(location.search);
    return results == null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
}

function post(url) {
    window.location = url + "&form=" + $("#formSelector1").val();
};
function closeModal() {
    $("#modal1").trigger('close');
}

$(document).ready(function()
{
	var qsStatus = getParameterByName("qsStatus");
	var qsLocale = getParameterByName("qsLocale");
	var qsCategory = getParameterByName("qsCategory");
	if(qsStatus != "" || qsLocale != "" || qsCategory != "")
	{
		var jsonData = new FilterDataObj(C.filterObject.getSavedData());
		jsonData.status = qsStatus;
		jsonData.locales = qsLocale;
		jsonData.categories = [];
		jsonData.categories.push(qsCategory);

		sessionStorage.setObject('content-filters', jsonData);

		C.ready();
		C.applyFilterBtn.click();
	}
});
