xquery version "1.0-ml";

module namespace sp = "http://lds.org/code/modules/site-properties";


import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "ldse-settings.xqy";
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at "document-functions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "access-control-functions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at 'utility-functions.xqy';
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at 'ldse-meta.xqy';
import module namespace df = "http://lds.org/code/shared/lds-edit/dynamicForms" at '../ice/modules/dynamicForms.xqy';
import module namespace library = "http://lds.org/code/shared/lds-edit/supported-languages" at "../supported-languages/modules/library.xqy";


declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace its = "http://www.w3.org/2005/11/its";

declare option xdmp:mapping "true";

declare variable $site-properties as element(siteProperties)* := sp:get-site-properties(());
declare variable $attr-sites as xs:string* := $site-properties/@site;
declare variable $ele-sites as xs:string* := $site-properties/sites/site/@value;
declare variable $all-sites as xs:string* := fn:distinct-values(($attr-sites, $ele-sites));
declare variable $site-param as xs:string* := xdmp:get-request-field('site');
declare variable $map as map:map := map:map();
declare variable $used-map as map:map := map:map();
declare variable $template-map as map:map := map:map();
declare variable $new-map as map:map := map:map();

declare function sp:get-site-properties(
    $site as xs:string?
) as element(siteProperties)* {
    cts:search(/siteProperties,
        cts:and-query((
            if ( fn:exists($site) ) then (
                cts:element-attribute-value-query(xs:QName('siteProperties'), xs:QName('site'), $site, 'exact')
            ) else ()
        ))
    )
};

declare function sp:get-site-properties-by(
    $host as xs:string*
) as element(siteProperties)* {
    cts:search(/siteProperties,
        cts:and-query((
            cts:element-value-query(xs:QName('url'), $host, 'exact')
        ))
    )
};

declare function sp:get-templates(
    $id as xs:string?
) as element(template)* {
    cts:search(/template,
        cts:and-query((
            core:get-filter-query(),
            if ( fn:exists($id) ) then (
                cts:element-attribute-value-query(xs:QName('template'), xs:QName('id'), $id, 'exact')
            ) else ()
        ))
    )
};

declare function sp:get-sub-templates(
    $id as xs:string?
) as element(sub-template)* {
    cts:search(/sub-template,
        cts:and-query((
            core:get-filter-query(),
            if ( fn:exists($id) ) then (
                cts:element-attribute-value-query(xs:QName('sub-template'), xs:QName('id'), $id, 'exact')
            ) else ()
        ))
    )
};

declare function sp:get-alerts(
    $site as xs:string*,
    $locale as xs:string*
) as element(alert)* {
    cts:search(/alert,
        cts:and-query((
            cts:element-attribute-value-query(xs:QName('alert'), xs:QName('locale'), $locale, 'exact'),
            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
        ))
    )
};

declare function sp:get-feedbacks(
    $site as xs:string*,
    $locale as xs:string*
) as element(feedback)* {
    cts:search(/feedback,
        cts:and-query((
            cts:element-attribute-value-query(xs:QName('feedback'), xs:QName('locale'), $locale, 'exact'),
            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
        ))
    )
};


declare function sp:get-alert-options(
    $value as item()*
) as element(option)* {
    <option>please select</option>,
    let $site as xs:string* := xdmp:get-request-field('site')
    let $locale as xs:string* := xdmp:get-request-field('lang')
    for $alert in sp:get-alerts($site, $locale)
    order by $alert/ldse:ldse-meta/ldse:document/@title/xs:string(.) ascending
    return (
        <option value="{ $alert/@id/xs:string(.)  }">{
            if ( $value = $alert/@id/xs:string(.)) then ( attribute selected { 'selected' } ) else (),
            ( $alert/ldse:ldse-meta/ldse:document/@title/xs:string(.), $alert/alerts/alert/title/xs:string(.))[1]
        }</option>
    )
};


