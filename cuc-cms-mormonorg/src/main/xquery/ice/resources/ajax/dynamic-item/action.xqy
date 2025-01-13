xquery version "1.0-ml";

import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../../modules/access-control-functions.xqy";
import module namespace action = "http://lds.org/code/shared/lds-edit/action-functions" at "../../../modules/action-functions.xqy";
(:import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../../modules/ldse-settings.xqy";:)

declare namespace handle-correlation = "http://lds.org/code/shared/lds-edit/handle-correlation";
declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace cldse = "http://lds.org/code/lds-edit/correlation";

declare boundary-space preserve;
declare option xdmp:mapping "true";
declare option xdmp:update "true";

(: pass variables :)
declare variable $action as xs:string := xdmp:get-request-field("action", "");
declare variable $uri as xs:string := xdmp:get-request-field("uri", "");
declare variable $locale as xs:string := xdmp:get-request-field("locale", "");
declare variable $site as xs:string? := xdmp:get-request-field("site");

(: item object :)
declare variable $name as xs:string := xdmp:get-request-field("name", "");
declare variable $folder as xs:string := xdmp:get-request-field("folder", "");
declare variable $html-id as xs:string := xdmp:get-request-field("id", ""); (: html id not a file id :)
declare variable $ids as xs:string+ := fn:distinct-values(xdmp:get-request-field("ids[]", ""));

declare variable $has-permission as xs:boolean := ac:is-action-allowed($action, $locale, $uri);

(: item index :)
declare variable $index as xs:string := xdmp:get-request-field("index", "");

xdmp:set-response-content-type("application/json"),
if ($has-permission) then (
    action:perform-action($action, $uri, $locale, $name, $folder, $html-id, $ids, fn:false(), $site, $index)
) else (
    fn:false(), "You don't have permissions to perform this action"
)
