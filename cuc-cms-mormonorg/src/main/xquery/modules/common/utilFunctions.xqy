xquery version "1.0-ml"; 

module namespace util = "http://lds.org/code/lds-edit-services/utilFunctions";

import module namespace resource = "http://lds.org/code/shared/common/resource-functions" at "/shared/common/resourceFunctions.xqy";
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace soap = "http://lds.org/code/shared/common/member/soap-functions" at "/shared/common/member/soapFunctions.xqy";
import module namespace ldseUtil = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";

declare boundary-space preserve;

declare option xdmp:mapping "true";

declare variable $site as xs:string := ldseUtil:getSharedPrefix($context);
declare variable $context as xs:string := "/preview/";
declare variable $env as xs:string := ldseUtil:getEnv($context);
declare variable $site-param as xs:string? := xdmp:get-request-field('site');

(:~
    Retrieves the supported languages for the site

    @param $lang 
    
    @return languages as node 
:)
declare function getLanguages($lang as item()) as element()* {
    cts:search(/supportedLanguages,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('supportedLanguages'), xs:QName('application'), $site, 'exact'),
            cts:element-attribute-value-query(xs:QName('supportedLanguages'), xs:QName('site'), $site-param, 'exact')
        ))
    )/language
};


(:~
    Checks to see if omniture is active in the site properties file

    @return $active as boolean 
:)
declare function isOmnitureActive() as item()*{
    let $active as item()*:= xdmp:directory("/published/", "infinity")/siteProperties/omniture/active
    return xs:boolean($active)
};

(:~
    Retrieves the valid fileExtensions for the site

    @param $site 
    
    @return extensions as node 
:)
declare function getFileExtensions($site as xs:string) as element()*{
    xdmp:directory($context, "infinity")/fileExtensions[@application]/ext
};



declare function customSave($status as xs:string, $context as xs:string?, $path as xs:string?, $file as element(), $origFile as element()?)
as  item()* {
  (: take the xml and just insert a test node into it :)
  let $newXml as element() := mem:node-insert-child($file, <custom-save>custom-save test worked</custom-save>)
  return (fn:false(), $newXml)
};
            

declare function customDelete($status as xs:string, $context as xs:string?, $path as xs:string?, $file as element(), $origFile as element()?) 
as  item()*  {
(
      (: just perform a log statement and then return false() :)
)
};

(:~
    Post Clone Process Function
    @param $context - ("/preview/" or "/published/")
    @param $action - ("clone" or "move") but really can be anything
    @param $currentUri - uri of page cloned
    @param $newUri - the uri the page was cloned to
    @param $currentLocale - locale of the page cloned
    @param $newLocale - the locale the page was cloned to
    return item()*
~:)
declare function post-clone(
    $context as xs:string, 
    $action as xs:string, 
    $currentUri as xs:string, 
    $newUri as xs:string, 
    $currentLocale as xs:string, 
    $newLocale as xs:string
) as item()* {
    xdmp:log("Post Clone Process function executed"),
    xdmp:log($action)
};
