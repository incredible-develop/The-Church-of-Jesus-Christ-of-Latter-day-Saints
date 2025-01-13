xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../../modules/utility-functions.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "../../../modules/iceFunctions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../../modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../../modules/ldse-core.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../../modules/access-control-functions.xqy";


declare boundary-space preserve;
declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

declare variable $host as xs:string := $util:host;

declare variable $country as xs:string? := util:escape-chars(xdmp:get-request-field("country", ""));
declare variable $preLang as xs:string := util:escape-chars(xdmp:get-request-field("lang", "eng"));

declare variable $lang as xs:string := if ($country ne '') then (fn:concat($preLang,'-',$country)) else ($preLang);
                  
declare variable $sharedPrefix as xs:string? := $settings:shared-prefix;

declare variable $navName as xs:string := util:escape-chars(xdmp:get-request-field("navName", ""));
declare variable $channelName as xs:string := util:escape-chars(xdmp:get-request-field("channelName"));
declare variable $channelSequence as xs:string := util:escape-chars(xdmp:get-request-field("channelSequence", ""));
declare variable $currentPage as xs:string := xdmp:get-request-field("curPage", "false");

declare variable $isCustom as xs:string := xdmp:get-request-field("isCustom", "");
declare variable $custom-page as element(custom-page) := if ($isCustom eq 'true') then (ice:get-custom-page($currentPage, $lang)) else ();

declare variable $channel as element()? := 
    if ($isCustom eq 'true') then (
        $custom-page/channel
    ) else (
        cts:search(/channels[@name eq $navName and @locale eq $lang],
            core:get-filter-query()
        )//channel[@sequence eq $channelSequence and @name eq $channelName][1]
    );
    
declare variable $location as xs:string? := if (fn:exists($channel)) then (xdmp:path($channel)) else ();
declare variable $size as xs:string := "32";

declare variable $referencedChannel as xs:string? := if ($isCustom eq 'true') then ($custom-page/channel/@reference) else ();
declare variable $hideClass as xs:string? := if ($isCustom eq 'true' and $referencedChannel ne '') then ('hidden') else ();

