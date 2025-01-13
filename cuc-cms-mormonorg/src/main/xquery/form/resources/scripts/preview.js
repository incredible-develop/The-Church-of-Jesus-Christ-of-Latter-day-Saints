var devices = [
  {
    name: 'Custom',
    os: 'other',
    dimensions: {
      portrait: {
        width: 400,
        height: 400
      },
      landscape: {
        width: 400,
        height: 400
      }
    }
  },
  {
    name: 'Desktop',
    os: 'other',
    thumbnail: sharedPrefix + "/form/resources/images/desktop.png",
    dimensions: {
      portrait: {
        width: 768,
        height: 1024
      },
      landscape: {
        width: 1024,
        height: 768
      }
    }
  },
  {
    name: 'Google Nexus 7',
    os: 'android',
    thumbnail: sharedPrefix + "/form/resources/images/nexus7.png",
    dimensions: {
      portrait: {
        width: 603,
        height: 911,
        chrome: {
          top: 135,
          right: 81,
          bottom: 194,
          left: 77,
          statusBar: 26,
          image: sharedPrefix + "/form/resources/images/nexus7.png"
        }
      },
      landscape: {
        width: 966,
        height: 548,
        chrome: {
          top: 81,
          right: 194,
          bottom: 135,
          left: 135,
          statusBar: 26,
          image: sharedPrefix + "/form/resources/images/nexus7landscape.png"
        }
      }
    }
  },
  {
    name: 'iPad & iPad Mini',
    os: 'ios',
    thumbnail: sharedPrefix + "/form/resources/images/ipad.png",
    dimensions:{
      portrait: {
        width: 768,
        height: 1024,
        chrome: {
          top: 110,
          right: 98,
          bottom: 123,
          left: 103,
          statusBar: 20,
          image: sharedPrefix + "/form/resources/images/ipad.png"
        }
      },
      landscape: {
        width: 1024,
        height: 768,
        chrome: {
          top: 98,
          right: 123,
          bottom: 103,
          left: 110,
          statusBar: 20,
          image: sharedPrefix + "/form/resources/images/ipadlandscape.png"
        }
      }
    }
  },
  {
    name: 'iPhone 3/4',
    os: 'ios',
    thumbnail: sharedPrefix + "/form/resources/images/iphone4.png",
    dimensions: {
      portrait: {
        width: 320,
        height: 480,
        chrome: {
          top: 134,
          right: 28,
          bottom: 130,
          left: 31,
          statusBar: 20,
          image: sharedPrefix + "/form/resources/images/iphone4.png"
        }
      },
      landscape: {
        width: 480,
        height: 320,
        chrome: {        
          top: 28,
          right: 130,
          bottom: 31,
          left: 134,
          statusBar: 20,
          image: sharedPrefix + "/form/resources/images/iphone4landscape.png"
        }
      }
    }
  },
  {
    name: 'iPhone 5',
    os: 'ios',
    thumbnail: sharedPrefix + "/form/resources/images/iphone5.png", 
    dimensions: {
      portrait: {
        width: 320,
        height: 568,
        chrome: {
          top: 118,
          right: 26,
          bottom: 114,
          left: 32,
          statusBar: 19,
          image: sharedPrefix + "/form/resources/images/iphone5.png"
        }
      },
      landscape: {
        width: 568,
        height: 320,
        chrome: {
          top: 26,
          right: 114,
          bottom: 32,
          left: 118,
          statusBar: 19,
          image: sharedPrefix + "/form/resources/images/iphone5landscape.png"
        }
      }
    }
  },
  {
    name: 'Kindle Fire',
    os: 'android',
    dimensions: {
      portrait: {
        width: 600,
        height: 800
      },
      landscape: {
        width: 800,
        height: 600
      }
    }
  },
  {
    name: 'Kindle Fire HD 7"',
    os: 'android',
    dimensions: {
      portrait: {
        width: 533,
        height: 853
      },
      landscape: {
        width: 853,
        height: 533
      }
    }
  },
  {
    name: 'Kindle Fire HD 8.9"',
    os: 'android',
    dimensions: {
      portrait: {
        width: 800,
        height: 1280
      },
      landscape: {
        width: 1280,
        height: 800
      }
    }
  },
  {
    name: 'Samsung Galaxy S3/S4',
    os: 'android',
    thumbnail: sharedPrefix + "/form/resources/images/galaxys3.png",
    dimensions: {
      portrait: {
        width: 360,
        height: 640,
        chrome: {
          top: 77,
          right: 29,
          bottom: 95,
          left: 29,
          statusBar: 26,
          image: sharedPrefix + "/form/resources/images/galaxys3.png"
        }
      },
      landscape: {
        width: 640,
        height: 360,
        chrome: {
          top: 29,
          right: 95,
          bottom: 29,
          left: 76,
          statusBar: 26,
          image: sharedPrefix + "/form/resources/images/galaxys3landscape.png"
        }
      }
    }
  },
  {
    name: 'Samsung Galaxy Tablet',
    os: 'android',
    dimensions: {
      portrait: {
        width: 600,
        height: 966
      },
      landscape: {
        width: 966,
        height: 600
      }
    }
  }
]


