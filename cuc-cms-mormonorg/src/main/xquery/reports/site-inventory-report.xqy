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

declare variable $resources as element(resources)* := sman:get-resource-files();

let $login := okta:okta-login()
return
if (ac:has-permission('ldse:view-reports-admin', '', '')) then (
    let $title as xs:string := "Site Inventory Report"
    let $thisPage as xs:string := "shared/lds-edit/reports/site-inventory-report"
    let $head as element(head) :=
        <head>
        </head>

    let $scripts as element(scripts) :=
        <scripts>
            <script src="{$settings:shared-prefix}/reports/resources/scripts/pageStatusReports.js"></script>
        </scripts>

    let $siteLocales := for $i in fn:distinct-values(ac:site-locales-by-permission("ldse:view-reports-admin"))
                        return if(fn:contains($i[1],('missionary-portal-40')) or fn:contains($i[1],('my-plan')) or fn:contains($i[1],('unified'))) then ()
                               else $i

    let $content as element(content) :=
        <content>
            <section class="ldse-section ldse-filters ldse-clearfix">
                <header class="ldse-section--header">
                    <h2><a href="#filter-body" class="ldse-icon-ko-tri-up">Filters</a></h2>
                </header>
                <div class="ldse-section--body" id="filter-body">
                    <form class="ldse-rowFix ldse-makeCols ldse-form">
                        <div class="ldse-block filters" id="siteLangFilterBox">
                            <header id="siteLangFilter">
                                <h3>Site and Language</h3>

                            </header>
                            <div class="ldse-block--body" id="paramList">
                                <select name="" multiple="multiple" class="multiselect site-language-box">
                                    {
                                        <option value="" msindex="0">Select a site</option>,
                                        <option value="all | all">all sites | all languages</option>,
                                        for $site-lang as xs:string in fn:distinct-values($siteLocales)
                                        return
                                            <option value="{$site-lang}">{(
                                                $site-lang
                                            )}
                                            </option>

                                    }
                                </select>
                            </div>
                        </div>
                    </form>
                </div>
            </section>
        </content>


    return
        core:template-apply(
            $title,
            $thisPage,
            <page>
                {$head}
                {$content}
                {$scripts}
                <button-groups>
                    <button-group>
                        <button id="pageStatusReportButton" class="ldse-button primary ldse-icon-download ldse-modal-trigger" onclick="SM.updatePageStatusExportType();  modal.trigger(&quot;close&quot;); SM.siteInventoryReportExport(); return false;">Save Report</button>
                    </button-group>
                </button-groups>
                <options></options>
            </page>
        )
) else (
    template:error-access-denied("Error!", "Sorry, you don't have permission to view this page.")
)
