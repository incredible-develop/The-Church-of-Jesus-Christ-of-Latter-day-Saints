
var enterKey = 13;


/* Helper function - if string returns string
 * if number returns number rounded to two decimal places.
 */
Handlebars.registerHelper('round', function(content) {
	if(content=="" && typeof content == "string"){
		return "Not Available";
	}
	if(isNaN(content)){
		return content;
	}
	var num = Number(content);
	return numberWithCommas(Math.round(num*100)/100);
});

function numberWithCommas(n) {
	var parts = n.toString().split(".");
	return parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",")
			+ (parts[1] ? "." + parts[1] : "");
}

$("#getSeoDataBtn").click(function(){
	getSeoData();
});



$(".handlebars-template").each(function() {
	window[$(this).attr('id')] = Handlebars.compile($(this).html());
});


function showDescription(desc){
	$("#displayDescription").html(desc);
}

function hideDescription(){
	$("#displayDescription").html("");
}

function checkEnter(func){
	if(event.keyCode == 13){
		func();
	}
	//func();
}

function sendRequestWithTargetURL(targetFld){
	var targetFld =  $("#targetURLFld").val();
	if(targetFld==""){
		alert("please enter a value for the URL");
		return;
	}
	var targetURL =  targetFld;
	var parser = document.createElement("a");
	
	//check protocol - if none, add http: so not relative link - then use parser to find hostname & pathname
	if(targetFld.indexOf("://") >=0){		
		parser.href =  targetFld;
	}
	else{
		parser.href = "http://" + targetFld;
	}
	
	targetURL =  parser.hostname + parser.pathname;
	if(sharedPrefix == undefined){
		var sharedPrefix ="";
	}
	var url = sharedPrefix + "/shared/lds-edit/seomoz/ajax/getSeoData?lang=eng";
	var data = {"targetURL":targetURL};
	$.ajax({
		url : url,
		type:"GET",
		data:data,
		success:function(response){
			var htmlFromTemplate = window['seoTableTemplate'](response);
			
			$("#dataTable").html(htmlFromTemplate);
		},
		error:function(response){
			
			alert("Failed to load seo Data response:" + response);
		}
	})
}

function returnToURL(url){
	window.location.href = url;
}

function getSeoData(){
	sendRequestWithTargetURL($("#targetURLFld").val());
}