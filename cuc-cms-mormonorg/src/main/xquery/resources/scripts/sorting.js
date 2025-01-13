
function sortColumn(column) {
    var columnHead = $(column).closest("th.sorts"),
        columnName = columnHead.attr("data-name"),
        hasDesc = columnHead.hasClass("desc"),
        hasAsc = columnHead.hasClass("asc"),
        hasSort = columnHead.hasClass("sort"),
        columnType = columnHead.data("sort-type") || "string",
        sortDir;
	    if (!hasDesc && !hasAsc && !hasSort) {
		  columnHead.addClass("sort desc")
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
	var item = $(".ldse-sortable-tr:visible").clone();
	function sortRow(a,b) {
	    var tdA = $(a).find("td[data-sort='" + columnName + "']"), 
	        dataA = tdA.data("sort-value") || tdA.text(),
	        tdB = $(b).find('td[data-sort="'+columnName+'"]'),
	        dataB = tdB.data("sort-value") || tdB.text();
  		if ( columnType == "integer" ) {
  		    dataA = parseInt(dataA);
  		    dataB = parseInt(dataB);
  		} else if ( columnType == "date" ) {
  		    dataA = new Date(dataA);
  		    dataB = new Date(dataB);
  		} else {
  		    dataA = dataA.toLowerCase();
  		    dataB = dataB.toLowerCase();
  		}
  		if ((sortDir && dataB > dataA) ||(! sortDir && dataA > dataB)) {
  			return 1/*-1 is b before a*/
  		} else if ((sortDir && dataA > dataB) ||(! sortDir && dataB > dataA)) {
  			return -1;
  			/*a before b*/
  		} else {
  			return 0;
  			/*no sort*/
  		}
	}
	item.sort(sortRow);
	$('#detail-table tbody').html(item);
	item =[];
}

$(document).ready( function () {
    var trs = $("#detail-table-body").find("tr");
    $("#filter-search, #searchButton").on("keyup change blur click", function () {
        var searchValue = $("#filter-search").val().toLowerCase(),
            values = trs.each(function(){
                var text = $(this).text().toLowerCase();
                if (text.indexOf(searchValue) != -1) {
                    $(this).show();
                } else {
                    $(this).hide();
                }
            });
    });
});