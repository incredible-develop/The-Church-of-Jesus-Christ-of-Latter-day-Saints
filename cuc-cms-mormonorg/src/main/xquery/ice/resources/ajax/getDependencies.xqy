xquery version "1.0-ml";

import module namespace json = "http://marklogic.com/json" at "../../../modules/fasterjson.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../modules/access-control-functions.xqy";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../modules/ldse-core.xqy";
import module namespace df = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../../modules/dynamicForms.xqy";

declare boundary-space preserve;
declare option xdmp:mapping "true";
declare option xdmp:update "true";

(: pass variables :)
declare variable $action as xs:string := xdmp:get-request-field("action", "");
declare variable $uri as xs:string := xdmp:get-request-field("uri", "");
declare variable $locale as xs:string := xdmp:get-request-field("locale", "");
declare variable $pageUri as xs:string := xdmp:get-request-field("pageUri", "");
declare variable $compID as xs:string := xdmp:get-request-field("compID","");
declare variable $compName as xs:string := xdmp:get-request-field("compName","");

declare variable $has-permission as xs:boolean := ac:is-action-allowed($action, $locale, $uri);

xdmp:set-response-content-type("application/json"),
if ($has-permission) then (
    let $options := 
         <options xmlns="http://marklogic.com/appservices/search">
            <searchable-expression>/custom-page</searchable-expression>
            <additional-query>{
                cts:and-query((
                    cts:element-query(xs:QName('content'),
                        cts:and-query((
                            core:get-filter-query(),
                            cts:element-value-query(xs:QName($compName), $compID, ('exact'))                            
                        ))
                    ),
                    cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('locale'), df:getVariable('locale'), ('exact'))
                ))
            }</additional-query>
         </options>

    let $files := search:search("", $options,1,10)     
    let $urls := for $file in $files/search:result
                 let $_doc := $file/@uri/fn:string()
                 let $uri := fn:doc($_doc)/element()/@uri/fn:string()
                 return (
                        if($uri eq $pageUri) then ( ()
                        ) else ( $uri )
                 )
    return (
        xdmp:set-response-content-type('application/json'),
        json:arrq(fn:distinct-values($urls))
     )         
) else ( 
    fn:false(), "You don't have permissions to perform this action"
)