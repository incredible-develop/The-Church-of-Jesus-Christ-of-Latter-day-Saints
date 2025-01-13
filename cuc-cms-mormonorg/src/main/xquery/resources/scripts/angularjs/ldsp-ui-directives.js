'use strict';

angular.module('ldsp-ui', [])
	.directive('a', function() {
	    return {
	        restrict: 'E',
	        link: function(scope, elem, attrs) {
	            if(attrs.ngClick && attrs.href === '#stopProp') {
	                elem.on('click', function(e){
	                    e.preventDefault();
	                });
	            }
	        }
	   };
	})
 /*
 * dialog Directive usage:
 * Place <dialog/> element in markup.
 * Options available in controller:
 * 	$scope.dialog.options.title - Title of dialog
 * 	$scope.dialog.options.body - Html for body of dialog, can include Angular markup
 * 	$scope.dialog.options.buttons - An array of button objects:
 * 		{
 * 			title: Button Title,
 * 			class: Any class to apply to button. ldse-button is automatically applied,
 * 			ngclick: Angular expression
 * 		}
 * 	$scope.dialog.options.width - Width of dialog
 * 	$scope.dialog.show - true || false - shows or hides the dialog
 */
	.directive("dialog", [function dialog() {
		return {
			replace: true,
			restrict: "E",
            scope: false,
			template:
				'<section>' +
					'<div class="ldse-modal-backdrop" ng-show="dialog.show"></div>' +
					'<section id="dialogBox" class="ldse-modal better" ng-show="dialog.show" style="width:{{dialog.options.width}}px;left:{{dialog.left}}px;">' +
						'<header class="ldse-section--header">' +
							'<h2>{{dialog.options.title}}</h2>' +
						'</header>' +
						'<div class="ldse-section--body ldse-form">' +
							'<div dynamic="dialog.options.body"></div>' +
							'<div class="ldse-form-buttons" style="margin-top:20px;">' +
								'<button ng-repeat="button in dialog.options.buttons" type="button" class="ldse-button {{button.class}}" ng-click="button.ngclick()">{{button.title}}</button>' +
							'</div>' +
						'</div>' +
					'</section>' +
				'</section>',
			link: function (scope, element, attrs) {

				scope.dialog = {
					options: {
						title: "",
						body: "",
						buttons:[],
						width: 350
					},
					show: false,
					left: (window.innerWidth - 350) / 2
				};

				scope.$watch("dialog.options.width", function() {
					if(typeof(scope.dialog.options.width) == "undefined") {
						scope.dialog.options.width = 350;
					}
					scope.dialog.left = (window.innerWidth - scope.dialog.options.width) / 2;
				});
			}
		}
        element.draggable();
	}])
	.directive("dynamic", ["$compile", function ($compile) {
		return {
			restrict: "A",
            scope: false,
			replace: true,
			link: function (scope, element, attrs) {
				scope.$watch(attrs.dynamic, function (html) {
					element.html(html);
					$compile(element.contents())(scope);
				});
			}
		}
	}])
	.directive("messagebox", ["$timeout", function($timeout) {
		return {
			replace: true,
			restrict: "E",
			template: '<section class="ldse-alert" ng-show="messagebox.show">' +
						'<span class="ldse-alert-text">{{messagebox.message}}</span>' +
						'<span class="ldse-alert-close ldse-icon-x ldse-icon" ng-click="messagebox.show=false;">Close</span>' +
					'</section>',
			link: function (scope, el, attrs) {
				var messageboxTimeout;
				$(".ldse-alert").off("click");

				scope.messagebox = {
					message: "Default Message",
					show: false
				}

				scope.$watch("messagebox.show", function () {
					if (scope.messagebox.show) {
						$timeout.cancel(messageboxTimeout);

						messageboxTimeout = $timeout(function () {
							scope.messagebox.show = false;
						},
						5000);
					} else {
						$timeout.cancel(messageboxTimeout);
					}
				});
			}
		}
	}])
	.directive('selectBox', function(){
	    return {
	        replace: true,
	        restrict: 'E',
	        scope: false,
	        template: function (element, attrs) {
	        	/*
	        	 * This allows the passthrough of any attribute from the markup.
	        	 * I found that having ng-options defined in the markup was
	        	 * breaking the generated select. ng-options needs to be passed in as
	        	 * optexp and it gets transformed into ng-options here.
	        	*/

	        	var attributes = [];

	        	for(var prop in attrs.$attr) {
	        		if(["optexp"].indexOf(prop) == -1) {
		        		attributes.push(attrs.$attr[prop] + "='" + attrs[prop].replace(/'/g, "&apos;") + "'");
		        	} else {
		        		if("optexp" == prop) {
		        			attributes.push("ng-options='" + attrs["optexp"].replace(/'/g, "&apos;") + "'");
		        		}
		        	}
	        	}

	        	/*
	        	 * This allows us to inject any extra classes needed into a class
	        	 * attribute, wether or not one was passed in.
	        	 */
	        	attributes.push("ng-class='{angular:true}'");

	            return '<span class="select">' +
							'<span class="text"></span>' +
							'<span class="arrow"> </span>' +
							//'<select class="angular" name="' + attrs.name + '" ' + 'ng-model="' + attrs.ngModel + '" ' + 'ng-options="' + attrs.optexp + '"' + ((attrs.required) ? ' required' : '') + '></select>'+
							'<select ' + attributes.join(" ") + '></select>' +
						'</span>'
	        },
	        link: function (scope, el, attrs) {
	        	if (!$.isArray(attrs.ngModel)) {
	        		attrs.ngModel = [];
        		}
	        	var span = el.children('.text'),
	        		select = el.children('select'),
	        		newWidth;

	        	select.css({position:"absolute", width:"auto", opacity: 0.001, top:0, left:0});

                function updateWidth() {
                	var width = attrs.width || "100%";
                	/*var temp = select.clone();
    				temp.css({
    					position:"absolute",
    					top:"-1000em",
    					width:"auto"
    				}).appendTo("body");

    				newWidth = temp.outerWidth(false);
    				if (newWidth > 150 ) { newWidth = 150; }
    				else if (newWidth < 50 ) { newWidth = 50; }*/
    				span.css({width: width});
    				select.width({width: width});
    				//temp.remove();
                }

	            scope.$watch(attrs.ngModel, function () {
	            	//updateWidth();
					span.text( $("option:selected", el).text() );
	            });
	            scope.$watch(
	            		function(){ return $("option:selected", el).text(); },
	            		function (newValue, oldValue) {
			            	//updateWidth();
							span.text( newValue );
            			}
        		);
	            updateWidth();
	        }
	    }
	})
	.filter('multiselectOptions', function() {
		return function(options, values, index) {
			var array = [],
				y = 0,
				selected = false,
				value = values[index],
				optionsLength = 0;
			if(options && options.length) {
				optionsLength = options.length;
			}
			for (var i = 0; i < optionsLength; i++) {
				var option = options[i];
				selected = false;
				if (option == value || value == option.value) {
					array[y] = options[i];
					y++;
				} else {
					for (var j = 0; j < values.length; j ++){
						var v = values[j];
						if ( option == v || v == option.value ) {
							selected = true;
							break;
						}
					}
					if (!selected) {
						array[y] = options[i];
						y++;
					}
				}
			}
			return array;

		}
	})
	.directive('multiBox', function(){
	    return {
	        replace: true,
	        restrict: 'E',
	        scope: {
	        	value: '=',
	        	options: '='
	        },
	        template: function (element, attrs) {
	            return '<div class="multiselect-wrapper">' +
	            	        '<div ng-repeat="v in value" class="wrapper ui-multiSelect ui-widget">' +
		        	        	'<a href="#d" class="remover" ng-click="remove($index);"style="opacity: 1; display: inline;">' +
		        	        		'<span class="ldse-icon ldse-icon-ko-remove">Remove this row</span>' +
		        	        	'</a>'+
		        	        	'<select-box name="" class="multiselect" ng-model="value[$index]" optexp="o.value||o as o.label||o group by o.group for o in options | multiselectOptions:value:$index"></select-box>' +
		            		'</div>' +
	        	        	'<a href="#d" ng-hide="value.length == options.length"class="adder" ng-click="add()">' +
        	        			'<span class="ldse-icon-ko-add">Add Filter</span>' +
        	        		'</a>' +
	            	   '</div>';
	        },
	        link: function (scope, el, attrs) {
	        	scope.add = function() {
	        		if (!$.isArray(scope.value)) {
	        			scope.value = [];
	        		}
	        		scope.value.push( {} );
	        	};
	        	scope.remove = function (index) {
	        		scope.value.splice(index, 1);
	        	};
	        }
	    }
	})
	.directive('ngDatepicker', function () {
		return {
			restrict: 'A',
			transclude: true,
			scope: {
			      date: '='
			},
			link : function (scope, element, attrs) {

				function updateDate()  {
						var altFormat = element.datepicker('option', 'altFormat'),
							currentDate = element.datepicker('getDate'),
							formatedDate = $.datepicker.formatDate(altFormat, currentDate);
						scope.date = formatedDate;

				}
				element.datepicker({
					onSelect: function (dateText, inst) {
						updateDate();
						attrs.ngModel = dateText;
						scope.$apply();
					},
					altFormat : "yy-mm-dd"
				}).on("blur",function(){
					updateDate();
					scope.$apply();
				});
				scope.$watch(attrs.date, function () {
					var parsedDate = "";
                    if ( scope.date && scope.date != undefined && scope.date != "") {
                        parsedDate = $.datepicker.parseDate('yy-mm-dd', scope.date);
                    }
					element.datepicker('setDate', parsedDate);
	            });
			}
		}
	})
	.service("Ajax",[ "$http", "$q", function Ajax ($http, $q) {
		this.Server = function (settings) {
			var defer = $q.defer();

			$http(
			settings).success(function (data, status) {
				defer.resolve({
					data: data, status: status
				});
			}).error(function (error, status) {
				defer.resolve({
					data: error, status: status
				});
			});

			return defer.promise;
		};
	}])
    .directive("multiText",[ "$timeout", function ($timeout) {
        return {
            replace: true,
            restrict: "E",
            scope: {
                value: "@",
                model: "="
            },
            template: function (element, attrs) {
                return '' +
                    '<div>' +
                    '   <div ng-repeat="arrayValue in model track by $index" class="wrapper ui-multiSelect ui-widget">' +
                    '       <a href="#" class="remover" ng-click="RemoveText($index);" style="opacity: 1; display: inline;">' +
                    '           <span class="ldse-icon ldse-icon-ko-remove">Remove this row</span>' +
                    '       </a>' +
                    '       <input type="text" style="display:inline;" ng-model="model[$index]" />' +
                    '   </div>' +
                    '   <a href="#" class="adder" ng-click="AddText()">' +
                    '      <span class="ldse-icon-ko-add">Add Filter</span>' +
                    '   </a>' +
                    '</div>';
            },
            link: function (scope, element, attrs) {
                scope.AddText = function () {
                    if (scope.model.indexOf("") === -1) {
                        scope.model.push("");
                    }
                };
                scope.RemoveText = function (index) {
                    scope.model.splice(index, 1);
                };
            }
        }
    }])
    .filter("setvisible", function () {
    	return function (collection, visible) {
    		var array = [];
    		angular.forEach(collection, function (item) {
    			item.visible = visible;
    			array.push(item);
    		});
    		return array;
    	}
    })
    /*
     * Controls classes on the parent <th> when the <a> is clicked. 
     */
    .directive("sortOn", function () {
    	return {
    		restrict: "A",
    		link: function (scope, element, attrs) {
    			element.bind("click", function () {
    				var parentTh = this.parentElement;
    				var ths = this.parentElement.parentElement.getElementsByTagName("th");
    				
    				if(typeof(scope.reverse) === "undefined") {
    					scope.reverse = true;
    				}
    				
    				if(scope.sorton !== attrs.sortOn) {
	    				scope.sorton = attrs.sortOn;
    					scope.reverse = false;
    				} else {
	    				scope.reverse = !scope.reverse;
    				}
    				
    				angular.forEach(ths, function (th) {
    					th.classList.remove("sort");
    					th.classList.remove("asc");
    					th.classList.remove("dsc");
    				});
    				
    				parentTh.classList.add("sort");
    					
    				if(scope.reverse) {
    					parentTh.classList.add("desc");
    				} else {
    					parentTh.classList.add("asc");
    				}
    				
    				scope.$apply();
    				
    				if(typeof(scope.Sort) === "function") {
	    				scope.Sort(scope.sorton, scope.reverse);
	    			}
    			});
    		}
    	}
    })
;






















