xquery version "1.0-ml";

import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "modules/dynamicForms.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "modules/iceFunctions.xqy";
import module namespace json = "http://lds.org/code/shared/common/json/json-functions" at "/shared/common/json/jsonFunctions.xqy";
import module namespace cc = "http://lds.org/code/shared/lds-edit/clear-cache-functions" at "../clear-cache/modules/clear-cache-functions.xqy";
import module namespace search="http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../modules/access-control-functions.xqy";
import module namespace site = "http://lds.org/code/shared/lds-edit/custom/ldse-site-core" at "../custom/lds-edit/ldse-site-core.xqy";
import module namespace cloneFunctions = "http://lds.org/code/shared/lds-edit/clone-functions" at "/ice/resources/ajax/clone-page/cloneFunctions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
(: Forces this transaction to be an update transaction :)
declare option xdmp:update "true";
declare option xdmp:mapping "true";

(: MAIN PARAMS :)
declare variable $locale as xs:string := form:getVariable('locale');   (: lang or lang-country :)
declare variable $formName as xs:string := form:getVariable('form');
declare variable $action as xs:string := form:getVariable('action'); (: edit, add :)
declare variable $status as xs:string := form:getVariable('status'); (: ldse:preview, ldse:publish, ldse:publish-all :)
declare variable $uri as xs:string := form:getVariable('uri');
declare variable $cloneFromId as xs:string? := xdmp:get-request-field('cloneFromId');
declare variable $site as xs:string? := xdmp:get-request-field('site');
declare variable $cloneId := xdmp:get-request-field('cloneId');
(: *********** :)

let $ajax as xs:boolean := xdmp:get-request-field("ajax","") eq "true"
let $buildMap as empty-sequence() := form:buildParamMap()
let $_form as element(ldse:formTemplate) := form:getFormTemplate($formName)
let $form := site:add-standardized-fields-to-iceform($_form)
let $file as element()? := form:getRootFile($form)

let $has-permission as xs:boolean :=
    if ($action = "edit") then (
        ac:has-permission('ldse:edit-doc', $locale, $uri)
    ) else if ($action = "add") then (
        ac:has-permission('ldse:add-doc', $locale, $uri)
    ) else ( fn:false() )

(: Get the name of the image path node :)
let $image-path-name as xs:string? := form:getVariable('image-path-node')

let $data as element()? := if ($cloneId) then
                cts:search(/cloneDoc,
                                cts:and-query((
                                    cts:element-attribute-value-query(xs:QName('cloneDoc'), xs:QName('cloneId'), $cloneId, 'exact'),
                                    cts:element-attribute-value-query(xs:QName('cloneDoc'), xs:QName('formName'), $formName, 'exact'),
                                    cts:element-attribute-value-query(xs:QName('cloneDoc'), xs:QName('component-id'), $cloneFromId, 'exact')
                                ))
                            )/element()
             else ()
let $delete := if ($data) then xdmp:document-delete($data/fn:base-uri()) else ()
return (
    if ($has-permission) then (
        let $id as xs:string :=
            if ($action eq 'add' or fn:empty($file)) then (
                form:newId($locale)
            ) else (form:getVariable('id'))
        let $newXml as element()? := if ($cloneId and $data) then
                                         cloneFunctions:copyFileUsedByClongingInsideComponentOnly($locale, $site, $uri, $data, $id)
                                     else
                                        let $newXml as element() := form:buildNewXml($status, $file, $form, $id)
                                        let $newXml as element() := ice:stripUrlsProcess($newXml)
                                        let $save as item()* := form:saveFile($file, $newXml, $form)
                                        return $newXml

        (: call the clear cache functionality if we are publishing or unpublishing :)
        let $uris as element(uris) := element uris { element uri {$uri} }
        let $clearCache as item()* :=
                        if ($status eq ('ldse:publish', 'ldse:unpublish')) then (
                            cc:clearCache($uris, $site, $locale, ())
                        ) else ()

        return (
           if ($ajax) then (
               json:serializeSet((
                    element id {xs:string($newXml/(@id|search-meta/source)[1])},
                    ($newXml/(search-meta|.)/title)[1],
                    if (fn:exists($image-path-name)) then (
                        $newXml//*[fn:node-name(.) eq xs:QName($image-path-name)]
                    ) else (),
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
               form:redirect($file, $newXml, $form)
            )
        )
    ) else (
        let $errorMsg as xs:string:="Sorry, you don't have permission to view this page."
        let $errorTitle as xs:string:= "Error!"
        return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
    )
)
