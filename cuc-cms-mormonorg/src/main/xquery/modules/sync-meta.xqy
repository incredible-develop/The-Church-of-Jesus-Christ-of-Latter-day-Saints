xquery version "1.0-ml";

import module namespace sync-meta = "http://lds.org/code/shared/lds-edit/sync-meta-spawn" at "sync-meta-spawn.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "ldse-meta.xqy";
import module namespace func = "http://lds.org/code/shared/lds-edit/function-apply" at "../invoke/function-apply.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

let $from-id as xs:string? := xdmp:get-request-field("id")
let $options as xs:string? := xdmp:get-request-field("options")
let $options-tok as xs:string* := fn:tokenize($options, ",")
let $options-form as xs:string := for $option-tok as xs:string in $options-tok return if(fn:starts-with($option-tok, "form:")) then $option-tok else ()
let $form-name as xs:string? := fn:substring-after($options-form, ":")
return
	if ( fn:exists($from-id) and fn:exists($form-name) ) then (
		let $from-xml as item()* :=
			cts:search(
				/*,
				cts:element-attribute-value-query(
					xs:QName("ldse:document"),
					xs:QName("id"),
					$from-id
				)
			)[1]
			
		let $from-uri as xs:string := $from-xml/xdmp:node-uri(.)
		let $to-xmls as element()* := ldsemeta:get-translated-files-in-preview($from-xml//ldse:document)
		let $to-uris as xs:string* := for $to-xml as element() in $to-xmls return xdmp:node-uri($to-xml)
		let $uris-map as map:map := map:map()
		let $no-op as empty-sequence() := map:put($uris-map, "uris", ($from-uri, $to-uris))
		return 
			func:spawn(xdmp:function(xs:QName("sync-meta:spawn"), "/modules/sync-meta-spawn.xqy"), "preview", $uris-map, $form-name, $from-id, ldsemeta:get-document-locale($from-xml), $ldsemeta:USERNAME, $ldsemeta:USERID)
			
	) else ()
