xquery version "1.0-ml";

import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "../../modules/iceFunctions.xqy";

declare variable $current-page as xs:string := xdmp:get-request-field('currentPage')[. ne ''];
declare variable $lang as xs:string* := xdmp:get-request-field('lang')[. ne ''];
declare variable $is-template as xs:string := xdmp:get-request-field('isTemplate')[. ne ''];
declare variable $options as xs:string? := xdmp:url-decode(xdmp:get-request-field('options')[. ne '']);
declare variable $data as xs:string? := xdmp:url-decode(xdmp:get-request-field('data')[. ne '']);

let $options as element(options)? := ice:csv-variables($options)
let $is-template as xs:boolean := 
    if ( $is-template = 'true' ) then (
        fn:true()
    ) else ( fn:false() )
    
return (
    if ( $data = 'json' ) then (
        ice:add-gear-links($current-page, $lang, (), $is-template, $options)
    ) else (
        ice:add-gear($current-page, $lang, $is-template, $options)
    )
)