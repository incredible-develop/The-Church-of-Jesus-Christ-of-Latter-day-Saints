xquery version "1.0-ml";

import module namespace sman = "http://lds.org/code/shared/lds-edit/riceFunctions" at "/string-manager/modules/stringFunctions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace template = "http://lds.org/shared/lds-edit/template" at "/modules/template.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace sp = "http://lds.org/code/modules/site-properties" at "/modules/site-properties.xqy";
import module namespace okta = 'http://lds.org/code/cms/modules/okta-library' at "/modules/okta-library.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare boundary-space preserve;

declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

declare variable $allLangs as xs:string* := core:get-all-langs();
declare variable $allLocales as xs:string* := core:get-all-locales();
declare variable $allOptions as xs:string* := ($allLangs, $allLocales);
declare variable $site as xs:string? := xdmp:get-request-field('site')[. != ''][1];
declare variable $lang as xs:string? := (xdmp:get-request-field("lang"), "eng")[1];

declare variable $resources as element(resources)* := sman:get-resource-files();

let $login := okta:okta-login()
return
if (ac:has-permission('ldse:edit-doc', '', '')) then (
    let $pageIndex as xs:int := 1
    let $pageSize as xs:int := 25
    let $title as xs:string := "Clone components"
    let $thisPage as xs:string := "shared/lds-edit/string-manager"
    let $pages := for $page in cts:search(/custom-page,
                    cts:and-query((
                    cts:directory-query('/preview/', 'infinity'),
                    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $lang, 'exact'),
                    cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
                    ))
                    )
                  let $uri := $page/@uri/fn:string()
                  where ac:has-permission('ldse:edit-doc', $lang, '', $site)
                  order by $uri
                  return <option value="{$uri}">{$uri}</option>
    let $destinationPages :=
        for $page in cts:search(/custom-page,
                    cts:and-query((
                        cts:directory-query('/preview/', 'infinity'),
                        cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $lang, 'exact'),
                        cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
                    ))
                            )
                let $uri := $page/@uri/fn:string()
                let $templateId := $page/ldse:ldse-meta/ldse:form-options/ldse:templateId/fn:string()
                let $templateSections :=
                        for $region in sp:get-templates($templateId)/region
                        where fn:not(fn:exists($region/@fixed-order)) or $region/@fixed-order eq 'false'
                        return element pageRegion {attribute uri {$uri}, $region/@id, $region/@title }
                where ac:has-permission('ldse:edit-doc', $lang, '', $site)
                order by $uri
                return for $templateSection in $templateSections
                       return <option value="{$templateSection/@uri||'|'||$templateSection/@id}">{$templateSection/@uri||'|'||$templateId||':'||$templateSection/@title}</option>

    let $scripts as element(scripts) :=
        <scripts>
            <script src="{$settings:shared-prefix}/ice/resources/script/cloneComponents.js"></script>
            {sman:build-bundle-scripts()}
            {sman:build-component-list-for-cloning()}
        </scripts>

    let $content as element(content) :=
        <content>
            <section class="ldse-section ldse-filters ldse-clearfix">
                <header class="ldse-section--header">
                    <h2><a href="#filter-body" class="ldse-icon-ko-tri-up">Filters</a></h2>
                </header>
                <div class="ldse-section--body" id="filter-body">
                    <form class="ldse-rowFix ldse-makeCols ldse-form">
                        <div class="ldse-block filters ldse-last" id="fromPageFilterBox" >
                            <header>
                                <h3>Clone from page</h3>
                            </header>
                            <div class="ldse-block--body" style="display:block;">
                                <select id="fromPage" class="fromPage-box">
                                    <option value="" msindex="0">Select a page</option>
                                    {$pages}
                                </select>
                            </div>
                        </div>
                        <div class="ldse-block filters ldse-last" id="toPageFilterBox" >
                            <header>
                                <h3>Destination Page</h3>
                            </header>
                            <div class="ldse-block--body" style="display:block;">
                                <select name="" class="toPage-box cloneToSite required">
                                    <option value="" msindex="0">Select a page</option>
                                    {$destinationPages}
                                </select>
                            </div>
                        </div>
                    </form>
                </div>
            </section>
            {
                sman:build-component-list-section-for-cloning()
            }
        </content>


    return
        core:template-apply(
            $title,
            $thisPage,
            <page>
                {$content}
                {$scripts}
                <options></options>

            </page>
        )
) else (
    template:error-access-denied("Error!", "Sorry, you don't have permission to view this page.")
)
