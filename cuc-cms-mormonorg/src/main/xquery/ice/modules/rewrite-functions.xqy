xquery version "1.0-ml";

module namespace rw = "http://lds.org/code/shared/lds-edit/rewrite-functions";

import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace function = "http://lds.org/code/shared/lds-edit/function-apply" at "../../invoke/function-apply.xqy";
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at "../../modules/document-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";

declare variable $site as xs:string? := xdmp:get-request-field('site')[. != ''];
declare variable $locale as xs:string? := xdmp:get-request-field('lang')[. != ''];

declare function rw:remove-rewrite-rule(
    $old-uri as xs:string?,
    $new-uri as xs:string,
    $template as element(template)?
) {
    let $rewriteRules as element(rewriteRules)? := rw:get-rewrite-rules($locale, $site)
    let $old-rule as element(rule)? := $rewriteRules/rule[@path = $old-uri and @params = ( $template/rule/@params[. != ''], '0' )[1]]
    where fn:exists($old-rule)
    return (
        xdmp:node-delete($rewriteRules/rule[@path = $old-rule/@path and @params = $old-rule/@params])
    )
};

declare function rw:update-rewrite-rule(
    $action as xs:string,
    $uri as xs:string,
    $locale as xs:string,
    $file as element()?,
    $site as xs:string?
) as item()*  {
   try {
        let $delete-fn as xdmp:function := xdmp:function(xs:QName('rw:delete-rule'))
        let $save-fn as xdmp:function := xdmp:function(xs:QName('rw:add-rule'))
        let $rewriteRules as element(rewriteRules)? := rw:get-rewrite-rules($locale, $site)
        let $template as element()? := 
            cts:search(/template,
                cts:and-query((
                    cts:element-attribute-value-query(xs:QName('template'), xs:QName('id'), $file/ldse:ldse-meta/ldse:form-options/ldse:templateId, 'exact')
                )),
                'unfiltered'
            )
        let $rule as element(rule)? := ( $rewriteRules/rule[@path = $uri and @params = ( $template/rule/@params[. != ''], '0' )[1]] )[1]
        
        let $delete-modes as xs:string* := settings:get-action-delete-modes($action)
        let $save-modes as xs:string* := settings:get-action-save-modes($action)[. != $core:mode ]
    
        let $deletes as item()* := 
            for $mode as xs:string in $delete-modes
            let $result as item()* := function:apply($delete-fn, $mode, $uri, $locale, $rule, $site)
            return (
                <response><success>{$result[1]}</success><error>{$result[2]}</error></response>
            )
        let $saves as item()* := 
            for $mode as xs:string in $save-modes
            let $result as item()* := function:apply($save-fn, $mode, $uri, $locale, $rule, $site)
            return (
                <response><success>{$result[1]}</success><error>{$result[2]}</error></response>
            )
            
        return fn:true()
        
    } catch ($e) {
        fn:false(), "Rewrite Action Failed",
        xdmp:trace("ldse-action", $action),
        xdmp:trace("ldse-action", "Action: error preforming action on rewrite rule."),
        xdmp:trace("ldse-action", $e)
    }
};

declare function rw:delete-rule(
    $uri as xs:string,
    $locale as xs:string,
    $rule as element(rule)*,
    $site as xs:string?
) as item()* {
    let $rules as element(rewriteRules)? := rw:get-rewrite-rules($locale, $site)
    return (
        if ( fn:exists($rule) ) then (
            xdmp:node-delete($rules/rule[@path = $rule/@path and @params = $rule/@params])
        ) else (
            let $uri as xs:string := ( fn:substring-after($uri, $settings:shared-prefix)[. != ''], $uri )[1]
            let $rule as element(rule)* := $rules/rule[@path = $uri and @params = "0"]
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
        )
    )
};

declare function rw:add-rule(
    $uri as xs:string*,
    $locale as xs:string,
    $newRule as element(rule),
    $site as xs:string?
) as item()* {
    let $rewriteRules as element(rewriteRules)? := rw:get-rewrite-rules($locale, $site)
    let $topRule as element(rule)? := $rewriteRules/rule[1]
    let $existingRule as element(rule)? := $rewriteRules/rule[@path eq $uri and @params eq "0"]
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
                            <rewriteRules status="publish" locale="{$locale}" site="{ $site }">
                                {$newRule}
                            </rewriteRules>
                        let $db-path as xs:string := core:build-db-path("", $locale, "", $file, ())
                        let $db-path as xs:string := 
                            if ( fn:exists($site) ) then (
                                fn:replace($db-path, 'rewrite-rules', 'rewrite-rules-' || $site)
                            ) else ( $db-path )
                        
                        return core:save-file($db-path, $file, ())
                    )
                return (
                    fn:true()
                )
            ) else (
                fn:false(), "Error - couldn't get lock"
            )
        ) else (
            fn:true(), "No Rewrite Rule"
        )
    return (
        $save
    )
};

declare function rw:get-rewrite-rules(
    $locale as xs:string,
    $site as xs:string?
) as element(rewriteRules)? {
    cts:search(/rewriteRules,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('locale'), $locale, 'exact'),
            if ( fn:exists($site) ) then (
                cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('site'), $site, 'exact')
            ) else ()
        ))
    )
};