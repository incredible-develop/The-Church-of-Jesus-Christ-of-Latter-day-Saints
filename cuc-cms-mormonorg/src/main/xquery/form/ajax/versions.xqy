xquery version "1.0-ml";

import module namespace version = "http://lds.org/code/lds-edit/versions" at "../../modules/versions-functions.xqy";

declare option xdmp:mapping "true";

declare variable $id as xs:string := xdmp:get-request-field('id');
declare variable $fn as xs:string := xdmp:get-request-field('fn');

if ($fn = "get-versions") then (
    xdmp:set-response-content-type('application/json'),
    version:get-versions-json($id)
) else if ( $fn = "get-version-form" ) then  (
    xdmp:set-response-content-type('test/html'),
    let $version as xs:string := xdmp:get-request-field('version')
    let $form as xs:string :=  xdmp:get-request-field('form')
    return (
        version:get-version-form($id, $version, $form)
    )
) else ()