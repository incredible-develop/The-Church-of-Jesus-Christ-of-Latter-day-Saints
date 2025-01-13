xquery version "1.0-ml";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace sf = "http://lds.org/code/shared/lds-edit/content-admin/slug-functions" at "../modules/slug-functions.xqy";
import module namespace c = "http://lds.org/code/shared/common/common-functions" at "/shared/common/commonFunctions.xqy";
(:import module namespace cache-control = "http://lds.org/code/seminary-and-institute/cache-control-functions" at "/sites/si/modules/cacheControlFunctions.xqy";:)
import module namespace sp = "http://lds.org/code/modules/site-properties" at '../../modules/site-properties.xqy';

declare namespace ldse = "http://lds.org/code/lds-edit";

declare variable $slug as xs:string* := sf:getForwardSlashURLS(util:escapeChars(xdmp:get-request-field("slug")));
declare variable $id as xs:string? := util:escapeChars(xdmp:get-request-field("id"))[. != ''];
declare variable $lang as xs:string? := util:escapeChars(xdmp:get-request-field("lang"))[. != ''];
declare variable $uri as xs:string? := util:escapeChars(xdmp:get-request-field("url"))[. != ''];
declare variable $site as xs:string? := util:escapeChars(xdmp:get-request-field("site"))[. != ''];
declare variable $site-properties as element(siteProperties) := sp:get-site-properties($site);

declare variable $slugExists as xs:boolean := sf:is-unique-uri($slug, $lang, $id, $site);

(:cache-control:addNoCacheHeader(),:)
xdmp:set-response-content-type("text/html"),
if ( $slugExists ) then ( 
    'false'
) else ( 
    sf:check-rewrite-rules($lang, $site, $slug[1], $id, $site-properties)
)