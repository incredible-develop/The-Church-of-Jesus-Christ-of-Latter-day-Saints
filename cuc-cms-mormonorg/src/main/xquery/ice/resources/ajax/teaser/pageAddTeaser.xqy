xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../../modules/utility-functions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../../modules/access-control-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../../modules/ldse-core.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "../../../modules/iceFunctions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../../../modules/ldse-meta.xqy";

declare boundary-space preserve;
declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";
declare option xdmp:update "true";

let $country as xs:string? := util:escape-chars(xdmp:get-request-field("country", ""))
let $preLang as xs:string? := util:escape-chars(xdmp:get-request-field("lang", "eng"))

let $lang as xs:string := if ($country ne '') then (fn:concat($preLang,'-',$country)) else ($preLang)

let $teaserType as xs:string? := xdmp:get-request-field("teaserType", "")
let $requestId as xs:string? := xdmp:get-request-field("id", "000")
let $page as xs:string? := xdmp:get-request-field("currentPage", "")
let $uriPage as xs:string? := if (fn:ends-with($page, "/")) then ($page) else (fn:concat($page, "/"))
let $pageLocation as xs:string? := xdmp:get-request-field("pageLocation", "")

let $pageXml as element(custom-page)? := ice:get-custom-page($page, $lang)

let $teaser as element(teaser) := cts:search(/teaser[@locale eq $lang and @id eq $requestId], core:get-filter-query())

let $id as xs:string := if ($teaser/@page ne $page) then (util:generate-unique-id($lang)) else ($requestId)

let $teaserUri as xs:string := 
    if ($teaser/@page ne $page) then (
        core:build-db-path($page, $lang, $id, $teaser, <options><file-prefix>{fn:concat($pageLocation, "-")}</file-prefix></options>)
    ) else (
        xdmp:node-uri($teaser)
    )

let $ldse-meta as element(ldse:ldse-meta) := ldsemeta:get-meta($teaser, $id, $lang, $page, 'preview')
let $newTeaser as element(teaser) := 
    element teaser {
        attribute id {$id},
        attribute type {$teaserType},
        attribute locale {$lang},
        attribute status {'preview'},
        attribute sequence {1},
        attribute page {$page},
        attribute location {$pageLocation},
        $ldse-meta,
        $teaser/*[fn:not( self::ldse:ldse-meta )]
    }

let $saveTeaser as item()* := core:save-file($teaserUri, $newTeaser, ())

let $updatePageXml as item()* := 
    if (fn:exists($pageXml) and fn:empty($pageXml/content/teaser[. eq $id])) then (
            xdmp:node-insert-child($pageXml/content, <teaser type="{$teaserType}" location="{$pageLocation}">{$id}</teaser>)     
    ) else ()

return (<result>{$saveTeaser}: {$teaserUri}</result>)
