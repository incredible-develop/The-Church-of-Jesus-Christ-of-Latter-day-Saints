/********************************
Plugins
********************************/
/*! jQuery UI - v1.8.20 - 2012-04-30
* https://github.com/jquery/jquery-ui
* Includes: jquery.ui.core.js
* Copyright (c) 2012 AUTHORS.txt; Licensed MIT, GPL */
(function(a,b){function c(b,c){var e=b.nodeName.toLowerCase();if("area"===e){var f=b.parentNode,g=f.name,h;return!b.href||!g||f.nodeName.toLowerCase()!=="map"?!1:(h=a("img[usemap=#"+g+"]")[0],!!h&&d(h))}return(/input|select|textarea|button|object/.test(e)?!b.disabled:"a"==e?b.href||c:c)&&d(b)}function d(b){return!a(b).parents().andSelf().filter(function(){return a.curCSS(this,"visibility")==="hidden"||a.expr.filters.hidden(this)}).length}a.ui=a.ui||{};if(a.ui.version)return;a.extend(a.ui,{version:"1.8.20",keyCode:{ALT:18,BACKSPACE:8,CAPS_LOCK:20,COMMA:188,COMMAND:91,COMMAND_LEFT:91,COMMAND_RIGHT:93,CONTROL:17,DELETE:46,DOWN:40,END:35,ENTER:13,ESCAPE:27,HOME:36,INSERT:45,LEFT:37,MENU:93,NUMPAD_ADD:107,NUMPAD_DECIMAL:110,NUMPAD_DIVIDE:111,NUMPAD_ENTER:108,NUMPAD_MULTIPLY:106,NUMPAD_SUBTRACT:109,PAGE_DOWN:34,PAGE_UP:33,PERIOD:190,RIGHT:39,SHIFT:16,SPACE:32,TAB:9,UP:38,WINDOWS:91}}),a.fn.extend({propAttr:a.fn.prop||a.fn.attr,_focus:a.fn.focus,focus:function(b,c){return typeof b=="number"?this.each(function(){var d=this;setTimeout(function(){a(d).focus(),c&&c.call(d)},b)}):this._focus.apply(this,arguments)},scrollParent:function(){var b;return a.browser.msie&&/(static|relative)/.test(this.css("position"))||/absolute/.test(this.css("position"))?b=this.parents().filter(function(){return/(relative|absolute|fixed)/.test(a.curCSS(this,"position",1))&&/(auto|scroll)/.test(a.curCSS(this,"overflow",1)+a.curCSS(this,"overflow-y",1)+a.curCSS(this,"overflow-x",1))}).eq(0):b=this.parents().filter(function(){return/(auto|scroll)/.test(a.curCSS(this,"overflow",1)+a.curCSS(this,"overflow-y",1)+a.curCSS(this,"overflow-x",1))}).eq(0),/fixed/.test(this.css("position"))||!b.length?a(document):b},zIndex:function(c){if(c!==b)return this.css("zIndex",c);if(this.length){var d=a(this[0]),e,f;while(d.length&&d[0]!==document){e=d.css("position");if(e==="absolute"||e==="relative"||e==="fixed"){f=parseInt(d.css("zIndex"),10);if(!isNaN(f)&&f!==0)return f}d=d.parent()}}return 0},disableSelection:function(){return this.bind((a.support.selectstart?"selectstart":"mousedown")+".ui-disableSelection",function(a){a.preventDefault()})},enableSelection:function(){return this.unbind(".ui-disableSelection")}}),a.each(["Width","Height"],function(c,d){function h(b,c,d,f){return a.each(e,function(){c-=parseFloat(a.curCSS(b,"padding"+this,!0))||0,d&&(c-=parseFloat(a.curCSS(b,"border"+this+"Width",!0))||0),f&&(c-=parseFloat(a.curCSS(b,"margin"+this,!0))||0)}),c}var e=d==="Width"?["Left","Right"]:["Top","Bottom"],f=d.toLowerCase(),g={innerWidth:a.fn.innerWidth,innerHeight:a.fn.innerHeight,outerWidth:a.fn.outerWidth,outerHeight:a.fn.outerHeight};a.fn["inner"+d]=function(c){return c===b?g["inner"+d].call(this):this.each(function(){a(this).css(f,h(this,c)+"px")})},a.fn["outer"+d]=function(b,c){return typeof b!="number"?g["outer"+d].call(this,b):this.each(function(){a(this).css(f,h(this,b,!0,c)+"px")})}}),a.extend(a.expr[":"],{data:function(b,c,d){return!!a.data(b,d[3])},focusable:function(b){return c(b,!isNaN(a.attr(b,"tabindex")))},tabbable:function(b){var d=a.attr(b,"tabindex"),e=isNaN(d);return(e||d>=0)&&c(b,!e)}}),a(function(){var b=document.body,c=b.appendChild(c=document.createElement("div"));c.offsetHeight,a.extend(c.style,{minHeight:"100px",height:"auto",padding:0,borderWidth:0}),a.support.minHeight=c.offsetHeight===100,a.support.selectstart="onselectstart"in c,b.removeChild(c).style.display="none"}),a.extend(a.ui,{plugin:{add:function(b,c,d){var e=a.ui[b].prototype;for(var f in d)e.plugins[f]=e.plugins[f]||[],e.plugins[f].push([c,d[f]])},call:function(a,b,c){var d=a.plugins[b];if(!d||!a.element[0].parentNode)return;for(var e=0;e<d.length;e++)a.options[d[e][0]]&&d[e][1].apply(a.element,c)}},contains:function(a,b){return document.compareDocumentPosition?a.compareDocumentPosition(b)&16:a!==b&&a.contains(b)},hasScroll:function(b,c){if(a(b).css("overflow")==="hidden")return!1;var d=c&&c==="left"?"scrollLeft":"scrollTop",e=!1;return b[d]>0?!0:(b[d]=1,e=b[d]>0,b[d]=0,e)},isOverAxis:function(a,b,c){return a>b&&a<b+c},isOver:function(b,c,d,e,f,g){return a.ui.isOverAxis(b,d,f)&&a.ui.isOverAxis(c,e,g)}})})(jQuery);
/*! jQuery UI - v1.8.20 - 2012-04-30
* https://github.com/jquery/jquery-ui
* Includes: jquery.ui.widget.js
* Copyright (c) 2012 AUTHORS.txt; Licensed MIT, GPL */
(function(a,b){if(a.cleanData){var c=a.cleanData;a.cleanData=function(b){for(var d=0,e;(e=b[d])!=null;d++)try{a(e).triggerHandler("remove")}catch(f){}c(b)}}else{var d=a.fn.remove;a.fn.remove=function(b,c){return this.each(function(){return c||(!b||a.filter(b,[this]).length)&&a("*",this).add([this]).each(function(){try{a(this).triggerHandler("remove")}catch(b){}}),d.call(a(this),b,c)})}}a.widget=function(b,c,d){var e=b.split(".")[0],f;b=b.split(".")[1],f=e+"-"+b,d||(d=c,c=a.Widget),a.expr[":"][f]=function(c){return!!a.data(c,b)},a[e]=a[e]||{},a[e][b]=function(a,b){arguments.length&&this._createWidget(a,b)};var g=new c;g.options=a.extend(!0,{},g.options),a[e][b].prototype=a.extend(!0,g,{namespace:e,widgetName:b,widgetEventPrefix:a[e][b].prototype.widgetEventPrefix||b,widgetBaseClass:f},d),a.widget.bridge(b,a[e][b])},a.widget.bridge=function(c,d){a.fn[c]=function(e){var f=typeof e=="string",g=Array.prototype.slice.call(arguments,1),h=this;return e=!f&&g.length?a.extend.apply(null,[!0,e].concat(g)):e,f&&e.charAt(0)==="_"?h:(f?this.each(function(){var d=a.data(this,c),f=d&&a.isFunction(d[e])?d[e].apply(d,g):d;if(f!==d&&f!==b)return h=f,!1}):this.each(function(){var b=a.data(this,c);b?b.option(e||{})._init():a.data(this,c,new d(e,this))}),h)}},a.Widget=function(a,b){arguments.length&&this._createWidget(a,b)},a.Widget.prototype={widgetName:"widget",widgetEventPrefix:"",options:{disabled:!1},_createWidget:function(b,c){a.data(c,this.widgetName,this),this.element=a(c),this.options=a.extend(!0,{},this.options,this._getCreateOptions(),b);var d=this;this.element.bind("remove."+this.widgetName,function(){d.destroy()}),this._create(),this._trigger("create"),this._init()},_getCreateOptions:function(){return a.metadata&&a.metadata.get(this.element[0])[this.widgetName]},_create:function(){},_init:function(){},destroy:function(){this.element.unbind("."+this.widgetName).removeData(this.widgetName),this.widget().unbind("."+this.widgetName).removeAttr("aria-disabled").removeClass(this.widgetBaseClass+"-disabled "+"ui-state-disabled")},widget:function(){return this.element},option:function(c,d){var e=c;if(arguments.length===0)return a.extend({},this.options);if(typeof c=="string"){if(d===b)return this.options[c];e={},e[c]=d}return this._setOptions(e),this},_setOptions:function(b){var c=this;return a.each(b,function(a,b){c._setOption(a,b)}),this},_setOption:function(a,b){return this.options[a]=b,a==="disabled"&&this.widget()[b?"addClass":"removeClass"](this.widgetBaseClass+"-disabled"+" "+"ui-state-disabled").attr("aria-disabled",b),this},enable:function(){return this._setOption("disabled",!1)},disable:function(){return this._setOption("disabled",!0)},_trigger:function(b,c,d){var e,f,g=this.options[b];d=d||{},c=a.Event(c),c.type=(b===this.widgetEventPrefix?b:this.widgetEventPrefix+b).toLowerCase(),c.target=this.element[0],f=c.originalEvent;if(f)for(e in f)e in c||(c[e]=f[e]);return this.element.trigger(c,d),!(a.isFunction(g)&&g.call(this.element[0],c,d)===!1||c.isDefaultPrevented())}}})(jQuery);
/*
 * fixSelect
 * @description	Allows us to style the select box across browssers
 * @version		1.1.3 - 2011/8/11
 * @author		Aaron Barker
 * @requires	ui.core.js (1.8+)
 * @licence		Licensed under the MIT license.
 */
