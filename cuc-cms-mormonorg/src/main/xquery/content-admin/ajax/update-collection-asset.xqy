xquery version "1.0-ml";

import module namespace af = "http://lds.org/code/lds-edit/content-admin/admin-functions" at "../modules/functions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";

declare variable $locale as xs:string := util:escape-chars(xdmp:get-request-field('lang', 'eng'))[. != ''];
declare variable $site as xs:string := util:escape-chars(xdmp:get-request-field('site'))[. != ''];
declare variable $asset-id as xs:string := util:escape-chars(xdmp:get-request-field('assetId'))[. != ''];
declare variable $collection-ids as xs:string* := xdmp:get-request-field('ids[]')[. != ""];
declare variable $status as xs:string := util:escape-chars(xdmp:get-request-field('status'))[. != ''];

af:update-collection-asset($locale, $collection-ids, $site, $asset-id, $status)