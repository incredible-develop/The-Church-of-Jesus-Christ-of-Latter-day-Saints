xquery version "1.0-ml";

import module namespace df = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../../ice/modules/dynamicForms.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare variable $input-name as xs:string := xdmp:get-request-field('inputName');
declare variable $form-name as xs:string := xdmp:get-request-field('formName');
declare variable $search-form as xs:string := xdmp:get-request-field('searchForm');
declare variable $search-val as xs:string := xdmp:get-request-field('value');

let $form as element(ldse:formTemplate)? := df:get-form($form-name)
let $search-form as element(ldse:formTemplate)? := df:get-form($search-form)
let $input as element(ldse:input)? := $form//ldse:input[@name = $input-name]

return (
    df:buildCustomCheckboxes($input, (), (), $search-val, $search-form)
)