xquery version "1.0-ml";

import module namespace sman = "http://lds.org/code/shared/lds-edit/riceFunctions" at "/string-manager/modules/stringFunctions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace template = "http://lds.org/shared/lds-edit/template" at "/modules/template.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
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
    let $title as xs:string := "Clone from "||$site||'  '||$lang
    let $thisPage as xs:string := "shared/lds-edit/string-manager"
    let $head as element(head) :=
        <head>
            <link rel="stylesheet" href="{$settings:shared-prefix}/translation/resources/styles/calendar.css" />
        </head>

    let $scripts as element(scripts) :=
        <scripts>
            <script src="{$settings:shared-prefix}/ice/resources/script/cloneMultiplePages.js"></script>
            {sman:build-bundle-scripts()}
            {sman:build-bundle-page-template-for-cloning()}

        </scripts>

    let $content as element(content) :=
        <content>
            <section class="ldse-section ldse-filters ldse-clearfix">
                <header class="ldse-section--header">
                    <h2><a href="#filter-body" class="ldse-icon-ko-tri-up">Filters</a></h2>
                </header>
                <div class="ldse-section--body" id="filter-body">
                    <form class="ldse-form ldse-search ldse-box ldse-tableize" action="">
                        <span class="ldse-tableize--fill">
                            <input type="text" placeholder="Search Strings" id="filter-search" class="ldse-square-right"/>
                        </span>
                        <span>
                            <input type="button" value="&#xe40a;" class="ldse-square-left" id="questionButton"/>
                        </span>
                    </form>
                    <form class="ldse-rowFix ldse-makeCols ldse-form">
                        <div class="ldse-block filters ldse-first" id="bundleNameBox">
                            <header id="bundleName">
                                <h3>Resource Name or Page URI</h3>
                                <a href="#d" class="ldse-icon-ko-add ldse-icon">Resource Name or Page URI</a>
                            </header>
                            <div class="ldse-block--body">
                                <div class="repeater table">
                                    <dl class="repeat-this repeaterWrapper">
                                        <dt>
                                            <a href="#d" class="remover ldse-icon-ko-remove ldse-icon disabled remove-bundles">Remove</a>
                                        </dt>
                                        <dd>
                                            <input type="text" name="Bundle Name" class="bundleName"/>
                                        </dd>
                                    </dl>
                                </div>
                                <a href="#d" class="ldse-adder adder add-bundle-name ldse-icon-ko-add">Add Filter</a>
                            </div>
                        </div>
                        <div class="ldse-block filters ldse-last" id="toSiteFilterBox" >
                            <header>
                                <h3>Destination Site</h3>
                            </header>
                            <div class="ldse-block--body" style="display:block;">
                                <select name="" class="toSite-box cloneToSite required">
                                    <option value="" msindex="0">Select a Site</option>
                                    {for $sites in cts:search(/siteProperties, ())
                                        for $supportedLanguage in cts:search(/supportedLanguages,
                                                cts:and-query((
                                                    cts:directory-query('/preview/', 'infinity'),
                                                    cts:element-attribute-value-query(xs:QName('supportedLanguages'), xs:QName('site'), $sites/@site, 'exact')
                                                ))
                                            )
                                        for $_lang in $supportedLanguage/language/@key
                                        let $_site := $supportedLanguage/@site/fn:string()
                                        let $result := $_site || '|' || $_lang
                                        where ($_site) and ac:has-permission('ldse:edit-doc', $_lang, '', $_site)
                                        order by $_site, $_lang
                                        return <option value="{$result}">{$result}</option>
                                    }
                                </select>
                            </div>
                        </div>
                    </form>
                </div>
                <div id="filterButtons">
                    <div class="ldse-form ldse-fullbleed ldse-section--body">
                        <hr/>
                        <div class="ldse-fullbleed ldse-section--body">
                            <div class="ldse-table-buttons">
                                <button id="applyFilterBtn" class="ldse-button primary ldse-icon-check2">Apply Filters</button>
                                <button id="cancelFilterBtn" class="ldse-button ldse-icon-x">Cancel</button>
                                <button id="clearFilterBtn" class="ldse-button secondary ldse-icon-ko-x ldse-icon">Clear</button>
                            </div>
                        </div>
                    </div>
                </div>
            </section>
            {
                sman:build-bundle-page-section-for-cloning()
            }
        </content>


    return
        core:template-apply(
            $title,
            $thisPage,
            <page>
                {$head}
                {$content}
                {$scripts}
                <options></options>

            </page>
        )
) else (
    template:error-access-denied("Error!", "Sorry, you don't have permission to view this page.")
)
