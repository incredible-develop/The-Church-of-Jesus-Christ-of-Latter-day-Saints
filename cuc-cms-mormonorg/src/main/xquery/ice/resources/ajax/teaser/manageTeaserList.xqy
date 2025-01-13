xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../../modules/utility-functions.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "../../../modules/iceFunctions.xqy";
import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../../../modules/dynamicForms.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../../modules/access-control-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../../../modules/ldse-meta.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../../modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../../modules/ldse-core.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

(: MAIN PARAMS :)
declare variable $fileid as xs:string* := xdmp:get-request-field("fileid");
declare variable $formName as xs:string := xdmp:get-request-field("formName");
declare variable $currentPage as xs:string := xdmp:get-request-field("currentPage");
declare variable $options as xs:string := xdmp:get-request-field("option");
declare variable $publishType as xs:string := xdmp:get-request-field("publishType");
declare variable $locale as xs:string := form:getVariable('locale');

(: *********** :)
(:Get location from the teaser that was used to call the manager :)
let $location as xs:string := cts:search(/teaser[@id = $fileid], core:get-filter-query())/@location
(:Get all teasers that match the curren teasers local, current page, and location^ :)
let $allTeasers as node()* := ice:findSiblingTeasers(xs:QName('teaser'), $locale, $currentPage, $location)
(:The nodes that will be used to display text inside of the manager. If none are passed default to title and body :)
let $displayNodes as xs:string* := fn:tokenize(xdmp:url-decode(form:getVariable('teaser-manager')), "\|")
let $displayNodes as xs:string* := if(fn:count($displayNodes) > 0)then($displayNodes)else(("title", "body"))
let $buttonOptions as xs:string* := fn:tokenize(xdmp:url-decode(form:getVariable('manager-options')), "\|")
let $buttonOptions as xs:string* := if(fn:count($buttonOptions) > 0)then($buttonOptions)else(("edit","remove","delete"))
return (
    if (ac:has-permission('ldse:teaser-manager', $locale, $currentPage)) then (
        xdmp:set-response-content-type( "text/html" ),
        <div>
            <link rel="stylesheet" type="text/css" media="all" href="{$settings:shared-prefix}/ice/resources/styles/screen.css" />
            <div id="ice-dialog" title="Teaser Manager" class="padding-sm">
                {if($buttonOptions eq 'add')then(<button type="button" onclick="ICE.openForm({xdmp:to-json-string($locale)}, '', 'add', {xdmp:to-json-string($formName)}, {xdmp:to-json-string($currentPage)}, {xdmp:to-json-string($currentPage)}, {xdmp:to-json-string($options)}); ICE.teaserManagerChange = true; return false;">Add</button>)else()}
                <form action="" method="post" enctype="multipart/form-data" class="ixf-form">
                    <input type="hidden" name="newOrder" id="manageTeaser-newOrder" />
                    <fieldset class="margin-bottom-sm float-left"  style="width: 845px; background: white; border: 2px inset #CCC;">
                        <ul class="sortable ui-sortable teaserManager">
                        {
                            for $t as element() in $allTeasers
                            let $image as xs:string? := ($t//image, $t//@img, $t//img/@src)[1]
                            let $tID as xs:string? := $t/@id
                            let $displayText as xs:string* := $t/node()[local-name(.) = $displayNodes]
                            let $displayText as xs:string? := fn:string-join($displayText, " ")
                            let $isPublished as xs:boolean? := ldsemeta:is-published($t)
                            let $correlationCanPublish as xs:boolean := ldsemeta:correlation-can-publish($t)
                            order by fn:number($t/@sequence)
                            return
                            (
                                <li data-id="{$tID}" sequence="{$t/@sequence}">{
                                    if($buttonOptions eq 'edit' and ac:has-permission('ldse:edit-doc', $locale, $currentPage) ) then (
                                        <button onclick="window.location='{$settings:shared-prefix}/form?lang={util:js-number-escape($locale)}&amp;country=&amp;id={$tID}&amp;status=edit&amp;uri={util:js-number-escape($currentPage)}&amp;page={util:js-number-escape($currentPage)}&amp;option={util:js-number-escape($options)}'; return false;">Edit</button>
                                    )else(),
                                    if($buttonOptions eq 'remove' and ac:has-permission('ldse:remove-doc', $locale, $currentPage) ) then (
                                        <button type="button" onclick="ACT.item('ldse:remove', {xdmp:to-json-string($currentPage)}, {xdmp:to-json-string($locale)}, {xdmp:to-json-string($publishType)}, '{$tID}'); ICE.teaserManagerDRHold= '{$tID}'; ICE.teaserManagerChange = true; return false;">Remove</button>
                                    )else(),
                                    if($buttonOptions eq 'delete' and ac:has-permission('ldse:delete-doc', $locale, $currentPage) ) then (
                                        <button type="button" onclick="ACT.item('ldse:delete', {xdmp:to-json-string($currentPage)}, {xdmp:to-json-string($locale)}, {xdmp:to-json-string($publishType)}, '{$tID}'); ICE.teaserManagerDRHold= '{$tID}'; ICE.teaserManagerChange = true; return false;">Delete</button>
                                    )else(),
                                    if ($buttonOptions eq 'publish' and $isPublished and ac:has-permission('ldse:unpublish-doc', $locale, $currentPage)) then (
                                        <button type="button" onclick="ACT.item('ldse:unpublish', {xdmp:to-json-string($currentPage)}, {xdmp:to-json-string($locale)}, {xdmp:to-json-string($publishType)}, '{$tID}'); return false;">Un-Publish</button>
                                    ) else (),
                                    if ($buttonOptions eq 'publish' and $correlationCanPublish and ac:has-permission('ldse:publish-doc', $locale, $currentPage) ) then (
                                        <button type="button" onclick="ACT.item('ldse:publish', {xdmp:to-json-string($currentPage)}, {xdmp:to-json-string($locale)}, {xdmp:to-json-string($publishType)}, '{$tID}'); return false;">Publish</button>
                                    ) else (),
                                    if(fn:string-length($image) > 1) then (
                                        <img style="width: 130px; max-height: 100px;" src="{ core:get-display-uri($image) }" />,
                                        <br />,
                                        <p>{fn:substring($displayText, 0, 150)}{if(fn:string-length($displayText) > 150)then("...")else()}</p>
                                    ) else (
                                        <p>{fn:substring($displayText, 0, 290)}{if(fn:string-length($displayText) > 290)then("...")else()}</p>
                                    )
                                }</li>
                            )
                        }
                        </ul>
                    </fieldset><div class="clear">
                        <hr />    
                        <input type="button" onclick="ICE.teaserManagerReorder('save')" class="ixf-button primary float-right text-sm" value="Save and Publish Order" />
                        <input type="button" onclick="ICE.teaserManagerReorder()" class="ixf-button primary float-right text-sm" value="Save Order" />
                        <input type="button" class="ixf-button float-left text-sm cancel closeForm" value="Cancel" />
                    </div>
                </form>
            </div>
            <script type="text/javascript">
                function init_form() {{
                    if (ICE !== undefined) {{
                        ICE.setupForm();
                    }} else {{
                        setTimeout(init_form, 100);
                    }}
                }}
                init_form();
            </script>
            
        </div>
    ) else (
         let $errorMsg as xs:string:="Sorry, You don't have permission" 
         let $errorTitle as xs:string:= "Access Denied!"
         return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
    )
)
