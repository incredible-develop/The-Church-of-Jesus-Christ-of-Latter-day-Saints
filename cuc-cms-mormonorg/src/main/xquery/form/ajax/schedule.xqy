xquery version "1.0-ml";

import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../modules/ldse-meta.xqy";
import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../../ice/modules/dynamicForms.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";

declare option xdmp:mapping "true";

let $ids as xs:string+ := fn:distinct-values( xdmp:get-request-field("ids[]") )
let $action as xs:string := xdmp:get-request-field("action")

for $id as xs:string in $ids
let $file as element() := ldsemeta:get-file-by($id, (), (), ())
let $form as element()? := form:getFormTemplate(ldsemeta:get-form-options($file)/form/fn:string(.))
let $origFile as element() := $file
let $newXml as element() := util:clone($file)

let $_ as empty-sequence() := form:buildParamMap()
let $sets as item()* := (
    form:setVariable('id', $id),
    form:setVariable('locale', ldsemeta:get-document-locale($file)),
    form:setVariable('uri', ldsemeta:get-document-uri($file))
)
let $newXml as element()? := 
	if ( $action = "ldse:schedule-publish" ) then (
	   form:scheduledPublish($origFile, $newXml, $form)
	) else if ( $action = "ldse:schedule-unpublish" ) then (
	   form:scheduledUnpublish($origFile, $newXml, $form)
	) else ()
where fn:exists($newXml)
return core:document-replace($origFile, $newXml)