(function(e){e.widget("lds.fixSelect",{options:{selectClass:"select",arrowSpanClass:"arrow",textSpanClass:"text",hoverClass:"hover",focusClass:"focus",activeClass:"active",disabledClass:"disabled",padding:0,wrapperTag:"span",deriveWidth:!1},_create:function(){var t=this.options,n=this.element,r=this,i=e("<"+t.wrapperTag+" />"),s=e('<span class="'+t.textSpanClass+'" />'),o=e('<span class="'+t.arrowSpanClass+'" />'),u=n.find(":selected:first"),a=t.activeClass,f=t.hoverClass,l=t.focusClass,c=r.widgetName;n.parent("."+t.selectClass).length&&n.fixSelect("destroy");t.spanTag=s;t.arrowSpanTag=o;n.is("[multiple]")||(i.addClass(t.selectClass).css({position:"relative"}),t.useID&&i.attr("id",t.idPrefix+"-"+n.attr("id")),u.length===0&&(u=n.find("option:first")),r.updateSpanTag(s,u.text()),n.css("opacity",.001),n.wrap(i),n.before(s),n.before(o),i=n.parent("span"),s=n.siblings("span."+t.textSpanClass),o=n.siblings("span."+t.arrowSpanClass),r.updateWidths(),n.css({position:"absolute",top:0,left:0}),!n.is(":visible")&&!t.deriveWidth&&(u=parseInt(i.css("padding-left"),10)+parseInt(i.css("padding-right"),10),o=i.clone(),o.css({position:"absolute",top:"-1000em"}).appendTo("body"),u=o.find("select").outerWidth()-u,i.css({width:"100%"}),t.spanTag.css({width:"100%"}),o.remove()),n.css("opacity",.001),n.bind("change."+c,function(){r.updateSpanTag(s,n.find(":selected").text());i.removeClass(t.activeClass);t.deriveWidth&&r.updateWidths(!0)}).bind("focus."+c,function(){i.addClass(l)}).bind("blur."+c,function(){i.removeClass(l);i.removeClass(a)}).bind("mousedown."+c,function(){i.addClass(a)}).bind("mouseup."+c,function(){i.removeClass(a)}).bind("click."+c,function(){i.removeClass(a)}).bind("mouseover."+c,function(){i.addClass(f)}).bind("mouseout."+c,function(){i.removeClass(f)}).bind("keyup."+c,function(){r.updateSpanTag(s,n.find(":selected").text())}),e(n).attr("disabled")&&i.addClass(t.disabledClass),e(n).attr("readonly")&&r.readonly("true"),r.updateWidths())},disable:function(){this.element.parent("span").addClass(this.options.disabledClass)},enable:function(){this.element.parent("span").removeClass(this.options.disabledClass)},readonly:function(e){this.options.readonly=e||!0},destroy:function(){e.Widget.prototype.destroy.apply(this,arguments);var t=this.element;t.parent().find("span").remove();t.unwrap().css({opacity:"",position:"",top:"",left:""}).unbind("."+this.widgetName)},updateWidths:function(e){var t=this.element,n=this.options,r=t.parent(n.wrapperTag);e||t.trigger("change."+this.widgetName);t.is(":visible")&&(n.deriveWidth?t.css({width:"100%",height:r.outerHeight(),position:"absolute",top:0,left:0}):(r.css({width:"100%"}),n.spanTag.css({width:"100%"})))},updateSpanTag:function(e,t){t?e.text(t):e.html(" ")}});e.extend(e.lds.fixSelect,{version:"1.1.3"})})(jQuery);

