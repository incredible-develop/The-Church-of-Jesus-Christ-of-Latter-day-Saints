xquery version "1.0-ml";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../modules/ldse-core.xqy";
import module namespace history = "http://lds.org/code/shared/lds-edit/history/history" at "../../../history/history.xqy";
import module namespace json = "http://marklogic.com/json" at "../../../modules/fasterjson.xqy";
import module namespace sens-functs = "http://lds.org/code/shared/lds-edit/sensitive/functions" at "../../modules/functions.xqy";

declare option xdmp:mapping "true";

declare variable $ids as xs:string* := xdmp:get-request-field('ids[]');

for $id as xs:string in $ids
let $save as item()* := sens-functs:approve-item($id)
return (
    $save
)