var deviceList = Handlebars.compile('<ul class="slides">{{#each this}}<li data-value="{{index}}">{{#if thumbnail}}<img src="{{thumbnail}}"/>{{else}}<span class="ldse-icon-logo"></span>{{/if}}<p>{{name}}</p>{{/each}}</ul>');

var Preview = {

  defaultDevice: 3, // 0 based index of devices object to select
  defaultCarouselPage: 0, //0 based inex of pages so correct object shows

  animateSpeedRatio: 1,
  animateSpeedFallback: 300,

  customHolder: false, //initial false, hasn't been called before
  customCurrent: "",

  init: function()
  {
    //When preview button is clicked we need to fire a window resize so that the flexslider will show properly
    $("#preview").click(Preview.fireResize);

    //set a resize callback to determine whether comparison can show next to eachother or not
    LDSE.resizeCallbacks.previewResize = function(){
      // console.log("windows resize is being fired");
      Preview.resizeCompare();
    };

    // $(".preview-iframe-container").resizable({
    //  helper: "ui-resizable-helper",
    //  maxWidth: $("#preview-body").width()
    // });
    // setTimeout("Preview.setMaxWidth()", 5000);
    $(".preview-url").on("keypress", function(e){
      if(e.which == 13)
      {
        $(this).closest("div").find(".preview-go").click();
        return false;
      }
    });

    Preview.deviceGenerate();

    //listener for device size change
    $(".flexslider").on("click", ".slides li", Preview.deviceChange);

    $(".preview-orientation button").click(Preview.updateOrientation);

    //sets max-width for flexslider dynamically based on number of devices
    Preview.setMaxWidthFlexslider();

    $(window).load(function(){
      Preview.setFlexslider();
    });

  },

  animateIframe: function(iframe, div, width, height, top, right, bottom, left, statusBar, image){
    //iframe should be a jquery object, height and width should be a number unless you need the width to be a percent
    // console.log(width, height, top, right, bottom, left, statusBar, image)
    //remove the background image first - it will be added back in on the div.animate callback
    div.css({'background-image': 'none', 'background-repeat': 'no-repeat'});
    var speed;
    if(typeof(width) == 'string'){
      speed = Preview.animateSpeedFallback;
    }else{
      speed = iframe.width() - width < 0 ? (iframe.width() - width) * -1 : (iframe.width() - width) * 1;
      speed = speed * Preview.animateSpeedRatio;
    }
    iframe.animate({width: width, height: height - statusBar, top: top + statusBar, left: left}, speed).css({position: "absolute"});
      //must multiply these vars by 1 otherwize they are interpreted as strings and 100 becomes 10,000
    div.animate({width: (width * 1) + (right * 1) + (left * 1), height: (height * 1) + (top * 1) + (bottom * 1)}, speed, function(){
      //loading the image after the containter has re-sized
      if(image != null){
        $(this).addClass('noBoxShadow').css({'background-image': 'url('+image+')', 'background-repeat': 'no-repeat'});
      }else{
        $(this).removeClass('noBoxShadow');
      }

      //must fire the resize function so the devices don't overlap
      Preview.resizeCompare();
    });

  },
  
  current: function()
  {
    $("#preview-left .preview-url").val($("#preview-url").val());
    $("#preview-left .preview-go").click();
  },

  deviceChange: function(){
    var value = $(this).data("value");

    // console.log("Change Device", value);

    //check for custom dimensions
    if(devices[value].name == "Custom"){
      //check customHolder
        if(!Preview.customHolder){
          Preview.customCurrent = $(this);
          //modal
          var display = '<div class="confirmation"><header class="ldse-section--header"><h2>Set custom dimensions</h2></header><div class="ldse-section--body ldse-form ldse-preview-custom"><dl><dt><label for="reason">Width:</label><input type="number" class="preview-custom-width" value="400" /></dt></dl><dl><dt><label for="reason">Height:</label><input type="number" class="preview-custom-height" value="400" /></dt></dl><div class="ldse-form-buttons"><button type="button" class="ldse-button primary ldse-icon-check2" value="Apply">Apply</button><button type="button" class="ldse-button ldse-icon-x ldse-close-modal" value="Cancel">Cancel</button></div></div></div>';
          modal.find('div').remove();
          modal.append(display).trigger('open');
          modal.find('.ldse-preview-custom input').on("keypress", function(e){
            if(e.which == 13)
            {
               modal.find('.ldse-button.primary').click();
            }
          });
          modal.find('.ldse-button.primary').click(function () {
            var height = modal.find(".preview-custom-height").val() || 400;
            var width = modal.find(".preview-custom-width").val() || 400;
            devices[value].dimensions.landscape.height = width;
            devices[value].dimensions.portrait.height = height;
            devices[value].dimensions.landscape.width = height;
            devices[value].dimensions.portrait.width = width;
            Preview.customCurrent.click();
            modal.trigger('close');
            return false;
          });

          modal.find('.ldse-button.ldse-close-modal').click(function(){
            modal.trigger('close');
            Preview.customHolder = false;
            $(".ldse-modal-backdrop").unbind("click");
            return false;
          });

          $(".ldse-modal-backdrop").not(".ldse-modal, .ldse-modal *").click(function(e){
            modal.trigger('close');
            Preview.customHolder = false;
            $(".ldse-modal-backdrop").unbind("click");
            return false;
          })

          Preview.customHolder = true;

          return false;
        }else{
          //reset custom holder
          Preview.customHolder = false;
        }
    }

    //Set customHolder to false
    Preview.customHolder = false;

    $(this).addClass("active").siblings().removeClass("active");

    // console.log("device change");
    // console.log("closest div", $(this).closest("div.flexslider"));
    var orientation = $(this).closest("div.ldse-preview-window").find(".preview-orientation button.active").data("value");
    // console.log($(this), orientation);
    var iframe = $("iframe." + $(this).closest("div.flexslider").data("iframe")); //must change size of iframe 
    var divIframe = $("div." + $(this).closest("div.flexslider").data("iframe")); //and the containing div
    // console.log("value", value);
    // if(value == 'auto'){
    //   Preview.animateIframe(iframe, '100%', '600px');
    //   Preview.deviceFloat(false);
    // }else{
      var dimensions = devices[value].dimensions[orientation];
      var width = dimensions.width;
      var height = dimensions.height;
      var chrome = dimensions.chrome || {};
      // console.log("chrome", chrome);
      var top = chrome.top || 0;
      var right = chrome.right || 0;
      var bottom = chrome.bottom || 0;
      var left = chrome.left || 0;
      var statusBar = chrome.statusBar || 0;
      var image = chrome.image || null;
      Preview.animateIframe(iframe, divIframe, width, height, top, right, bottom, left, statusBar, image);
      Preview.deviceFloat(true);
      Preview.deviceInfo($(this), width, height);
    // }

  },

  deviceFloat: function(toFloat){
    if(toFloat){
      $(".ldse-preview-window").addClass("push-left");
    }else{
      $(".ldse-preview-window").removeClass("push-left");
    }
  },

  deviceInfo: function(element, width, height){
    var infoBox = element.closest("div.ldse-preview-window").find("div.ldse-device-info");
    $(".ldse-device-width", infoBox).text(width + "px");
    $(".ldse-device-height", infoBox).text(height + "px");
  },

  deviceGenerate: function(){
    //first add the index to the object - supported natively in latest handlebars, but not in the version ldse is using
    for(var i = 0; i < devices.length; i++){
      devices[i].index = i;
    }

    $(".ldse-device-list.ldse-device-type").append(deviceList(devices));
    // console.log("Loaded devices");
    // $("select.ldse-device-list.ldse-device-type").val("0");
    setTimeout(function(){
      // $("select.ldse-device-list.ldse-device-type").change();
      // Preview.setFlexslider();
      $(".ldse-device-list .slides").each(function(){
        $("li",this).eq(Preview.defaultDevice).click();
      });
    }, 200);
  },

  setFlexslider: function(){
    // console.log("setting flexslider")
    $(".flexslider").flexslider({
      slideshow: false,
      animation: 'slide',
      itemWidth: 110,
      itemMargin: 0, 
      startAt: Preview.defaultCarouselPage
    });

    Preview.fireResize();
  },

  fireResize:function(){
    // console.log("firing resize")
    //resize needs to fire twice to get the flexslider to resize properly - it is finiky
    setTimeout(function(){
      $(window).resize();
    }, 300);
    setTimeout(function(){
      $(window).resize();
    }, 600);
  },

  resizeCompare: function(){

    if($("#comparison-preview").is(":checked")) {
      containerWidth = $("#preview-body").innerWidth() - 100; //subtract margin and padding from available width
      container50 = containerWidth/2;
      iframeLeftWidth = $("#preview-left .preview-iframe-container").outerWidth();
      iframeRightWidth = $("#preview-right .preview-iframe-container").outerWidth();

      // console.log(containerWidth, iframeLeftWidth, iframeRightWidth, iframeLeftWidth+iframeRightWidth);
      
      if( iframeRightWidth < container50 && iframeLeftWidth < container50 ){
        if(!$("#preview-left, #preview-right").hasClass("ldse-preview-half")){
          Preview.fireResize();
        }
        $("#preview-left, #preview-right").addClass("ldse-preview-half");
      }else{
        $("#preview-left, #preview-right").removeClass("ldse-preview-half");
      }
    }else{
      $("#preview-left, #preview-right").removeClass("ldse-preview-half");
    }

  },

  setMaxWidthFlexslider: function(){
    var maxWidth = devices.length * 110 + 15;
    $(".flexslider").css({'max-width': maxWidth+"px"});
  },
  
  updateOrientation: function(e){

    $(this).addClass("active").siblings().removeClass("active");

    Preview.customHolder = true; // set this to true so it doesn't ask for new dimensions when switching orientation

    $(this).closest("div.ldse-preview-window").find(".flexslider li.active").click();

    e.preventDefault();
    e.stopPropagation();
  },
  
  toggle: function()
  {
    var $checkbox = $("#comparison-preview");
    
    // $(".preview-iframe-container").removeAttr("style");
    
    if($checkbox.is(":checked"))
    {
      $("#preview-left").addClass("compare-preview");
      // Preview.setMaxWidth();
      $("#preview-right").show();
    }
    else
    {
      $("#preview-left").removeClass("compare-preview");
      // Preview.setMaxWidth();
      $("#preview-right").hide();
    }

    //for some reason it has to be fired twice - otherwize the view doesn't update and the devices overlap
    Preview.fireResize();
  },

  tileClick: function()
  {
    try {
      $("#preview-haschanges").toggle(hasChanges($(".form-data")));
    }catch(e){
      //do nothing
    }
    
    $("#preview-body iframe").each(function()
    {
      if($(this).attr("src") == "")
      {
        $(this).attr("src", $(this).parent("div").parent("div").find("input").val());
      }
    });
  },
  
  go: function(ctrl)
  {
    var $this = $(ctrl);
    if($this.parent("div").find("input").val() != "")
    {
      $this.parent("div").parent("div").find("iframe").attr("src", $this.parent("div").find("input").val());
    }
  }
};