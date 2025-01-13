xquery version "1.0-ml";

module namespace template="http://lds.org/shared/lds-edit/template";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace sp = "http://lds.org/code/modules/site-properties" at "/modules/site-properties.xqy";
import module namespace library = "http://lds.org/code/shared/lds-edit/supported-languages" at "/supported-languages/modules/library.xqy";
import module namespace okta = 'http://lds.org/code/cms/modules/okta-library' at "/modules/okta-library.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

declare variable $default-site-lang as element()? := sp:get-default-site-and-lang(); (: finds a site and language that the user has the permission to access :)
declare variable $site as xs:string? := (xdmp:get-request-field("site")[1][. != ''], $default-site-lang/@site/(.), $sp:all-sites )[1];
declare variable $lang-param as xs:string? := ($util:locale, "eng" )[1];
(: $permitted-lang:
    Check if $lang-param is supported by site and that the user has permission to access.
   If not, find another language that the user can access for the site. :)
declare variable $permitted-lang := library:get-a-permitted-supported-languages-by-site($site, $lang-param);
declare variable $lang as xs:string := ($permitted-lang, $util:locale, "eng" )[1];
declare variable $localeParams as xs:string := util:split-locale-param($lang);
declare variable $message as xs:string? := xdmp:get-request-field("save");
declare variable $signOutUrl as xs:string := if ($okta:okta-active) then $okta:okta-settings/cms-signout-page/text() else $util:host||'/?signmeout';

declare function template:build-button-lists($button-groups as element(button-group), $enabled as xs:boolean) as element()*
{
    for $button as element(button-group) in $button-groups
    let $button-group as element(button)* := $button/button
    let $count as xs:int := fn:count($button-group)
    where $enabled
    return (
        if (fn:count($button-group) > 1) then (
            <span class="ldse-button-list">
                <ul>
                    <li>
                    	{
                    		if ( util:string-exists($button-group[1]/@ng-form) )
                    		then
                    			<ng-form name="{$button-group[1]/@ng-form/fn:string(.)}">
			                        <button style="{if ( fn:exists($button-group[1]/@hide) ) then ( 'display:none;' ) else ()}" class="{fn:concat('ldse-button ldse-main-action dropdown-left ', $button-group[1]/@class, ' ',  $button-group[1]/@icon)}">{$button-group[1]/@* except ($button-group[1]/(@class|@icon|@ng-form))}{fn:string($button-group[1])}</button>
			                    </ng-form>
			                else
			                	<button style="{if ( fn:exists($button-group[1]/@hide) ) then ( 'display:none;' ) else ()}" class="{fn:concat('ldse-button ldse-main-action dropdown-left ', $button-group[1]/@class, ' ',  $button-group[1]/@icon)}">{$button-group[1]/@* except ($button-group[1]/(@class|@icon|@ng-form))}{fn:string($button-group[1])}</button>
			            }
                        <button type="button" style="{if ( fn:exists($button-group[1]/@hide) ) then ( 'display:none;' ) else ()}" class="{fn:concat('ldse-button dropdown-right ldse-icon ', $button-group[1]/@class)}">More {fn:string($button-group[1])} Options</button>
                        <ul class="ldse-button-subgroup" style="display:none">
                            <li class="ldse-main-action-list">
		                    	{
		                    		if(util:string-exists($button-group[1]/@ng-form))
		                    		then
		                    			<ng-form name="{$button-group[1]/@ng-form/fn:string(.)}">
					                        <button style="{if ( fn:exists($button-group[1]/@hide) ) then ( 'display:none;' ) else ()}" class="{fn:concat('ldse-button ', $button-group[1]/@class, ' ',  $button-group[1]/@icon)}">{$button-group[1]/@* except ($button-group[1]/(@class|@icon|@ng-form))}{fn:string($button-group[1])}</button>
					                    </ng-form>
					                else
					                	<button style="{if ( fn:exists($button-group[1]/@hide) ) then ( 'display:none;' ) else ()}" class="{fn:concat('ldse-button ', $button-group[1]/@class, ' ',  $button-group[1]/@icon)}">{$button-group[1]/@* except ($button-group[1]/(@class|@icon|@ng-form))}{fn:string($button-group[1])}</button>
					            }
                            </li>{
                            for $buttons as element(button) in fn:subsequence($button-group, 2)
                            return (
                                <li>
                                	{
                                		if(util:string-exists($buttons/@ng-form))
                                		then
                                			<ng-form name="{$buttons/@ng-form/fn:string(.)}">
	                                			<button style="{if ( fn:exists($buttons/@hide) ) then ( 'display:none;' ) else ()}" class="{fn:concat('ldse-button ', $buttons/@class, ' ', $buttons/@icon)}">{$buttons/@* except ($buttons/(@class|@icon|@ng-form))}{fn:string($buttons)}</button>
	                                		</ng-form>
                                		else
                                			<button style="{if ( fn:exists($buttons/@hide) ) then ( 'display:none;' ) else ()}" class="{fn:concat('ldse-button ', $buttons/@class, ' ', $buttons/@icon)}">{$buttons/@* except ($buttons/(@class|@icon|@ng-form))}{fn:string($buttons)}</button>
                                	}

                                </li>
                            )
                        }</ul>
                    </li>
                </ul>
            </span>
        ) else (
        	if(util:string-exists($button-group/@ng-form))
        	then
        		<ng-form name="{$button-group/@ng-form/fn:string(.)}">
	            	<button style="{if ( fn:exists($button-group[1]/@hide) ) then ( 'display:none;' ) else ()}" class="{fn:concat('ldse-button ldse-responsive-button', $button-group/@icon, ' ', $button-group/@class)}">{$button-group/@* except ($button-group/(@class|@icon|@ng-form))}{fn:string($button-group)}</button>
	            </ng-form>
            else
            	<button style="{if ( fn:exists($button-group[1]/@hide) ) then ( 'display:none;' ) else ()}" class="{fn:concat('ldse-button ldse-responsive-button', $button-group/@icon, ' ', $button-group/@class)}">{$button-group/@* except ($button-group/(@class|@icon|@ng-form))}{fn:string($button-group)}</button>
        )
    )
};

