xquery version "1.0-ml";

import module namespace pretty = "http://lds.org/code/shared/common/pretty-print" at "/shared/common/util/pretty-print.xqy";

import module namespace formValidatorFunctions = "http://lds.org/code/shared/lds-edit/formValidatorFunctions" at "../modules/formValidatorFunctions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

declare variable $formName as xs:string := xdmp:get-request-field("formName");
declare variable $form as element(ldse:formTemplate) :=  formValidatorFunctions:getFormByName($formName);
declare variable $formTitle as xs:string := formValidatorFunctions:getTitle($form);

declare variable $ruleFunction as xs:string := xdmp:get-request-field("scope");

declare variable $validationInfo as element(validationInfo) := formValidatorFunctions:validateFormWithRule($form,$ruleFunction);
declare variable $errorMap as element(map:map) := $validationInfo/map/map:map;
declare variable $warningMap as element(map:map) := $validationInfo/warningMap/map:map;

declare variable $key as xs:string := $form/@name;

declare variable $errorPaths as xs:string* := formValidatorFunctions:getErrorPaths($errorMap,$key);
declare variable $errorNodes as element()* := $form/$errorPaths;

declare variable $warningPaths as xs:string* := formValidatorFunctions:getErrorPaths($warningMap,$key);
declare variable $errorType as xs:string := xdmp:get-request-field("type");

xdmp:set-response-content-type("text/html"),
<div id="xmlContainer">
    {
    if($errorType eq "error") then
        (
            pretty:print($form,$form//*[xdmp:path(.) = $errorPaths],fn:true())
        )
        else(
            pretty:print($form,$form//*[xdmp:path(.) = $warningPaths],fn:true())
        )
        
    }
</div>