declare function sp:get-feedback-options(
    $value as item()*
) as element(option)* {
    <option>please select</option>,
    let $site as xs:string* := xdmp:get-request-field('site')
    let $locale as xs:string* := xdmp:get-request-field('lang')
    for $feedback in sp:get-feedbacks($site, $locale)
    order by $feedback/ldse:ldse-meta/ldse:document/@title/xs:string(.) ascending
    return (
        <option value="{ $feedback/@id/xs:string(.) }">{
            if ( $value = $feedback/@id/xs:string(.)) then ( attribute selected { 'selected' } ) else (),
            ( $feedback/ldse:ldse-meta/ldse:document/@title/xs:string(.), $feedback/states/state/title/xs:string(.)  )[1]
        }</option>
    )
};

declare function sp:get-template-options(
    $value as item()*
) as element(option)* {
    for $template as element(template) in sp:get-templates(())
    order by $template/name ascending
    return (
        <option value="{ $template/@id/xs:string(.) }">{
            if ( $value = $template/@id ) then ( attribute selected { 'selected' } ) else (),
            ( $template/name/xs:string(.), $template/@id/xs:string(.) )[1]
        }</option>
    )
};

declare function sp:get-experience-options(
    $value as item()*
) as element(option)* {
    <option>Please Select</option>,
    for $experience as element(ldse:experience) in $settings:ldse-settings/ldse:experiences/ldse:experience
    order by $experience ascending
    return (
        <option value="{ $experience/xs:string(.) }">{
            if ( $value = $experience) then ( attribute selected { 'selected' } ) else (),
            $experience/xs:string(.)
        }</option>
    )
};

declare function sp:save-site(
    $orig-file as element()?,
    $new-xml as element(),
    $new-form as element(ldse:formTemplate)
) {
    let $site-name as xs:string := $new-xml/name
    let $orig-name as xs:string? := $orig-file/name
    let $existing as element(siteProperties)? :=
        if ( $site-name = $orig-name ) then (
            sp:get-site-properties($site-name)
        ) else if ( fn:exists($orig-name) ) then (
            sp:get-site-properties($orig-name)
        ) else ()
    let $templates as element(template)* := $new-xml/templates/template
    let $put :=
        for $template as element(template) in $templates
        let $map-template as xs:int? := map:get($template-map, $template/type)
        return map:put($template-map, $template/type, 1 + $map-template)
    let $site-properties as element(siteProperties) := sp:create-site-properties($site-name, $new-xml, $templates, $existing)
    let $properties-path as xs:string := '/preview/cms/content/_configuration/site-properties/' || $site-name || '-site-properties.xml'
    let $save-properties as item()* :=
        if ( fn:exists($existing) ) then (
            document:document-replace($existing, $site-properties)
        ) else ( document:document-insert($properties-path, $site-properties) )

    return $new-xml
};

declare function sp:create-site-properties(
    $name as xs:string,
    $xml as element(),
    $templates as element(template)*,
    $existing as element(siteProperties)?
) as element(siteProperties) {
    let $disable-publishing := $xml/disable-publishing/xs:string(.)
    return
    element siteProperties {
        attribute site { $name },
        attribute display-name { $xml/display-name/xs:string(.) },
        element site-context {
            if ( fn:not(fn:starts-with($xml/site-context, '/')) and fn:exists($xml/site-context[. != '']) ) then (
                '/' || $xml/site-context/xs:string(.)
            ) else ( $xml/site-context/xs:string(.) )
        },
        $xml/page-not-found-uri,
        $xml/bing-search-configuration-id,
        $xml/bing-search-market,
        $xml/site-logo,
        $xml/country-code,
        element theme {
            element color {
                attribute main { $xml/theme/color/xs:string(.) }
            }
        },
        $xml/consolidation-status,
        $xml/suppress-lang-param,
        $xml/disable-publishing,
        element urls {
            element url {
                attribute env { 'preview' },
                $xml/preview-url/xs:string(.)
            },
            element url {
                attribute env { 'published' },
                $xml/published-url/xs:string(.)
            }
        },
        $xml/endpoints,
        $xml/content-endpoints,
        $xml/transform-apis,
        $xml/meta-tags,
        element caching {
            element cacheMaxAge { $xml/caching/xs:string(.) }
        },
        element admin-pages {
            element nav {
                element section {
                    attribute label { 'Pages' },
                    sp:get-section-pages($templates, $existing, 'pages')
                },
                element section {
                    attribute label { 'Content' },
                    sp:get-section-pages($templates, $existing, 'content'),
                    sp:other-template-processing($templates)
                },
                element section {
                    attribute label { 'Experiences' },
                    sp:get-section-pages-for-experiences($xml)
                },
                if ( $xml/sub-nav = 'true' ) then (
                    element section {
                        attribute label { 'Navigation' },
                        element page {
                            attribute id { 'sub-nav' },
                            attribute only-one { 'true' },
                            attribute formName { 'sub-nav' },
                            attribute template { 'false' },
                            'Sub Nav'
                        }
                    }
                ) else (),
                element section {
                    attribute label { 'Other' },
                    sp:get-other-links($xml/other-links)
                }
            },
            element languages {
                element enable { 'true' }
            }
        },
        $existing/element() except $existing/(site-context|page-not-found-uri|bing-search-configuration-id|bing-search-market|site-logo|country-code|urls|admin-pages|endpoints|theme|content-endpoints|transform-apis|caching|meta-tags|consolidation-status|suppress-lang-param|disable-publishing)
    }
};

