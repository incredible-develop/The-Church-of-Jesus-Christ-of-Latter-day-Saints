xquery version "1.0-ml";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace history = "http://lds.org/code/shared/lds-edit/history/history" at "/history/history.xqy";
import module namespace json = "http://marklogic.com/json" at "/modules/fasterjson.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";

declare option xdmp:mapping "true";

declare variable $flag as xs:string := xdmp:get-request-field('flag');
let $username as xs:string := ac:getUserName()
let $userid as xs:string? := ac:getPersonId()
let $id as xs:string := xdmp:get-request-field("id")
let $locale as xs:string := xdmp:get-request-field("locale")
let $username as xs:string? := xdmp:get-request-field("username")
let $date as xs:dateTime := fn:current-dateTime()
let $name as xs:string := core:get-contributor-name($username)
let $save as item()? :=
    if ( $flag = 'true' ) then (
        history:remove-follow-event($id, $locale, $username)
    ) else (
        history:build-follow-event($id, $locale, $date, $username, $userid)
    )
return (
    xdmp:set-response-content-type('application/json'),
    json:obj((
    	json:escapedKeyValue('username', $username),
    	json:escapedKeyValue('name', $name)
    ))
)
