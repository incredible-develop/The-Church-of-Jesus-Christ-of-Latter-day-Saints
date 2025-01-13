xquery version "1.0-ml";

import module namespace history = "http://lds.org/code/shared/lds-edit/history/history" at "../../history/history.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";

declare namespace hldse = "http://lds.org/code/lds-edit/history";

declare option xdmp:mapping "true";

declare variable $id as xs:string := xdmp:get-request-field("id");
declare variable $locale as xs:string := xdmp:get-request-field("locale");

xdmp:set-response-content-type("application/json"),
history:get-file-history-json($id, $locale)