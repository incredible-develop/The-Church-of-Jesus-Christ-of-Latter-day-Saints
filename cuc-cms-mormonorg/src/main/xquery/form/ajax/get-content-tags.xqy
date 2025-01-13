xquery version "1.0-ml";

import module namespace df = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../../ice/modules/dynamicForms.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare variable $tag-name as xs:string := xdmp:get-request-field('tag');
declare variable $lang as xs:string := xdmp:get-request-field('lang');
declare variable $site as xs:string := xdmp:get-request-field('site');

let $content as element()* := df:get-content-with-tags($tag-name, $lang, $site)
let $count as xs:int := fn:count($content)

return (
    object-node {
        'count': $count
    }
)