declare function template:build-notifications-url() as xs:string {
    if (fn:lower-case($settings:environment) = "prod") then (
        'https://publisher-preview.lds.org/publishing/notifications'
    ) else (
        fn:concat('https://publisher-preview-',fn:lower-case($settings:environment), '.lds.org/publishing/notifications')
    )
};

declare function template:apply($title as xs:string, $pageUri as xs:string, $page as element(page)) as item()+ {
(:
<page>
    <head></head>
    <content></content>
    <scripts></scripts>

    <button-groups>
    </button-groups>

    <options>
    </options>

</page>
:)
    (:let $page := element page {$page/(@*|node()), core:ldse-publisher-template-options($title, $pageUri, $page)}:)
    let $enabled as xs:boolean := core:is-ldse-enabled()
    let $siteForDisplay as xs:string := fn:replace($core:site, "-","-&#8203;") (: Firefox Fix:)
    let $current-page as xs:string := $pageUri
    let $menu as element()* :=
        if ($enabled) then (
            if($settings:ldse-settings/(ldse:navigation|ldse:pages))
            then buildMenu($current-page, $pageUri, $page)
            else build-admin-menu($current-page, $page)
        ) else ()

    let $error-redirect-check as item()*  :=
        if (fn:not($enabled) and fn:not(fn:ends-with($pageUri, '/error'))) then (
            let $errorMsg as xs:string:="Sorry, You don't have permission"
            let $errorTitle as xs:string:= "Access Denied!"
            return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
        ) else ()
    let $app as xs:string := ($page/app, "LDSP")[1]
    let $controller as xs:string? := $page/controller
    let $form as xs:string? := $page/form

	let $body-content as element()* :=
		<body>
	        <div id="ldse-toolbar-container" class="ldse-toolbar-container back">
	            <div id="ldse-toolbar" class="ldse-toolbar">
	                <div class="ldse-toolbar-item ldse-main-menu" id="ldse-main-menu">
	                    <p class="ldse-toolbar-logo ldse-dropdownMenu-trigger">
	                        <span class="ldse-icon-list-2 ldse-icon">Main Menu</span>
	                        <span class="ldse-brand">{(:
	                            <span class="ldse-logo-text-last">LDS</span>
	                            <span class="ldse-logo-text-first"> PUBLISHER</span>:)}
	                        </span>
	                        <span class="ldse-site-name">{$settings:display-name}</span>
	                    </p>
	                    <nav class="ldse-nav">{$menu}</nav>
	                </div>
	                <div id="ldse-toolbar-buttons">
	                    {$page/button-groups/@* except $page/button-groups/@class}
	                    {
	                        attribute class {
	                            fn:string-join(
	                            	(
	                            		"ldse-toolbar-buttons",
	                            		$page/button-groups/@class/fn:string(.)
	                            	),
	                            	" "
	                            )
	                        }
	                    }
	                    <span>{template:build-button-lists($page/button-groups/button-group, $enabled)}</span>
	                </div>
	                <div id="ldse-user-info" class="ldse-toolbar-item ldse-user">
	                    <p class="ldse-dropdownMenu-trigger">
	                        <span class="ldse-icon-user ldse-icon">User Info</span>
	                    </p>
	                    <nav class="ldse-nav">
	                        <ul class="ldse-menu">
	                            <li>
	                                <p class="ldse-user-name">{(fn:string($page/options/username)[. != ""], ac:getPersonName())[1]}</p>
	                            </li>
	                           <li>
	                                <a href="{template:build-notifications-url()}"><button class="ldse-button ldse-icon-alarm">Notifications</button></a>
	                            </li>
	                            <li>
                                    <a href="{$signOutUrl}"><button class="ldse-button ldse-last ldse-icon-exit" style="width:150px;">Log Out</button></a>
                                </li>
	                            {$page/options/user-menu-links/element()}
	                        </ul>
	                    </nav>
	                </div>
	                {
	                    if ($page/preview-eye and xs:string($page/preview-eye) ne "")
	                    then (
                            let $preview-enabled as xs:boolean := $settings:preview-enabled
                            return
                                if ($preview-enabled) then (
                                    <div id="ldse-preview-button" class="ldse-toolbar-item ldse-preview-button">
                                        <button id="action-preview" class="ldse-button special ldse-icon-preview ldse-icon" onclick="previewButtonClicked({xdmp:to-json-string(xs:string($page/preview-eye))}); return false;">Preview</button>
                                    </div>
                                )
                                else ()
                        )
	                    else ()
	                }
	                <div id="ldse-toolbar-toggle" class="ldse-toolbar-item ldse-toolbar-toggle">
	                    <span class="ldse-icon-close-menu ldse-icon">Toggle Toolbar</span>
	                </div>
	            </div>
	        </div>
	        {(:<div id="night-mode-toggle"><a class="ldse-icon-moon ldse-icon">Toggle Night Mode</a></div>:)}
	        <section class="ldse-page">
	            <h1>{
	                if ( fn:exists($page/title) ) then (
	                    $page/title/node()
	                ) else (
	                    $title
	                )
	            }</h1>
	            {$page/content/*}
	        </section>
	        <section id="save-alert" class="ldse-alert-container">
	            <div class="ldse-alert">
	                <span class="ldse-alert-text">Changes saved successfully</span>
	                <span class="ldse-alert-close ldse-icon-x ldse-icon">Close</span>
	            </div>
	        </section>
	        <section class="ldse-section ldse-modal" style="display:none;" id="modal1"><div></div></section>
	        <section class="ldse-section ldse-modal" style="display:none;" id="alertModal"><div></div></section>
	        <section id="ldse-footer" class="ldse-footer">
	            {
	               if ( $settings:logo = 'true' ) then (
                        <div class="ldse-logo {$page/options/ldse-logo-size-class}">
                           <p class="ldse-logo-image ldse-icon-logo ldse-icon ">Logo Image</p>
                           <p class="ldse-logo-text">
                               <span class="ldse-logo-text-first">LDS</span>
                               <span class="ldse-logo-text-last"> PUBLISHER</span>
                           </p>
                        </div>
                   ) else ()
               }
	        </section>
	        <div id="md-loading" class="panel-loading"><p>Loading</p><span></span></div>
            {
                if ( fn:empty($page/include-scripts) ) then (
                    <script type="text/javascript">
                        var sharedPrefix = {xdmp:to-json-string($settings:shared-prefix)};
                        var frontEndHost = {xdmp:to-json-string(core:get-front-end-host())};
                        var host = {xdmp:to-json-string($util:host)};
                        var cdnPath = {xdmp:to-json-string($settings:cdn-path)};
                        var locale = {xdmp:to-json-string($lang)};
                    </script>,
                    <script src="{$settings:cdn-path}/scripts/jquery/1.7.1/jquery.min.js" type="text/javascript">&nbsp;</script>,
                    <script src="{$settings:cdn-path}/scripts/ui/1.8.20/jquery.ui.datepicker.min.js" type="text/javascript">&nbsp;</script>,
                    <script src="{$settings:cdn-path}/scripts/jquery/plugins/cookie/jquery.cookie.20110127.min.js" type="text/javascript">&nbsp;</script>,
                    <script src="{$settings:cdn-path}/scripts/other/handlebars/handlebars1.0.0.beta.6.min.js ">&nbsp;</script>,
                    <script src="{$settings:shared-prefix}/resources/scripts/ldsedit.js" type="text/javascript">&nbsp;</script>,
                    <script class="handlebars-template" id="confirmTemplate" type="text/x-handlebars-template">
                        <header class="ldse-section--header">
                         <h2>{{{{this.title}}}}</h2>
                        </header>
                        <form class="ldse-section--body ldse-form">
                         <dl>
                             <dt><label for="reason">{{{{this.text}}}}</label></dt>
                         </dl>
                         <div class="ldse-form-buttons">
                             <input type="submit" class="ldse-button primary" value="OK" />
                             {{{{#unless this.noCancel}}}}
                                 <input type="button" class="ldse-button ldse-modal-close" value="Cancel" />
                             {{{{/unless}}}}
                         </div>
                        </form>
                    </script>
                ) else (
                    <div id="ldse-modal-backdrop" class="ldse-modal-backdrop" style="display:none;"></div>
                ),
                $page/scripts/*
            }
    	</body>/*


    return (
            xdmp:set-response-content-type("text/html; charset=utf-8"),
            xdmp:add-response-header("X-Frame-Options", "SAMEORIGIN"),
            "<!DOCTYPE html>",
            <html class="no-js ldse-admin-page" lang="en" ng-app="{ $app }">
            	{
            		if(util:string-exists($controller))
            		then attribute ng-controller {$controller}
            		else ()
            	}
                <head>
                    <title>{$title}</title>
                    <meta charset="utf-8"/>
                    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/>
                    <meta name="description" content=""/>
                    <meta name="author" content=""/>
                    <meta name="HandheldFriendly" content="True"/>
                    <meta name="MobileOptimized" content="320"/>
                    <meta name="viewport" content="width=device-width, initial-scale=1"/>
                    { if ( fn:empty($page/include-scripts) ) then ( <link rel="stylesheet" href="{$settings:shared-prefix}/resources/css/ldspublisher-ice.css" /> ) else () }
                    <link rel="stylesheet" href="{$settings:shared-prefix}/resources/css/ldspublisher.css" />
                    <link rel="shortcut icon" type="image/x-icon" href="{$settings:shared-prefix}/resources/ldspub-favicon.png" />
                    {$page/head/*}
                </head>
                <body>
                {
                	if(util:string-exists($form))
                	then <form name="{$form}">{$page/form/@* except $page/form/@name}{$body-content}</form>
                	else $body-content
                }
                </body>
            </html>
    )

};

(:Throws the default error:)
declare function error() as item()* {
    error((),())
};
(:Throws an error with the specified message and error title as parameters:)
declare function error($errorMsg as xs:string?, $errorTitle as xs:string?) as item()* {
    let $title as xs:string := ($errorMsg, "Sorry, an error occured.")[1]
    let $message as xs:string := ($errorTitle,"Error!")[1]
    return
    xdmp:redirect-response(
        fn:concat($settings:shared-prefix,"/error?errorMsg=",
        $message,
        "&amp;errorTitle=",$title))
};

declare private function add-pages() as element(ldse:sub-menu)*{
    for $page as element(ldse:page) in $settings:pages/ldse:page
        return
        <sub-menu xmlns="http://lds.org/code/lds-edit">
            <button>{$page/(@*|node())}</button>
        </sub-menu>

};

declare function get-ldse-menu() as element(ldse:navigation){
    <navigation xmlns="http://lds.org/code/lds-edit">
        <button uri="{$signOutUrl}" icon="ldse-icon-exit" sequence="99999999" title="Log Out">Log Out</button>
    </navigation>
};

declare function build-admin-menu($currentPage as xs:string, $page as element(page)) as element(ul)
{
    let $site-nav-items as element()* := $settings:admin-navigation/ldse:add/(ldse:link | ldse:menu)

    let $core-admin-pages-sequence as xs:integer :=
        if($settings:default-admin-navigation/menu[@title = 'Admin Pages']/@sequence/fn:string() castable as xs:integer)
        then xs:integer($settings:default-admin-navigation/menu[@title = 'Admin Pages']/@sequence/fn:string())
        else 99999998

    let $nav-items as element()* := (
        get-ldse-menu()/(ldse:link | ldse:menu | ldse:button),
        $settings:default-admin-navigation/(ldse:link | ldse:menu),
        if($site-nav-items)
        then
            <menu xmlns="http://lds.org/code/lds-edit" icon="ldse-icon-tools" sequence="{$core-admin-pages-sequence}" title="Site Admin Pages">
            {
                $settings:admin-navigation/ldse:add//ldse:link
            }
            </menu>
        else (),
        $page/options/ldse:navigation/(ldse:link | ldse:menu | ldse:button)
    )

    return
        element ul {
            attribute class { "ldse-menu" },
            build-admin-menu-process($currentPage, $page, $nav-items)
        }
};

declare function build-admin-menu-process(
    $currentPage as xs:string,
    $page as element(page),
    $nav-items as node()*
) as element(li)* {
    for $nav-item as element() in $nav-items
    let $id as xs:string := fn:concat(fn:local-name($nav-item), "-", fn:replace($nav-item/@title, " ", "_"))
    let $orderby-text as xs:string := ( $nav-item/@title, $nav-item/text() )[1]
(:    let $e := if ( $orderby-text = 'deseretindustries' ) then ( fn:error() ) else ():)
    where fn:not($settings:admin-navigation/ldse:remove/(ldse:menu | ldse:link)[@id eq $id])
        and (fn:not($nav-item/@permission) or ac:has-permission($nav-item/@permission/fn:string(), "", ""))
        and fn:not($nav-item/@ixf-only)
    order by fn:number($nav-item/@sequence), $orderby-text

    return (
        let $hasSubMenu as xs:string? := if(fn:exists($nav-item[self::ldse:menu])) then "with-submenu" else ()
        let $isCurrentPage as xs:string? := if($currentPage eq $nav-item/@uri) then "active" else ()
        let $li-class as xs:string := fn:string-join(($hasSubMenu, $isCurrentPage), " ")

        return (
            typeswitch($nav-item)
            case element(ldse:button) return ( build-admin-menu-link-li($id, $li-class, $nav-item, $lang) )
            case element(ldse:link) return ( build-admin-menu-link-li($id, $li-class, $nav-item, $lang) )
            case element(ldse:menu) return (
                let $isOpen as xs:string? := if(some $li in $nav-item//ldse:link[fn:not(@ixf-only)] satisfies $li/@uri = $currentPage) then "ldse-open" else ()
                return (
                    element li {
                        attribute id { $id },
                        attribute class { fn:string-join(($li-class, $isOpen), " ") },
                        element a {
                            attribute class { $nav-item/@icon },
                            $nav-item/@title/fn:string()
                        },
                        element ul {
                            build-admin-menu-process(
                                $currentPage,
                                $page,
                                (
                                    $nav-item/(ldse:link | ldse:menu)
                                    (: ,$settings:admin-navigation/ldse:add/(ldse:link | ldse:menu)[@menu-id = $id]) :)
                                )
                            )
                        }
                    }
                )
            )
            default return build-admin-menu-process($currentPage, $page, $nav-item/(ldse:link | ldse:menu))
        )
    )
};

declare function build-admin-menu-link-li($id as xs:string, $li-class as xs:string, $nav-item as element(), $lang as xs:string) as element(li)
{
    element li {
        attribute id { $id },
        attribute class { $li-class },
        element a {
            attribute href {
                fn:concat(
                    if (fn:starts-with($nav-item/@uri, "/shared")) then (
                        fn:concat($settings:shared-prefix, fn:string($nav-item/@uri))
                    ) else ( fn:string($nav-item/@uri) ),
                    if ( fn:contains($nav-item/@uri, '?') or $nav-item/@icon eq 'ldse-icon-exit' ) then ()
                    else (
                        fn:concat($localeParams, $nav-item/@hash/fn:string(.), '&amp;site=' || $site)
                    )
                )
            },
            attribute class { $nav-item/@icon },
            $nav-item/@* except $nav-item/(@href | @class | @title | @uri | @icon | @permission | @seq),
            $nav-item/@title/fn:string()
        }
    }
};

declare function buildMenu($currentPage as xs:string, $pageUri as xs:string, $page as element(page)) as element(ul)*{
    let $pages as element(ldse:navigation)* := ($settings:navigation, get-ldse-menu(), $page/options/ldse:navigation)
    return if ( fn:exists($pages) ) then (
        let $toolbar-nav :=
            for $page as element(ldse:button) in $pages/ldse:button
                let $subMenu as element(ldse:sub-menu)* := ($page/ldse:sub-menu, if($page/@pages = "true") then add-pages() else ())
                let $uri as xs:string :=
                    fn:concat(
                        if (fn:starts-with($page/@uri, "/shared"))
                        then fn:concat($settings:shared-prefix, fn:string($page/@uri))
                        else fn:string($page/@uri)
                   )
                let $uri as xs:string := if ( fn:contains($uri, "?") ) then ( $uri ) else ( fn:concat($uri, $localeParams) )
                let $name as xs:string := (
                    if (fn:exists($page/@title)) then (
                        fn:string($page/@title)
                        )else (fn:string($page))
                    )
                let $seqNotDefined as xs:boolean := ($page/@sequence = "" or fn:empty($page/@sequence))
                let $seq as xs:int := if($seqNotDefined) then 9999999 else $page/@sequence

                let $hasSubMenu as xs:boolean := fn:exists($subMenu)
                let $isCurrentPage as xs:boolean := $currentPage eq $page/@uri and fn:not($hasSubMenu)
                let $permission as xs:string? := $page/@permission[. != '']
                let $sub-menu as element(ul)? :=
                    if(fn:exists($subMenu)) then(
                        element ul {
                            for $subPage as element(ldse:button) in $subMenu/ldse:button
                            let $subUri as xs:string := $subPage/@uri
                            let $isCurrentPage as xs:boolean := $currentPage eq $subPage/@uri
                            let $sub-permission as xs:string? := $subPage/@permission[. != '']
                            let $has-permission as xs:boolean := if ( fn:exists($sub-permission) ) then ( ac:has-permission($sub-permission, "", "") ) else ( fn:true() )

                            where ( fn:not( fn:ends-with($subUri, "") ) and $has-permission )
                            order by xs:int($subPage/@sequence) ascending
                            return(
                                element li {
                                    if ($isCurrentPage) then (
                                        attribute class {"active"}
                                    ) else (),
                                    element a {
                                        attribute href {
                                            fn:concat(
                                                if (fn:starts-with($subPage/@uri, "/shared")) then (
                                                    fn:concat($settings:shared-prefix, $subPage/@uri)
                                                ) else ( $subPage/@uri ),
                                                if ( fn:contains($subPage, "?") ) then () else ( $localeParams )
                                           )
                                        },
                                        fn:string($subPage)
                                    }
                                }
                            )
                        }
                    ) else()
                let $isOpen as xs:boolean := some $li in $sub-menu/li satisfies $li/@class = "active"
                let $has-permission as xs:boolean := if ( fn:exists($permission) ) then ( ac:has-permission($permission, "", "") ) else ( fn:true() )
                where (
                    $has-permission and
                    (
                        ( $hasSubMenu and fn:exists( $sub-menu/*) ) or
                        fn:not($hasSubMenu)
                    )
                )
                order by $seq, $name
                return (
                    element li {
                        attribute class {
                            fn:string-join(
                              (
                                if ($isCurrentPage) then ("active") else (),
                                if($hasSubMenu) then ("with-submenu") else (),
                                if ($isOpen) then ("ldse-open") else ()
                              )
                            , " "
                            )
                        },
                        element a {
                            attribute class {$page/@icon},
                            if (fn:not($hasSubMenu)) then(
                                attribute href {$uri}
                            ) else (),
                            $name
                        },
                        $sub-menu
                    }

             )
        return element ul { attribute class {"ldse-menu"}, $toolbar-nav}
    )else ()
};

declare function template:error-access-denied(
    $errorTitle as xs:string?,
    $errorMsg as xs:string?
) as item()* {
    template:error-access-denied($errorTitle, $errorMsg, (), ())
};

declare function template:error-access-denied(
    $errorTitle as xs:string?,
    $errorMsg as xs:string?,
    $extraContent as item()*,
    $refer-link as item()*
) as item()* {
    let $errorTitle as xs:string := ( $errorTitle[. ne ""], "Error!" )[1]
    let $errorMsg as xs:string := ( $errorMsg[. ne ""], "An error occured." )[1]
    return (
        xdmp:set-response-content-type( "text/html" ),
        '<!DOCTYPE html >',
        core:template-apply(
            'Error Page',
            fn:concat($settings:shared-prefix, "/error"),
            <page>
                <head>
                    <link rel="stylesheet" type="text/css" href="{$settings:shared-prefix}/error/styles/error.css" />
                </head>

                <scripts>
                    <script type="text/javascript" src="{$settings:cdn-path}/lds-edit/scripts/jquery.form.js">&nbsp;</script>
                    <script>$(".active").removeClass("active")</script>
                </scripts>

                <content>
                    <div>
                       <h2 class='red'>{$errorTitle}</h2>
                       <h4 class='red' id='msg'>{$errorMsg}</h4>
                       {
                            if (fn:exists($refer-link)) then (
                                 <h4 class='red' id='extra'>Click <a href="{fn:concat($settings:shared-prefix, $refer-link)}">here</a> to return to front-end</h4>
                            ) else ()
                       }
                   </div>
                </content>
            </page>
        )
    )
};
