var DetailTable = {
	init: function () {
		DetailTable.Checkboxes.init();
	},
	
	"export": function (title) {
		var $trs = $("#detail-table tbody input:checkbox:checked").closest("tr");
		var $headers = $("#detail-table thead th");
		
		function Rows($trs, $headers) {
			var rows =[];
			
			$trs.each(function () {
				var row = new Row($(this), $headers);
				rows.push(row);
			});
			
			this.rows = rows
		}
		
		function Row($row, $headers) {
			var row =[];
			
			$headers.each(function (index) {
				var header = $(this).text().toUpperCase();
				
				if (header != "CHECK" && header != "") {
					var value = $row.find("td:nth-child(" + (index + 1) + ")").text() || $row.find("td:nth-child(" + (index + 1) + ") input").val();
					value = value.trim();
					var cell = new Cell(header, value);
					
					row.push(cell);
				}
			});
			
			this.row = row;
		}
		
		function Cell(header, value) {
			this[header] = value;
		}
		
		var rows = new Rows($trs, $headers)
		var jsonString = JSON.stringify(rows);
		var jsonStringLength = jsonString.length;
		var breakOn = 10000;
		var sets = parseInt(jsonStringLength / breakOn) + (jsonStringLength % breakOn > 0 ? 1: 0);
		var inputs =[];
		
		for (var i = 0; i < sets; i++) {
			var start = breakOn * i;
			var subset = jsonString.slice(start, breakOn * (i + 1));
			
			inputs.push("<textarea name='json'>" + subset + "</textarea>");
		}
		
		
		var form = "<form id='exportForm' action='" + sharedPrefix + "/shared/lds-edit/resources/ajax/export?lang=eng' method='post'>" +
		inputs.join("") +
		"<input type='hidden' name='title' value='" + title + "'/>" +
		"</form>";
		
		$("body").append(form);
		$("#exportForm").submit().remove();
	},
	
	Pagination: {
		pageSize: 25,
		
		currentPage: 1,
		
		totalPages: 0,
		
		trs: function () {
			return $("#detail-table tbody tr");
		},
		
		trCount: function () {
			return DetailTable.Pagination.trs().length;
		},
		
		changePageSize: function (newSize) {
			DetailTable.Pagination.pageSize = newSize;
			$(".ldse-pagination--shownum a").attr("href", "#");
			$("#pageSize" + newSize).removeAttr("href");
			$(".pageSize" + newSize).removeAttr("href");
			var totalPages = DetailTable.Pagination.updateTotalPages();
			DetailTable.Pagination.currentPage = 1;
			$("#currentPage").text(DetailTable.Pagination.currentPage);
			$(".currentPage").text(DetailTable.Pagination.currentPage);
			DetailTable.Pagination.showPage();
			DetailTable.Checkboxes.setCheckAll();
			DetailTable.Checkboxes.wireup();
		},
		
		updateTotalPages: function () {
			var totalPages = parseInt(DetailTable.Pagination.trCount() / DetailTable.Pagination.pageSize) + (DetailTable.Pagination.trCount() % DetailTable.Pagination.pageSize > 0 ? 1: 0);
			DetailTable.Pagination.totalPages = totalPages;
			$("#totalPages").text(totalPages);
			$(".totalPages").text(totalPages);
		},
		
		changePage: function (direction, getMoreRows) {
			DetailTable.Pagination.currentPage += direction;
			$("#currentPage").text(DetailTable.Pagination.currentPage);
			$(".currentPage").text(DetailTable.Pagination.currentPage);
			DetailTable.Pagination.showPage();
			
			if (DetailTable.Pagination.trs().filter(":visible").length == 0) {
				if (typeof (getMoreRows) == "function") {
					getMoreRows();
					DetailTable.Checkboxes.wireup();
				}
			} else {
				DetailTable.Checkboxes.setCheckAll();
			}
		},
		
		setArrows: function () {
			$("#prevPage").toggle(DetailTable.Pagination.currentPage > 1);
			$(".prevPage").toggle(DetailTable.Pagination.currentPage > 1);
			$("#nextPage").toggle(DetailTable.Pagination.currentPage < DetailTable.Pagination.totalPages);
			$(".nextPage").toggle(DetailTable.Pagination.currentPage < DetailTable.Pagination.totalPages);
		},
		
		showPage: function (page) {
			if (typeof (page) != "undefined") DetailTable.Pagination.currentPage = page;
			DetailTable.Pagination.trs().hide();
			DetailTable.Pagination.trs().slice((DetailTable.Pagination.currentPage - 1) * DetailTable.Pagination.pageSize, DetailTable.Pagination.currentPage * DetailTable.Pagination.pageSize).show();
			DetailTable.Pagination.setArrows();
		}
	},
	
	Checkboxes: {
		init: function () {
			//DetailTable.Checkboxes.wireup();
		},
		
		checkAll: function () {
			return $("#details-checkall");
		},
		
		all: function () {
			return $("#detail-table tbody input.rowSelect:checkbox");
		},
		
		checked: function () {
			return $(DetailTable.Checkboxes.all()).filter(":checked");
		},
		
		visible: function () {
			return $(DetailTable.Checkboxes.all()).filter(":visible");
		},
		
		setCheckAll: function () {
			if (typeof (DetailTable.Checkboxes.checkAll()[0]) != "undefined") {
				$(DetailTable.Checkboxes.checkAll())[0].checked = $(DetailTable.Checkboxes.visible()).filter(":checked").length == $(DetailTable.Checkboxes.visible()).length && $(DetailTable.Checkboxes.visible()).length > 0;
			}
		},
		
		wireup: function () {
			$(DetailTable.Checkboxes.all()).on(
			"click",
			function () {
				DetailTable.Checkboxes.fixPosition($(this));
				DetailTable.Checkboxes.setCheckAll();
			});
			
			$(DetailTable.Checkboxes.checkAll()).on( "click", function () {
				DetailTable.Checkboxes.fixPosition($(this));
				$(DetailTable.Checkboxes.visible()).each(
				function () {
					$(this).attr("checked", $(DetailTable.Checkboxes.checkAll())[0].checked);
				});
			});
		},
		
		fixPosition: function($this) {
			if($.browser.webkit) {
				$this.css("position", "inherit");
				window.setTimeout(function ($this) {
					$this.css("position", "absolute");
				},
				0,
				$this);
			}
		}
	},
	
	Sorting: {
		sort: function (getRows) {
			DetailTable.Pagination.currentPage = 1;
			$("#detail-table tbody tr").remove();
			
			if (typeof (getRows == "function")) {
				getRows();
			}
		}
	},
	
	RealCount: {
	    count: 0
	}
};

$(document).ready(function () {
	DetailTable.init();
});