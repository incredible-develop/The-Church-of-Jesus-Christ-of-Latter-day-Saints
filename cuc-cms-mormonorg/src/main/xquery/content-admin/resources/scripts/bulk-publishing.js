(() => {
    'use strict';
    angular.module('LDSP', []);
    var bp = angular.module("LDSP");
    bp.component('bulkPublishing', {
        templateUrl: '/cms/content-admin/resources/html/bulk-publishing.html',
        controller: function($scope, $http) {
            var self = this;
            self.facetSections = {
                facets: []
            };
            self.selections = [];
            self.update = (selected) => {
                self.selections.length = selected.index;
                self.selections.push(selected.id);
                selected = selected.id;
                self.filter();
            };
            self.filter = () => {
                document.getElementsByTagName('html')[0].classList += ' loading';
                $http.get('/cms/content-admin/ajax/update-publishing?lang=eng&selected=' + self.selections + '&site=' + site).then(function(data) {
                    self.facetSections.facets.length = self.selections.length;
                    if ( data.data.files.files ) {
                        self.files = data.data.files.files;
                    }
                    if ( data.data.facets.options ) {
                        self.facetSections.facets.push(data.data.facets);
                    }
                    if ( data.data.templates.length > 0 ) {
                        self.templates = data.data.templates
                    }
                    document.getElementsByTagName('html')[0].classList.remove('loading');
/*                    self.updatePagination(data.data.pages[0]);*/
                });
            };
            self.filter();
        }
    });
})();