xquery version "1.0-ml";

import module namespace sens-functs = "http://lds.org/code/shared/lds-edit/sensitive/functions" at "/sensitive/modules/functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "/ice/modules/dynamicForms.xqy";
import module namespace okta = 'http://lds.org/code/cms/modules/okta-library' at "/modules/okta-library.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

declare variable $locale as xs:string := form:getVariable('locale');

let $login := okta:okta-login()
let $thisPageURI as xs:string := '/shared/lds-edit/translation/archive/view-files'

let $has-permission as xs:boolean :=
    if ( ac:has-permission('ldse:view-unpublish-sensitive', $locale, ()) ) then (
        fn:true()
    ) else ( fn:false() )
let $page-title as xs:string := "Sensitive Files"
return (
    if ( $has-permission ) then (
        core:template-apply(
             "Sensitive Items",
             $thisPageURI,
             <page>
                <head>
                    <link rel="stylesheet" href="{$settings:shared-prefix}/shared/lds-edit/translation/resources/styles/translation.css" />
                    <link rel="stylesheet" href="{$settings:shared-prefix}/shared/lds-edit/translation/resources/styles/calendar.css" />
                </head>

                <scripts>
                    <script src="{$settings:shared-prefix}/shared/lds-edit/sensitive/resources/scripts/approval.js"/>
                </scripts>
                <title>{$page-title}</title>
                <content>
                    <form action="" class="ldse-form">
                        <table class="ldse-table ldse-fullbleed">
                            <thead>
                                <tr>
                                    <th>
                  						<span class="ldse-option box-only">
                  							<input type="checkbox" class="styled checkall" id="details-checkall"/>
                  							<label for="details-checkall">Check</label>
                  						</span>
                  					</th>
                  					<th></th>
                                    <th class="hide-large">Type</th>
                                    <th class="hide-small">Root</th>
                                    <th class="sm">Title</th>
                                    <th class="sm">Locale</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody id="sensitive-table-body">
                            {
                                sens-functs:sensitive-table()
                            }
                            </tbody>
                            <input type="hidden" id="dateselected" name="dateselected"/>
                        </table>
                    </form>
                </content>
                <button-groups>
                    <button-group>
                        <button class="ldse-button ldse-responsive-button destructive ldse-icon-unpublish" onclick="unpublishSensitive(); return false;" id="action-approve" status="ldse:unpublish" name="ldse:unpublish" i18n="" style="display:none;">Unpublish</button>
                    </button-group>
                </button-groups>
             </page>
        )
    ) else (
        let $errorMsg as xs:string:="Sorry, you don't have permission to view this page."
        let $errorTitle as xs:string:= "Error!"
        return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/shared/lds-edit/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
    )
)
