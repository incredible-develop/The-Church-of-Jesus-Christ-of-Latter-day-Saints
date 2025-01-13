xquery version "1.0-ml";

import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../../modules/ldse-meta.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../modules/ldse-settings.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";

let $id as xs:string := xdmp:get-request-field("id")

return
	if ( $id ) then (
		let $file as element() := ldsemeta:get-file-by($id, (), (), ())
        let $sensitive as element(ldse:sensitive)? := ldsemeta:get-sensitive($file)
        let $sensitive-page as xs:boolean? := 
            for $sensitive-uri as element(ldse:sensitive-uri) in $settings:sensitive-uris/ldse:sensitive-uri
            where $sensitive-uri = ldsemeta:get-document-uri($file)
            return fn:true()
        let $publishable as xs:boolean := 
            if ( $sensitive/@status = "yes" and fn:exists($sensitive/@approval-date) ) then (
                fn:true()
            ) else if ( $sensitive/@status = "yes" and fn:empty($sensitive/@approval-date) ) then (
                fn:false()
            ) else if ( $sensitive-page and fn:not($sensitive/@status = "no") ) then (
                fn:false() 
            ) else ( fn:true() )
		let $can-publish as xs:string := fn:string(ldsemeta:correlation-can-publish($file) and $publishable)
		return $can-publish
	) else "true"
