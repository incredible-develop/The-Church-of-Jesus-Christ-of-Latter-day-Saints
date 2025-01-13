var CP = {
	timer: {},

	hideErrors: function()
	{
		$("#newUriError").hide();
		$(".select.error").removeClass("error");
	},

	verifyUrls: function()
	{
		CP.hideErrors();
		var fullUrl = $("#newUri").val().toLowerCase();
		var currUrl = $("#currentPage").val().toLowerCase();
        var lang = getUrlParameter('lang');
        var site = getUrlParameter('site');
        var lang = getUrlParameter('lang');
        var contentAdmin = '/cms/content-admin?lang=' + lang + '&site=' + site;
		if(fullUrl == '')
		{
			$("#newUriError").html("Error: No uri given");
			$("#newUriError").show();
		}
		else if(fullUrl.substr(0,1) != '/' )
		{
			$("#newUriError").html("Error: Uri must begin with a /");
			$("#newUriError").show();
		}
		else if(/\?/.test(fullUrl))
		{
			$("#newUriError").html("Error: Uri must not contain query parameters");
			$("#newUriError").show();
		}
		else if(/\#/.test(fullUrl))
		{
			$("#newUriError").html("Error: Uri must not contain the # symbol");
			$("#newUriError").show();
		} else {
			CP.showWait("Checking if urls are available...");

			CP.langArray = [];
            CP.langErrorArray = [];
			$(".langDropDown").each(function()
			{
			    if ( fullUrl == currUrl && $(this).val() == locale ) {
         			$("#newUriError").html("Error: Uri must not be same as current page and language");
         			$("#newUriError").show();
			    } else if($(this).val() != "Please Select a Language..." && CP.langArray.indexOf($(this).val()) == -1)
				{
					CP.verifyUrl($(this), fullUrl);
				}
				else
				{
					if($(".langSelect").length > 1)
					{
						$(this).closest("dd").remove();
					}
				}
			});
		}

		CP.hideWait();
		if(!$("#newUriError").is(":visible"))
		{
			//submit urls
			if(CP.langArray.length > 0)
			{
				CP.showWait("Cloning Page...");

				var url = $("#clonePageForm").attr("action");
				var method = $("#clonePageForm").attr("method");
				var newUri = $("#newUri").val();
				var action = $("#action").val();
				var recurse = $("#recurse").val();
                var updToUniversalTemplate = $("#changeToUniversalTemplate").val();
				var successes = [];
				var errors = [];
				var uri;
				$(CP.langArray).each(function(index, value)
				{
					var locale = value;
					var span = CP.getDDbyLocale(locale).find('span.select');
					if (span.hasClass('success')) {
						successes.push(locale);
					} else {

						$.ajax({
							url: url,
							async: false,
							method: method,
							data:
							{
								langDropDown: locale,
								currentPage: $("#currentPage").val(),
								newUri: newUri,
								action: action,
								recurse: recurse,
								currentID: $("#currentID").val(),
                                site: site,
                                updToUniversalTemplate: updToUniversalTemplate
							},
							success: function(data) {
								if(data){
									uri = data;
								}
								successes.push(locale);
                          },
                          error : function(){
                            errors.push(locale);
                          }
                        });
                      }
                });

        // this is fired too quickly - Remove the hide and wait for the else statement below to hide the loader
				// CP.hideWait();

				if (errors.length == 0 && successes.length > 0 && CP.langErrorArray.length == 0) {
					if(uri)
                    {
                        window.location = uri
                    }
                    else
					{
					//	window.location = newUri + "?" + ICE.langParam(CP.langArray[0]);
                        window.location = contentAdmin;
					}
			    } else {
                    CP.hideWait();
			    	$("#newUriError").html("Error: The following languages failed to clone : " + CP.langErrorArray.join(', ')).show();
			    	$("#newUriSuccess").html("Success: The following languages were cloned: " + successes.join(', ')).show();

			    	for (var i=0; i < errors.length; i++) {
			    		var locale = errors[i];
			    		var dd = CP.getDDbyLocale(locale);
			    		dd.find('span.select').addClass('error');
			    	}
			    	for (var i=0; i < successes.length; i++) {
			    		var locale = successes[i];
			    		var dd = CP.getDDbyLocale(locale);
			    		dd.find('span.select').addClass('success');
			    	}
			    }
			}
        else {
                CP.hideWait();
                $("#newUriError").html("Error: Unable to clone. URL already exists in " + CP.langErrorArray.join(', ')).show();
                for (var i=0; i < CP.langErrorArray.length; i++) {
                    var locale = CP.langErrorArray[i];
                    var dd = CP.getDDbyLocale(locale);
                    dd.find('span.select').addClass('error');
                }
            }
		}
	},
	getDDbyLocale: function(locale) {
		return $('.langSelect').filter(function(){
			return $('select', this).val() == locale;
		});
	},
	langArray: [],

	showWait: function(text)
	{
		$(".panel-wait").find("p").text(text).end().show();
	},

	hideWait: function()
	{
		$(".panel-wait").hide();
	},

	verifyUrl: function($langDD, fullUrl)
	{
		var locale = $langDD.val();
		var lang = getLangForCloning(locale);
		var toSite = getCountryForCloning(locale);
		var span = $langDD.closest("span");
        var site = getUrlParameter("site");

		if (span.hasClass('success')) {
			CP.langArray.push(locale);
		} else {
			$.ajax({
				url: sharedPrefix + "/ice/resources/ajax/validateUrlBeforeCloning",
				dataType: "text",
				async: false,
				data:
				{
					lang: lang,
					toSite: toSite,
					url: fullUrl,
                    site: site
				},
				success: function(data)
				{
					var delim = data.indexOf("\n");
					if (delim != -1)
					{

						var isValid = data.substring(0, delim);
						if(isValid != 'true')
						{
                            CP.langErrorArray.push(locale)
						}
						else
						{
							CP.langArray.push(locale);
						}
					}
				}
			});
		}
	},

	updateSpanText: function(ctrl)
	{
		var $this = $(ctrl).closest("dd");
		var $span = $this.find("span.text");
		var $option = $this.find("option:selected");

		$span.text($option.val());
	},

	addLangSelect: function()
	{
		CP.hideErrors();

		var $select = $(".langSelect").first().clone();

		$select.find("option:selected").removeAttr("selected").end().find("option").first().attr("selected", "selected");
		$select.find("span.text").text($select.find("option:selected").text());
		$select.find("select").on("change", function(){CP.updateSpanText(this);});
		$("#langSelects").append($select).animate({
			scrollTop: $(".langSelect").last().offset().top
		});
	},

	removeSelect: function(ctrl)
	{
		var $langSelect = $(ctrl).closest(".langSelect");

		if($(".langSelect").length == 1)
		{
			$langSelect.find("option:selected").removeAttr("selected").end().find("option").first().attr("selected", "selected");
			$langSelect.find("span.text").text($langSelect.find("option:selected").text());
		}
		else
		{
			$langSelect.remove();
		}

		CP.hideErrors();
	},

    validateUri: function()
    {
        // add characters to the [] to make them a valid character
        let regex = new RegExp("[^\/a-zA-Z0-9\-$_.+!*'(),]+");
        let uri = $('#newUri');
        return uri.val.replace(regex ,'');
    }
}

$(function(){
	CP.hideErrors();
});
