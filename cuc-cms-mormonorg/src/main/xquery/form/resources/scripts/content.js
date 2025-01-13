jQuery(function(){
	// color banner flag
	jQuery('#platform-canvas').append('<div class="flag">&nbsp;</div>');
	
	jQuery('#platform-canvas-nav .leftNavSubList').click(function () {
		if (jQuery(this).hasClass('show')) {
			jQuery(this).next('ul').hide();
			jQuery(this).removeClass('show');
		} else {
			jQuery(this).next('ul').show();
			jQuery(this).addClass('show');
		}
	});
	
	// breadcrumb dropdown arrow
	jQuery('.filed-under > li > ul').append('<li class="dropdown-triangle">&nbsp;</li>');
	
	// sidebar tool arrows
	jQuery('#secondary .tools .download, #secondary .tools .share, #secondary .tools .notebook, #secondary .tools .export, .secondary-top .tools .share, .tools-box .tools .share, .profile-desc .tools .share').append('<span class="tool-arrow">&nbsp;</span>');
	
	// setup menus
	showHide('#secondary .tools .print-list', '#secondary .tools .print');
	showHide('#secondary .tools .download-list', '#secondary .tools .download');
	showHide('#secondary .tools .share-list', '#secondary .tools .share');
	showHide('#secondary .tools .notebook-list', '#secondary .tools .notebook');
	showHide('#secondary .tools .export-list', '#secondary .tools .export');
	showHide('.secondary-top .tools .share-list', '.secondary-top .tools .share');
	showHide('.profile-desc .tools .share-list', '.profile-desc .tools .share');
	showHide('#news .tools .share-list', '#news .tools .share');
    
	// select menu
	jQuery('.select-menu-list').hide();
	
	jQuery('.select-menu').each(function() {
		var buttonWidth = jQuery(this).children('.select-menu-button').innerWidth() - 24;
		jQuery(this).children('.select-menu-list').css("width", buttonWidth);
	})
		
	jQuery('#details .select-menu > .select-menu-button, .watch-conference .select-menu > .select-menu-button, .select-menu > .select-menu-button').toggle(
		function(){
			jQuery(this).parent().children('.select-menu-list').slideDown('fast');
			jQuery(this).parent().addClass('active');
		},
		function(){
			jQuery(this).parent().children('.select-menu-list').slideUp('fast');
			jQuery(this).parent().removeClass('active');
		}
	);
	
	jQuery('body').click(function(){
		if (jQuery('.select-menu').hasClass('active')) {
			jQuery('.select-menu.active > .select-menu-button').click();
		};
		jQuery('.fly-out,.click-menu').hide();
	});
	
	// conference list top arrow
	jQuery('.conf-menu-list, .heading-menu-list').append('<li class="triangle"/>');
	
	// show/hide conference list 
	jQuery('.conf-menu .conf-menu-button, .heading-menu .heading-menu-button').toggle(
		function() {
			jQuery('.conf-menu-list, .heading-menu-list').fadeIn();
			jQuery('.conf-menu, .heading-menu').addClass('active');
		},
		function() {
			jQuery('.conf-menu-list, .heading-menu-list').fadeOut();
			jQuery('.conf-menu, .heading-menu').removeClass('active');
		}
	);
	
	// hide conference list on blur
	jQuery('body').click(function() {
		if (jQuery('.conf-menu, .heading-menu').hasClass('active')) {
			jQuery('.conf-menu.active .conf-menu-button, .heading-menu.active .heading-menu-button').click();
		};
	});
	
	// IE8 and below need extra trickery for chuck. They can't do rounded corners normally so use VML
	if($.browser.msie && parseInt($.browser.version,10) <= 8){
		$(".chuckit").each(function(){
			var chuckit = $(this);
			var curChuck = $('<span class="chuck invisible"/>');

			chuckit
				.append(curChuck);
			var oval = $('<v:oval fillcolor="'+curChuck.css("backgroundColor")+'" stroked="false" class="vmlchuck" start="'+chuckit.css("backgroundColor")+'"><span></span></v:oval>');
			chuckit.append(oval);
			$(this).parent().bind("mouseover mouseout", function(){
				var curParent = this;
				setTimeout(function(){
					$(".vmlchuck",curParent)[0].fillcolor = curChuck.css("backgroundColor");
				},1);
			});
			if(chuckit.hasClass("chuck-left")){
				chuckit.prepend(curChuck).prepend(oval);
			}
		});
	}

	/* Download Menu Controls */
	// show/hide download menu
	clickMenu('.download-wrap .download-menu','.download-wrap .download','fade');

	// hide download menu via close button
	$('.download-wrap > .download-menu .close').click(function(e) {
		e.preventDefault();
		$(this).parents('.download-wrap').children('.download.active').click();
	});

	// hide download menu via clicking outside it
	$('body').click(function(e) {
		if(!$(e.target).is('.download-menu') && !$(e.target).is('.download-menu *')) {
			//$('.download.active').click(); // this causes major problems on the playlist pages so went with below's alternative
			$('.download-wrap > a.active').removeClass('active').next('.download-menu').fadeOut();
		}
	});
}); // END DOC READY

