xquery version "1.0-ml";

import module namespace json = "http://lds.org/code/shared/common/json/json-functions" at "/shared/common/json/jsonFunctions.xqy";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../../modules/utility-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../../../modules/ldse-meta.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../../modules/access-control-functions.xqy";
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at "../../../../modules/document-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../../modules/ldse-settings.xqy";
import module namespace function = "http://lds.org/code/shared/lds-edit/function-apply" at "../../../../invoke/function-apply.xqy";

declare boundary-space preserve;
declare option xdmp:mapping "true";
declare option xdmp:update "true";

declare function local:delete-rule($page as xs:string*, $locale as xs:string) as item()* {
    let $rule as element(rule)* := 
        cts:search(/rewriteRules,
            cts:and-query((
                core:get-filter-query(),
                if ( fn:exists($site) ) then (
                    cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('site'), $site, 'exact')
                ) else (),
                cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('locale'), $locale, 'exact')
            ))
        )/rule[@path eq $page and @params eq "0"]
    let $lock as xs:boolean? := document:lock($rule[1], fn:concat("Removing rewrite rules"))
    let $delete as item()* := 
        if ( fn:exists($rule) ) then (
            if ($lock) then (
                xdmp:node-delete($rule),
                fn:true()
            ) else (
                (fn:false(), "Error - couldn't get lock")
            )
        ) else (
            (fn:true(), "No Rewrite Rule")
        )
    return (
        $delete
    )
};

declare function local:add-rule($page as xs:string*, $locale as xs:string, $newRule as element(rule)) as item()* {
    let $rewriteRules as element(rewriteRules)? := 
        cts:search(/rewriteRules,
            cts:and-query((
                core:get-filter-query(),
                if ( fn:exists($site) ) then (
                    cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('site'), $site, 'exact')
                ) else (),
                cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('locale'), $locale, 'exact')
            ))
        )
    let $topRule as element(rule)? := $rewriteRules/rule[1]
    let $existingRule as element(rule)? := $rewriteRules/rule[@path eq $page and @params eq "0"]
    let $lock as xs:boolean? := document:lock($rewriteRules, fn:concat("Adding rewrite rules"))
    let $save as item()* := 
        if ( fn:exists($newRule) ) then (
            if ($lock or fn:empty($rewriteRules)) then (
                let $add as item()* := 
                    if ( fn:exists($existingRule) ) then (
                        xdmp:node-replace($existingRule, $newRule)
                    ) else if ( fn:exists($topRule) ) then (
                        xdmp:node-insert-before($topRule, $newRule)
                    ) else (
                        let $file as element(rewriteRules) := 
                            <rewriteRules status="publish" locale="{$locale}">
                                { if ( fn:exists($site) ) then ( attribute site { $site } ) else () }
                                {$newRule}
                            </rewriteRules>
                        let $db-path as xs:string := core:build-db-path("", $locale, "", $file, ()) 
                        return ( core:save-file($db-path, $file, ()) )
                    )
                return (
                    fn:true()
                )
            ) else (
                (fn:false(), "Error - couldn't get lock")
            )
        ) else (
            (fn:true(), "No Rewrite Rule")
        )
    return (
        $save
    )
};

(: pass variables :)
    declare variable $action as xs:string := xdmp:get-request-field("action", "");
    declare variable $uri as xs:string := xdmp:get-request-field("uri", "");
    declare variable $locale as xs:string := xdmp:get-request-field("locale", "");
    declare variable $site as xs:string? := xdmp:get-request-field("site");
(: item object :)
    declare variable $name as xs:string := xdmp:get-request-field("name", "");
    declare variable $folder as xs:string := xdmp:get-request-field("folder", "");
    declare variable $html-id as xs:string := xdmp:get-request-field("id", ""); (: html id not a file id :)
    declare variable $ids as xs:string+ := xdmp:get-request-field("ids[]", "");

declare variable $page as xs:string* := 
    if ($settings:shared-prefix != '') then (
        fn:substring-after($uri, $settings:shared-prefix), $uri
    ) else ( $uri );

declare variable $has-permission as xs:boolean :=  ac:is-action-allowed($action, $locale, $uri);

declare variable $delete-modes as xs:string* := settings:get-action-delete-modes($action);
declare variable $save-modes as xs:string* := settings:get-action-save-modes($action)[. != $core:mode ];
declare variable $delete-fn as xdmp:function := xdmp:function(xs:QName('local:delete-rule'));
declare variable $save-fn as xdmp:function := xdmp:function(xs:QName('local:add-rule'));

declare variable $rewriteRules as element(rewriteRules)? := 
        cts:search(/rewriteRules,
            cts:and-query((
                core:get-filter-query(),
                if ( fn:exists($site) ) then (
                    cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('site'), $site, 'exact')
                ) else (),
                cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('locale'), $locale, 'exact')
            ))
        );
declare variable $rule as element(rule)? := ($rewriteRules/rule[@path eq $page and @params eq "0"])[1];

xdmp:set-response-content-type("application/json"),
if ($has-permission) then (
        let $response as item()* :=
            if ( fn:exists($rule) ) then (
                (: Attempt to get lock on file :)
                let $lock as xs:boolean := 
                    if (settings:action-should-lock($action)) then (
                        document:lock($rewriteRules, fn:concat("Preforming Action On File"))
                    ) else ( fn:true() )
                (: Publish the file :)
                return 
                    if ($lock) then (
                        try {
                            let $deletes as item()* := 
                                for $mode as xs:string in $delete-modes
                                let $result as item()* := function:apply($delete-fn, $mode, $page, $locale)
                                return (
                                    <response><success>{$result[1]}</success><error>{$result[2]}</error></response>
                                )
                             let $saves as item()* := 
                                for $mode as xs:string in $save-modes
                                let $result as item()* := function:apply($save-fn, $mode, $page, $locale, $rule)
                                return (
                                    <response><success>{$result[1]}</success><error>{$result[2]}</error></response>
                                )   
                            return (
                                if ( ($deletes, $saves)/success = "false") then (
                                    xdmp:set-response-code(409, "Action Failed"),
                                    xdmp:rollback()
                                ) else (
                                    fn:true(), ""
                                )
                            ) 
                        } catch ($e) {
                            fn:false(), "Action Failed",
                            xdmp:trace("ldse-action", $action),
                            xdmp:trace("ldse-action", "Action: error preforming action on files."),
                            xdmp:trace("ldse-action", $e)
                        }
                    ) else (
                        (fn:false(), "Error - couldn't get lock")
                    )
            ) else (
                (fn:true(), "")
            )
        let $xml as element(response) := 
            <response>
                <action>{$action}</action>
                <uri>{$uri}</uri>
                <locale>{$locale}</locale>
                <success>{$response[1]}</success>
                <error>{$response[2]}</error>
                <count>{fn:count($rule)}</count>
                <name>{$name}</name>
                <folder>{$folder}</folder>
                <id>{$html-id}</id>
                <ids>{fn:string-join($ids, ',')}</ids>
            </response>
        return json:serialize($xml)
) else ( 
    let $errorMsg as xs:string:="Sorry, an error occured." 
    let $errorTitle as xs:string:= "Error!" 
    return xdmp:redirect-response( fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle) )
)
    
