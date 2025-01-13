xquery version "1.0-ml";

import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";
import module namespace ldse-meta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../modules/ldse-meta.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

(: Forces this transaction to be an update transaction :)
declare option xdmp:update "true";
declare option xdmp:mapping "true";

(: MAIN PARAMS :) (: preview, publish :)
(:declare variable $uri as xs:string := form:getVariable('uri');
declare variable $site as xs:string := form:getVariable('site');
:)

let $id as xs:string := xdmp:get-request-field('id')
let $file := ldse-meta:get-file-by($id, (), (), ())
let $uri := xdmp:node-uri($file)
let $referer := xdmp:get-request-header('Referer')

return (
      core:delete-file($uri, $file, ()),
      xdmp:redirect-response($referer)
)

