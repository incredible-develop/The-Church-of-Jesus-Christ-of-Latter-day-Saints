var app = angular.module("LDSP", ['ldsp-ui', 'AppServices']);

app.controller("ContentManager", function ContentManager($scope, $content, $filter, $timeout){
    $scope.items = [[], [], {}, []];
    $scope.jsonData = {
        rsum : true,
        columnId : "",
        ascending: false,
        generateFacets: true,
        locales: [],
        status: "",
        startDate: "",
        endDate: "",
        uris: [""],
        users: [""]
    };
    $scope.currentLocales = "";
    $scope.currentStatus = "";
    $scope.pageInfo = {};
    $scope.currentPage = 1;
    $scope.pageSize = 25;
	$scope.totalPages = 0;
    $scope.clearFiltersButton = false;
	$scope.showFollowing = false;
    $scope.showUser = false;
    $scope.showDate = false;
    $scope.checkAll = false;
    $scope.showStatus = false;
    $scope.showLocale = false;
    $scope.showUri = false;
    $scope.getContent = function(append) {
        $scope.jsonData.pageIndex = 1;
        $content.getContent($scope.jsonData).then(function (data) {
        	if ( append ) {
                $scope.items[1] = $scope.items[1].concat(data[1]);
                console.log($scope.items);
            } else {
                $scope.items = data;
                $scope.currentPage = 1;
                $scope.items[0].unshift({
        			title: "Show All", name: ""
        		});
                console.log($scope.items);
            }
            $scope.pageInfo = data[2];
            if ( $scope.jsonData.generateFacets == true ) {
                $scope.jsonData.locales.push("");
                $scope.localeOptions = data[3];
                $scope.jsonData.generateFacets = false;
            }
			$scope.updateLimits();
			$scope.data = angular.copy($scope.jsonData);
        });
    };
    $scope.dialog = [];
    $scope.editContent = function(item) {
	    if ( item == undefined ) {
            item = $scope.allCheckedRows()[0];	        
	    }
        $scope.href = item.previewUrl;
		if ( item.fileType == "resources" ) {
			$scope.redirectToFrontEnd();
		} else if ( item.option && item.option !== "" ) {
            var href = sharedPrefix + "/form?lang=" + item.locale + "&id=" + item.id; 
		    document.location = href;
		} else {
			$scope.dialog.options = {
			    title: "Problem Editing Content",
			    body: "<p>You are attempting to edit content that was created using a previous version of LDS Publisher. Click OK to view this content in context and then choose to edit it.</p>",
			    buttons: [
                    {
                        title: "OK",
                        class: "primary ldse-responsive-button ldse-icon-check2",
                        ngclick: $scope.redirectToFrontEnd
                    },
                    {
                        title: "Cancel",
                        class: "ldse-responsive-button ldse-icon-ko-x",
                        ngclick: $scope.closeModal
                    }
			    ]
			};
			$scope.dialog.show = true;
		}
	};
	
    $scope.closeModal = function() {
        $scope.dialog.show = false;
    };
    $scope.redirectToFrontEnd = function redirectToFrontEnd(){
        window.location = $scope.href;
    };
    $scope.clearButton = false;
    $scope.getContent(false);
    $scope.clickStatus = function(status) {
        if ( status == undefined ) {
            status = { 
                name: $scope.jsonData.status
            };
        } else {
            $scope.currentStatus = status.name;
            $scope.getContent(false);
        }
        $scope.clearFiltersButton = true;
        $scope.jsonData.status = status.name;
        $scope.showStatus = true;
    };
    $scope.search = function () {
        $scope.jsonData.searchString = $scope.searchText;
        $scope.clearFiltersButton = true;
        $scope.getContent(false);
    };
    $scope.changeFollowing = function () {
        $scope.showFollowing = $scope.showFollowing === false ? true : false;
    };
    $scope.changeUriFilter = function () {
        $scope.showUri = $scope.showUri === false ? true : false;
    };
    $scope.changeStatus = function () {
        $scope.showStatus = $scope.showStatus === false ? true : false;
        if ( $scope.showStatus ) {
            if ( !$scope.jsonData.status == $scope.data.status ) {
                $scope.getContent(false);
            }
            $scope.jsonData.status = "";
            $scope.currentStatus = "";
            $scope.filterForm.$setPristine();
        }
    };
    $scope.changeLocale = function () {
        $scope.showLocale = $scope.showLocale === false ? true : false;
        if ( $scope.showLocale ) {
            $scope.jsonData.locales = [];
            $scope.filterForm.$setPristine();
            if ( !$scope.jsonData.locales == $scope.data.locales ) {
                $scope.getContent(false);
            }
        }
    };
    $scope.changeDateFilter = function () {
        $scope.showDate = $scope.showDate === false ? true : false;
        if ( $scope.showDate ) {
            $scope.filterForm.$setPristine();
            if ( !$scope.jsonData.startDate == $scope.data.startDate || !$scope.jsonData.endDate == $scope.data.endDate ) {
                $scope.getContent(false);
            }
        }
    };
    $scope.changeUserFilter = function () {
        $scope.showUser = $scope.showUser === false ? true : false;
        if ( !$scope.showUser ) {
            $scope.filterForm.$setPristine();
            if ( !$scope.jsonData.users == $scope.data.users ) {
                $scope.getContent(false);
            }
        }
    };
    $scope.changePageSize = function (pageSize) {
        $scope.currentPage = 1;
        $scope.pageSize = pageSize;
        $scope.jsonData.pageSize = $scope.pageSize;
        $(".change-page-size").attr("href", "#");
        $("#page-size-" + pageSize).removeAttr("href");
        $scope.updateLimits();
        $timeout(function () {
			$scope.setCheckAll();
		});
    };
    $scope.updateLimits = function () {
        $scope.startLimit = $scope.currentPage * $scope.pageSize;

        if ($scope.startLimit > $scope.items[1].length) {
            $scope.endLimit = -1 * ($scope.items[1].length - (($scope.currentPage - 1) * $scope.pageSize));
        } else {
            $scope.endLimit = -1 * $scope.pageSize;
        }
    };
    
    $scope.changePage = function (direction) {
        $scope.currentPage = $scope.currentPage + direction;
        $scope.jsonData.pageIndex = $scope.currentPage;
        $scope.updateLimits();
        if ( $scope.pageSize * $scope.currentPage > $scope.items[1].length ) {
            $scope.getContent(true);
        }
        $timeout(function () {
			$scope.setCheckAll();
		});
    };
    $scope.updateSelect = function (id) {
        $("#" + id).closest("span").find("span.text").text($("#" + id).find("option:selected").text());
    };
    $scope.setCheckAll = function () {
        $scope.checkall = $scope.pageCheckedRows().length == $scope.pageSize;
    };
    $scope.pageRows = function () {
        return $scope.items.slice(($scope.currentPage - 1) * $scope.pageSize, $scope.currentPage * $scope.pageSize);
    };
    $scope.pageCheckedRows = function () {
        return $filter('filter')($scope.pageRows(), {
            checked: true
        });
    };
    $scope.statusFilter = function (status) {
        if ( status.name == "" ) {
            return false;
        }
        if ( $scope.jsonData.status !== "" ) {
            if ( status.name == $scope.jsonData.status ) {
                return true;
            };
            return false;
        };
        return true;
    };
    $scope.cancelFilters = function() {
        $scope.jsonData = $scope.data;
        $scope.filterForm.$setPristine();
    };
    $scope.clearFilters = function() {
        $scope.jsonData.status = "";
        $scope.currentStatus = "";
        $scope.jsonData.searchString = "";
        $scope.searchText = "";
        $scope.jsonData.locales = [];
        $scope.jsonData.users = [];
        $scope.jsonData.uris = [];
        $scope.getContent(false);
        $scope.showStatus = false;
        $scope.showLocale = false;
        $scope.showUri = false;
	    $scope.showFollowing = false;
        $scope.showUser = false;
        $scope.showDate = false;
        $scope.filterForm.$setPristine();
        $scope.clearFiltersButton = false;
    };
    $scope.applyFilters = function() {
        $scope.currentLocales = $scope.jsonData.locales;
        $scope.currentStatus = $scope.jsonData.status;
        $scope.filterForm.$setPristine();
        $scope.getContent(false);
        $scope.clearFiltersButton = true;
    };
    $scope.changeSort = function (name, index) {
        if ( $scope.jsonData.columnId == name) {
            $scope.jsonData.ascending = !$scope.jsonData.ascending;
            $scope.getContent(false);
        } else {
            $scope.jsonData.columnId = name;
            $scope.jsonData.ascending = false;
            $scope.getContent(false);
        }
    };
    $scope.setCheckAll = function () {
        $scope.checkAll = $scope.pageCheckedRows().length == $scope.pageSize;
    };
    $scope.checkAllBoxes = function(check) {
        $scope.checkAll = $scope.checkAll == false ? true : false;
        angular.forEach($scope.pageRows(), function (item) {
            item.checked = $scope.checkAll;
        });
    };
    $scope.pageRows = function () {
		return $filter("filter")(
		$scope.items[1], {
			visible: true
		})
	};
    $scope.pageCheckedRows = function () {
		return $filter("filter")(
		$scope.pageRows(), {
			checked: true
		})
	};
	$scope.allCheckedRows = function () {
		return $filter("filter")($scope.items[1], {
			checked: true
		});
	};
	$scope.showActionButton = function (action) {
		actionCount = 0;
      	angular.forEach($scope.allCheckedRows(), function (row) {
      		if ( row.checked == true ) {
      			actionCount++;
      		}
      	});
      	return actionCount === $scope.allCheckedRows().length && $scope.allCheckedRows().length !== 0;
	};
	$scope.showPublishButton = function () {
    	publishCount = 0;
      	angular.forEach($scope.allCheckedRows(), function (row) {
      		if ( row.checked == true ) {
      			publishCount++;
      		}
      	});
      	return publishCount === $scope.allCheckedRows().length && $scope.allCheckedRows().length !== 0;
	};
	$scope.showEditButton = function () {
    	checkCount = 0;
      	angular.forEach($scope.allCheckedRows(), function (row) {
      		if ( row.checked == true ) {
      			checkCount++;
      		}
      	});
      	return checkCount == 1 && checkCount === $scope.allCheckedRows().length && $scope.allCheckedRows().length !== 0;
	};
	$scope.showDeleteButton = function () {
    	checkCount = 0;
      	angular.forEach($scope.allCheckedRows(), function (row) {
      		if ( row.checked == true ) {
      			checkCount++;
      		}
      	});
      	return checkCount === $scope.allCheckedRows().length && $scope.allCheckedRows().length !== 0;
	};
	$scope.getCheckedIds = function(selectedItems) {
        ids = [];
	    angular.forEach(selectedItems, function(item) {
	        ids.push(item.id);
	    });
	    return ids;
	};
	$scope.removeItems = function(ids) {
	    angular.forEach(ids, function(id) {
	        $scope.items[1]
	    });
	};
	$scope.performAction = function (action) {
        $scope.selectedItems = $scope.allCheckedRows();
        $scope.postData = {
            ids: $scope.getCheckedIds($scope.selectedItems),
            action: action
        }
	    $content.performAction($scope.postData).then(function(data) {
            if ( action == "ldse:delete" ) {
                $scope.removeItems($scope.postData.ids);
            }
            angular.forEach($scope.items[1], function (item) {
                 if ( $scope.postData.ids.indexOf(item.id) !== -1 ) {
                     item.status = "published";
                     item.checked = false;
                 }
            });
	    });
	};
});