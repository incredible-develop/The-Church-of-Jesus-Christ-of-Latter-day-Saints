xquery version "1.0-ml";

module namespace version = "http://lds.org/code/lds-edit/versions";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "ldse-core.xqy";
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at "document-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "ldse-meta.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "ldse-settings.xqy";
import module namespace function = "http://lds.org/code/shared/lds-edit/function-apply" at "../invoke/function-apply.xqy";
import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../ice/modules/dynamicForms.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "utility-functions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "access-control-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";

declare variable $trace-key as xs:string := "ldse-versions";
declare variable $add-function as xdmp:function := xdmp:function(xs:QName('version:add'));

(:~
    Checks If versioning is on 
           document as an ldse-meta id
           Document controled 
    Spawns to version:add if all true 
~:)
declare function version:save(
    $mode as xs:string, 
    $doc as item(), 
    $db-path as xs:string
) as empty-sequence() {
    if ( settings:is-mode-versioned($mode) ) then (
        let $id as xs:string? := $doc/ldse:ldse-meta/ldse:document/@id
        let $managed as xs:int := 
            if ( $id != "" and fn:exists($id) ) then (
                core:is-managed($doc)
            ) else ( 0 )
        return
            if ($managed > 0) then (
                function:spawn($add-function, $mode, $doc, fn:doc($db-path)/*, $db-path, $id, $managed )
            ) else ()
    ) else ()
};

(:~
    Add creates a version file if there is an existing document
    Deletes previous verions if nessesary 
~:)
declare function version:add(
    $doc as element(),
    $existing-doc as element()?,
    $db-path as xs:string, 
    $id as xs:string, 
    $managed as xs:int
) as empty-sequence() {
    let $versions as xs:dateTime* := version:get-available-versions($id)
    return (
       if ( fn:exists($existing-doc) and ( version:is-different($doc, $existing-doc) or version:submission-being-submitted($doc, $existing-doc) ) ) then (
            let $delete as empty-sequence() :=
                if ( fn:count($versions) >= $managed ) then (
                    version:delete($id, fn:subsequence($versions, $managed))
                ) else ()
            let $last-modified as element(ldse:last-modified)? := ldsemeta:get-last-modified($doc)
            let $date as xs:dateTime := ( $last-modified/@date/xs:dateTime(.), fn:current-dateTime() )[1]
            let $uri as xs:string? := ldsemeta:get-document-uri($doc, fn:true())
            let $locale as xs:string? := ldsemeta:get-document-locale($doc)
            let $version as element(version:version) := version:build($existing-doc, $id, $date, $last-modified/@username, $last-modified/@userid)
            let $version-path as xs:string := core:build-db-path($uri, $locale, fn:concat($id, '-', $date), $version, ())
            return (
                xdmp:trace($trace-key, fn:concat('Add: ', $id, ' : ', $date, ' : ', $version-path) ),
                core:save-file($version-path, $version, ())
            )
       ) else (
            xdmp:trace($trace-key, fn:concat('No change detected for: ', $id) )
       )
    )
};

declare function version:submission-being-submitted(
    $doc as element(),
    $existing-doc as element()?
) as xs:boolean {
	ldsemeta:is-submission($doc)
	and ldsemeta:get-submission-status($existing-doc) = "draft"
	and ldsemeta:get-submission-status($doc) = "submitted"
};

declare function version:is-different(
    $doc as element(),
    $existing-doc as element()?
) as xs:boolean {
    let $doc-prepared as element() := util:get-root(mem:node-delete($doc/(@status|ldse:ldse-meta)))
    let $existing-prepared as element() := util:get-root(mem:node-delete($existing-doc/(@status|ldse:ldse-meta)))
    return (
        fn:not( fn:deep-equal($doc-prepared, $existing-prepared) )
    )
};

(:~
    Deletes version for the specified $id and $date 
~:)
declare function version:delete(
    $id as xs:string,
    $dates as xs:dateTime*
) as empty-sequence() {
    let $date := 
        for $date in $dates
            for $uri as xs:string in
                cts:uris('/', (),
                    cts:and-query((
                        core:get-filter-query(),
                        cts:element-attribute-value-query(xs:QName('version:version'), xs:QName('id'), $id, 'exact'),
                        cts:element-attribute-range-query(xs:QName('version:version'), xs:QName('date'), '<=', fn:current-dateTime() - xs:dayTimeDuration("P30D"), ())
                    ))
                )
            return (
                xdmp:trace($trace-key, fn:concat('Delete: ', $id, ' : ', $date) ),
                document:document-delete($uri)
            )
    return ()
};

(:~
    Deletes all versions for the specified $doc 
~:)
declare function version:delete-all(
    $mode as xs:string,
    $doc as element()
) as empty-sequence() {
    if ( settings:is-mode-versioned($mode) ) then (
        let $id as xs:string? := $doc/ldse:ldse-meta/ldse:document/@id
        let $delete as item()* :=
            if ( $id != "" and fn:exists($id) ) then (
                for $uri as xs:string in
                    cts:uris('/',(),
                        cts:and-query((
                            core:get-filter-query(),
                            cts:element-attribute-value-query(xs:QName('version:version'), xs:QName('id'), $id, 'exact')
                        ))
                    )
                return (
                    xdmp:trace($trace-key, fn:concat('Delete All: ', $id) ),
                    document:document-delete($uri)
                )
            ) else ()
        return ()
    ) else ()
};

(:~
    Returns version with $id and $date
~:)
declare function version:get-version($id as xs:string, $date as xs:dateTime) as element(version:version)? {
    cts:search(/version:version,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('version:version'), xs:QName('id'), $id, 'exact'),
            cts:element-attribute-range-query(xs:QName('version:version'), xs:QName('date'), '=', $date, ())
        )),
        "unfiltered"
    )[1]
};

declare variable $get-file-by as xdmp:function := xdmp:function(xs:QName('ldsemeta:get-file-by'));
 
declare function version:get-published-version($id as xs:string) as element()? {
    function:invoke($get-file-by, $settings:modes[fn:last()]/@name, $id, (), (), ())
};

declare function version:get-current-version($id as xs:string) as element()? {
    ldsemeta:get-file-by($id, (), (), ())
};

(:~
    Returns all versions for $id
~:)
declare function version:get-available-versions(
    $id as xs:string
) as xs:dateTime* {
    cts:element-attribute-values(
        xs:QName('version:version'), 
        xs:QName('date'), 
        (), 
        ("descending"),
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('version:version'), xs:QName('id'), $id, 'exact')
        ))
    )
};

(:~
    Builds a version element
~:)
declare function version:build(
    $doc as element(), 
    $id as xs:string, 
    $date as xs:dateTime, 
    $user-name as xs:string?, 
    $user-id as xs:string?
) as element(version:version) {
    <version xmlns="http://lds.org/code/lds-edit/versions">{
        attribute id { $id },
        attribute date { $date },
        element user {
            attribute id { $user-id },
            $user-name
        },
        element doc { xdmp:quote($doc) }
    }</version>
};

declare function version:get-versions-json(
    $id as xs:string
) {
    let $json := 
        object-node {
            'versions': array-node {
                for $date as xs:dateTime in version:get-available-versions($id)
                let $version as element(version:version) := version:get-version($id, $date)
                let $user as xs:string := core:get-contributor-name($version/version:user)
                return (
                    object-node {
                        'value': fn:string(xs:string($date)),
                        'text': fn:string(fn:concat(fn:format-dateTime($date, '[D01] [MNn,*-3] [Y0001] [h]:[m01] [PN]'), ' (', $user, ')' ))
                    }
                )
            }
        }
    return xdmp:from-json($json)
};

declare function version:get-version-form($id as xs:string, $version as xs:string, $form as xs:string) as element()* {
    let $_ as item()* := form:buildParamMap()
    let $file as element()? := 
        if ($version = "current") then (
            version:get-current-version($id)
        ) else if ($version = "published") then (
            version:get-published-version($id)
        ) else (
            version:get-version($id, xs:dateTime($version))/version:doc/xdmp:unquote(node())/*
        )
    let $files-form as xs:string := (ldsemeta:get-form-options($file)/form[ . != ""], $form)[1]
    let $form as element(ldse:formTemplate) := form:getFormTemplate($files-form)
    return (
        <div class="ldse-form">
            <fieldset>
                <input type="hidden" class="ldse-version-form" name="ldse-version-form" value="{ $files-form }" />
                { form:groupInputs($form, form:buildForm($form/ldse:structure/*, $file, ()), fn:false()) }
            </fieldset>
        </div>
    )
};

declare function version:build-versions-button(
    $file as element()?,
    $id as xs:string?,
    $disabled-on-add as xs:string?,
    $tooltip-on-add as attribute()?
) as element(section) {
     let $versioned as xs:int := 
         if (fn:exists($file)) then (
             core:is-managed($file)
         ) else ( 0 )
     let $count as xs:int := 
         if ( $versioned > 0) then (
             fn:count( version:get-available-versions($id)[1 to $versioned] )
         ) else ( 0 )
     let $disabled as xs:string? := if (fn:exists($disabled-on-add) and $versioned = 0) then ("disabled") else ()
     let $tooltip as attribute()? := 
         if ( fn:exists($tooltip-on-add) ) then (
             $tooltip-on-add
         ) else if ( $versioned = 0 ) then (
             attribute data-tooltip {"This document is not under version control."}
         ) else ()
     return (
         <section id="versions" class="ldse-block tile ldse-notification-container ldse-toggle-content {$disabled}" data-group="#options" data-selector="#versions-info">
            {$tooltip}
            <button class="ldse-button tile ldse-icon-versions above">Versions</button>
            <span class="ldse-information">{ $count }/{ $versioned }</span>
        </section>
    )
};

declare function version:build-versions-section($file as element()?) as element()* {
    <section id="versions-info" class="ldse-hidden">
        <section id="left-side" class="ldse-section ldse-summary ldse-clearfix grid-50 left-side">
            <header class="ldse-section--header ldse-form">
                <dl>
                    <dd><select name="" id="" class="version-select" data-side="left">
                            <option value="current" selected="selected">Current Version</option>
                            { 
                              if (ldsemeta:is-published($file)) then (
                                <option value="published" >Published Version</option>
                              ) else ()
                            }
                        </select>
                    </dd>
                </dl>
            </header>
            <form class="ldse-section--body ldse-form" method="post" enctype="multipart/form-data" action="">
                <input type="hidden" id="restored-versions" name="restored-versions" value=""/>
                <input type="hidden" id="can-restore-line-item" value='{ac:has-permission("ldse:versions-restore-line-item", ldsemeta:get-document-locale($file), ldsemeta:get-document-uri($file))}'/>
                <section class="modified-button-group">
                {
                	if(ac:has-permission("ldse:versions-save-as-current", ldsemeta:get-document-locale($file), ldsemeta:get-document-uri($file)))
                	then <button id="save-version" class="ldse-button primary ldse-icon-save" style="float: right;">Save as Current</button>
                	else ()
                }
                </section>
                <div class="form-section">
                </div>
            </form>
        </section>
        <section id="right-side" class="ldse-section ldse-summary ldse-clearfix grid-50">
            <header class="ldse-section--header ldse-form">
                <dl>
                    <dd>
                        <select name="" id="" class="version-select" data-side="right">
                            <option value="current">Current Version</option>
                            { 
                              if (ldsemeta:is-published($file)) then (
                                <option value="published" selected="selected">Published Version</option>
                              ) else ()
                            }
                        </select>
                    </dd>
                </dl>
            </header>
            <div class="ldse-section--body ldse-form">
                <section class="modified-button-group">
                {
                	if(ac:has-permission("ldse:versions-restore-complete", ldsemeta:get-document-locale($file), ldsemeta:get-document-uri($file)))
                	then <button id="complete-restore" class="modified ldse-button ldse-icon-revert">Restore Complete Version</button>
                	else ()
                }
                    <span id="complete-help">
                        <span id="complete_help_container">
                            <span id="complete_help_button" class="ldse-info-button ldse-icon-ko-info ldse-icon ldse-toggle-content" title="Show Info" data-selector="#complete_help_info_text">Show Info</span>
                            <div id="complete_help_info_text" class="ldse-info-text ldse-hidden">Only a complete restore is available when forms are different.</div>
                        </span>
                    </span>
                </section>
                <div class="form-section">
                    
                </div>
            </div>
        </section>
    </section>
};

declare function version:build-versions-scripts($id as xs:string) as element()* {
    <script type="text/javascript" src="{$settings:shared-prefix}/resources/scripts/simplediff.js"/>,
    <script type="text/javascript" src="{$settings:shared-prefix}/form/resources/scripts/versions.js"/>,
    <script type="text/javascript">
        var VERSIONS = new versions( {xdmp:to-json-string($id)} );
        VERSIONS.setup();
    </script>
};
