xquery version "1.0-ml";

import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../modules/ldse-settings.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";
import module namespace tf = 'http://lds.org/code/modules/titan-functions' at "../../../modules/titan-functions.xqy";

declare boundary-space preserve;
declare option xdmp:mapping "true";

(: pass variables :)
declare variable $titanId as xs:string := xdmp:get-request-field('id');
declare variable $type as xs:string := xdmp:get-request-field('type');

xdmp:set-response-content-type("application/json"),
if (fn:exists($titanId)) then (
    tf:get-titan-asset-details($titanId, $type)
) else ( )
