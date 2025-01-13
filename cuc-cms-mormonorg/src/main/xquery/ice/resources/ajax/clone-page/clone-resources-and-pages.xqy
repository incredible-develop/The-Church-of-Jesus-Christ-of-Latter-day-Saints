xquery version "1.0-ml";

import module namespace json = "http://lds.org/code/shared/common/json/json-functions" at "/shared/common/json/jsonFunctions.xqy";
import module namespace sman = "http://lds.org/code/shared/lds-edit/riceFunctions" at "/string-manager/modules/stringFunctions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "/modules/ldse-meta.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at "/modules/document-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace af = "http://lds.org/code/lds-edit/content-admin/admin-functions" at "/content-admin/modules/functions.xqy";
import module namespace cloneSite = "http://lds.org/code/shared/lds-edit/cloneSite" at "/ice/resources/ajax/clone-site/cloneSite.xqy";
declare boundary-space preserve;
declare option xdmp:mapping "true";
declare option xdmp:update "true";
declare variable $resourcesPages as xs:string* := xdmp:get-request-field("resourcesPages[]");
declare variable  $fromSite as xs:string := xdmp:get-request-field("fromSite");
declare variable  $fromLang as xs:string := xdmp:get-request-field("fromLang");
declare variable  $contentTypes as xs:string* := xdmp:get-request-field("contentTypes[]");
declare variable  $cloneToSite := xdmp:get-request-field("cloneToSite");

if (string-length($cloneToSite)) then
    let $content :=
        for $resourcePage at $idx in $resourcesPages
        let $contentType := fn:subsequence($contentTypes, $idx, 1)
        return element content {attribute type {$contentType},
        attribute name {$resourcePage}}

    let $resources := $content[@type eq 'resources']/@name/fn:string()
    let $uris := $content[@type eq 'custom-page']/@name/fn:string()
    let $clone :=
        for $toSiteLang in $cloneToSite
        let $toSite := fn:substring-before($toSiteLang, '|')
        let $toLang := fn:substring-after($toSiteLang, '|')
        return cloneSite:cloneSite($fromSite, $fromLang, $toSite, $toLang, $resources, $uris)

    return fn:concat('{"response":"', 'true', '"}')

else
  fn:concat('{"response":"', 'Missing destination site', '"}')


