xquery version "1.0-ml";

import module namespace cloneFunctions = "http://lds.org/code/shared/lds-edit/clone-functions" at "/ice/resources/ajax/clone-page/cloneFunctions.xqy";
declare boundary-space preserve;
declare option xdmp:mapping "true";
declare option xdmp:update "true";
declare variable $resourcesPages as xs:string* := xdmp:get-request-field("resourcesPages[]");
declare variable  $site as xs:string := xdmp:get-request-field("site");
declare variable  $language as xs:string* := xdmp:get-request-field("language");
declare variable  $componentIds as xs:string* := xdmp:get-request-field("componentIds[]");
declare variable  $cloneToPage := xdmp:get-request-field("cloneToPage");

if (string-length($cloneToPage)) then
    let $destinationPage := fn:substring-before($cloneToPage, '|')
    let $templateRegion := fn:substring-after($cloneToPage, '|')
    let $clone := cloneFunctions:clone-selected-components($language, $destinationPage, $componentIds, 'clone', $templateRegion, $site)
    return fn:concat('{"response":"', $clone, '"}')
else
    fn:concat('{"response":"', 'Missing destination page', '"}')


