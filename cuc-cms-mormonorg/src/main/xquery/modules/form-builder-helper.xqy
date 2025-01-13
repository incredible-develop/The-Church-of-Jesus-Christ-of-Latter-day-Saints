xquery version "1.0-ml";

module namespace fbh = "http://lds.org/code/lds-edit/modules/form-builder-helper";

import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace json2 = "http://lds.org/code/shared/common/json/json-functions" at "/shared/common/json/jsonFunctions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace ff = "http://lds.org/code/lds-edit/modules/formFunctions" at "/modules/formFunctions.xqy";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";

declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace http = "xdmp:http";
declare namespace basic = "http://marklogic.com/xdmp/json/basic";
declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace error = "http://marklogic.com/xdmp/error";

declare variable $requestType as xs:string? := util:escape-chars(xdmp:get-request-field("requestType"))[. != ""];
declare variable $form-name as xs:string? := util:escape-chars(xdmp:get-request-field("form-name"))[. != ""];
declare variable $host as xs:string? := util:escape-chars(xdmp:get-request-header("host"))[. != ""];
declare variable $json-schema := xdmp:get-request-field("json-schema")[. != ""];
declare variable $root as xs:string := core:get-site-root();
declare variable $site-root := if ( fn:contains($root, 'published') ) then ( fn:replace($root, 'published', 'preview') ) else ( $root );
declare variable $db-path as xs:string := util:clean-db-uri(fn:concat($site-root, "/content/_configuration/ice/ice-forms/json-schema/"));
declare variable $form as element(ldse:formTemplate)? := fbh:get-form($form-name);
declare variable $createUrl as xs:string := fbh:build-url($form-name);

declare function fbh:build-url(
    $formName as xs:string
) as xs:string {

    let $dateTime as xs:dateTime := fn:current-dateTime()
    let $year as xs:string := xs:string(fn:year-from-dateTime($dateTime))
    let $month as xs:string := xs:string(fn:month-from-dateTime($dateTime))
    let $day as xs:string := xs:string(fn:day-from-dateTime($dateTime))
    let $hours as xs:string := xs:string(fn:hours-from-dateTime($dateTime))
    let $mins as xs:string := xs:string(fn:minutes-from-dateTime($dateTime))
    let $secs as xs:string := fn:substring-before(xs:string(fn:seconds-from-dateTime($dateTime)), ".")
    return
        fn:concat(xdmp:get-request-protocol(), "://", $host, "/", $core:site, "/form?lang=eng", fn:concat("&amp;option=form:", $formName), "&amp;uri=/", $formName, "_", $year, "_", $month, $day, "_", $hours, $mins, "_", $secs)
};

declare function fbh:create-result(
    $message as xs:string?
) as element(result) {
    fbh:create-result((), -1, (), (), (), (), $message, fn:false(), ())
};

declare function fbh:create-result(
    $form as element(ldse:formTemplate)*,
    $status as xs:int,
    $created as xs:string?,
    $schema-title as xs:string?,
    $location as xs:string?,
    $url as xs:string?,
    $message as xs:string?,
    $array as xs:boolean,
    $forms as element(forms)*
) as element(result) {
    <result>
        { if ( $array ) then ( attribute array { 'true' } ) else () }
            <request>{ $requestType }</request>,
            <status>{ $status }</status>,
            <message>{ $message }</message>,
            <created>{ $created }</created>,
            <schema-title>{ $schema-title }</schema-title>
            <location>{ $location }</location>
            <create-url>{ $url }</create-url>
            {
                if ( fn:exists($form) ) then (
                    <form>{ xdmp:quote($form, <options xmlns="xdmp:quote"><indent>yes</indent><indent-untyped>yes</indent-untyped></options>) }</form>
                ) else (),
                $forms
            }
    </result>
};

declare function fbh:get-form-information(
    $created as xs:string?,
    $schema-title as xs:string?,
    $location as xs:string?,
    $url as xs:string
) as element()* {
    <created>{ $created }</created>,
    <schema-title>{ $schema-title }</schema-title>,
    <location>{ $location }</location>,
    <create-url>{ $url }</create-url>
};

declare function fbh:serialize-result(
    $result as element(result)
) as item()* {
    json2:serializeSet($result)
};

declare function fbh:get-form(
    $form-name as xs:string?
) as element(ldse:formTemplate)? {
    cts:search(/ldse:formTemplate,
        cts:and-query((
            cts:directory-query($db-path, 'infinity'),
            cts:element-attribute-value-query(xs:QName('ldse:formTemplate'), xs:QName('name'), $form-name, 'exact')
        )),
        "unfiltered"
    )
};

declare function fbh:get-forms(
    $form-name as xs:string?
) as element(ldse:formTemplate)* {
    cts:search(/ldse:formTemplate,
        cts:and-query((
            cts:directory-query($db-path, 'infinity')
        )),
        "unfiltered"
    )
};

