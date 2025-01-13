xquery version "1.0-ml";

import module namespace form = "http://lds.org/code/shared/lds-edit/form-save" at "../ice/modules/form-save.xqy";

(: Forces this transaction to be an update transaction :)
declare option xdmp:update "true";
declare option xdmp:mapping "true";

(: MAIN PARAMS :)
declare variable $sync-meta as xs:string? := xdmp:get-request-field("sync-meta");
declare variable $categoryName as xs:string* := xdmp:get-request-field("category");
declare variable $is-submission as xs:boolean := xs:boolean(xdmp:get-request-field("is-submission", "false"));

form:formSave($sync-meta, $categoryName, $is-submission)
