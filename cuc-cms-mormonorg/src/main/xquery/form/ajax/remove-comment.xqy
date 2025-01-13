xquery version "1.0-ml";

import module namespace history = "http://lds.org/code/shared/lds-edit/history/history" at "../../history/history.xqy";

declare option xdmp:mapping "true";

let $id as xs:string := xdmp:get-request-field("id")
let $locale as xs:string := xdmp:get-request-field("locale")
let $remove-id as xs:string := xdmp:get-request-field("commentId")

return history:remove-comment($id, $locale, $remove-id)