xquery version "1.0-ml";

module namespace form-functs = "http://lds.org/code/shared/lds-edit/form/form-functions";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../modules/ldse-meta.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "../../ice/modules/iceFunctions.xqy";
import module namespace translation = "http://lds.org/code/shared/lds-edit/translationFunctions" at "../../translation/modules/translationFunctions.xqy";
import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../../ice/modules/dynamicForms.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";
import module namespace correlation = "http://lds.org/code/shared/lds-edit/correlation" at "../../correlation/modules/correlation-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace its = "http://www.w3.org/2005/11/its";
declare namespace hldse = "http://lds.org/code/lds-edit/history";

declare option xdmp:mapping "true";

declare variable $site as xs:string := xdmp:get-request-field('site');

declare function form-functs:translation-table(
    $id as xs:string?,
    $form-name as xs:string,
    $option as xs:string?
) as item()* {
    let $form as element(ldse:formTemplate)? := form:getFormTemplate($form-name)
    let $doc-title as element(ldse:document-title)? := $form/ldse:document-title
    let $eng-id as xs:string := fn:replace($id, "^(.*)\-.*$", "$1-eng")
    let $orig-file as item()? := ldsemeta:get-file-by-id($eng-id)
    let $files as item()* := ldsemeta:get-translated-files($eng-id)
    let $all as item()* := ($files, $orig-file)
    return (
        form-functs:get-other-langs($all, $doc-title, $id)
     )
};

declare function form-functs:get-other-langs(
    $files as item()*,
    $doc-title as element(ldse:document-title)?,
    $orig-id as xs:string
) as element(tr)*{ 
    for $file as item()* at $count in $files
    let $locale as xs:string? := ldsemeta:get-document-locale($file)
    let $id as xs:string? := ldsemeta:get-document-id($file)
    let $options as element()? := ldsemeta:get-form-options($file)
    let $uri as xs:string? := ldsemeta:get-document-uri($file)
    let $date-returned as xs:string? := 
        if ($locale = "eng") then (
            "Original"
        ) else (fn:format-dateTime(ldsemeta:get-translation-returned($file)/@date, "[D01] [MN,*-3] [Y0001]"))
    let $date-sent as xs:string? := 
        if ($locale = "eng") then (
            "Original"
        ) else (fn:format-dateTime(ldsemeta:get-translation-sent($file)/@date, "[D01] [MN,*-3] [Y0001]"))
    let $options as xs:string? := 
        if (fn:exists($options/form)) then (
            ice:csv-variables($options)
        ) else (xdmp:get-request-field("option"))
    let $title as xs:string? :=
        if (fn:exists($doc-title) and fn:not($doc-title = "") ) then (
            fn:normalize-space(
                fn:string-join(
                    for $n as item() in util:value($file, $doc-title)
                    return fn:string($n)
                , ' ')
            )
        ) else (
            fn:string(fn:normalize-space(ldsemeta:get-document-title($file)))
        )
    let $site as xs:string := xdmp:get-request-field('site')[1]
    let $is-custom-page as xs:boolean := typeswitch($file) case element(custom-page) return fn:true() default return fn:false()
    where fn:exists($id) and fn:not($id = "")
    order by fn:not($locale = 'eng'), $locale ascending
    return ( 
        <tr class="originalTR" data-editable="{fn:not($id = $orig-id)}" data-fileid="{$id}" data-locale="{$locale}" data-options="{$options}" data-uri="{$uri}" data-page="{$uri}">
            <td>
            	<span class="ldse-option box-only">
            		{
				        if(ac:has-permission("ldse:translation-checkbox", $locale, $uri))
				        then (
				        	<input type="checkbox" name="" value="" id="box-{$count}" class="rowSelect"/>,
            				<label for="box-{$count}">Check</label>
            			)
				        else ()
            		}
            	</span>
            </td>
            <td><a href="{$uri}?lang={$locale}&amp;site={ $site }" onclick="ICE.linkToItem(this, '{ $id }'); return false;" class="ldse-icon-preview ldse-icon big">Preview</a></td>
            <td  data-sort="status" class="status">{ldsemeta:get-document-status($file)}</td>
            <td data-sort="title" class="hide-small title">
            {
                if ($id = $orig-id) then (
                    $title    
                ) else if ( $is-custom-page ) then (
                    let $url as xs:string := core:build-url( fn:concat($settings:shared-prefix, "/page-manager/page-editor"), $locale, '&amp;uri=' || $uri || '&amp;site=' || $site)
                    return (
                        <a href="{$url}">{ $title }</a>
                    )
                ) else (
                    <a onclick="editFileLink(this);">{  $title }</a>
                )
            }
            </td>
            <td data-sort="locale" class="locale">{$locale}</td>
            <td data-sort="dateReturned" class="dateReturned datesort">{$date-returned}</td>
            <td data-sort="dateSent" class="hide-large dateSent datesort">{$date-sent}</td>
            <td data-sort="component" class="hide-med component">{fn:string(ldsemeta:get-translation-returned($file)/@component-id)}</td>
            <td data-sort="filename" class="hide-large filename">{util:file-name($file)}</td>
        </tr>
    ) 
};

