xquery version "1.0-ml";

import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "modules/dynamicForms.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace json = "http://lds.org/code/shared/common/json/json-functions" at "/shared/common/json/jsonFunctions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../modules/utility-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../modules/ldse-core.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../modules/ldse-meta.xqy";

declare namespace cts = "http://marklogic.com/cts";
declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";

(: MAIN PARAMS :)
declare variable $locale as xs:string := ( form:getVariable('locale'), xdmp:get-request-field('lang'), 'eng' )[1]; 
declare variable $status as xs:string := form:getVariable('status'); (: preview, publish :)
declare variable $query as xs:string? := xdmp:get-request-field('query');
declare variable $formNames as xs:string* := fn:substring-after(xdmp:get-request-field('option'), 'form:');
declare variable $file-id as xs:string? := form:getVariable('id');
declare variable $site as xs:string? := xdmp:get-request-field('site')[1];
declare variable $ids as xs:string* := xdmp:get-request-field('ids[]');
declare variable $form as element(ldse:formTemplate)* := if ( fn:contains($formNames, ',') ) then ( for $formName as xs:string in fn:tokenize($formNames, ',') return form:getFormTemplate($formName) ) else ( form:getFormTemplate($formNames) );
(: *********** :)

declare function local:buildSearchQuery($ctsElements as element()*) as item()* {
    let $query :=
        cts:search(fn:collection(),
            cts:and-query((
                core:get-filter-query(),
                cts:or-query((
                    if ( fn:exists($site) ) then (
                        cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
                    ) else (),
                    cts:element-value-query(xs:QName('shareable'), 'true', 'exact')
                )),
                cts:element-attribute-value-query(xs:QName($ctsElements/cts:element/xs:string(.)), ( xs:QName('lang'), xs:QName('locale') ), $locale, 'exact'), 
                cts:word-query(fn:tokenize($query, '/s+'),("wildcarded", "diacritic-sensitive", "unstemmed", "case-insensitive", fn:concat("lang=", $locale)))
            ))
        )/*
        
	return $query
};

let $ctsQuery as item()* := local:buildSearchQuery($form/ldse:root-query/*)
let $main-collection as element()? := if ( fn:exists($file-id) ) then ( ldsemeta:get-file-by($file-id, $locale, (), ()) ) else ()
let $collection-ids as xs:string* := $main-collection/(items|contents)/(item|content)
let $results as element()* := $ctsQuery

return (
    json:serializeSet((
	   for $r as element() in $results
       let $id as xs:string? := ( ldsemeta:get-document-id($r), form:get-id($r, $form[@name = $r//ldse:form]) )[1]
       let $title as xs:string? := form:get-title($r, $form[@name = $r//ldse:form])
       let $uri as xs:string? := form:get-uri($r)
       let $thumbnail as xs:string? := form:get-thumbnail($r, $form[@name = $r//ldse:form])
       where fn:not($id eq $ids)
	   return ( 
	       if ( $id ne 'null' or $id ne ' ' or $id ne '' ) then (
				element results {
					attribute array {"true"},
					element id {$id},
					element title {$title},
                    element uri {$uri},
(:					element title {xs:string(($r//*[fn:node-name(.) eq $titleElementQName])[$titlePosition]/(if ($titleIsAttribute) then @*[fn:node-name(.) eq $titleAttrQName] else .))},:)
					if ( $thumbnail ) then (
						element image { 
							element src {$thumbnail}
						}
					) else ()
				}
			) else ()
		)
	))
)
