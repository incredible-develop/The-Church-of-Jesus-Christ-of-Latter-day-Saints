xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../../modules/utility-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../../../modules/ldse-meta.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../../modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../../modules/access-control-functions.xqy";

declare boundary-space preserve;
declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

declare variable $lang as xs:string := util:escape-chars(xdmp:get-request-field("lang", "eng"));
declare variable $country as xs:string? := util:escape-chars(xdmp:get-request-field("country", ""));
declare variable $locale as xs:string := if ($country ne '') then (fn:concat($lang, '-', $country)) else ($lang);

let $id as xs:string := util:escape-chars(xdmp:get-request-field("id", ""))
let $currentPage as xs:string := util:escape-chars(xdmp:get-request-field("curPage", ""))

let $teaser as element(teaser)? := ldsemeta:get-file-by($id, $locale, (), ())

return (
    if (ac:has-permission('ldse:edit-teaser-sequence', $locale, $currentPage) and fn:exists($teaser) ) then (
        xdmp:set-response-content-type( "text/html" ),
        <div id="edit-sequence" class="padding-sm" title="Edit Teaser Sequence">
            <form class="ldse-form" method="post" action="{$settings:shared-prefix}/ice/resources/ajax/teaser/updateSequence{util:split-locale-param($locale)}" enctype="multipart/form-data" id="teaserForm" onsubmit="fixNullInput();">
                <dl>
                    <dt class="sequence">Sequence:</dt>
                    <dd><input class="ice-seq sm" type="text" id="sequence" name="sequence" value="{fn:data($teaser/@sequence)}"/></dd>
                </dl>
                <dl>
                    <dd>
                            <input type="hidden" name="id" value="{$id}"/>
                            <input type="hidden" name="currentPage" value="{$currentPage}"/>
                            <input type="submit" class="ldse-button ldse-primary float-right" value="Save"/>
                     </dd>
                </dl>
            </form>
        </div>
    ) else ( 
         let $errorMsg as xs:string:="Sorry, You don't have permission" 
         let $errorTitle as xs:string:= "Access Denied!"
         return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
    )
)