// show/hide menu
function showHide(what, trig, hideTxt, showTxt) {
    jQuery(what).hide();
    jQuery(trig).click(function() {
        if (jQuery(this).hasClass('hide')) {
            jQuery(what).slideUp('fast');
            jQuery(this).removeClass('hide').addClass('show');
            if (showTxt) jQuery(trig).html(showTxt + '<span>&nbsp;</span>');     
        } else {
            jQuery(what).slideDown('fast');
            jQuery(trig).removeClass('show').addClass('hide');
            if (hideTxt) jQuery(trig).html(hideTxt + '<span>&nbsp;</span>');
        }
        return false;
    });
}

function closeMenu(what, trig){
	jQuery(trig).click(function(){
		jQuery(what).click();
	});
}

// slide/fade/show menus
function clickMenu(menu, trigger, transition, hideTxt, showTxt) { 
	// hide menu
	jQuery(menu).hide().addClass('click-menu');
	// setup transitions
	var t = (transition == 'slide' ? ['slideDown', 'slideUp'] : (transition == 'fade' ? ['fadeIn', 'fadeOut'] : ['show', 'hide']));
	// setup click toggle
	jQuery(trigger).toggle(
		function() {
			jQuery('.click-menu').prev('.active').click(); //closes any open menus
			jQuery(this).addClass('active');
			var currentMenu = jQuery(this).nextAll(menu).first();
			jQuery(currentMenu)[t[0]]();
			if (hideTxt) jQuery(this).html(hideTxt + '<span>&nbsp;</span>');
		},
		function() {
			jQuery(this).removeClass('active');
			var currentMenu = jQuery(this).nextAll(menu).first();
			jQuery(currentMenu)[t[1]]();
			if (showTxt) jQuery(this).html(showTxt + '<span>&nbsp;</span>');
		}
	);
}

//cache images
menuHoverArrow = new Image()
// menuHoverArrow.src = "/resources/images/common/arrow-4x7-a4a39e.png"

// set columns or elements to have equal heights
function setEqualHeight(boxes) {
	if (boxes.length > 1) {
		var tallestBox = 0;
		boxes.each(function(){
			currentHeight = $(this).height();
			if (currentHeight > tallestBox) {
				tallestBox = currentHeight;
			}
		});
		boxes.height(tallestBox);
	}
}

// hover arrows for carousels and galleries
function galleryHotSpot(prev,next,wrapper,width){
	// console.debug(arguments);
	$(wrapper).bind("mousemove.hotspot",function(e){
		// console.debug(e.clientX,e.clientY);
		// console.debug(e.layerX,e.layerY);
		var elem = $(this),
			hotSpotWidth = width,
			elemX = elem.offset().left;
		
		if(e.clientX - elemX < hotSpotWidth){
			// only show once so we don't show over and over
			if(!elem.data("left")){
				$(prev).show();
				elem.data("left",true);
				// console.debug("showing left");
			}
		} else {
			if(elem.data("left")){
				$(prev).hide();
				elem.data("left",false);
				// console.debug("hiding left");
			}
		}
		
		if(e.clientX - elemX > elem.width()-hotSpotWidth){
			// only show once so we don't show over and over
			if(!elem.data("right")){
				$(next).show();
				elem.data("right",true);
				// console.debug("showing right");
			}
		} else {
			if(elem.data("right")){
				$(next).hide();
				elem.data("right",false);
				// console.debug("hiding right");
			}
		}
	}).bind("mouseout.hotspot",function(){
		// console.debug("out");
		$(prev+", "+next).hide();
		$(this).data("left",false).data("right",false);
	}).trigger("mouseout.hotspot");
}

//Popup Window Functions
function newWindow(theURL) {
	var portionFloat = .6;
	var features='menubar=yes,scrollbars=yes,buttonbar=yes,status=yes,toolbar=yes,resizable=yes,location=yes,';

	winName = 'contentWindow';
	windowCoord = setWindowValues();

	var windowWidth = windowCoord.shift();
	var windowHeight = windowCoord.shift();
	var screenWidth = windowCoord.shift();
	var screenHeight = windowCoord.shift();
	var calcTop = windowCoord.shift();
	var calcLeft = windowCoord.shift();

	newWidth = parseInt(windowWidth * portionFloat);
	newHeight = parseInt(windowHeight * portionFloat);

	newXOffset = parseInt((windowWidth - newWidth) * .5) + calcLeft;
	newYOffset = parseInt((windowHeight - newHeight) * .5) + calcTop;

	if (navigator.appName == 'Microsoft Internet Explorer'){
	    offsetString = ',top=' + newYOffset + ', left=' + newXOffset;
	    }
	    else {
	    offsetString = ',screenX=' + newYOffset + ', screenY=' + newXOffset;
	    }

	features = features + 'width=' + newWidth + ',height=' + newHeight + offsetString;

	windowName = self.open(theURL,winName,features);
	if (windowName.focus) {windowName.focus()}
}

