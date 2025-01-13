xquery version "1.0-ml";

module namespace action = "http://lds.org/code/shared/lds-edit/action-functions";

import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../modules/ldse-meta.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at "../../modules/document-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";
import module namespace correlation = "http://lds.org/code/shared/lds-edit/correlation" at "../../correlation/modules/correlation-functions.xqy";
import module namespace func = "http://lds.org/code/shared/lds-edit/function-apply" at "../../invoke/function-apply.xqy";
import module namespace rw = "http://lds.org/code/shared/lds-edit/rewrite-functions" at "rewrite-functions.xqy";
import module namespace fj = "http://marklogic.com/json" at "../../modules/fasterjson.xqy";
import module namespace pf = "http://lds.org/code/lds-edit/publishing-functions" at "../../modules/publishing-functions.xqy";
import module namespace df = "http://lds.org/code/shared/lds-edit/dynamicForms" at "dynamicForms.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace form = "http://lds.org/code/shared/lds-edit/form-save" at 'form-save.xqy';
import module namespace af = "http://lds.org/code/lds-edit/content-admin/admin-functions" at "../../content-admin/modules/functions.xqy";

(:declare namespace handle-correlation = "http://lds.org/code/shared/lds-edit/handle-correlation";:)
declare namespace ldse = "http://lds.org/code/lds-edit";
(:declare namespace cldse = "http://lds.org/code/lds-edit/correlation";:)

declare boundary-space preserve;
declare option xdmp:mapping "true";
declare option xdmp:update "true";

declare variable $comp-map as map:map := map:map();
declare variable $id-map as map:map := map:map();

declare variable $collection as xs:string := xdmp:get-request-field("collection", "");
declare variable $options as element()? := if ( fn:exists($collection) ) then ( <options><collection>{$collection}</collection></options> ) else ();

declare function action:perform-action(
    $action as xs:string,
    $uri as xs:string,
    $locale as xs:string,
    $name as xs:string,
    $folder as xs:string,
    $html-id as xs:string?,
    $ids as xs:string+
) as item()* {
    action:perform-action($action, $uri, $locale, $name, $folder, $html-id, $ids, fn:false(), ())
};

declare function action:perform-action(
    $action as xs:string,
    $uri as xs:string,
    $locale as xs:string,
    $name as xs:string,
    $folder as xs:string,
    $html-id as xs:string?,
    $ids as xs:string+,
    $get-children as xs:boolean,
    $site as xs:string?
) as item()* {
    action:perform-action($action, $uri, $locale, $name, $folder, $html-id, $ids, $get-children, $site, ())
};