declare function form-functs:get-follower($current-user as xs:string, $id as xs:string, $locale as xs:string) as xs:string* {
    cts:element-attribute-values(xs:QName('hldse:following'), xs:QName('username'), (), (),
        cts:and-query((
            cts:element-attribute-value-query(xs:QName('hldse:document'), xs:QName('id'), $id, 'exact'),
            cts:element-attribute-value-query(xs:QName('hldse:document'), xs:QName('locale'), $locale, 'exact')
        ))
    )
};

declare function form-functs:builds-stakeholder-select($stakeholder as xs:string?) as element()* {
    for $user as element() in form-functs:get-stakeholders()
    let $selected-stakeholder as xs:string := xs:string($user/ldse:name)
    let $display-name as xs:string := 
        if ( fn:empty($user/ldse:name/@display) or $user/ldse:name/@display = "" ) then (
            $selected-stakeholder
        ) else (
            $user/ldse:name/@display
        )
    return (
        <option value="{$selected-stakeholder}"> { 
            if ( $stakeholder = $selected-stakeholder ) then (
                attribute selected { "selected" }
            ) else (),
            $display-name
       }</option>
    )
};

declare function form-functs:builds-other-stakeholder-select($stakeholder as xs:string?, $file as element()?) as element()* {
    let $other-stakeholders as element()? := ldsemeta:get-sensitive($file)
    for $user as element() in form-functs:get-stakeholders()
    let $selected-stakeholder as xs:string := xs:string($user/ldse:name)
    let $name as xs:string := 
        if ( fn:empty($user/ldse:name/@display) or $user/ldse:name/@display = "" ) then (
            $selected-stakeholder
        ) else (
            $user/ldse:name/@display
        )
    let $selected as xs:boolean? := 
        for $email-stakeholder as element() in $other-stakeholders/ldse:emails/ldse:email
        where $email-stakeholder/@name = $selected-stakeholder
        return (
            fn:true()
        )
    where fn:not($stakeholder = $selected-stakeholder)
    order by $name
    return (
        <option value="{$selected-stakeholder}">
        { 
            if ( $selected ) then (
                attribute selected { "selected" }
            ) else (),
            $name 
        }
        </option>
    )
};

declare function form-functs:get-stakeholders() as element()* {
    cts:search(/*,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName("ldse:role"), xs:QName("name"), "stakeholder", "exact")
        ))
    )            
};

declare function form-functs:get-stakeholders($file as element()?, $sensitive as xs:string?, $is-submitter as xs:boolean, $is-submitted as xs:boolean) as element()* {
    <section  id="sensitive-content-warning">
		<section class="ldse-section ldse-summary ldse-info-banner warning">
			<div class="ldse-section--body">
				<span class="ldse-icon-ko-warning ldse-icon ldse-info-banner-icon">Warning</span>
                    <div class="ldse-warning-messages-div">
                    {
                        if ( $sensitive = "yes" ) then (
                            <div class="ldse-warning-message-div">
                                <h3 class="ldse-warning-message-title">Sensitive Content</h3>
                                <div>This item has been marked as containing sensitive content.</div>
                            </div>
     					) else (),
    				    if ( $is-submitter and $is-submitted ) then (
               				<div class="ldse-warning-message-div">
               				    <h3 class="ldse-warning-message-title">Content has been submitted</h3>
               				    <div>Any changes to the content will not be saved.</div>
               			    </div>
               			) else (),
                        <div class="ldse-warning-message-div">{correlation:build-status-info-section($file)}</div>
					}
				</div>
			</div>
		</section>
	</section>
};
