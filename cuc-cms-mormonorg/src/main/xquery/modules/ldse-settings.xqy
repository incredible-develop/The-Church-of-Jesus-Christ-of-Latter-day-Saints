xquery version "1.0-ml";

module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace sp = "http://lds.org/code/modules/site-properties" at "/modules/site-properties.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace its = "http://www.w3.org/2005/11/its";

declare option xdmp:mapping "true";

declare variable $ldse-settings as element(ldse:ldse-settings) := $core:ldse-settings;
declare variable $host-header as xs:string? := fn:lower-case(xdmp:get-request-header("host"));
declare variable $isDevOpCMS as xs:boolean :=
    if (starts-with($host-header, 'cuc-') or
        starts-with($host-header, 'msadm-') ) then
        fn:true()
    else fn:false();
declare variable $live-domain as xs:string? := $ldse-settings/ldse:live-domain;
declare variable $shared-prefix as xs:string := ( $ldse-settings/ldse:shared-prefix, '')[1];
declare variable $query-directory as xs:string := ($ldse-settings/ldse:query-directory, '')[1];
declare variable $secure-prefix as xs:string := ($ldse-settings/ldse:secure-prefix, '')[1];
declare variable $cdn-path as xs:string := ($ldse-settings/ldse:cdn-path, '')[1];
declare variable $cdn-ldspub-path as xs:string := ($ldse-settings/ldse:cdn-ldspub-path, '//edge.ldscdn.org/cdn2/csp')[1];
declare variable $environment as xs:string := ( $ldse-settings/@environment[. != ''], $ldse-settings/ldse:environment[. !=""], "prod" )[1];
declare variable $display-name as xs:string := ($ldse-settings/@display-name, $ldse-settings/@application)[1];
declare variable $application as xs:string := $ldse-settings/@application/xs:string(.);
declare variable $is-local as xs:boolean := $environment = "local";
declare variable $bc-path as xs:string := ($ldse-settings/ldse:bc-path, '')[1];
declare variable $bcs-path as xs:string := ($ldse-settings/ldse:bcs-path, '')[1];
declare variable $ckeditor-version as xs:string := ($ldse-settings/ldse:ckeditor-version, '3.6.3')[1];
declare variable $manage-shared as xs:boolean := $ldse-settings/ldse:manage-shared eq "true";
declare variable $strip-domains as element(ldse:strip-domains)? := $ldse-settings/ldse:strip-domains;
declare variable $root-contexts as xs:string* := $ldse-settings/ldse:contexts/ldse:context;
declare variable $search-domain as xs:string := ($ldse-settings/ldse:search-domain, '')[1];
declare variable $root-qnames as xs:QName* := settings:build-root-qname( $ldse-settings/ldse:root-qnames/ldse:root );
declare variable $pages as element(ldse:pages)? := $ldse-settings/ldse:pages;
declare variable $navigation as element(ldse:navigation)? := $ldse-settings/ldse:navigation;
declare variable $default-locale as xs:string := ($ldse-settings/ldse:default-locale, "eng")[1];
declare variable $post-clone-process as element(ldse:post-clone-process)? := $ldse-settings/ldse:post-clone-process;
declare variable $jquery-ui as xs:string := ($ldse-settings/ldse:jquery-ui[. != ""], "1.8.13")[1];
declare variable $seo-title as xs:string* := ($ldse-settings/ldse:seo/ldse:seo-title, "metatitle")[1];
declare variable $seo-desc as xs:string* := ($ldse-settings/ldse:seo/ldse:seo-desc, "metadescription")[1];
declare variable $brightcove-user as xs:string := ($ldse-settings/ldse:brightcove-service/ldse:user, "ldsedit")[1];
declare variable $brightcove-key as xs:string := ($ldse-settings/ldse:brightcove-service/ldse:key, "ce2251c489202fc50a96f93526577e48")[1];
declare variable $brightcove-mode as xs:string := ($ldse-settings/ldse:brightcove-service/ldse:mode, $modes[1]/@name)[1];
declare variable $auto-crop as xs:string := ($ldse-settings/ldse:binary-manager/@auto-crop, "false")[1];
declare variable $has-sensitive as xs:string := ( $ldse-settings/ldse:has-sensitive/@enabled, "true" )[1];
declare variable $has-components as xs:string := ( $ldse-settings/ldse:has-components/@enabled, "true" )[1];
declare variable $file-server as xs:string := ( $ldse-settings/ldse:file-server, '' )[1];
declare variable $element-arrays as item()* := $ldse-settings/ldse:element-arrays/ldse:element-array;
declare variable $rwuser as xs:string? := $ldse-settings/ldse:logins/rw-user/@username;
declare variable $remove-custom-page-content as xs:boolean := $ldse-settings/ldse:remove-custom-page-content/@enabled = 'true';
declare variable $versification as xs:string? := $ldse-settings/ldse:versification;
declare variable $versification-uris as xs:string* := $ldse-settings/ldse:versification-uris/ldse:versification-uri/@uri;
declare variable $not-versification-uris as xs:string* := $ldse-settings/ldse:versification-uris/ldse:not-versification-uri/@uri;
declare variable $logo as xs:string := ( $ldse-settings/ldse:logo/fn:string(), 'true' )[1];
declare variable $ignore-elements as xs:QName* := $ldse-settings/ldse:ignore-elements/ldse:element/xs:QName(.);
declare variable $ignore-attributes as xs:QName* := $ldse-settings/ldse:ignore-attributes/ldse:attribute/xs:QName(.);
declare variable $host as xs:string? := $ldse-settings/ldse:domain;
declare variable $domains as element(ldse:app-domain)* := $ldse-settings/ldse:app-domain;
declare variable $titan-types as element(ldse:type)* := $ldse-settings/ldse:titan-asset-types/ldse:type;
declare variable $env-config := cts:search(/environment-config,());
declare variable $titan-images-used-api := $ldse-settings/ldse:feature-links/ldse:link[@type eq "titan-images-used-api"]/@path/fn:string();
declare variable $titan-image-path := $ldse-settings/ldse:titan-asset-paths/ldse:type[@value eq "image"]/fn:string();
declare variable $titan-audio-path := $ldse-settings/ldse:titan-asset-paths/ldse:type[@value eq "audio"]/fn:string();
declare variable $titan-video-path := $ldse-settings/ldse:titan-asset-paths/ldse:type[@value eq "video"]/fn:string();
declare variable $titan-pdf-path := $ldse-settings/ldse:titan-asset-paths/ldse:type[@value eq "pdf"]/fn:string();
declare variable $find-page-links := $ldse-settings/ldse:feature-links/ldse:link[@type eq "find-page-links"]/@path/fn:string();
declare variable $page-used-by := $ldse-settings/ldse:feature-links/ldse:link[@type eq "page-used-by"]/@path/fn:string();
declare variable $cms-api := $ldse-settings/ldse:feature-links/ldse:link[@type eq "cms-api"]/@path/fn:string();
declare variable $asset-crawler-url as xs:string? := ( $ldse-settings/ldse:asset-crawler-url[. != ''], 'http://assetcrawler-stage.ldschurch.org/api/v2' )[1];
declare variable $content-api-url as xs:string? := ( $ldse-settings/ldse:content-api-url[. != ''], 'http://contentapi-stage.ldschurch.org/api/v2' )[1];
declare variable $content-api-asset as xs:string? := ( $ldse-settings/ldse:content-api-asset[. != ''], 'https://contentapi.churchofjesuschrist.org/assetsearch/api/v2/asset/versionID' )[1];
declare variable $details-api-url as xs:string? := ( $ldse-settings/ldse:details-api-url[. != ''], 'https://contentapi.churchofjesuschrist.org/api/v2/asset/details/id/' )[1];
declare variable $content-groups-api as xs:string? := ( $ldse-settings/ldse:content-groups-api[. != ''], 'https://publish.ldschurch.org/content_automation/services/api/contentGroups' )[1];
declare variable $content-central-api as xs:string := ( $ldse-settings/ldse:content-central-api[. != ''], 'https://publish.ldschurch.org/content_automation' )[1];
declare variable $media-api-url as xs:string := ( $ldse-settings/ldse:media-api-url[. != ''], 'https://digital-media-api.pvu.cf.churchofjesuschrist.org/api/v1/assets/' )[1];
declare variable $cogito-url as xs:string := ( $ldse-settings/ldse:cogito-url[. != ''], 'http://cogito-dev.ldschurch.org:8090/cogito/v1/store/West/Subjects/descriptors/search' )[1];
declare variable $personalization-service as xs:string := ( $ldse-settings/ldse:personalization-service[. != ''], 'https://publisher.lds.org/services' )[1];
declare variable $emx-config as element(ldse:emx-config)? := cts:search(/ldse:emx-config, ());
declare variable $emx-queue as xs:string := ( $emx-config/ldse:url[. != ''], 'https://emx-stage.ldschurch.org/publisher/stage/onramp/message' )[1];
declare variable $emx-username as xs:string := ( $emx-config/ldse:credentials/ldse:username[. != ''] )[1];
declare variable $emx-password as xs:string := ( $emx-config/ldse:credentials/ldse:password[. != ''] )[1];
declare variable $lang-hosts as xs:string* := $ldse-settings/ldse:lang-hosts/ldse:lang-host;
declare variable $correlation-used as xs:string := ( 'false', $ldse-settings/ldse:correlation-used/@enabled, 'true' )[1];
declare variable $cogito-credentials as element(ldse:cogito-credentials)? := cts:search(ldse:cogito-config, ())/ldse:cogito-credentials;
declare variable $cogito-schemes as element(ldse:cogito-scheme)* := $ldse-settings/ldse:cogito-schemes/ldse:cogito-scheme;
declare variable $app-domain as xs:string? :=
    if ( fn:count($domains) > 1 ) then (
        $domains[@mode = $core:mode]
    ) else ( $domains )
;
declare variable $new-dynamic as xs:string? := $ldse-settings/ldse:new-dynamic;
declare variable $clone as xs:boolean := $ldse-settings/ldse:clone/fn:string(.) eq 'true';
declare variable $use-image-prefix as xs:boolean := $ldse-settings/ldse:use-image-prefix = 'true';
declare variable $content-admin-form-url as xs:string? := ( $ldse-settings/admin-form-url, $shared-prefix || '/content-admin' )[1];
declare variable $toolbar-settings as element(ldse:toolbar-settings) := (
    $ldse-settings/ldse:toolbar-settings,
    <toolbar-settings xmlns="http://lds.org/code/lds-edit">
        <ice-toggle enabled="true"/>
        <components-toggle enabled="false"/>
        <link-checker enabled="true"/>
        <seo-checker enabled="true"/>
        <toolbar-toggle enabled="true"/>
    </toolbar-settings>
)[1];
declare variable $publisher-email as element(ldse:lds-publisher-email)? := $ldse-settings/ldse:lds-publisher-email;
declare variable $scheduledJobFailureNotificationEmails as element(ldse:email)* := $ldse-settings/ldse:scheduled-job-failure-notification/ldse:email;
declare variable $site as xs:string? := xdmp:get-request-field('site')[1];
declare variable $site-properties as element(siteProperties)? := if ($site) then sp:get-site-properties($site) else ();
declare variable $preview-host as xs:string? :=
    if ($isDevOpCMS) then
       fn:replace($host-header, '-cms.pvu.cf.churchofjesuschrist.org', '-hannah-preview.pvu.cf.churchofjesuschrist.org')
    else
       $site-properties/urls/url[@env = 'preview']/fn:string();
declare variable $published-host as xs:string? :=
    if ($isDevOpCMS) then
        fn:replace($host-header, '-cms.pvu.cf.churchofjesuschrist.org', '-hannah.pvu.cf.churchofjesuschrist.org')
    else
        $site-properties/urls/url[@env = 'published']/fn:string();
declare variable $devop-prefix as xs:string? :=
    if ($isDevOpCMS) then
       if ($site-properties/@site eq 'comeuntochrist') then
          '/comeuntochrist-m'
       else if ($site-properties/site-context eq ('', '/')) then
            '/'||$site-properties/@site
       else ()
    else ();
declare variable $consolidation as element(site)? := sp:get-consolidation-info($site, 'publish');
declare variable $consolidated-host as xs:string? := $consolidation/@host||$consolidation/@prefix;

declare variable $brightcove-servers as element(ldse:brightcove-servers) := (
    $ldse-settings/ldse:brightcove-servers,
    <brightcove-servers xmlns="http://lds.org/code/lds-edit">
        <host env="prod">http://mediatools.ldschurch.org</host>
        <host env="stage">https://mediatools-uat.ldschurch.org</host>
        <host env="uat">https://mediatools-uat.ldschurch.org</host>
        <host env="test">https://mediatools-test.ldschurch.org</host>
        <host env="int">https://mediatools-dev.ldschurch.org</host>
        <host env="dev">https://mediatools-dev.ldschurch.org</host>
    </brightcove-servers>
)[1];
declare variable $sensitive-uris as element(ldse:sensitive-uris)? := $ldse-settings/ldse:sensitive-uris;
declare variable $brightcove-server as xs:string := $brightcove-servers/ldse:host[@env = $environment];
declare variable $medialoader-path as xs:string? := $ldse-settings/ldse:medialoader-path/@path;