if (ac:has-permission("ldse:edit-navigation", $lang, $currentPage)) then (
    xdmp:set-response-content-type( "text/html" ),
      <style type="text/css">
        #resourceForm  {{
            height: inherit;
            overflow-y: scroll;
        }}
        #channelForm ul {{
            border: 1px solid #ddd;
            margin-top: 10px;
            padding-bottom: 10px;
            padding-left: 5px;
            margin-bottom: 20px;
            margin-left: 15px;
        }}
        #channelForm ul li {{
            margin-top: 10px;
        }}
         
        #channelForm li span {{
            color: black;
        }}
        
        #channelForm #resourceForm {{
            overflow-x: scroll;
            width: 1200px;
        }}

        #channelForm input[type="text"] {{
            border: 1px solid #dddddd;
            border-radius: 5px;
            font-size: 16px;
            min-height: 40px;
            line-height: 100%;
            padding: 6px 10px;
            color: #454545;
            margin-right: 15px;
        }}
        
        tr.hidden {{
            display: none;
        }}
        .ldse-section--header{{
            min-height: 18px;
            font-size: 22px;
        }}
    </style>,
    <div id="ice-dialog" class="padding-sm" style="background-color: #f9f9f9;">
        <script type="text/javascript" src="{$sharedPrefix}/ice/resources/script/navigationForm.js">&nbsp;</script>
        <form method="post" action="{$sharedPrefix}/ice/resources/ajax/navigation/updateChannel{util:split-locale-param($lang)}" style="padding:20px 0;" id="channelForm" onsubmit="return validateChannelForm();">
            <input type="hidden" name="navName" value="{$navName}"/>
            <input type="hidden" name="orginalSequence" value="{$channelSequence}"/>
            <input type="hidden" name="orginalName" value="{$channelName}"/>
            <input type="hidden" name="orginalLocation" value="{$location}"/>
            <input type="hidden" name="currentPage" value="{$currentPage}"/>
            <input type="hidden" name="isCustom" value="{$isCustom}"/>
            <input type="hidden" name="referer" value="{xdmp:get-request-field('referer')}"/>
            <h2>{ xs:string($channel/name) }</h2>
            <section class="ldse-section">
                <section class="ldse-section--body ldse-form ldse-clearfix">
                    <div class="grid-50">
                        {
                            if ($isCustom eq 'true') then (
                                <dl>
                                    <dt class="label">Reference Global Channel</dt>
                                    <dd>
                                        <span>Select the channel you want to show or use "Build Custom Nav" to create one</span><br/>{
                                        let $channels as element(channels)* := 
                                            cts:search(/channels[@name eq $navName and @locale eq $lang],
                                                core:get-filter-query()
                                            )
                                        let $selectableChannels as element(channel)* :=  $channels//channel[@name ne '' and @sequence ne '']
                                        return (
                                            <select id="referencedChannel" name="referencedChannel" onchange="isCustomNavigation(this);">
                                                <option value="">Build Custom Nav</option>
                                                {
                                                for $channel as element(channel) in $selectableChannels
                                                let $url as xs:string := $channel/url
                                                let $value as xs:string := fn:string-join(($channel/@name, $channel/@sequence, $url) ,':')
                                                let $text as xs:string := if ($url ne '') then (
                                                                 fn:concat($channel/@name, ' [', $url, ']')
                                                             ) else (
                                                                 $channel/@name
                                                             )
                                                return (
                                                    if ($value eq $referencedChannel) then (
                                                       <option value="{$value}" selected="yes">{$text}</option>
                                                    ) else (
                                                        <option value="{$value}">{$text}</option>
                                                    )
                                                )
                                            }</select>
                                        )
                                    }</dd>
                                </dl>
                            ) else ()
                        }
                        <dl class="{$hideClass}"><dt class="label">Channel Sequence</dt><dd><input type="text" class="required sm" name="sectionSequence" value="{fn:data($channel/@sequence)}" size="2"/></dd></dl>
                        <dl class="{$hideClass}"><dt class="label">Name</dt><dd><input type="text" class="required" name="sectionName" value="{ xs:string($channel/name) }" size="{$size}"/></dd></dl>
                        <dl class="{$hideClass}"><dt class="label">URL</dt><dd><input type="text" name="sectionUrl" value="{ xs:string($channel/url) }" size="{$size}"/></dd></dl>
                        <dl class="{$hideClass}"><dt class="label">Name Attribute</dt><dd><input type="text" name="sectionAttrName" value="{$channel/@name}" size="13"/></dd></dl>
                        <dl class="{$hideClass}">
                            <dt class="label"></dt>
                            <dd class="ldse-option">
                                {
                                    if ($channel/channels/@alwaysShow eq 'true') then (
                                        <input type="checkbox" name="alwaysShow" value="true" checked="yes" id="alwaysShow"/>
                                    ) else (
                                        <input type="checkbox" name="alwaysShow" value="true" id="alwaysShow"/>
                                    )
                                }
                                <label for="alwaysShow">Always Show Sub Channels</label>
                            </dd>
                        </dl>
                    </div>
                </section>
            </section>
            <section class="ldse-section">
                <header class="ldse-section--header"><h2><a>Channels</a></h2></header>
                <section class="ldse-section--body">
                    <div class="{$hideClass}"><section colspan="2">{ice:buildChannelsList($channel/channels, '')}</section></div>
                </section>
            </section>

            
            <div id="message"></div>
            <div style="text-align: center;"><input style="float: none; max-width: 90px;" class="ldse-button ldse-primary" type="submit" value="Save"/></div>
        </form>
        <script type="text/javascript"> ICE.setupForm(); </script>
    </div>        
) else (
        let $errorMsg as xs:string:="Sorry, You don't have permission" 
        let $errorTitle as xs:string:= "Access Denied!"
        return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
    )
