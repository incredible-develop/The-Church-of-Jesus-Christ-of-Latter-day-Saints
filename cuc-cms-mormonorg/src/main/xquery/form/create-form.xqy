xquery version "1.0-ml";

import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../ice/modules/dynamicForms.xqy";
import module namespace json = "http://lds.org/code/shared/common/json/json-functions" at "/shared/common/json/jsonFunctions.xqy";
import module namespace faster-json = "http://marklogic.com/json" at "../modules/fasterjson.xqy";
import module namespace cc = "http://lds.org/code/shared/lds-edit/clear-cache-functions" at "/clear-cache/modules/clear-cache-functions.xqy";
import module namespace search="http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace fbf = "http://lds.org/code/shared/lds-edit/form-builder-functions" at "/form/modules/form-builder-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "/modules/ldse-meta.xqy";
import module namespace mljson = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace cldse = "http://lds.org/code/lds-edit/correlation";
declare namespace sync-meta-spawn = "http://lds.org/code/shared/lds-edit/sync-meta-spawn";
(: Forces this transaction to be an update transaction :)
declare option xdmp:update "true";
declare option xdmp:mapping "true";

(: MAIN PARAMS :)
declare variable $formName as xs:string? := xdmp:get-request-field('formName');
declare variable $action as xs:string := form:getVariable('action'); (: edit, add :)
declare variable $uri as xs:string := form:getVariable('uri');
declare variable $user as xs:string := ac:getUserName();

let $var := xdmp:get-request-field('form')
let $test := mljson:transform-from-json($var, mljson:config('basic'))

let $ajax as xs:boolean := xdmp:get-request-field("ajax","") eq "true"
(:let $buildMap as empty-sequence() := form:buildParamMap():)
let $form as element(ldse:formTemplate)? := fbf:getForm($formName)
let $file as element()? := fbf:getForm(())
let $has-permission as xs:boolean := fn:true()
(: Get the name of the image path node :)
let $image-path-name as xs:string? := form:getVariable('image-path-node')
let $forceRedirect as xs:string := "false"
let $id as xs:string :=
	if (fn:empty($file))
	then form:newId('eng')
	else form:getVariable('id')

let $save := fbf:jsonBuildNewXml($file, $test, $id)
let $e := fn:error()
return
	if ($has-permission )
	then
        let $newXml as element() := fbf:buildNewFormXml($file, $form, (), $id)
		let $save as empty-sequence() := fbf:saveForm($newXml, $file, $form)
        let $redirect as xs:string? := form:redirect($file, $newXml, $form)
		return (
		  xdmp:set-response-code(200, "OK"),
		  xdmp:set-response-content-type('application/json'),
          if ($ajax) then (
                let $doc-title as element(ldse:document-title)? := $form/ldse:document-title
                let $title as xs:string? :=
                    if (fn:exists($doc-title)) then (
                        form:dynamicXpath($newXml, $doc-title/text())
                    ) else (
                        xs:string(fn:normalize-space(ldsemeta:get-document-title($newXml)))
                    )
                return
                    json:serializeSet((
                        element id {xs:string(ldsemeta:get-document-id($newXml))},
                        element title { $title },

                        element search {
                            search:snippet(
                                $newXml,
                                search:parse("*"),
                                <transform-results apply="snippet" xmlns="http://marklogic.com/appservices/search">
                                    <per-match-tokens>30</per-match-tokens>
                                    <max-matches>4</max-matches>
                                    <max-snippet-chars>200</max-snippet-chars>
                                    <preferred-elements>
                                        <element name="title"/>
                                        <element name="description"/>
                                        <element name="p" ns="http://www.w3.org/1999/xhtml"/>
                                        <element name="p"/>
                                        <element name="div" ns="http://www.w3.org/1999/xhtml"/>
                                        <element name="div"/>
                                    </preferred-elements>
                                </transform-results>
                            )/search:match[1]/xs:string(.)
                        }
                    ))
            ) else (
                faster-json:obj((
                    faster-json:keyEscapedValue("success", "true"),
                    faster-json:keyEscapedValue("form", $form/@name/fn:string()),
                    faster-json:keyObject("forceRedirect", if ( fn:exists($forceRedirect) ) then ( $forceRedirect ) else ("") ),
                    faster-json:keyEscapedValue("redirect", if ( fn:exists($redirect) ) then ( $redirect ) else ("") ),
                    faster-json:keyEscapedValue("uri", ( form:getVariable('uri'), "" )[1])
                ))
            )
		)
	else (
        faster-json:obj((
            faster-json:keyEscapedValue("success", "false")
        ))
    )