/*
 * MultiSelect
 * @description	Take a multiple select element and breakes it into individual selects
 * @version		2.0.7 - 2011/08/15
 * @author		Aaron Barker
 * @requires	ui.core.js (1.8+)
 * @optional
 * @copyright	Intellectual Reserve, Inc.
 * @licence		Licensed under the MIT license. http://www.opensource.org/licenses/mit-license.php
 */
(function(e){e.widget("lds.multiSelect",{options:{addWhere:"bottom",maxFields:0,removePath:"",addPath:"",removeTitle:"Remove this row",addTitle:"Add additional row",adderClass:"sprite icon add",removerClass:"sprite icon delete",removeConfirm:"Are you sure you want to remove this?",matchWidths:!0,onAdd:function(){},onDelete:function(){},onChange:function(){}},_create:function(){var t=this.options,n=this,r=this.element,i;r.hide();if(r.attr("multiple")){this.element.find(":selected").each(function(){this.setAttribute("selected","selected")});i="ui-multiSelect-"+Math.floor(Math.random()*999999);n._setOption("uniqueClass",i);if(!t.maxFields)t.maxFields=r.find("option[value]").length;r.find("option:first").val()!==""&&r.prepend("<option></option>");r.find("option").each(function(t){e(this).attr("msIndex",t)});(r=r.find("option:selected"))&&r.length?r.each(function(){n.addSelect(e(this).attr("msIndex"))}):n.addSelect(0);t.setupDone=!0}},makeSelect:function(t){var n=this,r=this.element.clone(!1);e.support.leadingWhitespace||(r.find(":selected").removeAttr("selected"),this.element.find(":selected").each(function(){r.find("[msIndex="+e(this).attr("msIndex")+"]").attr("selected","selected")}));r.find(":selected").filter(function(){return e(this).attr("msIndex")==t||e(this).attr("msIndex")=="0"?!1:!0}).remove();r.attr({size:"1",id:"ui-multiSelect-"+Math.floor(Math.random()*999999),name:""}).show().removeAttr("multiple").attr("onchange","").bind("change.multiSelect",function(){n._updateValues(r);n.element.trigger("change")}).bind("removeIt.multiSelect",function(){var t=e(this).parents(".wrapper"),r;r=t.next(".wrapper").length?t.next():t.prev();n._updateValues(e(this));e(t).remove();n.updateControls();r.find(":input:visible").eq(0).focus()});return r},addSelect:function(t){var n=this.options,r=n.uniqueClass,i=this,s=this.element,o,u;if(n.disabled)return!1;o=this.makeSelect(t);u=s.siblings("."+r+":last");u.length?e(u).after(o):s.after(o);o.wrap('<div class="wrapper ui-multiSelect ui-widget '+r+'"></div>');r=e(' <a href="#d" class="remover"><span class="'+n.removerClass+'">'+n.removeTitle+"</span></a>").bind("click.multiSelect",function(){e(this).data("canRemove")&&(typeof n.removeConfirm=="string"&&i.removeSelect(o),typeof n.removeConfirm=="function"&&n.removeConfirm.call(o));return!1}).data("canRemove",!0);n.removePath&&r.find("span").html('<img src="'+n.removePath+'" alt="'+n.removeTitle+'"/>');s=e('<a href="#d" class="adder"><span class="'+n.adderClass+'">'+n.addTitle+"</span></a>").bind("click.multiSelect",function(){i.addSelect(0);return!1});n.addPath&&s.find("span").html('<img src="'+n.addPath+'" alt="'+n.addTitle+'"/>');o.parents(".wrapper").append(r).append(s);n.setupDone&&o.focus();o.data("oldIndex",t);i.updateControls();n.onAdd&&n.onAdd.call(o)},_updateValues:function(t){if(this.options.disabled)return!1;var n=this.options,r=n.uniqueClass,r=e(this.element).siblings("."+r).find("select"),i=this.element,s,o,u;s=t.find(":selected").attr("msIndex");o=t.data("oldIndex");t.data("oldIndex",s);o&&i.find("option[msIndex="+o+"]").removeAttr("selected")[0].removeAttribute("selected");o!=s&&s&&i.find("option[msIndex="+s+"]").attr("selected","selected")[0].setAttribute("selected","selected");e(r).each(function(){var n=e(this);if(n.attr("id")!=e(t).attr("id")&&(s&&s!="0"&&n.find("option[msIndex="+s+"]").remove(),o!="0")){u=t.find("option[msIndex="+o+"]").clone(!0);u.removeAttr("selected");for(var r=o;r>=0;r--)if(n.find("option[msIndex="+r+"]").length){n.find("option[msIndex="+r+"]").after(u);break}}});this.updateControls();n.onChange&&n.setupDone&&n.onChange.call(this)},removeSelect:function(e){var t=this.options,n=!0;if(t.disabled)return!1;t.removeConfirm&&(n=confirm(t.removeConfirm));n&&(e.trigger("removeIt"),t.onDelete&&t.onDelete.call())},updateControls:function(){var t=this.options,n=t.uniqueClass,r=this.element,i=r.siblings("."+n).find("select:visible"),s=r.siblings("."+n).find(".adder"),o;i.length<t.maxFields||t.maxFields=="0"?t.addWhere=="bottom"?(s.slice(0,s.length-1).hide(),s.eq(s.length-1).show()):t.addWhere=="top"&&(s.slice(1,s.length).hide(),s.slice(0,1).show()):s.hide();n=r.siblings("."+n).find(".remover");n.length=="1"?(n.addClass("disabled").fadeTo(1,.6),n.data("canRemove",!1)):(n.removeClass("disabled"),n.fadeTo(0,1),n.data("canRemove",!0));if(t.matchWidths){o=0;e(i).each(function(){e(this).width("");e(this).width()>o&&(o=e(this).width())});n=30;if(t.matchWidths>1)n=t.matchWidths;e(i).width("100%")}},destroy:function(){var t=this.options.uniqueClass;e.Widget.prototype.destroy.apply(this,arguments);this.element.removeClass("ui-widget ui-helper-reset").removeAttr("role").unbind(".multiSelect").removeData("multiSelect").show();e(this.element).siblings("."+t).remove();this.element.find("option").each(function(){e(this).removeAttr("msIndex")})}});e.extend(e.lds.multiSelect,{version:"2.0.7"})})(jQuery);
/*
 * repeater
 * @description	Repeats blocks of code (usually forms)
 * @version		2.0 - 2010/10/07
 * @author		Aaron Barker
 * @requires	ui.core.js (1.8+)
 * @optional	makeVisible
 * @copyright	Intellectual Reserve, Inc.
 * @licence		Licensed under the MIT license. http://www.opensource.org/licenses/mit-license.php
 */
