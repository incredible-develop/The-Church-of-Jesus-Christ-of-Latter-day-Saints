(:
Okta logic explained:
   To migrate our CMS from WAM to Okta, authentication will be handled by the CMS app.
   First of all, our ASE will need to remove the Irule on the F5 that routes our site traffic to WAM for authentication.

   When one of our CMS URL is requested, the okta:okta-login() function will be called.
   This function checks if the session field that stores the access token exists and valid. If so, then the app will go on to check the user's permissions and
   grant access accordingly. If the access token is not found or no longer valid, it will ask the user to login.

   Our CMS application uses the authorization code flow option.

   This code flow involves these steps:
    1. Calling an authorize endpoint to receive an authorization code
	2. Calling a token endpoint to exchange the authorization code for a token (an access_token and/or an id_token)

   For details, please refer to this documentation: https://ip.churchofjesuschrist.org/1929/document/creating-an-oidc-client-in-an-okta-dev-tenant#mcetoc_1ehapc34v1
:)

module namespace okta = 'http://lds.org/code/cms/modules/okta-library';

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace enc = "http://lds.org/code/shared/common/obfuscation/obfuscate-functions" at "/shared/common/obfuscation/obfuscateFunctions.xqy";
import module namespace hashing = "http://lds.org/code/shared/common/security/hashing-functions" at "/shared/common/security/hashingFunctions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";

declare namespace jsonb = "http://marklogic.com/xdmp/json/basic";
declare namespace http = "xdmp:http";

declare variable $okta-settings as element(okta)? := cts:search(/okta, ());
declare variable $okta-active as xs:boolean := if ($ac:isDevOpCMS) then
                                                    fn:false()
                                               else $okta-settings/@status eq 'active';
declare variable $client-info as xs:string := 'Basic '||xdmp:base64-encode($okta-settings/client_id/fn:string()||':'||$okta-settings/client_secret/fn:string());
declare variable $oauthClearCacheConfig as element(oauth-cache-flush-config)? := cts:search(/oauth-cache-flush-config, ());

declare function okta:okta-login() as item()* {
    let $access_token as xs:string? := xdmp:get-session-field('access_token')
    let $requested-url as xs:string? := xdmp:get-request-url()
    let $set := xdmp:set-session-field('requested-url', $requested-url)
    return
        if (($okta-settings/@status eq 'active') and
            not($ac:isDevOpCMS) and
            (not($access_token) or (okta:introspect-token-status(okta:token-api('access_token', $access_token, 'introspect-token')) ne fn:true()))) then
            okta:call-okta-login()
        else ()
};

declare function okta:call-okta-login() {
    let $state as xs:string? := hashing:string-to-hex(enc:genKey(16))
    let $set as item()? := xdmp:set-session-field("my_oauth_state", $state)
    let $call-okta as xs:string :=
        $okta-settings/issuer_url||$okta-settings/authorization_endpoint||
        '?response_type=code'||
        '&amp;redirect_uri='||xdmp:url-encode($util:host||$okta-settings/login-callback)||
        '&amp;client_id='||$okta-settings/client_id||
        '&amp;scope='||xdmp:url-encode($okta-settings/scope)||
        '&amp;state='||$state
    return xdmp:redirect-response($call-okta)
};