declare function sp:get-other-links(
    $links
) {
    for $link as element(link) in $links/link
    return (
        element page {
            attribute href { $link/url/xs:string(.) },
            $link/title/xs:string(.)
        }
    )
};

declare function sp:get-section-pages-for-experiences(
    $xml as element()
) as element(page)* {
    for $experience as element(experience) at $pos in $xml/experiences/experience
    let $id as xs:string := $experience/type
    (: let $formName := $experience/type :)
    return (
        element page {
            attribute id { $id },
            attribute formName { $id },
            if( $experience/experience-display-name[. != ''] )
            then( $experience/experience-display-name/xs:string(.))
            else( $id )
        }
    )
};

declare function sp:get-section-pages(
    $template as element(),
    $existing as element(siteProperties)?,
    $section as xs:string?
) as element(page)* {
    let $db-template as element(template) := sp:get-templates($template/type)
    let $sub-template as xs:string? := $template/sub-template[. != '']
    let $template-sub-temp as element(sub-template)? := $db-template/sub-templates/sub-template[@id = $sub-template]
    let $db-sub-template as element(sub-template)? :=
        if ( fn:exists($sub-template) ) then (
            sp:get-sub-templates($sub-template)
        ) else ()
    return (
        if ( $section = 'pages' and fn:empty($template-sub-temp/@formName[. != '']) ) then (
            sp:get-page-element($template, $existing, $db-template, $sub-template, $template-sub-temp, $db-sub-template)
        ) else if ( $section = 'content' and fn:exists($template-sub-temp/@formName[. != '']) ) then (
            sp:get-page-element($template, $existing, $db-template, $sub-template, $template-sub-temp, $db-sub-template)
        ) else ()
    )
};

declare function sp:get-page-element(
    $template as element(),
    $existing as element(siteProperties)?,
    $db-template as element(template),
    $sub-template as xs:string?,
    $template-sub-temp as element(sub-template)?,
    $db-sub-template as element(sub-template)?
) {
    let $used-template := ( map:get($used-map, $template/type/xs:string(.)), 0 )[1]
    let $template-count as xs:int := ( map:get($new-map, $template/type/xs:string(.)), 0 )[1]
    let $put := map:put($used-map, $template/type/xs:string(.), $used-template + 1)
    let $pub-type as xs:string? := $template-sub-temp/@pub-type
    let $display-name as xs:string? := ( $template/display-name[. != ''], $db-sub-template/name[. != ''] )[1]
    let $existing-template as element(page)* :=
        if ( fn:exists($sub-template[. != '']) ) then (
            $existing/admin-pages/nav/section/page[@template = $db-template/@id and @sub-template = $sub-template]
        ) else ( $existing/admin-pages/nav/section/page[@template = $db-template/@id] )
    let $unique as xs:string? := if ( $used-template > 0 ) then ( '-' || $used-template + 1 ) else ()
    let $has-needs as xs:string* := ( fn:tokenize($db-template/@needs, ','), fn:tokenize($db-sub-template/@needs, ',') )
    let $page-id as xs:string :=
        if ( ( fn:exists($existing-template) and ( fn:count($existing-template) <= 1 or $template-count = 0 ) ) or $template-count = 0 ) then (
            ( $existing-template/@id, $template/type/xs:string(.) )[1]
        ) else ( $template/type/xs:string(.) || $template-count )
    return (
        element page {
            attribute id { $page-id },
            attribute template { $db-template/@id/xs:string(.) },
            attribute only-one { $db-template/@only-one = 'true' },
            attribute uri { $template/url/xs:string(.) },
            if ( fn:exists($sub-template) ) then (
                attribute sub-template { $sub-template },
                if ( $template-sub-temp/@formName[. != ''] ) then (
                    attribute formName { $template-sub-temp/@formName/xs:string(.) }
                ) else ()
            ) else (),
            if ( fn:exists($pub-type) and fn:not($pub-type = '') ) then ( attribute pub-type { $pub-type } ) else (),
            attribute pagination { 'true' },
            ( $template/display-name[. != '']/xs:string(.), $db-sub-template/name/xs:string(.), $db-template/name/xs:string(.) )[1]
        },
        map:put($new-map, $template/type/xs:string(.), $template-count + 1)
    )
};

