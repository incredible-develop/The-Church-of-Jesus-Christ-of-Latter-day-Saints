xquery version "1.0-ml";

import module namespace resource = "http://lds.org/code/shared/lds-edit/fast-i18n" at "../../../../rice/modules/fast-i18n.xqy";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../../modules/utility-functions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../../modules/access-control-functions.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "../../../modules/iceFunctions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../../modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../../modules/ldse-core.xqy";

declare boundary-space preserve;
declare option xdmp:mapping "true";

declare variable $host as xs:string := $util:host;

declare variable $country as xs:string? := util:escape-chars(xdmp:get-request-field("country", ""));
declare variable $preLocale as xs:string := util:escape-chars(xdmp:get-request-field("locale", "eng"));
declare variable $locale as xs:string := if ($country ne '') then (fn:concat($preLocale,'-',$country)) else ($preLocale);
           
declare variable $sharedPrefix as xs:string? := $settings:shared-prefix;

declare variable $bundle as xs:string := util:escape-chars(xdmp:get-request-field("bundle", ""));
declare variable $pageUri as xs:string? := util:escape-chars(xdmp:get-request-field("pageUri"))[. != ""];
declare variable $key as xs:string := util:escape-chars(xdmp:get-request-field("key", ""));
declare variable $currentPage as xs:string := util:escape-chars(xdmp:get-request-field("currentPage", ""));
declare variable $currentUri as xs:string := ( $pageUri, util:escape-chars(xdmp:url-decode(xdmp:get-request-field("uri", ""))) )[1];
declare variable $hide-seo-title as xs:string := util:escape-chars(xdmp:get-request-field("hideTitle", ""));
declare variable $seo-title-passthru as xs:string := util:escape-chars(xdmp:get-request-field("seoTitle", ""));

declare variable $custom-page as element(custom-page)? := ice:get-custom-page($currentUri, $locale);
declare variable $seo-title as xs:string* := $settings:seo-title;
declare variable $seo-desc as xs:string* := $settings:seo-desc;
declare variable $bundles as xs:string* := fn:tokenize($bundle, ",");
declare variable $keys as xs:string* := fn:tokenize($key, ",");
declare variable $prepareCustomPage as xs:boolean := fn:empty($custom-page/resources);

