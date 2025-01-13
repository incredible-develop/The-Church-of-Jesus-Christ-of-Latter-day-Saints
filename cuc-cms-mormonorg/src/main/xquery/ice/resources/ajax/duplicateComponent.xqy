xquery version "1.0-ml";

import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace template = "http://lds.org/shared/lds-edit/template" at "/modules/template.xqy";
import module namespace af = "http://lds.org/code/lds-edit/content-admin/admin-functions" at "/content-admin/modules/functions.xqy";
declare namespace ldse = "http://lds.org/code/lds-edit";

declare boundary-space preserve;

declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

declare variable $site as xs:string? := xdmp:get-request-field('site');
declare variable $lang as xs:string? := xdmp:get-request-field("lang")[1];
declare variable $uri as xs:string? := xdmp:get-request-field('uri');
declare variable $id as xs:string? := xdmp:get-request-field("id");

if (ac:has-permission('ldse:edit-doc', '', '')) then
    af:duplicateComponent ($site, $lang, $uri, $id)
else
    template:error-access-denied("Error!", "Sorry, you don't have permission to duplicate component.")