declare function action:perform-action(
    $action as xs:string,
    $uri as xs:string,
    $locale as xs:string,
    $name as xs:string,
    $folder as xs:string,
    $html-id as xs:string?,
    $ids as xs:string+,
    $get-children as xs:boolean,
    $site as xs:string?,
    $index as xs:string?
) as item()* {
    let $count := fn:count($ids)
    let $isNestedComponent := xdmp:get-request-field("isNestedComponent", "false")
    let $ids := if($isNestedComponent eq "true") then (
                    let $nestedParentId := xdmp:get-request-field("nestedParentId")
                    return
                        if($nestedParentId) then
                            $nestedParentId
                        else
                            $ids
                ) else ( $ids )
    let $files as element()* :=
        for $file-id as xs:string in $ids
        return ldsemeta:get-file-by($file-id, $locale, (), (), $site)
    let $children := if ($action eq 'ldse:delete' and $count eq 1 ) then
                          let $element-name := xs:string(fn:node-name($files))
                          return if ($element-name eq 'custom-page') then
                                      for $id in fn:distinct-values(af:findAllFilesUsedByPageSettings($ids, $locale))
                                      let $comp-file as element()* := ldsemeta:get-file-by-id($id)
                                      where ($id ne $ids) and ($comp-file/ldse:ldse-meta/ldse:document/@uri/fn:string() eq $uri)
                                      return $id
                                 else af:getChildrenComponents ($ids, $locale)
                     else ()
    let $response as item()* :=
        if ( fn:exists($files) ) then (
            (: Attempt to get lock on file :)
            let $lock as xs:boolean :=
                if (settings:action-should-lock($action)) then (
                    every $file in $files satisfies document:lock($file, fn:concat("Preforming Action On File"))
                ) else ( fn:true() )
            (: Publish the file :)
            return (
                if ( $lock ) then (
                    (:)  try {  :)
                        let $custom :=
                            if ( fn:not($action = 'ldse:remove-from-page') and fn:not($action = 'ldse:disable-from-page') ) then (
                                for $file as element() in $files
                                let $formName as xs:string := ldsemeta:get-form-options($file)/form
                                let $form-template as element(ldse:formTemplate) := df:get-form($formName)
                                let $update as xs:boolean := action:update-content($file, $form-template)
                                let $post-process as item()* := action:perform-post-process($file, $form-template)
                                let $delete-children as item()* := if ($action eq 'ldse:delete' and $count eq 1 ) then (
                                                                       for $target-mode in ('preview','published')                                                                       (: let $file := ldsemeta:get-file-by-id($id)/fn:base-uri() :)                                                                                                                                              
                                                                       return func:apply(xdmp:function(xs:QName("action:deleteChildren")), $target-mode, $children, $uri, $target-mode) 
                                                                    ) else ()                                
                                return (
                                    if ( fn:not($update) ) then (
                                        action:update($file, $ids, $locale, $uri, $action, $get-children, $site)
                                    ) else ()
                                )
                            ) else (
                                if( $index ) then (
                                    action:update($files, $ids, $locale, $uri, $action, $get-children, $site, $index)
                                ) else ()
                            )
                        return ( fn:true(), "" )
                        (:)  } catch ($e) {
                        fn:false(), "Action Failed",
                        xdmp:trace("ldse-action", $action),
                        xdmp:trace("ldse-action", "Action: error preforming action on files."),
                        xdmp:trace("ldse-action", $e)
                    } :)
                ) else (
                    fn:false(), "Error - couldn't get lock"
                )
            )
        ) else (
            fn:true(), ""
        )
    let $xml as element(response) :=
        <response>
            <action>{$action}</action>
            <uri>{$uri}</uri>
            <locale>{$locale}</locale>
            <success>{$response[1]}</success>
            <error>{$response[2]}</error>
            <count>{fn:count($files) + fn:count($children)}</count>
            <name>{$name}</name>
            <folder>{$folder}</folder>
            <id>{$html-id}</id>
            <ids>{fn:string-join(($ids, $children), ',')}</ids>
        </response>
    return fj:xml-json($xml)
};


declare function action:update(
    $files as element()*,
    $ids as xs:string+,
    $locale as xs:string,
    $uri as xs:string,
    $action as xs:string,
    $get-children as xs:boolean,
    $site as xs:string?
) {
    action:update($files, $ids, $locale, $uri, $action, $get-children,  $site, ())
};


declare function action:update(
    $files as element()*,
    $ids as xs:string+,
    $locale as xs:string,
    $uri as xs:string,
    $action as xs:string,
    $get-children as xs:boolean,
    $site as xs:string?,
    $index as xs:string?
) {
    let $perform as element()* := action:update-items($files, $ids, $locale, $uri, $action, $get-children, $site, $index)
    let $publish-comps as element()* := if ( $action = "publish" ) then ( action:publish-components($action, $locale, $uri) ) else ()
    return action:update-content-items($action, $id-map, $locale, $uri, $ids, $get-children, $site)
};

declare function action:update-content(
    $file as element(),
    $form-template as element(ldse:formTemplate)
) as xs:boolean {
    if ( fn:exists($form-template/ldse:save-function) ) then (
        let $function-name as xs:string := $form-template/ldse:save-function/@name
        let $function as element(ldse:function)? := $form-template/ldse:functions/ldse:function[@name = $function-name]
        let $update := xdmp:apply(xdmp:function(fn:QName($function/@namespace, $function-name), $function/@path), $file, $file, $form-template)
        return fn:exists($form-template/ldse:save-function)
    ) else ( fn:false() )
};

declare function action:perform-post-process(
    $file as element(),
    $form-template as element(ldse:formTemplate)
) {
    for $post-process in $form-template/ldse:post-processing/ldse:function[@name ne 'postProcessUriDefinition' and @name ne 'sf:postProcessUriDefinition'
                    and @name ne 'track-uri-change' and @name ne 'sf:track-uri-change']
    let $function-name as xs:string := $post-process/@name
    let $function as element(ldse:function)? := $form-template/ldse:functions/ldse:function[@name = $function-name]
    let $update := xdmp:apply(xdmp:function(fn:QName($post-process/@namespace, $function-name), $post-process/@path), $file, $file, $form-template)
    return ()
};

