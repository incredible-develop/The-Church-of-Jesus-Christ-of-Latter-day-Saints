var hash = window.location.hash.split("=")[1];
var permalinkValue = {};
if (typeof (ICE) === "undefined") {
	/* jQuery Case-Insensitive :containsNC */
	$.extend($.expr[ ":"], {
		"containsNC": function (elem, i, match, array) {
			return (elem.textContent || elem.innerText || "").toLowerCase().indexOf((match[3] || "").toLowerCase()) >= 0;
		}
	});
	
	CKEDITOR_BASEPATH = location.protocol + cdnPath + '/lds-edit/scripts/ckeditor/';
	
	var ICE = {
		modal: $('#modal1'),
		ckeditor_loaded: false,
		page: null,
		uri: null,
		carousel: true, /* Current status of rotating carousels */
		formVars: '', /* SET when form opens */
		actions: {
			"ldse:publish": "Preview",
			"ldse:unpublish": "Unpublish",
			"ldse:remove": "Remove",
			"ldse:delete": "Delete"
		},
		post: function (path, params, method) {
			method = method || "post";
			var form = $("<form/>"),
			hiddenField;
			if (params && params.id && params.id != "" && path.indexOf('/shared/lds-edit/form') != -1 && path.indexOf('&id=') == -1) {
				path += '&id=' + params.id;
				delete params.id;
			}
			form.attr("method", method).attr("action", path).hide();
			for (var key in params) {
				if ($.isArray(params[key])) {
					for (var i = 0; i < params[key].length; i++) {
						hiddenField = $("<input/>");
						hiddenField.attr("type", "hidden").attr("name", key).attr("value", params[key][i]);
						form.append(hiddenField);
					}
				} else {
					hiddenField = $("<input/>");
					hiddenField.attr("type", "hidden").attr("name", key).attr("value", params[key]);
					form.append(hiddenField);
				}
			}
			$('body').append(form);
			form.submit();
			return false;
		},
		
		postLink: function (link) {
			link = $(link);
			var data = link.data();
			var postData = {
			};
			for (key in data) {
				if (data.hasOwnProperty(key) && key.indexOf('post.') == 0) {
					postData[key.replace(/post\./, '')] = data[key];
				}
			}
			ICE.post(link.attr('href'), postData);
			return false;
		},
		openForm: function (locale, id, action, form, uri, page, options) {
			if ($('.ldseForm').length > 0) {
				$('.ldseForm').remove();
			}
			$('<div class="ldseForm"></div>').appendTo('body');
			this.uri = uri;
			this.page = page != undefined ? page: uri;
			$.ajax({
				type: "POST",
				url: sharedPrefix + '/shared/lds-edit/ice/form?' + ICE.langParam(locale),
				data: {
					id: id, page: this.page, uri: uri, action: action, option: options, ixf: true
				},
				success: function (html) {
					$('.ldseForm').html(html).dialog({
						position:[($(window).width() / 2) - (910 / 2), 150],
						dialogClass: "ldseForm ldse-modal",
						height: 'auto',
						width: 910,
						zIndex: 4000,
						draggable: true,
						modal: true,
						title: $('.ldseForm #ice-dialog').attr('title'),
						beforeClose: function () {
							//ICE.destoryCKEditor();
						},
						close: function () {
							$('.ldseForm').remove().dialog("close");
						},
						open: function () {
							ICE.fixCKEditors();
							$('.confirm').click(function () {
								if ($('#status').attr('value') == 'delete') {
									$(this).removeClass('confirm');
									return confirm('This article will be permanently deleted, are you sure you want to continue?');
								}
							});
						}
					});
				}
			});
		},
		setupForm: function () {
			ICE.loadDatePickers();
			ICE.addSortable();
			ICE.fixSelects();
			ICE.addOnClicks();
			if ($.validator) {
				$.validator.setDefaults({
					onfocusout: function (element) {
						$(element).valid();
						$(':input.valid + label.error').remove();
					},
					ignoreTitle: true,
					success: function () {
						var inputs = $(':input.error'),
						first = inputs.first();
						if (inputs.length > 0) {
							inputs.each(function () {
								var input = $(this),
								group = input.closest('.ldse-group');
								if (group.hasClass('closed')) {
									group.removeClass('closed').find('.ldse-section--body').show();
								}
							});
							setTimeout(function () {
								$('html,body').scrollTop(first.closest(':visible').offset().top - 150)
							},
							10000);
						}
						$(':input.valid + label.error').remove();
					}
				});
			}
			if ($('form.ldse-form .required').length > 0) {
				$("form.ldse-form").validate({
					onfocusout: function (element) {
						$(element).valid();
					}
				});
			}
			ICE.addCKEditor();
			ICE.minEvaluate();
			$(".iceForm form").submit(function () {
				ICE.updateCKEditors();
				return true;
			});
		},
		minEvaluate: function () {
			var minValue = $('ul.sortable').data('min');
			if (minValue && minValue !== undefined) {
				for (var i = 0; i >= minValue; i++) {
					ICE.alertText("Test", "This is a test", function () {
						window.close();
					});
					$('ul.sortable').closest('dd').find('a.ldse-add').click();
				}
			} else {
			}
		},
		addCKEditor: function (newItem) {
			
			// Only load a new ckeditor instance if the ckeditor has already run its on load functions.
			if (typeof (CKEDITOR) !== "undefined") {
				var $editors = $(".iceForm textarea.ckeditor");
				if (newItem != null) {
					$editors = $(newItem).find('.ckeditor');
				}
				if ($editors.length) {
					$editors.each(function () {
						var editorID = $(this).attr("id");
						var instance = CKEDITOR.instances[editorID];
						if (instance) {
							try {
								if (instance.getData() !== '') {
									instance.updateElement();
								}
							}
							catch (e) {
							}
							instance.destroy(true);
						}
						CKEDITOR.replace(this);
					});
				}
			}
		},
		alertText: function (title, text, onOk, options) {
			var defaults = {
				okText: "OK",
				okClass: "primary ldse-icon-check2",
				cancelText: "Cancel",
				cancelClass: "ldse-icon-x"
			};
			options = $.extend({
			},
			defaults, options);
			$('#alertModal').remove().dialog('close');
			var modal = $(
			'<div id="alertModal" class="ldseForm">' +
			'<form class="ldse-section--body ldse-form">' +
			'<dl><dt><label>' + text + '</label></dt></dl>' +
			'<div class="ldse-form-buttons">' +
			'<button id="alert-ok" class="ldse-button ' + options.okClass + '">' + options.okText + '</button>' +
			'<button id="alert-cancel" class="ldse-button ' + options.cancelClass + ' float-right">' + options.cancelText + '</button>' +
			'</div>' +
			'</form>' +
			'</div>');
			modal.find('#alert-ok').click(function (e) {
				e.preventDefault();
				e.stopPropagation();
				$('#alertModal').remove().dialog('close');
				if (typeof onOk !== "undefined") {
					onOk();
				}
				return false;
			});
			modal.find('#alert-cancel').click(function (e) {
				e.preventDefault();
				e.stopPropagation();
				$('#alertModal').remove().dialog('close');
			});
			//$('body').append(modal);
			modal.dialog({
				position:[(window.innerWidth / 2) - 150, 150],
				dialogClass: "ldse-modal ldse-form ldseForm",
				height: 'auto',
				width: '350',
				zIndex: 99999999,
				draggable: true,
				modal: true,
				title: title,
				close: function () {
					$('#alertModal').remove().dialog("close");
				}
			});
		},		
		fixCKEditors: function () {
			var $editors = $(".iceForm textarea.ckeditor");
			$editors.each(function () {
				var editorID = $(this).attr("id");
				var instance = CKEDITOR.instances[editorID];
				try {
					instance.updateElement();
					instance.setMode('wysiwyg');
					//instance.execCommand( 'source' );
				}
				catch (e) {
				}
			});
		},
		updateCKEditors: function () {
			for (var instanceName in CKEDITOR.instances)
			CKEDITOR.instances[instanceName].updateElement();
		},
		addListItem: function (button) {
			var newItem = $(button).data('item');
            var hash = $(button).data('hash');
			var childIndex = parseInt($(button).data('childcount')) + 1;
			var max = $(button).closest('dl').find('ul:first').data('max');
			var liCount = $(button).closest('dl').find('li').length;

            var regex = new RegExp(hash, "g");
			if (max) {
				if (liCount < max) {
					$(button).data('childcount', childIndex);
					newItem = newItem.replace(regex, childIndex);
					$(button).siblings('ul').append(newItem);
					//ICE.fixedWidth($(button).siblings('ul').find('li > dl > dt > label'));
					//ICE.setupForm();
					newItem = $(button).siblings('ul').find('li').last();
					ICE.addOnClicks();
					ICE.addCKEditor(newItem);
					ICE.fixSelects(newItem);
					ICE.loadDatePickers();
					if ($('.required', newItem).length > 0) {
						newItem.closest('form').validate({
							onfocusout: function (element) {
								$(element).valid();
							}
						});
					}
				} else {
					alert("Error this is the max number you can add", function () {
						window.close()
					});
				}
			} else {
				$(button).data('childcount', childIndex);
				newItem = newItem.replace(regex, childIndex);
				$(button).siblings('ul').append(newItem);
				//ICE.fixedWidth($(button).siblings('ul').find('li > dl > dt > label'));
				//ICE.setupForm();
				newItem = $(button).siblings('ul').find('li').last();
				ICE.addOnClicks();
				ICE.addCKEditor(newItem);
				ICE.fixSelects(newItem);
				ICE.loadDatePickers();
				if ($('.required', newItem).length > 0) {
					newItem.closest('form').validate({
						onfocusout: function (element) {
							$(element).valid();
						}
					});
				}
			}
		},
		editFormItem: function (button) {
			var buttonObj = $(button);
			var modal = $('#modal1').trigger('close');
			modal.addClass('large');
			var formName = buttonObj.data('form');
			var itemId = buttonObj.data('id');
			var itemOptions = buttonObj.data('options');
			$.ajax({
				type: "POST",
				url: sharedPrefix + '/shared/lds-edit/ice/form?' + ICE.langParam(locale),
				data: {
					id: itemId, uri: ICE.uri, page: ICE.page, action: "edit", option: itemOptions
				},
				success: function (html) {
					modal.html(html).trigger('open');
					$('#ldse-toolbar-buttons').hide();
					var inlineDiv = modal.find('.ldse-form:first');
					$('html,body').scrollTop(modal.offset().top - 100);
					ICE.addOnClicks();
					ICE.fixSelects();
					ICE.loadDatePickers();
					ICE.addCKEditor(modal);
					var inlineForm = modal.find('form');
					// Setup the ajaxForm submit
					var options = {
						data: {
							ajax: 'true'
						},
						dataType: 'json',
						beforeSerialize: function () {
							ICE.updateCKEditors();
							if (! $('#modal1 form').valid()) {
								return false;
							}
						},
						success: function (data, statusText, xhr, $form) {
							$('#ldse-toolbar-buttons').show();
							ICE.destoryCKEditor(modal);
							$(inlineDiv).remove();
							buttonObj.text(data.title);
							ICE.addOnClicks();
							ICE.fixSelects();
							ICE.loadDatePickers();
							if ($('form.ldse-form .required').length > 0) {
								$("form.ldse-form").validate({
									onfocusout: function (element) {
										$(element).valid();
									}
								});
							}
							$('.iceForm.ui-dialog-content > div').show();
							$('#modal1').trigger('close');
							$('#modal1').find('div').remove();
							$('html,body').scrollTop(buttonObj.offset().top - 150);
						}
					};
					inlineForm.ajaxForm(options);
					if ($('.required', modal).length > 0) {
						$("form.ldse-form", modal).validate({
							onfocusout: function (element) {
								$(element).valid();
							}
						});
					}
					
					var cancelBtn = $(inlineForm).find('input[type="button"].cancel');
					// Remove other click events from the Cancel button so it won't close the previous form
					cancelBtn.unbind('click');
					// Add a new click event to the Cancel button so it will close the current form and show the previous one
					cancelBtn.bind('click', function (evt) {
						$('#ldse-toolbar-buttons').show();
						ICE.destoryCKEditor(modal);
						$(inlineDiv).remove();
						$('#modal1').trigger('close').removeClass('large');
						ICE.addOnClicks();
						ICE.fixSelects();
						ICE.loadDatePickers();
						if ($('form.ldse-form .required').length > 0) {
							$("form.ldse-form").validate({
								onfocusout: function (element) {
									$(element).valid();
								}
							});
						}
						$('html,body').scrollTop(buttonObj.offset().top - 150);
						return false;
					});
				}
			});
		},
		
		addFormItem: function (button) {
            var parser = new DOMParser(),
                buttonObj = $(button),
                formItem = parser.parseFromString(buttonObj.data('item'), "text/html"),
                elements = (formItem).firstChild,
                dataItems = $(elements).find("a.editFormItem").data('options'),
                modal = $('#modal1').trigger('close');
            modal.addClass('large');
            $.ajax({
                type: "POST",
                url: sharedPrefix + '/shared/lds-edit/ice/form?' + ICE.langParam(locale),
                data: {
                   id: "new", uri: ICE.uri, page: ICE.page, action: "add", option: dataItems
                },
				success: function (html) {
					$('#ldse-toolbar-buttons').hide();
					modal.html(html).trigger('open');
					var inlineDiv = modal.find('.ldse-form:first');
					$('html,body').scrollTop(modal.offset().top - 100);
					ICE.addOnClicks();
					ICE.fixSelects();
					ICE.loadDatePickers();
					ICE.addCKEditor(modal);
					
					var inlineForm = modal.find('form');
					
					// Setup the ajaxForm submit
					var options = {
						data: {
							ajax: 'true'
						},
						dataType: 'json',
						beforeSerialize: function () {
							ICE.updateCKEditors();
							if (! $('#modal1 form').valid()) {
								return false;
							}
						},
						success: function (data, statusText, xhr, $form) {
							$('#ldse-toolbar-buttons').show();
							ICE.destoryCKEditor(modal);
							$(inlineDiv).remove();
							var newItem = buttonObj.data('item');
							var childIndex = parseInt(buttonObj.data('childcount')) + 1;
							buttonObj.data('childcount', childIndex);
							newItem = newItem.replace(/INDEXHERE/g, childIndex);
							buttonObj.siblings('ul').append(newItem);
							var newItem = buttonObj.siblings('ul').find('li').last();
							var newEditLink = '<h3><a href="#d" class="editFormItem" data-id=' + data.id + ' data-form=' + formName + ' data-options=' + 'form:' + formName + '>' + data.title + '</a></h3>';
							newItem.find('h3').replaceWith(newEditLink);
							newItem.find('fieldset input').val(data.id);
							ICE.addOnClicks();
							ICE.addCKEditor(newItem);
							ICE.fixSelects();
							ICE.loadDatePickers();
							if ($('form.ldse-form .required').length > 0) {
								$("form.ldse-form").validate({
									onfocusout: function (element) {
										$(element).valid();
									}
								});
							}
							$('#modal1').trigger('close');
							$('html,body').scrollTop(buttonObj.offset().top - 150);
							ICE.coripCanPublish();
						}
					};
					inlineForm.ajaxForm(options);
					
					if ($('.required', modal).length > 0) {
						$("form.ldse-form", modal).validate({
							onfocusout: function (element) {
								$(element).valid();
							}
						});
					}
					
					var cancelBtn = $(inlineForm).find('input[type="button"].cancel');
					// Remove other click events from the Cancel button so it won't close the previous form
					cancelBtn.unbind('click');
					// Add a new click event to the Cancel button so it will close the current form and show the previous one
					cancelBtn.bind('click', function (evt) {
						$('#ldse-toolbar-buttons').show();
						ICE.destoryCKEditor(modal);
						$(inlineDiv).remove();
						$('#modal1').trigger('close').removeClass('large');
						ICE.addOnClicks();
						ICE.fixSelects();
						ICE.loadDatePickers();
						if ($('form.ldse-form .required').length > 0) {
							$("form.ldse-form").validate({
								onfocusout: function (element) {
									$(element).valid();
								}
							});
						}
						$('html,body').scrollTop(buttonObj.offset().top - 150);
						return false;
					});
				}
			});
		},
		searchFormItem: function (button) {
			var searchItem = $(button).data('item');
			var modal = $('#modal1').trigger('close').addClass('large');
			var formName = $(button).data('form');
			var fileId = $(button).data('file-id');
			
			var colTemplate, seaTemplate;
			$.ajax({
				url: sharedPrefix + '/shared/lds-edit/collections/ajax/collectionMain.html',
				type: "GET",
				dataType: 'html',
				success: function (data) {
					colTemplate = Handlebars.compile(data);
					buildColSearModal();
					
					//set up all the listeners on the form
					$("#collection-modal-form").submit(function (e) {
						e.preventDefault();
						searchCollection(fileId);
					});
					$("#collection-modal-search-button").click(function (e) {
						e.preventDefault();
						searchCollection(fileId);
					});
					$('#modal1').on("click", "ul.collection-modal-list li header a", function () {
						$(this).closest("li").find(".ldse-block--body").toggle(0);
						$(this).closest('section').toggleClass('ldse-open');
					});
					$('#modal1').on("click", '.addFromSearch',
					function () {
						var buttonObj = $(button).prev()
						var newItem = buttonObj.data('item');
						var childIndex = parseInt(buttonObj.data('childcount')) + 1;
						buttonObj.data('childcount', childIndex);
						newItem = newItem.replace(/INDEXHERE/g, childIndex);
						buttonObj.siblings('ul').append(newItem);
						ICE.fixedWidth(buttonObj.siblings('ul').find('li > dl > dt > label'));
						//ICE.setupForm();
						var newItem = buttonObj.siblings('ul').find('li').last();
						var newItemText = $(this).data("title");
						var newItemId = $(this).data("id");
						var newEditLink = '<h3><a href="#d" class="editFormItem" data-id=' + newItemId + ' data-form=' + formName + ' data-options=' + 'form:' + formName + '>' + newItemText + '</a></h3>';
						newItem.find('h3').replaceWith(newEditLink);
						newItem.find('fieldset input').val(newItemId);
						newItem.find('fieldset input').attr("id", newItemId);
						ICE.addOnClicks();
						ICE.addCKEditor(newItem);
						ICE.fixSelects();
						ICE.loadDatePickers();
						if ($('form.ldse-form .required').length > 0) {
							$("form.ldse-form").validate({
								onfocusout: function (element) {
									$(element).valid();
								}
							});
						}
						// $(this).parent().remove();
						$(this).hide();
						ICE.coripCanPublish();
					});
					$("#modal1").on("click", "#ldse-collection-modal-done", function () {
						/* remove listeners */
						$("#modal1").off("click", "#ldse-collection-modal-done");
						$('#modal1').off("click", '.addFromSearch');
						$('#modal1').off("click", "ul.collection-modal-list li header a");
						
						$('#inline-' + formName + '-search').siblings().remove();
						$('#inline-' + formName + '-search').remove()
						var modal = $('#modal1').trigger('close').removeClass('large');
						$('.iceForm > div').show();
						ICE.fixSelects();
					});
				},
				error: function () {
					//TEMPLATE ISSUE, but don't tell the user
					alert("Search modal could not be loaded");
				}
			});
			
			var buildColSearModal = function () {
				$('#modal1').html('').append(
				$('<div id="inline-' + formName + '-search" style="max-height: 700px; overflow:auto;"><header class="ldse-section--header"><h2>Search</h2></header>')).append(colTemplate({
				})).append('<link rel="stylesheet" type="text/css" href="' + sharedPrefix + '/shared/lds-edit/resources/css/collection-manager.css">');
			}
			var searchCollection = function (fileId) {
				var searchContainer = $('#collection-modal-search-results'),
				    collections = $("ul.sortable fieldset input")
					ids = [],
					id = "";
				searchContainer.html('');
				
				for (var i = 0; i < collections.length; i++) {
				    ids.push($(collections[i]).attr('id'));
				}
				$.ajax({
					type: "POST",
					url: sharedPrefix + '/shared/lds-edit/ice/search?' + ICE.langParam(locale),
					data: {
						option: "form:" + formName, 
						query: $("#collection-modal-search").val(),
						id : fileId,
						ids : ids
					},
					dataType: 'json',
					success: function (json) {
						$.ajax({
							url: sharedPrefix + '/shared/lds-edit/collections/ajax/collectionSearchResults.html',
							type: "GET",
							dataType: 'html',
							success: function (data) {
								seaTemplate = Handlebars.compile(data);
								if ( json !== null ) {
								    searchContainer.html(seaTemplate(json.results));    
								} else {
								    $(".search-results").append("There are no results");
								}
								$(window).resize();
							},
							error: function () {
								//TEMPLATE ISSUE, but don't tell the user
								alert("Search modal could not be loaded");
							}
						});
					}
				});
			};
			$('#modal1').show();
		},
		addOnClicks: function () {
			$('.iceForm .deleteListItem').click(function () {
				ICE.deleteListItem(this);
			}).removeClass('deleteListItem');
			$('.iceForm .addListItem').click(function () {
				ICE.addListItem(this);
			}).removeClass('addListItem');
			$('.iceForm .editFormItem').click(function () {
				ICE.editFormItem(this);
			}).removeClass('editFormItem');
			$('.iceForm .addFormItem').click(function () {
				ICE.addFormItem(this);
			}).removeClass('addFormItem');
			$('.iceForm .searchFormItem').click(function () {
				ICE.searchFormItem(this);
				var modal = $('#modal1').trigger('open');
				$('html,body').scrollTop($('#inline-image-search').offset());
			}).removeClass('searchFormItem');
			$('.iceForm .closeForm').click(function () {
				ICE.closeForm();
			}).removeClass('closeForm');
			$('.iceForm .binary-manager').click(function (e) {
				e.preventDefault();
				ICE.binaryManger(this);
				return false;
			}).removeClass('binary-manager');
		},
		addSortable: function () {
			$('.sortable').each(function () {
				$(this).sortable({
					start: function (event, ui) {
						ICE.fixCKEditors();
					},
					stop: function (event, ui) {
						ICE.addCKEditor($(this));
					},
					create: function (event, ui) {
						ICE.fixedWidth($(this).find('li > dl > dt > label'));
					}
				});
			});
		},
		closeForm: function () {
			$('.iceForm').dialog("close");
			ICE.addedCkEditor = false;
			//$('.iceForm').dialog( "destroy" );
			//$('.iceForm').remove();
		},
		deleteListItem: function (child) {
			var min = $(child).closest('ul').data('min');
			var liCount = $(child).closest('ul').find('li').length;
			if (min && min !== undefined) {
				if (liCount > min) {
					$(child).closest('li').remove();
				} else {
					alert("Error you cannot delete any more. A minimum of " + min + " is required", function () {
						window.close();
					});
				}
			} else {
				$(child).closest('li').remove();
			}
		},
		destoryCKEditor: function (section) {
			for (var instanceName in CKEDITOR.instances) {
				var instance = CKEDITOR.instances[instanceName];
				var remove = true;
				if (section != null) {
					remove = $(instance.element.$).closest(section).length != 0;
				}
				if (remove) {
					instance.destroy(true);
				}
			}
		},
		fixSelects: function (context) {
			context = context != undefined ? context: $('.iceForm, .ldse-form');
			$('select:not(.select select)', context).each(function (index, div) {
				try {
					$(this).fixSelect({
						deriveWidth: true
					});
				}
				catch (e) {
				}
			});
		},
		fixedWidth: function (selector) {
			var listWidth =[];
			$(selector).each(function () {
				listWidth.push($(this).outerWidth(false) + 1);
			});
			$(selector).width(Math.max.apply(Math, listWidth));
		},
		langParam: function (locale) {
			var split = locale.split('-');
			if (split.length > 1) {
				return 'lang=' + split[0] + '&country=' + split[1];
			} else {
				return 'lang=' + locale;
			}
		},
		linkToItem: function (href, id) {
			sessionStorage.markedItem = id;
			//$.cookie('lds-item-id', id, {expire: .1, path : '/'});
			
			$.newWindow(href);
		},
		loadDatePickers: function () {
			$(".iceForm .datePicker").each(function (index, input) {
				var format = $(input).data('format') == undefined ? 'yy-mm-dd': $(input).data('format');
				$(input).datepicker({
					showButtonPanel: false,
					dayNamesMin:[ 'S', 'M', 'T', 'W', 'T', 'F', 'S'],
					dateFormat: format,
					altFormat: format,
					showAnim: 'fadeIn'
				});
				$(input).removeClass('datePicker');
			});
		},
		carouselCheck: function () {
			if ($.cookie('lds-carousel') == "false") {
				$(document).ready(function () {
					ICE.toggleCarousel();
				});
			}
		},
		toggleCarousel: function () {
			if ($('#toggleCarousel').length > 0) {
				if (ICE.carousel == true) {
					$('#toggleCarousel').html('Start Carousel');
					/* stop carousels */
					var carousels = $('#toggleCarousel').data('carousel').split(',');
					for (var i in carousels) {
						$(carousels[i]).cycle('pause');
					}
					/* set cookie */
					$.cookie("lds-carousel", "false", {
						path: "/", expires: 365
					});
					ICE.carousel = false;
				} else {
					$('#toggleCarousel').html('Stop Carousel');
					/* Start carousels */
					var carousels = $('#toggleCarousel').data('carousel').split(',');
					for (var i in carousels) {
						$(carousels[i]).cycle('resume');
					}
					/* Set Cookie */
					$.cookie("lds-carousel", null);
					ICE.carousel = true;
				}
			}
		},
		
		workflowCheck: function (input) {
			if ($(input).is(':checked')) {
				/* $('#globalCheckbox').removeAttr('disabled'); */
				$('#globalCheckbox').attr('checked', 'checked');
			} else {
				/*
				$('#globalCheckbox').removeAttr("checked");
				$('#globalCheckbox').attr("disabled", true);
				 */
			}
		},
		
		binaryManger: function (button) {
			//add in some DOM elements for the modal etc. this intrduces a jQuery dependency for now
			if ($('.modal-background').length == 0) {
				$('bc-wrapper').remove();
				var modalDom = $('<div class="modal-background hidden"><div class="bc-wrapper">Binary Manger Loading</div></div>');
				$('body').append(modalDom);
				$('.modal-background').on('click', function () {
					$(this).hide();
				});
				$('.bc-wrapper').on('click', function (event) {
					event.stopPropagation()
				});
			}
			if (window.File && window.FileReader && window.FileList && window.Blob) {
				var binaryType = $(button).data('binary-type'),
				inputID = $(button).data('binary-input'),
				allowedHeight = $(button).data('image-height'),
				allowedWidth = $(button).data('image-width'),
				fileExts = $(button).data('binary-ext').split(","),
				updateArticle = (ICE.formVars.action === 'edit'),
				hideTabs = false;
				if (binaryType !== '' && fileExts.length > 0) {
					hideTabs = true;
				}
				//open modal
				$('.bc-wrapper').parents('.modal-background').show();
				//write in the js file if it hasn't already been loaded
				if (typeof jsloaded === 'undefined') {
					jsloaded = true;
					//load in the main control file
					function createBinaryManager() {
						createBC({
							adminLibrary: false,
							apiUrl: sharedPrefix + '/shared/lds-edit/ice/burce/',
							wrapperSelector: 'bc-wrapper',
							libraryUrl: sharedPrefix + '/shared/lds-edit/binary?lang=eng',
							noArticle: true,
							updateArticle: updateArticle,
							contentType: binaryType,
							inputID: inputID,
							allowedHeight: allowedHeight,
							allowedWidth: allowedWidth,
							allowedFileExtensions: fileExts,
							hideTabs: hideTabs
						});
					}
					if (typeof yourFunctionName == 'function') {
						$.getScript(sharedPrefix + '/shared/lds-edit/binary/resources/scripts/burce.js', function (data) {
							createBinaryManager()
						});
					} else {
						createBinaryManager()
					}
				} else {
					resetBC({
						contentType: binaryType,
						inputID: inputID,
						allowedHeight: allowedHeight,
						allowedWidth: allowedWidth,
						allowedFileExtensions: fileExts,
						hideTabs: hideTabs
					});
				}
			} else {
				alert('We\'re sorry but the browser you are using is not supported for this operation');
			}
		}
	};
	
	$(document).ready(function () {
		if ( hash ) {
            sessionStorage.markedItem = hash;
        }
		try {
			CKEDITOR.replaceByClassEnabled = false;
		}
		catch (e) {
		}
});

function setCookie (name, value, days) {
    var d = new Date();
    d.setTime(d.getTime() + (days*24*60*60*1000));
    var expires = "expires=" + d.toGMTString();
    document.cookie = name + "=" + value + "; " + expires;
};

function getCookie(name) {
    var name = name + "=",
        cookie = document.cookie.split(';');
    for(var i = 0; i < cookie.length; i++)
    {
        var cook = cookie[i].trim();
        if (cook.indexOf(name) == 0) return cook.substring(name.length, cook.length);
    }
    return "";
};
	
	
	function boxesIntersect(ax, ay, aw, ah, bx, by, bw, bh) {
		return (Math.abs(ax - bx) * 2 < (aw + bw)) &&
		(Math.abs(ay - by) * 2 < (ah + bh));
	}
	
	function closeOpenItems(notItem) {
		$('#ldse-ice-menu-clone').remove();
		$('.workflow-table.active').not(notItem).removeClass('active');
		$("#ldse-toolbar-container.front .ldse-toolbar-item.ldse-open ul.ldse-menu").not(notItem).hide().parents('.ldse-toolbar-item.ldse-open').removeClass('ldse-open');
	}
	
	function closeSupportMessage(evt) {
		evt.preventDefault();
		evt.stopPropagation();
		if ($.cookie) {
			$.cookie("ie-warning", "off");
		}
		$("#ice-overlay-header").hide();
	}
	

function guid() {
    function s4() {
        return Math.floor((1 + Math.random()) * 0x10000)
            .toString(16).substring(1);
    }
    return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
        s4() + '-' + s4() + s4() + s4();
};
function permalink_validate() {
	"use strict";
	var locale = $('#locale').val();
	var fullUrl = $("#fullUri").val();
	var validateUrl = $("#permalink").val();
	var isValid = false;
	$.ajax({
		url: validateUrl + '&url=' + fullUrl,
		success: function (result) {
			var delim = result.indexOf("\n");
			var valid = result
			if (delim !== -1) {
				valid = result.substring(0, delim);
			}
			
			if (valid === 'true') {
				jQuery("#fullUri").closest('dl').removeClass('error');
				isValid = true;
			}
			if (isValid === false) {
				jQuery("#fullUri").closest('dl').addClass('error');
				//.append("<span class='error'>Unavailable</span>");
			}
		},
		async: false,
		dataType: 'text'
	});
	return isValid;
}

function permalink_sanitize(value) {
   return value.replace(/[`~!@#\$%\^|''""\\\*\(\)\+={}\[\]:;'<>,\.\?\&]/g, "-").replace(/[-]+/g,'-').replace(/^-(.*)$/g,'$1').replace(/(.*)-$/g,'$1');
};

function permalinkUpdateFullUri(source, verify, permaRoot) {
	"use strict";
	try {
		var uriContext = "";
		var path = source.val().toLowerCase();
		if (uriContext[0] !== '/') {
		   uriContext = '/' + uriContext;
		}
		path = uriContext + permaRoot + path;
		
		if (path.indexOf(sharedPrefix) === -1) {
			path = sharedPrefix + path;
		}
		path = permalinkCleanPath(path);
		$('#permalink').val(path);
		if (verify) { permalinkVerifyUrl(); }
	} catch (e) { }
}

	function permalink_stripHTML(html) {
		var tmp = document.createElement("DIV");
		tmp.innerHTML = html;
		return tmp.textContent || tmp.innerText;
	}
	
	function permalink_generate(source_field_id, permalink_field_id, gen_root) {
		var sourceInput = $("#" + source_field_id);
		var permalinkInput = $("#" + permalink_field_id);
		if (sourceInput != null && permalinkInput != null) {
			permalinkInput.val((gen_root + permalink_sanitize(permalink_stripHTML(sourceInput.val()))).toLowerCase());
		}
		permalinkInput.blur();
	};
	
	function permalink_generate_from_ck(source_field_id, permalink_field_id, gen_root) {
		var sourceInput = CKEDITOR.instances[source_field_id].getData().replace("\n", "").replace(".", "");
		var permalinkInput = $("#" + permalink_field_id);
		if (sourceInput != null && permalinkInput != null) {
			permalinkInput.val((gen_root + permalink_sanitize(permalink_stripHTML(sourceInput))).toLowerCase());
		}
		
		permalinkInput.blur();
	};
function permalinkCleanPath(path) {
	"use strict";
	return $.trim(path).replace(/\ /g, '-').replace(/(-)\1+/g,'-').toLowerCase().replace(/[`~!@#\$%\^|''""\\\*\(\)\+={}\[\]:;'<>,\.\?\&]/g, '');
}

function permalinkVerifyUrl() {
	"use strict";
	var permalink = $("#permalink");
	if ( permalink.is(':not([readonly])') && permalinkValue.permalink != $(permalink).val() ) {
      	var fullUrl = $("#permalink").val();
      	var isValid = false;
      	$.ajax({
      		url: sharedPrefix + "/shared/lds-edit/ice/resources/ajax/validateUrl?" + ICE.langParam(locale) + '&url=' + fullUrl,
      		success: function (result) {
      			var delim = result.indexOf("\n");
      			var valid = result
      			if (delim !== -1) {
      				valid = result.substring(0, delim);
      			}
      			
      			if (valid === 'true') {
      				jQuery("#permalink").closest('dl').removeClass('error');
      				isValid = true;
      			}
      			if (isValid === false) {
      				jQuery("#permalink").closest('dl').addClass('error');
      				//.append("<span class='error'>Unavailable</span>");
      			}
      		},
      		async: false,
      		dataType: 'text'
      	});
      	return isValid;
	} else {
	    return true;
	}
}
	function permalink_validate() {
		"use strict";
		var locale = $('#locale').val();
		var fullUrl = $("#fullUri").val();
		var validateUrl = $("#permalink").val();
		var isValid = false;
		$.ajax({
			url: validateUrl + '&url=' + fullUrl,
			success: function (result) {
				var delim = result.indexOf("\n");
				var valid = result
				if (delim !== -1) {
					valid = result.substring(0, delim);
				}
				
				if (valid === 'true') {
					jQuery("#fullUri").closest('dl').removeClass('error');
					isValid = true;
				}
				if (isValid === false) {
					jQuery("#fullUri").closest('dl').addClass('error');
					//.append("<span class='error'>Unavailable</span>");
				}
			},
			async: false,
			dataType: 'text'
		});
		return isValid;
	}
	
	// Lang/Locale
	function getUrlParams() {
		var vars =[],
		hash;
		var url = window.location.href;
		url = url.split('#')[0];
		var hashes = url.slice(url.indexOf('?') + 1).split('&');
		for (var i = 0; i < hashes.length; i++) {
			hash = hashes[i].split('=');
			if (hash.length > 0) {
				vars.push(hash[0]);
				vars[hash[0]] = hash[1];
			}
		}
		return vars;
	}
	
	function getLocaleFromParams() {
		var urlParams = getUrlParams();
		var params = '';
		if (urlParams.country !== '' && urlParams.country !== undefined) {
			params = urlParams.lang + '&country=' + urlParams.country;
		} else {
			params = urlParams.lang;
		}
		return params;
	}
	
	
	function splitLocale(locale) {
		if (locale != undefined) {
			var split = locale.split('-');
			var lang = '';
			if (split.length > 1) {
				lang = split[0] + '&country=' + split[1];
			} else {
				lang = locale;
			}
			return lang;
		} else {
			return lang;
		}
	}
	
	function getLang(locale) {
		var split = locale.split('-');
		var lang = '';
		if (split.length > 1) {
			lang = split[0];
		} else {
			lang = locale;
		}
		return lang;
	}
	
	function getCountry(locale) {
		var split = locale.split('-');
		var country = '';
		if (split.length > 1) {
			country = split[1];
		} else {
			country = '';
		}
		return country;
	}
	
	function getCurrentUrl() {
		var url = document.location.toString();
		var index = url.lastIndexOf("#");
		if (index == -1) {
			index = url.length;
		}
		url = url.substring(0, index);
		return url;
	}
	
	function fixNullInput() {
		$('input.dynamicInput').each(function () {
			if ($(this).val() === "") {
				$(this).val(" ");
			}
		});
	}
	
	function getCurrentPage() {
		return decodeURIComponent(window.location.pathname);
	}
	
	function inlineTeaser(editor) {
		CKEDITOR.currentInstanceName = editor.name;
		window.open(sharedPrefix + '/shared/lds-edit/ice/resources/ajax/browse?lang=' + getLocaleFromParams() + '&currentPage=' + getCurrentPage() + '&type=teaser&source=wysiwyg', 'teaser_browse', 'width=1000,height=378,toolbar=no,status=no,menubar=no,toolbar=no');
	}
	
	function pdfBrowse(editor) {
		CKEDITOR.currentInstanceName = editor.name;
		window.open(sharedPrefix + '/shared/lds-edit/ice/resources/ajax/browse?lang=' + getLocaleFromParams() + '&currentPage=' + getCurrentPage() + '&type=pdf&source=wysiwyg', 'pdf_browse', 'width=1024,height=378,toolbar=no,status=no,menubar=no');
	}
	
	function embedVideo(editor) {
		CKEDITOR.currentInstanceName = editor.name;
		window.open(sharedPrefix + '/shared/lds-edit/ice/resources/ajax/browse?lang=' + getLocaleFromParams() + '&currentPage=' + getCurrentPage() + '&type=video&source=wysiwyg', 'teaser_browse', 'width=1000,height=378,toolbar=no,status=no,menubar=no,toolbar=no');
	}
	
	function embedAudio(editor) {
		CKEDITOR.currentInstanceName = editor.name;
		window.open(sharedPrefix + '/shared/lds-edit/ice/resources/ajax/browse?lang=' + getLocaleFromParams() + '&currentPage=' + getCurrentPage() + '&type=audio&source=wysiwyg', 'teaser_browse', 'width=1000,height=378,toolbar=no,status=no,menubar=no,toolbar=no');
	}
	
	function embedBrightCove(editor) {
		CKEDITOR.currentInstanceName = editor.name;
		window.open(sharedPrefix + '/shared/lds-edit/ice/resources/ajax/browse?lang=' + getLocaleFromParams() + '&currentPage=' + getCurrentPage() + '&type=brightcove&source=wysiwyg', 'teaser_browse', 'width=1000,height=378,toolbar=no,status=no,menubar=no,toolbar=no');
	}
	
	function embedBrightCoveGallery(editor) {
		CKEDITOR.currentInstanceName = editor.name;
		window.open(sharedPrefix + '/shared/lds-edit/ice/resources/ajax/browse?lang=' + getLocaleFromParams() + '&currentPage=' + getCurrentPage() + '&type=gallery&source=wysiwyg', 'teaser_browse', 'width=1000,height=378,toolbar=no,status=no,menubar=no,toolbar=no');
	}
	function windowHeight() {
		if (navigator.appName.indexOf("Microsoft") != -1) {
			return document.documentElement.clientHeight - 150;
		} else {
			return window.innerHeight - 200;
		}
	}
	
	function updateUriTitle(titleId, uriTitleId) {
		var titleTxt = $('#' + titleId).val();
		var uriTitleTxt = titleTxt.replace(/\ /g, '-').toLowerCase();
		uriTitleTxt = uriTitleTxt.replace(/[`~!@#\$%\^\*\(\)\+={}\[\]:;'<>,\.\?\&]/g, '');
		$('#' + uriTitleId).val(uriTitleTxt);
	}
	
	// New Window plugin
	(function (jQuery) {
		jQuery.extend(jQuery, {
			defined: function (value) {
				return (typeof (value) !== typeof (undefined));
			},
			empty: function (value) {
				return ! jQuery.defined(value) || value === null || (typeof (value) === "string" && value === "");
			},
			getPath: function (url) {
				return url ? jQuery('<a/>').attr('href', url)[0].pathname.replace(/^[^\/]/, '/'): '';
			},
			urlVars:[],
			getUrlVars: function () {
				if ($.urlVars.length == 0) {
					var hashes = window.location.search.substr(1).split('&');
					for (var i = 0; i < hashes.length; i++) {
						hash = hashes[i].split('=');
						$.urlVars.push(hash[0]);
						$.urlVars[hash[0]] = hash[1];
					}
				}
				return $.urlVars
			},
			getUrlVar: function (name) {
				return $.getUrlVars()[name];
			},
			newWindow: function (url, options) {
				options = options || {
				};
				var name = options.name || "_blank";
				var w = window.open(url, name);
				if (window.focus) {
					w.focus();
				}
				return w;
			}
		});
	})(jQuery);
	
	$(document).ajaxSend(function (event, request, settings) {});
}