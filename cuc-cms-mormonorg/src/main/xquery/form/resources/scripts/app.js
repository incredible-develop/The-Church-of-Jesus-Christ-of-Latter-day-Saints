var app = angular.module("LDSP", ['ldsp-ui']);

app.service('$form', function ($http, $q) {
    this.saveForm = function(postData) {
        var defer = $q.defer();
        $http({method: 'POST', url: sharedPrefix + "/form/create-form?lang=eng", params:postData})
            .success(function(data, status) {
                defer.resolve(data);
            });
        return defer.promise;
    };
});

app.controller("formBuilder", function formBuilder($scope, $form, $filter, $timeout){
    $scope.form = form.formTemplate;
    $scope.save = function() {
        var postData = {
            form: $scope.form
        }
        $form.saveForm(postData).then(function (data) {});
    };
    $scope.add = function(item) {
        if ( item == undefined ) {
            item = new Array();
            item.push({"name": ""});
        } else {
            item.push({})
        }
    }
});