declare function sp:other-template-processing(
    $templates as element(template)*
) {
    let $map as map:map := map:map()
    for $template as element(template) in $templates
    let $db-template as element(template) := sp:get-templates($template/type)
    let $sub-template as element(sub-template)? := $template/sub-template[. != '']
    let $db-sub-template as element(sub-template)? :=
        if ( fn:exists($sub-template) ) then (
            sp:get-sub-templates($sub-template)
        ) else ()
    let $needs as xs:string* := fn:distinct-values(( fn:tokenize($db-template/@needs, ','), fn:tokenize($db-sub-template/@needs, ',') ))
    return sp:get-global-template-needs($map, $needs)
};

declare function sp:get-key-value(
    $key-values as xs:string,
    $key-to-find as xs:string
) as xs:string {
    sp:get-key-value($key-values, $key-to-find, ())
};

declare function sp:get-key-value(
    $key-values as xs:string,
    $key-to-find as xs:string,
    $delimiter as xs:string?
) as xs:string {
    sp:get-key-value($key-values, $key-to-find, $delimiter, ())
};

declare function sp:get-key-value(
    $key-values as xs:string,
    $key-to-find as xs:string,
    $delimiter as xs:string?,
    $separator as xs:string?
) as xs:string {
    let $key-value-pairs as xs:string* := fn:tokenize($key-values, ($delimiter, ';')[1])
    for $key-value-pair as xs:string* in $key-value-pairs
    let $key-value as xs:string* := fn:tokenize($key-value-pair, ($separator, ':')[1])
    let $key as xs:string := ($key-value[1], '')[1]
    let $value as xs:string := ($key-value[2], '')[1]
    return
        if ($key eq $key-to-find) then ($value) else ()
};

declare function sp:get-global-template-needs(
    $map as map:map,
    $needs as xs:string*
) {
    for $need as xs:string in $needs
    let $is-complex-need as xs:boolean := fn:contains($need, ":")
    let $item as xs:string := if ( $is-complex-need ) then ( sp:get-key-value($need, 'form') ) else ( $need )
    let $only-one as xs:string := if ( $is-complex-need ) then ( sp:get-key-value($need, 'only-one') ) else ( 'true' )
    let $er := xdmp:log("Here is the need", "debug")
    let $er := xdmp:log($need, "debug")
    let $er := xdmp:log("is-complex-need", "debug")
    let $er := xdmp:log($is-complex-need, "debug")

    let $er := xdmp:log("Here is the item", "debug")
    let $er := xdmp:log($item, "debug")
    let $label as xs:string := if ( $is-complex-need ) then ( (sp:get-key-value($need, 'label'), $item)[1] ) else ( $item )
    where fn:not($item = '') and fn:empty(map:get($map, $item))
    return (
        element page {
            attribute id { $item || 'tag-options' },
            (:if ($item = "nav-categories") then (attribute only-one { "false"}) else (attribute only-one { $only-one }),:)
            attribute only-one { $only-one },
            attribute formName { $item },
            $label
        },
        map:put($map, $item, $item)
    )
};

