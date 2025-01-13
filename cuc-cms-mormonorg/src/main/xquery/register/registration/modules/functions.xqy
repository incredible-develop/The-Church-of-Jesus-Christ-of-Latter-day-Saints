xquery version "1.0-ml";

module namespace regis-functions = "http://lds.org/code/register/regis-functions";

import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../../../ice/modules/dynamicForms.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../modules/ldse-core.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../../modules/ldse-meta.xqy";
import module namespace spawn = "http://lds.org/code/shared/lds-edit/function-apply" at "../../../invoke/function-apply.xqy";
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at "../../../modules/document-functions.xqy";

declare namespace search = "http://marklogic.com/appservices/search";
declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace http = "xdmp:http";
 
declare option xdmp:mapping "true";

declare function regis-functions:get-site-version(
    $server as xs:string,
    $port as xs:string,
    $services as xs:string?,
    $site-shared-prefix as xs:string,
    $site-name as xs:string
) {
    ()
};

declare function regis-functions:email-registration(
    $site-name as xs:string,
    $contact-name as xs:string,
    $contact-email as xs:string,
    $contact-name-2 as xs:string,
    $contact-email-2 as xs:string
) as xs:boolean {
    let $ldse-settings as element(ldse:ldse-settings)? := $settings:ldse-settings
    let $registrationInfo as element(ldse:send-email)? := $ldse-settings/ldse:registration/ldse:send-email
    let $recipients as element(emails)* := (
        element emails {
            element email {$contact-email},
            element email {$contact-email-2},
            for $emails in $registrationInfo/ldse:recipient/ldse:email 
                return element email {$emails}
        }
    )
    let $senderName as xs:string? := $registrationInfo/ldse:sender/ldse:name
    let $senderEmail as xs:string? := $registrationInfo/ldse:sender/ldse:email
    let $subject as xs:string := fn:concat("LDS-Publisher Site Registration")
    let $message as xs:string := fn:concat("This message is to let you know that: ", $site-name, " site was registered to use LDS Publisher by: ", $contact-name, " ", $contact-email, " in ", fn:string($ldse-settings/@environment))
    let $sendEmail as item()* := 
        for $recipient in $recipients
        return (
            util:send-email($recipient/email, "", $subject, $message, $senderEmail, $senderName)
        )
    return (
        fn:empty($sendEmail)
    )
};

declare function regis-functions:save(
    $isEditor as xs:boolean, 
    $status as xs:string, 
    $form as element()?, 
    $file as element(registration)?, 
    $action as xs:string, 
    $locale as xs:string,
    $messages as xs:string?
) as empty-sequence() {
    let $id as xs:string :=
        if ($action eq 'add' or fn:empty($file)) then (
            form:newId($locale)
        ) else (form:getVariable('id'))
    let $new-xml as element() := form:buildNewXml($status, $file, $form, $id) 
    let $server as xs:string? := $new-xml/basic-data/server
    let $port as xs:string? := $new-xml/basic-data/port
    let $services as xs:string? := $new-xml/services-checkbox
    let $site-shared-prefix as xs:string? := $new-xml/basic-data/site-shared-prefix
    let $site-name as xs:string := $new-xml/basic-data/site
    let $db-path as xs:string? :=
        if (fn:exists($file)) then (
            xdmp:node-uri($file)
        ) else ()
    let $db-path as xs:string := 
        if (fn:empty($db-path) or $db-path = "") then (
            core:build-db-path(ldsemeta:get-document-uri($new-xml), ldsemeta:get-document-locale($new-xml), ldsemeta:get-document-id($new-xml), $new-xml, ())
        ) else ( $db-path ) 
    let $save as item()* := 
        if ( fn:exists($file) ) then (
            document:document-replace($file, $new-xml)
        ) else (
            document:document-insert($db-path, $new-xml)
        )
    return ()
};
declare function regis-functions:site-list($id as xs:string) as xs:string {
    fn:concat($settings:shared-prefix, "/register/registration?lang=eng&amp;id=", $id)
};

declare function regis-functions:redirect($messages) as empty-sequence() {
    xdmp:redirect-response(fn:concat($settings:shared-prefix, "/register?messages=", $messages))
};

declare function regis-functions:redirect-to-services($site-name) as empty-sequence() {
    xdmp:redirect-response(fn:concat("https://preview-test.lds.org/services/lds-edit/setup/admin#detail=", $site-name))
};

declare function regis-functions:translation-post(
    $site-name as xs:string,
    $preview-production-url as xs:string,
    $shared-prefix as xs:string?,
    $post-zip as xs:string,
    $pri-contact-name as xs:string,
    $pri-contact-email as xs:string,
    $sec-contact-name as xs:string,
    $sec-contact-email as xs:string
) {
    let $node as xs:string :=
        fn:concat('site-name=', xdmp:url-encode($site-name), '&amp;host=', xdmp:url-encode($preview-production-url), '&amp;site-prefix=', xdmp:url-encode($shared-prefix)
                , '&amp;post-url=http://content-preview-orig.ldschurch.org', xdmp:url-encode($post-zip), '&amp;pContact=', xdmp:url-encode($pri-contact-name)
                , '&amp;pEmail=', xdmp:url-encode($pri-contact-email), '&amp;sContact=', xdmp:url-encode($sec-contact-name), '&amp;sEmail=', xdmp:url-encode($sec-contact-email))
    let $environment := $settings:environment
    let $hosts as element(host)* := $core:siteProperties/translation/host
    return (
        for $host as element(host) in $hosts
        return (
            util:http-post(
                fn:concat("http://", $host ,"/register?lang=eng&amp;", $node),
                <options xmlns="xdmp:http">
                    <headers>
                        <content-type>text/xml</content-type>
                    </headers>
                </options>
            )
        )
    )
};
