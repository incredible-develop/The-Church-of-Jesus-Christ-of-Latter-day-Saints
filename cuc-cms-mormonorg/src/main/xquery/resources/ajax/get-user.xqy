xquery version "1.0-ml";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare variable $username as xs:string? := xdmp:get-request-field('username')[. ne ''];
declare variable $arrays as xs:string* := xdmp:get-request-field('arrays')[. ne ''];
declare variable $element as xs:string* := xdmp:get-request-field('element')[. ne ''];
declare variable $data as xs:string? := xdmp:get-request-field('data')[. ne ''];

if ( $data = 'json' ) then (
    let $val as element(ldse:contributor)? := core:get-contributor($username)
    let $arrays as xs:QName* := 
        for $array as xs:string in $arrays
        return (
            xs:QName($array)
        )
    return (
        core:transform-to-json($val, $arrays)
    )
) else (
    core:get-contributor($username)
)