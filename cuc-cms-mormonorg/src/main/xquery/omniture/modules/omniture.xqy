xquery version "1.0-ml";

module namespace omni = "http://lds.org/code/lds-edit/omniture";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";

(:declare namespace SOAP-ENV = "soapenv";:)
declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace ldso = "http://lds.org/code/lds-edit/omniture";
declare namespace xdmpNS = "xdmp:http";

declare option xdmp:mapping "true";

declare variable $ldso as xs:string := "http://lds.org/code/lds-edit/omniture";

declare variable $omniture-url as xs:string := $settings:omniture-service-url;

declare function omni:get-data($page-name as xs:string) as item()?{
    let $url as xs:string := fn:concat($omniture-url, "?pageName=", fn:encode-for-uri($page-name))
    let $response as item()* := util:http-post($url,
        <options xmlns="xdmp:http">
            <headers xmlns="xdmp:http">
                <content-type>application/json</content-type>               
            </headers>
            <format xmlns="xdmp:document-get">text</format>
        </options>)
    let $trace as item()* := xdmp:trace('ldse-omniture', $url)    
    let $trace as item()* := xdmp:trace('ldse-omniture', $response)
    return (
        ($response[2], '{}')[1]
    )
};

declare function sanitizePageName($name as xs:string) as xs:string{
    let $name as xs:string := fn:replace($name,"'"," ")
    let $name as xs:string := fn:replace($name,'"'," ")
    let $name as xs:string := fn:replace($name,":","|")
    let $name as xs:string := fn:replace($name,'"',"-")
    let $name as xs:string := fn:replace($name,'\\'," ")
    let $name as xs:string := fn:replace($name,'/'," ")
    let $name as xs:string := fn:replace($name,';'," ")
    let $name as xs:string := fn:replace($name,'\['," ")
    let $name as xs:string := fn:replace($name,'\]'," ")
    let $name as xs:string := fn:replace($name,'\(',"|")
    let $name as xs:string := fn:replace($name,'\)',"|")
    let $name as xs:string := fn:replace($name,'%'," ")
    let $name as xs:string := fn:replace($name,'\+'," ")
    let $name as xs:string := fn:replace($name,'&amp;',"AND ")
    return $name
};

