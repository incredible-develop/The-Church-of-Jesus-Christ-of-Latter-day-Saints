xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";
import module namespace content = "http://lds.org/code/shared/lds-edit/contentFunctions" at "../../../content/modules/contentFunctions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../modules/access-control-functions.xqy";

declare option xdmp:mapping "true";


declare variable $lang as xs:string := util:escape-chars(xdmp:get-request-field("locale", "eng"));

declare variable $permission as xs:string := 'ldse:view-content-admin';
declare variable $localesWithRights as xs:string* := ac:locales-by-permission($permission);
declare variable $locale as xs:string := if ($lang eq $localesWithRights) then ($lang) else ($localesWithRights[1]);

declare variable $section as xs:string := util:escape-chars(xdmp:get-request-field("s", ""));

declare variable $uris as xs:string* := content:getUrisBySection($locale, $section);

if (ac:has-permission($permission, $locale, '')) then (
    xdmp:set-response-content-type( "text/html" ),
    <ul>{content:buildUriBreakDown($uris, $locale, $section)}</ul>
) else ()