declare function sp:get-site-links(){
    for $site as xs:string in $all-sites
    let $params as xs:string? := fn:substring-after(xdmp:get-original-url(), '?')
    let $new-params as xs:string := util:update-site-param($params, $site)
    let $new-url as xs:string := fn:substring-before(xdmp:get-original-url(), '?') || '?' || $new-params
    let $original-lang-param as xs:string?:= fn:substring(fn:substring-after($params, 'lang='), 1, 3)
    let $lang-for-site as xs:string?:= library:get-a-permitted-supported-languages-by-site($site, $original-lang-param)
    let $new-url as xs:string := if ($original-lang-param eq $lang-for-site) then $new-url else fn:replace($new-url, fn:concat('lang=', $original-lang-param), fn:concat('lang=', $lang-for-site))
    where ac:has-permission('ldse:view-lds-edit-home', '', '', $site)
    return (
        <link uri="{ $new-url }" xmlns="http://lds.org/code/lds-edit" icon="edit" permission="ldse:view-lds-edit-home" sequence="36" title="{ $site }" />
    )
};

declare function sp:get-non-template-content-types(
    $value as item()*
) as element(option)* {
    let $site-properties as element(siteProperties) := sp:get-site-properties(df:getVariable('currSite'))

    for $sub-template as element(sub-template) in sp:get-templates(())/sub-templates/sub-template[$site-properties//page/@sub-template]
    where ($sub-template/@id = $site-properties//page/@sub-template and fn:exists($sub-template/@pub-type) and fn:not($sub-template/@pub-type = ''))
    return (
        <option value="{ $sub-template/@pub-type/xs:string(.) }">{
            if ( $value = $sub-template/@pub-type ) then ( attribute selected { 'selected' } ) else (),
            $sub-template/@pub-type/xs:string(.)
        }</option>
    )
};

declare function sp:get-sub-templates(
    $template as xs:string?,
    $sub-template as xs:string?,
    $id as xs:string?,
    $index as xs:string?
) as element(option)* {
    if ( fn:exists($template) ) then (
        let $file as element()? := ldsemeta:get-file-by-id($id)
        let $index as xs:int? :=
            if ( $index castable as xs:int ) then (
                xs:int($index) + 1
            ) else (
                xs:int(util:substring-after-last($index, '-')) + 1
            )
        let $sub-templates as element(option)* := sp:get-sub-template-options($template, $index, $file)
        return (
            $sub-templates
        )
    ) else ()
};

declare function sp:get-sub-template-options(
    $template as xs:string?,
    $index as xs:int?,
    $file as element()?
) as element(option)* {
    let $selected-sub-temp as xs:string? := $file/templates/template[$index]/sub-template
    for $sub-temp as element(sub-template) in sp:get-templates($template)/sub-templates/sub-template
    let $sub as element(sub-template) := sp:get-sub-templates($sub-temp/@id)
    order by $sub/name ascending
    return (
        <option value="{ $sub/@id/xs:string(.) }">{
            if ( $sub/@id = $selected-sub-temp ) then (
                attribute selected { 'selected' }
            ) else (),
            $sub/name/xs:string(.)
        }</option>
    )
};

declare function sp:after-save-redirect-url(
    $origFile as element()?,
    $newXml as element(),
    $form as element(ldse:formTemplate)
) as xs:string {
    if ( fn:empty($origFile) ) then (
        $settings:shared-prefix || '/supported-languages?lang=eng' || '&amp;site=' || $newXml/name
    ) else ( $settings:shared-prefix || '/content-admin?lang=eng' || '&amp;site=' || $newXml/name )
};

declare function sp:get-site-properties-by-site-host-and-uri(
    $render404 as xs:boolean,
    $site as xs:string?,
    $host as xs:string,
    $uri as xs:string?
) {
    let $site-properties :=
        if (fn:exists($site)) then
            sp:get-site-properties($site)
        else sp:get-site-properties-by($host)

    return
        if (count($site-properties) eq 1) then
            $site-properties
        else

            let $page := if ($render404) then
                            let $address := fn:substring-after($uri, '--')
                            let $host := fn:tokenize(fn:substring-after($uri, '--'), '/')[1]
                            return fn:substring-after($address, $host)
                         else $uri
            let $result :=
                for $i in $site-properties
                (: where ($i/site-context/(.) ne ('') and $i/site-context/(.) ne ('/')  and ($context eq $i/site-context/(.))):)
                let $site-context := $i/site-context/fn:string()
                where fn:starts-with($page, $i/site-context/fn:string())
                return $i
            return
                if (count($result) eq 1) then
                    $result
                else if ($result) then
                        let $site-context := max(( $result/site-context/fn:string() ))
                        let $site := $result[site-context eq $site-context]
                        return $site
                else ()
};


declare function sp:getAPIEndpoints(
    $value as xs:string?
) as element(option)* {
    <option value=''></option>,
    for $t in sp:get-site-properties(df:getVariable('currSite'))/endpoints/endpoint
    return (
        if (xs:string($t/name/@uri-title) eq $value) then (
            <option value="{xs:string($t/name/@uri-title)}" selected="yes">{$t/name/xs:string(.)}</option>
        ) else (
            <option value="{xs:string($t/name/@uri-title)}">{$t/name/xs:string(.)}</option>
        )
    )
};

declare function sp:get-search-url(
    $url as xs:string?,
    $site-properties as element(siteProperties)?
) as xs:string? {
    $site-properties/endpoints/endpoint[name/@uri-title = $url]/url
};

(: This function finds a site and language that the user has permission to access :)
declare function sp:get-default-site-and-lang () as element (default-site-lang) ? {
    (for $site in $all-sites
    for $lang in (library:site-default-language($site), library:get-supported-languages-by-site($site)/language[@default-language ne 'yes' and @key ne 'eng']/@key)
    where ac:has-permission("ldse:edit-doc", $lang, '', $site)
    order by $site, $lang
    return element default-site-lang {attribute site{$site},
                                      attribute lang{$lang}  })[1]
};

declare function sp:get-site-name-by-host-without-site-prefix(
    $host as xs:string*
) as xs:string?  {
    for $i in cts:search(/siteProperties,
                cts:and-query((
                    cts:element-value-query(xs:QName('url'), $host, 'exact')
                ))
    )
    let $site-context := $i/site-context/fn:string()
    where $site-context eq '/' or $site-context = ''  or $site-context = ' ' or fn:empty($site-context) or fn:not(fn:exists($site-context))
    return $i/@site/fn:string()
};

declare function sp:get-consolidation-info($site as xs:string, $context as xs:string) as element (site)?
{
    cts:search(/site-additional-hosts/site,
        cts:and-query((
            cts:element-attribute-value-query(xs:QName('site'), xs:QName('id'), $site, 'exact'),
            cts:element-attribute-value-query(xs:QName('site'), xs:QName('context'), $context, 'exact')
        )))
};

declare function sp:get-consolidation-by-site-and-linked-host($host as xs:string, $site as xs:string)
    as element (site)?
{
    cts:search(/site-additional-hosts/site,
        cts:and-query((
            cts:element-attribute-value-query(xs:QName('site'), xs:QName('linked-host'), $host),
            cts:element-attribute-value-query(xs:QName('site'), xs:QName('id'), $site)
        )))
};

declare function sp:get-consolidation-by-host($host as xs:string)
    as element (site)*
{
    cts:search(/site-additional-hosts/site,
        cts:element-attribute-value-query(xs:QName('site'), xs:QName('host'), $host, 'exact')
    )
};

declare function sp:get-consolidation-by-site-host-context($host as xs:string, $site as xs:string, $context as xs:string)
as element (site)?
{
    cts:search(/site-additional-hosts/site,
        cts:and-query((
            cts:element-attribute-value-query(xs:QName('site'), xs:QName('host'), $host, 'exact'),
            cts:element-attribute-value-query(xs:QName('site'), xs:QName('id'), $site, 'exact'),
            cts:element-attribute-value-query(xs:QName('site'), xs:QName('context'), $context, 'exact')
        )))
};


declare function sp:find-sites-by-host-and-uris($host as xs:string, $uris as xs:string*)
as element (site)*
{
    let $group1 :=
        for $site in (sp:get-site-properties-by($host))
        let $status := if ($site/urls/url[. eq $host]/@env eq 'preview') then 'preview' else 'publish'
        let $site-context := fn:replace($site/site-context||'/', '//', '/')
        let $site-context2 := functx:substring-before-last($site-context, '/')
        let $match := for $uri in $uris
                        where fn:starts-with($uri,$site-context) or ($uri eq $site-context) or ($uri eq $site-context2 )
                        return $uri
        return
            if ($match) then
                element site {
                    attribute id {$site/@site},
                    attribute full-prefix {$site/site-context},
                    attribute site-prefix {$site/site-context},
                    attribute status {$status},
                    attribute site-logo {$site/site-logo},
                    attribute page-not-found {$site/page-not-found-uri}
                }
            else ()

    let $group2 :=
        for $site in sp:get-consolidation-by-host($host)
        let $site-data := sp:get-site-properties($site/@id)
        let $site-context := $site-data/site-context/fn:string()
        let $full-prefix := fn:replace($site/@prefix||$site-context||'/', '//', '/')
        let $match := for $uri in $uris
                        where fn:starts-with($uri,$full-prefix) or ($uri eq $full-prefix) or ($uri eq functx:substring-before-last($full-prefix, '/') )
                        return $uri
        return  if ($match and $site-data/consolidation-status/fn:string() eq 'consolidated' ) then
            element site {
                attribute id {$site/@id},
                attribute full-prefix {$full-prefix},
                attribute consolidation-prefix {$site/@prefix},
                attribute site-prefix {$site-context},
                attribute linked-host {$site/@linked-host},
                attribute status {$site/@context},
                attribute site-logo {$site-data/site-logo},
                attribute page-not-found {$site-data/page-not-found-uri}
            }
        else ()
    let $max := max(($group1/@full-prefix/string-length(),$group2/@full-prefix/string-length() ))
    return (($group1, $group2)[@full-prefix/string-length() eq $max])

};

declare function sp:find-sites-by-site-host-and-uris($site as xs:string, $host as xs:string, $uris as xs:string*, $isDevOP as xs:boolean)
as element (site)*
{
        for $site in (sp:get-site-properties($site))
        let $status := if (fn:contains($host, 'preview')) then 'preview' else 'publish'
        let $site-context := fn:replace($site/site-context||'/', '//', '/')
        let $site-context2 := functx:substring-before-last($site-context, '/')
        let $match :=
            for $uri in $uris
            where fn:starts-with($uri,$site-context) or fn:starts-with($uri,$site-context2) or ($uri eq $site-context) or ($uri eq $site-context2 )
            return $uri
        return
            if ($match or $isDevOP) then
                element site {
                    attribute id {$site/@site},
                    attribute full-prefix {$site/site-context},
                    attribute site-prefix {$site/site-context},
                    attribute status {$status},
                    attribute site-logo {$site/site-logo},
                    attribute page-not-found {$site/page-not-found-uri}
                }
            else ()
};

declare function sp:get-site-home-page($site-properties as element(siteProperties), $status as xs:string*, $devOpNonProd as xs:boolean){
    let $_prefix := $site-properties/site-context/fn:string()
    let $devop-homepage := if ($_prefix eq ('', '/')) then '/'||$site-properties/@site else $_prefix
    let $site-prefix := if ($_prefix eq ('', '/')) then () else $_prefix
    let $env := if (($status) eq 'publish') then 'published' else 'preview'
    return if ($devOpNonProd) then
             $devop-homepage
           else "//"||$site-properties/urls/url[@env eq $env]||$site-prefix
};

declare function sp:non-cuc-sites () as xs:string* {
    for $site in cts:search(/siteProperties, ())
    let $template :=
        for $t in $site/admin-pages/nav/section[@label eq 'Pages']/page
        where not(starts-with($t/@id, 'mo-'))
        return $t
    return if ($template) then $site/@site/fn:string() else ()
};
