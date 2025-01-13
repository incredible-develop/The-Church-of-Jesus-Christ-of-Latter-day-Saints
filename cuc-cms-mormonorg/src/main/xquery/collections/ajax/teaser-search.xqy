xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace cf = "http://lds.org/code/shared/lds-edit/collections/functions" at "../modules/collections-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";

declare variable $searchLocale as xs:string? := util:escape-chars(xdmp:get-request-field("searchLocale"));
declare variable $teaserType as xs:string? := xdmp:get-request-field("type");
declare variable $referer as xs:string :=xdmp:get-request-field("referer");
declare variable $ids as xs:string* := fn:distinct-values(fn:tokenize(xdmp:get-request-field("ids"), ","));

let $teasers as element()* := cf:get-teasers($teaserType, $searchLocale, $ids)

return (
    cf:teaser-search($teasers)
)