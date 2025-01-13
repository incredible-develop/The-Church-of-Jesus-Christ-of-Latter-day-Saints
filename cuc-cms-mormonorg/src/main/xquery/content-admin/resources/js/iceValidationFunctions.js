var delay = (function () {
    var timer = 0;
    return function (callback, ms) {
        clearTimeout(timer);
        timer = setTimeout(callback, ms);
    };
})();

function slugCheckPath(slug, opts, slugObj) {
    var context = $(slugObj).closest('dl').siblings().find(opts['slugSiteSelect']).val();
    return $.ajax({
        type: 'GET',
        url: opts['slugCheckPath'],
        cache: false,
        data: {
            slug: slug,
            id: ICE.formVars.id,
            lang: ICE.formVars.lang,
            site: ICE.formVars['site-context'],
            templateUri: ICE.formVars.templateUri,
            siteContext: context
        }
    }).pipe(function (isUniqueSlug) {
        if (isUniqueSlug === 'true') {
            return true;
        } else {
            return false;
        }
    });
}

//The URI, the fullURI path, and the siteSelect must be in the same group (they have to be siblings)
function generateUri(opts, uri, slugObj) {

    var slug = cleanUri(uri);
    var uriPath = makeUriPathValid(opts, slug, slugObj);
    var callback = slugCheckPath(uriPath, opts, slugObj);

    $(slugObj).val(slug);

    return callback;
}
function cleanUri(uri) {
    'use strict';
    return $.trim(uri)
        .toLowerCase()
        .replace(/[\ ()_-]+/g, '-')  //make delimiters '-'
/*        .replace(/([^a-z0-9áéíñóúü/-])|(^[^a-z0-9áéíñóúü/-]+)|([^a-z0-9áéíñóúü/-]+$)|_/g, '') //remove anything not on the whitelist*/
        .replace(/[?\!&$%#@^*]+/g, '')
        .replace(/-+/g, '-') //replace multiple '-' with one '-'
        .replace(/\/+/g, '/'); //replace multiple / with one /

};

function validateUri(opts, uri, slugObj) {
    //generateUri(opts, uri, slugObj);
    validateFields(opts);
}

function makeUriPathValid(opts, slug, slugObj, firstrun) {

    if (firstrun) {
        var exist = true;
        $(opts['slug']).each(function (i, a) {
            if ($(a).val() == '') {
                exist = false;
            }
        });
        if (!exist) //if there any are empty it is invalid, disable saving
            disableSaving();
    }

    var uripath = $(slugObj).closest('dl').siblings().find(opts['slugUriPath']);
    var site = $(slugObj).closest('dl').siblings().find(opts['slugSiteSelect']);
    var siteContext = opts.siteContext;
    if (uripath && opts['pathPrefix']) {
        //make sure that the slashes are formatted correctly
        var siteval = site.val() ? site.val() + '/' : '';
        var siteContextVal = siteContext ? siteContext + '/' : '';
        siteval = ('/' + siteval) === opts['pathPrefix'] ? '' : siteval;
        var templateUri = ICE.formVars.templateUri ? ICE.formVars.templateUri : '';
        uripathValue = (opts['pathPrefix']  + siteContextVal + templateUri + '/' + slug).replace(/\/+/g, '/');

        uripath.val(uripathValue);
    }
    return uripath.val();
}


function handleURI(opts) {
    $(opts['slug']).on('keyup', function () {
        validateUri(opts, $(this).val(), this);
    });

    $(opts['slug']).on('blur', function () {
        validateUri(opts, $(this).val(), this);
    });

    $(opts['slugSiteSelect']).on('change', function () {
        validateUri(opts, $(opts['slug']).val(), $(opts['slug']));
    });
    makeUriPathValid(opts, $(opts['slug']).val(), $(opts['slug']), true);
}

function handleDynamicURI(opts) {
    $(opts['dynamicUri']).on('keyup', opts['slug'], function () {
        validateUri(opts, $(this).val(), this);
    });

    $(opts['dynamicUri']).on('blur', opts['slug'], function () {
        validateUri(opts, $(this).val(), this);
    });

    $(opts['dynamicUri']).on('change', opts['slugSiteSelect'], function () {
        var relatedSlug = $(this).closest('dl').siblings().find(opts['slug']);
        validateUri(opts, $(relatedSlug).val(), relatedSlug);
    });

    $(opts['dynamicUri']).parent().on('click', opts['addUri'], function () {
        validateFields(opts, {uriModifier: 1, type: 'uri'});
        var newuri = $(opts['dynamicUri']).find(opts['slug']).last();
        makeUriPathValid(opts, $(newuri).val(), newuri, true);
    });

    $(opts['dynamicUri']).on('click', opts['delUri'], function () {
        validateFields(opts, {uriModifier: 0, type: 'uri'});
    });
    makeUriPathValid(opts, $(opts['slug']).val(), $(opts['slug']), true);
    validateFields(opts);
}

function handleTime(opts) {
    var timebox = $(opts['timeTextBox']);
    if (timebox) {
        validationFuncs.push(function (modifier) {
            return validateTime(modifier, timebox.val(), timebox)
        });
        timebox.keyup(function () {
            validateFields(opts, {type: 'timeBox'});
        });
        timebox.blur(function () {
            validateFields(opts, {type: 'timeBox'});
        });
        //if(!timebox.val()){timebox.val('12:00');} //Default value
        validateFields(opts);
    }
}

function validateTime(modifier, input, timebox) {
    var regex = new RegExp(/^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$/);
    if (regex.test(input) || input === '') {
        $(timebox).closest('dl').removeClass('error');
        return true;
    }
    else {
        if (modifier && modifier.type === 'timeBox')
            $(timebox).closest('dl').addClass('error');
        return false;
    }
}

var disableButtons = ['#action-save', '#action-publish', '#action-save-done'];
function disableSaving() {
    for (var i = 0; i < disableButtons.length; i++) {
        $(disableButtons[i]).attr('disabled', 'disabled');
    }
}

function enableSaving() {
    for (var i = 0; i < disableButtons.length; i++) {
    $(disableButtons[i]).removeAttr('disabled');
    }
}

var validationFuncs = [];
function validateFields(opts, modifier) {

    var validateUriFuncs = $(opts['slug'])
        .each(function (index, slugInput) {
            generateUri(opts, $(slugInput).val(), $(slugInput))
                //using .pipe() instead of .then() because we are running JQuery 1.7.1 (1.8 and after use .then() instead, .pipe() is deprecated)
                .pipe(function (result) {
                    if (!result)
                        return false;
                    else
                        return true;
                }).pipe(function (result) {
                    if (!result)
                        return false;

                    for (var i = 0; i < validationFuncs.length; i++) {
                        var t = validationFuncs[i](modifier);
                        if (!(t == true)) {
                            return false;
                        }
                    }
                    return true;
                }).pipe(function (valid) {
                    var uriCurValue = $('input#uri-title.required.valid').val();
                    $('label[for=uri-title].uri-error-duplicated').remove();
                    if (valid) {
                        enableSaving();
                        return true;
                    }
                    else {
                        disableSaving();
                        if($('label[for=uri-title].uri-error-duplicated').length === 0 && uriCurValue !== undefined)
                            $('input#uri-title.required.valid').closest('dd').append('<label for="uri-title" class="uri-error-duplicated">URI already exists or it starts with the URI prefix of another site sharing the same domain.</label>');
                        return false;
                    }
                })
        });

    for (var i = 0; i < validationFuncs.length; i++) {
        var t = validationFuncs[i](modifier);
        if (!(t == true)) {
            valid = false;
        }
    }
}



