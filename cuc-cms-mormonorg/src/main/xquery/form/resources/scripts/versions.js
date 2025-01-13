function versions(id) {
    var parent = this,
        button = $('#versions button'),
        section = $('#versions-info'),
        leftSide = $('#versions-info #left-side'),
        rightSide = $('#versions-info #right-side'),
        selects = $('#versions-info .version-select'),
        rightSelect = selects.eq(1),
        completeRestore = $('#versions-info #complete-restore'),
        restoredVersions = $('#restored-versions'),
        save = $('#versions-info #save-version'),
        help = $('#complete-help'),
        form = leftSide.find('form'),
        leftVersion = "",
        rightVersion = "",
        leftForm = "",
        rightForm = "",
        versionHistory = [],
    	stop = false;
     
    this.setup = function () {
        save.hide();
        completeRestore.hide();
        this.getVersions();
        button.click(function (e) {
            updateCkeditors();
        	var h = hasChanges($('form:first'));
        	if ( !h || stop) {
        		stop = false;
        		parent.show($(this));
        	} else {
            	var msg = 'Restoring a version will discard your unsaved changes.';
        		var fn = function () {
    				stop = true;
    				button.trigger('click');
        		};
        		e.preventDefault();
        		e.stopPropagation();
        		LDSE.confirm("Warning", msg, fn);
        	}
            
        });
        selects.change(function () {
            parent.getVersion($(this));
        });
        completeRestore.click(function () {
            parent.restoreVersion($(this));
        });
        save.click(function (e) {
            e.preventDefault();
            e.stopPropagation();
            form.submit();
        });
        $(window).resize(function () {
            parent.lineUpReverts();
        });
        rightSide.on('click', '.form-section button.modified', function () {
            parent.restoreField($(this));
        });

        form.prepend($('#content-info > div > input[type="hidden"]').clone()).attr('action', $('.ldse-page > form:first').attr('action'));

        form.ajaxForm({
            success: function () {
                var postData = ICE.postVars[ICE.formVars.form];
                ICE.post(window.location.href, postData);
            },
            error: function () {
                alert("Failed to save version");
            }
        });
    };

    this.addHistory = function (version) {
        var add = true;
        for (var i = 0; add && i < versionHistory.length; i++) {
            if (versionHistory[i] === version) {
                add = false;
            }
        }
        if (add) {
            versionHistory.push(version);
        }
        restoredVersions.val(versionHistory.join());
    };

    this.clearHistory = function () {
        versionHistory = [];
        restoredVersions.val(versionHistory.join());
    };

    this.show = function (button) {
        if (leftVersion === "" && rightVersion === "") {
            selects.trigger('change');
        }
    };

    this.getVersions = function () {
        $.ajax({
            type: "POST",
            url: sharedPrefix + '/form/ajax/versions?lang=eng',
            data: {
                "id": id,
                "fn": "get-versions"
            },
            success: function (data) {
                var options = $(''),
                    versions = data.versions,
                    length = versions.length,
                    i = 0;
                for (; i < length; i++) {
                    var version = versions[i];
                    options = options.add('<option value="' + version.value + '">' + version.text + '</option>');
                }
                selects.append(options);
            }
        });
    };

    this.getVersion = function (select) {
        var version = select.val() || "",
            side = select.data('side');
        if (side === "left") {
            leftVersion = version;
            this.clearHistory();
            if (version !== "current") {
                save.show();
                this.addHistory(version);
            } else {
                save.hide();
            }
        } else {
            rightVersion = version;
        }
        completeRestore.hide();
        if (version !== "") {
            $.ajax({
                type: "POST",
                url: sharedPrefix + '/form/ajax/versions?lang=eng',
                data: {
                    "id": id,
                    "version": version,
                    "form": ICE.formVars.form,
                    "fn": "get-version-form"
                },
                success: function (data) {
                    select.closest('section').find('div.form-section').html(data);
                    parent.setupForms();
                    parent.updateFormNames();
                    if (leftVersion !== "" && rightVersion !== "") {
                    	if (leftForm === rightForm) {
                    		help.hide();
	                        setTimeout(parent.markDiffs, 50);
	                        setTimeout(parent.lineUpReverts, 100);
                    	} else {
                    		completeRestore.show();
                    		help.show();
                    	}
                    }

                },
                error: function () {
                    completeRestore.hide();
                    select.closest('section').find('div.form-section').html('Failed to load version.');
                }
            });
        } else {
            select.closest('section').find('div.form-section').html('');
        }
    };
    
    this.updateFormNames = function () {
    	leftForm = leftSide.find('.ldse-version-form').val();
    	rightForm = rightSide.find('.ldse-version-form').val();
    };
    
    this.setupForms = function () {
        //make inputs read only
        section.find('.form-section :input:not([readonly="readonly"])').attr('readonly', 'readonly');
        section.find('.form-section select:not([disabled="disabled"])').attr('disabled', 'disabled').each(function(){
    		var select = $(this),
    			input = $('<input type="hidden"/>');
    		input.attr('name', select.attr('name')).val(select.val());
    		select.before(input);
        });
        //change textareas to fake editors
        $('#versions-info textarea:visible').each(function () {
            var area = $(this).hide();
            area.after(
                '<div class="fake-ck-editor">' +
                parent.unescapeHTML(area.val()) +
                '</div>');
        });
        $('#versions-info .form-section select').fixSelect({deriveWidth:true});
    };

    this.unescapeHTML = function (html) {
        return $("<div />").html(html).html();
    };

    this.markDiffs = function () {
    	completeRestore.hide();
        var leftDLs = leftSide.find('.form-section dl:not(dl dl)'),
            rightDLs = rightSide.find('.form-section dl:not(dl dl)');
        rightSide.find('.form-section button.modified').remove();
        leftDLs.each(function (index) {
            parent.compareDL(leftDLs.eq(index), rightDLs.eq(index));
        });
    };

    this.compareDL = function (left, right) {
        var leftInputs = left.find('dd :input, dd textarea'),
            rightInputs = right.find('dd :input, dd textarea'),
            leftLength = leftInputs.length,
            rightLength = rightInputs.length,
            i = 0,
            modified = false,
            index = Math.random().toString().substring(2);
        left.height("auto");
        right.height("auto");
        
    	if (left.height() > right.height()) {
    		right.height( left.height() );
    	} else if (right.height() > left.height()) {
    		left.height( right.height() );
    	}
    	
        left.attr('data-id', index);
        right.attr('data-id', index);
        
        if (leftLength !== rightLength) {
            modified = true;
        }
        for (; !modified && i < leftInputs.length; i++) {
        	var l = leftInputs.eq(i),
        		r = rightInputs.eq(i);
            if (l.eq(i).val() !== r.eq(i).val() || l.eq(i).is(":checked") !==  r.eq(i).is(":checked") ) {
                modified = true;
                if (l.eq(i).is('textarea') && r.is('textarea')) {
                	var before = l.val(),
                		after = r.val(),
                		bHtml = $('<div class="fake-ck-editor"/>').append(parent.unescapeHTML(before)),
                		aHtml = $('<div class="fake-ck-editor"/>').append(parent.unescapeHTML(after)),
                		diff = domDiff(bHtml, aHtml);
                	
                	$.each(diff.before, function(i, v){
                		$(v).addClass('modified');
                	});
                	$.each(diff.after,function(i, v){
                		$(v).addClass('modified');
                	});
                	
                	l.next(".fake-ck-editor").remove();
                	r.next(".fake-ck-editor").remove();

                	r.after(aHtml);
                	l.after(bHtml);
                }
            }
        }
        if (modified) {
            completeRestore.show();
            var button = "";
            if($("#can-restore-line-item").val() == "true")
            {
            	button = '<button class="modified ldse-button ldse-icon-revert"><span></span></button>';
            }
            right.addClass("modified").children('dd').append(button);
        } else {
            right.removeClass("modified").find('dd > button.modified').remove();
        }
    };

    this.lineUpReverts = function () {
        var left = leftSide.offset().left + leftSide.outerWidth(false),
            right = rightSide.offset().left,
            half = left + ((right - left) / 2);
        rightSide.find('.form-section button.modified').each(function (i, e) {
            var modButton = $(e);
            var span = modButton.find('span');
            if ($(window).width() > 899) {
                modButton.css('left', '0px');
                var buttonLeft = modButton.offset().left,
                    buttonWidth = modButton.outerWidth(false),
                    buttonHalf = buttonLeft + (buttonWidth / 2),
                    newLeft = buttonHalf - half,
                    lineWidth = buttonLeft - left,
                    lineLeft = (lineWidth - buttonWidth) / 2;
                modButton.css('left', -(newLeft) + "px");
                span.css({
                    'width': lineWidth,
                    'left': -(lineLeft)
                });
            } else {
                modButton.css('left', '');
            }
        });
    };

    this.restoreField = function (button) {
        var rightDl = button.closest('dl'),
            id = rightDl.attr('data-id'),
            leftDl = leftSide.find('dl[data-id="' + id + '"]');
        button.remove();
        rightDl.removeClass("modified");
        leftDl.replaceWith(rightDl.clone());
        if (rightSide.find('.form-section button.modified').length === 0) {
            completeRestore.hide();
        }
        this.addHistory(rightSelect.val());
        save.show();
        leftSide.find('dl[data-id="' + id + '"]').find('.modified').removeClass("modified");
        rightSide.find('dl[data-id="' + id + '"]').find('.modified').removeClass("modified");
    };
    
    this.updateOptions = function () {
    	var options = leftSide.find('form > input[name = "option"]'),
    		value = options.val(),
    		form = value.split(",")[0];
    	options.val( value.replace(form, "form:" + leftForm) );    	
    };
    
    this.restoreVersion = function () {
    	this.addHistory(rightSelect.val());
    	rightSide.find('.form-section button.modified').remove();
    	rightSide.find('.form-section dl.modified').removeClass('modified');
        leftSide.find('.form-section').replaceWith(rightSide.find('.form-section').clone()); 
        this.updateFormNames();
        this.updateOptions();
        completeRestore.hide();
        save.show();
        this.markDiffs();
    };

}