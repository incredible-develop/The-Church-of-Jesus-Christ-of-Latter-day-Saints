xquery version "1.0-ml";

import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../../../modules/dynamicForms.xqy";
import module namespace json = "http://marklogic.com/json" at "../../../../modules/fasterjson.xqy";

declare option xdmp:mapping "true";

declare variable $locale as xs:string := xdmp:get-request-field('locale');
declare variable $uri as xs:string := xdmp:get-request-field('uri');
declare variable $content-type as xs:string? := xdmp:get-request-field('type');
declare variable $location as xs:string? := xdmp:get-request-field('location');
declare variable $parent-id as xs:string? := xdmp:get-request-field('parentId');
declare variable $country as xs:string? := xdmp:get-request-field('country')[1];
declare variable $options as xs:string := xdmp:get-request-field('option');

let $create-component as item()* := form:prebuild-component($locale, $uri, $country, $location, $content-type, $parent-id, $options)

return (
    xdmp:set-response-content-type('application/json'),
    json:obj((
    	json:escapedKeyValue('success', "true")
    ))
)