if (ac:has-permission("ldse:edit-rice", $locale, $currentPage)
	or (
		$currentPage = "/form"
		and ac:has-permission("ldse:edit-rice-contentEditor", (), ())
	)
) then (
    xdmp:set-response-content-type( "text/html" ),
    <div id="resourceFrom" style="width: inherit; height: inherit; overflow-y:scroll;">
        <form method="post" action="{$sharedPrefix}/ice/resources/ajax/resource/updateResource?lang=eng&amp;locale={$preLocale}&amp;country={$country}">
            <input type="hidden" name="currentPage" value="{$currentPage}"/>
            <input type="hidden" name="currentUri" value="{$currentUri}"/>
            <table class="iceEditor">
                <tr>
                    <td class="header">Location</td>
                    <td class="header">Key</td>
                    <td class="header">Value</td>
                </tr>
                {
                    if (fn:count($bundles) = fn:count($keys)) then (
                        for $b as xs:string at $i in $bundles
                        let $k as xs:string := $keys[$i]
                        let $existing as item()* := 
                            if ($b eq "custom-page") then (
                                resource:get-page-string-value($custom-page, $k)
                            ) else (
                                resource:get-value($locale, fn:concat($b, ":", $k))
                            )
                        let $clone as item()* := 
                            for $n as item() in $existing return (
                                typeswitch ( $n )
                                case element() return (element {fn:node-name($n)} {$n/@*, $n/node() } )
                                case text() return ( text { $n } )
                                case xs:string return ( fn:string($n) )
                                default return ( $n )
                            )
                        
                        let $quoted-existing as xs:string? := fn:normalize-space(xdmp:quote($clone))
                        let $existing as item()* := 
                            if (fn:count($existing) = 1 and fn:starts-with($quoted-existing, "?") and fn:ends-with($quoted-existing, "?")) then (
                                ""
                            ) else (
                                $quoted-existing
                            )
                        let $preparePage as item()* := 
                            if ($b eq "custom-page" and $prepareCustomPage) then (
                                xdmp:set($prepareCustomPage, fn:false()),
                                resource:prepare-page-for-resources($locale, $currentUri, $custom-page)
                            ) else ()
                        let $is-seo-title as xs:boolean := ice:match-regex($k, $seo-title)
                        let $is-seo-desc as xs:boolean := fn:not($is-seo-title) and ice:match-regex($k, $seo-desc)
                        let $location as xs:string? := 
                                        if ($b ne "custom-page") then (
                                            cts:uris(core:get-site-root(),(),
                                                cts:and-query((
                                                    core:get-filter-query(),
                                                     cts:element-query(xs:QName("resources"),
                                                        cts:and-query((
                                                            cts:element-value-query(xs:QName('name'),$b, 'exact'),
                                                            cts:element-attribute-value-query(xs:QName('resources'),xs:QName('locale'),$locale, 'exact')
                                                        ))
                                                    )
                                                ))
                                            )
                                         ) else (
                                             xdmp:node-uri($custom-page)
                                         )
                        let $order as xs:int := if ( $is-seo-title) then (1) else if ( $is-seo-desc ) then (2) else (3)
                        order by $order ascending        
                        return (
                            if ( fn:exists($location) ) then (
                              <tr>
                                    <td class="top" style="font-size: 10px; width:150px;">{$location}</td>
                                    <td class="top">{
                                        if ( $is-seo-title ) then (
                                            "SEO Title ", 
                                            <span class="ldse-info-button ldse-icon-ko-info ldse-icon ldse-toggle-content ldse-show-seoT-info">Show Info</span>,
                                            <div id="contentTitle-2129_help_info_text" class="ldse-info-text ldse-infoT-text" style="display: none;">Click <a href="https://preview.lds.org/lds-edit-help/article/view/107" target="_blank">here</a> for more information</div>
                                        ) else if ( $is-seo-desc ) then (
                                            "Meta Description ", 
                                            <span class="ldse-info-button ldse-icon-ko-info ldse-icon ldse-toggle-content ldse-show-seoD-info">Show Info</span>,
                                            <div id="contentTitle-2129_help_info_text" class="ldse-info-text ldse-infoD-text" style="display: none;">Click <a href="https://preview.lds.org/lds-edit-help/article/view/108" target="_blank">here</a> for more information</div>
                                        ) else (
                                            $k
                                        )
                                    }</td>
                                    <td>
                                        <input type="hidden" name="bundle" value="{$b}"/>
                                        <input type="hidden" name="key" value="{$k}"/>
                                        {
                                            if ( $hide-seo-title = 'true' and $is-seo-title ) then (
                                                <input type="hidden" name="seo-title-key" value="{fn:concat($b, ':', $k)}"/>
                                            ) else ()
                                        }
                                        {
                                            if ( $is-seo-title ) then (
                                                element input { 
                                                    attribute type {"text" },
                                                    attribute class {"seo-title"},
                                                    attribute onkeyup {"RICE.onChange();"},
                                                    attribute name {"newValue"} ,
                                                    if ( $hide-seo-title = 'true' ) then (  
                                                        attribute value { $seo-title-passthru },
                                                        attribute style { "width:80%;color: #999;" },
                                                        attribute readonly { "readonly" }
                                                    ) else (
                                                        attribute value { $existing },
                                                        attribute style { "width:80%;" }
                                                    )
                                                },
                                                <span class="ldse-seo-title-message" />
                                            ) else if ( $is-seo-desc ) then (
                                                <textarea class="rice-text" onkeyup="RICE.onChange();" type="text" name="newValue" value="" rows="3" cols="50">{$existing}</textarea>,
                                                <span class="ldse-seo-desc-message" />
                                            ) else (
                                                <textarea class="rice-text" onkeyup="RICE.onChange();" type="text" name="newValue" value="" rows="3" cols="50">{$existing}</textarea>
                                            )
                                        }
                                    </td>
                                </tr>,
                                if ( $is-seo-desc ) then (
                                    <tr>
                                        <td></td>
                                        <td>Snippet Preview</td>                                  
                                        <td>
                                            <span class="ldse-seo-title">{ if ( $hide-seo-title = 'true' ) then ( $seo-title-passthru ) else () }</span>
                                            <span class="ldse-seo-url">{if ( fn:contains($currentUri, $sharedPrefix) ) then ( fn:concat($settings:live-domain, $currentUri) ) else ( fn:concat($settings:live-domain, $sharedPrefix, $currentUri) ) }</span>
                                            <span class="ldse-seo-description" onkeyup="RICE.onChange();"/>
                                        </td>
                                    </tr>
                                ) else ()
                            ) else ()
                        )                        
                    ) else ("No Hidden Text to Edit")
                }
                <tr>
                    <td colspan="4" style="text-align: center;"><input style="float: none; width: auto; height: 40px; min-height: 0px;" class="ldse-button ldse-primary" id="saveResource" type="submit" value="Save"/></td>
                </tr>
            </table>
        </form>
        <script type="text/javascript">jQuery(document).ready(function() {{ RICE.onChange(); }} );</script>
    </div>
) else (
        let $errorMsg as xs:string:="Sorry, You don't have permission" 
        let $errorTitle as xs:string:= "Access Denied!"
        return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
    )
