(() => {
    'use strict';
    var p = angular.module("LDSP");
    p.component('pagination', {
        require: {
            ts: '^titanSearch'
        },
        bindings: {
            'pages': '<'
        },
        templateUrl: sharedPrefix + '/ice/resources/ajax/pagination.html',
        controller: function($scope, $element, $attrs) {
            var ctrl = this;
            ctrl.pages = $scope.pages;
            ctrl.pageChange = $scope.change;
            ctrl.nextPage = () => {
                var page = ctrl.pages.page + ctrl.pages.rows;
                var selected = ctrl.pages.selected + 1;
                ctrl.ts.pageChange(page, selected);
            };
            ctrl.previousPage = () => {
                var page = ctrl.pages.page - ctrl.pages.rows;
                var selected = ctrl.pages.selected - 1;
                ctrl.ts.pageChange(page, selected);
            };
            ctrl.setPage = (selected) => {
                var page;
                if ( selected > ctrl.pages.selected ) {
                    var add = ( selected - ctrl.pages.selected ) * 20;
                    page = ctrl.pages.page + add;
                } else {
                    var subtract = ( ctrl.pages.selected - selected ) * 20;
                    page = ctrl.pages.page - subtract;
                }
                ctrl.ts.pageChange(page, selected);
            }
        }
    });
})();