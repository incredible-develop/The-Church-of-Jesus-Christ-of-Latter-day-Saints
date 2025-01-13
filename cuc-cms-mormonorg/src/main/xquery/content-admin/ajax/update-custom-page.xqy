xquery version "1.0-ml";

import module namespace af = "http://lds.org/code/lds-edit/content-admin/admin-functions" at "../modules/functions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";

declare variable $uri as xs:string? := util:escape-chars(xdmp:get-request-field('uri'))[. != ""];
declare variable $locale as xs:string := util:escape-chars(xdmp:get-request-field('lang'));
declare variable $site as xs:string := util:escape-chars(xdmp:get-request-field('site'));
declare variable $ids as xs:string* := fn:tokenize(util:escape-chars(xdmp:get-request-field('ids')), ' ')[. != ""];

af:update-custom-page($locale, $uri, $ids, $site)