function setWindowValues(){
 
    windowWidth = getWindowWidth(self); // or you could just apply some value here
    windowHeight = getWindowHeight(self); // or you could just apply some value here
    screenWidth = screen.availWidth ? screen.availWidth : screen.width;
    screenHeight = screen.availHeight ? screen.availHeight : screen.height;
    
    calcTop = window.screenY ? window.screenY : self.screenTop;
    calcLeft = window.screenX ? window.screenX : self.screenLeft;
    
    return (windowCoord = new Array(windowWidth,windowHeight,screenWidth,screenHeight,calcTop,calcLeft));
}

function getWindowWidth (windowObject) {
    var windowWidth = 0

    if (windowObject.innerWidth)
    {
        windowWidth = windowObject.innerWidth;
    }
    else if (windowObject.document.documentElement && windowObject.document.documentElement.clientWidth)
    {
        windowWidth = windowObject.document.documentElement.clientWidth;
    }
    else if (windowObject.document.body)
    {
        windowWidth = windowObject.document.body.clientWidth;
    }
    if (windowWidth < 500){
        windowWidth = 500;
    }
    return windowWidth;
}

function getWindowHeight (windowObject) {
    
    if (windowObject.innerHeight)
    {
        windowHeight = windowObject.innerHeight;
    }
    else if (windowObject.document.documentElement && windowObject.document.documentElement.clientHeight)
    {
        windowHeight = windowObject.document.documentElement.clientHeight;
    }
    else if (windowObject.document.body)
    {
        windowHeight = windowObject.document.body.clientHeight;
    }
    if (windowHeight < 325){
        windowHeight = 325;
    }
    return windowHeight;
}

/**
 * Conference session countdown.
 */

cd_isReady = null;
cd_isLive = null;
cd_hasNext = null;
cd_nextStart = null;
cd_nextStop = null;
cd_timeStamp = null;
cd_interval = null;

function calculateCountdown() {
    if(cd_isReady && !cd_isLive && cd_hasNext) {
    	currentDate = new Date(cd_timeStamp);        
        days = 0;
        hours = 0;
        minutes = 0;
        difference = cd_nextStart - currentDate.getTime();
        if(difference > 86400000) {
            days = Math.floor(difference / 86400000);
            difference = difference - (days * 86400000);
        }
        if(difference > 3600000) {
            hours = Math.floor(difference / 3600000);
            difference = difference - (hours * 3600000);
        }
        if(difference > 60000) {
            minutes = Math.floor(difference / 60000);
            difference = difference - (minutes * 60000);
        }
        countdownString = '';
        if(days != 0) {
            countdownString += days + countdownDaysLabel;
        }
        if(days != 0 && hours != 0) {
        	countdownString += ', ';
        }
        else {
        	countdownString += ' ';
        }
        if(hours != 0) {
            countdownString += hours + countdownHoursLabel;
        }
        if(hours != 0 && minutes != 0) {
        	countdownString += ', ';
        }
        else {
        	countdownString += ' ';
        }
        if(minutes != 0) {
            countdownString += minutes + countdownMinutesLabel;
        }        
        if(currentDate.getTime() > cd_nextStop) {
    		getCountdown();
    	}
        else {
        	jQuery(countdownTimerID).html(countdownString);
            jQuery(countdownBlockID).show();
        }
    }
    else {
    	jQuery(countdownBlockID).hide();
    }
};

function getCountdown() {
	cd_isReady = null;
	cd_isLive = null;
    cd_hasNext = null;
    cd_nextStart = null;
    cd_nextStop = null;
    cd_timeStamp = null;
    if(cd_interval != null) {
    	clearInterval(cd_interval);
    }
	jQuery(countdownBlockID).hide();
    jQuery.ajax({
        type:       'POST',
        cache:      false,
        dataType:   'json',
        url:        countdownDataURL,
        success:    function(data) {
        	cd_isReady = true;
            cd_isLive = data.isLive;
            cd_hasNext = data.hasNext;
            cd_nextStart = Date.parse(data.nextStart);
            cd_nextStop = Date.parse(data.nextStop);
            cd_timeStamp = Date.parse(data.timeStamp);
            calculateCountdown();            
            cd_interval = setInterval('calculateCountdown()', 60000);
        },
        error:		function(data, desc) {            
        	cd_interval = setInterval('getCountdown()', 60000);
        }
    });
};

// detect cal link height and position fly-out accordingly
jQuery('.cal-box dd ul li a.event-title').live("click",function() {
    var linkHeight = jQuery(this).height() + 9;
    jQuery('.cal-box .fly-out').css('bottom', linkHeight);
    jQuery(".fly-out").hide();
    jQuery(this).closest('li').find('.click-menu').fadeIn();
    return false;
});
