xquery version "1.0-ml";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../../modules/utility-functions.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "../../../modules/iceFunctions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../../modules/access-control-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../../modules/ldse-core.xqy";

declare boundary-space preserve;
declare option xdmp:mapping "true";
(: This page is used via AJAX, called by browse.xqy :)

let $country as xs:string? := util:escape-chars(xdmp:get-request-field("country", ""))
let $preLang as xs:string := util:escape-chars(xdmp:get-request-field("lang", "eng"))

let $lang as xs:string := if ($country != "") then (fn:concat($preLang,'-',$country)) else ($preLang)

let $site as xs:string := $core:site

let $currentPage as xs:string := xdmp:get-request-field("currentPage", "")
let $location as xs:string := util:escape-chars(xdmp:get-request-field("pageLocation", ""))
let $currentId as xs:string := util:escape-chars(xdmp:get-request-field("currentId", ""))
let $newId as xs:string := util:generate-unique-id($lang)

let $url as xs:string := $currentPage

let $oldTeaser as element(teaser)* := cts:search(/teaser[@id eq $currentId], core:get-filter-query())

let $noCopy as xs:boolean := if (fn:data($oldTeaser/@locale) eq $lang and fn:data($oldTeaser/@page) eq $currentPage) then (fn:true()) else (fn:false())

let $ldsxmlTeaser as xs:boolean := if (fn:starts-with($url,'/ensign')) then (fn:true())
                else if (fn:starts-with($url,'/friend')) then (fn:true())
                else if (fn:starts-with($url,'/liahona')) then (fn:true())
                else if (fn:starts-with($url,'/new-era')) then (fn:true())
                   else (fn:false())

return (
    if (ac:has-permission("ldse:edit-doc", $lang, $currentPage)) then (
        (: Create teaser and save it to the database :)
        let $id as xs:string :=
            if ($noCopy)
            then ($currentId)
            else (
                let $newTeaser as element(teaser) :=
                        <teaser id="{$newId}" type="{fn:data($oldTeaser/@type)}" locale="{$lang}" status="preview" sequence="{fn:data($oldTeaser/@sequence)}" page="{$url}" location="{$location}">
                            {$oldTeaser/node()}
                        </teaser>

                let $teaserPath as xs:string := core:build-db-path($url, $lang, $newId, $newTeaser, <options><file-prefix>{$location}-</file-prefix></options>)
                                    
                let $statusUpdatedTeaser as item()* := core:save-file($teaserPath, $newTeaser, ()) 
                let $debug as item()* := xdmp:trace("ldsorgICE", fn:concat("SavedTeaser:",$teaserPath))

                (: Add teaser reference to page.xml :)
                let $addToPage as item()* :=
                    try {
                        let $pageContent as element(content)* := ice:get-custom-page($url, $lang)/content
                        return (
                            if (fn:not($ldsxmlTeaser))
                            then (xdmp:node-insert-child($pageContent, <teaser type="{fn:data($oldTeaser/@type)}" location="{$location}">{$newId}</teaser>))
                            else ()
                        )
                    } catch ($exception) {
                        let $debug as item()* := xdmp:trace("ldsorgICE", fn:concat("copyTeaser: error finding page file for ", $url))
                        let $debug as item()* := xdmp:trace("ldsorgICE", $exception)
                        return (fn:false(), "Error finding page file")
                    }
               return $currentId
           )
      return $id
   ) else ()
)
