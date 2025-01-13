var viewFormName;

$(function(){
 
   ixf.setup();
   $("ul li a").click(function(){      
       displayData(this);    
   });

});

function displayData(clickObj){
    $.ajax(
        {
            url: sharedPrefix + "/ice/form-validator/ajax/getFormInfo?lang=eng&formName=" + clickObj.id,
            success: function(data){
               viewFormName = clickObj.id;
               $('.results').html(data);

              var failCount = (document.getElementById('failCount').innerHTML);
              var warnCount = (document.getElementById('warnCount').innerHTML);
              
              var failFld = document.getElementById('failCount_'+clickObj.id);
              var warnFld = document.getElementById('warnCount_'+clickObj.id);

          

               if(failCount > 0){
                    failFld.innerHTML = "(" + failCount + ")";
                    clickObj.setAttribute("class","sprite stop prefix");
                }
                else if(warnCount > 0){
                    warnFld.innerHTML = "(" + warnCount + ")";
                    clickObj.setAttribute("class","sprite warning prefix");
                }
                else{
                    clickObj.setAttribute("class","sprite check prefix");
                }
                         
                $('.results').hide();
                $('.results').fadeIn('slow');
            }
        }
    );
}

function displayErrorXML(){
   showErrorWindow("error","all");
}

function displayWarningXML(){
   showErrorWindow("warning","all");
}

function displayRuleErrorXML(ruleObj){
      showErrorWindow("error",ruleObj.id);
}

function displayRuleWarningXML(ruleObj){
     showErrorWindow("warning",ruleObj.id);
}

function showErrorWindow(type,scope){
     $.ajax(
        {

            url: sharedPrefix + "/ice/form-validator/ajax/getErrorXML?lang=eng&formName=" + viewFormName + "&type=" + type + "&scope=" + scope,

            success: function(data){
               $('#dialog').html(data);
               $('#dialog').dialog({
            	   				   position: [($(window).width() / 2) - (1000 / 2), 150],
            	                   resizable:true,
                                   modal:true,
                                   maxHeight:1000,
                                   maxWidth:1000,
                                   minWidth:800,
                                   minHeight:600,
                                   title:"XML Window"});
               
               if(type=="error"){
                   $(".highlight").css( {'background-color': '#633', "border-color" : "#f00"}); 
               }
               else{
                   $(".highlight").css( {'background-color': '#763', "border-color" : "#fb0"});
               }
            }
        }
    );
}


function validateAll(){ 
   $("#dynamic-form-list li a").each(function(){
       displayData(this);  
   });
}