declare function okta:okta-token($code as xs:string) as item()* {
    let $oauthHeaderNode :=
        <headers xmlns="xdmp:http">
            <Content-Type>application/x-www-form-urlencoded</Content-Type>
            <Accept>application/json</Accept>
        </headers>

    let $payload as xs:string :=
        'scope='||xdmp:url-encode($okta-settings/scope)||
        '&amp;grant_type=authorization_code'||
        '&amp;code='||$code||
        '&amp;client_id='||$okta-settings/client_id||
        '&amp;client_secret='||$okta-settings/client_secret||
        '&amp;redirect_uri='||xdmp:url-encode($util:host||$okta:okta-settings/login-callback)

    let $options as element(http:options) :=
        <options xmlns="xdmp:http">
            {$oauthHeaderNode}
            <data>{$payload}</data>
            <verify-cert>false</verify-cert>
            <format xmlns="xdmp:document-get">text</format>
        </options>

    let $oauth-get-token as item()* :=
        (xdmp:http-post($okta-settings/issuer_url||$okta-settings/token-endpoint, $options))[2]

    let $oauth-result as item()* := json:transform-from-json($oauth-get-token)
    let $access_token as xs:string? := $oauth-result/jsonb:access__token/text()
    let $id_token as xs:string? := $oauth-result/jsonb:id__token/text()
    let $refresh_token as xs:string? := $oauth-result/jsonb:refresh__token/text()
    let $set as item()* :=
        (xdmp:set-session-field('access_token', $access_token),
         xdmp:set-session-field('id_token', $id_token),
         xdmp:set-session-field('refresh_token', $refresh_token) )
    return
        if ($access_token) then (
            $access_token,
            $id_token
        )
        else 'failed'
};

declare function okta:okta-user-info($access-token as xs:string, $request as xs:string) as item()*  {
    let $token as xs:string := replace($access-token, functx:escape-for-regex('.'), ';')
    let $access_tokens as xs:string* := fn:tokenize($token, ';')
    let $access_result :=
        for $t in $access_tokens
        return try {
            json:transform-from-json(xdmp:base64-decode($t))
        }
        catch ($e) {
            ()
        }
    return
        for $i in $access_result//*
        where contains(xdmp:path($i), 'jsonb:'||$request)
        return ($i)
};

declare function okta:oauthHeader() as element(http:headers) {
    <headers xmlns="xdmp:http">
        <Content-Type>application/x-www-form-urlencoded</Content-Type>
        <Accept>application/json</Accept>
        <Authorization>{$client-info}</Authorization>
    </headers>
};

declare function okta:token-api($type as xs:string, $token as xs:string, $action as xs:string) {
    let $payload as xs:string :=
        'token='||$token||
        '&amp;token_type_hint='||$type
    let $options as element(http:options) :=
        <options xmlns="xdmp:http">
            {okta:oauthHeader()}
            <data>{$payload}</data>
            <verify-cert>false</verify-cert>
            <format xmlns="xdmp:document-get">text</format>
        </options>

    return (xdmp:http-post($okta:okta-settings/issuer_url||$okta:okta-settings/*[name(.) eq $action]/text(), $options))

};

declare function okta:introspect-token-status($result) {
    try {
        json:transform-from-json(($result)[2])/jsonb:active/text() eq 'true'
    }
    catch ($e) {
        'no result'
    }
};

declare function okta:okta-logout() as item()* {
    (
        okta:token-api('access_token', xdmp:get-session-field('access_token'), 'revoke-token'),
        okta:token-api('id_token', xdmp:get-session-field('id_token'), 'revoke-token'),
        xdmp:redirect-response($okta:okta-settings/signout-url||$util:host)
    )
};

declare function okta:get-okta-access-token-for-cache-flushing() as item()* {
    let $oauthHeaderNode :=
        <headers xmlns="xdmp:http">
            <Content-Type>application/x-www-form-urlencoded</Content-Type>
            <Accept>application/json</Accept>
        </headers>

    let $payload as xs:string :=
        'scope=client_token'||
        '&amp;grant_type=client_credentials'||
        '&amp;client_id='||$okta-settings/client_id||
        '&amp;client_secret='||$okta-settings/client_secret

    let $options as element(http:options) :=
        <options xmlns="xdmp:http">
            {$oauthHeaderNode}
            <data>{$payload}</data>
            <verify-cert>false</verify-cert>
            <format xmlns="xdmp:document-get">text</format>
        </options>
    let $oauth-get-token as item()* :=
        (xdmp:http-post($oauthClearCacheConfig/okta-request-token-url, $options))[2]

    let $oauth-result as item()* := json:transform-from-json($oauth-get-token)
    let $access_token as xs:string? := $oauth-result/jsonb:access__token/text()
    return ($access_token, 'failed')[1]
};