(() => {
    'use strict';
    var f = angular.module("LDSP");
    f.component('facet', {
        bindings: {
            'facetSection': '<',
            'updateFacets': '&'
        },
        templateUrl: sharedPrefix + '/content-admin/resources/html/facet.html',
        controller: function($scope) {
            var self = this;
            self.facetSection = $scope.facetSection;
            self.updateEverything = (selected) => {
                self.updateFacets({selected: selected});
            };
        }
    });
})();