declare variable $warehouse-servers as element(ldse:warehouse-servers) := (
    $ldse-settings/ldse:warehouse-servers,
    <warehouse-servers xmlns="http://lds.org/code/lds-edit">
        <host env="prod">http://orig.churchofjesuschrist.org/services/warehouse</host>
        <host env="stage">http://uat-orig.churchofjesuschrist.org/services/warehouse</host>
        <host env="uat">http://uat-orig.churchofjesuschrist.org/services/warehouse</host>
        <host env="test">http://int-orig.churchofjesuschrist.org/services/warehouse</host>
        <host env="int">http://int-orig.churchofjesuschrist.org/services/warehouse</host>
        <host env="dev">http://int-orig.churchofjesuschrist.org/services/warehouse</host>
        <host env="local">http://int-orig.churchofjesuschrist.org/services/warehouse</host>
    </warehouse-servers>
)[1];
declare variable $warehouse-server as xs:string := $warehouse-servers/ldse:host[@env = $environment];

declare variable $enrich-servers as element(ldse:enrich-servers) := (
    $ldse-settings/ldse:enrich-servers,
    <enrich-servers xmlns="http://lds.org/code/lds-edit">
        <host env="prod">http://orig.churchofjesuschrist.org/services/enrich</host>
        <host env="stage">http://uat-orig.churchofjesuschrist.org/services/enrich</host>
        <host env="uat">http://uat-orig.churchofjesuschrist.org/services/enrich</host>
        <host env="test">http://int-orig.churchofjesuschrist.org/services/enrich</host>
        <host env="int">http://int-orig.churchofjesuschrist.org/services/enrich</host>
        <host env="dev">http://int-orig.churchofjesuschrist.org/services/enrich</host>
        <host env="local">http://int-orig.churchofjesuschrist.org/services/enrich</host>
    </enrich-servers>
)[1];
declare variable $enrich-server as xs:string := $enrich-servers/ldse:host[@env = $environment];

declare variable $is-submitter as xs:boolean := fn:not(ac:has-permission("ldse:view-any-submission", "", "")) and ac:has-permission("ldse:add-submission", "", "");

(: CACHE CLEARING :)
declare variable $exclude-lang-extensions as xs:string* :=
    fn:map(
        function($ext) { fn:lower-case($ext) },
        fn:map(
            function($ext) { if (fn:starts-with($ext, '.')) then $ext else fn:concat('.', $ext) },
            $ldse-settings/ldse:cache-clearing/ldse:exclude-lang-extensions/ldse:ext/fn:lower-case(xs:string(.))
        )
    );

declare variable $related-cache-urls as element(ldse:related-urls)* := $ldse-settings/ldse:cache-clearing/ldse:related-urls;
(: END CACHE CLEARING :)

(: SITE MAPS :)
declare variable $sitemap-indexes as element()* := $ldse-settings/ldse:site-maps/(ldse:rangeElementAttrIndex|ldse:rangeElementIndex);
(: END SITE MAPS:)

(: STATS :)
    declare variable $stats-contexts as xs:string* := $ldse-settings/ldse:statistics/ldse:context;
(: END STATS :)
(: Binary Manager :)
    declare variable $binary-manager as element(ldse:binary-manager)? := $ldse-settings/ldse:binary-manager;
    declare variable $binary-manager-active as xs:boolean := $ldse-settings/ldse:binary-manager/@active = "true";
    declare variable $binary-manager-extensions as element(ldse:ext)* :=  $ldse-settings/ldse:binary-manager/ldse:extensions/ldse:ext;
    declare variable $binary-manager-root-uri as xs:string* :=  $ldse-settings/ldse:binary-manager/ldse:root-uri;
    declare variable $crop-settings as element(ldse:image-crop-settings)? := $ldse-settings/ldse:image-crop-settings;
    declare variable $deep-zoom as element(ldse:deep-zoom)? := $ldse-settings/ldse:image-crop-settings/ldse:deep-zoom;
    declare variable $aspect-ratios as element(ldse:aspect-ratio)* := $ldse-settings/ldse:image-crop-settings/ldse:aspect-ratio;
    declare function settings:extract-meta($extension as xs:string?) as xs:boolean {
        fn:empty( $ldse-settings/ldse:binary-manager/ldse:extensions/ldse:ext[ . = $extension and @extract-meta = "false"] )
    };
(: END Binary Manager :)

declare variable $default-admin-navigation as element(ldse:admin-navigation)? :=
    <admin-navigation xmlns="http://lds.org/code/lds-edit">
        <link uri="{ if (fn:exists($shared-prefix) and fn:not($shared-prefix = "")) then ($shared-prefix) else ('/') }" icon="ldse-icon-preview" sequence="0" title="{$display-name}" />
        <link uri="{ $shared-prefix }" icon="ldse-icon-home" permission="ldse:view-lds-edit-home" sequence="10" title="LDS Publisher Home" />
        { if ( $correlation-used = 'true' ) then ( <link uri="{ $shared-prefix }/correlation" icon="ldse-icon-legal" permission="ldse:view-correlation" title="Cor-IP / Cor-Eval" sequence="20"/> ) else () }
        <link uri="{ $shared-prefix }/content" icon="ldse-icon-folder" permission="ldse:view-binary-manager" sequence="30" title="Content Manager" />
        <link uri="{ $shared-prefix }/page-manager" icon="ldse-icon-page" permission="ldse:view-pages-admin" sequence="34" title="Page Manager" />
        <link uri="{ $shared-prefix }/content-admin" icon="ldse-icon-folder" permission="ldse:view-binary-manager" sequence="35" title="Content Admin" testid="contentadmin"/>
        <link uri="{ $shared-prefix }/sensitive/approve" icon="ldse-icon-review" permission="ldse:view-approve-sensitive" sequence="36" title="Approve Sensitive Item" />
        <link uri="{ $shared-prefix }/sensitive" icon="ldse-icon-list" permission="ldse:view-unpublish-sensitive" sequence="40" title="Sensitive Item List" />
        <menu title="Sites" icon="ldse-icon-globe" permission="ldse:view-lds-edit-home" sequence="4">
            { sp:get-site-links() }
        </menu>
        <menu title="Translation" icon="ldse-icon-globe" permission="ldse:view-translation" sequence="40">
            <link uri="{ $shared-prefix }/translation" icon="icon-page" permission="ldse:view-translation" sequence="20" title="Translation Manager" />
            <link uri="{ $shared-prefix }/translation/submit/to-translation" icon="icon-page" permission="ldse:send-to-translation" sequence="21" title="Submit Pages/Resource Bundles to Translation" />
            <link uri="{ $shared-prefix }/translation/archives/to-translation" icon="icon-page" permission="ldse:view-translation-archive" sequence="22" title="Files Sent to Translation" />
            <link uri="{ $shared-prefix }/translation/archives/from-translation" icon="icon-page" permission="ldse:view-translation-archive" sequence="23" title="Files Returned From Translation" />
            <!-- This schema and code are ready to support Sub-Menus, but the CSS and Javascript are not.  To see the effect, uncomment the following <menu/> -->
            <!--<menu title="Translation Sub 1" icon="ldse-icon-globe" permission="ldse:view-translation" sequence="30">
                <link uri="{ $shared-prefix }/translation" icon="icon-page" permission="ldse:view-translation" sequence="10" title="Translation Manager" />
                <link uri="{ $shared-prefix }/translation/archives" icon="icon-page" permission="ldse:view-translation-archive" sequence="20" title="Translation Archives" />
                <menu title="Translation Sub 2" icon="ldse-icon-globe" permission="ldse:view-translation" sequence="30">
                    <link uri="{ $shared-prefix }/translation" icon="icon-page" permission="ldse:view-translation" sequence="10" title="Translation Manager" />
                    <link uri="{ $shared-prefix }/translation/archives" icon="icon-page" permission="ldse:view-translation-archive" sequence="20" title="Translation Archives" />
                </menu>
            </menu>-->
        </menu>
        <menu icon="ldse-icon-tools" sequence="15" pages="true" title="Admin Pages">
            <link uri="{ $shared-prefix }" icon="acrobat" permission="ldse:view-lds-edit-home" sequence="0" title="Dashboard" ixf-only="true"/>
            <link uri="{ $shared-prefix }/clear-cache" icon="address" permission="ldse:view-clear-cache" sequence="10" title="Clear Cache" />
            <link uri="{ $shared-prefix }/reports" icon="report" permission="ldse:view-reports-admin" sequence="20" title="Content Reports" />
            <link uri="{ $shared-prefix }/ice/form-validator" icon="info" permission="ldse:validate-forms" sequence="40" title="Form Validator" />
            <link uri="{ $shared-prefix }/binary" icon="folder_open" permission="ldse:view-binary-manager" sequence="50" title="Multimedia" />
            {(:<link uri="{ $shared-prefix }/form" data-post.issubmission="{$is-submitter}" data-post.option="form:pageBuilder" data-post.page="/" data-post.action="add" onclick="ICE.postLink(this); return false;" icon="ko-add" permission="ldse:add-new-page" sequence="55" title="New Page From Template" />:)}
{(:            <link uri="{ $shared-prefix }/form" hash="#settings" data-post.issubmission="{$is-submitter}" data-post.option="form:pageBuilder" data-post.page="/" data-post.action="add" onclick="ICE.postLink(this); return false;" icon="ko-add" permission="ldse:add-new-page" sequence="55" title="New Page From Template" />
            <link uri="{ $shared-prefix }/redirect-manager" icon="share" permission="ldse:view-redirect-manager" sequence="55" title="Redirect Manager" />
            <link uri="{ $shared-prefix }/rewrite-manager" icon="share" permission="ldse:view-rewrite-manager" sequence="60" title="Rewrite Manager" />:)}
            <link uri="{ $shared-prefix }/seomoz" permission="ldse:view-seomoz-page" sequence="70" title="Seomoz" />
            <link uri="{ $shared-prefix }/scripts" icon="edit" permission="ldse:view-xml" sequence="75" title="Scripts" />
            <link uri="{ $shared-prefix }/stats" icon="edit" permission="ldse:view-stats-admin" sequence="80" title="Stats" />
            <link uri="{ $shared-prefix }/string-manager" icon="edit" permission="ldse:view-rice-admin" sequence="90" title="String Manager" />
            <link uri="{ $shared-prefix }/supported-languages" icon="icon-page" permission="ldse:view-supported-languages" sequence="100" title="Supported Languages" />
            <link uri="{ $shared-prefix }/user-manager" icon="lds_account" permission="ldse:grant-permissions" sequence="110" title="User Manager" />
        </menu>
    </admin-navigation>
;

declare variable $admin-navigation as element(ldse:admin-navigation)? :=
    $ldse-settings/ldse:admin-navigation
;

(: SEOMOZ :)
    declare variable $seomoz as element(ldse:seomoz-settings)? :=
        (
            $ldse-settings/ldse:seomoz-settings,
            <seomoz-settings xmlns="http://lds.org/code/lds-edit">
                <service-url>/linkscape/url-metrics/</service-url>
                <api-host>lsapi.seomoz.com</api-host>
                <access-id>member-72a6d73ab9</access-id>
                <secret-key>0cad20bb4d55b205663c902fc24688ec</secret-key>
                <minutes-to-expiration>5</minutes-to-expiration>
                <url-metrics>
                    <metric name="Title" bit-flag="1" responseFld="ut" active="false"><desc>The title of the page if available. For example: "Request-Response Format"</desc></metric>
                    <metric name="URL" bit-flag="4" responseFld="uu" active="false"><desc>The canonical form of the URL.  For example: "www.seomoz.org"</desc></metric>
                    <metric name="Subdomain" bit-flag="8" responseFld="ufq" active="false"><desc>The subdomain of the URL.  For example: "apiwiki.seomoz.org"</desc></metric>
                    <metric name="Root Domain" bit-flag="16" responseFld="upl" active="false"><desc>The root domain of the URL.  For example: "seomoz.org"</desc></metric>
                    <metric name="External Links" bit-flag="32" responseFld="ueid" active="true"><desc>The number of juice-passing external links to the URL.</desc></metric>
                    <metric name="Subdomain External Links" bit-flag="64" responseFld="feid" active="false"><desc>The number of juice-passing external links to the subdomain of the URL.</desc></metric>
                    <metric name="Root Domain External Links" bit-flag="128" responseFld="peid" active="true"><desc>The number of juice-passing external links to the root domain of the URL.</desc></metric>
                    <metric name="Juice-Passing Links" bit-flag="256" responseFld="ujid" active="false"><desc>The number of juice-passing links (internal or external) to the URL.</desc></metric>
                    <metric name="Subdomains Linking" bit-flag="512" responseFld="uifq" active="false"><desc>The number of subdomains with any pages linking to the URL.</desc></metric>
                    <metric name="Root Domains Linking" bit-flag="1024" responseFld="uipl" active="false"><desc>The number of root domains with any pages linking to the URL.</desc></metric>
                    <metric name="Links" bit-flag="2048" responseFld="uid" active="false"><desc>The number of links (juice-passing or not, internal or external) to the URL.</desc></metric>
                    <metric name="Subdomain Subdomains Linking" bit-flag="4096" responseFld="fid" active="false"><desc>The number of subdomains with any pages linking to the subdomain of the URL.</desc></metric>
                    <metric name="Root Domain Root Domains Linking" bit-flag="8192" responseFld="pid" active="false"><desc>The number of root domains with any pages linking to the root domain of the URL.</desc></metric>
                    <metric name="MozRank" bit-flag="16384" responseFld="umrp" active="true"><desc>The mozRank of the URL. Requesting this metric will provide the pretty 10-point score (in umrp)</desc></metric>
                    <metric name="Subdomain MozRank" bit-flag="32768" responseFld="fmrp" active="false"><desc>The mozRank of the subdomain of the URL.  Requesting this metric will provide the pretty 10-point score (fmrp)</desc></metric>
                    <metric name="Root Domain MozRank" bit-flag="65536" responseFld="pmrp" active="false"><desc>The mozRank of the Root Domain of the URL.  Requesting this metric will provide both the pretty 10-point score (pmrp) and the raw score (pmrr).</desc></metric>
                    <metric name="MozTrust" bit-flag="131072" responseFld="utrp" active="true"><desc>The mozTrust of the URL. Requesting this metric will provide the pretty 10-point score (utrp)</desc></metric>
                    <metric name="Subdomain MozTrust" bit-flag="262144" responseFld="ftrp" active="false"><desc>The mozTrust of the subdomain of the URL.  Requesting this metric will provide both the pretty 10-point score (ftrp) and the raw score (ftrr).</desc></metric>
                    <metric name="Root Domain MozTrust" bit-flag="524288" responseFld="ptrp" active="false"><desc>The mozTrust of the root domain of the URL.  Requesting this metric will provide both the pretty 10-point score (ptrp) and the raw score (ptrr).</desc></metric>
                    <metric name="External MozRank" bit-flag="1048576" responseFld="uemrp" active="false"><desc>The portion of the URLs mozRank coming from external links. You get both the pretty 10-point score (uemrp) and the raw score (uemrr).</desc></metric>
                    <metric name="Root Domain External Domain juice" bit-flag="4194304" responseFld="pejp" active="false"><desc>The portion of the mozRank of all pages on the root domain coming from external links. You get both the pretty 10-digit score (pejp) and the raw source.</desc></metric>
                    <metric name="Subdomain Domain Juice" bit-flag="8388608" responseFld="fjp" active="false"><desc>The mozRank of all pages on the subdomain combined. You get the pretty 10-point score (fjp) and the raw score (fjr).</desc></metric>
                    <metric name="Root Domain Domain Juice" bit-flag="16777216" responseFld="pjp" active="false"><desc>The mozRank of all pages on the root domain combined. You get both the pretty 10-point score (pjp) and the raw score (pjr).</desc></metric>
                    <metric name="HTTP Status Code" bit-flag="536870912" responseFld="us" active="false"><desc>The HTTP status code recorded by Mozscape for this URL (if available).</desc></metric>
                    <metric name="Links to Subdomain" bit-flag="4294967296" responseFld="fuid" active="false"><desc>Total links (including internal and nofollow links) to the subdomain of the URL.</desc></metric>
                    <metric name="Links to Root Domain" bit-flag="8589934592" responseFld="puid" active="false"><desc>The number of root domains with at least one link to the subdomain of the URL.</desc></metric>
                    <metric name="Root Domains linking to Subdomain" bit-flag="17179869184" responseFld="fipl" active="false"><desc>The number of root domains with at least one link to the subdomain of the URL.</desc></metric>
                    <metric name="Page Authority" bit-flag="34359738368" responseFld="upa" active="true"><desc>A score out of 100 points representing the likelihood of a page to rank well, regardless of content</desc></metric>
                    <metric name="Domain Authority" bit-flag="68719476736" responseFld="pda" active="false"><desc>A score out of 100 points representing the likelihood of a domain to rank well, regardless of content</desc></metric>
                </url-metrics>
            </seomoz-settings>
        )[1];
