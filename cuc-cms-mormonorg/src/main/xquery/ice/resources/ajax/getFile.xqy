xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";
import module namespace df = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../../modules/dynamicForms.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../modules/access-control-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

let $id as xs:string := util:sanitize-input(xdmp:get-request-field("id"))
let $formname as xs:string := util:sanitize-input(xdmp:get-request-field("formname"))
let $lang as xs:string := util:escape-chars(xdmp:get-request-field("lang", "eng"))


let $form as element(ldse:formTemplate)? := df:getFormTemplate($formname)

let $queryVars as item()* := df:getQueryVariables($form/ldse:root-query/*)

let $set as empty-sequence() :=
    for $x as xs:string in $queryVars
    return df:setVariable($x, xdmp:get-request-field($x))

let $notmap as empty-sequence() := df:buildParamMap()

let $file as element()? := df:getRootFile($form)
where ac:has-permission('ldse:edit-doc', "", "")
return
    $file
