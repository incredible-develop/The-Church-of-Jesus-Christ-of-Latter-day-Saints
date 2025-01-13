xquery version "1.0-ml";

import module namespace regis-functions = "http://lds.org/code/register/regis-functions" at "functions.xqy";
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at "../../../modules/document-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../modules/ldse-settings.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";

let $port := core:set-port(9397)
let $site-root := core:get-site-root()
let $search as element()*:= (
    cts:search(/registration, 
        core:get-filter-query()
    )
)
let $locale := "english"

return (
    for $site in $search
        let $site-name as xs:string := fn:normalize-space(fn:string($site/basic-data/site-name))
        let $server as xs:string := fn:normalize-space(fn:string($site/basic-data/server)) 
        let $id as xs:string := fn:normalize-space(fn:string($site/@id)) 
        let $port as xs:string := fn:normalize-space(fn:string($site/basic-data/port))
        let $site-shared-prefix as xs:string := fn:normalize-space(fn:string($site/basic-data/shared-prefix))
        let $translation as xs:string? := fn:normalize-space(fn:string($site/translation-checkbox))
        let $services as xs:string? := fn:normalize-space(fn:string($site/services-checkbox))
        let $db-path as xs:string := core:build-db-path("", $locale, $id, $site, <options></options>)
        let $new-xml as node() := (
            if (fn:exists($site/version)) then (
                mem:node-replace($site/version, regis-functions:get-site-version($server, $port, $services, $site-shared-prefix, $site-name))
            ) else (mem:node-insert-child($site, regis-functions:get-site-version($server, $port, $services, $site-shared-prefix, $site-name)))
        )
    return (
        core:save-file($db-path, $new-xml, $site)
    )
)