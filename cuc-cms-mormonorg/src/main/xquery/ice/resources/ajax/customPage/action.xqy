xquery version "1.0-ml";

import module namespace json = "http://lds.org/code/shared/common/json/json-functions" at "/shared/common/json/jsonFunctions.xqy";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../../modules/utility-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../../../modules/ldse-meta.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../../modules/access-control-functions.xqy";
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at "../../../../modules/document-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../../modules/ldse-settings.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "../../../modules/iceFunctions.xqy";
import module namespace pf = "http://lds.org/code/lds-edit/publishing-functions" at "../../../../modules/publishing-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare boundary-space preserve;
declare option xdmp:mapping "true";
declare option xdmp:update "true";


(: pass variables :)
    declare variable $action as xs:string := xdmp:get-request-field("action", "");
    declare variable $uri as xs:string := xdmp:url-decode(xdmp:get-request-field("uri", ""));
    declare variable $locale as xs:string := xdmp:get-request-field("locale", "");
    declare variable $site as xs:string? := xdmp:get-request-field("site");
(: item object :)
    declare variable $name as xs:string := xdmp:get-request-field("name", "");
    declare variable $folder as xs:string := xdmp:get-request-field("folder", "");
    declare variable $html-id as xs:string := xdmp:get-request-field("id", ""); (: html id not a file id :)
    declare variable $ids as xs:string+ := xdmp:get-request-field("ids[]", "");


declare variable $has-permission as xs:boolean :=  ac:is-action-allowed($action, $locale, $uri);

declare variable $files as element(custom-page)? := ice:get-custom-page($uri, $locale, fn:true(), $site);

xdmp:set-response-content-type("application/json"),
if ($has-permission) then (
        let $response as item()* :=
            if ( fn:exists($files) ) then (
                (: Attempt to get lock on file :)
                let $lock as xs:boolean := 
                    if (settings:action-should-lock($action)) then (
                        every $file in $files satisfies document:lock($file, fn:concat("Preforming Action On File"))
                    ) else ( fn:true() )
                (: Publish the file :)
                let $test := $site
                let $files := $files
                let $e := fn:error()
                return 
                    if ( $lock ) then (
                        try {
                            let $perform as item()* :=
                                for $file as element(custom-page) in $files
                                let $publishable as xs:boolean := pf:is-publishable($file, $uri)
                                where $publishable
                                return (
                                    if ( $action = "ldse:publish" ) then (
                		                let $db-path as xs:string := xdmp:node-uri($file)
                                        let $new-file as element() := ldsemeta:update-sensitive-file($file, (), (), "yes", "no", $action, ())
                                        return (
                		                    core:update-file($action, $db-path, core:action-transform($action, $new-file), $file)
                                        )
                                    ) else (
                                        core:preform-action-and-update($action, $file)
                                    )
                                )
                            return ( fn:true(), "" ) 
                        } catch ($e) {
                            fn:false(), "Action Failed",
                            xdmp:trace("ldse-action", $action),
                            xdmp:trace("ldse-action", "Action: error preforming action on files."),
                            xdmp:trace("ldse-action", $e)
                        }
                    ) else (
                        (fn:false(), "Error - couldn't get lock")
                    )
            ) else (
                (fn:true(), "")
            )
        let $xml as element(response) := 
            <response>
                <action>{$action}</action>
                <uri>{$uri}</uri>
                <locale>{$locale}</locale>
                <success>{$response[1]}</success>
                <error>{$response[2]}</error>
                <count>{fn:count($files)}</count>
                <name>{$name}</name>
                <folder>{$folder}</folder>
                <id>{$html-id}</id>
                <ids>{fn:string-join($ids, ',')}</ids>
            </response>
        return json:serialize($xml)
) else ( 
    let $errorMsg as xs:string:="Sorry, an error occured." 
    let $errorTitle as xs:string:= "Error!" 
    return xdmp:redirect-response( fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle) )
)
    
