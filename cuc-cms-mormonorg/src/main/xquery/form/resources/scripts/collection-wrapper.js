(() => {
    'use strict';
    var tApp = angular.module("LDSP");
    tApp.component('collectionWrapper', {
/*        require: {
            ts: '^titanSearch'
        },*/
        bindings: {
            'json': '<'
        },
        templateUrl: sharedPrefix + '/resources/components/form/collection-wrapper.html',
        controller: function($scope, $element, $attrs) {
            var self = this;
            self.json = $scope.json;
            self.selected = {};
            self.setSelected = (id, title) => {
                //item.result.selected = item.result.selected == true ? false : true;
                self.selected.id = self.selected.id != id ? id : '';
                self.ts.setSelected(self.selected.id, title);
            };
            self.add = () => {
                document.getElementById('titanModal').style.display = 'block';
                document.getElementsByClassName('ldse-modal-backdrop')[0].style.display = 'block';
                document.body.scrollTop = document.documentElement.scrollTop = 0;
/*                self.items.items[0].push({'id': id, 'title': title})*/
            };
        }
    });
})();