declare function action:update-items(
    $file as element(),
    $ids as xs:string+,
    $locale as xs:string,
    $uri as xs:string,
    $action as xs:string,
    $get-children as xs:boolean,
    $site as xs:string?
) as element()? {
    action:update-items($file, $ids, $locale, $uri, $action, $get-children, $site, ())
};

declare function action:update-items(
    $file as element(),
    $ids as xs:string+,
    $locale as xs:string,
    $uri as xs:string,
    $action as xs:string,
    $get-children as xs:boolean,
    $site as xs:string?,
    $index as xs:string?
) as element()? {
    let $comp-id as xs:string? := $file/@compId
    let $parent as xs:string? := $file/@parent
    let $update-map as empty-sequence() :=
        if ( fn:exists($comp-id) and fn:exists($parent) and fn:not($comp-id eq $ids) and fn:not($parent eq $ids) ) then (
            ( map:put($comp-map, $comp-id, $comp-id), map:put($comp-map, $parent, $parent) )
        ) else if ( fn:not($comp-id eq $ids) and fn:exists($comp-id) ) then (
            map:put($comp-map, $comp-id, $comp-id)
        ) else if ( fn:not($parent eq $ids) and fn:exists($parent) ) then (
            map:put($comp-map, $parent, $parent)
        ) else ()
    let $content-ids as map:map := action:get-content-items($file, $locale, $site)
    let $publishable as xs:boolean := pf:is-publishable($file, $uri)
    let $update-rewrite as item()* := action:update-rewrite-rule($file, $action, $site)
    let $page-uri as xs:string? := xdmp:get-request-field('pageUri')
    let $isNestedComponent as xs:string := xdmp:get-request-field('isNestedComponent','false')
    return (
        if ( $action = 'ldse:remove-from-page' or $action = 'ldse:disable-from-page' ) then (
            if ( $isNestedComponent eq "false" ) then (

                let $page as element()? := ( df:get-custom-page($page-uri, $locale, $site), df:get-article($page-uri, $locale, $site) )[1]
                let $content-item as element()* := $page/(contents,content)/element()[. = $file/@id]
                return (
                    if ( fn:exists($content-item) ) then (
                        if ( $action = 'ldse:remove-from-page' ) then (
                            let $new-page as element() := mem:delete($content-item)/*
                            let $new-page := mem:node-replace($new-page/ldse:ldse-meta/ldse:last-modified/@date, attribute date { fn:current-dateTime() })/*
                            let $new-page := mem:node-replace($new-page/ldse:ldse-meta/ldse:last-modified/@username, attribute username { $ac:contributor/ldse:name/fn:string() })/*
                            let $save as item()* := document:document-replace($page, $new-page)
                            return $new-page
                        ) else if ( $action = 'ldse:disable-from-page' ) then (
                            if($content-item/@disable) then (
                                let $new-page as element() := mem:delete($content-item/@disable)/*
                                let $new-page := mem:node-replace($new-page/ldse:ldse-meta/ldse:last-modified/@date, attribute date { fn:current-dateTime() })/*
                                let $new-page := mem:node-replace($new-page/ldse:ldse-meta/ldse:last-modified/@username, attribute username { $ac:contributor/ldse:name/fn:string() })/*
                                let $save as item()* := document:document-replace($page, $new-page)
                                return $new-page
                            ) else (
                                let $disable := attribute disable { "true" }
                                let $new-page as element():= mem:insert-child( $content-item, $disable)/*
                                let $new-page := mem:node-replace($new-page/ldse:ldse-meta/ldse:last-modified/@date, attribute date { fn:current-dateTime() })/*
                                let $new-page := mem:node-replace($new-page/ldse:ldse-meta/ldse:last-modified/@username, attribute username { $ac:contributor/ldse:name/fn:string() })/*
                                let $save as item()* := document:document-replace($page, $new-page)
                                return $new-page
                            )
                        ) else ( $page )
                    ) else ( $page )
                )
            ) else (
                if( $action eq 'ldse:disable-from-page' ) then (
                    let $nestedComponentIdx as xs:string? := xdmp:get-request-field('nestedComponentIdx','-1')
                    let $nestedId as xs:string? := xdmp:get-request-field('nestedId','empty')
                    let $page as element()* := df:get-custom-component-page($ids, $uri, $locale, $site)
                    let $content-item as element()* := ($file//*[@is-reference eq 'true' and . eq $nestedId])                    
                    return (
                         if ( fn:exists($content-item) and fn:exists($page) ) then (
                            if($content-item/@disable) then (
                                let $new-page as element() := mem:delete($content-item/@disable)/*
                                let $new-page := mem:node-replace($new-page/ldse:ldse-meta/ldse:last-modified/@date, attribute date { fn:current-dateTime() })/*
                                let $new-page := mem:node-replace($new-page/ldse:ldse-meta/ldse:last-modified/@username, attribute username { $ac:contributor/ldse:name/fn:string() })/*
                                let $save as item()* := document:document-replace($page, $new-page)
                                let $update-level-up := action:update-parent-level-up-status(ldsemeta:get-parent-file-by-child-id($ids[1], $uri, $locale, $site)/node())
                                return $new-page
                            ) else (
                                let $disable := attribute disable { "true" }
                                let $new-page as element():= mem:insert-child( $content-item, $disable)/*
                                let $new-page := mem:node-replace($new-page/ldse:ldse-meta/ldse:last-modified/@date, attribute date { fn:current-dateTime() })/*
                                let $new-page := mem:node-replace($new-page/ldse:ldse-meta/ldse:last-modified/@username, attribute username { $ac:contributor/ldse:name/fn:string() })/*
                                let $save as item()* := document:document-replace($page, $new-page)
                                let $update-level-up := action:update-parent-level-up-status(ldsemeta:get-parent-file-by-child-id($ids[1], $uri, $locale, $site)/node())
                                return $new-page
                            )
                         ) else ( )
                    )
                ) else ( )
            )
        ) else (
            let $updateParent as element()* :=
                if( $action eq 'ldse:delete' ) then (
                    for $target-mode in ('preview','published')
                    let $searchForRef as xs:string* := 
                        cts:uris("", (),
                            cts:and-query((
                                (: core:get-filter-query(), :)
                                cts:directory-query('/'||$target-mode||'/', 'infinity'),                   
                                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uri, 'exact')                                
                        )))
                    let $deleteRef as element()*:=  if (fn:count($ids) eq 1) then (
                                                        func:apply(xdmp:function(xs:QName("action:deleteReferences")), $target-mode, $searchForRef, $ids, $target-mode)                                        
                                                    ) else ( )
                    return ( )
                ) else ( )                            
            return
                action:perform($file, $action, $publishable, $uri, $locale, $get-children, $site)
        )
    )
};

declare function action:update-parent-level-up-status(
    $item as item()?
) as element()? {
    if(fn:name($item) eq "custom-page") then (        
        let $new-page := mem:node-replace($item/ldse:ldse-meta/ldse:last-modified/@date, attribute date { fn:current-dateTime() })/*
        let $new-page := mem:node-replace($new-page/ldse:ldse-meta/ldse:last-modified/@username, attribute username { $ac:contributor/ldse:name/fn:string() })/*        
        let $save as item()* := document:document-replace($item, $new-page)
        let $level-up := xdmp:log(fn:name($item))        
        return ()
    ) else (
        if(fn:exists($item)) then (            
            let $level-up := action:update-parent-level-up-status(ldsemeta:get-parent-file-by-child-id($item/@id, $item/@uri/fn:string(),  $item/@locale/fn:string(), $item/ldse:ldse-meta/ldse:form-options/ldse:site-context/fn:string())/node())
            let $new-page := mem:node-replace($item/ldse:ldse-meta/ldse:last-modified/@date, attribute date { fn:current-dateTime() })/*            
            let $new-page := mem:node-replace($new-page/ldse:ldse-meta/ldse:last-modified/@username, attribute username { $ac:contributor/ldse:name/fn:string() })/*
            let $save as item()* := document:document-replace($item, $new-page)
            return ()
        ) else ( )        
    )    
};

declare function action:deleteReferences(
    $uris as xs:string*,
    $id as xs:string,
    $target-mode as xs:string
) as item()* {
    if ($uris) then (
        for $uri in $uris
        let $itemToDelete as element()* := fn:doc($uri)//node()[@is-reference = "true"][. = $id]
        return
            if (fn:exists($itemToDelete)) then (
                let $deleteNode as element()* := xdmp:node-delete($itemToDelete)
                let $updateNode as element()* := xdmp:node-replace(fn:root($itemToDelete)/node()/ldse:ldse-meta/ldse:last-modified/@date, attribute date { fn:current-dateTime() })
                return (  )
            ) else (
                if ($target-mode = "published") then (
                    let $itemToDelete as element()* := fn:doc($uri)//content/node()[@region = "page-components"][. = $id]
                    return
                        if (fn:exists($itemToDelete)) then (
                           let $log := xdmp:log($itemToDelete)
                           let $deleteNode as element()* := xdmp:node-delete($itemToDelete)
                           let $updateNode as element()* := xdmp:node-replace(fn:root($itemToDelete)/node()/ldse:ldse-meta/ldse:last-modified/@date, attribute date { fn:current-dateTime() })                           
                           return ( )
                
                        ) else ( )
                ) else ( )
            )
    ) else ( )
};

declare function action:deleteChildren(
    $children as xs:string*,
    $uri as xs:string,
    $target-mode as xs:string
) as item()* {
 
    for $id in $children                                                                                                                                                      
    let $file as xs:string* := 
        cts:uris("", (),
                cts:and-query((
                    cts:directory-query('/'||$target-mode||'/', 'infinity'),                   
                    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uri, 'exact'),
                    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $id, 'exact')
                )))[1]                
    let $delete := xdmp:document-delete($file)
    return ( )
                                                                  
};

declare function action:publish-components(
    $action as xs:string,
    $locale as xs:string,
    $uri as xs:string
) as item()* {
    for $key as xs:string in map:keys($comp-map)
    return (
        if ( $action = "ldse:publish" and fn:not($key = "") ) then (
            let $component as element()? := ldsemeta:get-file-by($key, $locale, $uri, ())
            where fn:exists($component)
            return (
                action:publish-component($component, $action)
            )
        ) else ()
    )
};

declare function action:publish-component(
    $component as element(),
    $action as xs:string
) as element() {
    let $update-file as element() := core:action-transform($action, $component)
    let $save as item()* := core:update-file($action, xdmp:node-uri($component), $update-file, $component, $options)
    return (
        $update-file
    )
};

declare function action:perform(
    $file as element(),
    $action as xs:string,
    $publishable as xs:boolean,
    $uri as xs:string,
    $locale as xs:string,
    $get-children as xs:boolean,
    $site as xs:string?
) as element()? {
    let $type as xs:string? := ldsemeta:get-document-type($file)
    return (
        if ( fn:contains($action, "ldse:publish") and $settings:correlation-enabled ) then (
            if ( ldsemeta:correlation-can-publish($file) and $publishable ) then (
                if ( correlation:file-can-be-sent-to-correlation($file) ) then (
                    let $correlation-document-uri as xs:string := correlation:initiate-operation-fake-form-post(ldsemeta:get-document-id($file))
                    let $db-path as xs:string := xdmp:node-uri($file)
                    let $new-file as element() := ldsemeta:update-sensitive-file($file, (), (), "yes", "no", $action, ())
                    let $save as item()* := core:update-file($action, $db-path, $new-file, $file, $options)
                    return (
                        $new-file
                        (:,
                        func:spawn(xdmp:function(xs:QName("handle-correlation:spawn"), "/correlation/modules/handle-correlation-spawn.xqy"), "preview", $correlation-document-uri, fn:false(), ldsemeta:get-document-id($file), ldsemeta:get-document-locale($file)):)
                    )
                ) else (
                    let $db-path as xs:string := xdmp:node-uri($file)
                    let $new-file as element() := ldsemeta:update-sensitive-file($file, (), (), "yes", "no", $action, ())
                    let $new-file as element() := core:action-transform($action, $new-file)
                    let $save as item()* := core:update-file($action, $db-path, $new-file, $file, $options)
                    return (
                        $new-file
                    )
                )
            ) else ()(: Document is in a state that does not allow publishing or user does not have rights to override") :)

        ) else if ( $action = "ldse:publish" ) then (
            if ( $publishable and ldsemeta:correlation-can-publish($file) ) then (
                let $db-path as xs:string := xdmp:node-uri($file)
                let $new-file as element() := ldsemeta:update-sensitive-file($file, (), (), "yes", "no", $action, ())
                let $save as item()* := core:update-file($action, $db-path, $new-file, $file, $options)
                return (
                    $new-file
                )
            ) else ()
        ) else if ( ( $type = 'custom-page' or fn:local-name($file) = 'article' ) and $action = "ldse:delete" ) then (
            let $_ := if ( $settings:remove-custom-page-content ) then ( action:remove-custom-page-content($file, $site) ) else ()
            return (
                core:preform-action-and-update($action, $file, $options)
            )
        ) else if ( $action = 'ldse:delete' and fn:not($get-children) ) then (
            let $update-custom-page as item()* :=  action:update-custom-page($file)
            return (
                core:preform-action-and-update($action, $file, $options)
            )
        ) else (
            let $others as element()* :=
                if ( fn:not(fn:local-name($file) = ( 'custom-page', 'article' ) ) ) then (
                    action:get-other-pages($file)
                ) else ()
            where fn:count($others) <= 1
            return core:preform-action-and-update($action, $file, $options)
        )
    )
};

declare function action:update-rewrite-rule($file as element(), $action as xs:string, $site as xs:string?) {
    typeswitch ( $file )
    case element(custom-page) return (
        rw:update-rewrite-rule($action, ldsemeta:get-document-uri($file), ldsemeta:get-document-locale($file), $file, $site)
    ) default return ()
};

declare function action:update-content-items(
    $action as xs:string,
    $content-ids as map:map,
    $locale as xs:string,
    $uri as xs:string?
) as item()* {
    action:update-content-items($action, $content-ids, $locale, $uri, (), fn:false(), ())
};

declare function action:update-content-items(
    $action as xs:string,
    $content-ids as map:map,
    $locale as xs:string,
    $uri as xs:string?,
    $ids as xs:string*,
    $get-children as xs:boolean,
    $site as xs:string?
) as item()* {
    for $key as xs:string in map:keys($content-ids)
    where fn:not($key = "") and $action = "ldse:publish" and fn:not($key = $ids)
    return (
        let $file as element()? := ldsemeta:get-file-by($key, $locale, (), (), $site)
        where fn:exists($file)
        return (
            core:preform-action-and-update($action, $file, $options)
        )
    )
};

declare function action:get-content-items($file as element(), $locale as xs:string, $site as xs:string?) as map:map {
(:    let $items :=
        for $item as element() in $file/items/item
        where fn:contains($file/@uri, 'media-library') or fn:contains(ldsemeta:get-document-uri($file), "media-library")
        return (
            map:put($id-map, $item/fn:string(), $item/fn:string())
        )
    return (
        $id-map
    ):)
    map:map()
};

declare function action:remove-custom-page-content(
    $custom-page as element(),
    $site as xs:string?
) as item()* {
    let $uri as xs:string := $custom-page/@uri
    let $locale as xs:string := ldsemeta:get-document-locale($custom-page)
    let $files as element()* :=
        for $item as element() in $custom-page/content/element()
        return ldsemeta:get-files-by($item, $locale, (), (), $site)
    for $file as element() in $files
    let $others as element()* := action:get-other-pages($file)
    where fn:empty($others)
    return (
        core:delete-file(xdmp:node-uri($file), $file, $file)
    )
};

declare function action:get-other-pages(
    $file as element()?
) as element()* {
    cts:search(/(article|custom-page),
        cts:and-query((
            core:get-filter-query(),
            cts:element-value-query(xs:QName(fn:local-name($file)), ( $file/@id[. != ''], ldsemeta:get-document-id($file) )[1], 'exact')
        ))
    )
};

declare function action:update-custom-page(
    $file as element()
) as item()* {
    let $form-name as xs:string? := $file/ldse:ldse-meta/ldse:form-options/ldse:form
    let $form as element(ldse:formTemplate)? := df:get-form($form-name)
    return (
        if ( fn:exists($form) ) then (
            let $updateCustomPage := df:updateCustomPage($file, $file, $form)
            let $updateCustomPageDependencies := df:updateCustomPageDependencies($file, $form-name) (: When component deleted, update its references :)
            return $updateCustomPage
        ) else ()
    )
};
