xquery version "1.0-ml";

import module namespace cc = "http://lds.org/code/shared/lds-edit/clear-cache-functions" at "../../clear-cache/modules/clear-cache-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";
import module namespace ldseUtil = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare variable $uri as xs:string := ldseUtil:escape-chars(xdmp:get-request-field('uri', ''));
declare variable $form as xs:string := ldseUtil:escape-chars(xdmp:get-request-field('form', ''));
declare variable $docId as xs:string := ldseUtil:escape-chars(xdmp:get-request-field('id', ''));
declare variable $locale as xs:string := ldseUtil:escape-chars(xdmp:get-request-field('lang', ''));
declare variable $site as xs:string := $core:site;

declare variable $services as element(ldse:cache-clearing)? := cc:getCacheConfig();
declare variable $service as xs:string* := $services/ldse:clear-service/@value;

let $uris as element(uris) :=
    element uris {
        let $uri := (
            'http://' || $settings:ldse-settings/ldse:live-domain || cc:getRedirectPath($uri, $form, $docId),
            'https://' || $settings:ldse-settings/ldse:live-domain || cc:getRedirectPath($uri, $form, $docId)
        )
        return
            for $u in $uri
            return
                element uri {$u}
    }
return (
    cc:clearCache($uris, $site, $locale, $service)
)