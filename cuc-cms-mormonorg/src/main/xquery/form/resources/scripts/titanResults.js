(() => {
    'use strict';
    var tApp = angular.module("LDSP");
    tApp.component('titanResults', {
        require: {
            ts: '^titanSearch'
        },
        bindings: {
            'results': '='
        },
        templateUrl: sharedPrefix + '/ice/resources/ajax/titanResults.html',
        controller: function($scope, $element, $attrs) {
            var self = this;
            self.results = $scope.results;
            self.selected = {};
            self.setSelected = (item) => {
                //item.result.selected = item.result.selected == true ? false : true;
                self.selected.id = self.selected.id != item.id ? item.id : '';
                self.ts.setSelected(item);
            };
        }
    });
})();