(: END SEOMOZ :)


(: Cor-IP / Cor-Eval :)
    declare variable $correlation-enabled as xs:boolean := fn:false()
(:    let $exception as xs:boolean :=
        ($ldse-settings/ldse:correlation-settings/ldse:enabled eq "false"
        and $environment ne "prod")
        or $ldse-settings/ldse:correlation-settings/ldse:exception-site eq "true"

    return
        if($exception)
        then fn:false()

        else if(
                fn:exists($ldse-settings/ldse:correlation-settings/node())
                and fn:exists($ldse-settings/ldse:correlation-settings/ldse:login[@username][@password])
                and fn:exists($ldse-settings/ldse:correlation-settings/ldse:department-code/text())
                and fn:exists($ldse-settings/ldse:correlation-settings/ldse:project-id[@default eq "true"]/text())
                and fn:exists($ldse-settings/ldse:correlation-settings/ldse:post-to-server[@name = $environment]/text())
            )
            then fn:true()

        else
            if(fn:not(fn:exists($ldse-settings/ldse:correlation-settings/node())))
            then fn:error(xs:QName("CorIPCorEval"), "Missing required correlation-settings in ldse-settings.xml")

            else if(fn:not(fn:exists($ldse-settings/ldse:correlation-settings/ldse:login[@username][@password])))
            then fn:error(xs:QName("CorIPCorEval"), "Missing required correlation-settings/login element in ldse-settings.xml")

            else if(fn:not(fn:exists($ldse-settings/ldse:correlation-settings/ldse:department-code/text())))
            then fn:error(xs:QName("CorIPCorEval"), "Missing required correlation-settings/department-code element in ldse-settings.xml")

            else if(fn:not(fn:exists($ldse-settings/ldse:correlation-settings/ldse:project-id[@default eq "true"]/text())))
            then fn:error(xs:QName("CorIPCorEval"), "Missing required correlation-settings/project-id element in ldse-settings.xml")

            else if(fn:not(fn:exists($ldse-settings/ldse:correlation-settings/ldse:post-to-server[@name = $environment]/text())))
            then fn:error(xs:QName("CorIPCorEval"), "Missing required correlation-settings/post-to-server element in ldse-settings.xml")

            else fn:error(xs:QName("CorIPCorEval"), "Missing required correlation-settings element in ldse-settings.xml"):)
        ;

    declare variable $correlation-reporting-statement-options as element(option)* :=
        <options>
            <option data-value="0">Please select</option>
            <option data-value="1">RS - FTE</option>
            <option data-value="2">RS - Magazine Staff</option>
            <option data-value="3">RS - Translation</option>
            <option data-value="4">RS - GA</option>
            <option data-value="5">RS - TCH</option>
            <option data-value="6">RS - Set Design</option>
            <option data-value="7">RS - Unrecognizable Image</option>
            <option data-value="8">RS - News</option>
            <option data-value="9">RS - Documentary Image</option>
            <option data-value="10">RS - Screenshots</option>
            <option data-value="11">RS - Product Shots</option>
            <option data-value="12">RS - Incidental Image</option>
            <option data-value="13">RS - Ordinary Text</option>
            <option data-value="14">RS - Scriptures</option>
            <option data-value="15">RS - Repurposed Text</option>
            <option data-value="16">RS - Previously Approved Products</option>
            <option data-value="17">RS - Grandfathered Product</option>
            <option data-value="18">RS - Repurposed Church Documents</option>
            <option data-value="19">RS - Promotional Clips for Kiosks</option>
            <option data-value="20">RS - Implied Consent for Vendor Forms</option>
            <option data-value="21">RS – Implied Consent for Training Materials</option>
            <option data-value="22">RS – VIO Incidental</option>
            <option data-value="23">RS – Exhibits</option>
            <option data-value="24">RS – Public Domain</option>
        </options>/option;

    declare variable $brightcove-settings as element(ldse:brightcove-settings)? :=
        ($ldse-settings/ldse:brightcove-settings,
        <brightcove-settings  xmlns="http://lds.org/code/lds-edit">
            <player-id-element-xpath>//(player-id | playerid | playerId)</player-id-element-xpath>
            <player-key-element-xpath>//(player-key | playerkey | playerKey)</player-key-element-xpath>
            <video-id-element-xpath>//(video-id | videoid | videoId)</video-id-element-xpath>
        </brightcove-settings>)[1];

(: Preview :)
    declare variable $preview-enabled as xs:boolean := ($ldse-settings/ldse:preview/@enabled/xs:boolean(.), fn:true())[1];
(: History :)
    declare variable $history-enabled as xs:boolean := ($ldse-settings/ldse:history/@enabled/xs:boolean(.), fn:true())[1];
    declare variable $history-mode as xs:string := (xs:string($ldse-settings/ldse:history/ldse:mode), $modes[1]/@name)[. != ""][1];
(: COPY TO COUNTRY :)
    declare variable $country-uri-matches as element(ldse:uri-match)* := $ldse-settings/ldse:country-copy/ldse:uri-match;

    declare function settings:is-valid-country-copy($uri as xs:string) as xs:boolean {
        some $uri-match as element(ldse:uri-match) in $country-uri-matches
        satisfies (
            ($uri-match/@uri != "" and $uri = $uri-match/@uri ) or
            ($uri-match/@starts-with != "" and fn:starts-with($uri, $uri-match/@starts-with))
        )
    };
(: END COPY TO COUNTRY :)

(: OMNITURE :)
    declare variable $omniture-service as element() := (
        $ldse-settings/ldse:omniture-service,
        <omniture-service xmlns="http://lds.org/code/lds-edit">
            <url env="dev">http://dev-orig.churchofjesuschrist.org/services/omniture/get-data</url>
            <url env="test">http://dev-orig.churchofjesuschrist.org/services/omniture/get-data</url>
            <url env="stage">http://stage-orig.churchofjesuschrist.org/services/omniture/get-data</url>
            <url env="uat">http://stage-orig.churchofjesuschrist.org/services/omniture/get-data</url>
            <url env="prod">http://orig.churchofjesuschrist.org/services/omniture/get-data</url>
        </omniture-service>
    )[1];

    declare variable $omniture-service-url as xs:string := (
        $omniture-service/ldse:url[@env = $environment],
        "http://l12772:9440/services/omniture/get-data"
    )[1];
(: END OMNITURE :)


