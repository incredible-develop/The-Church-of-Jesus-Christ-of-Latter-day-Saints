xquery version "1.0-ml";

module namespace content-workflow = "http://lds.org/code/shared/lds-edit/new-content-manager/content-workflow";

(: lds-edit :)
import module namespace json = "http://marklogic.com/json" at "/modules/fasterjson.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "/modules/ldse-meta.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace tw = "http://lds.org/code/shared/lds-edit/translation-workflow" at "/translation/modules/translation-workflow.xqy";
import module namespace content-settings = "http://lds.org/code/shared/lds-edit/new-content-manager/content-settings" at "/new-content-manager/modules/content-settings.xqy";
import module namespace snip = "http://lds.org/code/shared/lds-edit/new-content-manager/json-snippet" at "/new-content-manager/modules/json-snippet.xqy";
import module namespace cc = "http://lds.org/code/shared/lds-edit/clear-cache-functions" at "/clear-cache/modules/clear-cache-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace hldse = "http://lds.org/code/lds-edit/history";

declare option xdmp:mapping "true";

declare variable $steps as element(ldse:step)* := declare-steps();
declare private variable $permissions-override as xs:boolean := fn:false();
declare variable $USERNAME as xs:string? := fn:lower-case(ac:getUserName());

declare function set-permissions-override($override as xs:boolean) as empty-sequence()
{
	xdmp:set($permissions-override, $override)
};

declare function editFile() as item()* {
    let $file-ids as xs:string* := fn:distinct-values(xdmp:get-request-field('id[]')[. ne ''])
    let $files as element()* :=
        if (fn:exists($file-ids)) then (
            ldsemeta:get-files-by($file-ids, (), (), ())
        ) else ()

    let $status as xs:string? := xdmp:get-request-field('status')[. ne '']
    let $action as xs:string? := xdmp:get-request-field('action')[. ne '']
    let $lang as xs:string? := ldsemeta:get-document-locale($files)[1]
    let $uri as xs:string? := ldsemeta:get-document-uri($files)[1]
    let $origin as xs:string? := xdmp:get-request-header('Origin')
    return xdmp:redirect-response(fn:concat($origin, $settings:shared-prefix, "/form?lang=", $lang, "&amp;country=", "&amp;id=", $file-ids, "&amp;uri=", $uri))
};

