xquery version "1.0-ml";

module namespace eval = "http://lds.org/code/shared/lds-edit/modules/eval";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../modules/utility-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../modules/ldse-settings.xqy";

declare option xdmp:mapping "true";

declare function eval:eval($xquery as xs:string, $vars as item()*) as item()* {
    xdmp:eval($xquery, $vars)
};

declare function eval:email-eval($xquery as xs:string, $vars as item()*, $emails as xs:string*, $script-name as xs:string) as item()* {
    let $eval as item() := 
        <html xmlns="http://www.w3.org/1999/xhtml"> 
            <head>
                <title>{$script-name}</title>
            </head>
            <body>
                <p>Run on: {$settings:display-name}</p>
                <div>{xdmp:eval($xquery, $vars)}</div>
            </body>
        </html>
    for $email as xs:string in $emails
    return (
        util:send-email($email, "", fn:concat("Results from ", $script-name, " script"), $eval, "no-reply@ldschurch.org", "LDS Publisher")
    )
};
