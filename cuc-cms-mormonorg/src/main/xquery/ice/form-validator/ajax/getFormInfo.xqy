xquery version "1.0-ml";


import module namespace formValidatorFunctions = "http://lds.org/code/shared/lds-edit/formValidatorFunctions" at "../modules/formValidatorFunctions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

declare variable $formName as xs:string := xdmp:get-request-field("formName");
declare variable $form as element(ldse:formTemplate) :=  formValidatorFunctions:getFormByName( $formName);
declare variable $formTitle as xs:string := formValidatorFunctions:getTitle($form);

declare variable $validationInfo as element(validationInfo) := formValidatorFunctions:validateForm($form);
declare variable $successCount as xs:int := $validationInfo/successCount;
declare variable $failCount as xs:int := $validationInfo/failCount;
declare variable $warnCount as xs:int := $validationInfo/warnCount;

xdmp:set-response-content-type("text/html"),
<div id="resultsBox">   
    <div id= "resultsHeader">
        Validation Results for {$formTitle}
        
        { (:$successCount} / {fn:sum(($successCount,$failCount)) :) }
        {
        if($failCount gt 0) then
            <a href="#" onclick="displayErrorXML()" class="failText sprite stop prefix"> View Errors XML ({$failCount})</a>
            else(),
           if($warnCount gt 0) then (
            <a href="#" onclick="displayWarningXML()" class="warnText sprite warning prefix"> View Warnings XML ({$warnCount}) </a>
            )
            else()
         }
         
    </div>
    <div id= "resultsContent">{$validationInfo/content/*}</div>
    <span style="visibility:hidden" id="failCount">{$failCount}</span>
    <span style="visibility:hidden" id="warnCount">{$warnCount}</span>
</div>
            