declare function get-config() as element(script)* {
    let $workflow as element(ldse:content-workflow)? := $content-settings:workflow
    let $template-ids as xs:string* := fn:distinct-values($workflow//ldse:template[@type eq "form"]/@id)
    return (
        <script type="text/javascript">
            C.SETTINGS = {json:obj((
                    for $step as element(ldse:step) in $workflow/ldse:step
                    let $name as xs:string := $step/@name
                    let $date-title as xs:string? := $step/ldse:date-filter/@title
                    let $user-title as xs:string? := $step/ldse:user-filter/@title
                    return (
                       json:keyObject($step/@name,
                           json:obj((
                               if ( fn:exists($date-title) ) then (json:keyValue("date", $date-title)) else (),
                               if ( fn:exists($user-title ) ) then (json:keyValue("user", $user-title )) else (),
                               for $action as element() in $step/(ldse:back|ldse:block|ldse:complete)
                               let $name as xs:string := fn:local-name($action)
                               let $template as element(ldse:template)? := $action/ldse:template
                               let $type as xs:string? := $template/@type
                               let $permission as element(ldse:permission)? := $action/ldse:permission
                               where fn:empty($permission) or ac:has-permission($permission, (), ())
                               return (
                                    json:keyValue($name, $action/@title),
                                    if ( fn:exists($template) ) then (
                                        json:keyObject(fn:concat($name, "-template"),
                                            json:obj((
                                                json:keyValue("type", $type),
                                                if ($type eq "form") then (
                                                    json:keyValue("id", xs:string($template/@id)),
                                                    json:keyValue("additional", xs:string($template/@additional))
                                                ) else if ($type = "reason") then (
                                                    json:keyValue("title", xs:string($template/@title)),
                                                    json:keyValue("label", xs:string($template/@label))
                                                ) else ()
                                            ))
                                        )
                                    ) else ()
                               )
                           ))
                       )
                    ),
                    json:keyValue("recipients", fn:string-join($settings:to-recipient-emails, '; '))
                ))
            };
            { publish-file($workflow)/node() }
        </script>,
        for $template-id as xs:string in $template-ids
        let $template as element(ldse:template) := ($workflow/ldse:step//ldse:template[@id eq $template-id and @type eq "form"])[1]
        let $step as element(ldse:step) := ($template/ancestor::ldse:step)[1]
        where fn:exists($template)
        return (
            apply-template($template, $step)
        )
    )
};

declare function publish-file($workflow as element(ldse:content-workflow)?) as element(script)? {
    let $file-id as xs:string? := xdmp:get-request-field("publish")
    let $action as element()? := $workflow/ldse:step/*[ldse:template/@name = "publish-template"]
    let $action-name as xs:string? := fn:local-name($action)
    where fn:exists($file-id) and fn:exists($action)
    return (
        let $file as element()? := ldsemeta:get-file-by($file-id, (), (), ())
        let $status as xs:string := $action/parent::ldse:step/@name
        let $template as element(ldse:template) := $action/ldse:template
        where fn:exists($file)
        return (
            let $value as element() := <script type="text/javascript">
                C.PUBLISH = {
                    json:obj((
                        json:keyObject("file", snip:json-all($file, (), ())),
                        json:keyValue("status", $status),
                        json:keyValue("action", $action-name),
                        json:keyObject("template",
                            json:obj((
                               json:keyValue("type", xs:string($template/@type)),
                               json:keyValue("id", xs:string($template/@id)),
                               json:keyValue("additional", xs:string($template/@additional))
                            ))
                        )
                    ))
                };
            </script>
            return $value
        )
    )
};

declare function publish-files($workflow as element(ldse:content-workflow)?) as element(script)? {
    let $file-id as xs:string? := xdmp:get-request-field("publish")
    let $action as element()? := $workflow/ldse:step/*[ldse:template/@name = "publish-templates"]
    let $action-name as xs:string? := fn:local-name($action)
    where fn:exists($file-id) and fn:exists($action)
    return (
        let $file as element()? := ldsemeta:get-file-by($file-id, (), (), ())
        let $status as xs:string := $action/parent::ldse:step/@name
        let $template as element(ldse:template) := $action/ldse:template
        where fn:exists($file)
        return (
          let $value as element() := <script type="text/javascript">
                C.PUBLISH = {
                    json:obj((
                        json:keyObject("file", snip:json-all($file, (), ())),
                        json:keyValue("status", $status),
                        json:keyValue("action", $action-name),
                        json:keyObject("template",
                            json:obj((
                               json:keyValue("type", xs:string($template/@type)),
                               json:keyValue("id", xs:string($template/@id)),
                               json:keyValue("additional", xs:string($template/@additional))
                            ))
                        )
                    ))
                };
            </script>
        return $value
        )
    )
};

declare function get-steps() as element(ldse:step)* {
    $steps
};

declare function declare-steps() as element(ldse:step)* {
    for $step as element(ldse:step) in $content-settings:workflow/ldse:step
    	let $permissions as element(ldse:permission)* := ($step/ldse:permission[fn:not(. = "")], <permission xmlns="http://lds.org/code/lds-edit">ldse:view-all-content-manager-statuses</permission>)
	    return
			if(fn:exists($permissions))
			then
				if(some $permission as xs:string in $permissions satisfies ac:has-permission($permission, (), ()) or $permissions-override)
				then $step
				else ()
			else $step


(:
    let $permission as xs:string? := $step/ldse:permission[. != ""]
    where fn:exists($permission) and ac:has-permission($permission, (), ())
    return ( $step )
:)
};

declare function get-step-by-name($step-name as xs:string) as element(ldse:step)? {
    let $step as element(ldse:step)? := $steps[@name eq $step-name]
    where some $permission in $step/ldse:permission[. != ""] satisfies ac:has-permission($permission, "", "") or $permissions-override
    return $step
};

declare function get-action-from-step($step as element(ldse:step), $action as xs:string) as element()? {
    if ($action eq "complete") then (
        $step/ldse:complete
    ) else if ($action eq "block") then (
        $step/ldse:block
    ) else if ($action eq "back") then (
        $step/ldse:back
    ) else ()
};

declare function has-action-permission($action-element as element()?, $locale as xs:string?, $uri as xs:string?) as xs:boolean {
    fn:exists($action-element) and
    (
        $action-element/ldse:permission = "" or
        ac:has-permission($action-element/ldse:permission, $locale, $uri)
    )
};

declare function get-query($step-name as xs:string) as cts:query* {
    get-step-query(get-step-by-name($step-name))
};

declare variable $locales as xs:string* := cts:element-attribute-values(xs:QName("ldse:document"), xs:QName("locale"))[. ne 'ALL'];

declare function get-step-query($step as element(ldse:step)) as cts:query* {
    let $query as element(ldse:query)? := $step/ldse:query
    let $cts-query as cts:query* := (
        if ($query/@status eq "comments") then (
           cts:and-query((
                cts:element-query(xs:QName('hldse:comment'), cts:and-query(( () ))),
                rights-query-by-step($step)
            ))
		)
		else (
            cts:and-query((
                 cts:element-attribute-range-query(xs:QName("ldse:document"), xs:QName("locale"), "=", $locales, "collation=http://marklogic.com/collation/"),
                 rights-query-by-step($step),
                 if ($query/@status eq "published") then (
                     cts:and-query((
                         cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('status'), '=', "publish", "collation=http://marklogic.com/collation/"),
                         cts:element-query(xs:QName('ldse:publish-date'),
                             cts:and-query( () )
                         )
                     ))
                 ) else if ($query/@status eq "unpublish") then (
                     cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('status'), '=', "unpublish", "collation=http://marklogic.com/collation/"),
                     cts:element-query(xs:QName('ldse:unpublish-date'),
                         cts:and-query( () )
                     )
                 ) else if ($query/@status eq "preview") then (
                    cts:and-query ((
                         cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('status'), '=', "preview", "collation=http://marklogic.com/collation/"),
                         if ($query/@name eq "modified") then (
                             cts:element-query(xs:QName('ldse:publish-date'), cts:and-query(( () )))
                         ) else (
                             cts:not-query(
                                 cts:element-query(xs:QName('ldse:publish-date'), cts:and-query(( () )))
                             )
                         ),
                         cts:or-query(
                         	(cts:element-attribute-value-query(
                         		xs:QName("ldse:submission"),
                         		xs:QName("edited"),
                         		"true"
                         	),
                         	cts:not-query(
	                         	cts:element-query(
	                         		xs:QName("ldse:submission"),
	                         		cts:and-query(())
                         		)
                         	))
                         )

                    ))
                 ) else if ($query/@status eq "schedulePublish") then (
                    cts:element-attribute-range-query(xs:QName("ldse:schedule-publish"), xs:QName("dateTime"), ">=", fn:current-dateTime(), "collation=http://marklogic.com/collation/")
                 ) else if ($query/@status eq "scheduleUnpublish") then (
                    cts:element-attribute-range-query(xs:QName("ldse:schedule-unpublish"), xs:QName("dateTime"), ">=", fn:current-dateTime(), "collation=http://marklogic.com/collation/")
                 ) else if($query/@status eq "submission-created")
					then
						cts:and-query((
							cts:element-attribute-value-query(
								xs:QName("ldse:submission"),
								xs:QName("status"),
								"created",
								"exact"
							)
						))

					else if($query/@status eq "submission-submitted")
					then
						cts:and-query((
							cts:element-attribute-value-query(
								xs:QName("ldse:submission"),
								xs:QName("status"),
								"submitted",
								"exact"
							),
							cts:not-query(
								cts:element-attribute-value-query(
									xs:QName("ldse:submission"),
									xs:QName("edited"),
									"true"
								)
							)
						))

			        else (
                     apply-function($query, $step)
                 )
             ))
         )
    )

    let $cts-query as cts:query* :=
    	cts:and-query((
    		$cts-query,

    		if($settings:is-submitter)
			then
				cts:element-attribute-value-query(
					(xs:QName("ldse:created"), xs:QName("hldse:created")),
					xs:QName("username"),
					$USERNAME,
					"exact"
				)
			else (),

			if(fn:not($query/@status eq ("submission-created", "submission-submitted")))
			then
				cts:not-query(
					cts:element-attribute-value-query(
						xs:QName("ldse:submission"),
						xs:QName("status"),
						"created"
					)
				)
			else ()
    	))

    return $cts-query
};

declare function get-all-step-queries() as cts:query* {
    cts:or-query((
        for $step as element(ldse:step) in $steps
        return (
            get-step-query($step)
        )
    ))
};

declare function rights-query-by-step($step as element(ldse:step)?) as cts:query* {
    if ( $permissions-override ) then (
        cts:and-query(( () ))
    ) else (
        if ( $step/@name = 'comments' ) then (
            ac:query-permission( ($step/ldse:permission, "ldse:view-all-content-manager-statuses"), xs:QName('hldse:document'), xs:QName('locale'), xs:QName('hldse:document'), xs:QName('uri') )
        ) else (
            ac:query-permission( ($step/ldse:permission, "ldse:view-all-content-manager-statuses") )
        )
    )
};

declare function build-function($element as element()) as xdmp:function {
    let $ns as xs:string := ($element/@ns[. ne ''], "http://lds.org/code/shared/lds-edit/new-content-manager/content-workflow")[1]
    return (
        xdmp:function(fn:QName($ns, xs:string($element/@name)), xs:string($element/@at))
    )
};

declare function apply-function(
    $element as element(),
    $step as element(ldse:step)
) as item()* {
    xdmp:apply( build-function($element), $step)
};

declare function apply-function(
    $element as element(),
    $step as element(ldse:step),
    $files as element()+
) as item()* {
    xdmp:apply(build-function($element), $step, $element, $files)
};

declare function apply-template(
    $template as element(),
    $step as element(ldse:step)
) as item()* {
    let $name as xs:string := $template/@name
    let $id as xs:string := $template/@id
    return (
        if ($name eq "remove-template") then (
            remove-template($step, $id)
        ) else if ($name eq "publish-template") then (
            publish-template($step, $id)
        ) else if ($name eq "publish-templates") then (
            publish-templates($step, $id)
        ) else (
            xdmp:apply(build-function($template), $step, $id)
        )
    )

};

declare function clear-cache-for-files(
    $files as element()+
) as item()* {
    let $locales as xs:string* := ldsemeta:get-document-locale($files)
    for $locale as xs:string in $locales
    let $uris as element(uris) :=
        element uris {
            for $file as element() in $files
            where ldsemeta:get-document-locale($file) = $locale
            return (
                element uri { ldsemeta:get-document-uri($file) }
            )
        }
    return (
        cc:clearCache($uris, $core:site, $locale)
    )
};

(:
********************************************************
                GENERIC-WORKFLOW-FUNCTIONS
********************************************************
:)
declare function apply-action(
    $step-name as xs:string,
    $action as xs:string,
    $files as element()+
) as item()* {
    let $step as element(ldse:step) := get-step-by-name($step-name)
    let $action-element as element() := get-action-from-step($step, $action)
    let $simpleUpdate as xs:boolean := fn:exists($action-element)

    return (
        if ($action-element/@action = "ldse:publish") then (
            tw:publish-files($step, $action-element , $files)
        ) else if ( $simpleUpdate ) then (
            remove-file($step, $action-element, $files)
        ) else (
            apply-function($action-element, $step, $files)
        )
    )
};

declare function get-uri($id as xs:string, $locale as xs:string) as element()? {
    cts:search(/*,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName("id"),($id),'exact'),
            cts:element-attribute-value-query(xs:QName("locale"),($locale),'exact')
        ))
    )[1]
};

declare function remove-file(
    $step as element(ldse:step),
    $action-element as element(),
    $files as element()+
) as item()* {
    if ( fn:exists($action-element) ) then (
        for $file as element() in $files
        let $ldse-action as xs:string := fn:string($action-element/@action)
        return ( core:preform-action-and-update($ldse-action, $file)),
            '{"success":true}'
    ) else (
        '{"success":false,"error":["Action had no update to meta"]}'
    )
};

declare function file-needs-action(
    $step-name as xs:string,
    $action as xs:string,
    $file as element()
) as xs:boolean {
    let $step as element(ldse:step)? := get-step-by-name($step-name)
    let $action-element as element()? := get-action-from-step($step, $action)
    let $file-status as xs:string? := ldsemeta:get-translation-event-status($file)
    let $step-status as xs:string? := $step/ldse:query/@status
    return (
        fn:exists($step) and fn:exists($action-element) and $file-status eq $step-status
    )
};
(:
********************************************************
                ACTION-CUSTOM-FUNCTIONS
********************************************************
:)
declare function publish-files(
    $step as element(ldse:step),
    $action as element(),
    $files as element()+
) as xs:string {
    let $ldse-action as xs:string := ($action/@action, "ldse:publish")[1]
    let $clear-cache as item()* := clear-cache-for-files($files)
    let $publish as item()* := core:preform-action-and-update($ldse-action, $files)
    return (
        '{"success":true}'
    )
};

(:
********************************************************
                FORM TEMPLATES
********************************************************
:)
declare function remove-template(
    $step as element(ldse:step),
    $id as xs:string
) as item()* {
    <script class="handlebars-template" id="{ $id }" type="text/x-handlbars-template" xmlns="">
        <header class="ldse-section--header">
            <h2>Remove {{{{checkedCount}}}} Documents</h2>
        </header>
        <form class="ldse-section--body ldse-form">
            {{{{#loop this.files}}}}
                <input type="hidden" name="id[]" value="{{{{this.id}}}}"/>
                <h3>Document {{{{iPlus1}}}} of {{{{checkedCount}}}}: {{{{this.title}}}} ({{{{this.locale}}}})</h3>
                {{{{#if languageFiles.length }}}}
                <dl>
                    <dt>
                        <label>Translations:</label>
                    </dt>
                    <dd>
                        <table class="ldse-table">
                            <thead>
                                <tr>
                                    <th>
                                        <span class="ldse-option box-only">
                                            <input type="checkbox" class="checkall" id="lang-checkall{{{{i}}}}"/>
                                            <label for="lang-checkall{{{{i}}}}">check</label>
                                         </span>
                                    </th>
                                    <th>Title</th>
                                    <th>Locale</th>

                                </tr>
                            </thead>
                            <tbody>
                            {{{{#each languageFiles}}}}
                                <tr data-id="{{{{this.id}}}}">
                                    <td>
                                        <span class="ldse-option box-only">
                                            <input type="checkbox" name="id[]" value="{{{{this.id}}}}" id="lang-{{{{this.id}}}}-{{{{i}}}}"/>
                                            <label for="lang-{{{{this.id}}}}-{{{{i}}}}">check</label>
                                         </span>
                                    </td>
                                    <td><a href="{{{{previewUrl}}}}" onclick="ICE.linkToItem(this.href, '{{{{this.id}}}}'); return false;">{{{{forceBreak this.title}}}}</a></td>
                                    <td>{{{{this.locale}}}}</td>
                                </tr>
                           {{{{/each}}}}
                           </tbody>
                        </table>
                    </dd>
                </dl>
                {{{{else}}}}
                    <dl>
                        <dt>
                            <label>Translations: None</label>
                        </dt>
                    </dl>
                {{{{/if}}}}
                {{{{#if referenceFiles.length }}}}
                <dl>
                    <dt>
                        <label>Teasers:</label>
                    </dt>
                    <dd>
                        <table class="ldse-table">
                            <thead>
                                <tr>
                                    <th>
                                        <span class="ldse-option box-only">
                                            <input type="checkbox" class="checkall" id="teaser-checkall{{{{i}}}}"/>
                                            <label for="teaser-checkall{{{{i}}}}">check</label>
                                         </span>
                                    </th>
                                    <th>Title</th>
                                    <th>Locale</th>
                                </tr>
                            </thead>
                            <tbody>
                            {{{{#each referenceFiles}}}}
                                <tr data-id="{{{{this.id}}}}">
                                    <td>
                                        <span class="ldse-option box-only">
                                            <input type="checkbox" name="id[]" value="{{{{this.id}}}}" id="teaser-{{{{this.id}}}}-{{{{i}}}}"/>
                                            <label for="teaser-{{{{this.id}}}}-{{{{i}}}}">check</label>
                                         </span>
                                    </td>
                                    <td><a href="{{{{previewUrl}}}}" onclick="ICE.linkToItem(this.href, '{{{{this.id}}}}'); return false;">{{{{forceBreak this.title}}}}</a></td>
                                    <td>{{{{this.locale}}}}</td>
                                </tr>
                           {{{{/each}}}}
                           </tbody>
                        </table>
                    </dd>
                </dl>
                {{{{else}}}}
                    <dl>
                        <dt>
                            <label>Teasers: None</label>
                        </dt>
                    </dl>
                {{{{/if}}}}
                <hr class="ldse-fullbleed"/>
            {{{{/loop}}}}
            <dl>
                <dt>
                    <label for="reason">Reason:</label>
                </dt>
                <dd>
                    <input type="text" name="reason" value="" id="reason"/>
                </dd>
            </dl>
            <div class="ldse-form-buttons">
                <button class="ldse-button destructive ldse-icon-trash">Remove</button>
                <button class="ldse-button ldse-icon-x cancel">Cancel</button>
            </div>
        </form>
    </script>
};

declare function publish-template(
    $step as element(ldse:step),
    $id as xs:string
) as item()* {
    <script class="handlebars-template" id="{ $id }" type="text/x-handlbars-template" xmlns="">
        <header class="ldse-section--header">
            <h2>Publish {{{{checkedCount}}}} Documents</h2>
        </header>
        <form class="ldse-section--body ldse-form">
            {{{{#loop this.files}}}}
                <input type="hidden" name="id[]" value="{{{{this.id}}}}"/>
                <h3>Document {{{{iPlus1}}}} of {{{{checkedCount}}}}: {{{{this.title}}}}  ({{{{this.previewLocale}}}})</h3>
                {{{{#if languageFiles.length }}}}
                <dl>
                    <dt>
                        <label>Translations:</label>
                    </dt>
                    <dd>
                        <table class="ldse-table">
                            <thead>
                                <tr>
                                    <th>
                                        <span class="ldse-option box-only">
                                            <input type="checkbox" class="checkall" id="lang-checkall{{{{i}}}}"/>
                                            <label for="lang-checkall{{{{i}}}}">check</label>
                                         </span>
                                    </th>
                                    <th>Title</th>
                                    <th>Locale</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                            {{{{#each languageFiles}}}}
                                <tr data-id="{{{{this.id}}}}">
                                    <td>
                                        <span class="ldse-option box-only">
                                            <input type="checkbox" class="always-check-all" name="id[]" value="{{{{this.id}}}}" id="lang-{{{{this.id}}}}-{{{{i}}}}"/>
                                            <label for="lang-{{{{this.id}}}}-{{{{i}}}}">check</label>
                                         </span>
                                    </td>
                                    <td><a href="{{{{previewUrl}}}}" onclick="ICE.linkToItem(this.href, '{{{{this.id}}}}'); return false;">{{{{forceBreak this.title}}}}</a></td>
                                    <td>{{{{this.locale}}}}</td>
                                    <td>{{{{this.status}}}}</td>
                                </tr>
                           {{{{/each}}}}
                           </tbody>
                        </table>
                    </dd>
                </dl>
                {{{{else}}}}
                    <dl>
                        <dt>
                            <label>Translations: None</label>
                        </dt>
                    </dl>
                {{{{/if}}}}
                <hr class="ldse-fullbleed"/>
            {{{{/loop}}}}
            <div class="ldse-form-buttons">
                <button class="ldse-button primary ldse-icon-check2">Publish</button>
                <button class="ldse-button ldse-icon-x cancel">Cancel</button>
            </div>
        </form>
    </script>
};

declare function publish-templates(
    $step as element(ldse:step),
    $id as xs:string
) as item()* {
    <script class="handlebars-template" id="{ $id }" type="text/x-handlbars-template" xmlns="">
        <header class="ldse-section--header">
            <h2>Publish {{{{checkedCount}}}} Documents</h2>
        </header>
        <form class="ldse-section--body ldse-form">
            {{{{#loop this.files}}}}
                <input type="hidden" name="id[]" value="{{{{this.id}}}}"/>
                <h3>Document {{{{iPlus1}}}} of {{{{checkedCount}}}}: {{{{this.title}}}}  ({{{{this.previewLocale}}}})</h3>
                {{{{#if languageFiles.length }}}}
                <dl>
                    <dt>
                        <label>Translations:</label>
                    </dt>
                    <dd>
                        <table class="ldse-table">
                            <thead>
                                <tr>
                                    <th>
                                        <span class="ldse-option box-only">
                                            <input type="checkbox" class="checkall" id="lang-checkall{{{{i}}}}"/>
                                            <label for="lang-checkall{{{{i}}}}">check</label>
                                         </span>
                                    </th>
                                    <th>Title</th>
                                    <th>Locale</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                            {{{{#each languageFiles}}}}
                                <tr data-id="{{{{this.id}}}}">
                                    <td>
                                        <span class="ldse-option box-only">
                                            <input type="checkbox" class="always-check-all" name="id[]" value="{{{{this.id}}}}" id="lang-{{{{this.id}}}}-{{{{i}}}}"/>
                                            <label for="lang-{{{{this.id}}}}-{{{{i}}}}">check</label>
                                         </span>
                                    </td>
                                    <td><a href="{{{{previewUrl}}}}" onclick="ICE.linkToItem(this.href, '{{{{this.id}}}}'); return false;">{{{{forceBreak this.title}}}}</a></td>
                                    <td>{{{{this.locale}}}}</td>
                                    <td>{{{{this.status}}}}</td>
                                </tr>
                           {{{{/each}}}}
                           </tbody>
                        </table>
                    </dd>
                </dl>
                {{{{else}}}}
                    <dl>
                        <dt>
                            <label>Translations: None</label>
                        </dt>
                    </dl>
                {{{{/if}}}}
                <hr class="ldse-fullbleed"/>
            {{{{/loop}}}}
            <div class="ldse-form-buttons">
                <button class="ldse-button primary ldse-icon-check2">Publish</button>
                <button class="ldse-button ldse-icon-x cancel">Cancel</button>
            </div>
        </form>
    </script>
};
