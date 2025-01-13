xquery version "1.0-ml";

module namespace layout = "http://lds.org/code/shared/lds-edit/layout-functions";

import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace okta = 'http://lds.org/code/cms/modules/okta-library' at "/modules/okta-library.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

declare variable $signOutUrl as xs:string := if ($okta:okta-active) then $okta:okta-settings/cms-signout-page/text() else $util:host||'/?signmeout';

declare function addResources($title as xs:string) as item()* {
    xdmp:add-response-header("X-Frame-Options", "SAMEORIGIN"),
    <title>{$title}</title>,
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />,
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />,
    <link rel="stylesheet" type="text/css" media="all" href="{$settings:cdn-path}/ixf/1.1/styles/screen.css" />,

    <script type="text/javascript" src="{$settings:cdn-path}/scripts/jquery/1.7.1/jquery.min.js">&nbsp;</script>,
    <script type="text/javascript" src="{$settings:cdn-path}/scripts/ui/1.8.13/jquery-ui.min.js">&nbsp;</script>,
    <script type="text/javascript" src="{$settings:cdn-path}/ixf/1.1/scripts/ixf-plugins.min.js">&nbsp;</script>,
    <script type="text/javascript" src="{$settings:cdn-path}/ixf/1.1/scripts/ixf-utilities.min.js">&nbsp;</script>,
    <script type="text/javascript" src="{$settings:cdn-path}/ml/platform/scripts/platform-utilities.js">&nbsp;</script>,
    <script type="text/javascript">
        var sharedPrefix = {xdmp:to-json-string($settings:shared-prefix)};
        var frontEndHost = {xdmp:to-json-string(core:get-front-end-host())};
        var host = {xdmp:to-json-string($util:host)};
        var cdnPath = {xdmp:to-json-string($settings:cdn-path)};
    </script>,
    <script type="text/javascript" src="{$settings:shared-prefix}/ice/resources/script/ice.js">&nbsp;</script>

};

declare function buildHeader($title as xs:string)
as item()*
{
    <a href="#body" class="invisible">Skip to content</a>,

    <div class="ixf-header" role="navigation">
            <div class="ixf-appname">
                <a href="#appmenu" class="ixf-appname-link ixf-popup" data-pop-direction="left" title="Admin Pages">
                    {$title}
                </a>
            </div><!-- END ixf-appname -->

            <div class="ixf-tools">
                <span style="color:#AAA;">{ac:getPersonName()}</span>
                <a href="{$signOutUrl}" class="ixf-tools-link sprite locked prefix">Log Out</a>
            </div>
            <!-- END ixf-tools -->
     </div>

};


declare function buildSubHeader($title as xs:string) as item()* {
    buildSubHeader($title, ())
};

declare function buildSubHeader($title as xs:string, $extra as item()*)
as item()*
{
    <div class="ixf-subheader padding-xs" role="navigation">
        <p class="ixf-breadcrumb padding-xs text-md">
            <span class="padding-right-xs">You are here:</span>
            <span>{$core:site}</span>
            <span class="padding-left-xs padding-right-xs">&gt;</span>
            <span class="current">{$title}</span>
            {$extra}
        </p>
    </div>
};

declare function buildAppMenu($currentPage as xs:string, $lang as xs:string) as element(div) {
    <div id="appmenu">
        <ul class="ixf-list nolinks">{
        	let $pages as element(ldse:page)* :=
        		if($settings:pages/ldse:pages)
        		then $settings:pages/ldse:pages/ldse:page
        		else
        			for $nav-item as element(ldse:link) in $settings:default-admin-navigation/ldse:menu[@title eq "Admin Pages"]/ldse:link
        			return
        				<page  xmlns="http://lds.org/code/lds-edit">
        				{
        					$nav-item/@*,
        					text { $nav-item/@title/fn:string() }
        				}
        				</page>

		for $page as element(ldse:page) in $pages
		let $uri as xs:string := $page/@uri
		let $name as xs:string := fn:string($page) (:$page/@title:)
		let $seqNotDefined as xs:boolean := $page/@sequence = ""
		let $seq as xs:int := if($seqNotDefined) then 9999999 else $page/@sequence
		where ac:has-permission($page/@permission, "", "")
		order by $seq, $name
		return (
		    element li {
		        if ($currentPage eq $uri) then (
		            attribute class {"selected"}
		        ) else (),
		        element a {
		            attribute href {
		                if (fn:starts-with($uri, $settings:shared-prefix)) then (
		                    fn:concat($uri, util:split-locale-param($lang))
		                ) else (
		                    fn:concat($settings:shared-prefix, $uri, util:split-locale-param($lang))
		                )
		            },
		            $name
		        }
		    }
		)
        }
        </ul>
    </div>
};

declare function buildAppList($lang as xs:string) as element(li)* {
    for $page as element(ldse:page) in $settings:pages/ldse:page[@uri != '']
    let $uri as xs:string := $page/@uri
    let $name as xs:string := fn:string($page)
    let $icon as xs:string? := $page/@icon
    let $style as xs:string? := $page/@style
    let $seq as xs:int := $page/@sequence
    where ac:has-permission($page/@permission, "", "")
    order by $seq, $name
    return (
        element li {
            element em {
                attribute class { fn:concat("sprite icon ", $icon) },
                if ($style ne '') then (
                    attribute style {$style}
                ) else ()
            },
            element a {
                attribute href {
                    if (fn:starts-with($uri, $settings:shared-prefix)) then (
                        fn:concat($uri, util:split-locale-param($lang))
                    ) else (
                        fn:concat($settings:shared-prefix, $uri, util:split-locale-param($lang))
                    )
                },
                $name
            }
        }
    )
};