(: ADD-ICE :)
    declare variable $add-ice-defaults as element(ldse:defaults)? :=
        let $site-defaults as element(ldse:defaults)? := $ldse-settings/ldse:add-ice/ldse:defaults
        let $our-defaults as element(ldse:defaults) :=
            <defaults xmlns="http://lds.org/code/lds-edit">
                <variables>
                </variables>
                <links>
                    <link name="ldse:edit-component">false</link>
                    <link name="ldse:edit-doc">true</link>
                    <link name="ldse:edit-submission">true</link>
                    <link name="ldse:add-doc">true</link>
                    <link name="ldse:add-submission">true</link>
                    <link name="ldse:view-submission">true</link>
                    <link name="ldse:publish">true</link>
                    <link name="ldse:publish-all">true</link>
                    <link name="ldse:unpublish">true</link>
                    <link name="ldse:remove">false</link>
                    <link name="ldse:remove-file">false</link>
                    <link name="ldse:disable-file">true</link>
                    <link name="ldse:view-preview-page">true</link>
                    <link name="ldse:view-preview-json" no-auth-only="true">true</link>
                    <link name="ldse:view-published-page" published-only="true">true</link>
                    <link name="ldse:view-published-json" published-only="true" no-auth-only="true">true</link>
                    <link name="ldse:view-published-consolidated-page" published-only="true" consolidated="true">true</link>
                    <link name="ldse:view-published-consolidated-json" published-only="true" consolidated="true">true</link>
                    <link name="ldse:titan-images-used">true</link>
                    <link name="ldse:current-page-links" link-api="true">true</link>
                    <link name="ldse:page-used-by" link-api="true">true</link>
                    <link name="ldse:delete">true</link>
                    <link name="ldse:delete-submission">true</link>
                    <link name="ldse:publish-languages">true</link>
                    <link name="ldse:translation-review">true</link>
                    <link name="ldse:edit-teaser-sequence">true</link>
                    <link name="ldse:teaser-search">true</link>
                    <link name="ldse:workflow">true</link>
                    <link name="ldse:translation-ready">true</link>
                    <link name="ldse:duplicate-component">true</link>
                </links>
                <settings>
                    <only-one>false</only-one>
                    <only-clone>false</only-clone>
                    <only-edit>false</only-edit>
                    <ajax>false</ajax>
                </settings>
            </defaults>
        return (
            <defaults xmlns="http://lds.org/code/lds-edit">
                <variables>{
                    let $vars as xs:QName* := $site-defaults/ldse:variables/*/fn:node-name(.)
                    return (
                        $site-defaults/ldse:variables/*,
                        $our-defaults/ldse:variables/*[fn:not(fn:node-name(.) = $vars)]
                    )
                }</variables>
                <links>{
                    let $links as xs:string* := $site-defaults/ldse:links/ldse:link/@name
                    return (
                        $site-defaults/ldse:links/ldse:link,
                        $our-defaults/ldse:links/ldse:link[fn:not(@name = $links)]
                    )
                }</links>
                <settings>{
                    let $settings as xs:QName* := $site-defaults/ldse:settings/*/fn:node-name(.)
                    return (
                        $site-defaults/ldse:settings/*,
                        $our-defaults/ldse:settings/*[fn:not(fn:node-name(.) = $settings)]
                    )
                }</settings>
            </defaults>
        );

    declare variable $add-ice-links as element(ldse:links)* :=
        let $suppress-lang-param := $site-properties/suppress-lang-param/fn:string()
        let $disable-publishing := $site-properties/disable-publishing /fn:string() eq 'true'
        return
        (
            $ldse-settings/ldse:add-ice/ldse:links,
            <links xmlns="http://lds.org/code/lds-edit">
                <link sequence="10" name="ldse:edit-component">
                     <checks>
                        <check op="permission">ldse:edit-doc</check>
                        <and>
                            <check op="exists">$file</check>
                            <check op="exists">$form</check>
                        </and>
                        <not>
                            <check op="is-submission">$file</check>
                        </not>
                        <or>
                            <check op="=" val="true">#only-edit</check>
                            <check op="!=" val="true">#only-clone</check>
                        </or>
                        <check op="=" val="false">$chq-protected</check>
                     </checks>
                     <a href="{{$shared-prefix}}/form?lang={{$lang}}&amp;country={{$country}}&amp;id={{$file-id}}&amp;site={{$site}}" onclick="ICE.postLink(this); return false;" data-post.action="edit" data-post.uri="{{$current-page}}" data-post.page="{{$current-page}}" data-post.option="{{$csv-variables}}" class="ldse-icon-edit" i18n="ldse.edit.{{$type}}">Edit {{$type}} - {{$title}}</a>
                </link>
                <link sequence="10" name="ldse:edit-doc">
                     <checks>
                        <check op="permission">ldse:edit-doc</check>
                        <and>
                            <check op="exists">$file</check>
                            <check op="exists">$form</check>
                        </and>
                        <not>
                            <check op="is-submission">$file</check>
                        </not>
                        <or>
                            <check op="=" val="true">#only-edit</check>
                            <check op="!=" val="true">#only-clone</check>
                        </or>
                        <check op="=" val="false">$chq-protected</check>
                     </checks>
                     <a href="{{$shared-prefix}}/form?lang={{$lang}}&amp;country={{$country}}&amp;id={{$file-id}}&amp;site={{$site}}" onclick="ICE.postLink(this); return false;" data-post.action="edit" data-post.uri="{{$current-page}}" data-post.page="{{$current-page}}" data-post.option="{{$csv-variables}}" class="ldse-icon-edit aaaaa" i18n="ldse.edit.{{$type}}">Edit {{$type}}</a>
                </link>

                <link sequence="10" name="ldse:edit-submission">
                     <checks>
                        <or>
                            <check op="exists">$file</check>
                            <check op="exists">$formXml</check>
                        </or>
                        <check op="=" val="false">$chq-protected</check>
                        <check op="is-submission">$file</check>
                        <or>
                            <check op="=" val="true">#only-edit</check>
                            <check op="!=" val="true">#only-clone</check>
                        </or>
                        <or>
                            <check op="permission">ldse:edit-any-submission</check>
                            <and>
                                <check op="permission">ldse:edit-submission</check>
                                <check op="user-created-file">$file</check>
                                <not>
                                    <check op="submission-submitted">$file</check>
                                </not>
                            </and>
                        </or>
                     </checks>
                     <a href="{{$shared-prefix}}/form?lang={{$lang}}&amp;country={{$country}}&amp;id={{$file-id}}&amp;site={{$site}}" onclick="ICE.postLink(this); return false;" data-post.isSubmission="true" data-post.action="edit" data-post.uri="{{$current-page}}" data-post.page="{{$current-page}}" data-post.option="{{$csv-variables}}" class="ldse-icon-edit" i18n="ldse.edit.{{$type}}">Edit {{$type}}{{$submission-string}}</a>
                </link>

                <link sequence="10" name="ldse:view-submission">
                     <checks>
                        <or>
                            <check op="exists">$file</check>
                            <check op="exists">$formXml</check>
                        </or>
                        <check op="=" val="false">$chq-protected</check>
                        <check op="is-submission">$file</check>
                        <check op="submission-submitted">$file</check>
                        <check op="permission">ldse:view-submission</check>
                        <check op="user-created-file">$file</check>
                        <not>
                            <check op="permission">ldse:edit-any-submission</check>
                        </not>
                        <or>
                            <check op="=" val="true">#only-edit</check>
                            <check op="!=" val="true">#only-clone</check>
                        </or>
                     </checks>
                     <a href="{{$shared-prefix}}/form?lang={{$lang}}&amp;country={{$country}}&amp;id={{$file-id}}&amp;site={{$site}}" onclick="ICE.postLink(this); return false;" data-post.isSubmission="true" data-post.action="view" data-post.uri="{{$current-page}}" data-post.page="{{$current-page}}" data-post.option="{{$csv-variables}}" class="ldse-icon-edit" i18n="ldse.edit.{{$type}}">View {{$type}}{{$submission-string}}</a>
                </link>

                <link sequence="20" name="ldse:edit-navigation">
                     <checks>
                        <check op="permission">ldse:edit-navigation</check>
                        <check op="=" val="sub-channel">$type</check>
                        <or>
                            <check op="empty">$custom-nav</check>
                            <check op="=" val="false">$custom-nav</check>
                        </or>
                     </checks>
                     <a href="" class="ldse-icon-edit" onclick="ICE.subChannelForm('{{$nav-name}}', '{{$node/@name}}', '{{$node/@sequence}}', '{{$current-page}}', '{{$locale}}', '{{$custom-nav}}'); return false;">Edit Global Nav</a>
                </link>
                <link sequence="30" name="ldse:edit-custom-navigation">
                     <checks>
                        <check op="permission">ldse:edit-navigation</check>
                        <check op="=" val="sub-channel">$type</check>
                        <check op="=" val="true">$custom-nav</check>
                     </checks>
                     <a href="" class="ldse-icon-edit" onclick="ICE.subChannelForm('{{$nav-name}}', '{{$node/@name}}', '{{$node/@sequence}}', '{{$current-page}}', '{{$locale}}', '{{$custom-nav}}'); return false;">Edit Custom Nav</a>
                </link>
                <link sequence="40" name="ldse:teaser-manager">
                     <checks>
                        <check op="permission">ldse:teaser-manager</check>
                     </checks>
                     <a href="{{$shared-prefix}}/collections?lang={{$lang}}&amp;country={{$country}}&amp;site={{$site}}" class="ldse-icon-versions manageTeaser" onclick="ICE.postLink(this); return false;" data-post.id="{{$file-id}}" data-post.status="edit" data-post.uri="{{$current-page}}" data-post.page="{{$current-page}}" data-post.option="{{$csv-variables}}">Manage {{$type}}</a>
                </link>

                <link sequence="50" name="ldse:edit-teaser-sequence" custom-call="false">
                    <checks>
                        <check op="=" val="teaser">$file-root</check>
                        <check op="permission">ldse:edit-teaser-sequence</check>
                        <check op="!=" val="true">#only-clone</check>
                        <check op="!=" val="true">#only-one</check>
                        <check op="=" val="true">$chq-protected</check>
                     </checks>
                     <a href="" class="ldse-icon-edit" onclick="ICE.teaserSequenceForm('{{$file-id}}', '{{$locale}}', '{{$current-page}}'); return false;">Edit Sequence</a>
                </link>

                <link sequence="60" name="ldse:teaser-search" custom-call="false">
                    <checks>
                        <check op="=" val="teaser">$file-root</check>
                        <check op="permission">ldse:teaser-search</check>
                        <check op="=" val="true">#chq-only</check>
                     </checks>
                    <a href="" class="ldse-icon-search" onclick="teaserSearch('{{$teaser-type}}', '{{$current-page}}', '{{$current-page}}', '{{$teaser-location}}', '{{$locale}}'); return false;">Search teaser</a>
                </link>

                <link sequence="70" name="ldse:add-doc" custom-call="false">
                    <checks>
                        <check op="permission">ldse:add-doc</check>
                        <or>
                            <check op="=" val="true">#only-clone</check>
                            <and>
                                <check op="!=" val="true">#only-edit</check>
                                <or>
                                    <check op="!=" val="true">#only-one</check>
                                    <check op="empty">$file</check>
                                </or>
                            </and>
                        </or>
                     </checks>
                     <a href="{{$shared-prefix}}/form?lang={{$lang}}&amp;country={{$country}}&amp;site={{$site}}" onclick="ICE.postLink(this); return false;" data-post.action="add" data-post.uri="{{$current-page}}" data-post.page="{{$current-page}}" data-post.option="{{$csv-variables}}" class="ldse-icon-ko-add" i18n="ldse.edit.{{$type}}">Add {{$type}}</a>
                </link>

                <link sequence="70" name="ldse:add-submission" custom-call="false">
                    <checks>
                        <check op="permission">ldse:add-submission</check>
                        <not>
                            <check op="permission">ldse:add-doc</check>
                        </not>
                        <or>
                            <check op="=" val="true">#only-clone</check>
                            <and>
                                <check op="!=" val="true">#only-edit</check>
                                <or>
                                    <check op="!=" val="true">#only-one</check>
                                    <check op="empty">$file</check>
                                </or>
                            </and>
                        </or>
                     </checks>
                     <a href="{{$shared-prefix}}/form?lang={{$lang}}&amp;country={{$country}}&amp;site={{$site}}" onclick="ICE.postLink(this); return false;" data-post.action="add" data-post.isSubmission="true" data-post.uri="{{$current-page}}" data-post.page="{{$current-page}}" data-post.option="{{$csv-variables}}" class="ldse-icon-ko-add" i18n="ldse.edit.{{$type}}">Add {{$type}}{{$submission-string}}</a>
                </link>

                <link sequence="80" name="ldse:publish" custom-call="false">
                    <checks>
                        <check op="action">ldse:publish</check>
                        <check op="!=" val="true">#only-clone</check>
                        <check op="!=" val="true">#only-edit</check>
                        <check op="exists">$file</check>
                        <check op="correlationcanpublish">$file</check>
                        {
                            if ( $settings:has-sensitive = 'true' ) then (
                                <or>
                                    <check op="approved"></check>
                                    <not>
                                        <check op="is-sensitive"></check>
                                    </not>
                                </or>
                            ) else ()
                        }
                     </checks>
                    {
                        if ($disable-publishing) then ()
                        else <a href="" class="ldse-icon-send" onclick="ACT.item('ldse:publish', '{{$current-page}}', '{{$locale}}', '{{$publish-type}}', '{{$file-id}}', '{{$site}}'); return false;" i18n="ldse.publish" >Publish Component</a>
                    }
                </link>

                <link sequence="85" name="ldse:publish-all" custom-call="false">
                    <checks>
                        <check op="action">ldse:publish</check>
                        <check op="!=" val="true">#only-clone</check>
                        <check op="!=" val="true">#only-edit</check>
                        <check op="exists">$file</check>
                        <check op="correlationcanpublish">$file</check>
                        {
                            if ( $settings:has-sensitive = 'true' ) then (
                                <or>
                                    <check op="approved"></check>
                                    <not>
                                        <check op="is-sensitive"></check>
                                    </not>
                                </or>
                            ) else ()
                        }
                     </checks>
                    {
                        if ($disable-publishing) then ()
                        else <a class="ldse-icon-send" onclick="performActionOnItems('ldse:publish', '{{$current-page}}', '{{$lang}}', '{{$site}}', true, '{{$file-id}}'); return false;" data-testid="{{$test-id}}">Publish Page &amp; Content</a>
                    }
                </link>

                <link sequence="90" name="ldse:publish-jericho" custom-call="false">
                    <checks>
                        <check op="action">ldse:publish</check>
                        <check op="permission">ldse:publish-jericho</check>
                        <check op="=" val="sub-channel">$type</check>
                        <check op="=" val="jericho">$nav-name</check>
                        <or>
                            <check op="empty">$custom-nav</check>
                            <check op="=" val="false">$custom-nav</check>
                        </or>

                     </checks>
                     <a href="" class="ldse-icon-send" onclick="ACT.publishJericho('{{$current-page}}', '{{$locale}}'); return false;">Publish Jericho</a>
                </link>

                <link sequence="100" name="ldse:publish-navigation" custom-call="false">
                    <checks>
                        <check op="action">ldse:publish</check>
                        <check op="permission">ldse:publish-navigation</check>
                        <check op="=" val="sub-channel">$type</check>
                        <check op="!=" val="jericho">$nav-name</check>
                        <or>
                            <check op="empty">$custom-nav</check>
                            <check op="=" val="false">$custom-nav</check>
                        </or>
                     </checks>
                     <a href="" class="ldse-icon-send" onclick="ACT.publishNav('{{$current-page}}', '{{$locale}}', '{{$nav-name}}'); return false;">Publish Nav</a>
                </link>

                {
                    if ($disable-publishing) then ()
                    else
                        <link sequence="110" name="ldse:publish-languages" custom-call="false">
                            <checks>
                                <check op="permission">ldse:publish-languages</check>
                                <check op="!=" val="true">#only-clone</check>
                                <check op="!=" val="true">#only-edit</check>
                                <check op="exists">$file</check>
                                <check op="=" val="true">#chq-only</check>
                                <check op="has-translated-files">$file</check>
                                <or>
                                    <and>
                                        <check op="is-submission">$file</check>
                                        <check op="submission-submitted">$file</check>
                                    </and>
                                    <not>
                                        <check op="is-submission">$file</check>
                                    </not>
                                </or>
                            </checks>
                            <a class="ldse-icon-send pub" href="{{$shared-prefix}}/form?lang={{$locale}}&amp;id={{$file-id}}&amp;site={{$site}}#translations" onclick="$.newWindow(this.href); return false;">Publish Languages</a>
                        </link>
                }

                <link sequence="120" name="ldse:unpublish" custom-call="false">
                    <checks>
                        <check op="action">ldse:unpublish</check>
                        <check op="=" val="true">$is-published</check>
                        <check op="!=" val="true">#only-clone</check>
                        <check op="!=" val="true">#only-edit</check>
                     </checks>
                     <a href="" class="ldse-icon-unpublish" onclick="ACT.item('ldse:unpublish', '{{$current-page}}', '{{$locale}}', '{{$publish-type}}', '{{$file-id}}', '{{$site}}'); return false;">Un-Publish</a>
                </link>

                <link sequence="130" name="ldse:remove" custom-call="false">
                    <checks>
                        <check op="action">ldse:remove</check>
                        <check op="!=" val="true">#only-clone</check>
                        <check op="!=" val="true">#only-edit</check>
                        <check op="exists">$file</check>
                        <check op="=" val="true">#chq-only</check>
                        <not><check op="=" val="true">#disable-remove</check></not>
                     </checks>
                     <a href="" class="ldse-icon-ko-remove" onclick="ACT.item('ldse:remove', '{{$current-page}}', '{{$locale}}', '{{$publish-type}}', '{{$file-id}}'); return false;">Remove</a>
                </link>

                <link sequence="130" name="ldse:remove-file" custom-call="false">
                    <checks>
                        <check op="!=" val="true">#only-edit</check>
                        <check op="exists">$file</check>
                        <check op="!=" val="pageBuilder">$form</check>
                        <check op="!=" val="article">$form</check>
                        <check op="!=" val="site-creator">$form</check>
                     </checks>
                     <a href="" class="ldse-icon-ko-remove" onclick="ACT.item('ldse:remove-from-page', '{{$current-page}}', '{{$locale}}', '{{$publish-type}}', '{{$file-id}}', '{{$site}}', this); return false;">Remove File from Page</a>
                </link>

                <link sequence="135" name="ldse:duplicate-component" custom-call="false">
                    <checks>
                        <check op="exists">$file</check>
                        <check op="!=" val="pageBuilder">$form</check>
                        <check op="!=" val="article">$form</check>
                        <check op="!=" val="site-creator">$form</check>
                        <check op="=" val="true">#can-duplicate-component</check>
                    </checks>
                    <a href="" class="ldse-icon-copy" onclick="ICE.duplicateComponent('{{$site}}', '{{$locale}}','{{$current-page}}', '{{$file-id}}', this); return false;">Duplicate Component</a>
                </link>

                <link sequence="140" name="ldse:delete" custom-call="false">
                    <checks>
                        <check op="!=" val="true">#only-clone</check>
                        <check op="!=" val="true">#only-edit</check>
                        <check op="exists">$file</check>
                        <not>
                            <check op="=" val="true">#disable-delete</check>
                        </not>
                        <or>
                            <and>
                                <check op="is-submission">$file</check>
                                <or>
                                    <and>
                                        <check op="permission">ldse:delete-submission</check>
                                        <check op="user-created-file">$file</check>
                                        <not>
                                            <check op="submission-submitted">$file</check>
                                        </not>
                                    </and>
                                    <check op="permission">ldse:delete-doc</check>
                                </or>
                            </and>
                            <and>
                                <not>
                                    <check op="is-submission">$file</check>
                                </not>
                                <check op="permission">ldse:delete-doc</check>
                            </and>
                        </or>
                     </checks>
                     <a href="" class="ldse-icon-trash" onclick="ACT.item('ldse:delete', '{{$current-page}}', '{{$locale}}', '{{$publish-type}}', '{{$file-id}}', '{{$site}}'); return false;">Delete</a>
                </link>

                <link sequence="150" name="ldse:translation-review" custom-call="false">
                    <checks>
                        <check op="translation" step="returned" action="complete"></check>
                        <check op="!=" val="">$file-id</check>
                        <check op="=" val="true">#chq-only</check>
                        <check op="!=" val="">$file-id</check>
                     </checks>
                     <a href="" class="ldse-icon-review" onclick="ICE.translationMark('returned', 'complete', '{{$file-id}}', this); return false;">Mark Reviewed</a>
                </link>

                <link sequence="150" name="ldse:translation-ready" custom-call="false">
                    <checks>
                        <check op="!=" val="">$file-id</check>
                        <check op="=" val="true">#chq-only</check>
                        <check op="!=" val="">$file-id</check>
                     </checks>
                     <a href="" class="ldse-icon-review" onclick="ICE.translationReady('ready', 'complete', '{{$lang}}', '{{$file-id}}', this); return false;">Mark Ready</a>
                </link>
                <link sequence="151" name="ldse:view-preview-page" custom-call="false">
                    <checks>
                        <check op="!=" val="true">#only-edit</check>
                        <check op="exists">$file</check>
                        <check op="=" val="pageBuilder">$form</check>
                        <check op="!=" val="article">$form</check>
                        <check op="!=" val="site-creator">$form</check>
                    </checks>
                    {
                        if ($suppress-lang-param eq 'true') then
                            <a href="//{$preview-host}{$devop-prefix}{{$current-page}}" class="ldse-icon-binoculars" target="_blank">Preview Page</a>
                        else
                            <a href="//{$preview-host}{$devop-prefix}{{$current-page}}?lang={{$lang}}" class="ldse-icon-binoculars" target="_blank">Preview Page</a>
                    }
                </link>
                <link sequence="152" name="ldse:view-preview-json" custom-call="false">
                    <checks>
                        <check op="!=" val="true">#only-edit</check>
                        <check op="exists">$file</check>
                        <check op="=" val="pageBuilder">$form</check>
                        <check op="!=" val="article">$form</check>
                        <check op="!=" val="site-creator">$form</check>
                    </checks>
                    {
                        if ($suppress-lang-param eq 'true') then
                            <a href="{$cms-api}{$preview-host}{$devop-prefix}{{$current-page}}"  class="ldse-icon-tools" target="_blank">Preview JSON</a>
                        else
                            <a href="{$cms-api}{$preview-host}{$devop-prefix}{{$current-page}}&amp;lang={{$lang}}"  class="ldse-icon-tools" target="_blank">Preview JSON</a>
                    }
                </link>
                <link sequence="153" name="ldse:view-published-page" custom-call="false">
                    <checks>
                        <check op="!=" val="true">#only-edit</check>
                        <check op="exists">$file</check>
                        <check op="=" val="pageBuilder">$form</check>
                        <check op="!=" val="article">$form</check>
                        <check op="!=" val="site-creator">$form</check>
                    </checks>
                    {
                        if ($suppress-lang-param eq 'true') then
                          <a href="//{$published-host}{$devop-prefix}{{$current-page}}"  class="ldse-icon-binoculars" target="_blank">Published Page</a>
                        else
                          <a href="//{$published-host}{$devop-prefix}{{$current-page}}?lang={{$lang}}"  class="ldse-icon-binoculars" target="_blank">Published Page</a>
                    }
                </link>
                <link sequence="154" name="ldse:view-published-json" custom-call="false">
                    <checks>
                        <check op="!=" val="true">#only-edit</check>
                        <check op="exists">$file</check>
                        <check op="=" val="pageBuilder">$form</check>
                        <check op="!=" val="article">$form</check>
                        <check op="!=" val="site-creator">$form</check>
                    </checks>
                    {
                        if ($suppress-lang-param eq 'true') then
                            <a href="{$cms-api}{$published-host}{$devop-prefix}{{$current-page}}" class="ldse-icon-tools" target="_blank">Published JSON</a>
                        else
                            <a href="{$cms-api}{$published-host}{$devop-prefix}{{$current-page}}&amp;lang={{$lang}}" class="ldse-icon-tools" target="_blank">Published JSON</a>
                    }
                </link>
                <link sequence="155" name="ldse:view-published-consolidated-page" custom-call="false">
                    <checks>
                        <check op="!=" val="true">#only-edit</check>
                        <check op="exists">$file</check>
                        <check op="=" val="pageBuilder">$form</check>
                        <check op="!=" val="article">$form</check>
                        <check op="!=" val="site-creator">$form</check>
                    </checks>
                    <a href="//{$consolidated-host}{{$current-page}}?lang={{$lang}}"  class="ldse-icon-binoculars" target="_blank">Published Consolidated Page</a>
                </link>
                <link sequence="156" name="ldse:view-published-consolidated-json" custom-call="false">
                    <checks>
                        <check op="!=" val="true">#only-edit</check>
                        <check op="exists">$file</check>
                        <check op="=" val="pageBuilder">$form</check>
                        <check op="!=" val="article">$form</check>
                        <check op="!=" val="site-creator">$form</check>
                    </checks>
                    <a href="{$cms-api}{$consolidated-host}{{$current-page}}&amp;lang={{$lang}}" class="ldse-icon-tools" target="_blank">Published Consolidate JSON</a>
                </link>
                <link sequence="157" name="ldse:titan-images-used" custom-call="false">
                    <checks>
                        <check op="!=" val="true">#only-edit</check>
                        <check op="exists">$file</check>
                        <check op="=" val="pageBuilder">$form</check>
                        <check op="!=" val="article">$form</check>
                        <check op="!=" val="site-creator">$form</check>
                    </checks>
                    <a href="{$titan-images-used-api}{{$file-id}}&amp;lang={{$lang}}&amp;site={{$site}}" class="ldse-icon-picture" target="_blank">Titan Images Used</a>
                </link>
                <link sequence="158" name="ldse:current-page-links" custom-call="false">
                    <checks>
                        <check op="!=" val="true">#only-edit</check>
                        <check op="exists">$file</check>
                        <check op="=" val="pageBuilder">$form</check>
                        <check op="!=" val="article">$form</check>
                        <check op="!=" val="site-creator">$form</check>
                    </checks>
                    <a href="{$find-page-links}{{$file-id}}&amp;lang={{$lang}}&amp;site={{$site}}" class="ldse-icon-link" target="_blank">Current page links</a>
                </link>
                <link sequence="159" name="ldse:page-used-by" custom-call="false">
                    <checks>
                        <check op="!=" val="true">#only-edit</check>
                        <check op="exists">$file</check>
                        <check op="=" val="pageBuilder">$form</check>
                        <check op="!=" val="article">$form</check>
                        <check op="!=" val="site-creator">$form</check>
                    </checks>
                    <a href="{$page-used-by}{{$file-id}}&amp;lang={{$lang}}&amp;site={{$site}}" class="ldse-icon-list" target="_blank">Components linked to this page</a>
                </link>
                <link sequence="160" name="ldse:disable-file" custom-call="false">
                    <checks>
                        <check op="!=" val="true">#only-edit</check>
                        <check op="exists">$file</check>
                        <check op="!=" val="pageBuilder">$form</check>
                        <check op="!=" val="article">$form</check>
                        <check op="!=" val="site-creator">$form</check>
                     </checks>
                     <a href="" class="ldse-icon-unpublish ldse-status-disable" onclick="ACT.item('ldse:disable-from-page', '{{$current-page}}', '{{$locale}}', '{{$publish-type}}', '{{$file-id}}', '{{$site}}', this); return false;">Disable</a>
                </link>
            </links>
        );

    declare function settings:get-ice-link-by-name($name as xs:string) as element(ldse:link)? {
        ($add-ice-links[1]/ldse:link[@name = $name], $add-ice-links[2]/ldse:link[@name = $name])[1]
    };

(: END ADD-ICE :)

(: ADD-GEAR:)

    declare variable $add-gear-defaults as element(ldse:defaults)? :=
        let $site-defaults as element(ldse:defaults)? := $ldse-settings/ldse:add-gear/ldse:defaults
        let $our-defaults as element(ldse:defaults) :=
            <defaults xmlns="http://lds.org/code/lds-edit">
                <variables>
                </variables>
                <links>
                    <link name="ldse:gear-publish">true</link>
                    <link name="ldse:gear-unpublish">true</link>
                    <link name="ldse:gear-publish-meta">true</link>
                    <link name="ldse:gear-settings">true</link>
                    <link name="ldse:gear-edit-hidden-resources">true</link>
                    <link name="ldse:gear-clone-page">true</link>
                    <link name="ldse:gear-change-template">true</link>
                    <link name="ldse:gear-omniture">true</link>
                    <link name="ldse:gear-seomoz">true</link>
                    <link name="ldse:gear-add-poll">false</link>
                    <link name="ldse:gear-new-page">true</link>
                    <link name="ldse:gear-toggle-carousel">false</link>
                    <link name="ldse:page-editor">true</link>
                </links>
                <settings>
                </settings>
            </defaults>
        return (
            <defaults xmlns="http://lds.org/code/lds-edit">
                <variables>{
                    let $vars as xs:QName* := $site-defaults/ldse:variables/*/fn:node-name(.)
                    return (
                        $site-defaults/ldse:variables/*,
                        $our-defaults/ldse:variables/*[fn:not(fn:node-name(.) = $vars)]
                    )
                }</variables>
                <links>{
                    let $links as xs:string* := $site-defaults/ldse:links/ldse:link/@name
                    return (
                        $site-defaults/ldse:links/ldse:link,
                        $our-defaults/ldse:links/ldse:link[fn:not(@name = $links)]
                    )
                }</links>
                <settings>{
                    let $settings as xs:QName* := $site-defaults/ldse:settings/*/fn:node-name(.)
                    return (
                        $site-defaults/ldse:settings/*,
                        $our-defaults/ldse:settings/*[fn:not(fn:node-name(.) = $settings)]
                    )
                }</settings>
            </defaults>
        );

    declare variable $add-gear-links as element(ldse:links)* :=
        (
            $ldse-settings/ldse:add-gear/ldse:links,
            <links xmlns="http://lds.org/code/lds-edit">

                <link sequence="40" name="ldse:gear-publish-meta" custom-call="false">
                    <checks>
                        <check op="permission">ldse:publish-meta</check>
                        <check op="=" val="true">$is-template</check>
                        {(:<not>
                            <check op="is-published">$custom-page</check>
                        </not>:)}
                     </checks>
                     <a href="#d" class="ldse-icon-send" onclick="ACT.publishMeta('{{$current-page}}', '{{$locale}}'); return false;">Publish Meta</a>
                </link>

                <link sequence="60" name="ldse:gear-unpublish" custom-call="false">
                    <checks>
                        <check op="action">ldse:unpublish</check>
                     </checks>
                     <a href="#d" class="ldse-icon-unpublish" onclick="ACT.page('ldse:unpublish','{{$current-page}}', '{{$locale}}'); return false;">Unpublish Page</a>
                </link>

                {(:
                <link sequence="80" name="ldse:gear-change-template" custom-call="false">
                    <checks>
                        <check op="permission">ldse:change-template</check>
                        <check op="=" val="true">$is-template</check>
                     </checks>
                     <a href="{{$shared-prefix}}{ $shared-prefix }/page-manager/page-editor?lang={{$lang}}&amp;country={{$country}}&amp;uri={{$current-page}}#settings" onclick="ICE.postLink(this); return false;" data-post.action="edit" data-post.page="{{$current-page}}" data-post.option="form:pageBuilder,changeTemplate:true"  class="ldse-icon-edit">Change Template</a>
                     {(:<a href="{{$shared-prefix}}{ $shared-prefix }/form?lang={{$lang}}&amp;country={{$country}}&amp;id={{$file-id}}" onclick="ICE.postLink(this); return false;" data-post.action="edit" data-post.uri="{{$current-page}}" data-post.page="{{$current-page}}" data-post.option="form:pageBuilder,changeTemplate:true"  class="ldse-icon-edit">Change Template</a>:)}
                </link>
                :)}

                <link sequence="100" name="ldse:gear-add-poll" custom-call="false">
                    <checks>
                        <check op="permission">ldse:add-poll</check>
                     </checks>
                     <a href="#d" class="ldse-icon-ko-add" title="Add Poll" onclick="ICE.openForm('{{$locale}}', '', 'add', 'poll-form', '', '{{$current-page}}', 'form:poll-form'); return false;">Add Poll</a>
                </link>

                {(:
                <link sequence="120" name="ldse:gear-settings" custom-call="false">
                    <checks>
                        <check op="permission">ldse:view-page-settings</check>
                        <check op="=" val="true">$is-template</check>
                     </checks>
                     <a href="#d" class="ldse-icon-settings" onclick="ICE.pageSettings('{{$current-page}}', '{{$locale}}'); return false;">Page Settings</a>
                </link>
                :)}

                <link sequence="140" name="ldse:gear-clone-page" custom-call="false">
                    <checks>
                        <check op="permission">ldse:clone-page</check>
                        <check op="=" val="true">$is-template</check>
                     </checks>
                     <a href="#d" class="ldse-icon-copy" onclick="ICE.clonePage('{{$locale}}', '{{$current-page}}', '{{#clone-page/@action}}')">Clone Page</a>
                </link>

                <link sequence="160" name="ldse:gear-edit-hidden-resources" custom-call="false">
                    <checks>
                        <check op="permission">ldse:edit-hidden-resources</check>
                        <check op="exists">$hidden-resources</check>
                     </checks>
                     <a href="#d" class="ldse-icon-edit" onclick="RICE.editHiddenResources('{{$locale}}'); return false;">Edit Hidden Text</a>
                </link>

                <link sequence="170" name="ldse:page-editor" custom-call="false">
                    <checks>
                        <check op="permission">ldse:view-page-editor</check>
                    </checks>
                    <a href="{{$shared-prefix}}/page-manager/page-editor?lang={{$lang}}&amp;country={{$country}}&amp;uri={{$current-page}}#content" class="ldse-icon-page" i18n="">Page Editor</a>
                </link>

                <link sequence="180" name="ldse:gear-new-page" custom-call="false">
                    <checks>
                        <check op="permission">ldse:add-new-page</check>
                     </checks>
                     <a href="{{$shared-prefix}}/form?lang={{$lang}}&amp;country={{$country}}#settings" data-post.issubmission="{$is-submitter}" onclick="ICE.postLink(this); return false;" data-post.action="add" data-post.page="{{$current-page}}" data-post.option="form:pageBuilder" class="ldse-icon-ko-add" i18n="">New Page from Template</a>
                     {(:<a href="{{$shared-prefix}}{ $shared-prefix }/form?lang={{$lang}}&amp;country={{$country}}" data-post.issubmission="{$is-submitter}" onclick="ICE.postLink(this); return false;" data-post.action="add" data-post.page="{{$current-page}}" data-post.option="form:pageBuilder" class="ldse-icon-ko-add" i18n="">New Page from Template</a>:)}
                </link>

                <link sequence="200" name="ldse:gear-toggle-carousel" custom-call="false">
                    <checks>
                        <check op="permission">ldse:toggle-carousel</check>
                        <check op="exists">#toggle-carousel/text()</check>
                     </checks>
                     <a href="#d" class="ldse-icon-loop" id="toggleCarousel" data-carousel="{{#toggle-carousel}}" onclick="ICE.toggleCarousel(); return false;">Stop Carousel</a>
                </link>

                <link sequence="220" name="ldse:gear-omniture" custom-call="false">
                    <checks>
                        <check op="permission">ldse:view-omniture-page</check>
                     </checks>
                     <a href="#d" class="ldse-icon-graph" id="omniture" onclick='ICE.showOmniture(); return false;'>View Omniture Stats</a>
                </link>


                <link sequence="230" name="ldse:gear-seomoz" custom-call="false">
                    <checks>
                        <check op="permission">ldse:view-seomoz-page</check>
                     </checks>
                     <a href="#d" class="ldse-icon-list" id="seomoz" onclick='ICE.showSEOMoz(); return false;'>View SEO-Moz Stats</a>
                </link>

            </links>
        );

    declare function settings:get-gear-link-by-name($name as xs:string) as element(ldse:link)? {
        ($add-gear-links[1]/ldse:link[@name = $name], $add-gear-links[2]/ldse:link[@name = $name])[1]
    };

(: END ADD-GEAR:)

(: TRANSLATION SETTINGS :)
    declare variable $to-translation as element(ldse:to-translation)? := $ldse-settings/ldse:to-translation;
    declare variable $to-days as xs:string? := $ldse-settings/ldse:to-translation/ldse:days-to-keep;
    declare variable $to-zip-path as xs:string := ($ldse-settings/ldse:to-translation/ldse:location[. ne ''], '/to-translation/')[1];
    declare variable $to-sender-name as xs:string := ($ldse-settings/ldse:to-translation/ldse:send-email/ldse:sender/ldse:name, "LDS Publisher")[1];
    declare variable $to-sender-email as xs:string := ($ldse-settings/ldse:to-translation/ldse:send-email/ldse:sender/ldse:email, "no-reply@ldschurch.org")[1];
    declare variable $to-recipient-emails as xs:string* := $ldse-settings/ldse:to-translation/ldse:send-email/ldse:recipient/ldse:email[. ne ''];

    declare variable $from-days as xs:string? := $ldse-settings/ldse:from-translation/ldse:days-to-keep;
    declare variable $from-trigger-mode as xs:string := ($ldse-settings/ldse:from-translation/ldse:trigger-mode, "preview")[1];
    declare variable $from-zip-path as xs:string := ($ldse-settings/ldse:from-translation/ldse:location, fn:concat(core:get-site-root(), 'from-translation/'))[1];
    declare variable $from-transforms as element(ldse:custom-transform)* := $ldse-settings/ldse:from-translation/ldse:custom-transform;
    declare variable $from-login as element(ldse:login) := $ldse-settings/ldse:from-translation/ldse:login;

    (: OLD Pages settings :)
        declare variable $to-tranlation-links as element(ldse:links)? := $ldse-settings/ldse:to-translation/ldse:links;
        declare variable $to-translation-custom-links as element(ldse:link)* := $ldse-settings/ldse:to-translation/ldse:links/ldse:custom/ldse:link;
        declare variable $to-translation-built-in-links as element(ldse:link)*:= $ldse-settings/ldse:to-translation/ldse:links/ldse:built-in/ldse:link;

(: END TRANSLATION SETTINGS :)

(: Modes :)
    declare variable $modes as element(ldse:mode)+ := $ldse-settings/ldse:modes/ldse:mode;

    declare function settings:is-ldse-enabled($mode as xs:string) as xs:boolean {
            $modes[@name = $mode]/ldse:ldse-enabled = "true"
    };

    declare function settings:get-mode($port as xs:integer?) as xs:string { core:get-mode($port) };
    declare function settings:get-mode-default($port as xs:integer?) as xs:string {
        let $mode as xs:string? :=
            let $matches as xs:string* := ($modes[ldse:port != ""][ldse:port/xs:integer(.) = $port]/@name)
            let $count as xs:int := fn:count($matches)
            return (
                if ($count = 1) then ( $matches ) else  (
                    ($matches[fn:contains(xdmp:get-request-header("host"), .)])[1]
                )
            )
        return (
            if ($mode != "" and fn:exists($mode) ) then (
                $mode
            ) else (
                (
                    ($modes[ldse:default = "true"]/@name)[1],
                    $modes[fn:last()]/@name
                )[1]
            )
        )
    };

    declare function settings:get-mode-by-root($root as xs:string) as xs:string {
        ($modes[ldse:root = $root ])[1]/@name
    };

    declare function settings:get-pharaoh-mode() as xs:string {
        ($modes[ldse:pharaoh = "true"])[1]/@name
    };

    declare function settings:get-mode-database($mode as xs:string) as xs:string {
        (
            $modes[@name = $mode]/ldse:database,
            "Delivery"
        )[1]
    };

    declare function settings:get-mode-root($mode as xs:string) as xs:string {
        (
            $modes[@name = $mode]/ldse:root,
            fn:concat('/', $mode, '/')
        )[1]
    };

    declare function settings:get-mode-port($mode as xs:string) as xs:integer? {
        ($modes[@name = $mode]/ldse:port[. != ""])[1]/xs:integer(.)
    };

    declare function settings:get-front-end-host($mode as xs:string) as xs:string? {
        ($modes[@name = $mode]/ldse:front-end-host[. != ""], $util:host)[1]
    };

    declare function settings:is-mode-versioned($mode as xs:string) as xs:boolean {
        $modes[@name = $mode]/ldse:versioned = "true"
    };

    declare function settings:get-mode-domain($mode as xs:string) as xs:string {
        ($modes[@name = $mode]/ldse:domain[. != ""], $util:host)[1]
    };

    declare function settings:get-warehouse-mode() as xs:string {
        ($modes[ldse:warehoused = "true"], $modes[1])[1]/@name
    };

    declare function settings:is-moded-warehoused($mode as xs:string) as xs:boolean {
        $modes[@name = $mode]/ldse:warehoused = "true"
    };

    declare function settings:mode-for-uri($uri as xs:string) as xs:string {
        (
            for $mode as element(ldse:mode) in $modes
            where fn:starts-with($uri, core:get-site-root($mode))
            return $mode,
            $modes[1]
        )[1]/@name
    };
(: END Mode :)

declare function settings:build-root-qname($root as element(ldse:root)) as xs:QName {
    fn:QName($root/@namespace, xs:string($root))
};

(: Checks if the given domain matches one of the strip domains. :)
declare function settings:is-strip-domain($domain as xs:string) as xs:boolean {
    fn:exists($strip-domains/ldse:domain[. eq $domain])
};


(: Actions :)
declare variable $action-groups as element(ldse:action-groups) :=
    let $defaults as element(ldse:action-groups) :=
        <action-groups xmlns="http://lds.org/code/lds-edit">
            <group seq="10" class="secondary" onclick="buttonClicked(this); return false;">constructive</group>
            <group seq="30" class="primary">save</group>
            <group seq="30" class="primary">save-done</group>
            <group seq="30" class="secondary">clone</group>
            <group seq="20" class="destructive">destructive</group>
            <group seq="30" class="primary">submissions</group>
            <group seq="9" class="secondary">other</group>
        </action-groups>

    let $names as xs:string* := $ldse-settings/ldse:action-groups/ldse:group/fn:string(.)[fn:not(. eq "")]

    return
        <action-groups xmlns="http://lds.org/code/lds-edit">
        {
            $ldse-settings/ldse:action-groups/ldse:group[fn:not(@remove = "true")],
            $defaults/ldse:group[fn:not(. = $names)]
        }
        </action-groups>
;

    declare variable $actions as element(ldse:action)+ :=
        let $disable-publishing := $site-properties/disable-publishing /fn:string() eq 'true'
        let $defaults as element(ldse:actions) :=
            <actions xmlns="http://lds.org/code/lds-edit">
                <action name="ldse:preview" id="action-save" onclick="buttonClicked(this); return false;" permission="ldse:edit-doc,ldse:edit-submission,ldse:add-doc" group="save" seq="10" title="Save" icon="ldse-icon-save" i18n="">
                    <status>preview</status>
                    <save>
                        <mode>preview</mode>
                    </save>
                    <checks>
                        <or>
                            <and>
                                <not>
                                    <check op="is-submission">$file</check>
                                </not>
                                <or>
                                    <check op="permission">ldse:edit-doc</check>
                                    <check op="permission">ldse:add-doc</check>
                                </or>
                            </and>
                            <and>
                                <check op="is-submission">$file</check>
                                <check op="submission-submitted">$file</check>
                                <check op="permission">ldse:edit-any-submission</check>
                            </and>
                        </or>
                    </checks>
                </action>
                <action name="ldse:save-done" id="action-save-done" onclick="buttonClickedSaveDone(); return false;" permission="ldse:edit-doc,ldse:edit-submission,ldse:add-doc" group="save-done" seq="10" title="Save &amp; Close" icon="ldse-icon-save" i18n="">
                    <status>preview</status>
                    <save>
                        <mode>preview</mode>
                    </save>
                    <checks>
                        <or>
                            <and>
                                <not>
                                    <check op="is-submission">$file</check>
                                </not>
                                <or>
                                    <check op="permission">ldse:edit-doc</check>
                                    <check op="permission">ldse:add-doc</check>
                                </or>
                            </and>
                            <and>
                                <check op="is-submission">$file</check>
                                <check op="submission-submitted">$file</check>
                                <check op="permission">ldse:edit-any-submission</check>
                            </and>
                        </or>
                    </checks>
                </action>

                 {
                if($ldse-settings/ldse:clone eq "true")
                    then ( <action name="ldse:clone" id="action-clone" onclick="clonePage(ICE.formVars.lang,ICE.formVars.uri,'ldse:preview', ICE.formVars.id, false); return false;" group="clone" permission="ldse:edit-doc,ldse:edit-submission,ldse:add-doc"  seq="10" title="Clone" icon="ldse-icon-copy" i18n="">
                    <status>preview</status>
                    <save>
                        <mode>preview</mode>
                    </save>
                    <checks>
                        <or>
                            <and>
                                <not>
                                    <check op="is-submission">$file</check>
                                </not>
                                <or>
                                    <check op="permission">ldse:edit-doc</check>
                                    <check op="permission">ldse:add-doc</check>
                                </or>
                            </and>
                            <and>
                                <check op="is-submission">$file</check>
                                <check op="submission-submitted">$file</check>
                                <check op="permission">ldse:edit-any-submission</check>
                            </and>
                        </or>
                    </checks>
                </action>,
                <action name="ldse:clone-all" id="action-clone-deep" onclick="clonePage(ICE.formVars.lang,ICE.formVars.uri,'ldse:preview', ICE.formVars.id, true); return false;" group="clone" permission="ldse:edit-doc,ldse:edit-submission,ldse:add-doc"  seq="10" title="Clone All" icon="ldse-icon-copy" i18n="">
                    <status>preview</status>
                    <save>
                        <mode>preview</mode>
                    </save>
                    <checks>
                        <or>
                            <and>
                                <not>
                                    <check op="is-submission">$file</check>
                                </not>
                                <or>
                                    <check op="permission">ldse:edit-doc</check>
                                    <check op="permission">ldse:add-doc</check>
                                </or>
                            </and>
                            <and>
                                <check op="is-submission">$file</check>
                                <check op="submission-submitted">$file</check>
                                <check op="permission">ldse:edit-any-submission</check>
                            </and>
                        </or>
                    </checks>
                </action>)
                else()
                }

                <action name="ldse:created" id="action-created" onclick="buttonClicked(this); return false;" permission="ldse:edit-submission" group="submissions" seq="10" title="Save as Draft" icon="ldse-icon-save" i18n="">
                    <status>preview</status>
                    <save>
                        <mode>preview</mode>
                    </save>
                    <checks>
                        <check op="is-submission">$file</check>
                        <not>
                            <check op="submission-submitted">$file</check>
                        </not>
                        <or>
                            <and>
                                <check op="=" val="edit">$action</check>
                                <or>
                                    <and>
                                        <check op="user-created-file">$file</check>
                                        <check op="permission">ldse:edit-submission</check>
                                    </and>
                                    <check op="permission">ldse:edit-any-submission</check>
                                </or>
                            </and>
                            <and>
                                <check op="=" val="add">$action</check>
                                <check op="permission">ldse:add-submission</check>
                            </and>
                        </or>
                    </checks>
                </action>
                <action name="ldse:submitted" id="action-submitted" onclick="buttonClicked(this); return false;" group="submissions" seq="20" permission="ldse:submit-submission" title="Submit" icon="ldse-icon-save" i18n="">
                    <status>preview</status>
                    <save>
                        <mode>preview</mode>
                    </save>
                    <checks>
                        <check op="is-submission">$file</check>
                        <not>
                            <check op="submission-submitted">$file</check>
                        </not>
                        <or>
                            <and>
                                <check op="=" val="edit">$action</check>
                                <or>
                                    <and>
                                        <check op="user-created-file">$file</check>
                                        <check op="permission">ldse:edit-submission</check>
                                    </and>
                                    <check op="permission">ldse:edit-any-submission</check>
                                </or>
                            </and>
                            <and>
                                <check op="=" val="add">$action</check>
                                <check op="permission">ldse:add-submission</check>
                            </and>
                        </or>
                    </checks>
                </action>

                {
                    if ($disable-publishing) then ()
                    else
                        <action name="ldse:publish" id="action-publish" not-valid="disable" group="constructive" permission="ldse:publish-doc" seq="10" title="Publish" icon="ldse-icon-send" i18n="">
                            <status>publish</status>
                            <save>
                                <mode>preview</mode>
                                <mode>published</mode>
                            </save>
                            <search>send</search>
                            <country>send</country>
                            <checks>
                                <check op="permission">ldse:publish-doc</check>
                                <check op="correlationcanpublish">$file</check>
                                <or>
                                    <and>
                                        <check op="is-submission">$file</check>
                                        <check op="submission-submitted">$file</check>
                                    </and>
                                    <and>
                                        <not>
                                            <check op="is-submission">$file</check>
                                        </not>
                                    </and>
                                </or>
                            </checks>
                        </action>
                }
                {(:
                <!--We shouldn't be doing a publish all-->
                <action name="ldse:publish-all" id="action-publish-all" not-valid="disable" group="constructive" permission="ldse:publish-doc" seq="10" title="Publish All" icon="ldse-icon-send" i18n="">
                    <status>publish</status>
                    <save>
                        <mode>preview</mode>
                        <mode>published</mode>
                    </save>
                    <search>send</search>
                    <country>send</country>
                    <checks>
                        <check op="permission">ldse:publish-doc</check>
                        <check op="correlationcanpublish">$file</check>
                        <or>
                            <and>
                                <check op="is-submission">$file</check>
                                <check op="submission-submitted">$file</check>
                            </and>
                            <and>
                                <not>
                                    <check op="is-submission">$file</check>
                                </not>
                            </and>
                        </or>
                    </checks>
                </action>:)}
                <action name="ldse:return" id="action-return" class="secondary" group="constructive" seq="25" permission="ldse:return-submission" onclick="returnSubmission(); return false;" title="Return Submission" icon="ldse-icon-revert" i18n="">
                    <status>preview</status>
                    <save>
                        <mode>preview</mode>
                    </save>
                    <checks>
                        <check op="permission">ldse:return-submission</check>
                        <check op="is-submission">$file</check>
                        <check op="submission-submitted">$file</check>
                    </checks>
                </action>

                <action name="ldse:syncMeta" id="action-syncMeta" class="secondary" group="constructive" seq="20" permission="ldse:sync-meta" onclick="syncMeta(); return false;" title="Sync Meta" icon="ldse-icon-loop" i18n="">
                    <status>preview</status>
                    <save>
                        <mode>preview</mode>
                    </save>
                    <checks>
                        <check op="permission">ldse:sync-meta</check>
                        <check op="exists">$file</check>
                        <check op="has-syncable-elements">$formXml</check>
                        <check op="has-translated-files">$file</check>
                        <not>
                            <check op="is-submission">$file</check>
                        </not>
                    </checks>
                 </action>
           <!--     <action name="ldse:ready-translation" title="Ready for Translation" permission="ldse:publish-doc" icon="ldse-icon-globe" i18n="" >
                    <status>publish</status>
                    <save>
                        <mode>preview</mode>
                        <mode>published</mode>
                    </save>
                    <search>send</search>
                    <country>send</country>
                </action>-->
                <action name="ldse:delete" id="action-destructive" group="destructive" seq="30" onclick="promptDelete(this); return false;" permission="ldse:delete-doc,ldse:delete-submission" title="Delete" icon="ldse-icon-trash" i18n="">
                    <status>delete</status>
                    <delete>
                        <mode>preview</mode>
                        <mode>published</mode>
                    </delete>
                    <search>remove</search>
                    <checks>
                        <check op="exists">$file</check>
                        <or>
                            <and>
                                <not>
                                    <check op="is-submission">$file</check>
                                </not>
                                <check op="permission">ldse:delete-doc</check>
                            </and>
                            <and>
                                <check op="is-submission">$file</check>
                                <or>
                                    <and>
                                        <not>
                                            <check op="submission-submitted">$file</check>
                                        </not>
                                        <check op="permission">ldse:delete-submission</check>
                                        <check op="user-created-file">$file</check>
                                    </and>
                                    <check op="permission">ldse:delete-any-submission</check>
                                </or>
                            </and>
                        </or>
                    </checks>
                </action>
                <action name="ldse:unpublish" id="action-unpublish" group="destructive" seq="10" onclick="buttonClicked(this); return false;" permission="ldse:unpublish-doc" title="Unpublish" icon="ldse-icon-unpublish" i18n="">
                    <status>unpublish</status>
                    <save>
                        <mode>preview</mode>
                    </save>
                    <delete>
                        <mode>published</mode>
                    </delete>
                    <search>remove</search>
                    <checks>
                        <check op="permission">ldse:unpublish-doc</check>
                        <or>
                            <check op="exists">$file</check>
                            <check op="exists">$custom-page</check>
                        </or>
                        <or>
                            <check op="is-published">$file</check>
                            <check op="is-published">$custom-page</check>
                        </or>
                    </checks>
                </action>
                <action name="ldse:remove" id="action-remove" group="destructive" seq="20" title="Remove" onclick="promptDelete(this); return false;" permission="ldse:remove-doc" icon="ldse-icon-ko-remove" i18n="">
                    <status>remove-from-page</status>
                    <save>
                        <mode>preview</mode>
                    </save>
                    <delete>
                        <mode>published</mode>
                    </delete>
                    <search>remove</search>
                    <checks>
                        <check op="permission">ldse:remove-doc</check>
                        <check op="exists">$file</check>
                        <check op="is-published">$file</check>
                    </checks>
                </action>
                <action name="ldse:cancel" id="action-cancel" seq="999" title="Close" icon="ldse-icon-x" onclick="promptChanges(); return false;" i18n="">
                </action>
            </actions>
        let $names as xs:string* := $ldse-settings/ldse:actions/ldse:action/@name
        return (
            $ldse-settings/ldse:actions/ldse:action[fn:not(@remove = "true")],
            $defaults/ldse:action[fn:not(@name = $names)]
        )
    ;

    declare function settings:get-action($action as xs:string) as element(ldse:action)? {
        $actions[@name = $action]
    };

    declare function settings:get-action-permission($action as xs:string) as xs:string* {
        fn:tokenize($actions[@name = $action]/@permission/fn:string(.), ",")
    };

    declare function settings:get-action-save-modes($action as xs:string) as xs:string* {
        $actions[@name = $action]/ldse:save/ldse:mode
    };

    declare function settings:get-action-delete-modes($action as xs:string) as xs:string* {
        $actions[@name = $action]/ldse:delete/ldse:mode
    };

    declare function settings:action-should-lock($action as xs:string) as xs:boolean {
        fn:empty($actions[@name = $action][ldse:delete/ldse:mode = $core:mode])
    };

    declare function settings:get-action-meta-status($action as xs:string) as xs:string {
        $actions[@name = $action]/ldse:status/fn:string()
    };
(: END ACTIONS :)

(: ROLES / PERMISSIONS :)
    declare variable $role-mapping as element(ldse:role-mapping)? := $ldse-settings/ldse:contributor-roles/ldse:role-mapping; (: Deprecated variable :)
    declare variable $additional-permissions as element(ldse:permission)* := $ldse-settings/ldse:permissions/ldse:permission;
    declare variable $ldse-roles as element(ldse:roles)? := get-ldse-roles();
    declare function settings:get-ldse-roles() as element(ldse:roles)? {
        let $roles as element(ldse:roles) := (
            $ldse-settings/ldse:roles,
            (: Default :)
            <roles xmlns="http://lds.org/code/lds-edit">
                <role name="dev" title="Developer" i18n="">
                    <inherit>super</inherit>
                    <permission>ldse:developer</permission>
                </role>
                <role name="super" title="Super" i18n="">
                    <inherit>admin</inherit>
{(:                    <inherit>shared-user</inherit>:)}
                    <!-- Views -->
                        <permission>ldse:view-xml</permission>
                        <permission>ldse:view-supported-languages</permission>
                    <!-- End Views -->
                    <!-- String-Manager Functions-->
                        <permission>ldse:string-manager-import-export</permission>
                        <permission>ldse:string-manager-add-bundle</permission>
                        <permission>ldse:string-manager-export-english</permission>
                        <permission>ldse:string-manager-add-string</permission>
                    <!-- Actions -->

                        <permission>ldse:edit-supported-language</permission>
                        <permission>ldse:clear-server-field</permission>
                        <permission>ldse:validate-forms</permission>
                        <permission>ldse:grant-permissions</permission>

                    <!-- End Actions -->
                    <!-- Translation Permissions -->
                    <!-- End Translation Permissions -->

                    <permission>ldse:view-rewrite-manager</permission>
                    <permission>ldse:edit-rewrite-rules</permission>
                    <permission>ldse:view-redirect-manager</permission>
                    <permission>ldse:edit-redirect-rules</permission>

                </role>
                <role name="admin" title="Admin" i18n="">
                    <require>locale</require>
                    <inherit>publisher</inherit>
                    <inherit>translation-admin</inherit>
                    <inherit>translation-approver</inherit>
                    <inherit>submitter</inherit>
                    <!-- Views -->
                    <!-- End Views -->
                        <permission>ldse:view-clear-cache</permission>
                        <permission>ldse:view-reports-admin</permission>

                    <!-- Actions -->
                    <!-- End Actions -->
                    <!-- Translation Permissions -->
                        <permission>ldse:send-to-translation</permission>
                        <permission>ldse:view-translation-archive</permission>
                        <permission>ldse:edit-translation-archive</permission>
                        <permission>ldse:translation-remove-ready</permission>
                        <permission>ldse:view-translation-mangage</permission>
                        <permission>ldse:translation-remove-approval</permission>
                        <permission>ldse:remove-comment</permission>
                    <!-- End Translation Permissions -->

                    <!-- Cor-IP / Cor-Eval -->
                        <permission>ldse:correlation-prepublisher</permission>
                    <!-- End Cor-IP / Cor-Eval -->

                    <!-- Submissions -->
                        <permission>ldse:edit-any-submission</permission>
                        <permission>ldse:view-any-submission</permission>
                        <permission>ldse:delete-any-submission</permission>
                    <!-- End Submissions -->
                        <permission>ldse:edit-rice-contentEditor</permission>
                    <!-- flexible-field-manager -->
                        <permission>ldse:flexible-field-manager</permission>
                    <!-- End flexible-field-manager -->
                    <!-- Titan ID Update -->
                        <permission>ldse:titan-id-update</permission>
                    <!-- End Titan ID Update -->

                </role>
                <role name="flexibleFieldManager" title="Flexible Field Manager" i18n="">
                    <permission>ldse:flexible-field-manager</permission>
                </role>
                <role name="titanIDUpdater" title="Titan ID Updater" i18n="">
                    <permission>ldse:titan-id-update</permission>
                </role>
                <role name="publisher" title="Publisher" i18n="">
                    <require>locale</require>
                    <require>uri</require>
                    <inherit>editor</inherit>
                    <!-- Views -->
                        <permission>ldse:view-clear-cache</permission>
                        <permission>ldse:view-rice-admin</permission>
                        <permission>ldse:view-content-admin</permission>
                        <permission>ldse:view-pages-admin</permission>
                        <permission>ldse:view-clear-cache-admin</permission>
                        <permission>ldse:view-stats-admin</permission>

                    <!-- End Views -->
                    <!-- Actions -->
                        <permission>ldse:string-manager-add-string</permission>
                        <permission>ldse:publish-all-bundles</permission>
                        <permission>ldse:publish-bundles</permission>
                        <permission>ldse:publish-doc</permission>
                        <permission>ldse:unpublish-doc</permission>
                        <permission>ldse:remove-doc</permission>
                        <permission>ldse:delete-doc</permission>
                        <permission>ldse:change-template</permission>
                        <permission>ldse:publish-navigation</permission>
                        <permission>ldse:publish-jericho</permission>
                        <permission>ldse:publish-meta</permission>
                        <permission>ldse:change-uri</permission>
                    <!-- End Actions -->
                    <!-- Translation Permissions -->
                        <permission>ldse:remove-translation-ready</permission>
                        <permission>ldse:translation-not-ready</permission>
                        <permission>ldse:translation-fix-not-ready</permission>
                        <permission>ldse:translation-remove-returned</permission>
                        <permission>ldse:view-translation</permission>
                        <permission>ldse:view-translation-ready</permission>
                        <permission>ldse:view-translation-in</permission>
                        <permission>ldse:view-translation-returned</permission>
                        <permission>ldse:view-translation-not-ready</permission>
                        <permission>ldse:view-translation-published</permission>
                        <permission>ldse:view-translation-archive</permission>
                        <permission>ldse:view-translation-reviewed</permission>
                        <permission>ldse:send-to-translation</permission>
                        <permission>ldse:view-reports-admin</permission>

                        <permission>ldse:translation-checkbox</permission>
                    <!-- End Translation Permissions -->
                        <permission>ldse:publish-languages</permission>

                    <!-- Cor-IP / Cor-Eval -->
                        <permission>ldse:correlation-send</permission>
                        <permission>ldse:view-correlation</permission>
                        <permission>ldse:correlation-no-new-content-button</permission>
                    <!-- End Cor-IP / Cor-Eval -->

                        <permission>ldse:return-submission</permission>

                </role>
                <role name="editor" title="Editor" i18n="">
                    <require>locale</require>
                    <require>uri</require>
                    <!-- Actions -->
                        <permission>ldse:view-page-editor</permission>
                        <permission>ldse:edit-doc</permission>
                        <permission>ldse:edit-component</permission>
                        <permission>ldse:add-doc</permission>
                        <permission>ldse:edit-navigation</permission>
                        <permission>ldse:teaser-manager</permission>
                        <permission>ldse:teaser-search</permission>
                        <permission>ldse:edit-teaser-sequence</permission>
                        <permission>ldse:add-poll</permission>
                        <permission>ldse:sync-meta</permission>
                        <permission>ldse:publish-doc</permission>
                        <permission>ldse:unpublish-doc</permission>
                        <permission>ldse:cloning</permission>
                    <!-- End Actions -->
                    <!-- Views -->
                        <permission>ldse:view-binary-manager</permission>
                        <permission>ldse:view-lds-edit-home</permission>
                        <permission>ldse:view-workflow</permission>
                        <permission>ldse:view-page-settings</permission>
                        <permission>ldse:view-omniture-admin</permission>
                        <permission>ldse:view-reports-admin</permission>
                    <!-- End Views -->

                    <!-- Add Gear -->
                        <permission>ldse:clone-page</permission>
                        <permission>ldse:edit-hidden-resources</permission>
                        <permission>ldse:add-new-page</permission>
                        <permission>ldse:toggle-carousel</permission>
                        <permission>ldse:view-omniture-page</permission>
                        <permission>ldse:view-seomoz-page</permission>
                    <!-- End Add Gear -->
                    <!-- IP Permissions -->
                        <permission>ldse:submit-ip</permission>
                    <!-- End IP Permissions -->
                    <!-- Correlation -->
                        <permission>ldse:correlation-always-add-element</permission>
                        <permission>ldse:correlation-always-remove-element</permission>
                    <!-- End Correlation -->
                    <!-- Rice -->
                        <permission>ldse:edit-rice</permission>
                    <!-- End Rice -->
                    <!-- Versions -->
                        <permission>ldse:versions-restore-complete</permission>
                        <permission>ldse:versions-restore-line-item</permission>
                        <permission>ldse:versions-save-as-current</permission>
                    <!-- End Versions -->
                </role>

                <role name="submitter" title="Submitter" i18n="">
                    <require>locale</require>
                    <require>uri</require>
                    <!-- Actions -->
                        <permission>ldse:edit-submission</permission>
                        <permission>ldse:add-submission</permission>
                        <permission>ldse:delete-submission</permission>
                        <permission>ldse:view-submission</permission>
                        <permission>ldse:submit-submission</permission>
                        <permission>ldse:add-poll</permission>
                    <!-- End Actions -->
                    <!-- Views -->
                        <permission>ldse:view-binary-manager</permission>
                        <permission>ldse:view-lds-edit-home</permission>
                        <permission>ldse:view-workflow</permission>
                        <permission>ldse:view-page-settings</permission>
                        <permission>ldse:view-pages-admin</permission>
                        <permission>ldse:view-page-editor</permission>
                    <!-- End Views -->

                    <!-- Add Gear -->
                        <permission>ldse:add-new-page</permission>
                    <!-- End Add Gear -->
                        <permission>ldse:view-all-content-manager-statuses</permission>
                </role>

                <role name="stakeholder" title="Stakeholder" i18n="">
                    <require>locale</require>
                    <!-- Actions -->
                    <!-- End Actions -->
                    <!-- Views -->
                        <permission>ldse:view-approve-sensitive</permission>
                        <permission>ldse:view-unpublish-sensitive</permission>
                    <!-- End Views -->
                </role>
                <role name="translation-admin" title="Translation Admin" i18n="">
                    <require>locale</require>
                    <inherit>translation-supervisor</inherit>
                    <!-- Translation Permissions -->
                        <permission>ldse:edit-translation-archive</permission>
                    <!-- End Translation Permissions -->
                </role>
                <role name="translation-supervisor" title="Translation Supervisor" i18n="">
                    <require>locale</require>
                    <inherit>translation-reviewer</inherit>
                    <!-- Actions -->
                        <permission>ldse:add-doc</permission>
                        <permission>ldse:delete-doc</permission>
                        <permission>ldse:remove-doc</permission>
                        <permission>ldse:edit-rice</permission>
                        <permission>ldse:edit-hidden-resources</permission>
                    <!-- End Actions -->
                    <!-- Translation Permissions -->
                        <permission>ldse:translation-not-ready</permission>
                        <permission>ldse:translation-fix-not-ready</permission>
                        <permission>ldse:translation-remove-returned</permission>
                        <permission>ldse:translation-unremove</permission>
                        <permission>ldse:view-translation-archive</permission>

                        <permission>ldse:view-translation-in</permission>
                        <permission>ldse:view-translation-returned</permission>
                        <permission>ldse:view-translation-not-ready</permission>
                        <permission>ldse:view-translation-removed</permission>
                        <permission>ldse:view-translation-published</permission>
                        <permission>ldse:view-translation-archive</permission>
                    <!-- End Translation Permissions -->
                </role>
                <role name="translation-reviewer" title="Translation Reviewer">
                    <require>locale</require>
                    <!-- Views -->
                        <permission>ldse:view-page-editor</permission>
                        <permission>ldse:view-lds-edit-home</permission>
                        <permission>ldse:view-workflow</permission>
                    <!-- End Views -->
                    <!-- Actions -->
                        <permission>ldse:edit-doc</permission>
                        <permission>ldse:edit-navigation</permission>
                        <permission>ldse:publish-navigation</permission>
                        <permission>ldse:edit-hidden-resources</permission>
                        <permission>ldse:edit-rice</permission>
                        <permission>ldse:publish-doc</permission>
                        <permission>ldse:unpublish-doc</permission>
                    <!-- End Actions -->
                    <!-- Translation Permissions -->
                        <permission>ldse:translation-review</permission>
                        <permission>ldse:translation-needs-reviewed</permission>
                        <permission>ldse:translation-not-ready</permission>
                        <permission>ldse:translation-fix-not-ready</permission>

                        <permission>ldse:view-translation-not-ready</permission>
                        <permission>ldse:view-translation</permission>
                        <permission>ldse:view-translation-returned</permission>
                        <permission>ldse:view-translation-reviewed</permission>

                        <permission>ldse:translation-checkbox</permission>
                    <!-- End Translation Permissions -->
                </role>
                <role name="translation-approver" title="Translation Approver" i18n="">
                    <require>locale</require>
                    <!-- Views -->
                        <permission>ldse:view-page-editor</permission>
                        <permission>ldse:view-lds-edit-home</permission>
                        <permission>ldse:view-workflow</permission>
                    <!-- End Views -->
                    <!-- Translation Permissions -->
                        <permission>ldse:translation-approve</permission>
                        <permission>ldse:translation-remove-ready</permission>

                        <permission>ldse:view-translation</permission>
                        <permission>ldse:view-translation-ready</permission>
                        <permission>ldse:view-translation-approved</permission>

                        <permission>ldse:translation-checkbox</permission>
                    <!-- End Translation Permissions -->
                </role>
                <role name="shared-user" title="Shared User" i18n="">
                    <require>locale</require>
                    <!-- Views -->
                        <permission>ldse:view-shared</permission>
                    <!-- End Views -->
                    <!-- Translation Permissions -->
                    <!-- End Translation Permissions -->
                </role>
                <role name="clear-cache" title="Cache Clear User" i18n="">
                    <require>locale</require>
                    <!-- Views -->
                        <permission>ldse:view-clear-cache-admin</permission>
                    <!-- End Views -->
                    <!-- Translation Permissions -->
                    <!-- End Translation Permissions -->
                </role>

            </roles>
        )[1]
        let $merge-roles as element(ldse:merge-roles)? := $ldse-settings/ldse:merge-roles
        return (
            if ( fn:exists($merge-roles) ) then (
                let $roles-names as xs:string* := $roles/ldse:role/@name
                let $merge-role-names as xs:string* := $merge-roles/ldse:role/@name
                let $dup-names as xs:string* :=
                    for $name as xs:string in $merge-role-names
                    where $name = $roles-names
                    return $name
                return (
                    <roles xmlns="http://lds.org/code/lds-edit">{
                        for $dup as xs:string in $dup-names
                        let $role as element(ldse:role) := $roles/ldse:role[@name = $dup]
                        let $merge as element(ldse:role) := $merge-roles/ldse:role[@name = $dup]
                        return (
                            <role xmlns="http://lds.org/code/lds-edit">{
                                $role/@*,
                                $role/*,
                                $merge/*
                            }</role>
                        ),
                        $merge-roles/ldse:role[fn:not(@name = $dup-names) ],
                        $roles/ldse:role[ fn:not(@name = $merge-role-names) ]
                    }</roles>
                )
            ) else (
                $roles
            )
        )
    };
(: END ROLES :)

declare variable $environmentConfig as element(environment)? := $core:environmentConfig;
declare variable $node-cache-url as xs:string? := $ldse-settings/ldse:node-cache-url;
declare variable $defaultInputTypes as element(options) :=
    <options>
        <option val="text">Text</option>
        <option val="multi-select">Multi Select</option>
        <option val="select">Select</option>
        <option val="wysiwyg">Wysiwyg</option>
        <option val="radio">Radio Button</option>
        <option val="checkbox">Checkbox</option>
        <option val="image">Image</option>
        <option val="pdf">PDF </option>
        <option val="datePicker">Datepicker</option>
        <option val="textarea">Textarea</option>
        <option val="binaryInput">Binary Input</option>
        <option val="dynamicXml">Repeating Item (Dynamic Xml)</option>
    </options>;
declare variable $customInputTypes as element(ldse:options)? := $ldse-settings/ldse:options;
declare variable $categories as element(ldse:category)* := $ldse-settings/ldse:categories/ldse:category;
declare variable $sub-categories as element(ldse:sub-categories)? := $ldse-settings/ldse:sub-categories;
declare variable $user-roles as element(ldse:user-role)* := $ldse-settings/ldse:user-roles/ldse:user-role;
