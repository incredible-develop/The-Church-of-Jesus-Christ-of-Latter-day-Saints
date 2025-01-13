var appServices = angular.module("AppServices", []);

var services = {};
services.Content = function($http, $q){
    var _ = this;

/*
    this.delete = function(name) {
        var defer = $q.defer();

        $http({method: 'POST', url: sharedPrefix + "/scripts/ajax/delete?lang=eng", params:{name:name}})
            .success(function(data, status) {
                defer.resolve(data);
            });
        return defer.promise;
    };
*/
    this.getContent = function(jsonData) {
        var defer = $q.defer();

        $http({method: 'POST', url: sharedPrefix + "/new-content-manager/ajax/search?lang=eng", params:jsonData})
            .success(function(data, status) {
                defer.resolve(data);
            });
        return defer.promise;
    };
    this.performAction = function(postData) {
        var defer = $q.defer();

        $http({method: 'POST', url: sharedPrefix + "/new-content-manager/ajax/apply-action?lang=eng", params:postData})
            .success(function(data, status) {
                defer.resolve(data);
            });
        return defer.promise;
    };

};
appServices.service('$content', services.Content);