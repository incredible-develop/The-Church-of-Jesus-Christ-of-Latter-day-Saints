xquery version "1.0-ml";

import module namespace formValidatorFunctions = "http://lds.org/code/shared/lds-edit/formValidatorFunctions" at "modules/formValidatorFunctions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace layout = "http://lds.org/code/shared/lds-edit/layout-functions" at "../../modules/layout-functions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

declare variable $lang as xs:string := util:escape-chars(xdmp:get-request-field("lang", "eng"));
declare variable $country as xs:string? := util:escape-chars(xdmp:get-request-field("country", ""));

declare variable $locale as xs:string := if ($country ne "") then (fn:concat($lang,'-',$country)) else ($lang);

declare variable $thisPage as xs:string := '/ice/form-validator';
declare variable $title as xs:string := 'Form Validator';

declare variable $forms as element(ldse:formTemplate)* := formValidatorFunctions:getDynamicForms();
if( ac:has-permission('ldse:validate-forms', '', '') ) then(
xdmp:set-response-content-type("text/html"),
<html>
    <head>
        {layout:addResources($title)}
        <script src="form-validator/scripts/formValidator.js">&nbsp;</script>
        <link rel="stylesheet" type="text/css" href="{$settings:shared-prefix}/ice/form-validator/styles/formValidator.css" />
    </head>
    <body class='toolbox'>
        {layout:buildHeader($title)}
        {layout:buildSubHeader($title)}
        
          <div class="ixf-panels">
            	<div class="ixf-panel ui-layout-west padding-md clear">
                    <a href="#" class="ixf-button primary margin-bottom-sm " onclick="validateAll()">Validate All</a>
                          
                            {
                                formValidatorFunctions:getFormList($forms)
                            }
                               
                            {
                                formValidatorFunctions:getFormListNoNameSpace()
                            }
                         
                              {layout:buildAppMenu($thisPage, $locale) }
                              
            	</div> 
            	<div class="ixf-panel ui-layout-center padding-sm clear">
            	         <div class ="results ">
                               Click form to view validation results.
                               </div>
                 </div>
        	<div id="dialog"></div>
        </div>
    <script>
            
            ixf.layoutDefaults = {{
            	west:{{
            		minWidth : 200
            	}},
            	center:{{
            		size:400
            	}}
            }}
            
    </script>
    </body>
</html>
) else(
    let $errorMsg as xs:string:="Sorry, you don't have permission to view this page."
    let $errorTitle as xs:string:= "Error!"    
    return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
)
