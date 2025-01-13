xquery version "1.0-ml";

import module namespace ldseUtil = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace cc = "http://lds.org/code/shared/lds-edit/clear-cache-functions" at "../../clear-cache/modules/clear-cache-functions.xqy";
import module namespace sp = "http://lds.org/code/modules/site-properties" at '../../modules/site-properties.xqy';

declare namespace ldse = "http://lds.org/code/lds-edit";

declare variable $uri as xs:string := ldseUtil:escape-chars(xdmp:get-request-field('uri', ''));
declare variable $site as xs:string := ldseUtil:escape-chars(xdmp:get-request-field('site', ''));
declare variable $lang as xs:string := ldseUtil:escape-chars(xdmp:get-request-field('lang', ''));
declare variable $context as xs:string := ldseUtil:escape-chars(xdmp:get-request-field('context'));

let $site-properties as element(siteProperties)? := sp:get-site-properties($site)
let $preview-url := $site-properties/urls/url[@env = 'preview']/fn:string()
let $published-url := $site-properties/urls/url[@env = 'published']/fn:string()
let $url := if ($context eq 'published') then
                '//' || $published-url || $uri || '?lang=' || $lang
            else
                '//' || $preview-url || $uri || '?lang=' || $lang
return (
    xdmp:redirect-response($url)
)
