(() => {
    'use strict';
    var fs = angular.module("LDSP");
    fs.component('facets', {
        bindings: {
            'facetSections': '=',
            'updateFacets': '&'
        },
        templateUrl: sharedPrefix + '/content-admin/resources/html/facets.html',
        controller: function($scope, $http) {
            var self = this;
            self.facetSections = $scope.facetSections;
            self.selections = [];
            self.update = (selected, index) => {
                selected.index = index;
                self.updateFacets({selected: selected});
            };
        }
    });
})();