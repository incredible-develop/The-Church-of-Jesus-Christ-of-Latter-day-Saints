(() => {
    'use strict';
    var tApp = angular.module("LDSP");
    tApp.component('titanCollectionItems', {
/*        require: {
            ts: '^titanSearch'
        },*/
        bindings: {
            'items': '<'
        },
        templateUrl: sharedPrefix + '/resources/components/form/titan-collection-items.html',
        controller: function($scope, $element, $attrs) {
            var self = this;
            self.items = $scope.items;
            self.selected = {};
            self.setSelected = (id, title, path) => {
                //item.result.selected = item.result.selected == true ? false : true;
                self.selected.id = self.selected.id != id ? id : '';
                self.ts.setSelected(self.selected.id, title, path);
            };
            self.add = () => {
                document.getElementById('titanModal').style.display = 'block';
/*                self.items.items[0].push({'id': id, 'title': title})*/
            };
        }
    });
})();