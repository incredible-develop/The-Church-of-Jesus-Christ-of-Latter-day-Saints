xquery version "1.0-ml";

import module namespace template = "http://lds.org/shared/lds-edit/template" at "../modules/template.xqy";
import module namespace tArchive = "http://lds.org/code/shared/lds-edit/archiveFunctions" at "../translation/archives/modules/archiveFunctions.xqy";
import module namespace tranSettings = "http://lds.org/code/shared/lds-edit/translation-settings" at "../translation/modules/translation-settings.xqy";
import module namespace sens-functs = "http://lds.org/code/shared/lds-edit/sensitive/functions" at "modules/functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../modules/ldse-core.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../modules/access-control-functions.xqy";
import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../ice/modules/dynamicForms.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

declare variable $locale as xs:string := form:getVariable('locale');

let $thisPageURI as xs:string := '/shared/lds-edit/translation/archive/view-files'

let $has-permission as xs:boolean :=
    if ( ac:has-permission('ldse:view-approve-sensitive', $locale, ()) ) then (
        fn:true()
    ) else ( fn:false() )
let $page-title as xs:string := "Sensitive Files Needing Your Approval"
return (
    if ( $has-permission ) then (
        core:template-apply(
             "Needed Approvals",
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
                                sens-functs:approval-table()
                            }
                            </tbody>
                            <input type="hidden" id="dateselected" name="dateselected"/>
                        </table>
                    </form>
                </content>
                <button-groups>
                    <button-group>
                        <button class="ldse-button ldse-responsive-button secondary ldse-icon-send" onclick="approveSensitive(); return false;" id="action-approve" status="ldse:approve-items" name="ldse:approve-items" i18n="" style="display:none;">Approve</button>
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