(function(a){a.widget("ui.repeater",{options:{addWhere:"last",adderWhere:"bottom",adderClass:"adder",adderIconClass:"sprite icon add",removerClass:"remover",removerIconClass:"sprite icon delete",addPath:"images/ico-add-16.png",removePath:"images/ico-delete-16.gif",removeTitle:"Remove this row",addTitle:"Add additional row",wrapperClass:"repeaterWrapper",rowIdPrefix:"rowID",exampleRow:"",addControls:true,putControls:"",repeatThese:".repeat-this",maxFields:0,removeConfirm:"Are you sure you want to remove this?",useBR:true,changeName:true,changeNameLookFor:/\[##\]/,changeNameReplaceWith:"[*]",useMakeVisible:true,makeVisibleOptions:{pad:20,easing:"easeOutExpo",speed:500},autoAdd:false,onBeforeAdd:function(){},onAdd:function(){},onBeforeRemove:function(){},onRemove:function(){}},_create:function(f){var e=this.options,c=this,d=this.element,b=d.find(e.repeatThese);if(!b.length){b=d.children()}b.each(function(){c.wrapItem(this)});b=d.find("."+e.wrapperClass);if(e.exampleRow){e.exampleRow=c.wrapItem(a(e.exampleRow,d));e.newRow=a(e.exampleRow,d).clone();a(e.exampleRow,d).remove();e.newRow.attr("id","")}else{theItem=b.eq(0);e.newRow=theItem.clone()}b.each(function(){c.setupItem(this)});e.setupDone=true},getItems:function(){var c=this.options,b=this.element.find("."+c.wrapperClass);if(!b.length){b=this.element.find(c.repeatThese);if(!b.length){b=this.element.children()}}return b},wrapItem:function(c){var b=this.options;if(a(c).is("img, input, select, textarea")&&!a(c).parent("."+b.wrapperClass).length){a(c).wrap("<span class='"+b.wrapperClass+" rp-wrapped'></span>");c=a(c).parent()}else{a(c).addClass(b.wrapperClass)}return c},destroy:function(){var c=this.options,b=this.element;if(c.addControls){b.find(".rp-added").remove();b.find(".rp-wrapped").unwrap()}else{b.find("."+c.removerClass).unbind(".repeater");b.find("."+c.adderClass).unbind(".repeater")}b.find(c.repeatThese+", ."+c.wrapperClass).andSelf().unbind(".repeater");b.children().unbind(".repeater");b.find("."+c.wrapperClass).removeClass(c.wrapperClass);b.find(":input, :radio, :checkbox").andSelf().unbind(".repeater");a.Widget.prototype.destroy.apply(this,arguments)},setupItem:function(f){var e=this.options,c=this,b,d;f=this.wrapItem(f);a(f).bind("addRow.repeater",function(g,h){c.addRow(this)}).bind("removeRow.repeater",function(g,h){c.removeRow(this)}).bind("destroy.repeater",function(){c.destroy()});if(e.addControls){d=a(' <a href="#d" class="'+e.removerClass+' rp-added"><span class="'+e.removerIconClass+'">'+e.removeTitle+"</span></a>");b=a(' <a href="#d" class="'+e.adderClass+' rp-added"><span class="'+e.adderIconClass+'">'+e.addTitle+"</span></a>");if(e.removePath){d.find("span").html('<img src="'+e.removePath+'" alt="'+e.removeTitle+'"/>')}if(e.addPath){b.find("span").html('<img src="'+e.addPath+'" alt="'+e.addTitle+'"/>')}if(e.putControls){a(f).find(e.putControls).append(d).append(b)}else{a(f).append(d).append(b)}if(e.useBR){a(f).append("<br class='rp-added' />")}}else{d=a(f).find("."+e.removerClass);b=a(f).find("."+e.adderClass)}d.bind("click.repeater",function(){if(a(this).data("canRemove")){if(typeof e.removeConfirm=="string"){a(f).trigger("removeRow")}if(typeof e.removeConfirm=="function"){e.removeConfirm.call(this)}}return false});b.bind("click.repeater",function(){a(f).trigger("addRow");return false});this.updateControls();if(a.fn.makeVisible&&e.useMakeVisible&&e.setupDone){a(f).makeVisible(e.makeVisibleOptions)}if(e.focusFirst&&!e.autoAdd&&e.setupDone){f.find(":checkbox, :input, :radio").eq(0).focus()}},addRow:function(h){var f=this.options,e=this.element,d=f.newRow.clone(),c=new Date().getTime();if(!h){if(f.addWhere=="first"){h=e.children(":first")}else{h=e.children(":last")}}this._trigger("onBeforeAdd",0,d);if(f.autoAdd){a(h).find(":input, :radio, :checkbox").andSelf().unbind("change.repeater")}var g=a(d).find("[name^="+f.rowIdPrefix+"]")[0];var b=this.getItems();if(f.addWhere=="last"){b.filter(":last").after(d)}else{if(f.addWhere=="first"){b.filter(":first").before(d)}else{if(f.addWhere=="prev"){a(h).before(d)}else{a(h).after(d)}}}a(d).show().find(":input, :radio, :checkbox").each(function(l){var k="field-"+c+"-"+l,m=a(this).attr("id");a(this).attr("id",k);a(d).find("label[for="+m+"]").attr("for",k);replaceWith2=f.changeNameReplaceWith.replace("*",c);var j=a(this).attr("name").replace(f.changeNameLookFor,replaceWith2);a(this).attr("name",j)});a(d).find("label").each(function(){a(this).attr("for",a(this).attr("for").replace(/\d+/,c))});if(!f.exampleRow){a(d).find(":input").not(":radio,:checkbox").attr("value","");a(d).find(":radio,:checkbox").andSelf().attr("checked","")}a(g).val(c);this.setupItem(d);if(f.setupDone){d.find(":checkbox, :input, :radio").eq(0).focus()}this._trigger("onAdd",0,d)},removeRow:function(f){var e=this.options,d=this.element,c=true,b;if(e.removeConfirm){c=confirm(e.removeConfirm)}if(c){this._trigger("onBeforeRemove",0,f);b=a(f).next("."+e.wrapperClass).length?a(f).next():a(f).prev();b.find(":checkbox, :input, :radio").eq(0).focus();a(f).remove();this.updateControls();this._trigger("onRemove",0,this)}},updateControls:function(){var f=this.options,e=this.element,d=e.find("."+f.removerClass),c=e.find("."+f.adderClass),b=this.getItems();if(d.length=="1"){d.addClass("disabled").fadeTo(1,0.6);d.data("canRemove",false)}else{d.removeClass("disabled").fadeTo(1,1);d.data("canRemove",true)}if(f.addWhere!="prev"&&f.addWhere!="next"){c.hide()}else{c.show()}if(d.length<f.maxFields||f.maxFields=="0"){if(f.adderWhere=="bottom"){c.eq(c.length-1).show()}else{if(f.adderWhere=="top"){c.eq(0).show()}}}else{c.hide()}if(f.autoAdd){newLast=b.filter(":last");b.find(":input, :radio, :checkbox").unbind("change.repeater");var g="";if(f.exclude){g=f.exclude.call(newRow)}newLast.find(":input, :radio, :checkbox").andSelf().not(g).bind("change.repeater",function(){a(newLast).trigger("addRow")})}e.find(":input[name^=rp-order]").each(function(h){a(this).val(h)})}});a.extend(a.ui.repeater,{version:"2.0"})})(jQuery);

var LDSE = {};
LDSE.slideToggleDuration = 0;
LDSE.resizeCallbacks = {};
LDSE.classNames = {
  rowFirst	: "ldse-first",
  rowLast		: "ldse-last"
};

LDSE.isTouch = "ontouchstart" in document.documentElement;
LDSE.isDesktop = !("ontouchstart" in document.documentElement);
LDSE.iphone = (/iphone|ipod/i.test(navigator.userAgent.toLowerCase()));
LDSE.ios = (/iphone|ipod|ipad/i.test(navigator.userAgent.toLowerCase()));

$("html").addClass(LDSE.isTouch?"touch":"no-touch");

// setup for general use stuff
LDSE.setupTouch = function(){
  /*! A fix for the iOS orientationchange zoom bug. Script by @scottjehl, rebound by @wilto.MIT License.*/(function(a){function m(){d.setAttribute("content",g),h=!0}function n(){d.setAttribute("content",f),h=!1}function o(b){l=b.accelerationIncludingGravity,i=Math.abs(l.x),j=Math.abs(l.y),k=Math.abs(l.z),(!a.orientation||a.orientation===180)&&(i>7||(k>6&&j<8||k<8&&j>6)&&i>5)?h&&n():h||m()}var b=navigator.userAgent;if(!(/iPhone|iPad|iPod/.test(navigator.platform)&&/OS [1-5]_[0-9_]* like Mac OS X/i.test(b)&&b.indexOf("AppleWebKit")>-1))return;var c=a.document;if(!c.querySelector)return;var d=c.querySelector("meta[name=viewport]"),e=d&&d.getAttribute("content"),f=e+",maximum-scale=1",g=e+",maximum-scale=10",h=!0,i,j,k,l;if(!d)return;a.addEventListener("orientationchange",m,!1),a.addEventListener("devicemotion",o,!1)})(window);
  /*!
  Don't zoom in on input fields for iOS
  Mashup of https://github.com/scottjehl/iOS-Orientationchange-Fix
  and
  http://stackoverflow.com/a/5196750
  */
  (function(){function e(){a.attr("content",d);enabled=true}function f(){a.attr("content",c);enabled=false}if(!(/iPhone|iPad|iPod/.test(navigator.platform)&&navigator.userAgent.indexOf("AppleWebKit")>-1)){return}var a=$("meta[name=viewport]"),b=a&&a.attr("content"),c=b+",maximum-scale=1",d=b+",maximum-scale=10";if(!a){return}$("input[type=text]").on("touchstart",f).mousedown(e)})()
};
LDSE.setupPopups = function(container){
  container = container||$("body");
  // can't just be an "on" event because we should close the flyout menu via JS so it is there for non-JS situations
  var openClass = "ldse-popup-open",
    closerClass = "ldse-popup-closer",
    targetOpenClass = "ldse-popup-target-open";
  $(".ldse-popup",container).each(function(){
    if(!$(this).data("ldsePopupSetup")){
      var cur = $(this),
        href = cur.data("href")||cur.attr("href"),
        hide = cur.data("hide"),
        show = cur.data("show"),
        open = cur.data("open")||"",
        target = $(href),
        closeIt,
        click = LDSE.isTouch?"touchend":"click",
        isHover = open.indexOf("hover") != -1;
      $("body").data("ldse-popup-parents",$("body"));

      // open would be set if it was for hover or something, touch doesn't have hover, so clear that out
      if(LDSE.isTouch){
        open = "";
      }
      target.hide();
      cur.on(click+" "+open, function(e){
        //console.debug("click");
        if(!cur.data("href") || LDSE.isTouch){
          //console.debug("prevent");
          e.preventDefault();
        }

        if(!$(e.target).parents(".triggered").length){
          if(target.is(":hidden") && (($(e.target).is(cur) && e.type === "click" ||  e.type === "touchend") || isHover && e.type === "mouseenter")){
            cur.trigger("open");
            clearTimeout(closeIt);
          } else {
            cur.trigger("close",true);
          }
        }
      }).on("open",function(){
        $("body").data("ldse-popup-parents",cur.parents());
        // close other popups
        $("."+targetOpenClass).not(target).not(cur.parents()).trigger("close",true);
        cur.addClass(openClass);
        target.addClass(targetOpenClass);
        target[show?show:"show"]();

        // if the trigger is off the screen (after clicking on it, meaning a previous menu closed and changed its position), scroll to it
        if(cur.offset().top < $("html,body")[0].scrollTop){
          $("html,body").scrollTop(cur.offset().top);
        }
      }).on("close",function(e,force,c){
        clearTimeout(closeIt);
        closeIt = setTimeout(function(){
          if(!$("body").data("ldse-popup-parents").is(target) || force){
            cur.add(target).removeClass(openClass).removeClass(targetOpenClass);
            target[hide?hide:"hide"]();
          }
        },force?0:100);
      }).on("mouseenter",function(){
        clearTimeout(closeIt);
      });
      target.on("close",function(e,force){
        cur.trigger("close",force);
      }).on("mouseenter",function(){
        clearTimeout(closeIt);
      }).on("mouseleave",function(e){
        if(isHover){
          cur.trigger("close");
        }
      });
      $(href).find("."+closerClass).on("click",function(e){
        e.preventDefault();
        // closeIt = setTimeout(function(){
          cur.trigger("close",true);
        // },100);
      }).end().hide();
      cur.data("ldsePopupSetup","true");
    }

  });
  if(!$("body").data("ldsePopupSetup")){
    $("body").on("click.ldse-popup",function(e){
      if(!$(e.target).parents().add(e.target).filter("."+openClass).length ){
        $("."+targetOpenClass).trigger("close",true);
      }
    }).data("ldse-popupSetup",true);
  }
};
// this dynamically determines what constitutes a "row" by looking at the width of the wrapper divided by the width of the first child. it then applies a class to the first and last elements which can be used for clearing, removing margin, etc.
LDSE.makeRows = function(wrappers){
  var classNames = LDSE.classNames,
    rowFirst = classNames.rowFirst,
    rowLast = classNames.rowLast;
  wrappers.each(function(){
    var toMatch = $(this).children();
    if(toMatch.length){
      toMatch.removeClass(rowFirst+" "+rowLast);
      var colWidth = toMatch.first().outerWidth(true),
        colMarginRight = parseInt(toMatch.first().css("margin-right"),10),
        totalWidth = toMatch.first().parent().outerWidth(),
        numCols = Math.floor((totalWidth+colMarginRight)/colWidth);
      // console.debug("numCols",numCols);
      if(numCols > 1){
        lasts = toMatch.filter(":nth-child("+numCols+"n)").addClass(rowLast);
        firsts = toMatch.filter(":nth-child("+numCols+"n-"+(numCols-1)+")").addClass(rowFirst);
      }

    }
  });

};
// this dynamically determines the number of columns that should be displayed based off of the min-width given to child elements.  When the min-width is reached, it drops a column. when wide enough to hold an additional min-width column it will add one
LDSE.makeCols = function(wrappers){
  return;
  wrappers.each(function(){
    var curWrapper = $(this),
      kids = curWrapper.children(":visible"),
      classNames = LDSE.classNames,
      rowFirst = classNames.rowFirst,
      rowLast = classNames.rowLast,
      maxCols = curWrapper.data("cols"),
      curWrapperWidth = curWrapper.width(),
      firstKid = kids.eq(0),
      marginRight = parseInt(firstKid.css("margin-right"),10),
      minColWidth = parseInt(firstKid.css("min-width"),10)||curWrapper.data("width")||150,
      numCols = Math.floor(curWrapperWidth/(minColWidth+marginRight)),
      wrapperRightX = curWrapper.offset().left + curWrapper.width(),
      totalMargin,curWrapperRemainder,colWidthPX,colWidth,lastOfRow,wideWidth,
            kidsCount = kids.length + kids.filter('.wide').length;

      kids.removeClass(rowFirst+" "+rowLast);

    if(numCols > maxCols) {
      numCols = maxCols;
    }
    if(curWrapper.data("fill") && numCols > kidsCount){
      numCols = kidsCount;
    }
    totalMargin = marginRight * (numCols - 1); // minus one for last getting margin 0
    curWrapperRemainder = curWrapperWidth - totalMargin;
    colWidthPX = Math.floor(curWrapperRemainder/numCols);
    colWidth = Math.floor((colWidthPX/curWrapperWidth)*10000000000)/100000000;

    if(numCols === "1"){
      colWidth = 100;
    }
        if (colWidth <= 50) {
            wideWidth = colWidth * 2;
        } else {
            wideWidth = 100;
        }
      kids.width(colWidth - .5 + "%").filter('.wide').width(wideWidth - .5 + "%");
    // run any logic for making rows fit
    if(numCols > 1){
      kids.filter(":nth-child("+numCols+"n)").addClass(rowLast);
      kids.filter(":nth-child("+numCols+"n-"+(numCols-1)+")").addClass(rowFirst);
    }

    // occasionally with a decimal margin, things don't add up. Make sure they do
    lastOfRow = kids.eq(numCols-1);
    // console.debug(lastOfRow,wrapperRightX,lastOfRow.offset().left + lastOfRow.outerWidth());

    //the while statement causes an infinite loop on FF. It makes sure rows aren't wrapping improperly. Above an offset of -.5 has been added. It may not be elegant, but it will work without the hassle of a few tenths of a point.
    // while(isFinite(colWidth) && colWidth > 0 && lastOfRow.length && (wrapperRightX - (lastOfRow.offset().left + lastOfRow.outerWidth()) > 10)){
    // 	//console.debug(colWidth,colWidth - .01);
    // 	colWidth = colWidth - .01;
    // 	// last column is the same as first colum, there is a width issue
    // 	kids.width(colWidth+"%");
    // }
  });
};

LDSE.setupModals = function(container){
  container = container||$("body");
  if(!$(".ldse-modal-backdrop").length){
    $("body").append($('<div class="ldse-modal-backdrop"></div>'));
  }
  // setup stuff on the modals themselves
  $('.ldse-modal, .ldse-modal-backdrop').hide();

  $(".ldse-modal",container).each(function(){
    var cur = $(this);
    cur.on("open",function(){
      // console.debug("open");
      cur.trigger("position");
      cur.add('.ldse-modal-backdrop').show();
      LDSE.resizeCallbacks.modalPosition = function(){
        cur.trigger("position");
      };
    })
    .on("close",function(){
      // console.debug("close");
      cur.add('.ldse-modal-backdrop').hide();
      LDSE.resizeCallbacks.modalPosition = function(){

      };
    })
    .on("click",".ldse-modal-close",function(e){
      e.preventDefault();
      // console.debug("inline close");
      cur.trigger("close");
    }).on("position",function(){
      cur.css("top",Math.floor($(window).height()/2 - cur.height()/2)+"px");
      cur.css("left",Math.floor($(window).width()/2 - cur.width()/2)+"px");
    });
  });

  // setup stuff on anchors that might open them
  container.on("click",".ldse-modal-trigger",function(e){
    e.preventDefault();
    var cur = $(this),
      href = cur.attr("href")||cur.data("href"),
      target = $(href);
      // console.debug("opening",target);
    target.trigger("open");
  });
};
LDSE.resizeCallbacks.makeRows = function(){
  LDSE.makeRows($(".ldse-rowFix"));
};
LDSE.resizeCallbacks.makeCols = function(){
  LDSE.makeCols($(".ldse-makeCols"));
};

LDSE.init = function(){
  var body = $("body");
  LDSE.setupTouch();
  LDSE.setupPopups();
  LDSE.setupModals();
  // custom style all select elems
  if($.fn.fixSelect){
    $('.ldse-form select:not(.angular)').fixSelect({deriveWidth:true});
  }
  // setup the repeater for the filters
  $(".repeater").repeater({
    onDelete : function(){
      if(typeof changeFilter !== "undefined"){
        changeFilter();
      }
    },
    removeConfirm : "",
    addControls:false,
    onAdd: function(){
      if(typeof reloadOnEnter !== "undefined"){
        $(this).find("input").keydown(reloadOnEnter);
      }
    }
  });
  $(".repeater ~ .adder").on("click",function(e){
    e.preventDefault();
    $(this).siblings(".repeater").repeater("addRow");
  });

  //setup the multiselect for the filters
  if($.lds.multiSelect){
    $(".multiselect[multiple]").multiSelect({
      onDelete : function(){
        if(typeof changeFilter !== "undefined"){
          changeFilter();
        }
      },
      removeConfirm : "",
      removerClass:"ldse-icon ldse-icon-ko-remove",
      adderClass: "ldse-icon-ko-add",
      addTitle:"Add Filter",
      onChange : function () {
        $(this).parents('div.ui-multiSelect').first().siblings("select.multiselect").change();
      },
      onAdd: function(a,b){
        var self = $(this);
        var parent = self.parents('div.ui-multiSelect').first().siblings("select.multiselect");
        self.width(parent.width() + 30);
        self.fixSelect({deriveWidth:false});
        self.width(parent.width());
        var select = self.parents(".select");
        select.siblings(".remover").insertBefore(select);
      }

    });
  }

  $(window).on("resize.ldse orientationchange.ldse",function(){
    clearTimeout(LDSE.resizeTimer);
    LDSE.resizeTimer = setTimeout(function(){
      // console.debug("run resize stuff");
      $.each(LDSE.resizeCallbacks,function(){
        // console.debug(this);
        this.apply();
      });
    },150);
  }).trigger("resize.ldse");
    // Collapse or expand the toolbar
    $("#ldse-toolbar-container.back .ldse-toolbar-toggle").on("click",function(e){
        $("#ldse-toolbar-container.back").toggleClass("ldse-collapsed");
        if($("#ldse-toolbar-container.back").hasClass("ldse-collapsed")) {
            sessionStorage.ldseToolbar = "collapsed";
        } else {
            sessionStorage.ldseToolbar = "shown";
        }
        $(".ldse-alert").toggleClass("ldse-collapsed");
    });
  // Display or hide the dropdown menu from the toolbar
  $("#ldse-toolbar-container.back .ldse-dropdownMenu-trigger").on("click",function(e){
    var cur = $(this),
      wrapper = cur.closest("div"),
      list = wrapper.find("ul.ldse-menu");
    if( !wrapper.hasClass("ldse-open")) {
        list.show();
      wrapper.addClass("ldse-open");
      e.stopPropagation();
      e.preventDefault();
      $(document).one('click', function() {
          wrapper.removeClass("ldse-open").find("ul.ldse-menu").hide();
      });
      var otherMenus = $('#ldse-toolbar-container.back .ldse-toolbar-item').not(wrapper);
      otherMenus.removeClass("ldse-open").find("ul.ldse-menu").hide();
    }
  });
  LDSE.resizeCallbacks['toolbarMenuMaxHeight'] = function () {
        $("#ldse-toolbar-container.back ul.ldse-menu").css({
              'overflow-y' : 'auto',
              'overflow-x' : 'hidden',
              'max-height' : (window.innerHeight - $('#ldse-toolbar').height() ) + "px"
          });
      };
  // Expand or collapse a submenu in the main nav dropdown menu
  $("#ldse-toolbar-container.back .with-submenu").on("click",function(e){
    $(this).find("ul").toggle(0, function() {
      $(this).closest("li").toggleClass("ldse-open");
    });
    e.stopPropagation();
  });
  // Show or hide dropdown with buttons
  $(".ldse-button.dropdown-right").on("click",function(e) {
    var btn = $(this).closest("button");
      listItem = btn.closest("li");
      subList = listItem.find("ul");
    if( btn.hasClass("depressed") ) {
      btn.removeClass("depressed");
      subList.toggle(false);
    } else {
      var otherBtn = $(".ldse-button.dropdown-right.depressed").closest("button");
        n = otherBtn.length;
      if(n!=0) {
        otherBtn.removeClass("depressed");
        otherBtn.closest("li").find("ul").toggle(false);
      }

      btn.addClass("depressed");
      subList.toggle(true);
      e.stopPropagation();

      $(document).one('click', function() {
        btn = $(".ldse-button.dropdown-right.depressed").closest("button");
        subList = btn.closest("li").find("ul");
        btn.toggleClass("depressed");
        subList.toggle(false);
      });
    }
  });
  // Expand or collapse section
  $(window).on("click", ".ldse-section--header h2 a",function(e){
    e.preventDefault();
    var cur = $(this),
      wrapper = cur.closest("section"),
      target = $(cur.attr("href")),
      guts = wrapper.children(".ldse-section--body");
    guts.toggle(0, function() {
        wrapper.toggleClass("closed");
        LDSE.resizeCallbacks.makeCols();
        guts.css('overflow', 'visible');
      }
    );
  });
  // Expand or collapse blocks with icons
  $(".ldse-block header .ldse-icon:not(.ldse-collection-button)").on("click",function(e){
    e.preventDefault();
    $(this).closest(".ldse-block").find(".ldse-block--body").toggle(0, function() {
      $(this).closest(".ldse-block").toggleClass("ldse-open").find(".ldse-block--body").css('overflow','visible');
      LDSE.resizeCallbacks.makeCols();
    });
  });
  // Toggle tile buttons' active state and toggle info section
  $(".ldse-block.tile:not(.disabled)").on("click",function(){
    var btn = $(this).toggleClass("depressed");
    if (btn.attr('id')) {
      location.hash = "#" + btn.attr('id');
      setTimeout(function() {
          if (location.hash) {
            window.scrollTo(0, 0);
          }
      }, 1);
    }
    if(btn.data("group")) {
      $(".ldse-block.tile.depressed", $(btn.data("group"))).not(btn).toggleClass("depressed").each(function() {
        LDSE.toggleContent($(this).data("selector"));
      });
    }
    if (btn.data('click')) {
      window[btn.data('click')](btn, btn.hasClass("depressed"))
    }
  });

  // Toggle content
  body.on("click", ".ldse-toggle-content:not(.disabled)",function(e){
    e.preventDefault();
    LDSE.toggleContent($(this).data("selector"));
  });

  // Fade content
  body.on("click",".ldse-fade-content", function(e){
    e.preventDefault();
    var info = $(this).data("selector");
    if($(info).hasClass("ldse-hidden")) {
      $(info).removeClass("ldse-hidden");
      $(info).css('display', 'none');
    }
    $(info).toggle(0, function() {
      $(info).css('overflow', 'visible');
      LDSE.resizeCallbacks.makeCols();
    });
  });

  // Toggle based on radio button
  $(window).on("click",".ldse-option.toggle",function() {
    $($(this).data("hide")).hide().addClass("ldse-hidden").find("input, select").val("").end().find(".text").html("");
    $($(this).data("show")).show().removeClass("ldse-hidden");
  });

  // To show and hide info text
  body.on("click",".ldse-info-button", function(e) {
    e.preventDefault();
    $(this).toggleClass("ldse-show-info");
  });

  // Make the select-all checkbox operate properly
  $("#box-all").on('click', function() {
    if(this.checked) {
      $("#detail-table-body :checkbox:visible").prop('checked',true);
    } else {
      $("#detail-table-body :checkbox:visible").prop('checked',false);
    }
  });

  // Mark the select-all checkbox as selected or not according to the rest of the checkboxes in the table
  $("#detail-table-body :checkbox").on('click', function() {
    if(this.checked === false) {
      $("#box-all").prop('checked',false);
    } else {
      if($("#detail-table-body :checkbox").length === $("#detail-table-body :checkbox:checked").length) {
        $("#box-all").prop('checked',true);
      }
    }
  });

  // Show and hide buttons in the table
  $("#detail-table").on('click', ':checkbox', function() {
    var n = $("#detail-table-body :checkbox:not(.ldse-show-items-exclude):checked").length;
    if(n > 1) {
      $(".ldse-show-mult").show();
      $(".ldse-show-single").hide();
    } else if (n === 1) {
      $(".ldse-show-mult, .ldse-show-single").not($(".ldse-hide-single")).show();
      $(".ldse-hide-single").hide();
    } else {
      $(".ldse-show-mult, .ldse-show-single").hide();
    }
  });



  // Make the select-all checkbox operate properly
  $(".ldse-check-all").on('click', function() {
    $(this).closest(".ldse-check-all-group").find(":checkbox:not(.ldse-check-all-group-exclude):visible").prop('checked', this.checked);
  });

  $(".ldse-check-all-group :checkbox:not(.ldse-check-all,.ldse-check-all-group-exclude)").on('click', function() {
    var allgroup = $(this).closest(".ldse-check-all-group");
    var check_all = allgroup.find(".ldse-check-all");

    var alln = $(":checkbox:not(.ldse-check-all,.ldse-check-all-group-exclude)", allgroup).length;
    var n = $(":checkbox:not(.ldse-check-all,.ldse-check-all-group-exclude):checked", allgroup).length;

    $(check_all).prop('checked', this.checked && alln === n);
  });

  // Show and Hide buttons for a given selector
  $(".ldse-show-items :checkbox:not(.ldse-show-items-exclude),.ldse-show-items :checkbox.ldse-check-all").on('click', function() {

    var parent = $(this).closest(".ldse-show-items");
    var n = $(":checkbox:checked:not(.ldse-show-items-exclude)", parent).length;
    var mult_selector = parent.data("ldse-show-items-mult-selector");
    var single_selector = parent.data("ldse-show-items-single-selector");
    var hide_single_selector = parent.data("ldse-show-items-hide-single-selector");

    if(n > 1) {
      $(mult_selector).show();
      $(single_selector).hide();
    } else if (n === 1) {
      $(mult_selector + ", " + single_selector).not($(hide_single_selector)).show();
      $(hide_single_selector).hide();
    } else {
      $(mult_selector + ", " + single_selector).hide();
    }

  });

  $(".ldse-alert-close").on("click", function(e) {
    // $(this).closest("section").toggle(true);
    $(this).closest("section").hide();
  });
  $('#night-mode-toggle').on('click', function(e){
    e.preventDefault();
    var html = $('html');
    if(html.hasClass('night-mode')) {
      sessionStorage.nightMode = 'off';
    } else {
      sessionStorage.nightMode = 'on';
    }
    html.toggleClass('night-mode');
    var wait = setTimeout(function(){$("#ldse-toolbar-container.back .ldse-toolbar-toggle").click()},'500');
  });

};
LDSE.toggleContent = function(content) {
  if($(content).hasClass("ldse-hidden")) {
    $(content).removeClass("ldse-hidden");
    $(content).css('display', 'none');
  }
  $(content).toggle(LDSE.slideToggleDuration, function() {
    $(content).css('overflow', 'visible');
    LDSE.resizeCallbacks.makeCols();
  });
};
LDSE.post = function (path, params, method) {
    method = method || "post";
    var form = $("<form/>"),
      hiddenField;
    if (params.id && params.id != "" &&  path.indexOf('/shared/lds-edit/form') != -1 && path.indexOf('&id=') == -1){
      path += '&id='+params.id;
      delete params.id;
    }
    form.attr("method", method).attr("action", path).hide();
    for(var key in params) {
        if(params.hasOwnProperty(key)) {
            if ($.isArray(params[key])) {
              for (var i = 0; i < params[key].length; i++ ){
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
    }
    $('body').append(form);
    form.submit();
};

LDSE.alert = function(title, text, options) {
  var alertModal = $('#alertModal');
  var defaults = {
      okText : "OK",
      okClass : "primary ldse-icon-check2"
  };
  options = $.extend({}, defaults, options);
  alertModal.empty();
  var modal = $(
      '<header class="ldse-section--header"><h2>'+ title +'</h2></header>'+
      '<form class="ldse-section--body ldse-form">'+
        '<dl><dt><label for="reason">'+ text +'</label></dt></dl>'+
        '<div class="ldse-form-buttons">'+
          '<button id="alert-ok" class="ldse-button ' + options.okClass + '">' + options.okText + '</button>'+
        '</div>' +
      '</form>');
  modal.find('#alert-ok').click(function(e){
    e.preventDefault();
    e.stopPropagation();
    alertModal.trigger('close');
    alertModal.empty();
    return false;
  });
  alertModal.append(modal).trigger('open');
};

LDSE.confirm = function(title, text, onOk, options) {
  var alertModal = $('#alertModal');
  var defaults = {
      okText : "OK",
      okClass : "primary ldse-icon-check2",
      cancelText : "Cancel",
      cancelClass : "ldse-icon-x"
  };
  options = $.extend({}, defaults, options);
  alertModal.empty();
  var modal = $(
      '<header class="ldse-section--header"><h2>'+ title +'</h2></header>'+
      '<form class="ldse-section--body ldse-form">'+
        '<dl><dt><label for="reason">'+ text +'</label></dt></dl>'+
        '<div class="ldse-form-buttons">'+
          '<button id="alert-ok" class="ldse-button ' + options.okClass + '">' + options.okText + '</button>' +
          '<button id="alert-cancel" class="ldse-button ' + options.cancelClass + ' float-right ldse-modal-close">' + options.cancelText + '</button>' +
        '</div>' +
      '</form>');
  modal.find('#alert-ok').click(function(e){
    e.preventDefault();
    e.stopPropagation();
    alertModal.trigger('close');
    if (typeof onOk !== "undefined") {
      onOk();
    }
    return false;
  });
  alertModal.append(modal).trigger('open');
};

function alert(text) {
  LDSE.alert("Alert", text);
}

$(function(){
    if(sessionStorage.ldseToolbar == "collapsed") {
        $("#ldse-toolbar-container").addClass("ldse-collapsed");
    }
    if(sessionStorage.nightMode == "on") {
        $("html").addClass("night-mode");
    }

  LDSE.init();
  if(typeof afterSetup !== "undefined"){
    afterSetup();
  }
});
