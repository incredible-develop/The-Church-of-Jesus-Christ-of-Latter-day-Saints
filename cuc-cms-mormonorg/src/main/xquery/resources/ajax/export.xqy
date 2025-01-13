xquery version "1.0-ml";

import module namespace excel = "http://marklogic.com/openxml/excel" at "../../modules/spreadsheet-ml-support.xqy";
import module namespace content = "http://lds.org/code/shared/lds-edit/contentFunctions" at "../../content/modules/contentFunctions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace faster-json = "http://marklogic.com/json" at "../../modules/fasterjson.xqy";

declare namespace json = "http://marklogic.com/xdmp/json";
declare namespace xsi = "http://www.w3.org/2001/XMLSchema-instance";

declare option xdmp:mapping "true";

declare function local:to-xml($json-node as item()) as item()*
{
	typeswitch($json-node)
		case element(json:object) return
			local:to-xml($json-node/node())
		
		case element(json:entry) return
			local:get-entry($json-node)
		
		case element(json:array) return
			local:to-xml($json-node/node())
		
		case element(json:value) return
			if(fn:exists($json-node/@xsi:type))
			then fn:data($json-node)
			else local:to-xml($json-node/node())
			
		case element(map:map) return
			local:to-xml($json-node/node())
		
		case element(map:entry) return
			local:get-entry($json-node)
		
		case element(map:value) return
			if(fn:exists($json-node/@xsi:type) and fn:not($json-node/@xsi:type = xs:QName("map:map")))
			then fn:data($json-node)
			else local:to-xml($json-node/node())
		
		default return local:to-xml($json-node/node())
};

declare function local:get-entry($json-node as item()) as item()*
{
	element {fn:replace(fn:replace(xdmp:diacritic-less($json-node/@key), '[^a-zA-Z0-9_]' ,''), '_+', '_')} {local:to-xml($json-node/node())}
};

let $title as xs:string := xdmp:get-request-field("title")
let $json as xs:string := fn:string-join(xdmp:get-request-field("json"), "")
let $json-object as item()*:= xdmp:from-json($json)
let $json-xml as item()* := local:to-xml(<json>{$json-object}</json>)
let $excel as binary() := excel:create-xlsx-from-xml-table($json-xml)
let $file-name as xs:string := fn:string-join((fn:tokenize($title, " "), fn:format-dateTime(fn:current-dateTime(), "[Y0001]-[M01]-[D01]_[h01][m01]")), "_") 

return (
	xdmp:add-response-header("Content-Disposition", fn:concat("attachment; filename=", $file-name, ".xlsx")),
	xdmp:set-response-content-type("application/octet-stream"),
	$excel
)




























