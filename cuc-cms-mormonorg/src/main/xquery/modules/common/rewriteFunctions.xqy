xquery version "1.0-ml";

module namespace rf = "http://lds.org/code/cms/rewrite-functions";

import module namespace rewrite = "http://lds.org/code/shared/common/uri-rewrite-functions" at "/shared/common/uri/uriRewriteFunctions.xqy";
import module namespace language = "http://lds.org/code/shared/common/uri-language-functions" at "/shared/common/uri/uriLanguageFunctions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace util = "http://lds.org/code/lds-edit-services/utilFunctions" at "/modules/common/utilFunctions.xqy";
import module namespace ldsesUser = "http://lds.org/code/lds-edit-services/user" at "/modules/userManagement.xqy";
import module namespace valid = "http://lds.org/code/shared/lds-edit/isValidFunctions" at "/ice/modules/isValidFunctions.xqy";

declare option xdmp:mapping "false";

declare variable $requestPath as xs:string := xdmp:get-request-url();
declare variable $site as xs:string := fn:tokenize($requestPath, "/")[2];
declare variable $tokenized as xs:string? := fn:tokenize($requestPath, "/")[2];
declare variable $pathWithoutContext as xs:string := fn:substring-after($requestPath, $tokenized);
declare variable $extensions as xs:string* := util:getFileExtensions($site);
declare variable $isPassThrough as xs:boolean := rewrite:isPassThrough($requestPath, $extensions);
declare variable $serviceSite as xs:string := (fn:substring-before($tokenized,"?")[. != ''],$tokenized)[1];
declare variable $siteRoot as xs:string := fn:concat("/", $serviceSite);

declare function default-rewrite() as xs:string {
    let $serviceSite as xs:string := ( $serviceSite, "lds-edit-services" )[1]
    (: TODO - not used? :)
    let $extensions as xs:string* := util:getFileExtensions($serviceSite)

    return (
        (: let URLs with file extensions pass through :)
        if ( $pathWithoutContext = '' ) then (
            fn:concat('/default.xqy?', fn:substring-after($requestPath, '?'))
        ) else if ( $isPassThrough ) then (
            xdmp:add-response-header("Access-Control-Allow-Origin","*"),
            $pathWithoutContext
        ) else (
            rf:build-target-url()
        )
    )
};

declare function xray-bypass() as xs:string? {
    if (fn:matches($requestPath, "^/shared/xray")) then (
        let $_login := xdmp:login("admin")
        return fn:string-join(("/shared/xray/default.xqy", fn:tokenize($requestPath, "\?")[2]), '?')
    ) else ()
};

declare function build-target-url() as xs:string? {
    let $requestLang as xs:string := rewrite:getRequestLang()
    let $lang as xs:string? := language:getLang($requestLang, $siteRoot)
    let $logging as xs:string := "lds-edit-servicesRewrite"
    let $xml as element(params) :=
        element params {
            element logging {$logging},
            element site {$siteRoot},
            element removeSiteContext {fn:true()},
            element requestPath {$requestPath},
            element requestLang {$requestLang},
            element lang {$lang},
            element mustRedirect {fn:false()},
            element pathWithoutContext {$pathWithoutContext}
        }
    return ( rewrite:buildTargetUrl($xml) )
};

declare function bc-path-check() as xs:string? {
    if ( fn:starts-with($requestPath, fn:concat('/', $site, '/bc')) ) then (
        let $after as xs:string := fn:substring-after($requestPath, fn:concat('/', $site, '/bc'))
        let $fullUrl as xs:string := if ( fn:starts-with($after, '/content') ) then ( fn:concat('/bc', $after) ) else ( fn:concat('/bc/content', $after) )
        return (
            fn:concat("/redirect.xqy?url=",$fullUrl)
        )
    ) else ()
};

declare function pass-through-check() as xs:string? {
    if ( $isPassThrough ) then (
        xdmp:add-response-header("Access-Control-Allow-Origin","*"),
        $pathWithoutContext
    ) else ()
};

declare function upload-check() as xs:string? {
    if ( fn:matches($requestPath, "^/services/lds-edit/uploadZip[^/]?.*$","i") ) then (
        let $login as xs:boolean? := ldsesUser:login("lds-edit-services", fn:false())
        return "/uploadZip.xqy"
    ) else ()
};

declare function xray-no-user-check() as xs:string? {
    if ($ac:no-users-exist) then (
        if (fn:starts-with($pathWithoutContext, "/user-manager/")) then (
            rf:build-target-url()
        ) else (
            (: send to the user creation page when no user exists :)
            '/user-manager/default.xqy'
        )
    ) else ()
};
