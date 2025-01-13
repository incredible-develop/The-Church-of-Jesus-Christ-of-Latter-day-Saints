(() => {
    'use strict';
    var fr = angular.module("LDSP");
    fr.component('facetResults', {
        bindings: {
            'files': '<',
            'templates': '<'
        },
        templateUrl: sharedPrefix + '/content-admin/resources/html/facet-results.html',
        controller: function($scope, $http) {
            var self = this;
            self.files = $scope.files;
            self.selected = [];
            self.statuses = [];
            self.updateItems = (status) => {
                var selected = [];
                var selectedIds = [];
                angular.forEach(self.files, function(value, key) {
                    if ( value.checked == true ) {
                        selected.push(value.uri);
                        selectedIds.push(value.dataId);
                    }
                })
                let templateSelector = document.getElementById('template-option');
                let template = templateSelector.options[templateSelector.selectedIndex].getAttribute('value');
                let site = self.getParam('site');
                $http.post('/cms/content-admin/ajax/bulk-update-content?lang=eng&selected=' + selected + '&site=' + site + '&status=' + status + '&template=' + template + '&titanIds=' + selectedIds).then(function(data) {
                    document.getElementsByTagName('html')[0].classList.remove('loading');
                    var newStatus = ''
                    if ( status == 'ldse:preview' ) {
                        newStatus = 'preview'
                    } else if ( status == 'ldse:publish' ) {
                        newStatus = 'published'
                    } else if ( status == 'ldse:unpublish' ) {
                        newStatus = 'unpublished'
                    } else if ( status == 'ldse:remove' ) {
                        newStatus = ''
                    }
                    angular.forEach(self.files, function(file, key) {
                        if ( file.checked ) {
                            file.status = newStatus
                            file.checked = false
                        }
                    });
                    self.selected = [];
                    self.statuses = [];
                    alert('Items have been updated');
                });
            };
            self.getParam = (sParam) => {
                var sPageURL = decodeURIComponent(window.location.search.substring(1)),
                    sURLVariables = sPageURL.split('&'),
                    sParameterName,
                    i;
                for (i = 0; i < sURLVariables.length; i++) {
                    sParameterName = sURLVariables[i].split('=');
                    if (sParameterName[0] === sParam) {
                        return sParameterName[1] === undefined ? true : sParameterName[1];
                    }
                }
            };
            self.checkAll = () => {
                if ( self.checkAllChecked == true ) {
                    angular.forEach(self.files, function(value, key) {
                        value.checked = true;
                        self.selected.push(value.uri);
                        self.statuses.push(value.status);
                    });
                } else {
                    angular.forEach(self.files, function(value, key) {
                        value.checked = false;
                    });
                    self.selected = [];
                    self.statuses = [];
                }
            };
            self.checkButtons = (file) => {
                if ( file.checked == true ) {
                    self.selected.push(file.uri);
                    self.statuses.push(file.status);
                } else if ( file.checked == false ) {
                    var index = self.selected.indexOf(file.uri);
                    var statusIndex = self.statuses.indexOf(file.status);
                    self.selected.splice(index, 1);
                    self.statuses.splice(statusIndex, 1);
                }
            };
        }
    });
})();