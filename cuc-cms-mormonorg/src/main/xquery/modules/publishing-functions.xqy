xquery version "1.0-ml";

module namespace pf = "http://lds.org/code/lds-edit/publishing-functions";

import module namespace ldsemeta =  "http://lds.org/code/shared/lds-edit/meta-functions" at  "ldse-meta.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "ldse-settings.xqy";

declare boundary-space preserve;

declare namespace its = "http://www.w3.org/2005/11/its";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";
declare option xdmp:update "true";

declare function is-publishable(
    $file as element(),
    $pageUri as xs:string
) as xs:boolean {
    let $sensitive as element(ldse:sensitive)? := ldsemeta:get-sensitive($file)
    let $sensitive-page as xs:boolean? := 
        for $sensitive-uri as element(ldse:sensitive-uri) in $settings:sensitive-uris/ldse:sensitive-uri
        where $sensitive-uri = $pageUri or $sensitive-uri = ldsemeta:get-document-uri($file)
        return fn:true()
    return (
        if ( $sensitive/@status = "yes" and fn:exists($sensitive/@approval-date) ) then (
            fn:true()
        ) else if ( $sensitive/@status = "yes" and fn:empty($sensitive/@approval-date) ) then (
            fn:false()
        ) else if ( $sensitive-page and fn:not($sensitive/@status = "no") ) then (
            fn:false() 
        ) else if ( $sensitive-page ) then (
            fn:false()
        ) else ( fn:true() )
    )
};