declare function fbh:perform-function() {
    if ( fbh:get-contributor()/ldse:roles/ldse:role/@name != ( "admin", "super" ) ) then (
        if ( fn:exists($requestType) ) then (
            util:login($settings:rwuser, (), fn:false()),

            switch ( $requestType )
            case "create-form" return ( fbh:create-form() )
            case "get-form" return (
                if ( fn:exists($form) ) then (
                    fbh:get-form-item()
                ) else ( fbh:serialize-result(fbh:create-result(fn:concat("cannot find form: ", $form-name)) ) )
            )
            case "get-form-dev-db" return (
                if ( fn:exists($form) ) then (
                    fbh:get-form-dev-db()
                ) else ( fbh:serialize-result(fbh:create-result(fn:concat("cannot find form: ", $form-name))) )
            )
            case "get-form-dev" return ( fbh:get-form-dev() )
            case "get-forms" return ( fbh:get-form-items() )
            case "delete-form" return (
                if ( fn:exists($form) ) then (
                    fbh:delete-form()
                ) else ( fbh:serialize-result(fbh:create-result(fn:concat("cannot find form with name: ", $form-name))) )
            )
            default return (
                fbh:serialize-result(fbh:create-result(fn:concat("unhandled requestType: ", $requestType)))
            )
        ) else ( xdmp:set-response-code(500, "requestType missing") )
    ) else ( xdmp:set-response-code(500, "You don't have permissions") )
};

(: creates form in DB :)
declare function fbh:create-form() as item()* {
    fbh:create-form($json-schema)
};

declare function fbh:create-form($json) as item()* {
    try {
        let $xml as node() := json:transform-from-json($json)
        let $result := ff:createLdsPubForm($xml, $db-path)
        let $createUrl as xs:string := fbh:build-url($result//ldse:formName)
        let $message as xs:string := fn:concat("created form: ", $result//ldse:formName)
        let $result as element(result) := fbh:create-result((), 0, $result//ldse:created, $result//ldse:schema-title, $result//ldse:location, $createUrl, $message, fn:false(), ())
        return (
            fbh:serialize-result($result)
        )
    } catch ($err) {
        let $message as xs:string := fn:concat("form creation failed: ", $err/error:code, ", ", $err/error:message)
        return (
            fbh:serialize-result(fbh:create-result($message))
        )
    }
};

(: gets meta-data for existing form :)
declare function fbh:get-form-item() {
    let $location as xs:string := xdmp:node-uri($form)
    let $result as element(result) := fbh:create-result($form, 0, $form/@created, $form/@schema-title, $location, $createUrl, fn:concat("form name: ", $form-name), fn:false(), ())
    return (
        fbh:serialize-result($result)
    )
};

(: returns raw form from DB :)
declare function fbh:get-form-dev-db() {
    let $result as element(result) := fbh:create-result($form, 0, $form/@created, $form/@schema-title, xdmp:node-uri($form), $createUrl, "Here is your form", fn:false(), ())
    return (
        fbh:serialize-result($result)
    )
};

(: generates form from passed schema and returns it, doesn't save in DB :)
declare function fbh:get-form-dev() {
    try {
        let $xml as node() := json:transform-from-json($json-schema)
        let $form := ff:getLdsPubForm($xml,"ldswebml")
        let $result as element(result) := fbh:create-result($form, 0, (), (), "Not in database", (), "Here is your form", fn:false(), ())
        return (
            fbh:serialize-result($result)
        )
    } catch ($err) {
        let $message as xs:string := fn:concat("get form failed: ", $err/error:code, ", ", $err/error:message)
        return (
            fbh:serialize-result(fbh:create-result($message))
        )
    }
};

(: returns meta-data for all forms :)
declare function fbh:get-form-items() {
    let $forms as element(ldse:formTemplate)* := fbh:get-forms(())
    let $form-nodes as element(forms)* :=
        for $form as element(ldse:formTemplate) in $forms
        let $createUrl as xs:string := fbh:build-url($form/@name)
        return (
            <forms>
                { fbh:get-form-information($form/@created, $form/@schema-title, xdmp:node-uri($form), $createUrl) }
                <name>{$form/@name/fn:string(.)}</name>
            </forms>
        )
    let $result as element(result) := fbh:create-result((), 0, (), () ,(), (), 'list of forms', fn:true(), $form-nodes)

    return (
        fbh:serialize-result($result)
    )
};

(: deletes an existing form by name :)
declare function fbh:delete-form() {
    let $nop as item()* := xdmp:document-delete(xdmp:node-uri($form))
    let $result as element(result) := fbh:create-result($form, 0, (), (), xdmp:node-uri($form), (), fn:concat("deleted form with name: ", $form-name), fn:false(), ())
    return (
        fbh:serialize-result($result)
    )
};

declare function fbh:get-contributor() {
    cts:search(/ldse:contributor,
        cts:and-query((
            core:get-filter-query(),
            cts:element-value-query(xs:QName('ldse:name'), ac:getUserName(), "case-insensitive")
        ))
    )[1]
};
