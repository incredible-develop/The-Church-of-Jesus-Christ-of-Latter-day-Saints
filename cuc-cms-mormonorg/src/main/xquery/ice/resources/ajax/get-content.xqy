xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";
import module namespace file-query = "http://lds.org/code/shared/lds-edit/file-query" at "../../modules/file-query.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../modules/ldse-core.xqy";
import module namespace json = "http://marklogic.com/json" at "../../../modules/fasterjson.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../modules/ldse-settings.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../../modules/ldse-meta.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
(:declare option xdmp:mapping "true";:)

let $id as xs:string? := util:sanitize-input(xdmp:get-request-field("id"))[. ne ""]
let $uri as xs:string? := util:sanitize-input(xdmp:get-request-field("uri"))[. ne ""]
(:let $formname as xs:string := util:sanitize-input(xdmp:get-request-field("formname")):)
let $lang as xs:string? := util:escape-chars(xdmp:get-request-field("lang", "eng"))
let $options as xs:string? := xdmp:get-request-field("options")[. ne ""]
let $root-element as xs:string? := util:escape-chars(xdmp:get-request-field("rootElement"))[. ne ""]
let $directory as xs:string? := util:escape-chars(xdmp:get-request-field("directory"))[. ne ""]
let $format as xs:string? := util:escape-chars(xdmp:get-request-field("format"))[. ne ""]
let $site as xs:string? := xdmp:get-request-field('site')[. ne ""]
let $categories as xs:string* := xdmp:get-request-field('categories')[. ne ""]
let $files as element()* := file-query:get-content-file($id, $uri, $lang, $options, $root-element, $directory, $categories, $site)

return (
    if ( $format = "xml" ) then (
        $files
    ) else (
        json:arr-enhanced(
            for $file in $files
            let $link as xs:string := fn:concat('"',"https://", core:get-domain($file, $lang), "/", $settings:shared-prefix, "/form?lang=", ldsemeta:get-document-locale($file), "&amp;id=", ldsemeta:get-document-id($file),'"')
            return (
                json:arr-enhanced(
                    (
                        core:transform-to-json($file, ("links")),
                        fn:concat('{',json:keyObject("editLink", $link),'}')
                    )
                )
            )
        )
    )
)