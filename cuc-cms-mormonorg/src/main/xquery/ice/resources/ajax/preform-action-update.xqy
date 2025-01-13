xquery version "1.0-ml";

import module namespace json = "http://lds.org/code/shared/common/json/json-functions" at "/shared/common/json/jsonFunctions.xqy";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../../modules/ldse-meta.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../modules/access-control-functions.xqy";
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at "../../../modules/document-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../modules/ldse-settings.xqy";
import module namespace correlation = "http://lds.org/code/shared/lds-edit/correlation" at "../../../correlation/modules/correlation-functions.xqy";
import module namespace func = "http://lds.org/code/shared/lds-edit/function-apply" at "../../../invoke/function-apply.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace rw = "http://lds.org/code/shared/lds-edit/rewrite-functions" at "../../modules/rewrite-functions.xqy";
import module namespace pf = "http://lds.org/code/lds-edit/publishing-functions" at "../../../../modules/publishing-functions.xqy";

declare namespace handle-correlation = "http://lds.org/code/shared/lds-edit/handle-correlation";
declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace cldse = "http://lds.org/code/lds-edit/correlation";

declare boundary-space preserve;
declare option xdmp:mapping "true";

let $action as xs:string := xdmp:get-request-field("action", "")
let $type as xs:string := xdmp:get-request-field("type", "")
let $id as xs:string := xdmp:get-request-field("id", "")
let $locale as xs:string := util:escape-chars(xdmp:get-request-field("locale", ""))
let $page as xs:string := xdmp:get-request-field("currentPage", "")

let $has-permission as xs:boolean :=  ac:is-action-allowed($action, $locale, $page)
let $setContentType as empty-sequence() := xdmp:set-response-content-type("application/json")
return
if ($has-permission) then (
        let $file as element()? := ldsemeta:get-file-by($id, $locale, (), ())
        let $response as item()* :=
            if ( fn:exists($file) ) then (
                (: Attempt to get lock on file :)
                let $lock as xs:boolean := 
                    if (settings:action-should-lock($action)) then (
                        document:lock($file, fn:concat("Preforming Action On File"))
                    ) else ( fn:true() )
                (: Publish the file :)
                return 
                    if ( $lock ) then (
                        let $result as item()* :=   
                            try {
                                let $uri as xs:string? := ldsemeta:get-document-uri($file)
                                let $publishable as xs:boolean := pf:is-publishable($file, $uri)
                                let $correlation-status as xs:string? := ldsemeta:get-correlation-status($file)
                                let $is-published as xs:boolean := ldsemeta:is-published($file)
                                let $rewrite as item()* := 
                                    typeswitch ( $file ) 
                                    case element(custom-page) return (
                                        rw:update-rewrite-rule($action, ldsemeta:get-document-uri($file), ldsemeta:get-document-locale($file), $file )
                                    ) default return ()
                                return (
                                    if ( fn:contains($action, "ldse:publish") and $settings:correlation-enabled and $publishable ) then ( 
                                        let $new-file as element() := ldsemeta:update-sensitive-file($file, (), (), "yes", "no", $action, ())
                                        return (
                                            if ( ldsemeta:correlation-can-publish($file) ) then (
                                                if ( correlation:file-can-be-sent-to-correlation($file) ) then (
                                                    let $correlation-document-uri as xs:string := correlation:initiate-operation-fake-form-post(ldsemeta:get-document-id($file))
                                                    return (
                                                        core:update-file($action, xdmp:node-uri($file), core:action-transform($action, $new-file), $file),
                                                        func:spawn(xdmp:function(xs:QName("handle-correlation:spawn"), "/correlation/modules/handle-correlation-spawn.xqy"), "preview", $correlation-document-uri, fn:false(), ldsemeta:get-document-id($file), ldsemeta:get-document-locale($file))
                                                    )
                                                ) else ( core:update-file($action, xdmp:node-uri($file), core:action-transform($action, $new-file), $file) )
                                            ) else ( )(: Document is in a state that does not allow publishing or user does not have rights to override") :)
                                        )
                                    ) else if ( $action = "ldse:publish" and $publishable ) then (
                                        let $db-path as xs:string := xdmp:node-uri($file)
                                        let $new-file as element() := ldsemeta:update-sensitive-file($file, (), (), "yes", "no", $action, ())
                                        return (
                                            core:update-file($action, $db-path, core:action-transform($action, $new-file), $file)
                                        )
                                    ) else if ( $action = "ldse:publish" ) then (
                                        fn:false()
                                    ) else (
                                        let $file as element() := core:preform-action-and-update($action, $file)
                                        return ()
                                    )
                              )
                            } catch ($e) {
                                fn:false(), "Action Failed",
                                xdmp:trace("ldse-action", $action),
                                xdmp:trace("ldse-action", "Action: error preforming action on file."),
                                xdmp:trace("ldse-action", $e)
                            }
                        return (
                            if (fn:empty($result)) then ( (fn:true(), "") ) else ( $result )
                        )
                    ) else (
                        (fn:false(), "Error - couldn't get lock")
                    )
            ) else (
                (fn:true(), "")
            )
        let $xml as element(response) := 
            <response>
                <action>{$action}</action>
                <locale>{$locale}</locale>
                <currentPage>{$page}</currentPage>
                <id>{$id}</id>
                <type>{$type}</type>
                <successful>{$response[1]}</successful>
                <error>{$response[2]}</error>
                <numberPublished>{fn:count($file)}</numberPublished>
            </response>
        return json:serialize($xml)
) else ( 
    let $errorMsg as xs:string:="Sorry, an error occured." 
    let $errorTitle as xs:string:= "Error!" 
    return xdmp:redirect-response( fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle) )
)
    
