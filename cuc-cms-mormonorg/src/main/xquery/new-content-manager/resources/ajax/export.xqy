xquery version "1.0-ml";

import module namespace excel = "http://marklogic.com/openxml/excel" at "../../../modules/spreadsheet-ml-support.xqy";
import module namespace content = "http://lds.org/code/shared/lds-edit/contentFunctions" at "../../../content/modules/contentFunctions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../modules/access-control-functions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";

declare option xdmp:mapping "true";

declare variable $lang as xs:string := util:escape-chars(xdmp:get-request-field("locale", "eng"));

declare variable $permission as xs:string := 'ldse:view-content-admin';
declare variable $localesWithRights as xs:string* := ac:locales-by-permission($permission);
declare variable $locale as xs:string := if ($lang eq $localesWithRights) then ($lang) else ($localesWithRights[1]);

declare variable $uri as xs:string := util:escape-chars(xdmp:get-request-field("s", "/"));

declare variable $files as element()* := content:getContentByUri($locale, $uri) ;
               
declare variable $fileName as xs:string := fn:concat('Content',fn:replace($uri, '/', '_'), '.xlsx');

declare variable $table as element(table) := content:buildSectionTable($files);
declare variable $excel as binary() := excel:create-xlsx-from-xml-table($table);

    if (ac:has-permission($permission, $locale, '') and fn:exists($excel)) then (
            xdmp:add-response-header('Content-Disposition', fn:concat('attachment; filename="', $fileName,'"')),
            xdmp:set-response-content-type('application/octet-stream'),
            $excel
    ) else ()
