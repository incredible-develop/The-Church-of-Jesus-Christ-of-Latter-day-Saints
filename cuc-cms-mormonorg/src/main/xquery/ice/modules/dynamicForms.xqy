xquery version "1.0-ml";

module namespace dynamicForms = "http://lds.org/code/shared/lds-edit/dynamicForms";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace mJson = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace fsDoc = "http://lds.org/code/shared/common/document/filesystem-doc-functions" at "/shared/common/document/filesystemDocFunctions.xqy";
import module namespace cpfCommon = "http://lds.org/code/shared/cpf/common-functions" at "/shared/common/cpf/commonFunctions.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace fast = "http://lds.org/code/shared/lds-edit/fast-i18n" at "/rice/modules/fast-i18n.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "/ice/modules/iceFunctions.xqy";
import module namespace task = "http://lds.org/code/shared/lds-edit/task-functions" at "/pharaoh/modules/taskFunctions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "/modules/ldse-meta.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace json = "http://marklogic.com/json" at "/modules/fasterjson.xqy";
import module namespace category = "http://lds.org/code/shared/lds-edit/category-functions" at "/modules/category-functions.xqy";
import module namespace sp = "http://lds.org/code/modules/site-properties" at '/modules/site-properties.xqy';
import module namespace moc = "http://lds.org/code/shared/lds-edit/mormonOrgComponents" at "/ice/modules/mormonOrgComponents.xqy";
import module namespace mofc = "http://lds.org/code/shared/lds-edit/mormonOrgFormComponents" at "/ice/modules/mormonOrgFormComponents.xqy";
import module namespace mosfc = "http://lds.org/code/shared/lds-edit/mormonOrgSteppedFormComponents" at "mormonOrgSteppedFormComponents.xqy";
import module namespace mpc = "http://lds.org/code/shared/lds-edit/missionaryPortalComponents" at "missionaryPortalComponents.xqy";
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at "/modules/document-functions.xqy";
import module namespace lib-multipart-post = "http://marklogic.com/ps/lib-multipart-post" at "/shared/common/http/lib-multipart-post.xqy";
import module namespace gct = "http://lds.org/code/transforms/gl-card-transform" at '/transforms/gl-card-transform.xqy';
import module namespace rice = "http://lds.org/code/shared/lds-edit/riceFunctions" at '/string-manager/modules/stringFunctions.xqy';
import module namespace api = "http://lds.org/code/transforms/modules/api-functions" at "/transforms/modules/api-functions.xqy";
import module namespace cf = "http://lds.org/code/lds-edit/content-admin/content-functions" at "/content-admin/modules/content-functions.xqy";
import module namespace tf = 'http://lds.org/code/modules/titan-functions' at "/modules/titan-functions.xqy";
(: ENRICH R&D :)
import module namespace enrich = "http://lds.org/code/shared/lds-edit/enrich" at "../../enrich/enrich-functions.xqy";
(: ENRICH R&D :)

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace cts = "http://marklogic.com/cts";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace its = "http://www.w3.org/2005/11/its";
declare namespace lds = "http://www.lds.org/schema/lds-meta/v1";
declare namespace basicJson = "http://marklogic.com/xdmp/json/basic";
declare namespace jsonb = "http://marklogic.com/xdmp/json/basic";

declare option xdmp:mapping "true";

declare variable $DEPRECATED as empty-sequence() := util:deprecated(());

declare variable $site-properties as element(siteProperties)* := sp:get-site-properties(());
declare variable $variables as map:map := map:map();
declare variable $functions as map:map := map:map();
declare variable $formName as xs:string? := xdmp:get-request-field("form")[1];
declare variable $form as element(ldse:formTemplate)? := getFormTemplate($formName);
declare variable $map as map:map := map:map();
declare variable $all-tags as element(tag)* := category:getTags();
declare variable $comp-map as map:map := map:map();
(: Map for versification ids :)
declare variable $vers-map as map:map := map:map();
declare variable $cache-form as map:map := map:map();
declare variable $clone-requested as xs:string? := xdmp:get-request-field("clone");

declare variable $ldse-settings as element(ldse:ldse-settings) := $core:ldse-settings;
declare variable $content-api-asset as xs:string? := ( $ldse-settings/ldse:content-api-asset[. != ''], 'https://contentapi.churchofjesuschrist.org/assetsearch/api/v2/asset/versionID' )[1];


declare function get-form($name as xs:string) as element(ldse:formTemplate)? {
    get-form($name, ())
};

declare function get-form($name as xs:string, $options as xs:string?) as element(ldse:formTemplate)? {
    let $form as element(ldse:formTemplate)? := map:get($cache-form, $name)
    let $form-location as xs:string? := getFormOptions($options, 'form-location')
    return (
        if ( fn:exists($form) ) then (
            $form
        ) else (
            let $new-form as element(ldse:formTemplate)? :=
                cts:search(/ldse:formTemplate,
                    cts:and-query((
                        if ( fn:exists($form-location) and fn:not($form-location = "") ) then (
                            cts:directory-query($form-location, 'infinity')
                        ) else (core:get-filter-query()),
                        cts:element-attribute-value-query(xs:QName("ldse:formTemplate"),xs:QName("name"),($name),'exact')
                    ))
                )[1]
            let $new-form as element(ldse:formTemplate)? :=
                if ( fn:exists($new-form) ) then (
                    $new-form
                ) else (
                    cts:search(/ldse:formTemplate,
                        cts:and-query((
                            core:get-filter-query(),
                            cts:element-attribute-value-query(xs:QName("ldse:formTemplate"),xs:QName("name"),($name),'exact')
                        ))
                    )[1]
                )
            let $add-to-cache as empty-sequence() := map:put($cache-form, $name, $new-form)
            return $new-form
        )
    )
};

declare function getFormTemplateWithoutMode(
    $name as xs:string
) as element(ldse:formTemplate) {
    cts:search(/ldse:formTemplate,
        cts:and-query((
            cts:element-attribute-value-query(xs:QName("ldse:formTemplate"),xs:QName("name"),($name),'exact')
        ))
    )[1]
};

declare function getFormTemplate($name as xs:string) as element(ldse:formTemplate)? {
    let $options as xs:string := xdmp:url-decode(xdmp:get-request-field("option", ""))[1]
    let $form as element(ldse:formTemplate)? := get-form($name, $options)
    let $addFunctions as empty-sequence() := addFunction($form/ldse:functions/ldse:function)
    let $addFormVariables as empty-sequence() := addFormVariable($form/ldse:variables/ldse:variable)
    let $addForm as empty-sequence() := setVariable('formXml', $form)
    return ($form)
};

(: Adds functions defined in the xml to the functions map :)
declare function addFunction($functionXml as element(ldse:function)) as empty-sequence() {
    let $function as xdmp:function := xdmp:function(fn:QName(xs:string($functionXml/@namespace), xs:string($functionXml/@name)), xs:string($functionXml/@path))
    return (
        map:put($functions, xs:string($functionXml/@name), $function)
    )
};

(: adds form variables to variable map :)
declare function addFormVariable($variable as element(ldse:variable)) as empty-sequence() {
    if (fn:exists($variable/@value)) then (
        setVariable(xs:string($variable/@name), xs:string($variable/@value))
    ) else if (fn:exists($variable/@function)) then (
        setVariable(xs:string($variable/@name), xdmp:apply(getFunction($variable/@function)))
    ) else ()
};

declare function getRootFile(
    $form as element(ldse:formTemplate)
) as element()? {
    if ( fn:not(getVariable('action') = 'add') ) then (
        let $file as element()? :=
            cts:search(/*,
                cts:and-query((
                    core:get-filter-query(),
                    buildQuery($form/ldse:root-query/*)
                ))
            )[1]
        let $country as xs:string? := getVariable('country')
        let $source as xs:string? := ldsemeta:get-document-source($file)
        let $id as xs:string? := getVariable('id')
        where ( fn:not($country = '') and $country eq $source) or ($country eq '' and $source eq 'chq')
        return (
            let $file as element()? := preProcessing($file,$form)
            let $id as empty-sequence() :=
                if (getVariable('action') = 'edit' and ($id = '' or fn:empty($id)) ) then (
                    setVariable('id', getId($file))
                ) else ()
            let $addFile as empty-sequence() := setVariable('file', $file)
            let $addSource as empty-sequence() := setSourceVariable($file)
            return ($file)
        )
    ) else ()
};

declare function buildQuery($query as element()*) as cts:query* {
    cts:query(replaceQueryVariables($query))
};

(: Returns the variables in the query :)
declare function getQueryVariables($nodes as item()*) as item()* {
    for $n as item() in $nodes
    return (
        typeswitch ($n)
            case text() return ()
            case element(cts:text) return (
                if (fn:starts-with(xs:string($n) ,'$')) then (
                    functx:substring-after-if-contains(xs:string($n), '$')
                ) else ()
            )
            default return getQueryVariables($n/node())
    )
};

(: Replaces any variables found in a cts:text element with the values found in the variable map :)
declare function replaceQueryVariables($nodes as item()*) as item()* {
    for $n as item() in $nodes
    return (
        typeswitch ($n)
            case text() return ($n)
            case element(cts:text) return (
                if (fn:starts-with(xs:string($n) ,'$')) then (
                    replaceQueryVariable($n)
                ) else ($n)
            )
            default return element { fn:node-name($n) } { $n/@*, ($n/namespace::*)[. ne "http://lds.org/code/lds-edit"], replaceQueryVariables($n/node()) }
    )
};

(: builds new cts:text with variable value :)
declare function replaceQueryVariable($ctsText as element(cts:text)) as element(cts:text) {
    element cts:text {
        getVariable( fn:substring-after(xs:string($ctsText),'$') )
    }
};

declare function setSourceVariable($file as element()?) as empty-sequence() {
    let $source as xs:string? := ldsemeta:get-document-source($file)
    return (
        if (getVariable('action') ne 'add' and $source ne '') then (
            setVariable('source', $source)
        ) else (
            if (fn:exists(getVariable('country'))) then (
                setVariable('source', getVariable('country'))
            ) else (
                setVariable('source', 'chq')
            )
        )
    )
};

(: used on save to generate new id :)
declare function newId($locale as xs:string) as xs:string {
    let $newId as xs:string := util:generate-unique-id($locale)
    let $update as empty-sequence() := setVariable('id', $newId)
    return ($newId)
};


(: returns the value of a variable from the map :)
declare function getVariable($param as xs:string) as item()* {
    let $mapIsReady as empty-sequence() :=
        if (map:count($variables) eq 0) then (
            buildParamMap()
        ) else ()
    return (
        map:get($variables, $param)
    )
};

(: adds a variable to the map :)
declare function setVariable($name as xs:string, $value as item()*) as empty-sequence() {
    map:put($variables, fn:concat("$", $name), $value),
    map:put($variables, $name, $value)
};

declare function get-custom-page(
    $uri as xs:string,
    $locale as xs:string,
    $site as xs:string?
) as element(custom-page)* {
    cts:search(/custom-page,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-range-query(xs:QName("ldse:document"), xs:QName("uri"), "=", $uri),
            cts:element-attribute-range-query(xs:QName("ldse:document"), xs:QName("locale"), "=", $locale),
            if ( fn:exists($site[. != '']) ) then (
                cts:or-query((
                    cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("site"), $site, 'exact'),
                    cts:element-value-query(xs:QName("ldse:site-context"), $site, 'exact')
                ))
            ) else ()
        ))
    )
};

declare function get-article(
    $uri as xs:string,
    $locale as xs:string,
    $site as xs:string?
) as element(article)* {
    cts:search(/article,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-range-query(xs:QName("ldse:document"), xs:QName("uri"), "=", $uri),
            cts:element-attribute-range-query(xs:QName("ldse:document"), xs:QName("locale"), "=", $locale),
            if ( fn:exists($site[. != '']) ) then (
                cts:or-query((
                    cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("site"), $site, 'exact'),
                    cts:element-value-query(xs:QName("ldse:site-context"), $site, 'exact')
                ))
            ) else ()
        ))
    )
};

declare function get-custom-page-item(
    $uri as xs:string,
    $locale as xs:string,
    $site as xs:string?
) as element()? {
    cts:search(/custom-page,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-range-query(xs:QName("ldse:document"), xs:QName("uri"), "=", $uri),
            cts:element-attribute-range-query(xs:QName("ldse:document"), xs:QName("locale"), "=", $locale),
            cts:element-attribute-value-query(xs:QName("ldse:sensitive"), xs:QName("status"), "yes", "exact"),
            if ( fn:exists($site[. != '']) ) then (
                cts:or-query((
                    cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("site"), $site, 'exact'),
                    cts:element-value-query(xs:QName("ldse:site-context"), $site, 'exact')
                ))
            ) else ()
        ))
    )
};

declare function get-custom-component-page(
    $id as xs:string,
    $uri as xs:string,
    $locale as xs:string,
    $site as xs:string
) as element()* {
    let $file := ldsemeta:get-file-by($id, $locale, (), (), $site)
    let $result :=
    cts:search(fn:doc(fn:base-uri($file)),
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-range-query(xs:QName("ldse:document"), xs:QName("uri"), "=", $uri),
            cts:element-attribute-range-query(xs:QName("ldse:document"), xs:QName("locale"), "=", $locale),
            cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("id"), $id, 'exact'),
            if ( fn:exists($site[. != '']) ) then (
                cts:or-query((
                    cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("site"), $site, 'exact'),
                    cts:element-value-query(xs:QName("ldse:site-context"), $site, 'exact')
                ))
            ) else ()
        ))
    )
    return
        if( $result ) then
            $result/node()
        else ( )
};

(: Populates variable map with common variables :)
declare function buildParamMap() as empty-sequence() {
    let $host as xs:string := $util:host
    let $protocol as xs:string := $util:protocol
    let $country as xs:string? := util:escape-chars(xdmp:get-request-field("country", ""))
    let $lang as xs:string := util:escape-chars(xdmp:get-request-field("lang", "eng"))
    let $locale as xs:string := if ($country ne '') then (fn:concat($lang,'-',$country)) else ($lang)
    let $uri as xs:string? := xdmp:url-decode(( xdmp:get-request-field("uri-path"), xdmp:get-request-field("uri", "/") )[1])
    let $page as xs:string? := xdmp:url-decode(xdmp:get-request-field("page", $uri))
    let $file as element()? := getRootFile($form)
    let $options as xs:string? := xdmp:url-decode(xdmp:get-request-field("option", ""))[1]
    let $required-options as xs:string? := getFormOptions($options, 'requiredFields')
    let $removed-fields as xs:string? := getFormOptions($options, 'removedFields')
    let $added-fields as xs:string? := getFormOptions($options, 'addedFields')
    let $curr-site as xs:string? := xdmp:get-request-field('site')[1]
    let $required-map as map:map := map:map()
    let $removed-map as map:map := map:map()
    let $added-map as map:map := map:map()
    let $put :=
        for $item as xs:string in fn:tokenize($required-options, ';')
        where fn:not($item = '')
        return map:put($required-map, $item, $item)
    let $put :=
        for $item as xs:string in fn:tokenize($removed-fields, ';')
        where fn:not($item = '')
        return map:put($removed-map, $item, $item)
    let $put :=
        for $item as xs:string in fn:tokenize($added-fields, ';')
        where fn:not($item = '')
        return map:put($added-map, $item, $item)
    let $is-submission as xs:boolean := xs:boolean((xdmp:get-request-field("is-submission", xdmp:get-request-field("isSubmission", xdmp:get-request-field("issubmission"))), "false")[1])
    let $custom-page as element(custom-page)* := get-custom-page($uri, $locale, $curr-site)
    let $sensitive-page as xs:boolean :=
        if ( fn:exists($custom-page) ) then (
            fn:false()
        ) else (
            fn:false()
        )
    let $is-submission as xs:boolean :=
        if(fn:not($is-submission)) then ( ldsemeta:is-submission($file) ) else ($is-submission)
    let $id as xs:string? := xdmp:get-request-field('id')[1]
    let $form-name as xs:string? :=
        if ( fn:exists($options) ) then (
            getFormOptions($options, 'form')
        ) else ()
    let $default as xs:string :=
        if ( fn:exists($file) or ( fn:exists($id) and fn:not($id = "") ) or ( fn:exists($custom-page) and fn:empty($form-name) ) ) then (
            'edit'
        ) else ( 'add' )
    return (
        setVariable('context', core:get-mode-root()),
        setVariable('binaryMangerActive', $settings:binary-manager-active),
        setVariable('site', $core:site),
        setVariable('host', $host),
        setVariable('protocol', $protocol),
        setVariable('sharedPrefix', $settings:shared-prefix),
        setVariable('cdn', $settings:cdn-path),
        setVariable('lang', $lang),
        setVariable('country', $country),
        setVariable('locale', $locale),
        setVariable('id', xdmp:get-request-field("id", "")[1]),
        setVariable('uri', $uri),
        setVariable('page', $page),
        setVariable('action', xdmp:get-request-field("action", $default)),
        setVariable('status', xdmp:get-request-field("status", "ldse:preview")),
        setVariable('to-translate', xdmp:get-request-field("to-translate", "")),
        setVariable('option', ( $options, ldsemeta:get-form-options($file) )[1]),
        setVariable('currentDateTime', fn:current-dateTime()),
        setVariable('currentDate', fn:current-date()),
        setVariable('user', ac:getUserName()),
        setVariable('referer', xdmp:get-request-field('referer', xdmp:get-request-header('Referer',''))),
        setVariable("is-submission", $is-submission),
        setVariable("file", $file),
        setVariable('currSite', $curr-site),
        setVariable("formName", $formName),
        setVariable('required-fields', $required-map),
        setVariable('removed-fields', $removed-map),
        setVariable('added-fields', $added-map),
        setVariable("sensitive-page", $sensitive-page),
        setVariable('formAction', (xdmp:get-request-field('formAction'), 'create')[1]),
        addOptionsVariables($options)
    )
};

declare function addOptionsVariables($options as xs:string?) as empty-sequence() {
    if ( $options = "" ) then (
    (: populate data if nothing was posted :)
    let $id as xs:string := getVariable('id')
    let $locale as xs:string := getVariable('locale')
    let $file as element()? := if ( fn:not($id = "") and fn:exists($id) ) then ( ldsemeta:get-file-by($id, $locale, (), ()) ) else ()
    let $options as element(form-options)? := ldsemeta:get-form-options($file)
    let $uri as xs:string? := ldsemeta:get-document-uri($file)
    let $sets as item()* := (
        setVariable('uri', $uri),
        setVariable('page', $uri),
        setVariable('option', ice:csv-variables($options) ),
        for $option as element() in $options/*
        return (
            setVariable( fn:local-name($option), xs:string($option) )
        )
    )
    return ()
    ) else (
        for $option as xs:string in fn:tokenize($options, ',')
        let $name as xs:string := fn:substring-before($option, ":")
        let $value as xs:string := fn:substring-after($option, ":")
        return (
            setVariable($name, $value)
        )
    )
};

declare function getFormOptions($options as xs:string, $string-match as xs:string) as xs:string? {
    for $option as xs:string in fn:tokenize($options, ',')
    let $name as xs:string := fn:substring-before($option, ":")
    let $value as xs:string := fn:substring-after($option, ":")

    where $name = $string-match
    return (
        $value
    )
};

declare function jsVariableMap() as element(script) {
    jsVariableMap(fn:true())
};

declare function jsVariableMap($outputFormVars as xs:boolean) as element(script) {
    <script type="text/javascript">
        {
            if ($outputFormVars) then (
                'ICE.formVars = {',
                fn:string-join(
                        for $key as xs:string in map:keys($variables)
                        let $value as xs:string* :=
                            if ( fn:not($key = ( '$required-fields', 'required-fields', 'removed-fields', '$removed-fields', 'added-fields', '$added-fields' )) ) then (
                                xs:string(getVariable($key))
                            ) else ()
                        where fn:not($key eq ('file', 'formXml', "$file", "$formXml")) and $value castable as xs:string
                        return ( json:escapedKeyValue($key, $value) ),
                        ','
                ),
                '}'
            ) else ()
        }
        if (!ICE.postVars) {{ ICE.postVars = {{}}; }}
        ICE.apiVars = {{contentApiUrl: '{$settings:content-api-url}', contentApiAsset: '{$settings:content-api-asset}'}};
        ICE.postVars[{util:js-string-escape( (getVariable('form'), "form")[1] )}] = {
        json:obj((
            for $field as xs:string in xdmp:get-request-field-names()[ . != ""]
            let $values as item()* := xdmp:get-request-field($field)
            let $toJsonValues := if ($clone-requested) then (
                    if($field eq 'action') then (
                        "add"
                    ) else ( $values )
                ) else ( $values )
            where fn:not($field = ('lang','country','id'))
            return (
                for $value as item() in $toJsonValues
                return (
                    json:escapedKeyValue($field, $value)
                )
            ),
            json:escapedKeyValue("referer", xdmp:get-request-field('referer', xdmp:get-request-header('Referer','')))
        ))
    };
    </script>
};

declare function ouputJavascript($form as element(ldse:formTemplate)) as element()* {
    for $script as element() in $form/ldse:javascript/*
    let $src as xs:string? := $script/@src
    let $function as xs:string? := $script/@function
    return (
        if ($function != '') then (
            xdmp:apply(getFunction($function), $form)
        ) else if (fn:matches($src, "\{\$.*\}" )) then (
            <script>{
                $script/@*[fn:not(fn:node-name(.) eq xs:QName('src'))],
                attribute src { evalVarsInSrc($src) },
                $script/node()
            }</script>
        ) else (
            $script
        )
    )
};

declare function ouputCss($form as element(ldse:formTemplate)) as element()* {
    for $link as element() in $form/ldse:css/*
    let $href as xs:string? := $link/@href
    let $function as xs:string? := $link/@function
    return (
        if ($function != '') then (
            xdmp:apply(getFunction($function), $form)
        ) else if (fn:matches($href, "\{\$.*\}" )) then (
            <link>{
                $link/@* except $link/@href,
                attribute href { evalVarsInSrc($href) },
                $link/node()
            }</link>
        ) else (
            $link
        )
    )
};

declare function evalVarsInSrc($src as xs:string) as xs:string {
    let $vars as xs:string* :=
        for $token as xs:string in fn:tokenize($src, '\}')
        let $var as xs:string? := fn:substring-after(fn:substring-after($token, '{'),'$')
        where $var ne ''
        return ($var)
    return evalVarInSrc($src, $vars)
};

declare function evalVarInSrc($src as xs:string?, $vars as xs:string*) as xs:string {
    if (fn:exists($vars)) then (
        let $var as xs:string := $vars[1]
        let $replaceStr as xs:string := fn:concat('\{\$', $var, '\}')
        let $value as xs:string := (getVariable($var), '')[1]
        let $newSrc as xs:string := fn:replace($src, $replaceStr, $value)
        return ( evalVarInSrc($newSrc, fn:subsequence($vars, 2)) )
    ) else ( $src )
};

declare function buildForm($structure as element()*, $file as element()?, $index as xs:string?) as element()* {
    buildForm($structure, $file, $index, ())
};

declare function buildForm(
    $structure as element()*,
    $file as element()?,
    $index as xs:string?,
    $path as xs:string?
) as element()* {
    buildForm($structure, $file, $index, (), ())
};

declare function buildForm(
    $structure as element()*,
    $file as element()?,
    $index as xs:string?,
    $path as xs:string?,
    $input-type as xs:string?
) as element()* {

    for $n as element() in $structure
    let $inInputGroupInput as xs:boolean := fn:exists($n/ancestor::*[@inputGroup eq "true"][1])
    let $removed-fields as xs:string* := map:get(getVariable('removed-fields'), fn:local-name($n))
    where fn:not(fn:local-name($n) = $removed-fields)
    return (
        typeswitch ( $n )
            case element(ldse:xhtml) return (buildXhtml($n, $file, $index))
            case element(ldse:input) return (
                if ($n/@type/fn:string(.) eq "inputGroupFunctions:inputGroupInput" or $inInputGroupInput eq fn:false()) then (
                    buildInput($n, $file, $index)
                ) else ()
            )
            case element(ldse:dynamic-xml) return (
                if ($inInputGroupInput eq fn:false()) then (
                    buildDynamicInputs($n, $file, $index)
                ) else ()
            )
            case element(ldse:dynamic-form-ref) return (
                if ($inInputGroupInput eq fn:false()) then (
                    buildDynamicFormRefs($n, $file, $index)
                ) else ()
            )
            case element(ldse:dynamic-titan-item-refs) return (
                buildDynamicTitanItems($n, $file, $index)
            )
            case element(ldse:component-ref) return (
                buildComponents($n, $file, $index, $path))
            default return (
                if ( fn:exists($input-type) ) then (
                    let $element as element()* := $n/element()[fn:local-name(.) = $input-type]
                    return (
                        if ( fn:exists($element) ) then (
                            buildForm($element, $file, $index, $path, $input-type)
                        ) else ( buildForm($n/element(), $file, $index, $path, $input-type) )
                    )
                ) else ( buildForm($n/element(), $file, $index, $path, $input-type) )
            )
    )
};

declare function added-fields(
    $file as element()?
) {
    for $item as xs:string in map:keys(getVariable('added-fields'))
    let $type as xs:string := fn:substring-after($item, ':')
    let $type as xs:string :=
        if ( fn:contains($type, '|') ) then (
            fn:substring-before($type, '|')
        ) else ( $type )
    let $name as xs:string := fn:substring-before($item, ':')
    let $options as xs:string := fn:substring-after(fn:substring-after($item, ':'), '|')
    let $options :=
        if ( $type = 'select' ) then (
            if (fn:contains($options, '[dynamic-options]')) then
                let $dynamic-function := xdmp:function(xs:QName(fn:concat('dynamicForms:', fn:substring-after($options, '[dynamic-options]'))))
                return xdmp:apply($dynamic-function, ())
            else
                for $option as xs:string in fn:tokenize($options, '#')
                return (
                    <ldse:option value="{ fn:substring-before($option, '!') }">{ fn:substring-after($option, '!') }</ldse:option>
                )
        )
          else ()
    let $new-input as element(ldse:input) := <ldse:input type="{ $type }" xpath="{ $name }/node()" name="{ $name }" title="{ $name }"
                id="{ $name }">{ $options }</ldse:input>
    return (
        buildInput($new-input, $file, ())
    )
};

declare function groupInputs($form as element(ldse:formTemplate), $inputs as element()*, $allow-closed as xs:boolean) as element()* {
    let $groups as element(ldse:group)* := $form/ldse:groups/ldse:group
    for $item as element() in ($groups, $inputs)
    order by fn:number($item/(@data-sequence|@seq))
    return (
        typeswitch ( $item )
        case element(ldse:group) return (
            let $group as element(ldse:group) := $item
            let $name as xs:string? := $group/@name
            let $title as xs:string? := $group/@title
            let $group-inputs as element()* :=
                for $input as element() in $inputs[@data-group = $name or ( $name = "" and fn:empty(@data-group))]
                order by fn:number($input/@data-sequence)
                return $input
            let $group-ul as element(ul)* := $group-inputs/dd/ul
            let $collapsing as xs:string? :=
                if ( (fn:exists($group-ul/@collapsible) or $group-ul/@collapsible = "true") and (fn:exists($group-ul/@collapsed) or $group-ul/@collapsed = "true") ) then (
                    "expand"
                ) else if ( fn:exists($group-ul/@collapsible) or $group-ul/@collapsible = "true" ) then (
                    "collapse"
                ) else ()
            where fn:exists($group-inputs)
            return (
                <section class="ldse-group ldse-section { if ($allow-closed and $group/@closed = "true") then ( "closed" ) else (),
                                                          if (fn:exists($group/@region) and $group/@region/fn:string(.) eq "true") then ("ldse-region") else (),
                                                          if ($group/@region/fn:string(.) eq "true" and fn:exists($group/@regionType)) then (fn:concat("ldse-region--",$group/@regionType/fn:string(.))) else (),
                                                          if ($group/@required/fn:string(.) eq "true") then ("ldse-region--required") else () }"

                        allowed="{if (fn:exists($group/@allowed)) then ($group/@allowed/fn:string(.)) else ()}">
                    <div class="ldse-section--header">
                        <h2><a href="#d" class="ldse-icon-ko-tri-down ldse-group-header">{ $title }</a></h2>
                        {
                            if ( $collapsing = "expand" ) then (
                                <button onclick="return false;" class="ldse-button header-right ldse-icon-ko-tri-down" id="toggle-btn-collapse">Expand All</button>
                            ) else if ( $collapsing = "collapse" ) then (
                                <button onclick="return false;" class="ldse-button header-right ldse-icon-ko-tri-right" id="toggle-btn-collapse">Collapse All</button>
                            ) else ()
                        }
                    </div>
                    <div class="ldse-section--body ldse-form">
                        { $group-inputs }
                    </div>
                </section>
            )
        )
        default return (
            if ( fn:not($item/@data-group = $groups/@name) ) then (
                $item
            ) else ()
        )
    )
};

declare function getFunction($name as xs:string) as xdmp:function {
    let $name := fn:normalize-space($name)
    let $function as xdmp:function? := map:get($functions,$name)
    return (
        if (fn:exists($function)) then (
            $function
        ) else (
            xdmp:function(fn:QName("http://lds.org/code/shared/lds-edit/dynamicForms", $name))
        )
    )
};

(: Input Help Functions :)
declare function required(
    $input as element(ldse:input)
) as element(em)? {
    let $required as xs:boolean := fn:exists(map:get(getVariable('required-fields'), $input/@name))
    return (
        if (fn:contains($input/@class, 'required') or $required) then (
            <em>*</em>
        ) else ()
    )
};

declare function buildInputName($input as element(ldse:input), $index as xs:string?) as xs:string? {
    if (fn:exists($index)) then (
        fn:concat($input/@name, '-', $index)
    ) else (
        xs:string($input/@name)
    )
};

declare function buildInputId($input as element(ldse:input), $name as xs:string) as xs:string {
    if (fn:exists($input/@id)) then (
        xs:string($input/@id)
    ) else ($name)
};

declare function searchInput($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    textInput($input, $file, $index)
};

declare function urlInput($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    textInput($input, $file, $index)
};

declare function emailInput($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    textInput($input, $file, $index)
};

declare function numberInput($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    textInput($input, $file, $index)
};

declare function passwordInput($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    textInput($input, $file, $index)
};

declare function checkForDefault($input as element(ldse:input), $value as item()*) as item()* {
    checkForDefault($input, $value, ())
};

declare function permalink($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $blockAttrs as xs:string* := ('type','seq', 'name', 'value', 'id', 'options', 'xpath', 'dlClass', 'help')
    let $value as item()* := checkForDefault($input, dynamicXpath($file, xs:string($input/@xpath)), xs:string($input/@value))
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            {inputLabel($input, $id, $index)}
            <dd>{
                element input {
                    getInputAttributes($input, $blockAttrs, $index),
                    attribute name {$name},
                    attribute type { "text" },
                    attribute value {xdmp:quote($value)},
                    attribute id {$id},
                    if ( getVariable("action") = "edit" and fn:not(ac:has-role("admin", (), ())) ) then (
                        attribute readonly {"readonly"}
                    ) else ()
                }
            }</dd>
        </dl>
    )
};

declare function checkForDefault($input as element(ldse:input), $value as item()*, $optionalDefault as item()*) as item()* {
    if (fn:exists($value) or fn:exists(getVariable('file'))) then (
        $value
    ) else if (fn:exists($input/ldse:default-value)) then (
        if ($input/ldse:default-value/@type eq 'function') then (
            xdmp:apply(getFunction( xs:string($input/ldse:default-value) ))
        ) else if ($input/ldse:default-value/@type eq 'variable') then (
            if (fn:starts-with($input/ldse:default-value, '$')) then (
                getVariable(fn:substring-after(xs:string($input/ldse:default-value),'$'))
            ) else (
                getVariable(xs:string($input/ldse:default-value))
            )
        ) else (
            $input/ldse:default-value/node()
        )
    ) else (
        $optionalDefault
    )
};

declare function addClass($input as element(ldse:input), $newClass as xs:string) as xs:string {
    if ( fn:contains($input/@class, $newClass) ) then (
        $input/@class
    ) else if ($input/@class eq '') then (
        $newClass
    ) else ( fn:concat($newClass, ' ', $input/@class) )
};

declare function getInputAttributes(
    $input as element(),
    $blockAttrs as xs:string*,
    $index as xs:string?
) as attribute()* {
    for $attr as attribute() in $input/@*
    let $name as xs:string := fn:local-name($attr)
    let $required as xs:boolean := fn:exists(map:get(getVariable('required-fields'), $input/@name))
    where fn:not($name = $blockAttrs)
    return (
        if ( $required and $name = 'class' ) then (
            attribute class { $attr/xs:string(.) || ' required' }
        ) else if ( fn:starts-with($attr, '$') ) then (
            attribute { $name } { getVariable(fn:substring-after($attr,'$')) }
        )
        else if ($index and $name = 'display-dependency') then
                attribute display-dependency {$attr/fn:string()||'-'||$index}
        else if ($index and $name = 'add-required') then
                attribute add-required {$attr/fn:string()||'-'||$index}
            else ( $attr )
    )
};

declare function getTitanInputAttributes(
    $input as element(),
    $blockAttrs as xs:string*,
    $index as xs:string?
) as attribute()* {
    let $attrs as attribute()* := getInputAttributes($input, $blockAttrs, $index)
    let $titan-asset as xs:string := 'titan-asset'
    return
        if(some $attrInSeq in $attrs satisfies (fn:name($attrInSeq) eq "class") ) then (
            let $class as attribute()? := $attrs[fn:name(.) eq "class"]
            return
                if (fn:not(fn:contains($class/fn:string(), $titan-asset)) ) then (
                    ( $attrs[fn:not(fn:name(.) eq "class")], attribute class { fn:string-join( ($class/fn:string(), $titan-asset), " ") } )
                ) else (
                    $attrs
                )
        ) else (
            ( $attrs, attribute class { $titan-asset } )
        )
};

(: END of Input helper Functions :)

declare function buildXhtml(
    $html as element(ldse:xhtml),
    $file as element()?,
    $index as xs:string?
) as element()* {
    for $element as element() in $html/element()
    let $element as element() := util:strip-namespaces($element)
    return
        element {fn:local-name($element)} {
            if (fn:exists($element/@seq)) then
                attribute data-sequence { $element/@seq }
            else (),
            $element/@*[fn:not(fn:local-name(.) eq 'seq')],
            $element/node()
        }
};

declare function buildInput($input as element(ldse:input), $file as element()?, $index as xs:string?) as element()* {
    let $type as xs:string :=
        if ($input/@type eq ('text','number','email','url','search','binary', 'password')) then (
            fn:concat($input/@type, 'Input')
        ) else (xs:string($input/@type))
    let $skipTypes as xs:string* := ('duplicate', 'variable')
    where fn:not($type eq $skipTypes)
    return(
        xdmp:apply(getFunction($type), $input, $file, $index)
    )
};

(: Input Functions :)
declare function inputLabel($input as element(ldse:input), $id as xs:string) as element(dt) {
    inputLabel($input, $id, "0")
};
declare function inputLabel($input as element(ldse:input), $id as xs:string, $index as xs:string?) {
    <dt class="label">
        {theLabel($input, $id, $index)}
    </dt>
};
(: Label for checkboxes :)
declare function inputLabel($input as element(ldse:input), $id as xs:string, $index as xs:string?, $unwrap as xs:string?) {
    <span style="margin-left:10px;">
        {theLabel($input, $id, $index)}
    </span>
};

declare function theLabel($input as element(ldse:input), $id as xs:string, $index as xs:string?) {
    let $index as xs:string := ($index[. ne ""], "0")[1]
    let $form-name as xs:string := ( util:get-root($input)/@name, $input/@name )[1]
    let $template-id as xs:string? := fn:substring-after(fn:tokenize(getVariable('option'), ',')[fn:contains(., 'templateName')], ':')
    return (
        <span>
            <label for="{$id}">
                { ( ice:get-bundle-value($input/@title-resource-key[fn:not(. = "")], "eng")[. != $input/@title-resource-key/xs:string(.)], $input/@title/xs:string(.) )[1] }
            </label>
            {required($input)}
            {ice:inline-help-link($input, $index, $template-id)}
        </span>
    )
};

declare function autocomplete($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $blockAttrs as xs:string* := ('seq', 'name', 'value', 'id', 'options', 'xpath', 'dlClass', 'help')
    let $value as item()* := checkForDefault($input, dynamicXpath($file, xs:string($input/@xpath)), xs:string($input/@value))
    let $data-src-qName as xs:string := $input/@data-qname/xs:string(.)
    let $data-src-values as xs:string* := cts:element-values(xs:QName($data-src-qName), (), 'collation=http://marklogic.com/collation/')
    let $data-src-name as xs:string := fn:concat(fn:replace($id, "([^a-zA-Z])", ""), "_datasrc")

    return
        <dl data-sequence="{xs:string($input/@seq)}" class="{xs:string($input/@dlClass)}">
            <dt>
                <label for="{$id}">{xs:string($input/@title)}</label>{dynamicForms:required($input)}
            </dt>
            <dd>
                {
                    element input
                    {
                        getInputAttributes($input, $blockAttrs, $index),
                        attribute name {$name},
                        attribute value {xdmp:quote($value)},
                        attribute id {$id}
                    }
                }
            </dd>
            <script type="text/javascript">
                var {$data-src-name} = [
                {for $v as xs:string in $data-src-values return fn:concat('"', $v, '"', if ($v eq $data-src-values[fn:last()]) then () else (','))}
                ];
                setTimeout(function() {{ $('{fn:concat("#", $id)}').autocomplete({{source:{$data-src-name}}}); }}, 2000);
            </script>
        </dl>
};

declare function textInput($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $blockAttrs as xs:string* := ('seq', 'name', 'value', 'id', 'options', 'xpath', 'dlClass', 'help')
    let $value as item()* := checkForDefault($input, dynamicXpath($file, xs:string($input/@xpath)), xs:string($input/@value))
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            {inputLabel($input, $id, $index)}
            <dd>{
                element input {
                    getInputAttributes($input, $blockAttrs, $index),
                    attribute name {$name},
                    attribute value {xdmp:quote($value)},
                    attribute id {$id}
                }
            }</dd>
        </dl>
    )
};

declare function hidden($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $blockAttrs as xs:string* := ('seq', 'name', 'value', 'id', 'options', 'xpath', 'dlClass', 'help')
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">{
            element input {
                getInputAttributes($input, $blockAttrs, $index),
                attribute name {$name},
                attribute value {xdmp:quote(dynamicXpath($file, xs:string($input/@xpath)))},
                attribute id {$id}
            }
        }</dl>
    )
};

declare function wysiwyg($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $class as xs:string := addClass($input, 'ckeditor')
    let $value as item()* := dynamicXpath($file, xs:string($input/@xpath))
    let $toolbar as xs:string? := $input/@toolbar
    let $config as xs:string? := $input/@config
    let $blockAttrs as xs:string* := ('seq', 'name', 'value', 'id', 'class', 'options', 'xpath', 'dlClass', 'help', "toolbar", "config")
    let $adjusted-value as item()* := wysiwyg-embedded-links-display($file, $input, $index, $value)
    return (
        <dl data-sequence="{ xs:string($input/@seq) }" data-group="{ $input/@group }" class="{ xs:string($input/@dlClass) }">
            {inputLabel($input, $id, $index)}
            <dd>{
                element textarea {
                    getInputAttributes($input, $blockAttrs, $index),
                    if (fn:exists($toolbar) and $toolbar != "") then attribute data-toolbar {$toolbar} else (),
                    if (fn:exists($config) and $config != "") then attribute data-config {$config} else (),
                    attribute name {$name},
                    attribute id {
                        if ( fn:exists($index[. != '']) ) then (
                            $id || '-' || $index
                        ) else ( $id )
                    },
                    attribute class {$class},
                    if ($adjusted-value) then attribute data-value { xdmp:quote($adjusted-value) } else attribute data-value { xdmp:quote($value) },
                    if ($adjusted-value) then $adjusted-value else $value
                }
            }</dd>
        </dl>
    )
};

declare function ldswebml($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $class as xs:string := addClass($input, 'ckeditor')
    let $value as item()* := dynamicXpath($file, xs:string($input/@xpath))
    let $value as item()* := ice:ldswebmlToWysiwyg($value)
    let $toolbar as xs:string? := $input/@toolbar
    let $config as xs:string? := $input/@config
    let $blockAttrs as xs:string* := ('seq', 'name', 'value', 'id', 'class', 'options', 'xpath', 'dlClass', 'help', "toolbar", "config")
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            {inputLabel($input, $id, $index)}
            <dd>{
                element textarea {
                    getInputAttributes($input, $blockAttrs, $index),
                    attribute name {$name},
                    attribute id {$id},
                    attribute class {$class},
                    if (fn:exists($toolbar) and $toolbar != "") then attribute data-toolbar {$toolbar} else (),
                    if (fn:exists($config) and $config != "") then attribute data-config {$config} else (),
                    $value
                }
            }</dd>
        </dl>
    )
};

declare function datePicker($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $class as xs:string := addClass($input, 'datePicker')
    let $value as xs:string? := dynamicXpath($file, xs:string($input/@xpath))
    let $value as xs:string? := checkForDefault($input, $value, ())
    let $required as xs:string? := map:get(getVariable('required-fields'), $name)

    let $blockAttrs as xs:string* := ('seq', 'name', 'value', 'id', 'class', 'options', 'xpath', 'dlClass', 'help')
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            {inputLabel($input, $id, $index)}
            <dd>
                {
                    element input {
                        getInputAttributes($input, $blockAttrs, $index),
                        attribute name {$name},
                        attribute value {xdmp:quote($value)},
                        attribute class { $class, if ( fn:exists($required[. != '']) ) then ( ' required' ) else () },
                        attribute id {$id},
                        <b class="ldse-icon-calendar" onclick="$('#{$id}').focus();"></b>
                    }
                }</dd>
        </dl>
    )
};

declare function select($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl)* {
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $node as item()* := dynamicXpath($file, xs:string($input/@xpath))
    let $value as xs:string? := dynamicXpath($file, xs:string($input/@xpath))
    let $blockAttrs as xs:string* := ('seq', 'name', 'id', 'options', 'xpath', 'dlClass', 'help')
    let $class := $input/@dlClass
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            {inputLabel($input, $id, $index)}
            <dd>
                {
                    element select {
                        getInputAttributes($input, $blockAttrs, $index),
                        attribute name {$name},
                        attribute id {$id},
                        if ( fn:exists($input/ldse:dynamic-options/@cogito) ) then (
                            get-cogito-dropdown($file, $input, $index, $file)
                        ) else if ( fn:exists($input/ldse:dynamic-options/@root) and fn:not($input/ldse:dynamic-options/@root = "") ) then (
                            buildCustomSelectOptions($input, $file, $value, (), ())
                        ) else if ( fn:exists($input/ldse:dynamic-options)  ) then (
                            xdmp:apply(getFunction($input/ldse:dynamic-options/@function), $value)
                        ) else (
                            for $option as element(ldse:option) in $input/ldse:option
                            return (
                                element option {
                                    $option/@*,
                                    if ($option/@value eq fn:string($value) or $option/@selected ) then (
                                        attribute selected {"selected"}
                                    ) else (),
                                    xs:string($option)
                                }
                            )
                        )
                    }
                }</dd>
        </dl>
    )
};

declare function multi-select($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $value as xs:string* := dynamicXpath($file, xs:string($input/@xpath))
    let $blockAttrs as xs:string* := ('seq', 'name', 'id', 'options', 'xpath', 'dlClass', 'help')
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            {inputLabel($input, $id, $index)}
            <dd>
                {
                    element select {
                        getInputAttributes($input, $blockAttrs, $index),
                        attribute multiple { 'multiple' },
                        attribute name {$name},
                        attribute id {$id},
                        attribute size {(xs:string($input/@size), "4")[1]},
                        if (fn:exists($input/ldse:dynamic-options)) then (
                            xdmp:apply(getFunction($input/ldse:dynamic-options/@function), $value)
                        ) else (
                            for $option as element(ldse:option) in $input/ldse:option
                            return (
                                element option {
                                    $option/@*,
                                    if ($option/@value = xs:string($value) or $option/@selected ) then (
                                        attribute selected {"selected"}
                                    ) else (),
                                    xs:string($option)
                                }
                            )
                        )
                    }
                }</dd>
        </dl>
    )
};

declare function radio($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $value as xs:string? := dynamicXpath($file, xs:string($input/@xpath))
    let $options as element(ldse:option)* :=
        if (fn:exists($input/ldse:radio-options/@function)) then (
            xdmp:apply(getFunction($input/ldse:radio-options/@function), $input, $value)
        ) else ($input/ldse:option)
    let $blockAttrs as xs:string* := ('seq', 'id', 'name', 'value', 'options', 'xpath', 'dlClass', 'help')
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            {inputLabel($input, $id, $index)}
            <dd>
                {
                    for $option as element(ldse:option) at $i in $options
                    let $unique-id as xs:string := if ($i != 1) then (fn:concat($id , $i)) else ($id)
                    return (
                        element input {
                            getInputAttributes($input, $blockAttrs, $index),
                            attribute id {$unique-id},
                            attribute name {$name},
                            $option/@value,
                            if ($option/@value eq $value) then (
                                attribute checked {"checked"}
                            ) else ()
                        },
                        element label {
                            attribute for {$unique-id},
                            xs:string($option)
                        },
                        element br {}
                    )
                }</dd>
        </dl>
    )
};

(: Checkboxes only post if they are checked:)
declare function checkbox($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $values as item()* := checkForDefault($input, dynamicXpath($file, xs:string($input/@xpath)))
    let $values as item()* := get-category-values($values)
    let $value as xs:string* := $values
    let $value-ids as xs:string* := $values[. instance of element()]/@id
    let $options as element()* :=
        if (fn:exists($input/ldse:checkbox-options/@function)) then (
            xdmp:apply(getFunction($input/ldse:checkbox-options/@function), $input, $value)
        ) else if ( fn:exists($input/ldse:option) ) then (
            $input/ldse:option
        ) else (
            <option value="{$input/@value}" checked="{$input/@checked}">{xs:string($input/@title)}</option>
        )
    let $blockAttrs as xs:string* := ('seq', 'id', 'name', 'value', 'options', 'xpath', 'dlClass', 'help', 'checked')
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            <dd>
                {
                    for $option as element() at $i in $options
                    let $unique-id as xs:string := if ($i != 1) then (fn:concat($id , $i)) else ($id)
                    return (
                        element input {
                            if ( fn:local-name($option) = "input" ) then (
                                getInputAttributes($option, $blockAttrs, $index)
                            ) else ( getInputAttributes($input, $blockAttrs, $index) ),
                            attribute id {$unique-id},
                            attribute name {$name},
                            $option/@value,
                            if ($option/@value eq $value or $option/@value = $value-ids or (not(exists($file)) and $option/@checked eq "true")) then (
                                attribute checked {"checked"}
                            ) else (
                            )
                        },
                        inputLabel($input, $id, $index, "true"),
                        element br {}
                    )
                }
            </dd>
        </dl>
    )
};

declare function get-category-values(
    $values as item()*
) as item()* {
    for $value as item() in $values
    return (
        typeswitch ( $value )
        case element() return (
            if ( fn:local-name($value) = "resource-tags" ) then (
                $value,
                $value/sub-tags/sub-tag
            ) else ( $values )
        )
        default return ( $values )
    )
};

declare function textarea($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $value as item()* := dynamicXpath($file, xs:string($input/@xpath))
    let $blockAttrs as xs:string* := ('seq', 'name', 'value', 'id', 'options', 'xpath', 'dlClass', 'help')
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            {inputLabel($input, $id, $index)}
            <dd>{
                element textarea {
                    getInputAttributes($input, $blockAttrs, $index),
                    attribute name {$name},
                    attribute id {$id},
                    $value
                }
            }</dd>
        </dl>
    )
};

declare function supported-languages(
    $input as element(ldse:input),
    $file as element()?,
    $index as xs:string?
) as element(dl)? {

    let $lang as xs:string := (util:escape-chars(xdmp:get-request-field("lang", "eng")),'eng')[1]
    return
        if ($lang eq "eng") then (

            let $site-name as xs:string := sp:get-site-properties(getVariable('currSite'))/@site/fn:string(.)
            let $supportedLanguages as element(supportedLanguages) := cts:search(/supportedLanguages,
                                                                            cts:and-query((
                                                                                core:get-filter-query(),
                                                                                cts:element-attribute-value-query(xs:QName("supportedLanguages"), xs:QName("site"), $site-name, 'exact')
                                                                            ))
                                                                       )
            let $languageMapping as element(languages) := cts:search(/languages,
                                                              cts:and-query((
                                                                  core:get-filter-query(),
                                                                  cts:element-attribute-value-query(xs:QName("languages"), xs:QName("locale"), "none", 'exact')
                                                              ))
                                                          )

            let $supportedLanguages as xs:string* := $supportedLanguages/language/@key/fn:string(.)
            let $name as xs:string := buildInputName($input, $index)
            let $id as xs:string := $name
            let $blockAttrs as xs:string* := ( 'id', 'type', 'name', 'seq', 'value', 'options', 'xpath', 'dlClass', 'help' )
            let $savedLangs as xs:string* := dynamicXpath($file, xs:string($input/@xpath))/fn:string(.)
            return (
                <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group/fn:string(.)}" class="{xs:string($input/@dlClass)}">
                    <dt class="label">
                        <label for="eng">{$input/@title/fn:string(.)}</label>
                    </dt>
                    <dd>
                        {
                            for $lang as xs:string in $supportedLanguages
                            let $englishName as xs:string? := $languageMapping/language[@key eq $lang]/englishName/fn:string(.)
                            order by $lang
                            return (
                                element input {
                                    getInputAttributes($input, $blockAttrs, $index),
                                    attribute type {'checkbox'},
                                    attribute id {$id},
                                    attribute name {$name},
                                    attribute value {$lang},
                                    if ($lang eq $savedLangs) then (attribute checked {'checked'}) else ()
                                },
                                element label {
                                    attribute for {$lang},
                                    if (fn:exists($englishName)) then ($englishName) else ($lang)
                                },
                                element br {}
                            )
                        }
                    </dd>
                </dl>
            )
        )
        else (
            <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group/fn:string(.)}" class="{xs:string($input/@dlClass)}">
                <dt class="label">
                    <label for="eng">{$input/*:nonEngHelpText}</label>
                </dt>
            </dl>
        )

};

declare function processSupportedlanguagesCheckbox($file,$input,$index,$value) {
    for $v in $value
    return <lang>{$v}</lang>
};

declare function image(
    $input as element(ldse:input),
    $file as element()?,
    $index as xs:string?
) as element(dl) {
    let $binaryMangerActive as xs:boolean := getVariable('binaryMangerActive')
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $image as xs:string? := dynamicXpath($file, xs:string($input/@xpath))
    let $blockAttrs as xs:string* := ( 'id', 'type', 'name', 'seq', 'value', 'options', 'xpath', 'dlClass', 'help' )
    let $imagePrevClass as xs:string? := if ( fn:exists($image) ) then () else ( 'hidden' )
    return (
        <dl data-sequence="{ xs:string($input/@seq) }" data-group="{ $input/@group }" class="{ xs:string($input/@dlClass) }">
            {inputLabel($input, $id, $index)}
            <dd>
                <dl class="padding-sm imageWrapper">
                    <div>
                        {
                            if ($binaryMangerActive) then (
                                <a id="{fn:concat($id,'-manage')}" data-image-min-height="{$input/@min-height}" data-image-min-width="{$input/@min-width}" data-image-height="{$input/@forced-height}" data-image-width="{$input/@forced-width}" data-binary-type="image" data-binary-ext="bmp,gif,jpg,jpeg,png,tif,svg" data-binary-input="{fn:concat('#',$id)}" class="ldse-button ldse-responsive-button secondary ldse-icon-search binary-manager ixf-button">Search</a>,
                                <a id="{fn:concat($id,'-manage')}" onclick="clearInputField('{$name}')" class="ldse-button ldse-responsive-button destructive ldse-icon-trash ixf-button">Delete</a>
                            ) else ()
                        }
                    </div>
                    <dt>
                        <label for="{$id}">Path</label>
                    </dt>
                    <dd>{
                        element input {
                            getInputAttributes($input, $blockAttrs, $index),
                            attribute id {$id},
                            attribute name {$name},
                            attribute value {$image},
                            attribute type { 'text' }
                        }
                    }</dd>
                    <dt>Current Image</dt>
                    <dd>
                        <img width="200" id="{fn:concat($id,'-preview')}" src="{ if (fn:contains($image,'http')) then ($image) else (core:get-display-uri($image)) }"/>
                    </dd>
                    { if (fn:not($binaryMangerActive)) then (
                        <dt>
                            <label for="{fn:concat($name, '-upload')}">Upload New</label>
                        </dt>,
                        <dd>
                            <input type="file" id="{fn:concat($id, '-upload')}" name="{fn:concat($name, '-upload')}"/>
                        </dd>
                    ) else () }
                </dl>
            </dd>
        </dl>
    )
};

declare function titanImage(
    $input as element(ldse:input),
    $file as element()?,
    $index as xs:string?
) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $image as xs:string? := dynamicXpath($file, xs:string($input/@xpath))
    let $image-node as element()? := util:unpath($file, util:substring-before-last($input/@xpath, '/'))
    let $blockAttrs as xs:string* := ( 'id', 'type', 'name', 'seq', 'value', 'options', 'xpath', 'dlClass', 'help' )
    let $required as xs:boolean := fn:exists(map:get(getVariable('required-fields'), $input/@name))
    let $input as element(ldse:input) :=
        if ( $required and fn:empty($input/@class) ) then (
            <ldse:input> {
                attribute xmlns { 'http://lds.org/code/lds-edit' },
                $input/@*,
                attribute class {},
                $input/*
            } </ldse:input>
        ) else ( $input )
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            { inputLabel($input, $id, $index) }
            <dd>
                <dl class="padding-sm imageWrapper">
                    <div> {
                        <a id="{ fn:concat($id,'-manage') }" data-type="image" class="ldse-button ldse-responsive-button secondary ldse-icon-search titanFormItem">Search</a>,
                        <a id="{ fn:concat($id,'-manage') }" onclick="clearInputField('{ $name }')" class="ldse-button ldse-responsive-button destructive ldse-icon-trash ixf-button">Delete</a>
                    } </div>
                    <dt>
                        <label for="{ $id }">Titan ID</label>
                    </dt>
                    <dd>{
                        element input {
                            getTitanInputAttributes($input, $blockAttrs, $index),
                            attribute id { $id },
                            attribute name { $name },
                            attribute value { $image-node/xs:string(.) },
                            attribute type { 'text' },
                            attribute data-type { 'image' },
                            attribute onchange { fn:concat('updateTitanPreview("', fn:concat($id, '-titan-image-hidden'), '", "', fn:concat($id, '-preview'), '", this)') }
                        }
                    }</dd>
                    <dd>{
                        element input {
                            attribute id { $id || '-titan-image-hidden' },
                            attribute name { $name },
                            attribute type { 'hidden' },
                            attribute value { $image-node/@thumb/xs:string(.) }
                        }
                    }</dd>
                    <dt>Current Image</dt>
                    <dd>
                        <img style="max-width: 200px" id="{fn:concat($id, '-preview')}" src="{ $image-node/@thumb/xs:string(.) }"/>
                    </dd>
                </dl>
            </dd>
        </dl>
    )
};

declare function titanAudio(
    $input as element(ldse:input),
    $file as element()?,
    $index as xs:string?
) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $audio-node as element()? := util:unpath($file, util:substring-before-last($input/@xpath, '/'))
    let $blockAttrs as xs:string* := ('id', 'type', 'name', 'seq', 'value', 'options', 'xpath', 'dlClass', 'help')
    let $required as xs:boolean := fn:exists(map:get(getVariable('required-fields'), $input/@name))
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            {inputLabel($input, $id, $index)}
            <dd>
                <dl class="padding-sm imageWrapper">
                    <div> {
                        <a id="{ fn:concat($id,'-manage') }" data-type="audio" class="ldse-button ldse-responsive-button secondary ldse-icon-search titanFormItem">Search</a>,
                        <a id="{ fn:concat($id,'-manage') }" onclick="clearInputField('{$name}')" class="ldse-button ldse-responsive-button destructive ldse-icon-trash ixf-button">Delete</a>
                    } </div>
                    <dt>
                        <label for="{ $id }">Titan ID</label>
                    </dt>
                    <dd>{
                        element input {
                            getTitanInputAttributes($input, $blockAttrs, $index),
                            attribute id { $id },
                            attribute name { $name },
                            attribute value { $audio-node/xs:string(.) },
                            attribute type { 'text' },
                            attribute data-type { 'audio' },
                            attribute onchange { fn:concat('updateTitanPreview("', fn:concat($id, '-track-title-hidden'), '", "', fn:concat($id, '-track-title-preview'), '", this)') }
                        }
                    }</dd>
                    <dd>{
                        element input {
                            attribute id { $id || '-track-title-hidden' },
                            attribute name { $name },
                            attribute type { 'hidden' },
                            attribute value { $audio-node/@track-title/xs:string(.) }
                        }
                    }</dd>
                    <dt>Current Audio</dt>
                    <dd>
                        <span id="{ $id || '-track-title-preview' }">{ $audio-node/@track-title/xs:string(.) }</span><br/>
                    </dd>
                </dl>
            </dd>
        </dl>
    )
};

declare function titanAsset(
    $input as element(ldse:input),
    $file as element()?,
    $index as xs:string?
 ) as element(dl) {
     let $name as xs:string := buildInputName($input, $index)
     let $id as xs:string := $name
     let $node as element()? := util:unpath($file, util:substring-before-last($input/@xpath, '/'))
     let $blockAttrs as xs:string* := ('id', 'type', 'name', 'seq', 'value', 'options', 'xpath', 'dlClass', 'help')
     let $required as xs:boolean := fn:exists(map:get(getVariable('required-fields'), $input/@name))
     let $input as element(ldse:input) :=
        if ( $required and fn:empty($input/@class) ) then (
            <ldse:input> {
                attribute xmlns { 'http://lds.org/code/lds-edit' },
                $input/@*,
                attribute class {},
                $input/*
            } </ldse:input>
        ) else ( $input )
     return (
         <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
             {inputLabel($input, $id, $index)}
             <dd>
                 <dl class="padding-sm imageWrapper">
                     <div> {
                         <a id="{ fn:concat($id,'-manage') }" data-type="generic" class="ldse-button ldse-responsive-button secondary ldse-icon-search titanFormItem">Search</a>,
                         <a id="{ fn:concat($id,'-manage') }" onclick="clearInputField('{$name}', this)" class="ldse-button ldse-responsive-button destructive ldse-icon-trash ixf-button">Delete</a>
                     } </div>
                     <dt>
                         <label for="{ $id }">Titan ID</label>
                     </dt>
                     <dd>{
                         element input {
                             getTitanInputAttributes($input, $blockAttrs, $index),
                             attribute id { $id },
                             attribute name { $name },
                             attribute value { $node/xs:string(.) },
                             attribute type { 'text' },
                             attribute data-type-generic {''},
                             attribute data-type { $node/@data-type-generic/xs:string(.) },
                             attribute onchange { fn:concat('updateTitanPreview("', fn:concat($id, '-title-hidden'), '", "', fn:concat($id, '-title-preview'), '", this, "', fn:concat($id, '-type-hidden'), '", "', fn:concat($id, '-thumb-hidden'),'")') }
                         }
                     }</dd>
                     <dd>{
                         element input {
                             attribute id { $id || '-title-hidden' },
                             attribute name { $name },
                             attribute type { 'hidden' },
                             attribute data-type-generic {''},
                             attribute value { $node/@title/xs:string(.) }
                         }
                     }</dd>
                     <dd>{
                         element input {
                             attribute id { $id || '-thumb-hidden' },
                             attribute name { $name },
                             attribute type { 'hidden' },
                             attribute data-type-generic {''},
                             attribute value { $node/@thumb/xs:string(.) }
                         }
                     }</dd>
                     <dd>{
                         element input {
                             attribute id { $id || '-type-hidden' },
                             attribute name { $name },
                             attribute type { 'hidden' },
                             attribute data-type-generic {''},
                             attribute value { $node/@data-type-generic/xs:string(.) }
                         }
                     }</dd>
                     <dt>Current Titan <span data-type-generic="">{xdmp:initcap($node/@data-type-generic/xs:string(.))}</span></dt>
                     <dd>
                         <img width="200" src="{ $node/@thumb/xs:string(.) }"/>
                         <br/>
                         <span id="{ $id || '-title-preview' }">{ $node/@title/xs:string(.) }</span>
                     </dd>
                 </dl>
             </dd>
         </dl>
     )
 };

declare function titanVideo(
    $input as element(ldse:input),
    $file as element()?,
    $index as xs:string?
) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $video as xs:string? := dynamicXpath($file, xs:string($input/@xpath))
    let $video-node as element()? := util:unpath($file, util:substring-before-last($input/@xpath, '/'))
    let $blockAttrs as xs:string* := ('id', 'type', 'name', 'seq', 'value', 'options', 'xpath', 'dlClass', 'help')
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            {inputLabel($input, $id, $index)}
            <dd>
                <dl class="padding-sm imageWrapper">
                    <div> {
                        <a id="{ fn:concat($id,'-manage') }" data-type="video" class="ldse-button ldse-responsive-button secondary ldse-icon-search titanFormItem">Search</a>,
                        <a id="{ fn:concat($id,'-manage') }" onclick="clearInputField('{$name}')" class="ldse-button ldse-responsive-button destructive ldse-icon-trash ixf-button">Delete</a>
                    } </div>
                    <dt>
                        <label for="{ $id }">Titan ID</label>
                    </dt>
                    <dd>{
                        element input {
                            getTitanInputAttributes($input, $blockAttrs, $index),
                            attribute id { $id },
                            attribute name { $name },
                            attribute value { $video },
                            attribute type { 'text' },
                            attribute data-type { 'video' },
                            attribute onchange { fn:concat('updateTitanPreview("', fn:concat($id, '-title-hidden'), '", "', fn:concat($id, '-title-preview'), '", this)') }
                        }
                    }</dd>
                    <dt>Current Video</dt>
                    <dd>{
                        element input {
                            attribute id { $id || '-title-hidden' },
                            attribute name { $name },
                            attribute type { 'hidden' },
                            attribute value { ( $video-node/@title/xs:string(.)[. != ''], ' ' )[1] }
                        }
                    }</dd>
                    <dd>
                        <span id="{ $id || '-title-preview' }">{ ( $video-node/@title/xs:string(.), ' ' )[1] }</span><br/>
                    </dd>
                </dl>
            </dd>
        </dl>
    )
};

declare function titanPdf(
    $input as element(ldse:input),
    $file as element()?,
    $index as xs:string?
) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $pdf as xs:string? := dynamicXpath($file, xs:string($input/@xpath))
    let $pdf-node as element()? := util:unpath($file, util:substring-before-last($input/@xpath, '/'))
    let $blockAttrs as xs:string* := ('id', 'type', 'name', 'seq', 'value', 'options', 'xpath', 'dlClass', 'help')
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            {inputLabel($input, $id, $index)}
            <dd>
                <dl class="padding-sm imageWrapper">
                    <div> {
                        <a id="{ fn:concat($id,'-manage') }" data-type="pdf" class="ldse-button ldse-responsive-button secondary ldse-icon-search titanFormItem">Search</a>,
                        <a id="{ fn:concat($id,'-manage') }" onclick="clearInputField('{$name}')" class="ldse-button ldse-responsive-button destructive ldse-icon-trash ixf-button">Delete</a>
                    } </div>
                    <dt>
                        <label for="{ $id }">Titan ID</label>
                    </dt>
                    <dd>{
                        element input {
                            getTitanInputAttributes($input, $blockAttrs, $index),
                            attribute id { $id },
                            attribute name { $name },
                            attribute value { $pdf },
                            attribute type { 'text' },
                            attribute data-type { 'pdf' },
                            attribute onchange { fn:concat('updateTitanPreview("', fn:concat($id, '-title-hidden'), '", "', fn:concat($id, '-title-preview'), '", this)') }
                        }
                    }</dd>
                    <dt>Current PDF File</dt>
                    <dd>{
                        element input {
                            attribute id { $id || '-title-hidden' },
                            attribute name { $name },
                            attribute type { 'hidden' },
                            attribute value { ( $pdf-node/@title/xs:string(.)[. != ''], ' ' )[1] }
                        }
                    }</dd>
                    <dd>
                        <span id="{ $id || '-title-preview' }">{ ( $pdf-node/@title/xs:string(.), ' ' )[1] }</span><br/>
                    </dd>
                </dl>
            </dd>
        </dl>
    )
};

declare function titanSourceDoc(
    $input as element(ldse:input),
    $file as element()?,
    $index as xs:string?
) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $source-node as element()? := util:unpath($file, util:substring-before-last($input/@xpath, '/'))
    let $blockAttrs as xs:string* := ('id', 'type', 'name', 'seq', 'value', 'options', 'xpath', 'dlClass', 'help')
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            {inputLabel($input, $id, $index)}
            <dd>
                <dl class="padding-sm imageWrapper">
                    <div> {
                        <a id="{ fn:concat($id,'-manage') }" data-type="html5" class="ldse-button ldse-responsive-button secondary ldse-icon-search titanFormItem">Search</a>,
                        <a id="{ fn:concat($id,'-manage') }" onclick="clearInputField('{$name}')" class="ldse-button ldse-responsive-button destructive ldse-icon-trash ixf-button">Delete</a>
                    } </div>
                    <dt>
                        <label for="{ $id || 'uri-hidden' }">LDS Source Document URI</label>
                    </dt>
                    <dd>
                        {
                            element input {
                                attribute id { $id || '-uri-hidden' },
                                attribute name { $name },
                                attribute type { 'text' },
                                attribute value { $source-node/@uri/xs:string(.) }
                            }
                        }
                    </dd>
                    <dt>
                        <label for="{ $id }">Titan ID</label>
                    </dt>
                    <dd>{
                        element input {
                            attribute id { $id || '-lang-hidden' },
                            attribute name { $name },
                            attribute type { 'hidden' },
                            attribute value { $source-node/@lang/xs:string(.) }
                        },
                        element input {
                            getInputAttributes($input, $blockAttrs, $index),
                            attribute id { $id },
                            attribute name { $name },
                            attribute value { $source-node/xs:string(.) },
                            attribute type { 'text' },
                            attribute data-type { 'html5' }
(:                            attribute onchange { fn:concat('updatePreview("', fn:concat($id, '-preview'), '", this)') }:)
                        },
                        element input {
                            attribute id { $id || '-hidden' },
                            attribute name { $name },
                            attribute type { 'hidden' },
                            attribute value { $source-node/@title/xs:string(.) }
                        }
                    }</dd>
                    <dt>Current Item</dt>
                    <dd>
                        <div id="{ $id || '-preview' }">Title: { $source-node/@title/xs:string(.) }</div>
                        <div id="{ $id || '-preview-lang' }">Lang: { $source-node/@lang/xs:string(.) }</div>
                    </dd>
                </dl>
            </dd>
        </dl>
    )
};

declare function titanCollection(
    $input as element(ldse:input),
    $file as element()?,
    $index as xs:string?
) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $coll-node := dynamicXpath($file, xs:string($input/@xpath))
    let $blockAttrs as xs:string* := ('id', 'type', 'name', 'seq', 'value', 'options', 'xpath', 'dlClass', 'help')
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            {inputLabel($input, $id, $index)}
            <dd>
                <dl class="padding-sm imageWrapper">
                    <div> {
                        <a id="{ fn:concat($id,'-manage') }" data-type="collection" class="ldse-button ldse-responsive-button secondary ldse-icon-search titanFormItem">Search</a>,
                        <a id="{ fn:concat($id,'-manage') }" onclick="clearInputField('{$name}')" class="ldse-button ldse-responsive-button destructive ldse-icon-trash ixf-button">Delete</a>
                    } </div>
                    <dt>
                        <label for="{ $id }">Titan ID</label>
                    </dt>
                    <dd>{
                        element input {
                            getInputAttributes($input, $blockAttrs, $index),
                            attribute id { $id },
                            attribute name { $name },
                            attribute value { $coll-node/xs:string(.) },
                            attribute type { 'text' }
                        },
                        element input {
                            attribute id { $id || '-hidden' },
                            attribute name { $name },
                            attribute type { 'hidden' },
                            attribute value { $coll-node/@title/xs:string(.) }
                        }
                    }</dd>
                    <dt>
                        <label for="{ $id }">Collection Path</label>
                    </dt>
                    <dd>{
                        element input {
                            getInputAttributes($input, $blockAttrs, $index),
                            attribute id { $id || '-path' },
                            attribute name { $name || '-path' },
                            attribute value { $coll-node/@path/xs:string(.) },
                            attribute type { 'text' },
                            attribute readonly { 'readonly' }
                        },
                        element input {
                            attribute id { $id || '-hidden' },
                            attribute name { $name },
                            attribute type { 'hidden' },
                            attribute value { $coll-node/@title/xs:string(.) }
                        }
                    }</dd>
                    <dt>Current Image</dt>
                    <dd>
                        <img width="200" id="{fn:concat($id, '-preview')}" src="{ fn:concat($settings:content-api-url, '/id/' , $coll-node/@thumb-id/xs:string(.)) }"/>
                    </dd>
                </dl>
            </dd>
        </dl>
    )
};

declare function pdf($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    let $binaryMangerActive as xs:boolean := getVariable('binaryMangerActive')
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $pdf as xs:string? := dynamicXpath($file, xs:string($input/@xpath))
    let $blockAttrs as xs:string* := ('id', 'type', 'name', 'seq', 'value', 'options', 'xpath', 'dlClass', 'help')
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            {inputLabel($input, $id, $index)}
            <dd>
                <dl class="padding-sm imageWrapper">
                    {
                        if (fn:not($binaryMangerActive)) then (
                            <dt>
                                <label for="{fn:concat($name, '-upload')}">Upload New</label>
                            </dt>,
                            <dd>
                                <input type="file" id="{fn:concat($id, '-upload')}" name="{fn:concat($name, '-upload')}"/>
                            </dd>
                        ) else ()
                    }
                    <dt>
                        <label for="{$id}">Path</label>
                    </dt>
                    <dd>{
                        element input {
                            getInputAttributes($input, $blockAttrs, $index),
                            attribute id {$id},
                            attribute name {$name},
                            attribute value {$pdf},
                            attribute type {'text'}
                        },
                        if ($binaryMangerActive) then (
                            <a type="button" id="{fn:concat($id,'-manage')}" data-binary-type="other" data-binary-ext="pdf" data-binary-input="{fn:concat('#',$id)}" class="ldse-button secondary ldse-icon-search binary-manager ixf-button" value="Pdf Search"/>
                        ) else ()
                    }</dd>
                </dl>
            </dd>
        </dl>
    )
};

declare function binaryInput($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $path as xs:string? := dynamicXpath($file, xs:string($input/@xpath))
    let $type as xs:string := if ( fn:exists($input/@data-binary-type) ) then ( $input/@data-binary-type ) else ('other')
    let $exts as xs:string* :=
        if ( fn:exists($input/@data-binary-ext) ) then (
            $input/@data-binary-ext
        ) else (
            for $ext as element() in $settings:binary-manager-extensions
            return xs:string($ext)
        )
    let $blockAttrs as xs:string* := ('id', 'type', 'name', 'seq', 'value', 'options', 'xpath', 'dlClass', 'help', 'data-binary-type', 'data-binary-ext', 'data-binary-input')
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{fn:concat(xs:string($input/@dlClass))}">
            {inputLabel($input, $id, $index)}
            <dd>
                <dl class="padding-sm imageWrapper">
                    <a type="button" id="{fn:concat($id,'-manage')}" data-binary-type="{ $type }" data-binary-ext="{ fn:string-join($exts, ',')}" data-binary-input="{fn:concat('#',$id)}" class="ldse-button secondary ldse-icon-search binary-manager ixf-button">Search</a>
                    <dd>{
                        element input {
                            getInputAttributes($input, $blockAttrs, $index),
                            attribute id {$id},
                            attribute name {$name},
                            attribute value {$path},
                            attribute type {'text'}
                        }
                    }</dd>
                    <dt>Current Image</dt>
                    <dd>
                        <img width="200" id="{fn:concat($id,'-preview')}" src="{ if (fn:contains($path,'http')) then ($path) else (core:get-display-uri($path)) }"/>
                    </dd>
                </dl>
            </dd>
        </dl>
    )
};

declare function get-id($file as element()?, $form as element(ldse:formTemplate)?) as xs:string? {
    if ( $form/ldse:id-xpath ) then (
        dynamicXpath($file, $form/ldse:id-xpath/xs:string(.))
    ) else (
        (: OLD NASTY :)
        let $idNode as element()? := ($form/ldse:structure//ldse:input[@value eq '$id'])[1]/..
        let $idIsAttribute as xs:boolean := $idNode instance of element(ldse:attribute)
        let $idAttrQName as xs:QName? :=  if ($idIsAttribute) then xs:QName(xs:string($idNode/@name)) else ()
        let $idElementQName as xs:QName? := xs:QName(fn:node-name($idNode/(if ($idIsAttribute) then .. else .)))
        let $id as xs:string? := xs:string($file/descendant-or-self::*[fn:node-name(.) eq $idElementQName]/(if ($idIsAttribute) then @*[fn:node-name(.) eq $idAttrQName] else .))
        return (
            $id
        )
    )
};

declare function get-title($file as element()?, $form as element(ldse:formTemplate)?) as xs:string? {
    if ( fn:exists($form/ldse:document-title) ) then (
        dynamicXpath($file, $form/ldse:document-title/xs:string(.))
    ) else if (fn:exists($form/ldse:title-xpath)) then (
        dynamicXpath($file, $form/ldse:title-xpath/xs:string(.))
    ) else (
        (: OLD NASTY :)
        let $titleNode as element()* := ($form/ldse:structure//ldse:input[@name eq 'title' and @type ne 'duplicate'])[1]/..
        let $titleIsAttribute as xs:boolean := $titleNode instance of element(ldse:attribute)
        let $titleAttrQName as xs:QName? :=  if ($titleIsAttribute) then xs:QName(xs:string($titleNode/@name)) else ()
        let $titleElementQName as xs:QName? := fn:QName("http://lds.org/code/lds-edit", fn:local-name($titleNode/(if ($titleIsAttribute) then .. else .)))
        let $titlePosition as xs:integer* := ($form/ldse:structure//*[fn:node-name(.) eq $titleElementQName])/(if (. is $titleNode or . is $titleNode/..) then fn:position() else ())
        let $title as xs:string? := xs:string(($file//*[fn:local-name(.) eq fn:string($titleElementQName)])[$titlePosition]/(if ($titleIsAttribute) then @*[fn:node-name(.) eq $titleAttrQName] else .))
        return (
            $title
        )
    )
};


declare function get-uri($file as element()?) as xs:string? {
   let $uri := if ($file) then
                  $file/@uri/fn:string()
               else ()
   return $uri
};

declare function multipleExternalForm(
    $input as element(ldse:input),
    $file as element()?,
    $index as xs:string?
) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $value as item()* := dynamicXpath($file, xs:string($input/@xpath))
    let $value-exists as xs:boolean := fn:exists($value) and $value ne ""
    let $formName as xs:string* := fn:tokenize($input/@formName, ',')
    let $external-form as element(ldse:formTemplate)* :=
        cts:search(/ldse:formTemplate,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName("ldse:formTemplate"), xs:QName("name"), $formName, 'exact')
            ))
        )[1]
    let $the-existing := $file
    let $file-form as xs:string? := $the-existing/ldse:ldse-meta/ldse:form-options/ldse:form
    let $formQuery as element(query) :=
        element query {
            $external-form/ldse:root-query/*
        }
    let $replace-path as xs:string? := xs:string($input/@replace-xpath)
    let $formQuery as element(query)? :=
        if ($value-exists) then (
            if ($replace-path ne "") then (
                mem:node-replace(dynamicXpath($formQuery, $replace-path), element cts:text{$value})
            ) else ( mem:node-replace($formQuery//cts:text[. eq '$id'], element cts:text{$value}) )
        ) else ()
    let $file as element()? :=
        if ( $value-exists ) then (
            cts:search(/*,
                cts:and-query((
                    core:get-filter-query(),
                    buildQuery($formQuery/*)
                ))
            )[1]
        ) else ()
    let $file as element()? :=
        if ( fn:empty($file) ) then (
            ldsemeta:get-file-by($the-existing, (), (), ())
        ) else ( $file )
    let $formName := $file//ldse:form[1]
    let $external-form :=
        if ( $external-form/@name = $formName or fn:empty($formName) ) then (
            $external-form
        ) else ( get-form($formName) )
    let $id as xs:string* := get-id($file, $external-form)
    let $title as xs:string* := get-title($file, $external-form)
    let $options as item()* := ldsemeta:get-form-options($file)/(@*|node())
    let $options as item()* :=
        if ( fn:exists($options[self::form]) ) then (
            $options
        ) else (
            <form>{xs:string($input/@formName)}</form>,
            $options
        )
    return (generateExternalFormOutput($file, $external-form, $input, $index, $name, $value, $id, $title, $options))[1]
};

declare function get-thumbnail($file as element()?, $form as element(ldse:formTemplate)?) as xs:string? {
    if (fn:exists($form/ldse:image-xpath) and fn:not($form/ldse:image-xpath = "")) then (
        core:get-display-uri(dynamicXpath($file, $form/ldse:image-xpath/xs:string(.)))
    ) else (
        (: OLD NASTY :)
        let $hasThumbnail as xs:boolean := fn:exists($form/ldse:structure//(ldse:image-thumbnail|ldse:images/ldse:small|ldse:image-path))
        let $thumbnail as xs:string? := core:get-display-uri(xs:string(($file//(image-thumbnail|images/small))[1]))
        return (
            $thumbnail
        )
    )
};

declare function externalDynamicForm($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $externalFormData :=
        if ( $file ) then (
            cts:search(fn:collection(),
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("id"), ( $file/text() ),'exact')
                ))
            )[1]
        ) else()

    let $externalFormName :=
        if ( $externalFormData ) then(
            $externalFormData//ldse:ldse-meta/ldse:form-options/ldse:form/xs:string(.)
        ) else ()
    let $options as item()* := ldsemeta:get-form-options($file)/(@*|node())
    let $options as item()* :=
        if ( fn:exists($options[self::form]) ) then (
            $options
        ) else (
            <form>{$externalFormName}</form>,
            $options
        )
    return (
        if ( $externalFormName ) then (
            let $external-form as element(ldse:formTemplate) :=
                cts:search(/ldse:formTemplate,
                    cts:and-query((
                        core:get-filter-query(),
                        cts:element-attribute-value-query(xs:QName("ldse:formTemplate"), xs:QName("name"), ($externalFormName), 'exact')
                    ))
                )

            let $formTitle as xs:string* := $external-form//ldse:title
            let $title as xs:string? := $externalFormData//ldse:document/@title[1]/xs:string(.)

            let $id as item()* := dynamicXpath($file, xs:string($input/@xpath))
            let $blockAttrs as xs:string* := ('name','id', 'title', 'formName')
            let $dynamicInput as element(ldse:input) :=
                element ldse:input {
                    getInputAttributes($input, $blockAttrs, $index),
                    attribute name {$input/@name},
                    attribute id {$id},
                    attribute title {$formTitle[1]},
                    attribute formName {$externalFormName}
                }
            return (
                generateExternalFormOutput($file, $external-form, $dynamicInput, $index, $name, $id, $id, $title, $options)
            )
        ) else (
            externalForm($input, $file, $index)
        )
    )
};

declare function externalForm($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $value as item()* := dynamicXpath($file, xs:string($input/@xpath))
    let $value-exists as xs:boolean := fn:exists($value) and $value ne ""

    let $external-form as element(ldse:formTemplate) :=
        cts:search(/ldse:formTemplate,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName("ldse:formTemplate"), xs:QName("name"), ($input/@formName), 'exact')
            ))
        )
    let $the-existing := $file
    let $formQuery as element(query) :=
        element query {
            $external-form/ldse:root-query/*
        }
    let $replace-path as xs:string? := xs:string($input/@replace-xpath)
    let $formQuery as element(query)? :=
        if ($value-exists) then (
            if ($replace-path ne "") then (
                mem:node-replace(dynamicXpath($formQuery, $replace-path), element cts:text{$value})
            ) else ( mem:node-replace($formQuery//cts:text[. eq '$id'], element cts:text{$value}) )
        ) else ()
    let $file as element()? :=
        if ($value-exists) then (
            cts:search(/*,
                cts:and-query((
                    core:get-filter-query(),
                    buildQuery($formQuery/*)
                ))
            )[1]
        ) else ()
    let $file as element()? :=
        if ( fn:empty($file) ) then (
            ldsemeta:get-file-by($the-existing, (), (), ())
        ) else ( $file )
    let $formName := $file//ldse:form[1]
    let $external-form :=
        if ( $external-form/@name = $formName or fn:empty($formName) ) then (
            $external-form
        ) else ( get-form($formName) )
    let $id as xs:string? := get-id($file, $external-form)
    let $title as xs:string? := get-title($file, $external-form)
    let $options as item()* := ldsemeta:get-form-options($file)/(@*|node())
    let $options as item()* :=
        if ( fn:exists($options[self::form]) ) then (
            $options
        ) else (
            <form>{xs:string($input/@formName)}</form>,
            $options
        )
    return generateExternalFormOutput($file, $external-form, $input, $index, $name, $value, $id, $title, $options)
};

declare function titan-item(
    $input as element(ldse:input),
    $file as element()?,
    $index as xs:string?
) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $value as item()* := dynamicXpath($file, xs:string($input/@xpath))
    let $value-exists as xs:boolean := fn:exists($value) and $value ne ""
    let $xpath as xs:string := $input/@xpath/xs:string(.)
    return (
        <dl></dl>
    )
};

declare function generateExternalFormOutput($file as element()?,$external-form as element(ldse:formTemplate),$input as element(ldse:input),$index as xs:string?,$name as xs:string,$value as item()*, $id as xs:string?,$title as xs:string?,$options as item()* ){
    let $options as item()* :=
        if ( fn:exists($options) and fn:exists(getVariable('currSite')[. != '']) ) then (
            $options, <site-context>{ getVariable('currSite') }</site-context>
        ) else ( $options )
    let $blockAttrs as xs:string* := ('type','seq', 'name', 'value', 'id', 'class', 'options', 'xpath', 'dlClass', 'formName', 'help')
    let $chars as xs:string* := functx:chars(( $title[. != ''], $file/@id/xs:string(.) )[1])
    let $dots as xs:string? := if ( fn:count($chars) > 90 ) then ( '...' ) else ()
    return
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            <dt>{inputLabel($input, $id, $index)}</dt>
            <dd>{
                element input {
                    getInputAttributes($input, $blockAttrs, $index),
                    attribute type {"hidden"},
                    attribute name {$name},
                    attribute id {$id},
                    attribute value {$value}
                },
                element h3 {
                    element a {
                        attribute href {'#d'},
                        attribute data-id {$value},
                        attribute data-form {$external-form/@name/xs:string(.)},
                        attribute data-options {ice:csv-variables(<variables>{$options}</variables>)},
                        attribute class {'editFormItem'},
                        fn:string-join($chars[1 to 90], '') || $dots
                    }
                }
            }</dd>
        </dl>

};

declare function get-inputs(
    $minimum as xs:int?,
    $dynamicXml as element(ldse:dynamic-xml),
    $file as element()?,
    $name as xs:string,
    $inner-hash as xs:string,
    $new as xs:boolean,
    $hash as xs:unsignedInt?,
    $input-type as xs:string?
) as element(li)* {
    for $i as xs:int in 1 to $minimum
    let $hash := ( $hash, $i )[1]
    let $buttons := (
        <input type="hidden" name="{fn:concat($name, '-child')}" class="child" value="{ $hash }"/>,
        <button title="add above" class="sprite ldse-dynamic-icon-addToList top addListItem" type="button"></button>,
        <button title="remove" class="sprite ldse-dynamic-icon-trash deleteListItem" type="button"></button>,
        <button title="add below" class="sprite ldse-dynamic-icon-addToList bottom addListItem" type="button"></button>
    )
    return (
        element li {
            attribute class { "repeated-item" },
            if ( fn:exists($dynamicXml/@item-style) ) then (
                attribute style { $dynamicXml/@item-style }
            ) else (),
            <dl>{
                if ($dynamicXml/@collapsible = "true") then (
                    <header class="dynamic-xml-header">
                        <a href="#d" class="{ if ( $dynamicXml/@collapsed = "true" and fn:not($new) ) then ( 'ldse-icon-rev-tri-right dynamic-xml-toggle closed' ) else ('ldse-icon-rev-tri-down dynamic-xml-toggle')}"></a>
                        {
                            $buttons
                        }
                    </header>
                ) else (
                    $buttons
                )
            }</dl>,
            <fieldset class="table">{
                for $node as element() in buildForm($dynamicXml/element(), $file, fn:concat($inner-hash, $hash), (), $input-type)
                order by fn:number($node/@data-sequence)
                return ($node)
            }</fieldset>
        }
    )
};

declare function buildDynamicInputs($dynamicXml as element(ldse:dynamic-xml), $file as element()?, $index as xs:string?) as element(dl) {

    let $name as xs:string := if (fn:exists($dynamicXml/@name)) then (xs:string($dynamicXml/@name)) else (util:sanitize-uri($dynamicXml/@title))
    let $name as xs:string := if (fn:exists($index)) then (fn:concat($name, '-', $index)) else ($name)
    let $input-types as xs:string* := fn:tokenize($dynamicXml/@content-types, ',')
    let $hash as xs:unsignedInt := xdmp:hash32( $name )
    let $inner-hash as xs:string := if ( fn:exists($index) ) then ( fn:concat($index, '-') ) else ( "" )
    let $addInput as element(li) := get-inputs(1, $dynamicXml, (), $name, $inner-hash, fn:true(), $hash, ())
    let $nodes as element()* :=
        if ( fn:exists($input-types) ) then (
            dynamicXpath($file, xs:string($dynamicXml/@xpath))
        ) else ( dynamicXpath($file, xs:string($dynamicXml/@xpath)) )

    let $blockAttrs as xs:string* := ('seq', 'name', 'title', 'options', 'xpath', 'dlClass', 'help', 'item-style', 'add-label')
    let $minimum as xs:int? := $dynamicXml/@data-min
    let $count as xs:string :=  if (fn:exists($nodes)) then (xs:string(fn:count($nodes))) else ( (xs:string($minimum), '0' )[1] )
    let $blank-inputs as element(li)* := get-inputs($minimum, $dynamicXml, (), $name, $inner-hash, fn:false(), (), ())
    let $siteCreationTitles := ("other-links","endpoints","transform-apis","templates","experiences","meta-tags","comeuntochrist-site-features")

    return (
        <dl data-sequence="{xs:string($dynamicXml/@seq)}" data-group="{$dynamicXml/@group}" class="{if(exists(index-of($siteCreationTitles, $name)))then() else("ldse-group ldse-section")} {xs:string($dynamicXml/@dlClass)}" allowed="{$dynamicXml/@allowed}">
            <dt class="{if(exists(index-of($siteCreationTitles, $name)))then() else("ldse-section--header")}">
                {
                    if (exists(index-of($siteCreationTitles, $name)))
                    then ()
                    else
                        <h3 class="ldse-icon-ko-tri-down ldse-group-header"><b>{xs:string($dynamicXml/@title)}</b></h3>
                }
            </dt>
            <dd class="ldse-section--body">
                {
                    element ul {
                        getInputAttributes($dynamicXml, $blockAttrs, $index),
                        for $node as element() at $i in $nodes
                        let $input-type as xs:string? := $node/element()/fn:local-name(.)[. = $input-types]
                        let $test := get-inputs(1, $dynamicXml, $node, $name, $inner-hash, fn:false(), $i, $input-type)
                        return (
                            $test
                        ),
                        if (fn:empty($nodes) and fn:not($dynamicXml/@empty-child = "false")) then ($blank-inputs) else ()
                    },
                    if ( fn:exists($input-types) ) then (
                        <select class="ldse-dynamic-input-types">{
                            for $type in $input-types
                            return (
                                <option value="{ $type }">{ $type }</option>
                            )
                        }</select>
                    ) else (),
                    <div class="addToContainer">
                        <a title="Add Item to List" class="sprite ldse-dynamic-icon-addToList ldse-add prefix addListItem center" data-item="{ xdmp:quote($addInput) }" data-hash="{$hash}" data-childCount="{$count}">
                            {
                                for $input-type as xs:string in $input-types
                                return (
                                    attribute { 'data-' || $input-type } { xdmp:quote(get-inputs(1, $dynamicXml, (), $name, $inner-hash, fn:true(), $hash, $input-type)) }
                                )
                            }
                        </a>
                    </div>
                }
            </dd>
        </dl>
    )
};

declare function buildDynamicFormRefs($dynamicXml as element(ldse:dynamic-form-ref), $file as element()?, $index as xs:string?) as element(dl) {

    let $name as xs:string := if (fn:exists($dynamicXml/@name)) then (xs:string($dynamicXml/@name)) else (util:sanitize-uri($dynamicXml/@title))
    let $name as xs:string := if (fn:exists($index)) then (fn:concat($name, '-', $index)) else ($name)
    let $addInput as element(li) :=
        element li {
            attribute class { "repeated-item" },
            <dl>
                <span class="correlation-not-approved-new warning float-left" style="display:none;">
                    <span class="ldse-icon-ko-warning ldse-icon ldse-info-banner-icon">Warning</span>
                    <label>Cor-IP / Cor-Eval not approved for publishing</label>
                </span>
                <a href="#d" class="sprite delete ldse-icon-ko-remove bottom float-right deleteListItem"></a>
                <input type="hidden" name="{fn:concat($name, '-child')}" class="child" value="INDEXHERE"/>
            </dl>,
            <div class="correlation-not-approved-new" style="display:none;">&nbsp;</div>,
            <fieldset class="table">{
                for $node as element() in buildForm($dynamicXml/element(), (), 'INDEXHERE')
                order by fn:number($node/@data-sequence)
                return ($node)
            }</fieldset>
        }
    let $nodes as element()* := dynamicXpath($file, xs:string($dynamicXml/@xpath))
    let $count as xs:integer :=  if (fn:exists($nodes)) then (fn:count($nodes)) else (1)
    let $hide-buttons as xs:boolean := $dynamicXml/@only-one = 'true' and fn:exists($nodes)
    let $blockAttrs as xs:string* := ('seq', 'name', 'title', 'options', 'xpath', 'dlClass','formName','add', 'help')
    let $template-id as xs:string? := fn:substring-after(fn:tokenize(getVariable('option'), ',')[fn:contains(., 'templateName')], ':')
    let $site := ($file/ldse:ldse-meta/ldse:form-options/ldse:site/fn:string(), $file/ldse:ldse-meta/ldse:form-options/ldse:site-context/fn:string())[1]
    let $suppress-reference as xs:string? := if ($template-id) then
                                                cf:getTemplateById($template-id)/@suppress-reference
                                             else
                                                let $_template-id := fn:string(get-custom-page(fn:string($file/ldse:ldse-meta/ldse:document/@uri),
                                                                                               fn:string($file/ldse:ldse-meta/ldse:document/@locale),
                                                                                               $site)/ldse:ldse-meta/ldse:form-options/ldse:templateId)
                                                return if ($_template-id) then cf:getTemplateById($_template-id)/@suppress-reference else ()
    return (
        <dl data-sequence="{xs:string($dynamicXml/@seq)}" data-group="{$dynamicXml/@group}" class="{xs:string($dynamicXml/@dlClass)}">
            <dt>
                <label>{xs:string($dynamicXml/@title)}</label>
            </dt>
            <dd style="margin-left:3em;">
                {
                    element ul {
                        getInputAttributes($dynamicXml, $blockAttrs, $index),
                        for $node as element() at $index in $nodes
                        let $id as xs:string := xs:string($node)
                        let $file as element()? := ldsemeta:get-file-by($id, (), (), ())
                        let $can-publish as xs:boolean :=
                            if ( fn:exists($file) ) then (
                                ldsemeta:correlation-can-publish($file)
                            ) else ( fn:false() )
                        let $show-it as xs:string? :=
                            if ( $can-publish ) then (
                                "display:none;"
                            ) else ()
                        where fn:exists($file)
                        return (
                            element li {
                                attribute class { "repeated-item" },
                                <dl>
                                    <span class="correlation-not-approved warning float-left" style="{$show-it}">
                                        <span>
                                            <span class="ldse-icon-ko-warning ldse-icon ldse-info-banner-icon">Warning</span>
                                            <label>Cor-IP / Cor-Eval not approved for publishing</label>
                                        </span>
                                    </span>
                                    <a href="#d" class="sprite delete ldse-icon-ko-remove bottom float-right deleteListItem"></a>
                                    <input type="hidden" name="{fn:concat($name, '-child')}" class="child" value="{$index}"/>
                                </dl>,
                                <div class="correlation-not-approved" style="{$show-it}">&nbsp;</div>,
                                <div>Type: { $file/ldse:ldse-meta/ldse:form-options/ldse:form/xs:string(.) }</div>,
                                <fieldset class="table">{
                                    for $node as element() in buildForm($dynamicXml/element(), $node, xs:string($index))
                                    order by fn:number($node/@data-sequence)
                                    return ($node)
                                }</fieldset>
                            }
                        ),
                        if (fn:empty($nodes)) then (element li {}) else ()
                    },
                    if ( $dynamicXml/@dynamic-form-names ) then (
                        <div class="dynamicForms" style="margin-bottom: 5px; { if ( $dynamicXml/@only-one = 'true' and fn:exists($nodes) ) then ( 'display:none;' ) else () }">
                            <label>Select Form Type</label>
                            <select class="dynamicFormsSelect">
                                {

                                    let $formNames := fn:tokenize($dynamicXml/@dynamic-form-names,',')
                                    let $options := if($dynamicXml/@dynamic-form-names eq "mo-components") then (
                                            <option value="">Please Select</option>,
                                            let $components := moc:get-mormon-org-components()
                                            for $component in $components
                                            return
                                                <option value="{$component/fn:node-name()}">{$component/fn:string()}</option>
                                        )
                                        else if ($dynamicXml/@dynamic-form-names eq "mo-footer-selector") then (
                                            <option value="">Please Select</option>,
                                            <option value="mo-dynamic-i18n-selector">Dynamic I18n Selector</option>
                                        )
                                        else if ($dynamicXml/@dynamic-form-names eq "mp-components") then (
                                            <option value="">Please Select</option>,
                                            let $components := mpc:get-missionary-portal-components()
                                            for $component in $components
                                            return
                                                <option value="{$component/fn:node-name()}">{$component/fn:string()}</option>
                                        )
                                        else if ($dynamicXml/@dynamic-form-names eq "mo-form-components") then (
                                            <option value="">Please Select</option>,
                                            let $components := mofc:get-mormon-org-form-components()
                                            for $component in $components
                                            return
                                                <option value="{$component/fn:node-name()}">{$component/fn:string()}</option>
                                        )
                                        else if ($dynamicXml/@dynamic-form-names eq "mo-stepped-form-components") then (
                                            <option value="">Please Select</option>,
                                            let $components := mosfc:get-mormon-org-stepped-form-components()
                                            for $component in $components
                                            return
                                                <option value="{$component/fn:node-name()}">{$component/fn:string()}</option>
                                        )
                                        else if ($dynamicXml/@dynamic-form-names eq "mo-emphasized-components") then (
                                            <option value="">Please Select</option>,
                                            <option value="mo-card-tile">Card Tile</option>,
                                            <option value="mo-default-media-tile">Default Media Tile</option>,
                                            <option value="mo-uber-tile">Uber Tile</option>
                                        )
                                        else if ($dynamicXml/@dynamic-form-names eq "mo-sign-up-components") then (
                                            <option value="">Please Select</option>,
                                            <option value="mo-newsletter">Newsletter</option>,
                                            <option value="mo-simple-sign-up">Simple Sign Up</option>
                                        )
                                        else if ($dynamicXml/@dynamic-form-names eq "mo-media-block-components") then (
                                            <option value="">Please Select</option>,
                                            <option value="mo-action-bar">Action Bar</option>
                                        )
                                        else if ($dynamicXml/@dynamic-form-names eq "mo-inline-component-gallery-components") then (
                                            <option value="">Please Select</option>,
                                            <option value="mo-media-block">Media Block</option>,
                                            <option value="mo-content-block">Content Block</option>,
                                            <option value="mo-heading">Heading</option>,
                                            <option value="mo-button">Button</option>,
                                            <option value="mo-spot-illustration">Spot Illustration</option>,
                                            <option value="mo-action-bar">Action Bar</option>
                                        )
                                         else if ($dynamicXml/@dynamic-form-names eq "mo-drawer-modal-components") then (
                                            <option value="">Please Select</option>,
                                            <option value="mo-block-quote">Block Quote</option>,
                                            <option value="mo-button">Button</option>,
                                            <option value="mo-content-block">Text Block</option>,
                                            <option value="mo-digit">Digit</option>,
                                            <option value="mo-enhanced-ui-slider">Enhanced UI Slider</option>,
                                            <option value="mo-heading">Heading</option>,
                                            <option value="mo-horizontal-rule">Horizontal Rule</option>,
                                            <option value="mo-horizontal-tile">Horizontal Tile</option>,
                                            <option value="mo-media-block">Media Block</option>,
                                            <option value="mo-meetinghouse-cta">Meetinghouse CTA</option>,
                                            <option value="mo-prebuilt-form">Prebuilt Form</option>,
                                            <option value="mo-pull-quote">Pull Quote</option>,
                                            <option value="mo-simple-sign-up">Simple Sign Up</option>,
                                            <option value="mo-social-block">Social Block</option>,
                                            <option value="mo-spot-illustration">Spot Illustration</option>,
                                            <option value="mo-stepped-form">Stepped Form</option>,
                                            <option value="mo-text-link-list">Text Link List</option>
                                        ) else if ($dynamicXml/@dynamic-form-names eq "mo-flip-card-components") then (
                                            <option value="mo-flip-card-individual">Individual Flip Card</option>
                                        )
                                        else if ($dynamicXml/@dynamic-form-names eq "mo-confirmation-components") then (
                                            <option value="">Please Select</option>,
                                            <option value="mo-block-quote">Block Quote</option>,
                                            <option value="mo-button">Button</option>,
                                            <option value="mo-content-block">Content Block</option>,
                                            <option value="mo-horizontal-rule">Horizontal Rule</option>,
                                            <option value="mo-horizontal-tile">Horizontal Tiles</option>,
                                            <option value="mo-media-block">Media Block</option>,
                                            <option value="mo-spot-illustration">Spot Illustration</option>,
                                            <option value="mo-heading">Text Heading</option>,
                                            <option value="mo-enhanced-ui-slider">Enhanced Ui Slider</option>
                                        )
                                        else (
                                            <option value="">Please Select</option>,
                                            for $formName in $formNames
                                                return
                                                    <option value="{$formName}">{fn:replace($formName,'-', ' ')}</option>
                                        )
                                        return $options
                                }
                            </select>
                        </div>
                    ) else (),
                    if ( xs:string($dynamicXml/@upload) eq "false" ) then (
                        <a href="#d" class="ldse-button secondary prefix ldse-icon-ko-add addFormItem hidden" style="{ if ( $hide-buttons or ( fn:exists($nodes) and $count >= $dynamicXml/@data-max )) then ( 'display:none;' ) else () }" data-item="{ xdmp:quote($addInput) }" data-form="{ xs:string($dynamicXml/@formName) }" data-childCount="{ $count }">Create New</a>
                    ) else (
                        <a href="#d" class="ldse-button secondary prefix ldse-icon-ko-add addFormItem" style="{ if ( $hide-buttons or ( fn:exists($nodes) and $count >= $dynamicXml/@data-max )) then ( 'display:none;' ) else () }" data-item="{xdmp:quote($addInput)}" data-form="{ xs:string($dynamicXml/@formName) }" data-childCount="{ $count }">{ $dynamicXml/@data-max }Create New</a>
                    ),
                    if ($suppress-reference eq 'true' or fn:empty($file)) then (
                        () )
                    else (
                        <a href="#d" class="ldse-button secondary ldse-icon-search prefix searchFormItem add-existing-button" style="{ if ( $hide-buttons or ( fn:exists($nodes) and $count >= $dynamicXml/@data-max )) then ( 'display:none;' ) else () }" data-form="{ xs:string($dynamicXml/@formName) }" data-file-id="{ $file/@id/xs:string(.) }">{
                            $dynamicXml/@data-max,
                            'Add Existing'
                        }</a> ),
                    <a href="#d" class="ldse-button secondary ldse-icon-search prefix searchFormItem add-existing-button clone-requested" style="{ if ( $hide-buttons or ( fn:exists($nodes) and $count >= $dynamicXml/@data-max )) then ( 'display:none;' ) else () }" data-form="{ xs:string($dynamicXml/@formName) }" data-file-id="{ $file/@id/xs:string(.) }">{
                        $dynamicXml/@data-max,
                        'Clone Existing'
                    }</a>
                }
            </dd>
        </dl>
    )
};

declare function buildDynamicTitanItems(
    $dynamicXml as element(ldse:dynamic-titan-item-refs),
    $file as element()?,
    $index as xs:string?
) as element(dl) {
    let $name as xs:string := if ( fn:exists($dynamicXml/@name) ) then ( $dynamicXml/@name ) else ( util:sanitize-uri($dynamicXml/@title) )
    let $name as xs:string := if ( fn:exists($index) ) then ( fn:concat($name, '-', $index) ) else ( $name )
    let $addInput as element(li) :=
        element li {
            attribute class { "repeated-item" },
            <dl>
                <span class="correlation-not-approved-new warning float-left" style="display:none;">
                    <span class="ldse-icon-ko-warning ldse-icon ldse-info-banner-icon">Warning</span>
                    <label>Cor-IP / Cor-Eval not approved for publishing</label>
                </span>
                <a href="#d" class="sprite delete ldse-icon-ko-remove bottom float-right deleteListItem"></a>
                <input type="hidden" name="{fn:concat($name, '-child')}" class="child" value="INDEXHERE"/>
            </dl>,
            <div class="correlation-not-approved-new" style="display:none;">&nbsp;</div>,
            <fieldset class="table">{
                for $node as element() in buildForm($dynamicXml/element(), (), 'INDEXHERE')
                order by fn:number($node/@data-sequence)
                return ($node)
            }</fieldset>
        }
    let $nodes as element()* := dynamicXpath($file, $dynamicXml/@xpath)
    let $count as xs:integer :=  if ( fn:exists($nodes) ) then ( fn:count($nodes) ) else ( 1 )
    let $hide-buttons as xs:boolean := $dynamicXml/@only-one = 'true' and fn:exists($nodes)
    let $blockAttrs as xs:string* := ( 'seq', 'name', 'title', 'options', 'xpath', 'dlClass','formName','add', 'help' )
(:    let $json :=
        object-node {
            'items': array-node {
                for $item in $file/items/item
                return (
                    object-node {
                        'id': ( $item/xs:string(.), '' )[1],
                        'title': ( $item/@title/xs:string(.), '' )[1]
                    }
                )
            },
            'types': array-node {
                for $type as element(ldse:type) in $settings:titan-types
                where fn:exists($type/@value/xs:string(.))
                order by $type ascending
                return (
                    object-node {
                        'value': $type/@value/xs:string(.),
                        'name': ( $type/xs:string(.), '' )[1]
                    }
                )
            }
        }:)
    return (
        <dl data-sequence="{ xs:string($dynamicXml/@seq) }" data-group="{ $dynamicXml/@group }" class="{ xs:string($dynamicXml/@dlClass) }">
            <dt>
                <label>{ xs:string($dynamicXml/@title) }</label>
            </dt>
{(:            <collection-wrapper json="{ xdmp:from-json($json) }"></collection-wrapper>:)}
           <dd>
{(:                <titan-collection-items items="{ xdmp:from-json($json) }"></titan-collection-items>:)}
                <ul>{
                    getInputAttributes($dynamicXml, $blockAttrs, $index),
                    for $node as element() at $index in $nodes
                    let $id as xs:string := $node
                    let $title as xs:string? := $node/@title
                    let $type as xs:string? := $node/@type
                    let $show-it as xs:string? := "display:none;"
                    where fn:exists($id)
                    return (
                        element li {
                            attribute class { "repeated-item" },
                            <dl>
                                <span class="correlation-not-approved warning float-left" style="{$show-it}">
                                    <span>
                                        <span class="ldse-icon-ko-warning ldse-icon ldse-info-banner-icon">Warning</span>
                                        <label>Cor-IP / Cor-Eval not approved for publishing</label>
                                    </span>
                                </span>
                                <a href="#d" class="sprite delete ldse-icon-ko-remove bottom float-right deleteListItem"></a>
                                <input type="hidden" name="{fn:concat($name, '-child')}" class="child" value="{$index}"/>
                            </dl>,
                            <div class="correlation-not-approved" style="{$show-it}">&nbsp;</div>,
                            <div>Type: { $type }</div>,
                            <fieldset class="table">{
                                <dd>
                                    <input type="hidden" value="{ $id }" name="{ $name || '-' || $index }"></input>
                                    <input type="hidden" value="{ $title }" name="{ $name || '-' || $index }"></input>
                                    <input type="hidden" value="{ $type }" name="{ $name || '-' || $index }"></input>
                                    <h3>
                                        <a>{ $title }</a>
                                    </h3>
                                </dd>
                            }</fieldset>
                        }
                    )
                }</ul>
                <div class="titan-type" style="margin-bottom: 5px;">
                    <label>Select Titan Asset Type</label>
                    <select class="titan-type-select">{
                        for $type as element(ldse:type) in $settings:titan-types
                        order by $type ascending
                        return <option value="{ $type/@value/xs:string(.) }">{ $type/xs:string(.) }</option>
                    }</select>
                </div>
                <a href="#d" class="ldse-button secondary ldse-icon-search prefix titanFormItem" data-collection="collection" data-type="audio" data-name="{ $name }" data-file-id="{ $file/@id }">Search Titan</a>
            </dd>
        </dl>
    )
};

(: End of Input Functions :)

(: Uses xdmp:value to evaluate the $xpath against the $file passed in :)
declare function dynamicXpath($file as element(), $xpath as xs:string) as item()* {
    let $value as item()* := $file/xdmp:value($xpath)
    return (
        typeswitch ($value)
            case attribute() return ( fn:string($value) )
            default return (
                $value
            )
    )
};

(: Function to add ids to versification map :)
declare function updateVersIdMap($xml as element()) as empty-sequence() {
    for $id in $xml//@data-id
    return map:put($vers-map, $id, $id)
};

declare function buildNewXml($status as xs:string, $origFile as element()?, $form as element(ldse:formTemplate)) as element() {
    buildNewXml($status, $origFile, $form, ())
};

declare function buildNewXml($status as xs:string, $origFile as element()?, $form as element(ldse:formTemplate), $id as xs:string) as element() {
    let $vers-map-add as empty-sequence() := updateVersIdMap($origFile)
    let $uri as xs:string? := getVariable('uri')
    let $versify as xs:boolean := $settings:versification = 'true' or $uri = $settings:versification-uris or ( fn:starts-with($uri, $settings:versification-uris) and fn:exists($settings:versification-uris) and fn:not($uri = $settings:not-versification-uris) and fn:not($uri = "null") and fn:not($uri = "") )
    let $added-items as element()* :=
        for $item as xs:string in map:keys(getVariable('added-fields'))
        let $name as xs:string := fn:substring-before($item, ':')
        let $type as xs:string := fn:substring-before(fn:substring-after($item, ':'), '|')
        return (
            element { fn:QName('http://lds.org/code/lds-edit', $name) } {
                if ( $type = 'image' or $type = 'titan-image' or $type = 'select' ) then (
                    attribute its:translate { 'no' }
                ) else (),
                element { fn:QName('http://lds.org/code/lds-edit', 'input') } {
                    attribute name { $name },
                    attribute xpath { $name || '/node()' },
                    attribute type { $type },
                    attribute id { $name },
                    if ( $type = 'wysiwyg' ) then (
                        attribute options { 'tidy' }
                    ) else ()
                }
            }
        )
    let $templateName := $form/@name/fn:string()
    let $result := mem:node-insert-child($form/ldse:structure/element(), $added-items)/*
    let $form := if ($templateName eq 'pageBuilder' or $templateName eq 'site-creator') then $result else $form
    let $xml as element() :=
        if ( $versify ) then (
            dispatchStructure($origFile, $form/ldse:structure/node(), (), $id, fn:true(), $form)
        ) else ( dispatchStructure($origFile, $form/ldse:structure/node(), (), $id, fn:false(), $form) )

    let $xml as element() := if ( $versify ) then ( element { fn:name($xml) } { $xml/@*, build-xml($origFile, $xml, $xml, $form) } ) else ( $xml )
    let $xml as element() := if ( fn:exists($xml/@translation) ) then ( mem:node-delete($xml/@translation) ) else ( $xml )
    let $xml as element() := postProcessing($origFile, $xml, $form)
    return $xml
};

(: PRE PROCESSING FUNCTIONS (DJS) :)
(:
    <ldse:pre-processing>
        <ldse:function name="ns:someFuntionNameThatTakesTwoParams"/>
    </ldse:pre-processing>
:)

declare function preProcessing($origFile as element()?, $form as element(ldse:formTemplate)) as element()? {
    let $functions as xdmp:function* :=
        for $functionName as xs:string in $form/ldse:pre-processing/ldse:function/@name
        where $functionName ne ''
        return getFunction($functionName)
    return (
        preProcessingFunctionChain($functions, $origFile, $form)
    )
};

declare function preProcessingFunctionChain($functions as xdmp:function*, $origFile as element()?, $form as element(ldse:formTemplate)) as element()? {
    if (fn:count($functions) eq 0) then (
        $origFile
    ) else (
        preProcessingFunctionChain(fn:subsequence($functions, 2), xdmp:apply($functions[1], $origFile, $form), $form)
    )
};

(: POST PROCESSING FUNCTIONS :)
declare function postProcessing($origFile as element()?, $newXml as element(), $form as element(ldse:formTemplate)) as element() {
    let $update-meta as xs:string? := 'update-meta'
    let $action-transform as xs:string? := 'apply-action-transform'
    let $customPage as xs:string? := if ( fn:exists($form/ldse:custom-page) and fn:not(xdmp:get-request-field('updateCustomPage') = 'false') ) then ( 'updateCustomPage' ) else ()

    let $new-file-compare := if ( fn:exists($newXml/@status) ) then ( mem:node-delete($newXml/@status) ) else ( $newXml )
    let $orig-file-compare := if ( fn:exists($origFile/ldse:ldse-meta) ) then ( mem:node-delete($origFile/ldse:ldse-meta)/* ) else ( $origFile )
    let $orig-file-compare := if ( fn:exists($orig-file-compare/@status) ) then ( mem:node-delete($orig-file-compare/@status)/* ) else ( $orig-file-compare )
    let $files-are-equal as xs:boolean := fn:deep-equal($orig-file-compare, $new-file-compare)
    let $add-scheduled-publish as xs:string? := if ($form/@schedule-publish eq 'true') then ('scheduledPublish') else ()
    let $add-scheduled-unpublish as xs:string? := if ($form/@schedule-unpublish eq 'true') then ('scheduledUnpublish') else ()
    (: let $addFormOptions as xs:string? := if ($form/@addOptions eq 'false') then () else ('addFormOptions') :)
    let $functions as xdmp:function* :=
        for $functionName as xs:string in ($update-meta, $customPage, if ( fn:not($files-are-equal) ) then ( $action-transform, $add-scheduled-publish, $add-scheduled-unpublish ) else ( '' ), $form/ldse:post-processing/ldse:function/@name)
        where $functionName ne ''
        return getFunction($functionName)

    return (
        postProcessingFunctionChain($functions, $origFile, $newXml, $form)
    )
};

declare function postProcessingFunctionChain($functions as xdmp:function*, $origFile as element()?, $newXml as element(), $form as element(ldse:formTemplate)) as element() {
    if (fn:count($functions) eq 0) then (
        $newXml
    ) else (
        postProcessingFunctionChain(fn:subsequence($functions, 2), $origFile, xdmp:apply($functions[1], $origFile, $newXml, $form), $form)
    )
};

declare function apply-action-transform($origFile as element()?, $newXml as element(), $form as element(ldse:formTemplate)) as element() {
    core:action-transform(getVariable('status'), $newXml)
};

declare function addSource($origFile as element()?, $newXml as element(), $form as element(ldse:formTemplate)) as element() {
    if (fn:exists($newXml/@source)) then ($newXml) else (
        let $source as attribute(source) := attribute source {getVariable('source')}
        return (mem:node-insert-child($newXml, $source))
    )
};

declare function update-meta($origFile as element()?, $newXml as element(), $form as element(ldse:formTemplate)) as element() {
    let $action as xs:string := getVariable('action')
    let $status as xs:string := getVariable('status')
    let $meta-status as xs:string := settings:get-action-meta-status($status)
    let $to-translate as xs:string := getVariable('to-translate')
    let $file as element() := if ( fn:empty($origFile) ) then ( $newXml ) else ( $origFile )

    let $new-file-compare := if ( fn:exists($newXml/@status) ) then ( mem:node-delete($newXml/@status) ) else ( $newXml )
    let $orig-file-compare := if ( fn:exists($origFile/ldse:ldse-meta) ) then ( mem:node-delete($origFile/ldse:ldse-meta)/* ) else ( $origFile )
    let $orig-file-compare := if ( fn:exists($orig-file-compare/@status) ) then ( mem:node-delete($orig-file-compare/@status)/* ) else ( $orig-file-compare )
    let $files-are-equal as xs:boolean := fn:deep-equal($orig-file-compare, $new-file-compare)

    let $ldse-meta as element(ldse:ldse-meta) :=
        if ( $files-are-equal and $to-translate = 'true' ) then (
            $origFile/ldse:ldse-meta
        ) else ( ldsemeta:get-meta($file, getVariable('id'), getVariable('locale'), getVariable('uri'), $meta-status ) )

    (: ENRICH R&D :)
    let $enrich-on as xs:boolean := $form/ldse:enrich = "true" and enrich:enrichable-lang(getVariable('locale'))
    let $enriched as xs:boolean := xdmp:get-request-field('ldse-document-enriched', 'false') = 'true'
    let $enrich as element(ldse:enrich)? :=
        if ($enrich-on and $enriched and fn:exists($ldse-meta/ldse:enrich) ) then (
            let $enrich as element(ldse:enrich)? := $ldse-meta/ldse:enrich
            let $keyword-indexes as xs:int* :=
                for $v as xs:string in xdmp:get-request-field("ldse-keyword")
                return ( xs:int($v) )
            let $org-indexes as xs:int* :=
                for $v as xs:string in xdmp:get-request-field("ldse-organization")
                return ( xs:int($v) )
            let $role-indexes as xs:int* :=
                for $v as xs:string in xdmp:get-request-field("ldse-role")
                return ( xs:int($v) )
            let $location-indexes as xs:int* :=
                for $v as xs:string in xdmp:get-request-field("ldse-location")
                return ( xs:int($v) )
            let $person-indexes as xs:int* :=
                for $v as xs:string in xdmp:get-request-field("ldse-person")
                return ( xs:int($v) )
            let $related-indexes as xs:int* :=
                for $v as xs:string in xdmp:get-request-field("ldse-related")
                return ( xs:int($v) )
            return (
                enrich:update-actives($enrich, $keyword-indexes, $org-indexes, $role-indexes, $location-indexes, $person-indexes, $related-indexes)
            )
        ) else ()
    (: ENRICH R&D :)

    let $restored-versions as xs:string* := fn:tokenize(xdmp:get-request-field("restored-versions"), ',')[. != ""]
    let $node-name := xs:string(fn:node-name($newXml))
    let $subsitename := if ($node-name eq 'sub-site') then
                            $newXml/name/fn:string()
                        else ()
    let $option as xs:string? := getVariable('option')
    let $ldse-meta as element(ldse:ldse-meta) :=
        ldsemeta:add-form-options($ldse-meta,
                <form-options xmlns="http://lds.org/code/lds-edit">{
                    attribute its:translate {"no"},
                    if ( fn:exists($option) and fn:not($option = "") ) then (
                        for $item as xs:string in fn:tokenize($option,',')
                        let $tokens as xs:string* := fn:tokenize($item, ':')
                        let $name as xs:string? := $tokens[1]
                        let $value as xs:string? := $tokens[2]
                        where fn:exists($name) and fn:exists($value)
                        return (
                            if ($node-name eq 'sub-site' and $name eq 'site-context') then
                               element {$name} {$subsitename}
                            else
                                element {$name} {$value}
                        )
                    ) else (
                        element form {$formName}
                    )
                }</form-options>
        )
    let $sensitive as xs:string? := xdmp:get-request-field("sensitive")
    let $stakeholder as xs:string? := xdmp:get-request-field("stakeholder")
    let $request as xs:string? := if ( $status = "ldse:publish" ) then ( "yes" ) else ( xdmp:get-request-field("request") )
    let $approval-sent as xs:string? := if ( $status = "ldse:publish" ) then ( "no" ) else ( xdmp:get-request-field("approval-sent") )
    let $other-stakeholders as xs:string* := xdmp:get-request-field("other-stakeholders")
    let $ldse-meta as element(ldse:ldse-meta) := ldsemeta:update-sensitive-meta($ldse-meta, $sensitive, $stakeholder, $request, $approval-sent, $status, $other-stakeholders)
    let $email-addresses as xs:string* := util:get-stakeholder-emails($ldse-meta)
    let $email as item()* :=
        if ( $sensitive = "yes" and fn:exists($stakeholder) and $status = "ldse:publish" ) then (
            let $subject := fn:concat(core:get-title($newXml), " has been Published")
            let $body as element() :=
                <html xmlns="http://www.w3.org/1999/xhtml">
                    <head>
                        <title>{$subject}</title>
                    </head>
                    <body>
                        <div>
                            <div>
                                <p>{core:get-title($file)} has been published. This content is considered sensitive. If it should be unpublished, click <a href="{fn:concat(core:get-domain($newXml, getVariable('locale')), $settings:shared-prefix)}/sensitive/unpublish?lang=eng">here</a></p>
                            </div>
                        </div>
                        {(:                    <div class="footer">
                            <div>Modify your notification settings by visiting this link: <a href="publisher-preview{$env}.lds.org/publishing/notifications">settings</a></div>
                            <div>To unsubscribe from ALL future emails: <a href="publisher-preview{$env}.lds.org/publishing/notifications/unsubscribe?email={$email}&amp;h={$hash}">unsubscribe</a></div>
                        </div>:)}
                    </body>
                </html>
            return (
                for $email-address as xs:string in $email-addresses
                return (
                    util:send-email($email-address, "", $subject, $body, "no-reply@ldschurch.org", "LDS Publisher")
                )
            )
        ) else ()
    let $trans-attr as item()* := $newXml//@translation
    let $ldse-meta as element(ldse:ldse-meta) :=
        if ($action eq 'add') then (
            ldsemeta:update-document-source($ldse-meta)
        ) else ( $ldse-meta )
    let $ldse-meta as element(ldse:ldse-meta) :=
        if ($action = 'add' and $status != $meta-status) then (
            ldsemeta:remove-publish-date($ldse-meta)
        ) else ( $ldse-meta )
    let $ldse-meta as element(ldse:ldse-meta) :=
        if ( $to-translate = 'true' and fn:exists($origFile) ) then (
            ldsemeta:translation-mark-ready($ldse-meta, ())
        ) else (
            ldsemeta:translation-remove-ready($ldse-meta)
        )

    let $ldse-meta as element(ldse:ldse-meta) :=
        if ( fn:exists($restored-versions) ) then (
            let $version-text as xs:string* :=
                for $version as xs:string in $restored-versions
                return (
                    if( $version castable as xs:dateTime) then (
                        fn:format-dateTime( xs:dateTime($version), '[D01] [MNn,*-3] [Y0001] [h]:[m01] [PN]')
                    ) else if ($version = "current") then (
                        fn:format-dateTime(
                                xs:dateTime(
                                        (
                                            $file/ldse:ldse-meta/ldse:last-modified/@date,
                                            fn:current-dateTime()
                                        )[1]
                                ),
                                '[D01] [MNn,*-3] [Y0001] [h]:[m01] [PN]'
                        )
                    ) else if ($version = "published") then (
                        "Published"
                    ) else (
                        $version
                    )
                )
            return ldsemeta:version-restored($ldse-meta, fn:string-join($version-text, ', '))
        ) else (
            $ldse-meta
        )
    (: ENRICH R&D :)
    let $ldse-meta as element(ldse:ldse-meta) :=
        if ( fn:exists($enrich) ) then (
            if ( fn:exists($ldse-meta/ldse:enrich) ) then (
                mem:node-replace($ldse-meta/ldse:enrich, $enrich)
            ) else (
                mem:node-insert-child($ldse-meta, $enrich)
            )
        ) else if ( fn:not( $enrich-on ) and fn:exists($ldse-meta/ldse:enrich) ) then (
            mem:node-delete($ldse-meta/ldse:enrich)
        ) else ( $ldse-meta )
    (: ENRICH R&D :)
    return (
        if($newXml/*[1]) then (
            mem:node-insert-before($newXml/*[1], $ldse-meta)
        ) else (
            mem:node-insert-child($newXml, $ldse-meta)
        )
    )
};

declare function addPublishDate($origFile as element()?, $newXml as element(), $form as element(ldse:formTemplate)) as element() {
    let $status as xs:string := getVariable('status')
    let $action as xs:string := getVariable('action')
    let $publishDate as element(publishDate)? :=
        if ($status eq "publish") then (
            element publishDate {
                attribute its:translate {"no"},
                attribute user {ac:getUserName()},
                fn:current-dateTime()
            }
        ) else if ($status ne "unpublish" and $origFile/publishDate and $action ne 'add') then (
            $origFile/publishDate
        ) else ()
    return (
        if (fn:exists($publishDate)) then (
            mem:node-insert-after($newXml/*[fn:last()], $publishDate)
        ) else ($newXml)
    )
};

declare function addFormOptions($origFile as element()?, $newXml as element(), $form as element(ldse:formTemplate)) as element() {
    let $option as xs:string := getVariable('option')
    let $options as element(form-options) :=
        element form-options {
            attribute its:translate {"no"},
            for $item as xs:string in fn:tokenize($option,',')
            let $tokens as xs:string* := fn:tokenize($item, ':')
            let $name as xs:string? := $tokens[1]
            let $value as xs:string? := $tokens[2]
            where fn:exists($name) and fn:exists($value)
            return (
                element {$name} {$value}
            )
        }
    return (
        if (fn:exists($options/*)) then (
            mem:node-insert-after($newXml/*[fn:last()], $options)
        ) else ($newXml)
    )
};

(: Updates the references on components which depend on a component that has been deleted.
   If the component has been updated, and it is flagged for deletion, it will remove the
   references hosted in other components.
   @param $origFile - is the xml that has been updated
   @param $compName - is the component's name that has been updated.
:)
declare function updateCustomPageDependencies(
    $origFile as element(),
    $compName as xs:string
) as element() {
    (: id used in references of the component updated :)
    let $id as xs:string := $origFile/@id/fn:string()
    (: info about component updated :)
    let $origCustomPage as element(custom-page)? :=
        cts:search(/custom-page,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('uri'), ( getVariable('uri'), $origFile/ldse:ldse-meta/ldse:document/@uri )[1], ('exact')),
                cts:element-value-query(xs:QName('ldse:site-context'), getVariable('site-context'), 'exact'),
                cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('locale'), getVariable('locale'), ('exact'))
            ))
        )[1]
    let $origFileId := $origCustomPage/@id/fn:string()

    (: get all components that depend on the component updated :)
    let $custom-pages as element(custom-page)* :=
        cts:search(/custom-page,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('locale'), getVariable('locale'), ('exact')),
                cts:not-query(cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('id'), $origFileId, ('exact'))),
                cts:element-query(xs:QName('content'),
                    cts:and-query((
                        cts:element-value-query(xs:QName($compName), $id, ('exact'))
                    ))
                )
            ))
        )
    (: update component references when component is flagged for deletion :)
    let $updateFiles as empty-sequence() :=
        for $newXml in $custom-pages
        let $action as xs:string := getVariable('action')
        let $status as xs:string := getVariable('status')
        let $action as xs:string :=
            if ( $action = 'edit' or $action = 'add' ) then (
                $status
            ) else ( $action )
        let $save-action as xs:string :=
            if ( fn:exists(settings:get-action-delete-modes($action)) ) then (
                ($settings:actions[fn:not(ldse:delete/ldse:mode)])[1]/@name
            ) else (
                $action
            )
        (: reference signature of component deleted used by references :)
        let $contentRef as element() := element { xs:string($compName) } { $id }
        (: building new component without deleted reference :)
        let $newPage as element() :=
            element { fn:name($newXml) } {
                $newXml/@*,
                $newXml/*[fn:not(fn:node-name(.) = (xs:QName('content')))],
                element content {
                    $newXml/content/@*,
                    $newXml/content/*[fn:not(. = ($contentRef))]
                }
            }
        let $dbPath as xs:string? := xdmp:node-uri($newXml)
        (: update the dependent component :)
        let $save as item()* := core:update-file($save-action, $dbPath, $newPage, $newXml)
        return ()
    return $origFile
};

declare function updateCustomPage(
    $origFile as element()?,
    $newXml as element(),
    $form as element(ldse:formTemplate)
) as element() {
    let $custom-page as element(custom-page)? :=
        cts:search(/custom-page,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('uri'), ( getVariable('uri'), $newXml/ldse:ldse-meta/ldse:document/@uri )[1], ('exact')),
                cts:element-value-query(xs:QName('ldse:site-context'), getVariable('site-context'), 'exact'),
                cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('locale'), getVariable('locale'), ('exact'))
            ))
        )
    let $wrapper-id as xs:string? := xdmp:get-request-field('wrapper-id')
    let $item as element()? :=
        if ( fn:exists($custom-page) ) then (
            $custom-page
        ) else (
            cts:search(fn:collection(),
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), ( getVariable('uri'), $newXml/ldse:ldse-meta/ldse:document/@uri )[1], 'exact'),
                    cts:element-value-query(xs:QName('ldse:site-context'), getVariable('site-context'), 'exact'),
                    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), getVariable('locale'), 'exact'),
                    if ( getVariable('status') = 'ldse:delete' or getVariable('action') = 'ldse:delete' or getVariable('action') = 'edit' ) then (
                        cts:element-value-query(xs:QName(fn:name($newXml)), $newXml/ldse:ldse-meta/ldse:document/@id, 'exact')
                    ) else (),
                    if ( fn:exists($wrapper-id) ) then (
                        cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $wrapper-id, 'exact')
                    ) else ()
                ))
            )/*
        )
    let $update as empty-sequence() :=
        if ( fn:exists($item) and fn:exists($form/ldse:custom-page/@type) ) then (
            let $status as xs:string := getVariable('status')
            let $action as xs:string := getVariable('action')
            let $is-edit as xs:boolean :=
                if ($status eq 'ldse:delete') then
                    fn:false()
                else
                    $action = 'edit'
            let $action as xs:string :=
                if ( $action = 'edit' or $action = 'add' ) then (
                    $status
                ) else ( $action )
            let $save-action as xs:string :=
                if ( fn:exists(settings:get-action-delete-modes($action)) ) then (
                    ($settings:actions[fn:not(ldse:delete/ldse:mode)])[1]/@name
                ) else (
                    $action
                )
            let $region := fn:substring-after(fn:tokenize(getVariable('option'), ',')[fn:contains(., 'region')], '=')
            let $admin-location := fn:substring-after(fn:tokenize(getVariable('option'), ',')[fn:contains(., 'admin-location-var')], '=')
            let $update-page as xs:string? := xdmp:get-request-field('updateCustomPage')
            let $page-status as xs:string := if ($save-action = "ldse:publish") then ("publish") else ("preview")
            let $mainRef as element() :=
                element { xs:string($form/ldse:custom-page/@type) } {
                    $newXml/@location,
                    attribute is-id { 'true' },
                    if ( fn:exists($region) and fn:not($region = '') ) then ( attribute region { $region } ) else (),
                    if ( fn:exists($admin-location) and fn:not($admin-location = '') ) then ( attribute admin-location { $admin-location } ) else (),
                    ( $newXml/@id/fn:string(), getVariable('id') )[1]
                }
            let $delete-mode as xs:boolean := settings:get-action-delete-modes($action) = $core:mode
            let $inlineRefs as element()* := buildInlineReference($newXml//xhtml:pre)
            let $newPage as element() :=
                if ( ( $page-status = 'publish' and fn:exists($origFile) ) or $is-edit or $update-page = 'false' ) then (
                    element { fn:name($item) } {
                        attribute status { $page-status },
                        $item/@*[fn:not(fn:local-name(.) eq 'status')],
                        ldsemeta:get-meta($item, (), (), (), $page-status),
                        $item/*[fn:not(fn:node-name(.) = xs:QName('ldse:ldse-meta'))]
                    }
                ) else (
                    element { fn:name($item) } {
                        attribute status { $page-status },
                        $item/@*[fn:not(fn:local-name(.) eq 'status')],
                        ldsemeta:get-meta($item, (), (), (), $page-status),
                        element content {
                            attribute its:translate { "no" },
                            $item/content/*[fn:not(. = ($mainRef, $inlineRefs))],
                            if ( fn:not($delete-mode) and $status != "ldse:remove") then (
                                $mainRef,
                                $inlineRefs
                            ) else ()
                        },
                        $item/*[fn:not(fn:node-name(.) = (xs:QName('content'), xs:QName('ldse:ldse-meta')))]
                    }
                )
            let $dbPath as xs:string? := xdmp:node-uri($item)
            let $save as item()* := core:update-file($save-action, $dbPath, $newPage, $item)

            (:let $debug := xdmp:log(("HERE", $dbPath)):)
            return ()


        ) else if (fn:exists($form/ldse:custom-page/@type) and fn:string($form/ldse:custom-page/@create) eq "true") then (
            let $status as xs:string := getVariable('status')
            let $save-action as xs:string :=
                if ( fn:exists(settings:get-action-delete-modes($status) ) ) then (
                    ($settings:actions[fn:not(ldse:delete/ldse:mode)])[1]/@name
                ) else (
                    $status
                )
            let $page-status as xs:string := if ($save-action = "ldse:publish") then ("publish") else ("preview")
            let $mainRef as element() :=
                element {xs:string($form/ldse:custom-page/@type)} {
                    $newXml/@location,
                    getVariable('id')
                }
            let $delete-mode as xs:boolean := settings:get-action-delete-modes($save-action) = $core:mode
            let $id as xs:string := fn:concat(util:generate-unique-id(), "-", $newXml/@locale)
            let $inlineRefs as element()* := buildInlineReference($newXml//xhtml:pre)
            let $newPage as element(custom-page) :=
                element custom-page {
                    attribute status {$page-status},
                    $newXml/@*[fn:not(fn:local-name(.) eq 'status') and fn:not(fn:local-name(.) eq 'type') and fn:not(fn:local-name(.) eq 'id')],
                    attribute id { $id },
                    element content {
                        attribute its:translate {"no"},
                        if ( fn:not($delete-mode) and $status != "ldse:remove" ) then (
                            $mainRef,
                            $inlineRefs
                        ) else ()
                    },
                    $form/ldse:custom-page/*
                }
            let $meta as element(ldse:ldse-meta) := ldsemeta:get-meta($newXml, $id, (), (), $page-status)
            let $edited-page as element(custom-page) := mem:insert-child($newPage, $meta)
            let $dbPath as xs:string? := core:build-db-path(getVariable('uri'), getVariable('locale'), getVariable('id'), $edited-page)
            let $save as item()* := core:update-file($save-action, $dbPath, $edited-page, ())

            return ()
        ) else ()
    return ( $newXml )
};

(: $inlinePre should be as element(xhtml:pre) or element(pre) :)
declare function buildInlineReference($inlinePre as element()) as element()? {
    let $tokens as xs:string* := fn:tokenize(fn:substring-before(fn:substring-after(xs:string($inlinePre),"["),"]"), ":")
    let $type as xs:string := fn:normalize-space(fn:lower-case($tokens[1]))
    let $type as xs:string := if ($type eq 'brightcove') then ('video') else ($type)
    let $id as xs:string? := fn:normalize-space($tokens[2])
    where fn:exists($id) and fn:not($id = "")
    return (
        element {$type} {
            attribute location {"inline"},
            $id
        }
    )
};

declare function scheduledPublish($origFile as element()?, $newXml as element(), $form as element(ldse:formTemplate)?) as element() {
    let $futureDate as xs:string? := xdmp:get-request-field("futureDate")
    let $futureHour as xs:string? := xdmp:get-request-field("futureHour", "00")
    let $futureMin as xs:string? := xdmp:get-request-field("futureMin", "00")

    let $date as xs:date? := if ($futureDate ne '') then (xs:date($futureDate)) else ()
    let $time as xs:time? := if ($futureDate ne '') then ( xs:time(fn:concat($futureHour,":",$futureMin,":00")) ) else ()
    let $dateTime as xs:dateTime? := if ($futureDate ne '') then ( fn:dateTime($date, $time) ) else ()
    return (
        if (fn:exists($futureDate) and $futureDate ne '' and $dateTime > fn:current-dateTime()) then (
            let $id as xs:string := getVariable('id')
            let $site as xs:string := getVariable('site')
            let $locale as xs:string := getVariable('locale')
            let $uri as xs:string := getVariable('uri')
            let $user as xs:string := getVariable('user')

            let $scheduleTask as item()*  := task:queue-action-task('ldse:publish', $dateTime, $id, $locale, $uri, $user)

            let $ldse-meta as element(ldse:ldse-meta) := ldsemeta:schedule-publish(ldsemeta:get-meta($newXml), $date, $time)

            return (
                if ( fn:exists($newXml/ldse:ldse-meta) ) then (
                    mem:node-replace($newXml/ldse:ldse-meta, $ldse-meta)
                ) else (
                    mem:node-insert-before($newXml/*[1], $ldse-meta)
                )
            )
        ) else (
            let $ldse-meta as element(ldse:ldse-meta) := ldsemeta:remove-schedule-publish(ldsemeta:get-meta($newXml))
            return (
                if ( fn:exists($newXml/ldse:ldse-meta) ) then (
                    mem:node-replace($newXml/ldse:ldse-meta, $ldse-meta)
                ) else (
                    mem:node-insert-before($newXml/*[1], $ldse-meta)
                )
            )
        )
    )
};

declare function scheduledUnpublish($origFile as element()?, $newXml as element(), $form as element(ldse:formTemplate)?) as element() {
    let $futureDate as xs:string? := xdmp:get-request-field("unpubFutureDate")
    let $futureHour as xs:string? := xdmp:get-request-field("unpubFutureHour", "00")
    let $futureMin as xs:string? := xdmp:get-request-field("unpubFutureMin", "00")

    let $date as xs:date? := if ($futureDate ne '') then (xs:date($futureDate)) else ()
    let $time as xs:time? := if ($futureDate ne '') then ( xs:time(fn:concat($futureHour,":",$futureMin,":00")) ) else ()
    let $dateTime as xs:dateTime? := if ($futureDate ne '') then ( fn:dateTime($date, $time) ) else ()
    return (
        if (fn:exists($futureDate) and $futureDate ne '' and $dateTime > fn:current-dateTime()) then (
            let $id as xs:string := getVariable('id')
            let $site as xs:string := getVariable('site')
            let $locale as xs:string := getVariable('locale')
            let $uri as xs:string := getVariable('uri')
            let $user as xs:string := getVariable('user')

            let $scheduleTask as item()*  := task:queue-action-task('ldse:unpublish', $dateTime, $id, $locale, $uri, $user)

            let $ldse-meta as element(ldse:ldse-meta) := ldsemeta:schedule-unpublish(ldsemeta:get-meta($newXml), $date, $time)
            return (
                if ( fn:exists($newXml/ldse:ldse-meta) ) then (
                    mem:node-replace($newXml/ldse:ldse-meta, $ldse-meta)
                ) else (
                    mem:node-insert-before($newXml/*[1], $ldse-meta)
                )
            )
        ) else (
            let $ldse-meta as element(ldse:ldse-meta) := ldsemeta:remove-schedule-unpublish(ldsemeta:get-meta($newXml))
            return (
                if ( fn:exists($newXml/ldse:ldse-meta) ) then (
                    mem:node-replace($newXml/ldse:ldse-meta, $ldse-meta)
                ) else (
                    mem:node-insert-before($newXml/*[1], $ldse-meta)
                )
            )
        )
    )
};

(: END OF POST PROCESSING FUNCTIONS:)

(: Executes Save Functions :)
declare function saveFile($origFile as element()?, $newXml as element(), $form as element(ldse:formTemplate)) as item()* {
    let $functionName as xs:string := if (fn:exists($form/ldse:save-function)) then ($form/ldse:save-function/@name) else ('defaultSaveFile')
    return (
        xdmp:apply(getFunction($functionName), $origFile, $newXml, $form)
    )
};
(: Default Save used unless other is specfied in form :)
declare function defaultSaveFile($origFile as element()?, $newXml as element(), $form as element(ldse:formTemplate)) as item()* {
    let $status as xs:string := getNewStatusIfNeeded($origFile, $newXml)
    let $dbPath as xs:string := getDbPath($origFile, $newXml, $form)
    let $collection as element()? := $form/ldse:collections/ldse:collection
    let $options as element() := <options>{ if ( fn:exists($collection) ) then ( <collection>{$collection/fn:string()}</collection> ) else () }</options>
    return (
        $dbPath,
        core:update-file($status, $dbPath, $newXml, $origFile, $options)
    )
};

declare function getNewStatusIfNeeded(
    $origFile as element()?,
    $newXml as element()
) as xs:string {
    if ( ( $newXml/@status = "unpublish" or ldsemeta:get-document-status($newXml) = 'unpublish' ) and fn:exists($origFile) ) then (
        "ldse:unpublish"
    ) else ( getVariable('status') )
};

declare function redirect($origFile as element()?, $newXml as element()?, $form as element(ldse:formTemplate)?) as xs:string? {
    let $functionName as xs:string := if (fn:exists($form/ldse:redirect-function)) then ($form/ldse:redirect-function/@name) else ('defaultRedirect')
    return (
        xdmp:apply(getFunction($functionName), $origFile, $newXml, $form)
    )
};

(: Default Redirect used unless other is specfied in form :)
declare function defaultRedirect($origFile as element()?, $newXml as element()?, $form as element(ldse:formTemplate)?) as xs:string? {
    let $referer as xs:string := getVariable('referer')
    let $uri as xs:string :=
        if (fn:local-name($newXml) = "custom-page") then (
            $newXml/@uri
        ) else if ($referer) then (
            fn:replace($referer, getVariable('host'), "")
        ) else (
            getVariable('uri')
        )
    let $uri as xs:string :=
        if (getVariable('sharedPrefix') ne '' and fn:not(fn:starts-with($uri, getVariable('sharedPrefix'))) and fn:not(fn:contains($uri, "://"))) then (
            fn:concat(getVariable('sharedPrefix'), $uri)
        ) else (
            $uri
        )
    return (
        core:build-url($uri, getVariable('locale'), ())
    )
};

declare function dispatchStructure($file as element()?, $structure as item()*, $id as xs:string) as item()* {
    dispatchStructure($file, $structure, (), $id, fn:false())
};

declare function dispatchStructure($file as element()?, $structure as item()*, $id as xs:string, $versify as xs:boolean, $form as element(ldse:formTemplate)) as item()* {
    dispatchStructure($file, $structure, (), $id, $versify, $form)
};

declare function dispatchStructure($file as element()?, $structure as item()*, $index as xs:string?, $id as xs:string, $versify as xs:boolean, $form as element(ldse:formTemplate)) as item()* {
    dispatchStructure($file, $structure, $index, $id, (), $versify, $form)
};

declare function dispatchStructure($file as element()?, $structure as item()*, $index as xs:string?, $id as xs:string, $parent as xs:string?, $versify as xs:boolean, $form as element(ldse:formTemplate)) as item()* {
    for $n as item() at $i in $structure
    return (
        typeswitch ($n)
            case comment() return ()
            case text() return (if (fn:normalize-space($n) eq '') then () else ($n))
            case element(ldse:attribute) return (attribute {xs:string($n/@name)} {dispatchStructure($file, $n/node(), $index, $id, $parent, $versify, $form)})
            case element(ldse:input) return (getInputValue($n, $file, $index, $id, $i, $parent, $versify, $form))
            case element(ldse:dynamic-xml) return (getDynamicXmlValues($n, $file, $index, $id, $parent, $versify, $form))
            case element(ldse:dynamic-form-ref) return (getDynamicXmlValues($n, $file, $index, $id, $parent, $versify, $form))
            case element(ldse:dynamic-titan-item-refs) return (getDynamicXmlValues($n, $file, $index, $id, $parent, $versify, $form))
            case element(ldse:xhtml) return () (: only used to help give content contributor help filling out form :)
            case element(ldse:component-ref) return ( buildComponentData($n, $file, $index, $id, $i, $parent, $versify, $form) )
            default return (
                createElement($n, $file, $index, $id, $i, $parent, $versify, $form)
            (: element { fn:node-name($n) } {
                $n/@*, dispatchStructure($file, $n/node(), $index)
            } :)
            )
    )
};

declare function buildComponents(
    $n as element(ldse:component-ref),
    $file as element()?,
    $index as xs:string?,
    $path as xs:string?
) {
    let $updated-items as element()* := buildComponent($n, $file, $index, $path)

    return (
        buildForm($updated-items, $file, $index)
    )
};

declare function buildComponent(
    $n as element(ldse:component-ref),
    $file as element()?,
    $index as xs:string?,
    $path as xs:string?
) {
    if ( fn:exists($n/@name) ) then (
        let $component as element(ldse:component)? := getComponentXml($n)
        let $full-path as xs:string? := xdmp:path($n)
        let $parent-path as xs:string := fn:substring-before(fn:replace($full-path, 'ldse:', ''), 'component-ref')
        let $parent-path as xs:string :=
            if ( fn:contains($full-path, 'ldse:structure') ) then (
                fn:substring-after(fn:substring-after($parent-path, 'structure/'), '/')
            ) else if ( fn:contains($parent-path, '/component/') ) then (
                fn:concat($path, fn:substring-after($parent-path, '/component/'))
            ) else ( fn:concat($path, $parent-path) )
        let $parent-path as xs:string :=
            if ( fn:contains($parent-path, 'dynamic-xml') ) then (
                ''
            ) else ( $parent-path )
        return (
            updateComponentChildren($component, $component/node(), $parent-path, $n/@group, $file, $index, $n/@seq, $n/@class)
        )
    ) else ()
};

declare function updateComponentChildren(
    $n as element(ldse:component),
    $node as node(),
    $path as xs:string,
    $group as xs:string?,
    $file as element()?,
    $index as xs:string?,
    $seq as xs:string?,
    $class as xs:string?
) as item()* {
    typeswitch ( $node )
    case element(ldse:input) return (
        let $input-index as xs:string? := ( fn:string(map:get($comp-map, 'index'))[. != ''], '1' )[1]
        let $update as empty-sequence() := map:put($comp-map, 'index', xs:int($input-index) + 1)
        return (
            updateComponentInput($n, $node, $path, $group, $seq, $index, $class)
        )
    )
    case element(ldse:component-ref) return ( buildComponent($node, $file, $index, $path) )
    case text() return ( if ( fn:normalize-space($node) = '' ) then ( ) else ( $node ) )
    default return (
        element { fn:QName('http://lds.org/code/lds-edit', fn:local-name($node)) } {
            $node/@*,
            updateComponentChildren($n, $node/node(), $path, $group, $file, $index, $seq, $class)
        }
    )
};

declare function updateComponentInput(
    $n as element(ldse:component),
    $node as element(),
    $path as xs:string,
    $group as xs:string?,
    $seq as xs:string?,
    $input-index as xs:string?,
    $class as xs:string?
) as element() {
    element { fn:QName('http://lds.org/code/lds-edit', fn:local-name($node)) } {
        $node/@* except $node/(@xpath|@group|@name|@seq|@class|@inline-help),
        attribute group { ( $group, $node/@group )[1] },
        attribute xpath { $path || $node/@xpath },
        attribute name { $node/@name || '-' || $input-index },
        attribute seq { ( $seq, $node/@seq )[1] },
        attribute class { ( $class, $node/@class )[1] },
        if ( fn:exists($node/@inline-help) ) then ( attribute inline-help { fn:replace($node/@inline-help, '\|', '|' || functx:words-to-camel-case(fn:replace(getVariable('form'), '-', ' ')) || '-') } ) else (),
        updateComponentChildren($n, $node/node(), $path, $group, (), $input-index, $seq, $class)
    }
};

declare function getComponentXml(
    $component as element(ldse:component-ref)
) as element(ldse:component)? {
    cts:search(/ldse:component,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('ldse:component'), xs:QName('name'), $component/@name, 'exact')
        ))
    )
};

declare function buildComponentData(
    $node as element(),
    $file as element()?,
    $index as xs:string?,
    $id as xs:string,
    $i as xs:int,
    $parent as xs:string?,
    $versify as xs:boolean,
    $form as element(ldse:formTemplate)
) {
    buildComponentContent($node, $file, $index, (), ())
};

declare function buildElement(
    $n as element(ldse:component),
    $node as node(),
    $path as xs:string,
    $group as xs:string?,
    $file as element()?,
    $index as xs:string?,
    $seq as xs:string?,
    $input-index as xs:string?
) {
    typeswitch ( $node )
    case element(ldse:input) return (
        let $update as empty-sequence() := map:put($comp-map, 'index', xs:int($input-index) + 1)
        return (
            buildResult($n, $node, $file, $index, $path, $group, $seq, $index) )
        )
    case element(ldse:component-ref) return ( buildComponentContent($node, $file, $index, $path, $index) )
    case text() return ()
    default return (
        element { fn:local-name($node) } {
            $node/@*[fn:not(fn:local-name(.) eq ('ldse-ns', 'ldse-prefix', 'xpath', 'index', "duplicate"))],
            buildElement($n, $node/node(), $path, $group, $file, $index, $seq, $index)
        }
    )
};

declare function buildResult(
    $n as element(ldse:component),
    $node as element(),
    $file as element()?,
    $index as xs:string?,
    $path as xs:string,
    $group as xs:string?,
    $seq as xs:string?,
    $input-index as xs:string?
) as item()* {
    let $input as element(ldse:input) := updateComponentInput($n, $node, $path, $group, $seq, $input-index, $n/@class)
    return (
        getInputValue($input, $file, $index, fn:false())
    )
};

declare function buildComponentContent(
    $n as element(ldse:component-ref),
    $file as element()?,
    $index as xs:string?,
    $path as xs:string?,
    $input-index as xs:string?
) {
    if ( fn:exists($n/@name) ) then (
        let $component as element(ldse:component) := getComponentXml($n)
        let $full-path as xs:string? := xdmp:path($n)
        let $parent-path as xs:string := fn:substring-before(fn:replace($full-path, 'ldse:', ''), 'component-ref')
        let $parent-path as xs:string :=
            if ( fn:contains($parent-path, 'dynamic-xml') ) then (
                ''
            ) else if ( fn:contains($full-path, 'structure') ) then (
                fn:substring-after(fn:substring-after($parent-path, 'structure/'), '/')
            ) else if ( fn:contains($parent-path, '/component/') and fn:ends-with($parent-path, '/component/') ) then (
                fn:concat($path, fn:substring-after($parent-path, '/component/'))
            ) else ( fn:concat($path, $parent-path) )
        return (
            buildElement($component, $component/element(), $parent-path, $n/@group, $file, $index, $n/@seq, $input-index)
        )
    ) else ()
};

declare function getEnabledStatus($file as element()?, $path as xs:string?) as item()? {
    if (fn:root($file)/xdmp:value($path)/@disable) then
        attribute disable { "true" }
    else ( )
};


declare function createElement(
    $node as element(),
    $file as element()?,
    $index as xs:string?,
    $id as xs:string,
    $i as xs:int,
    $parent as xs:string?,
    $versify as xs:boolean,
    $form as element(ldse:formTemplate)
) as item()* {
    let $ns as xs:string? := $node/@ldse-ns
    let $prefix as xs:string? := $node/@ldse-prefix
    let $nodeName as xs:string :=
        if ($prefix ne '' and $ns ne '') then (
            fn:concat($prefix, ':', fn:local-name($node))
        ) else ( fn:local-name($node) )

    let $path as xs:string := xdmp:path(util:strip-namespaces($node))
    let $item-path as xs:string? := if ( fn:exists($index) ) then ( fn:concat($parent, $path, "[", $index, "]") ) else ( fn:concat($parent, $path) )
    let $curr-element as element()? := if ( $versify ) then ( getElementPath($node, $file, $index) ) else ()
    let $is-dup as xs:boolean := $node/ldse:input/@type = "duplicate"
    let $dup-name as xs:string? := ( $node/ldse:input/@name )[1]
    let $curr-element as element()? := if ( $is-dup ) then ( $file//node()[@data-id = $curr-element/@data-id] ) else ( $curr-element )
    return (
        let $new-element as element() :=
            element { fn:QName($ns, $nodeName) } {
                if ( $versify and fn:not(fn:local-name($node) = fn:local-name($file)) ) then (
                    let $id as xs:string := getUniqueId($node, $id, $i, 0)
                    let $put as empty-sequence() := map:put($vers-map, $id, $id)
                    return (
                        $curr-element/(@data-id|@translation),
                        if ( fn:empty($curr-element/@data-id) ) then ( attribute data-id { $id } ) else (),
                        attribute index { ( $index, $i )[1] },
                        attribute xpath { $item-path }
                    )
                ) else (),
                if ( $is-dup and $versify ) then (
                    attribute duplicate { $dup-name }
                ) else (),
                getEnabledStatus($file, $item-path),
                $node/@*[fn:not(fn:local-name(.) eq ('ldse-ns', 'ldse-prefix', 'xpath', 'index', "duplicate"))],
                if ( $is-dup and fn:not(fn:contains($node/ldse:input/@options, "constant")) and $versify ) then (
                    let $dup-name as xs:string := $node/ldse:input/@name
                    let $input as element(ldse:input) := ( $form//ldse:input[@name = $dup-name and @type != "duplicate"], $form//element()[@name = $dup-name and ldse:input/@type != "duplicate"]/ldse:input )[1]
                    let $children as item()* := getInputValue($input, $file, (), fn:true())
                    return (
                        typeswitch ( $children )
                        case element() return (
                            if ( fn:exists($children/@data-id) ) then (
                                $children
                            ) else ( dispatchStructure($file, $node/node(), $index, $id, $item-path, $versify, $form) )
                        )
                        default return ( $children )
                    )
                ) else ( dispatchStructure($file, $node/node(), $index, $id, $item-path, $versify, $form) )
            }
        let $new-element as element()* :=
            if ( fn:not(fn:deep-equal($curr-element, $new-element)) and fn:empty($new-element/@translation) and $versify ) then (
                compareElements($new-element, $curr-element)
            ) else ( $new-element )
        return $new-element
    )
};

declare function getUniqueId($node as element(), $id as xs:string, $i as xs:int, $count as xs:int) as xs:string {
    let $new-id as xs:string := if ( $count < 10 ) then ( fn:concat(fn:local-name($node), '-', $id, '-', $i) ) else ( fn:concat(fn:local-name($node), '-', $id, '-', $i, '-', $i) )
    return (
        if ( fn:empty(map:get($vers-map, $new-id)) ) then (
            map:put($vers-map, $new-id, $new-id), $new-id
        ) else ( getUniqueId($node, $id, $i + 10, $count + 1) )
    )
};

declare function getUniqueId($node as element(), $id as xs:string, $i as xs:int, $count as xs:int, $new-i as xs:int, $new-child-index as xs:string?) as xs:string {
    let $new-id as xs:string := if ( $count < 10 ) then ( fn:concat(fn:local-name($node), '-', $id, '-', $i, "-", $new-i, $new-child-index) ) else ( fn:concat(fn:local-name($node), '-', $id, '-', $i, "-", $new-i, $new-child-index, '-', $i) )
    return (
        if ( fn:empty(map:get($vers-map, $new-id)) ) then (
            map:put($vers-map, $new-id, $new-id), $new-id
        ) else ( getUniqueId($node, $id, $i + 10, $count + 1, $new-i, $new-child-index) )
    )
};

declare function getElementPath($node as element(), $file as element()?, $index as xs:string?) {
    let $path as xs:string := fn:replace(xdmp:path($node), "ldse:", "*:")
    let $path as xs:string := fn:replace($path, "\*:dynamic-xml", "")
    let $path as xs:string := fn:substring-after($path, "structure")
    return (
        let $node as element()? :=
            if ( fn:exists($index) and $index castable as xs:int ) then (
                util:unpath($file, $path)[xs:int($index)]
            ) else (
                util:unpath($file, $path)
            )
        return (
            let $path as xs:string := fn:substring-after($path, fn:local-name($file))
            return (
                if ( fn:empty($node) ) then (
                    if ( fn:exists($index) and $index castable as xs:int ) then (
                        util:unpath($file, $path)[xs:int($index)]
                    ) else (
                        util:unpath($file, $path)
                    )
                ) else ( $node )
            )
        )
    )
};

(: $dynamicXml should be as element(dynamic-xml) or element(dynamic-form-ref) :)
declare function getDynamicXmlValues($dynamicXml as element(), $file as element()?, $index as xs:string?, $id as xs:string, $parent as xs:string?, $versify as xs:boolean) as element()* {
    let $name as xs:string := if (fn:exists($dynamicXml/@name)) then (xs:string($dynamicXml/@name)) else (util:sanitize-uri($dynamicXml/@title))
    let $name as xs:string := if (fn:exists($index)) then (fn:concat($name, '-', $index)) else ($name)
    let $childs as xs:string* :=
        for $child as xs:string in xdmp:get-request-field(fn:concat($name, '-child'))
        where $child
        return (xs:string($child))
    let $inner-index as xs:string := if ( fn:exists($index) ) then ( fn:concat($index, '-') ) else ( "" )
    return (
        for $i as xs:string at $child-i in $childs
        return (
            dispatchStructure($file, $dynamicXml/node(), fn:concat($inner-index, $i), $id, $parent, $versify )
        )
    )
};

declare function getDynamicXmlValues($dynamicXml as element(), $file as element()?, $index as xs:string?, $id as xs:string, $parent as xs:string?, $versify as xs:boolean, $form as element(ldse:formTemplate)) as element()* {
    let $name as xs:string := if (fn:exists($dynamicXml/@name)) then (xs:string($dynamicXml/@name)) else (util:sanitize-uri($dynamicXml/@title))
    let $name as xs:string := if (fn:exists($index)) then (fn:concat($name, '-', $index)) else ($name)
    let $childs as xs:string* :=
        for $child as xs:string in xdmp:get-request-field(fn:concat($name, '-child'))
        where $child
        return (xs:string($child))
    let $inner-index as xs:string := if ( fn:exists($index) ) then ( fn:concat($index, '-') ) else ( "" )

    return (
        for $i as xs:string at $child-i in $childs
        return (
            dispatchStructure($file, $dynamicXml/node(), fn:concat($inner-index, $i), $id, $parent, $versify, $form )
        )
    )
};

declare function getInputValue($input as element(ldse:input), $file as element()?, $index as xs:string?, $versify as xs:boolean) as item()* {
    let $name as xs:string? := buildInputName($input, $index)
    let $value as item()* := trim($file, $input, $index, xdmp:get-request-field($name, ""))
    return (
        if ( $input/@type = "wysiwyg" and $versify ) then (
            for $item at $new-i in valueOptions($file, $input, $value, $index)[. != "&#10;"]
            where fn:not($item = "&#10;")
            return (
                $item
            )
        ) else ( valueOptions($file, $input, $value, $index) )
    )
};

declare function getInputValue($input as element(ldse:input), $file as element()?, $index as xs:string?) as item()* {
    getInputValue($input, $file, $index, fn:false())
};

declare function getInputValue($input as element(ldse:input), $file as element()?, $index as xs:string?, $id as xs:string, $i as xs:int, $parent as xs:string?, $versify as xs:boolean, $form as element(ldse:formTemplate)) as item()* {
    let $types-map as map:map := map:map()
    let $name as xs:string? := buildInputName($input, $index)
    let $value as item()* := trim($file, $input, $index, xdmp:get-request-field($name, ""))
    return (
        if ( $input/@type = "wysiwyg" and $versify ) then (
            let $items :=
                for $item in valueOptions($file, $input, $value, $index)
                return (
                    typeswitch( $item )
                    case element() return ( $item )
                    default return ()
                )
            return (
                getTrueIndexAndXpath($items, $file, $id, $i, (), $parent, $types-map)
            )
        ) else ( valueOptions($file, $input, $value, $index, $id, $i, $parent, $versify) )
    )
};

declare function get-duplicate-values(
    $node as element(),
    $newXml as element(),
    $form as element(ldse:formTemplate),
    $type as xs:string
) as item()* {
    let $form-node as element(ldse:input) := $form//ldse:input[@name = $node/@name and fn:not(@type = 'duplicate')]
    let $path as xs:string := fn:substring-before(fn:substring-after(fn:replace(xdmp:path($form-node), 'ldse:', ''), '/structure'), '/input')
    let $value as item()* := dynamicXpath($newXml, $path)

    return (
        if ( fn:exists($value) ) then (
            $value/node()
        ) else ( dynamicXpath($newXml, fn:substring-after($path, fn:tokenize($path, '/')[2]))/node() )
    )
};

declare function build-xml(
    $file as element()?,
    $nodes as element(),
    $newXml as element(),
    $form as element(ldse:formTemplate)
) as item()* {
    for $node in $nodes/node()
    return (
        typeswitch ( $node )
        case element() return (
            let $input as element(ldse:input)? := $form//ldse:input[@name = $node/@duplicate and fn:not(@type = "duplicate")]
            let $form-node as element()? := $form//node()[fn:name(.) = fn:name($node) and ldse:input/@name = $input/@name]
            let $item-options as xs:string? := $form-node/ldse:input/@options

            return (
                if ( fn:exists($input) and fn:exists($node/@duplicate) and fn:not(fn:contains($item-options, "constant")) ) then (
                    element { fn:name($node) } {
                        $node/@*,
                        let $path as xs:string := fn:substring-before(fn:substring-after(fn:replace(xdmp:path($input), 'ldse:', ''), fn:local-name($newXml)), '/input')
                        let $value as item()* := util:unpath($newXml, $path)/node()
                        return (
                            valueOptions($file, $input, $value, ())
                        )
                    }
                ) else (
                    element { fn:name($node) } {
                        $node/@*,
                        build-xml($file, $node, $newXml, $form)
                    }
                )
            )
        )
        case text() return ( $node )
        default return (
            $node
        )
    )
};

declare function getTrueIndexAndXpath($items as item()*, $file as element()?, $id as xs:string, $i as xs:int, $child-index as xs:int?, $parent as xs:string?, $types-map as map:map) {
    for $item at $new-i in $items
    return (
        let $get as xs:int? := map:get($types-map, fn:local-name($item))
        let $count as xs:int := if ( fn:exists($get) ) then ( $get + 1 ) else ( 1 )
        let $put := map:put($types-map, fn:local-name($item), $count)

        return (
            typeswitch ( $item )
            case element() return (
                if ( fn:local-name($item) = 'div' and fn:exists($item/node()) ) then (
                    let $curr-element as element()? := ( $file//element()[@data-id = $item/@data-id], util:unpath($file, $item/@xpath) )[1]
                    let $ele-path as attribute()? :=
                        let $path := xdmp:path(util:strip-namespaces($item))
                        let $node := if ( fn:exists($new-i) ) then ( fn:concat($parent, $path, "[", $new-i, "]") ) else ( fn:concat($parent, $path) )
                        return ( attribute xpath { $node } )
                    let $new-element as element() :=
                        element { fn:node-name($item) } {
                            $item/@* except $item/(@xpath|@index),
                            attribute index { $new-i },
                            if ( fn:empty($item/@data-id) ) then (
                                let $new-child-index := if ( fn:exists($child-index) ) then ( "-" || $child-index ) else ()
                                return ( attribute data-id { getUniqueId($item, $id, $i, 0, $new-i, $new-child-index) } )
                            ) else (),
                            $ele-path,
                            getTrueIndexAndXpath($item/node(), $file, $id, $i, (), $parent, $types-map)
                        }
                    return (
                        if ( fn:empty($new-element/@translation) ) then (
                            compareElements($new-element, $curr-element)
                        ) else ( $new-element )
                    )
                ) else ( valueUpdateForVersification($item, $file, $id, $i, $count, (), $parent, $new-i) )
            )
            default return ( valueUpdateForVersification($item, $file, $id, $i, $count, (), $parent, $new-i) )
        )
    )
};

(: If wysiwyg input and versification is on we need to add data-id attributes to all elements in the wysiwyg and determine if translation ready :)
declare function valueUpdateForVersification($item as item(), $file as element()?, $id as xs:string, $i as xs:int, $new-i as xs:int, $child-index as xs:int?, $parent as xs:string?, $index as xs:int) {
    typeswitch ( $item )
    case element() return (
        let $curr-element as element()? := ( $file//element()[@data-id = $item/@data-id], util:unpath($file, $item/@xpath) )[1]
        let $ele-path as attribute()? :=
            let $path := xdmp:path(util:strip-namespaces($item))
            let $node := if ( fn:exists($new-i) ) then ( fn:concat($parent, $path, "[", $new-i, "]") ) else ( fn:concat($parent, $path) )
            return ( attribute xpath { $node } )
        let $new-element as element() :=
            element { fn:node-name($item) } {
                $item/@* except $item/(@xpath|@index),
                attribute index { if ( fn:local-name($item) = ('li', 'tbody', 'tr', 'td') ) then ( $new-i ) else ( $index ) },
                if ( fn:empty($item/@data-id) ) then (
                    let $new-child-index := if ( fn:exists($child-index) ) then ( "-" || $child-index ) else ()
                    return ( attribute data-id { getUniqueId($item, $id, $i, 0, $new-i, $new-child-index) } )
                ) else (),
                $ele-path,
                if ( fn:not(fn:local-name($item) = ( "p", 'li', 'table' )) ) then (
                    for $item-child at $ci in $item/node()
                    return ( valueUpdateForVersification($item-child, $file, $id, $i, $ci, $child-index, $ele-path, $index) )
                ) else ( $item/node() )
            }
        return (
            if ( fn:empty($new-element/@translation) ) then (
                compareElements($new-element, $curr-element)
            ) else ( $new-element )
        )
    )
    default return ( $item )
};

declare function compareElements($new-element as element(), $current as element()?) as element() {
    cleanCheck($new-element, $current)
};

declare function cleanCheck(
    $new-element as element(),
    $current as element()?
) as element() {
    let $update-index as attribute()? := if ( fn:not($new-element/@index = $current/@index) and fn:exists($new-element/@index) ) then ( attribute update-index { 'true' } ) else ()
    let $new := util:renamespace(element { fn:local-name($new-element) } { $new-element/@* except $new-element/(@index|@data-id|@translation|@update-index|@xpath), $new-element/node() }, "")
    let $curr := util:renamespace(if ( fn:exists($current) ) then ( element { fn:local-name($current) } { $current/@* except $current/(@index|@data-id|@translation|@update-index|@xpath), $current/node() } ) else ( $current ), "")
    let $quote1 := fn:replace(fn:replace(fn:normalize-space(xdmp:quote($new)), '> ', '>'), ' <', '<')
    let $quote2 := fn:replace(fn:replace(fn:normalize-space(xdmp:quote($curr)), '> ', '>'), ' <', '<')

    return (
        if ( ( fn:not($quote1 = $quote2) and fn:not(fn:deep-equal($new, $curr)) ) or fn:not($new = $curr) ) then (
            addAttributes($new-element, $update-index, fn:true())
        ) else if ( fn:local-name($new-element) = ( 'ul', 'ol' ) ) then (
            if ( fn:not(fn:deep-equal($new, $curr)) and fn:not($quote1 = $quote2) ) then (
                addAttributes($new-element, $update-index, fn:true())
            ) else ( addAttributes($new-element, $update-index, fn:false()) )
        ) else if ( fn:local-name($new-element) = ( 'p', 'div', 'h1', 'h2', 'h3', 'h4', 'table', 'li' ) ) then (
            if ( ( fn:not($quote1 = $quote2) and fn:not(fn:deep-equal($new, $curr)) ) or fn:not($new = $curr) ) then (
                addAttributes($new-element, $update-index, fn:true())
            ) else ( addAttributes($new-element, $update-index, fn:false()) )
        ) else (
            if ( fn:not(fn:deep-equal($new, $curr)) and fn:not($quote1 = $quote2) ) then (
                addAttributes($new-element, $update-index, fn:true())
            ) else ( addAttributes($new-element, $update-index, fn:false()) )
        )
    )
};

declare function addAttributes($new-element as element(), $update-index as attribute()?, $add-translate as xs:boolean) {
    let $new as element() := if ( $add-translate and fn:empty($new-element/@translation) ) then ( mem:node-insert-child($new-element, attribute translation { "ready" }) ) else ( $new-element )
    return (
        if ( fn:exists($update-index) and fn:not($new/@translation) and fn:empty($new/@update-index) ) then (
            mem:node-insert-child($new, $update-index)
        ) else ( $new )
    )
};

declare function valueOptions($file as element()?, $input as element(ldse:input), $value as xs:string*, $index as xs:string?) as item()* {
    if (fn:exists($input/@options)) then (
        valueOptions($file, $input, $index, $value, fn:tokenize($input/@options, ','))
    ) else ( $value )
};

declare function valueOptions($file as element()?, $input as element(ldse:input), $value as xs:string*, $index as xs:string?, $id as xs:string, $i as xs:int, $parent as xs:string?, $versify as xs:boolean) as item()* {
    if (fn:exists($input/@options)) then (
        valueOptions($file, $input, $index, $value, fn:tokenize($input/@options, ','), $id, $i, $parent, $versify)
    ) else ( $value )
};

declare function getId($file as element()) as xs:string? {
    ldsemeta:get-document-id($file)
};

declare function buildWorkFlowCheckboxes($file as element()?, $form as element(ldse:formTemplate), $locale as xs:string) as element(dl)? {
    if ($locale eq 'eng' and fn:not($form/@translate eq 'false') ) then (
        <dl>
            <dt></dt>
            <dd class="options-vertical">
                <fieldset id="translate-checkbox">
                    <span class="ldse-option">
                        {buildTranslateCheckbox($file)}
                        <label for="translateCheckbox">This item requires translation</label>
                    </span>
                    { buildSentDate($file) }
                </fieldset>
            </dd>
        </dl>
    ) else ()
};

declare function buildFuturePublish($file as element()?, $form as element(ldse:formTemplate), $locale as xs:string) as element(dl)* {
    let $schedule-publish as element(ldse:schedule-publish)? := ldsemeta:get-schedule-publish($file)

    let $date as xs:date? := xs:date($schedule-publish/@date)
    let $time as xs:time? := xs:time($schedule-publish/@time)
    let $hour as xs:integer? := fn:hours-from-time($time)
    let $min as xs:integer? := fn:minutes-from-time($time)
    return (
        <dl>
            <dt>Future Publish Date (select date to publish in future even if it is today. Date is required when scheduling)</dt>
            <dd>
                <input name="futureDate" id="futureDate" class="datePicker lg" value="{$date}" placeholder="YYYY-MM-DD"><b class="ldse-icon-calendar" onclick="$('#futureDate').focus();"></b></input>
            </dd>
        </dl>,
        <dl>
            <dt>
                <label for="futureHour">Military Time (Hour Minute)</label>
            </dt>
            <dd>
                <select name="futureHour" id="futureHour">{
                    for $h as xs:integer in 0 to 23
                    let $value as xs:string := if ($h < 10 ) then ( fn:concat("0", $h) ) else (xs:string($h))
                    return (
                        element option {
                            if ($h eq $hour) then (
                                attribute selected {"selected"}
                            ) else (),
                            attribute value {$value},
                            $value
                        }
                    )
                }</select>
                <select name="futureMin" id="futureMin">{
                    for $m as xs:integer in 0 to 59
                    let $value as xs:string := if ($m < 10 ) then ( fn:concat("0", $m) ) else (xs:string($m))
                    return (
                        element option {
                            if ($m eq $min) then (
                                attribute selected {"selected"}
                            ) else (),
                            attribute value {$value},
                            $value
                        }
                    )
                }</select>
            </dd>
        </dl>
    )
};

declare function buildFutureUnpublish($file as element()?, $form as element(ldse:formTemplate), $locale as xs:string) as element(dl)* {
    let $schedule-unpublish as element(ldse:schedule-unpublish)? := ldsemeta:get-schedule-unpublish($file)

    let $date as xs:date? := xs:date($schedule-unpublish/@date)
    let $time as xs:time? := xs:time($schedule-unpublish/@time)
    let $hour as xs:integer? := fn:hours-from-time($time)
    let $min as xs:integer? := fn:minutes-from-time($time)
    return (
        <dl>
            <dt class="margin-top-sm">Future Unpublish Date (select date to unpublish in future even if it is today. Date is required when scheduling)</dt>
            <dd>
                <input name="unpubFutureDate" id="unpubFutureDate" class="datePicker lg" value="{$date}" placeholder="YYYY-MM-DD"><b class="ldse-icon-calendar" onclick="$('#unpubFutureDate').focus();"></b></input>
            </dd>
        </dl>,
        <dl>
            <dt>
                <label for="unpubFutureHour">Military Time (Hour Minute)</label>
            </dt>
            <dd>
                <select name="unpubFutureHour" id="unpubFutureHour">{
                    for $h as xs:integer in 0 to 23
                    let $value as xs:string := if ($h < 10 ) then ( fn:concat("0", $h) ) else (xs:string($h))
                    return (
                        element option {
                            if ($h eq $hour) then (
                                attribute selected {"selected"}
                            ) else (),
                            attribute value {$value},
                            $value
                        }
                    )
                }</select>
                <select name="unpubFutureMin" id="unpubFutureMin">{
                    for $m as xs:integer in 0 to 59
                    let $value as xs:string := if ($m < 10 ) then ( fn:concat("0", $m) ) else (xs:string($m))
                    return (
                        element option {
                            if ($m eq $min) then (
                                attribute selected {"selected"}
                            ) else (),
                            attribute value {$value},
                            $value
                        }
                    )
                }</select>
            </dd>
        </dl>
    )
};

declare function buildTranslateCheckbox($file as element()?) as element(input) {
    element input {
        attribute type {'checkbox'},
        attribute onchange {"ICE.workflowCheck(this)"},
        attribute id {'translateCheckbox'},
        attribute name {'to-translate'},
        attribute value {'true'},
        if ( ldsemeta:get-translation-event-status($file) eq 'ready' ) then (
            attribute checked {"checked"}
        ) else (),
        if(fn:not(ac:has-permission("ldse:translation-checkbox", ldsemeta:get-document-locale($file), ldsemeta:get-document-uri($file))))
        then attribute disabled {"disabled"}
        else ()
    }
};

declare function buildSentDate($file as element()?) as element(span)? {
    let $date as xs:string? := fn:substring-before(ldsemeta:get-translation-sent($file)/@date, "T")
    where fn:exists($date) and $date ne '&nbsp;' and $date ne ''
    return (
        <span>Sent: { $date }</span>
    )
};
(:Shorter function that assumes things are in variables:)
declare function getDbPath($origFile as element()?, $newXml as element(), $form as element(ldse:formTemplate)) as xs:string {
    getDbPath($origFile, $newXml, $form, getVariable('locale'), getVariable('action'), getVariable('id'))
};
declare function getDbPath($orig-file as element()?, $newXml as element()?, $form as element(ldse:formTemplate)?, $locale as xs:string, $action as xs:string, $id as xs:string) as xs:string {
    let $fileExists as xs:boolean := fn:exists($orig-file) and xdmp:node-uri($orig-file) != ''
    return (
        if ( $fileExists and ($action eq 'edit' or fn:local-name($orig-file) eq 'custom-page')) then (
            xdmp:node-uri($orig-file)
        ) else (
            let $uri as xs:string? := (getVariable('uri'),$newXml/@uri)[1]
            let $uri as xs:string? := if (fn:contains($uri, '#')) then (fn:substring-before($uri, '#')) else ($uri)
            let $uri as xs:string? := if (fn:starts-with($uri, getVariable('sharedPrefix'))) then (fn:substring-after($uri, getVariable('sharedPrefix'))) else ($uri)
            let $folderSufix as xs:string? := $form/ldse:folder
            let $filePrefix as xs:string? := if (fn:starts-with($form/ldse:file-prefix, "$")) then (getVariable(fn:substring-after($form/ldse:file-prefix, "$"))) else ($form/ldse:file-prefix)
            return (
                core:build-db-path($uri, $locale, $id, $newXml,
                        <options>
                            <folder>{ $folderSufix }</folder>
                            <file-prefix>{ $filePrefix }</file-prefix>
                            <use-lang-folder>{ $form/ldse:use-lang-folder }</use-lang-folder>
                        </options>
                )
            )
        )
    )
};

(: INPUT OPTION PROCESSING FUNCTIONS :)
declare function valueOptions($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*, $options as xs:string*) as item()* {
    let $functions as xdmp:function* :=
        for $option as xs:string in $options
        let $option as xs:string? := if (fn:starts-with($option, 'limit:')) then ('limit') else ($option)
        where $option ne ''
        return getFunction($option)
    return (
        optionFunctionChain($functions, $file, $input, $index, $value)
    )
};

(: INPUT OPTION PROCESSING FUNCTIONS :)
declare function valueOptions($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*, $options as xs:string*, $id as xs:string, $i as xs:int, $parent as xs:string?, $versify as xs:boolean) as item()* {
    let $functions as xdmp:function* :=
        for $option as xs:string in $options
        let $option as xs:string? := if (fn:starts-with($option, 'limit:')) then ('limit') else ($option)
        where $option ne ''
        return getFunction($option)
    return (
        for $update at $i in optionFunctionChain($functions, $file, $input, $index, $value)
        return (
            typeswitch($update)
            case element() return (
                if ( $versify ) then (
                    element { fn:node-name($update) } {
                        if ( fn:empty($update/@data-id) ) then (
                            let $id as xs:string := getUniqueId($update, $id, $i, 0)
                            let $put := map:put($vers-map, $id, $id)
                            return (
                                attribute data-id { $id }
                            )
                        ) else (
                            $update/@data-id
                        ),
                        if ( fn:empty($update/@index) ) then ( attribute index { $i } ) else (),
                        attribute xpath { $parent || xdmp:path($update) || '[' || $i || ']' },
                        if ( fn:empty($update/@translate) ) then ( attribute translate { 'ready' } ) else (),
                        $update/@*[fn:not(fn:local-name(.) eq ('data-id', 'index', 'xpath'))],
                        $update/node()
                    }
                ) else ( $update )
            ) default return ($update)
        )
    )
};

declare function optionFunctionChain($functions as xdmp:function*, $file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as item()* {
    if (fn:count($functions) eq 0) then (
        $value
    ) else (
        optionFunctionChain(fn:subsequence($functions, 2), $file, $input, $index, xdmp:apply($functions[1], $file, $input, $index, $value))
    )
};

declare function static($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as item()* {
    $file/xdmp:value(xs:string($input/@xpath))
};

declare function constant($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as item()* {
    let $xmlValue as item()* := dynamicXpath($file, xs:string($input/@xpath))
    return (
        if (fn:empty($xmlValue) or getVariable('action') eq 'add') then (
            $value
        ) else (
            $xmlValue
        )
    )
};

declare function trim($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()) as item()* {
    if ($value instance of xs:string) then (
        functx:trim($value)
    ) else ($value)
};

declare function quote($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()) as item()* {
    xdmp:quote($value)
};

declare function tidy($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as item()* {
    stripJavascript($file, $input, $index, ice:tidy($value))
};

declare variable $namespace-regex as xs:string := fn:concat('xmlns="[^"]*?"', '|' , "xmlns='[^']*?'");

declare function xml($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as item()* {
    util:renamespace( stripJavascript($file, $input, $index, ice:html-tidy( fn:replace($value, $namespace-regex, '') ) ), "")
};

declare function html($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as item()* {
    util:renamespace( stripJavascript($file, $input, $index, ice:html-tidy( fn:replace($value, $namespace-regex, '') ) ), "http://www.w3.org/1999/html")
};

declare function xhtml($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as item()* {
    util:renamespace( stripJavascript($file, $input, $index, ice:html-tidy( fn:replace($value, $namespace-regex, '') ) ), "http://www.w3.org/1999/xhtml")
};

declare function noNamespaceParas($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as item()* {
    util:renamespace( stripJavascript($file, $input, $index, ice:html-tidy( fn:replace($value, $namespace-regex, '') ) ), "")
};

declare function sanitize($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as xs:string? {
    if ( fn:exists($value[2][. != '']) ) then (
        util:sanitize-uri($value[2])
    ) else ( util:sanitize-uri($value[1]) )
};

declare function stripNamespaces($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as item()* {
    util:strip-namespaces($value)
};

declare function escapeChars($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as xs:string? {
    util:escape-chars($value)
};

declare function forceDate($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as xs:string? {
    let $value := if ( $value castable as xs:date ) then ( fn:adjust-date-to-timezone(xs:date($value), ()) ) else ( $value )
    let $parsedDate as item() := util:convert-to-date-time(xs:string($value))
    let $date as item() := if (xs:string($parsedDate) = "invalid format") then ( fn:current-dateTime() ) else ( $parsedDate )
    return (
        fn:format-dateTime($date, "[Y]-[M01]-[D01]")
    )
};

declare function upperCase($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as xs:string? {
    fn:upper-case($value)
};

declare function lowerCase($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as xs:string? {
    fn:lower-case($value)
};

declare function getIndex($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as xs:string? {
    $index
};

declare function variable($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as item()* {
    getVariable(fn:substring-after($input/@value, '$'))
};

declare function limit($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as item()* {
    let $limit as xs:string := fn:substring-after(fn:tokenize($input/@options, ',')[fn:starts-with(., 'limit')],':')
    return (
        if (fn:not($value instance of text())) then (
            $value/xdmp:value(fn:concat('//', $limit))
        ) else ($value)
    )
};

declare function wysiwygToldswebml($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as item()* {
    ice:wysiwygToldswebml($value, getVariable('uri'))
};

declare function stripJavascript($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as item()* {
    if ($value instance of text()) then (
        fn:replace($value,'(<script>[\w\W]*?</script>|%3Cscript%3E[\w\W]*?%3C%2Fscript%3E)','')
    ) else (
        stripJavascript(element strip { $value })/node()
    )
};

declare function stripJavascript($node as node()) as node() {
    if ( fn:exists($node//(xhtml:script|script)) ) then (
        stripJavascript(mem:node-delete($node//(xhtml:script|script)[1]))
    ) else ($node)
};

declare function imageUpload($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as item()* {
    let $name as xs:string := buildInputName($input, $index)
    let $uploadName as xs:string := fn:concat($name, '-upload')
    let $imageFileName as xs:string? := xdmp:get-request-field-filename($uploadName)
    let $imageFileContents as item()? := xdmp:get-request-field($uploadName)

    return (
        if (fn:exists($imageFileName)) then (
            let $imageBase as xs:string := $settings:bcs-path
            let $uri as xs:string := getVariable('uri')
            let $urlPath as xs:string := if (fn:ends-with($uri, '/')) then ($uri) else (fn:concat($uri, '/'))
            let $site as xs:string := fn:concat('/', getVariable('site'))
            let $imagePath as xs:string :=
                if (fn:starts-with($urlPath, $site)) then (
                    fn:concat($urlPath, "images/", $imageFileName)
                ) else (
                    fn:concat($site, $urlPath, "images/", $imageFileName)
                )
            let $save as item()* := fsDoc:save(fn:concat($imageBase, "/content", $imagePath), $imageFileContents)
            return (core:get-display-uri($imagePath))
        ) else ($value)
    )
};

declare function pdfUpload($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as item()* {
    let $locale as xs:string := getVariable('locale')
    let $name as xs:string := buildInputName($input, $index)
    let $uploadName as xs:string := fn:concat($name, '-upload')
    let $pdfFileName as xs:string? := xdmp:get-request-field-filename($uploadName)
    let $pdfFileContents as item()? := xdmp:get-request-field($uploadName)
    return (
        if (fn:exists($pdfFileName) and fn:ends-with($pdfFileName, '.pdf')) then (
            let $base as xs:string := $settings:bcs-path
            let $uri as xs:string := getVariable('uri')
            let $urlPath as xs:string := if (fn:ends-with($uri, '/')) then ($uri) else (fn:concat($uri, '/'))
            let $site as xs:string := fn:concat('/', getVariable('site'))
            let $pdfPath as xs:string :=
                if (fn:starts-with($urlPath, $site)) then (
                    fn:concat($urlPath, "pdf/", $pdfFileName)
                ) else (
                    fn:concat($site, $urlPath, "pdf/", $pdfFileName)
                )

            let $fullPath as xs:string := fn:concat($base, "/content", $pdfPath)
            let $save as item()* := fsDoc:save($fullPath, $pdfFileContents)

            let $pdfXml as element(pdf)? := cpfCommon:buildPDFXml($fullPath)
            let $pdfXml as element(pdf)? :=
                if (fn:exists($pdfXml/@locale)) then (
                    mem:node-replace($pdfXml/@locale, attribute locale {$locale})
                ) else (
                    mem:node-insert-child($pdfXml, attribute locale {$locale})
                )
            let $pdfXml as element(pdf)? :=
                if (fn:exists($pdfXml/@id)) then (
                    $pdfXml
                ) else (
                    mem:node-insert-child($pdfXml, attribute id {util:generate-unique-id($pdfXml/@locale)})
                )
            let $xmlPath as xs:string := getDbPath($pdfXml, $pdfXml, (), $locale, 'add', xs:string($pdfXml/@id))
            let $xmlSave as item()* :=
                if (fn:exists($pdfXml)) then (
                    core:save-file("preview", $xmlPath, $pdfXml, ())
                ) else ()
            return ($pdfPath)
        ) else ($value)
    )
};
(: END OF INPUT OPTION PROCESSING FUNCTIONS :)


declare function getLanguagePath($locale as xs:string, $deprecated-context as xs:string) as xs:string {
    let $langName as xs:string? := util:get-full-language-name-by-locale($locale)
    return (
        $DEPRECATED,
        if (fn:exists($langName)) then (
            fn:lower-case($langName)
        ) else (
            fn:concat('country-sites/',$locale)
        )
    )
};

declare function set-permalink($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as xs:string? {
    let $val as xs:string? := setVariable("uri", $value)
    return $value
};

declare function multi-select-options($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as element()* {
    for $values as xs:string in $value
    let $new-element as element() :=
        element { fn:node-name($input/ldse:child/element()) } {
            attribute value { $values },
            $values
        }
    return util:strip-namespaces($new-element)
};

declare function build-action-groups(
    $form as element(ldse:formTemplate)?
) as element(button-groups) {
    let $remove-buttons as xs:string* := fn:tokenize($form/@remove-buttons, ',')[. != '']

    return (
        <button-groups> {
            for $element as element() in ($settings:action-groups/ldse:group, $settings:actions)
            where ac:has-permission($element/@permission, map:get($map, "$locale"), map:get($map, "$uri")) or fn:not($element/@permission)
            order by xs:integer(($element/@seq[fn:not(. = "")], 9999)[1])
            return (
                typeswitch($element)
                case element(ldse:group) return build-action-group($settings:actions[@group = $element and fn:not(@name = $remove-buttons)], $element)
                case element(ldse:action) return build-action-group($element[fn:not(@group = $settings:action-groups/ldse:group) and fn:not(@name = $remove-buttons)], $element)
                default return ()
            )
        } </button-groups>
    )
};

declare function build-action-group(
    $actions as element(ldse:action)*,
    $element as element()
) as element(button-group)? {
    if ( fn:exists($actions) ) then (
        let $button-group as element(button-group) :=
            <button-group>
                {
                    for $action as element(ldse:action) in $actions
                    let $is-valid as xs:boolean :=
                        if ( fn:exists($action//ldse:check) ) then (
                            action-is-valid($action)
                        ) else (
                            check-permissions($action) or fn:not($action/@permission)
                        )
                    let $disabled as attribute()? :=
                        if ( fn:not($is-valid) and $action/@not-valid = "disable" ) then (
                            attribute disabled {"disabled"}
                        ) else ()
                    order by fn:number(($action/@seq[fn:not(. = "")], 9999)[1])
                    return
                        if ( (fn:not($is-valid) and $action/@not-valid = "disable") or $is-valid ) then (
                            <button> {
                                attribute id { ($action/@id/fn:string(.), $action/@name/fn:string(.))[1] },
                                attribute class { fn:string-join((($action/@class, $element[fn:not(@class = $action/@class)]/@class)[1], $action/@icon), " ") },
                                attribute status { fn:string($action/@name) },
                                ($action/@onclick, $element[fn:not(@onclick = $action/@onclick)]/@onclick)[1],
                                $disabled,
                                $action/@* except $action/(@id|@class|@status|@onclick|@icon|@seq|@title|@not-valid|@permission|@group),
                                $action/@title/fn:string(.)
                            } </button>
                        ) else ()
                }
            </button-group>

        return $button-group[button]
    ) else ()
};

declare function check-permissions($action as element()) as xs:boolean
{
    let $permissions as xs:string* := fn:tokenize($action/@permission/fn:string(.), ",")
    let $result as xs:boolean* :=
        for $permission as xs:string in $permissions
        return ac:has-permission($permission, map:get($map, "$locale"), map:get($map, "$uri"))
    return fn:not(fn:false() = $result)
};

declare function action-is-valid($action as element(ldse:action)?) as xs:boolean
{
    if( fn:exists($action/ldse:checks/*) )
    then ice:validate-checks(<ldse:and>{$action/ldse:checks/*}</ldse:and>, $variables)
    else fn:true()
};

declare function prebuild-component(
        $locale as xs:string,
        $uri as xs:string,
        $country as xs:string?,
        $location as xs:string?,
        $component-names as xs:string?,
        $parent-id as xs:string?,
        $options as xs:string
) as item()* {
    let $locale as xs:string := if ( fn:exists($country) and fn:not($country = "") ) then ( fn:concat($locale, '-', $country) ) else ( $locale )
    let $custom-page as element(custom-page)? := get-custom-page($uri, $locale, ())
    let $custom-page-path as xs:string? := $custom-page/fn:base-uri(.)
    let $username as xs:string? := ac:getUserName()
    let $userId as xs:string? := ac:getPersonId()
    let $custom-contents as element()* := $custom-page/content/element()
    let $id as xs:string? := newId($locale)
    let $site as xs:string? := ldsemeta:get-document-site($custom-page)
    let $source as xs:string? := ldsemeta:get-document-source($custom-page)
    let $options as xs:string := fn:replace($options, "%2C", ",")
    let $options as xs:string := fn:replace($options, "%3A", ":")
    let $options as xs:string := fn:replace($options, "%2F", "/")
    let $options as xs:string := fn:replace($options, "%7C", "|")
    let $new-xml as element(component) :=
        element component {
            attribute id { $id },
            attribute its:translate { "no" },
            attribute locale { $locale },
            attribute location { $location },
            attribute parent { $parent-id },
            attribute status { "preview" },
            attribute uri { $uri },
            attribute xml:lang { "" },
            attribute xmlns:its { "http://www.w3.org/2005/11/its" },
            <ldse-meta its:translate="no" xmlns="http://lds.org/code/lds-edit">
                <document env="{$settings:environment}" id="{$id}" locale="{$locale}" source="{($source, $country)[1]}" site="{$site}" status="preview" tgp="0.001" title="Default Title" type="component" uri="{$uri}" words="2"/>
                <created date="{fn:current-dateTime()}" userid="{$userId}" username="{$username}"/>
                <last-modified date="{fn:current-dateTime()}" userid="{$userId}" username="{$username}"/>

                <form-options its:translate="no" xmlns="http://lds.org/code/lds-edit">{
                    for $item as xs:string in fn:tokenize($options, ',')
                    let $tokens as xs:string* := fn:tokenize($item, ':')
                    let $name as xs:string? := $tokens[1]
                    let $value as xs:string? := $tokens[2]
                    where fn:exists($name) and fn:exists($value)
                    return (
                        element {$name} {$value}
                    )
                }</form-options>
                {(:                <form-options its:translate="no">
                    <form>component</form>
                    <location>{$location}</location>
                    <components>{fn:string-join($component-names,"|")}</components>
                </form-options>:)}
            </ldse-meta>,
            element title {
                attribute type { "content" },
                "Default Title"
            },
            element sequence {
                attribute its:translate { "no" },
                attribute type { "hidden" },
                if ( fn:exists($custom-contents) ) then ( fn:count($custom-contents) + 1 ) else ( "1" )
            },
            element component-id {
                attribute its:translate { "no" },
                $component-names
            }
        }
    let $new-xml-path as xs:string? := core:build-db-path($uri, $locale, $id, $new-xml, <options><folder>component</folder><file-prefix>component-</file-prefix></options>)
    let $update-custom-page as item()* := if ( fn:exists($custom-page) ) then ( update-custom-page-content($custom-page, $custom-page-path, $id, $location) ) else ()
    return (
        core:update-file('ldse:preview', $new-xml-path, $new-xml, ())
    )
};

declare function update-custom-page-content($custom-page as element(), $custom-page-path as xs:string, $id as xs:string, $location as xs:string?) as item()* {
    let $new-page as element() := mem:node-insert-child($custom-page/content, <component location="{$location}">{$id}</component>)/*
    return (
        core:document-replace($custom-page, $new-page)
    )
};

declare function buildDefaultSelector($value as item()*) as element(option)* {
    for $input as element() in ( $settings:defaultInputTypes/option, $settings:customInputTypes/ldse:option )
    let $inputVal as xs:string := $input/@val/fn:string()
    order by $inputVal
    return (
        element option {
            if ($inputVal = $value) then (
                attribute selected {"selected"}
            ) else (),
            attribute value {$input/@val},
            $inputVal
        }
    )
};

declare function getFormNames() as element(option)* {
    for $form as element(ldse:formTemplate) in cts:search(/ldse:formTemplate, core:get-filter-query())
    let $formName as xs:string := $form/@name/fn:string()
    order by $formName
    return (
        <option val="{$formName}">{$formName}</option>
    )
};

declare function userRoles($value as item()*) as element(option)* {
    <option value="">Please Select</option>,
    for $role as element(ldse:user-role) in $settings:user-roles
    let $role-name as xs:string := $role/@name/fn:string()
    order by $role-name
    return (
        element option {
            if ($role-name = $value) then (
                attribute selected {"selected"}
            ) else (),
            attribute value {$role-name},
            $role
        }
    )
};

declare function clearNodeCache($origFile as element()?, $newFile as element(), $form as element(ldse:formTemplate)) {
    let $locale as xs:string := getVariable('locale')
    let $uri as xs:string? := getVariable('uri')
    let $url as xs:string? := $settings:node-cache-url
    let $cacheClear := if (($newFile/@status = 'publish') and $url) then (util:http-get(fn:concat($url, '?url=', $uri, '&amp;lang=', $locale), ())) else ()
    return $newFile
};

declare function getTagCheckboxes(
    $input as element(ldse:input),
    $value as item()*
) as element(input)* {
    for $tag as element(tag) in $all-tags
    let $sub-ids as xs:string* := $tag//sub-tag/@id
    return (
        <input value="{$tag/@id}" type="checkbox" data-children="{$sub-ids}" onclick="unClickChildren();">{$tag/tag-name}</input>,
        buildSubTags($tag)
    )
};

declare function customCheckboxes(
    $input as element(ldse:input),
    $value as item()*
) as element()* {
    let $items as item()* :=
        if ( fn:exists($input/@other-elements) ) then (
            let $file as element()? := getVariable('file')
            let $new-value as xs:string? := $file//element()[fn:name(.) = $input/@other-elements]
            return (
                getItems($input, $new-value, (), ())
            )
        ) else ( getItems($input, $value, (), ()) )
    return (
        if ( fn:exists($items) ) then (
            for $item as element() at $index in $items
            let $form-name as xs:string := $item//ldse:form
            let $form as element(ldse:formTemplate) := get-form($form-name)
            let $id as xs:string* := ( ldsemeta:get-document-id($item), $item/@id )[1]
            let $title as xs:string := get-title($item, $form)
            return (
                <input value="{$id}" type="checkbox" id="{$input/@name || $index}">{
                    $input/@name,
                    $title
                }</input>
            )
        ) else (
            <input id="{$input/@name}" type="{$input/@type}" name="{$input/@name}"></input>
        )
    )
};

declare function buildSubTags(
    $tag as element(tag)
) as element(input)* {
    for $subtag as element(sub-tag) in $tag/sub-tags/sub-tag
    return (
        <input value="{$subtag/@id/fn:string()}" type="checkbox" class="subtag" onclick="checkParent('{$tag/@id}');" style="margin-left:25px;">{$subtag/sub-tag-name}</input>
    )
};

declare function processTags(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $value as item()*
) as element()* {
    (: TODO: Check index and xpath attribute creation :)
    for $v as xs:string at $idx in $value
    let $tags as element()* := ( $file/tags/tag )
    let $tag as element()? := $all-tags[@id = $v]
    let $name as xs:string? := $tag/tag-name
    let $new-tags as element()? :=
        if ( fn:exists($tag) ) then (
            element { fn:local-name($tag) } {
                if ( fn:exists($tags[. eq $v]/@data-id) ) then (
                    $tags[. eq $v]/@data-id
                ) else (),
                ( $tag/@id, attribute id { $v } )[1],
                <tag-name>{$name}</tag-name>,
                element sub-tags {
                    get-sub-tags($tag, $value)
                }
            }
        ) else ()
    where fn:normalize-space($v) ne '' and fn:exists($name) and fn:exists($new-tags)
    return (
        if ( fn:not($new-tags = $tags[. = $v]) and fn:empty($tags[. = $v]/@translation) ) then (
            mem:node-insert-child($new-tags, attribute translation { "ready" })
        ) else ( $new-tags )
    )
};

declare function generateId(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $value as item()*
) as xs:string {
    if ( fn:exists($value) and fn:not($value = "") ) then (
        $value
    ) else ( createUniqueId() )
};

declare function createUniqueId() as xs:string {
    let $hash as xs:string :=
        xs:string(
            xdmp:hash64(
                fn:concat(
                    xs:string(xdmp:host()),
                    xs:string(fn:current-dateTime()),
                    xs:string(xdmp:random())
                )
            )
        )
    return (
        util:pad-string($hash, 20, fn:false())
    )
};

declare function buildCustomCheckboxes(
    $input as element(ldse:input),
    $file as element()?,
    $value as item()*,
    $search-val as xs:string?,
    $form as element(ldse:formTemplate)?
) as element()* {
    let $items as element()* := getItems($input, $value, $search-val, $file)
    let $form as element(ldse:formTemplate)? :=
        if ( fn:exists($form) ) then (
            $form
        ) else if ( fn:exists($items) ) then (
            let $form-name as xs:string := $items[1]//ldse:form
            return get-form($form-name)
        ) else ()
    let $options as element()* :=
        for $item as element() at $index in $items
        let $id as xs:string? := ( $item/@id, ldsemeta:get-document-id($item) )[1]
        let $title as xs:string? := get-title($item, $form)
        let $uri-title as xs:string? := util:sanitize-uri($title)
        return (
            if ( $index = 1 ) then (
                <input value="{$id}" id="{$input/@name}" name="{$input/@name}" type="checkbox" uri-title="{$uri-title}">{
                    if ( $id = $value ) then (
                        attribute checked { "checked" }
                    ) else ()
                }</input>,
                <label for="{$input/@name}">{$title}</label>,
                <br/>
            ) else (
                <input value="{$id}" id="{$input/@name || $index}" name="{$input/@name}" type="checkbox" uri-title="{$uri-title}">{
                    if ( $id = $value ) then (
                        attribute checked { "checked" }
                    ) else ()
                }</input>,
                <label for="{$input/@name || $index}">{$title}</label>,
                <br/>
            )
        )

    return (
        if ( fn:exists($options) ) then (
            $options
        ) else (
            <input id="{$input/@name}" type="checkbox"></input>,
            <label for="{$input/@name}"></label>,
            <br/>
        )
    )
};

declare function get-sub-tags(
    $tag as element(tag),
    $values as item()*
) as element(sub-tag)* {
    for $sub-tag as element(sub-tag) in $tag/sub-tags/sub-tag
    where $sub-tag/@id = $values
    return (
        $sub-tag
    )
};

declare function buildCustomSelectOptions(
    $input as element(ldse:input),
    $file as element()?,
    $value as item()*,
    $search-val as xs:string?,
    $form as element(ldse:formTemplate)?
) as element(option)* {
    let $items as item()* :=
        if ( fn:exists($input/@other-elements) and fn:exists($file) ) then (
            let $file as element()? := getVariable('file')
            let $new-value as xs:string := $file//element()[fn:name(.) = $input/@other-elements]
            return (
                getItems($input, $new-value, (), $file)
            )
        ) else ( getItems($input, $value, $search-val, $file) )
    let $form as element(ldse:formTemplate)? :=
        if ( fn:exists($form) ) then (
            $form
        ) else if ( fn:exists($items) ) then (
            let $form-name as xs:string := $items[1]//ldse:form
            return get-form($form-name)
        ) else ()
    let $options as element(option)* :=
        for $item as element() in $items
        let $id as xs:string? := ( $item/@id, ldsemeta:get-document-id($item) )[1]
        let $title as xs:string? := get-title($item, $form)
        let $uri-title as xs:string? := util:sanitize-uri($title)
        return (
            if ( $id = $value ) then (
                <option value="{$id}" selected="selected" uri-title="{$uri-title}">{ $title }</option>
            ) else ( <option value="{$id}" uri-title="{$uri-title}">{ $title }</option> )
        )
    return (
        <option />,
        $options
    )
};

declare function getItems(
    $input as element(ldse:input),
    $value as item()*,
    $search-val as xs:string?,
    $file as element()?
) as element()* {
    let $rootElement as xs:string? := ( $input/ldse:dynamic-options/@root, $input/@root )[1]
    let $attr as xs:string? := ( $input/ldse:dynamic-options/@attribute, $input/@attr )[1]
    let $node-value as xs:string? := ( $input/ldse:dynamic-options/@value, $input/@val )[1]
    let $type as xs:string? := ( $input/ldse:dynamic-options/@type, $input/@content-type )[1]
    let $other-eles as xs:string? := ( $input/ldse:dynamic-options/@other-elements, $input/@other-elements )[1]
    let $value-eles as xs:string? := ( $input/ldse:dynamic-options/@value-elements, $input/@value-elements )[1]
    let $child-eles as xs:string? := ( $input/ldse:dynamic-options/@child-element, $input/@child-element )[1]
    let $file-value as xs:string? :=
        if ( fn:exists($value-eles) and fn:exists($file) ) then (
            $file//element()[fn:name(.) = $value-eles]
        ) else ()

    let $node-value as xs:string? :=
        if ( fn:starts-with($node-value, '$') ) then (
            getVariable( fn:substring-after(xs:string($node-value),'$') )
        ) else ( $node-value )
    return (
        cts:search(fn:collection(),
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName($rootElement), xs:QName('locale'), getVariable('locale'), 'exact'),
                if ( fn:exists($type) ) then (
                    cts:element-attribute-value-query(xs:QName($rootElement), xs:QName('type'), $type, 'exact')
                ) else (),
                if ( fn:exists($attr) and ( fn:exists($node-value) or fn:exists($search-val) ) ) then (
                    cts:element-attribute-value-query(xs:QName($rootElement), xs:QName($attr), ( $node-value, $search-val ), 'exact')
                ) else if ( fn:exists($node-value) ) then (
                    cts:element-value-query(xs:QName($rootElement), $node-value, 'exact')
                ) else (),
                if ( ( fn:exists($other-eles) or fn:exists($value-eles) ) and ( fn:empty($attr) or fn:exists($file) ) ) then (
                    cts:or-query((
                        if ( fn:exists($other-eles) and ( fn:exists($node-value) or fn:exists($value) or fn:exists($search-val) ) ) then (
                            for $element as xs:string in fn:tokenize($other-eles, ',')
                            return (
                                cts:or-query((
                                    cts:element-value-query(xs:QName($element), ( $node-value, $value, $search-val ), 'exact'),
                                    if ( fn:exists($child-eles) ) then (
                                        cts:element-value-query(xs:QName($child-eles), ( $node-value, $value, $search-val ), 'exact')
                                    ) else ()
                                )),
                                if ( fn:exists($file-value) ) then (
                                    cts:element-value-query(xs:QName($element), $file-value, 'exact')
                                ) else ()
                            )
                        ) else ()
                    ))
                ) else ()
            ))
        )/*
    )
};

declare function saveCustomCheckboxes(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $value as item()*
) as element()* {
    for $item as item() in $value
    return (
        element { $input/@child-element/fn:string() } {
            $item
        }
    )
};

declare function custom(
    $input as element(ldse:input),
    $file as element()?,
    $index as xs:string?
) as item()* {
    let $item as element()? := getItems($input, (), (), $file)
    return (
        let $result as xs:string? := ( ldsemeta:get-document-id($item), $item/@id )[1]
        return (
            <input type="hidden" name="{$input/@name}" value="{$result}" />
        )
    )
};

declare function titan-asset-save(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $value as item()*
) {
    let $verify-titan-object-exist :=
        if ( fn:exists($value[1][. != ""]) and fn:exists($value[4][. != ""])) then (
            let $object := api:get-asset-from-media-api($value[1], $value[4])
            return (
                if ( fn:empty($object) ) then (
                    fn:error(fn:concat("Missing-Titan-",$value[4]), $value[1])
                ) else (
                    $object
                )
            )
        ) else ()

    return (
        attribute type {"titanAsset"},
        attribute title { $value[2] },
        attribute thumb { $value[3] },
        attribute data-type-generic { $value[4] },
        $value[1]
    )
};

declare function titan-audio-save(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $value as item()*
) { let $titan-object :=
        if ( fn:exists($value[1][. != ""]) ) then (
            let $object := api:get-asset-from-media-api($value[1], 'audio')
            return (
                if ( fn:empty($object) ) then (
                    fn:error("MissingTitanAudio", $value[1])
                ) else (
                    $object
                )
            )
        ) else ()
    return (
    attribute type {"titanAudio"},
    attribute track-title { $value[2] },
    $value[1]
    )
};

declare function titan-video-save(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $value as item()*
) {
    let $titan-object :=
        if ( fn:exists($value[1][. != ""]) ) then (
            let $object := api:get-asset-from-media-api($value[1], 'video')
            return (
                if ( fn:empty($object) ) then (
                    fn:error("MissingTitanVideo", $value[1])
                ) else (
                    $object
                )
            )
        ) else ()
    return (
    attribute type {"titanVideo"},
    attribute title { $value[2] },
    $value[1]
    )
};

declare function titan-image-save(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $value as item()*
) {
    let $titan-object :=
        if ( fn:exists($value[1][. != ""]) ) then (
            let $object := api:get-asset-from-media-api($value[1], 'image')
            return (
                if ( fn:empty($object) ) then (
                    fn:error("MissingTitanImage", $value[1])
                ) else (
                    $object
                )
            )
        ) else ()
    let $thumb := if(fn:empty($titan-object))then($value[2])else(fn:concat($content-api-asset,"/",$titan-object/renditions[width le 200 and height le 200][last()]/id))
    return (
        attribute type {"titanImage"},
        attribute thumb { $thumb },
        $value[1]
    )
};
declare function titan-pdf-save(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $value as item()*
) {
    let $titan-object :=
        if ( fn:exists($value[1][. != ""]) ) then (
            let $object := api:get-asset-from-media-api($value[1], 'pdf')
            return (
                if ( fn:empty($object) ) then (
                    fn:error("MissingTitanPDF", $value[1])
                ) else (
                    $object
                )
            )
        ) else ()
    return (
        attribute type {"titanPdf"},
        attribute title { $value[2] },
        $value[1]
    )
};

declare function titan-source-save(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $value as item()*
) {
    attribute title { $value[4] }, attribute uri { $value[1]  }, attribute lang { $value[2] }, $value[3]
};

declare function titan-collection-item-save(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $value as item()*
) {
    let $titan-item-ref as xs:string := fn:root($input)/element()/ldse:structure/element()/ldse:items/ldse:dynamic-titan-item-refs/@name
    let $name as xs:string := $titan-item-ref || '-' || $index
    let $vals as item()* := trim($file, $input, $index, xdmp:get-request-field($name, ""))
    return (
        attribute title { $vals[2] }, attribute type { $vals[3] }, $vals[1]
    )
};

declare function titan-collection-save(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $value as item()*
) {
    attribute thumb-id { $value[2] }, $value[1]
};


declare function wysiwyg-embedded-links-save(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $value as item()*
) {
    let $locale := $file/@locale
    let $site := ($file//ldse:site-context/fn:string())[1]
    let $href-map := map:map()
    let $data-map := map:map()
    let $check := try {xdmp:node-kind($value)}
                    catch ($e) {
                        'not a node'
                    }
    return
        if ($check eq 'not a node') then
            $value
        else
            let $hrefs :=
                for $i in $value//xhtml:a/@href
                return if (starts-with($i, '/') and not(starts-with($i, '//'))) then
                    let $_href := if (contains($i, '?')) then substring-before($i, '?') else $i
                    let $href := if (contains($_href, '#')) then substring-before($_href, '#') else $_href
                    let $decoded-href := xdmp:url-decode(lower-case($href))
                    let $additional := substring-after($i, $href)
                    let $uris := if (ends-with($decoded-href, '/')) then
                        ($decoded-href, util:substring-before-last($decoded-href, '/'))
                    else
                        ($decoded-href, $decoded-href||'/')
                    let $id :=
                        cts:search(/custom-page,
                            cts:and-query((
                                cts:directory-query('/preview/', 'infinity'),
                                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uris, 'exact'),
                                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $locale, 'exact'),
                                cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
                            )))/@id
                    return
                        if ($id) then
                            map:put($href-map, $i, substring-before($id, '-')||$additional)
                        else ()
                else ()
            let $process :=
                for $i at $idx in $value
                let $data := xdmp:quote($i)
                let $put := map:put($data-map, 'data'||$idx, $data)
                return
                    for $key in map:keys($href-map)
                    let $current-data := xdmp:quote(map:get($data-map, 'data'||$idx))
                    let $replacement := map:get($href-map, $key)
                    let $newData := fn:replace($current-data, functx:escape-for-regex($key), $replacement)
                    return map:put($data-map, 'data'||$idx, $newData)

            return  for $i at $idx in $value
                    return (xdmp:unquote(map:get($data-map, 'data'||$idx), '', 'repair-full'), $i )[1]/node()
};

declare function wysiwyg-embedded-links-display(
    $locale as xs:string?,
    $site as xs:string?,
    $value as item()*
) {
    let $href-map := map:map()
    let $data-map := map:map()
    let $hrefs :=
        for $i in $value//xhtml:a/@href/fn:string()
        let $_link := if (contains($i, '?')) then substring-before($i, '?') else $i
        let $link := if (contains($_link, '#')) then  substring-before($i, '#') else $_link
        let $additional := substring-after($i, $link)
        return
            if (functx:is-a-number($link)) then
                let $uri := cts:search(/custom-page,
                    cts:and-query((
                        cts:directory-query('/preview/', 'infinity'),
                        cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $link||'-'||$locale, 'exact'),
                        cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $locale, 'exact'),
                        cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
                    )))/@uri
                return if ($uri) then
                    map:put($href-map, $i, $uri||$additional)
                else ()
            else ()

    let $process :=
        for $i at $idx in $value
        let $data := xdmp:quote($i)
        let $put := map:put($data-map, 'data'||$idx, $data)
        return
            for $key in map:keys($href-map)
            let $current-data := xdmp:quote(map:get($data-map, 'data'||$idx))
            let $replacement := map:get($href-map, $key)
            let $newData := fn:replace($current-data, functx:escape-for-regex($key), $replacement)
            return map:put($data-map, 'data'||$idx, $newData)

    return
        for $i at $idx in $value
        return (xdmp:unquote(map:get($data-map, 'data'||$idx), '', 'repair-full'), $i )[1]/node()

};

declare function wysiwyg-embedded-links-display(
    $file as element()?,
    $input as element(ldse:input)?,
    $index as xs:string?,
    $value as item()*
) {
    let $locale := ($file/@locale,xdmp:get-request-field('lang'))[1]
    let $site := (($file//ldse:site-context/fn:string())[1], xdmp:get-request-field('site'))[1]
    return wysiwyg-embedded-links-display($locale, $site, $value)

};

declare function keep-article-content(
    $orig-file as element()?,
    $new-xml as element(),
    $form-template as element(ldse:formTemplate)
) as element() {
    if ( fn:exists($orig-file/content) ) then (
        let $xml := mem:node-insert-child($new-xml, $orig-file/content)
        return (
            typeswitch ( $xml )
            case document-node() return ( $xml/* )
            default return ( $xml )
        )
    ) else ( $new-xml )
};

declare function get-site-tags(
    $value as item()*
) as element(option)* {
    <option>Please Select</option>,
    let $site as xs:string := xdmp:get-request-field('site')[. != ''][1]
    let $tags := get-saved-site-tags($site)
    for $tag as element(text) in ( $tags/tag-groups/tag-group/text, $tags/tag-groups/tag-group/tags/tag/text )
    return (
        <option value="{ $tag/@uri-text/xs:string(.) }">{
            if ( $value = $tag ) then (
                attribute selected { 'selected' }
            ) else (),
            $tag/xs:string(.)
        }</option>
    )
};

declare function get-site-nav-categories(
    $value as item()*
) as element(option)* {
    <option>Select a Nav Category</option>,
    let $site as xs:string := xdmp:get-request-field('site')[. != ''][1]
    return get-saved-site-nav-categories($site) ! build-site-nav-option(./nav-category, $value, "")
};

declare function build-site-nav-option(
    $nav-category as element(nav-category),
    $selected-value as xs:string?, $parent-text as xs:string
) as element(option)* {
    <option value="{$nav-category/path}">{
        if($selected-value = $nav-category/path) then attribute selected {'selected'} else (),
        $parent-text || $nav-category/text
    }</option>,
    if(fn:exists($nav-category/nav-category)) then (
        (: the one time function mapping is useful... :)
        build-site-nav-option($nav-category/nav-category, $selected-value, $parent-text || $nav-category/text || "  >  ")
    ) else ()
};

declare function get-site-audiences(
    $value as item()*
) as element(option)* {
    <option>Please Select</option>,
    let $site as xs:string := xdmp:get-request-field('site')[. != ''][1]
    let $audiences := get-saved-site-audiences($site)
    for $audience as element(text) in $audiences/audiences/audience/text
    return (
        <option value="{ $audience/@id/xs:string(.) }">{
            if ( $value = $audience ) then (
                attribute selected { 'selected' }
            ) else (),
            $audience/xs:string(.)
        }</option>
    )
};

declare function get-source-audiences(
    $value as item()*
) as element(option)* {
    <option>Please Select</option>,
    let $values as xs:string* := fn:tokenize(fn:replace($value, ' ', ''), ',')
    let $site as xs:string := xdmp:get-request-field('site')[. != ''][1]
    let $audiences := get-saved-site-audiences($site)
    for $audience as element(text) in $audiences/audiences/audience/text
    return (
        <option value="{ $audience/@id/xs:string(.) }">{
            if ( $values = $audience/@id ) then (
                attribute selected { 'selected' }
            ) else (),
            $audience/xs:string(.)
        }</option>
    )
};

declare function save-tag(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $value as item()*
) as item()* {
    let $site as xs:string := xdmp:get-request-field('site')[. != '']
    let $all-tags := get-saved-site-tags($site)
    let $tags as element(text)* := ( $all-tags/tag-groups/tag-group/text, $all-tags/tag-groups/tag-group/tags/tag/text )
    let $tag as element(text)? := ( $tags[@uri-text = $value] )[1]
    return (
        attribute uri-text { $value }, $tag/xs:string(.)
    )
};


declare function save-nav-categories(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $value as item()*
) as item()* {
    $value
};

declare function save-audience(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $value as item()*
) as item()* {
    let $site as xs:string := xdmp:get-request-field('site')[. != '']
    let $all-audiences := get-saved-site-audiences($site)
    let $audiences as element(text)* := $all-audiences/audiences/audience/text
    let $audience as element(text)? := $audiences[@id = $value]
    return (
        $value
    )
};

declare function save-source-audiences(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $value as item()*
) as item()* {
    let $site as xs:string := xdmp:get-request-field('site')[. != '']
    let $all-audiences := get-saved-site-audiences($site)
    let $audiences as element(text)* := $all-audiences/audiences/audience/text
    let $audience as element(text)? := $audiences[@id = $value]
    return (
        fn:string-join($value, ',')
    )
};

declare function get-saved-site-tags(
    $site as xs:string
) as element(tags)? {
    cts:search(/tags,
        cts:and-query((
            core:get-filter-query(),
            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
        )),
        'unfiltered'
    )
};


declare function get-saved-site-nav-categories(
    $site as xs:string
) as element(nav-categories)* {
    cts:search(/nav-categories,
        cts:and-query((
            core:get-filter-query(),
            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
        )),
        'unfiltered'
    )
};

declare function get-saved-site-audiences(
    $site as xs:string
) as element(audiences)? {
    cts:search(/audiences,
        cts:and-query((
            core:get-filter-query(),
            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
        )),
        'unfiltered'
    )
};

declare function get-saved-site-actions(
    $site as xs:string
) as element(actions)* {
    cts:search(/actions,
        cts:and-query((
            core:get-filter-query(),
            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
        )),
        'unfiltered'
    )
};

declare function get-site-meta-tags(
    $value as item()*
) as element(option)* {
    <option>Please Select</option>,
    let $site as xs:string := xdmp:get-request-field('site')[. != ''][1]
    let $siteProperties as element(siteProperties)? := sp:get-site-properties(getVariable('currSite'))
    for $meta-tag as element(meta-tag) in $siteProperties/meta-tags/meta-tag
    return (
        <option value="{ $meta-tag/@value/xs:string(.) }">{
            if ( $value = $meta-tag/@value ) then (
                attribute selected { 'selected' }
            ) else (),
            $meta-tag/xs:string(.)
        }</option>
    )
};
declare function get-content-with-tags(
    $tag as xs:string,
    $lang as xs:string,
    $site as xs:string
) as element()* {
    cts:search(/*,
        cts:and-query((
            core:get-filter-query(),
            cts:not-query(cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), getVariable('id'), 'exact')),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $lang, 'exact'),
            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact'),
            cts:element-value-query(xs:QName('tag'), $tag, 'case-insensitive')
        )),
        'unfiltered'
    )
};

declare function remove-tags-from-content(
    $orig-file as element()?,
    $new-xml as element(),
    $form-template as element(ldse:formTemplate)
) {
    if ( fn:exists($orig-file) ) then (
        check-tags($orig-file, $new-xml)
    ) else ( $new-xml )
};

declare function check-tags(
    $orig-file as element(),
    $new-xml as element()
) {
   let $rt := removed-tags($orig-file, $new-xml)
   return $new-xml
};

declare function removed-tags(
    $orig-file as element(),
    $new-xml as element()
) as element()* {
    for $tag as xs:string in $orig-file/tags/tag/text/@uri-text
    where fn:not($tag = $new-xml/tags/tag/text/@uri-text)
    return remove-tag-item-from-content($tag, $new-xml/ldse:ldse-meta/ldse:document/@locale, $new-xml/ldse:ldse-meta/ldse:form-options/ldse:site-context)
};

declare function remove-tag-item-from-content(
    $tag as xs:string,
    $locale as xs:string,
    $site as xs:string
) as empty-sequence() {
    for $item as element() in get-content-with-tags($tag, $locale, $site)
    return xdmp:node-delete($item/tags/tag[. = $tag])
};

declare function get-site-actions(
    $value as xs:string*
) as element(option)* {
    <option>Please Select</option>,
    let $site as xs:string := xdmp:get-request-field('site')[. != ''][1]
    for $action as element(name) in get-saved-site-actions($site)/actions/action/name
    return (
        <option value="{ $action/@uri-title/xs:string(.) }">{
            if ( $value = $action/@uri-title/xs:string(.) ) then (
                attribute selected { 'selected' }
            ) else (),
            $action/xs:string(.)
        }</option>
    )
};

declare function save-dynamic-xml-mixed-types(
    $orig-file as element()?,
    $new-xml as element(),
    $form-template as element(ldse:formTemplate)
) as element() {
    let $element as element() := $form-template/ldse:structure/element()//ldse:dynamic-xml[fn:exists(@content-types) and fn:not(@content-types = '')]/..
    let $content-types as xs:string* := fn:tokenize($element/ldse:dynamic-xml/@content-types, ',')
    let $dynamic-set as element() := $new-xml/element()[fn:local-name(.) = fn:local-name($element)]
    let $new-xml as element() :=
        element { fn:name($new-xml) } {
            $new-xml/@*,
            $new-xml/*[fn:local-name(.) != fn:local-name($element)],
            element { fn:name($dynamic-set) } {
                $dynamic-set/@*,
                build-dynamic-set($dynamic-set, $content-types)
            }
        }

    return $new-xml
};

declare function build-dynamic-set(
    $dynamic-set as node(),
    $content-types as xs:string*
) {
    for $item as item() in $dynamic-set/node()
    return (
        typeswitch ( $item )
        case attribute() return $item
        case element(xhtml:br) return $item
        case element() return (
            if ( fn:exists($item/node()) and fn:exists(fn:normalize-space(fn:string($item))[. != '']) ) then (
                if ( fn:local-name($item) = $content-types ) then (
                    attribute type { fn:local-name($item) }
                ) else (),
                element { fn:name($item) } {
                    $item/@* except $item/@type,
                    build-dynamic-set($item, $content-types)
                }
            ) else ()
        )
        case text() return $item
        default return ()
    )
};

declare function unique-tag(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $value as item()*
) {
    $value || '-' || $index
};

declare function externalResource(
    $input as element(ldse:input),
    $file as element()?,
    $index as xs:string?
) as element(dl) {
    let $name as xs:string := buildInputName($input, $index)
    let $id as xs:string := $name
    let $value as xs:string? := dynamicXpath($file, xs:string($input/@xpath))
    let $lang as xs:string := util:escape-chars(xdmp:get-request-field("lang", "eng"))
    let $blockAttrs as xs:string* := ( 'id', 'type', 'name', 'seq', 'value', 'options', 'xpath', 'dlClass', 'help')
    let $site-properties as element(siteProperties)* := sp:get-site-properties(getVariable('currSite'))
    let $dataUrl as xs:string? := $site-properties/content-endpoints/api-endpoint/url
    let $previewUrl as xs:string? := $site-properties/content-endpoints/preview-endpoint/url
    return (
        <dl data-sequence="{xs:string($input/@seq)}" data-group="{$input/@group}" class="{xs:string($input/@dlClass)}">
            { inputLabel($input, $id, $index) }
            <dd>
                <dl class="padding-sm imageWrapper">
                    <dt>
                        <label for="{ $id }">Resource ID</label>
                    </dt>
                    <dd>
                    <resource-reference data-url="{ $dataUrl }" data-input-id="{ $id }" data-search-id="search-resource">{
                        <div>
                            <a id="search-resource" data-type="image" class="ldse-button ldse-responsive-button secondary ldse-icon-search">Search</a>
                            <a id="delete-resource" onclick="clearInputField('{ $name }')" class="ldse-button ldse-responsive-button destructive ldse-icon-trash ixf-button">Delete</a>
                        </div>,
                        element input {
                            getInputAttributes($input, $blockAttrs, $index),
                            attribute id { $id },
                            attribute name { $name },
                            attribute value { $value },
                            attribute type { 'text' },
                            attribute onchange { fn:concat('updatePreview("', fn:concat($id, '-preview'), '", this)') }
                        }
                    }
                    </resource-reference>
                    <dt>Current Reference Image</dt>
                    <dd>
                        <img width="200" id="{fn:concat($id, '-preview')}" src="{ if ( fn:exists($value[. != '']) ) then ( $previewUrl || '/' || $value || '/image?lang=' || $lang ) else () }"/>
                    </dd>
                    </dd>
                </dl>
            </dd>
        </dl>
    )
};

declare function filterLinkSelect(
    $value as item()*
) as element(option)* {
    <option>Please Select</option>,
    for $custom-page in getPageUris()
        return (
            <option value="{ $custom-page/@id/xs:string(.) }">{
                if ( $value = $custom-page/@id/xs:string(.) ) then (
                    attribute selected { 'selected' }
                ) else (),
                $custom-page/@uri/xs:string(.)
            }</option>
        )
};

declare function getPageUris(
) as element()* {
    let $site as xs:string := xdmp:get-request-field('site')[. != ''][1]
    let $page-settings := cts:search(/custom-page,
        cts:and-query((
            cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('locale'), getVariable('locale')),
            cts:element-value-query(xs:QName('site-context'), $site)
        ))
    )
    return $page-settings
};

declare function updateAudiencesForLDSSource(
    $orig-file as element()?,
    $new-xml as element(),
    $form as element(ldse:formTemplate)
) as element() {
    let $audiences as xs:string? := fn:string-join($new-xml/head/lds:meta/lds:audience/xs:string(.), ', ')
    let $new-audience := <lds:audience xmlns:lds="http://www.lds.org/schema/lds-meta/v1">{ $audiences }</lds:audience>
    let $new-meta :=
        element { fn:name($new-xml/head/lds:meta) } {
            $new-xml/head/lds:meta/@*,
            $new-xml/head/lds:meta/* except $new-xml/head/lds:meta/lds:audience,
            $new-audience
        }
    let $new-xml as element() :=
        if ( fn:exists($new-xml/head/lds:meta/lds:audience) ) then (
            element { fn:name($new-xml) } {
                $new-xml/@*,
                element head {
                    $new-xml/head/@*,
                    $new-xml/head/* except $new-xml/head/lds:meta,
                    $new-meta
                },
                $new-xml/* except $new-xml/head
            }
        ) else if ( fn:exists($audiences) ) then (
            mem:node-insert-child($new-xml/head/lds:meta, $new-audience)
        ) else ( $new-xml )
    return $new-xml
};

declare function removePTag(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $value as item()*
) as item()* {
    let $test := $value/node()
    return $test
};

declare function get-content-groups(
    $value as item()*
) {
    let $response := util:map-xml(util:http-get($settings:content-groups-api, ())[2])
    for $content-group as element(contentgroup) in $response/contentgroup
    return (
        <option value="{ $content-group/id/xs:string(.) }">{
            if ( $content-group/id/xs:string(.) = $value ) then (
                attribute selected { 'selected' }
            ) else (),
            $content-group/name/xs:string(.)
        }</option>
    )
};

declare function get-content-group-select(
    $value as item()*
) {
    <option>Please Select</option>,
    get-content-groups($value)
};

declare function pushToContentCentral(
    $orig-file as element()?,
    $new-xml as element(),
    $form as element(ldse:formTemplate)
) {
    if ( getVariable('status') = 'ldse:publish' ) then (
        let $content-group as xs:string := $new-xml/content-group
        let $updated as element(html)? := mem:node-delete($new-xml/ldse:ldse-meta)
        let $updated as element(html)? := mem:node-delete($updated/@status)
        let $updated as element(html)? := mem:node-delete($updated/@xml:lang)
        let $updated as element(html)? := mem:node-delete($updated/content-group)
        let $new-update := ( "<!DOCTYPE html>", $updated )
        let $boundary as xs:string := '----ccpfc'
        let $manifest as element() :=
            <manifest xmlns="xdmp:multipart">
                <part>
                    <headers>
                        <Content-Disposition>form-data; name="file"; filename="{ util:substring-after-last($updated/@data-uri, '/') || '.html' }"</Content-Disposition>
                        <Content-Type>text/html</Content-Type>
                    </headers>
                </part>
            </manifest>
        let $options :=
            <options xmlns="xdmp:http">
                <headers>
                    <Content-Type>multipart/form-data; boundary={$boundary}</Content-Type>
                </headers>
            </options>
        let $encode-data := xdmp:multipart-encode($boundary, $manifest, $updated)
(:        let $boundary-str-len := concat(substring($boundary, string-length($boundary) - 4, 5),fn:codepoints-to-string((13,10)))
        let $length := string-length(string(data($encode-data))) idiv 2
        let $patched-multipart-encode :=
            if (xdmp:subbinary($encode-data, $length - 6, $length) eq xdmp:unquote($boundary-str-len, (), "format-binary")) then (
                binary { xs:hexBinary(concat(string(data(xdmp:subbinary($encode-data, 1, $length - 2))), "2D2D"))}
            ) else ( $encode-data )
:)

        let $send := util:http-post($settings:content-central-api || '/ws/v1/services/api/transform?contentGroupId=' || $content-group, $options, $encode-data)
        return ()
    ) else (),
    $new-xml
};

declare function get-mo-color(
    $value as item()*
) as element(option)* {
    (
        <option value=""></option>,
        for $i in cts:search(/mormonorg-settings/colors, ())/color/xs:string(.)
        return if ($i eq $value) then
            <option value="{$i}" selected="true">{$i}</option>
        else
            <option value="{$i}">{$i}</option>
    )
};

declare function get-mo-theme-color(
    $value as item()*
) as element(ldse:option)* {
    (
        <ldse:option value="">Use site theme</ldse:option>,
            for $i in cts:search(/mormonorg-settings/theme-colors, ())/color/xs:string(.)
            return if ($i eq $value) then
            <ldse:option value="{$i}" selected="true">{$i}</ldse:option>
        else
            <ldse:option value="{$i}">{$i}</ldse:option>
    )
};

declare function get-mo-bg-size(
    $value as item()*
) as element(option)* {
    (
        for $i in cts:search(/mormonorg-settings/bg-size, ())/size/xs:string(.)
        return if ($i eq $value) then
            <option value="{$i}" selected="true">{$i}</option>
        else
            <option value="{$i}">{$i}</option>
    )
};

declare function get-mo-mobile-bg-size(
    $value as item()*
) as element(option)* {
    (
        for $i in cts:search(/mormonorg-settings/mobile-bg-size, ())/size/xs:string(.)
        return if ($i eq $value) then
            <option value="{$i}" selected="true">{$i}</option>
        else
            <option value="{$i}">{$i}</option>
    )
};

declare function get-mo-grid-size(
    $value as item()*
) as element(option)* {
    (

        for $i in cts:search(/mormonorg-settings/grid-size, ())/size
        return
            if($i/fn:string() eq $value)then
			   <option value="{$i/fn:string()}" selected="true">{$i/fn:string()}</option>
			else if($i[@default eq "true"] and fn:not($value))then
			   <option value="{$i/fn:string()}" selected="true">{$i/fn:string()}</option>
			else <option value="{$i/fn:string()}">{$i/fn:string()}</option>
    )
};

declare function get-mo-emphasized-grid-size(
    $value as item()*
) as element(option)* {
    (
        for $i in cts:search(/mormonorg-settings/grid-size/size, ())[. ne 'narrow']/xs:string(.)
        return  if ($i eq $value) then
                   <option value="{$i}" selected="true">{$i}</option>
                else
                   <option value="{$i}">{$i}</option>
    )
};

declare function get-mo-button-variant(
    $value as item()*
) as element(option)* {
    (
        for $i in cts:search(/mormonorg-settings/button-variants, ())/variant/xs:string(.)
        return if ($i eq $value) then
            <option value="{$i}" selected="true">{$i}</option>
        else
            <option value="{$i}">{$i}</option>
    )
};

declare function get-mo-mobile-spacing(
    $value as item()*
) as element(option)* {
    (
        for $i in cts:search(/mormonorg-settings/mobile-spacing, ())/level
        return
            if($i/fn:string() eq $value)then
			   <option value="{$i/fn:string()}" selected="true">{$i/fn:string()}</option>
			else if($i[@default eq "true"] and fn:not($value))then
			   <option value="{$i/fn:string()}" selected="true">{$i/fn:string()}</option>
			else <option value="{$i/fn:string()}">{$i/fn:string()}</option>
    )
};

declare function get-mo-desktop-spacing(
    $value as item()*
) as element(option)* {
    (
        for $i in cts:search(/mormonorg-settings/desktop-spacing, ())/level
        return
            if($i/fn:string() eq $value)then
			   <option value="{$i/fn:string()}" selected="true">{$i/fn:string()}</option>
			else if($i[@default eq "true"] and fn:not($value))then
			   <option value="{$i/fn:string()}" selected="true">{$i/fn:string()}</option>
			else <option value="{$i/fn:string()}">{$i/fn:string()}</option>
    )
};

declare function get-mo-desktop-spacing-2(
    $value as item()*
) as element(option)* {
    (
        for $i in cts:search(/mormonorg-settings/desktop-spacing-2, ())/level
        return
            if($i/fn:string() eq $value)then
			   <option value="{$i/fn:string()}" selected="true">{$i/fn:string()}</option>
			else if($i[@default eq "true"] and fn:not($value))then
			   <option value="{$i/fn:string()}" selected="true">{$i/fn:string()}</option>
			else <option value="{$i/fn:string()}">{$i/fn:string()}</option>
    )
};

declare function get-mo-desktop-spacing-3(
    $value as item()*
) as element(option)* {
    (
        for $i in cts:search(/mormonorg-settings/desktop-spacing-3, ())/level
        return
            if($i/fn:string() eq $value)then
			   <option value="{$i/fn:string()}" selected="true">{$i/fn:string()}</option>
			else if($i[@default eq "true"] and fn:not($value))then
			   <option value="{$i/fn:string()}" selected="true">{$i/fn:string()}</option>
			else <option value="{$i/fn:string()}">{$i/fn:string()}</option>
    )
};

declare function get-mo-svg-image(
    $value as item()*
) as element(option)* {
    (
        for $i in cts:search(/mormonorg-settings/svg-image, ())/name/xs:string(.)
        return if ($i eq $value) then
            <option value="{$i}" selected="true">{$i}</option>
        else
            <option value="{$i}">{$i}</option>
    )
};

declare function get-mo-site-logo(
    $value as item()*
) as element(option)* {
   (
        for $i in cts:search(/mormonorg-configs/site-logo-code, ())/code/xs:string(.)
        return if ($i eq $value) then
            <option value="{$i}" selected="true">{$i}</option>
        else
            <option value="{$i}">{$i}</option>
    )
};

declare function get-mo-url-keys(
    $value as item()*
) as element(ldse:option)* {
    (
        <ldse:option value=""></ldse:option>,
        for $i in  rice:getBundles('mormonorg-url-keys', 'eng')/properties/entry   (::: hard code to 'eng' because this file only exists in English :::)
        order by $i/value/fn:string()
        return if ($i eq $i/@key) then
            <ldse:option value="{$i/@key}" selected="true">{$i/value/fn:string()}</ldse:option>
        else
            <ldse:option value="{$i/@key}">{$i/value/fn:string()}</ldse:option>
    )
};

declare function get-mo-country-code(
    $value as item()*
) as element(option)* {
    (
        <option value=""></option>,
        for $i in rice:get-bundle('country-codes', 'eng', 'churchofjesuschrist', '/preview/')/properties/entry  (: this bundle only exists for churchofjesuschrist/eng, and only needed in preview  :)
        order by $i/value/fn:string()
        return if ($i/@key/fn:string() eq $value) then
                    <option value="{$i/@key/fn:string()}" selected="true">{$i/value/fn:string()}</option>
                else
                    <option value="{$i/@key/fn:string()}">{$i/value/fn:string()}</option>
                )
};

declare function get-cogito-request-options(){
    <options xmlns="xdmp:http">
        <headers>
            <accept>application/json</accept>
            <contentType>application/json</contentType>
            <limit>10000</limit>
        </headers>
    </options>
};

declare function query-cogito(
    $scheme as xs:string
) as object-node()? {
    let $tagServiceUrl as xs:string? := $settings:cogito-url || "/tags"
    let $get := xdmp:http-get($tagServiceUrl, get-cogito-request-options())
    let $header := $get[1]
    return if($header/*:code = 200) then(
        let $response := $get[2]/node()
        return $response
    ) else (
        fn:error()
    )
};

declare function get-cogito-tags(
    $value as item()*
) as element(option)* {
    let $response := query-cogito('all')
    let $options := get-tag-options($response/tags, $value)
    return $options
};

declare function get-tag-options(
    $tags as object-node()*,
    $value as item()*
) as element(option)* {
    for $tag in $tags
    let $id as xs:string := fn:string($tag/id)
    order by $tag/label
    return (
        <option value="{ $id }">{
            if ( $id = fn:string($value) ) then ( attribute selected { 'true' } ) else (),
            fn:string($tag/label)
        }</option>
    )
};

declare function save-cogito-tags(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $value as item()*
) {
    let $response := query-cogito('all')
    let $tags :=
        for $tag in $response/tags
        let $id as xs:string := $tag/id
        return (
            <tag>{ attribute id { $id }, $tag/label }</tag>
        )
    return (
        $tags[@id = $value]/@id, $tags[@id = $value]/xs:string(.)
    )
};

declare function get-cogito-dropdown(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $node as element()?
) {
    let $id as xs:string? := $node/@id
    return (
        get-cogito-tags($id)
    )
};

declare function pushToQueue(
    $origFile as element()?,
    $newFile as element(),
    $formTemplate as element(ldse:formTemplate)
) as element() {
    if ( getVariable('status') = 'ldse:publish' ) then (
        let $event as xs:string :=
            if ( getVariable('status') = 'ldse:unpublish' ) then (
                'delete'
            ) else ( 'update' )
        let $json := gct:perform-transform($newFile, ())
        let $push := push-to-emx(fn:local-name($newFile), $json, ())
        return $newFile
    ) else ( $newFile )
};

declare function push-to-emx(
    $data-type as xs:string,
    $json as object-node(),
    $event as xs:string?
) {
    try {
        util:http-post($settings:emx-queue,
            <options xmlns="xdmp:http">
                <headers>
                    <dataType>{ $data-type }</dataType>
                    { if ( fn:exists($event) ) then ( <tagAction>{ $event }</tagAction> ) else () }
                    <Content-Type>application/json</Content-Type>
                </headers>
                <authentication method="basic">
                    <username>{ $settings:emx-username }</username>
                    <password>{ $settings:emx-password }</password>
                </authentication>
            </options>, $json)
    } catch ( $e ) { $e }
};

declare function get-custom-page-by-urlkey(
    $urlKey as xs:string,
    $locale as xs:string,
    $status as xs:string*
) as element(custom-page)? {
    cts:search(/custom-page,
        cts:and-query((
            cts:element-attribute-value-query(xs:QName("custom-page"),xs:QName("locale"), $locale, 'exact'),
            cts:element-value-query(xs:QName("urlKey"), $urlKey, 'exact'),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('status'), $status, 'exact')
        ))
    )
};

declare function mo-get-uri-list(
    $value as item()*
) as element(option)* {
    let $locale := getVariable('locale')
    let $site as xs:string := xdmp:get-request-field('site')[. != ''][1]
    let $list :=
     if ( fn:exists($site[. != '']) ) then (
        for $i in cts:search(/custom-page,
                cts:and-query((
                    cts:directory-query('/preview/', 'infinity'),  (: find the ones in the preview directory instead of checking for just the preview status - moml 5948 :)
                    cts:element-attribute-range-query(xs:QName("ldse:document"), xs:QName("locale"), "=", $locale),
                    cts:element-value-query(xs:QName("ldse:site-context"), $site, 'exact')
                ))
            )
        let $id := fn:substring-before($i/@id/fn:string(), '-')
        let $uri := $i/@uri/fn:string()
        order by $i/@uri/fn:string()
        return if ($value eq $id) then
                    <option value="{$id}" selected="true">{$uri}</option>
                else
                    <option value="{$id}">{$uri}</option>
      ) else ()
    return (
            <option value=""></option>,
            $list
            )
};

declare function get-mo-icon-types(
    $value as item()*
) as element(option)* {
    (
        for $i in cts:search(/mormonorg-settings/icon-types, ())/type/xs:string(.)
        return if ($i eq $value) then
            <option value="{$i}" selected="true">{$i}</option>
        else
            <option value="{$i}">{$i}</option>
    )
};

declare function get-languages-by-locale(
    $value as item()*
) as element(option)* {
    <option>Please Select</option>,
    let $locale := getVariable('locale')
    let $site as xs:string := xdmp:get-request-field('site')[. != ''][1]
    let $languages := for $language in cts:search(/resources,
                        cts:and-query((
                           cts:directory-query('/preview/', 'infinity'),
                           cts:element-value-query(xs:QName('name'), 'language-selector', 'exact'),
                           cts:element-attribute-value-query(xs:QName('resources'), xs:QName('site'), $site , 'exact'),
                           cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $locale , 'exact')
                        )))/properties/entry
                        order by $language
                        return  if(fn:string-length($language/@key/fn:string()) eq 3) then
                                  (<option value="{ $language/@key/fn:string() }">{
                                        if ( $value eq $language/@key/fn:string() ) then (
                                          attribute selected { 'selected' }
                                      ) else (),
                                      $language/fn:string()
                                  }</option>)
                                  else ()
   return $languages
};

declare function get-country-list(
    $value as item()*
) as element(option)* {
    let $countries := util:get-countries-list()
    let $data := if ($countries) then (
                        for $i in $countries/jsonb:json
                        return $i/jsonb:name/fn:string() )
                 else ()
    return
    (
        <option value=""></option>,
        for $i in $data
        return if ($i eq $value) then
            <option value="{$i}" selected="true">{$i}</option>
        else
            <option value="{$i}">{$i}</option>
    )
};

declare function get-mp-portal-filters-permissions(
    $value as item()*
) as element(option)* {
    (
        let $a := retrieve-from-lane-url(cts:search(/mportal-settings/lane-urls/permission-list-urls/url, ()))
        let $b := xdmp:to-json-string($a)
        let $length := fn:string-length($b)
        let $new := (fn:substring($b, 2, $length - 2))
        let $trimmed := fn:replace($new, ' ', '')
        let $result := fn:tokenize(fn:replace($trimmed, '"', ''), ','  )
        let $pResult := fn:insert-before($result, 0, "")
        let $pResult := ($pResult, "NO_ACCESS")
        let $isInArray := cts:contains($pResult, $value) or fn:string-length($value) eq 0
        let $insertionIndex := fn:count($pResult) + 1
        let $newResult := if ($isInArray) then $pResult else fn:insert-before($pResult, $insertionIndex, $value)
        let $allOptions :=
            for $i in $newResult
            return if ($i eq $value) then
                if ($isInArray) then
                    if (fn:string-length($value) eq 0) then
                        <option value="{$i}" selected="true">No Permission Required</option>
                    else
                        <option value="{$i}" selected="true">{$i}</option>
                else
                    <option value="{$i}" selected="true">{$i} (Permission no longer exists - please update)</option>
            else
                 if (fn:string-length($i) eq 0) then
                    <option value="{$i}">No Permission Required</option>
                else
                    <option value="{$i}">{$i}</option>
        return $allOptions
    )
};

declare function get-mp-static-routes(
    $value as item()*
) as element(option)* {
    (
        let $a := retrieve-from-lane-url(cts:search(/mportal-settings/lane-urls/portal4-react-routes/url, ()))
        let $b := xdmp:to-json-string($a)
        let $length := fn:string-length($b)
        let $new := (fn:substring($b, 2, $length - 2))
        let $trimmed := fn:replace($new, ' ', '')
        let $result := fn:tokenize(fn:replace($trimmed, '"', ''), ','  )
        let $retValue :=
            for $i in $result
            return if ($i eq $value) then
                <option value="{$i}" selected="true">{$i}</option>
            else
                <option value="{$i}">{$i}</option>
        return ($retValue)
    )
};

declare function get-mp-eden-icons(
    $value as item()*
) as element(option)* {
    (
        let $a := retrieve-from-lane-url(cts:search(/mportal-settings/lane-urls/portal4-react-eden-icons/url, ()))
        let $b := xdmp:to-json-string($a)
        let $length := fn:string-length($b)
        let $new := (fn:substring($b, 2, $length - 2))
        let $trimmed := fn:replace($new, ' ', '')
        let $result := fn:tokenize(fn:replace($trimmed, '"', ''), ','  )
        let $retValue :=
            for $i in $result
            return if ($i eq $value) then
                <option value="{$i}" selected="true">{$i}</option>
            else
                <option value="{$i}">{$i}</option>
        return (<option value="">Portal Default</option>, $retValue)
    )
};

declare function get-mp-eden-button-types(
    $value as item()*
) as element(option)* {
    (
        let $a := retrieve-from-lane-url(cts:search(/mportal-settings/lane-urls/portal4-react-eden-button-types/url, ()))
        let $b := xdmp:to-json-string($a)
        let $length := fn:string-length($b)
        let $new := (fn:substring($b, 2, $length - 2))
        let $trimmed := fn:replace($new, ' ', '')
        let $result := fn:tokenize(fn:replace($trimmed, '"', ''), ','  )
        let $retValue :=
            for $i in $result
            return if ($i eq $value) then
                <option value="{$i}" selected="true">{$i}</option>
            else
                <option value="{$i}">{$i}</option>
        return (<option value="">Portal Default</option>, $retValue)
    )
};

declare function get-mp-callout-box-colors(
    $value as item()*
) as element(option)* {
    (
        let $a := retrieve-from-lane-url(cts:search(/mportal-settings/lane-urls/portal4-react-callout-box-colors/url, ()))
        let $b := xdmp:to-json-string($a)
        let $length := fn:string-length($b)
        let $new := (fn:substring($b, 2, $length - 2))
        let $trimmed := fn:replace($new, ' ', '')
        let $result := fn:tokenize(fn:replace($trimmed, '"', ''), ','  )
        let $retValue :=
            for $i in $result
            return if ($i eq $value) then
                <option value="{$i}" selected="true">{$i}</option>
            else
                <option value="{$i}">{$i}</option>
        return (<option value="">Portal Default</option>, $retValue)
    )
};

declare function get-mp-eden-alert-colors(
    $value as item()*
) as element(option)* {
    (
        let $a := retrieve-from-lane-url(cts:search(/mportal-settings/lane-urls/portal4-react-eden-alert-colors/url, ()))
        let $b := xdmp:to-json-string($a)
        let $length := fn:string-length($b)
        let $new := (fn:substring($b, 2, $length - 2))
        let $trimmed := fn:replace($new, ' ', '')
        let $result := fn:tokenize(fn:replace($trimmed, '"', ''), ','  )
        let $retValue :=
            for $i in $result
            return if ($i eq $value) then
                <option value="{$i}" selected="true">{$i}</option>
            else
                <option value="{$i}">{$i}</option>
        return (<option value="">Portal Default</option>, $retValue)
    )
};

declare function get-mp-workforce-static-routes(
    $value as item()*
) as element(option)* {
    (
        let $a := retrieve-from-lane-url(cts:search(/mportal-settings/lane-urls/portal4-react-workforce-routes/url, ()))
        let $b := xdmp:to-json-string($a)
        let $length := fn:string-length($b)
        let $new := (fn:substring($b, 2, $length - 2))
        let $trimmed := fn:replace($new, ' ', '')
        let $result := fn:tokenize(fn:replace($trimmed, '"', ''), ','  )
        let $retValue :=
            for $i in $result
            return if ($i eq $value) then
                <option value="{$i}" selected="true">{$i}</option>
            else
                <option value="{$i}">{$i}</option>
        return $retValue
    )
};

declare function get-mp-landing-static-routes(
    $value as item()*
) as element(option)* {
    (
        let $a := retrieve-from-lane-url(cts:search(/mportal-settings/lane-urls/portal4-react-landing-routes/url, ()))
        let $b := xdmp:to-json-string($a)
        let $length := fn:string-length($b)
        let $new := (fn:substring($b, 2, $length - 2))
        let $trimmed := fn:replace($new, ' ', '')
        let $result := fn:tokenize(fn:replace($trimmed, '"', ''), ','  )
        let $retValue :=
            for $i in $result
            return if ($i eq $value) then
                <option value="{$i}" selected="true">{$i}</option>
            else
                <option value="{$i}">{$i}</option>
        return $retValue
    )
};

declare function retrieve-from-lane-url(
    $ctsSearchResult as node()*
) as node(){

        let $site as xs:string := xdmp:get-request-field('site')[. != ''][1]
        let $siteProperties as element(siteProperties)? := sp:get-site-properties(getVariable('currSite'))
        let $activeLane := for $meta-tag as element(meta-tag) in $siteProperties/meta-tags/meta-tag
        return if ( "lane" = $meta-tag/@value ) then (
                    $meta-tag/xs:string(.)
                ) else ()
        let $listOfLanes := for $i in cts:search(/mportal-settings/lane-urls/permission-list-urls/url, ())
            return $i/@lane/fn:string()
        let $defaultLane := "prod"
        let $chosenLane := if(fn:not(functx:is-value-in-sequence($activeLane, $listOfLanes))) then
            $defaultLane
        else
            $activeLane
        let $laneUrl := for $i in $ctsSearchResult
            return if ($i/@lane/fn:string() eq $chosenLane) then $i/xs:string(.) else ()
        return xdmp:http-get($laneUrl, <options xmlns="xdmp:http"/>)[2]
};


declare function mp-get-landing-uri-list(
    $value as item()*
) as element(option)* {
    let $locale := getVariable('locale')
    let $site as xs:string := xdmp:get-request-field('site')[. != ''][1]
    let $allowedTemplateIds := for $i in cts:search(/mportal-settings/internal-url-dropdown/allowed-page-templates/allowed-page-template, ())
    return ($i/xs:string(.))
    let $staticSitesList := get-mp-landing-static-routes($value)
    let $noRedirectOption := if($value eq 'NO_REDIRECT') then (
        <option value="NO_REDIRECT" selected="true">Keep user on home page if the user has matching permission below</option>
    ) else (
        <option value="NO_REDIRECT">Keep user on home page if the user has matching permission below</option>
    )
    let $publisherUrilist :=
        for $i in cts:search(/custom-page,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("locale"), $locale, 'exact'),
                cts:element-value-query(xs:QName("template-id"), $allowedTemplateIds, 'exact'),
                if ( fn:exists($site[. != '']) ) then (
                    cts:or-query((
                        cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("site"), $site, 'exact'),
                        cts:element-value-query(xs:QName("ldse:site-context"), $site, 'exact')
                    ))
                ) else ()
            ))
        )
        let $uri := $i/@uri/fn:string()
        return (<option value="{$uri}">{$uri}</option>)
    let $combinedList := for $i in ($staticSitesList, $publisherUrilist) order by $i/xs:string(.)
    return if ($i/@value/fn:string(.) eq $value) then
        <option value="{$i/@value/fn:string()}" secret-value="{$value}" selected="true">{$i/xs:string(.)}</option>
    else
        <option value="{$i/@value/fn:string()}" secret-value="{$value}">{$i/xs:string(.)}</option>
    return (
        <option value=""></option>,
        $noRedirectOption,
        $combinedList
    )
};

declare function mp-get-uri-list(
    $value as item()*
) as element(option)* {
    let $locale := getVariable('locale')
    let $site as xs:string := xdmp:get-request-field('site')[. != ''][1]
    let $allowedTemplateIds := for $i in cts:search(/mportal-settings/internal-url-dropdown/allowed-page-templates/allowed-page-template, ())
        return ($i/xs:string(.))
    let $staticSitesList := get-mp-static-routes($value)
    let $publisherUrilist :=
        for $i in cts:search(/custom-page,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("locale"), $locale, 'exact'),
                cts:element-value-query(xs:QName("template-id"), $allowedTemplateIds, 'exact'),
                if ( fn:exists($site[. != '']) ) then (
                    cts:or-query((
                        cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("site"), $site, 'exact'),
                        cts:element-value-query(xs:QName("ldse:site-context"), $site, 'exact')
                    ))
                ) else ()
            ))
        )
        let $uri := $i/@uri/fn:string()
        return (<option value="{$uri}">{$uri}</option>)
    let $combinedList := for $i in ($staticSitesList, $publisherUrilist) order by $i/xs:string(.)
        return if ($i/@value/fn:string(.) eq $value) then
            <option value="{$i/@value/fn:string()}" secret-value="{$value}" selected="true">{$i/xs:string(.)}</option>
        else
            <option value="{$i/@value/fn:string()}" secret-value="{$value}">{$i/xs:string(.)}</option>
    return (
        <option value=""></option>,
        $combinedList
    )
};

(:~ Core changes to mp-get-uri-list should also be made here, and vice-versa ~:)
declare function mp-get-workforce-uri-list(
    $value as item()*
) as element(option)* {
    let $staticSitesList := get-mp-workforce-static-routes($value)
    let $uriList := for $i in $staticSitesList order by $i/xs:string(.)
        return if ($i/@value/fn:string(.) eq $value) then
            <option value="{$i/@value/fn:string()}" secret-value="{$value}" selected="true">{$i/xs:string(.)}</option>
        else
            <option value="{$i/@value/fn:string()}" secret-value="{$value}">{$i/xs:string(.)}</option>
    return (
        <option value=""></option>,
        $uriList
    )
};

declare function mp-get-forbidden-page-options(
    $value as item()*
) as element(option)* {
    let $forbiddenOptions := for $i in cts:search(/mportal-settings/forbidden-user-options/option, ())
        return if ($i/@value/fn:string(.) eq $value) then
            <option value="{$i/@value/fn:string()}" selected="true">{$i/xs:string(.)}</option>
        else
            <option value="{$i/@value/fn:string()}">{$i/xs:string(.)}</option>


    return $forbiddenOptions
};

declare function mp-get-tile-type-options(
    $value as item()*
) as element(option)* {
    let $forbiddenOptions := for $i in cts:search(/mportal-settings/tile-type-options/option, ())
    return if ($i/@value/fn:string(.) eq $value) then
        <option value="{$i/@value/fn:string()}" selected="true">{$i/xs:string(.)}</option>
    else
        <option value="{$i/@value/fn:string()}">{$i/xs:string(.)}</option>


    return $forbiddenOptions
};

declare function mp-get-boolean-options(
    $value as item()*
) as element(option)* {
    let $booleanOptions := for $i in cts:search(/mportal-settings/boolean-options/option, ())
    return if ($i/@value/fn:string(.) eq $value) then
        <option value="{$i/@value/fn:string()}" selected="true">{$i/xs:string(.)}</option>
    else
        <option value="{$i/@value/fn:string()}">{$i/xs:string(.)}</option>
    return $booleanOptions
};

declare function mp-get-tile-type-modal-options(
    $value as item()*
) as element(option)* {
    let $forbiddenOptions := for $i in cts:search(/mportal-settings/tile-type-options/option[@has-modal='yes'], ())
    return if ($i/@value/fn:string(.) eq $value) then
        <option value="{$i/@value/fn:string()}" selected="true">{$i/xs:string(.)}</option>
    else
        <option value="{$i/@value/fn:string()}">{$i/xs:string(.)}</option>


    return $forbiddenOptions
};

declare function get-mo-international-hub-forms(
    $value as item()*
) as element(option)* {
    let $lang := (util:escape-chars(xdmp:get-request-field("lang", "eng")),'eng')[1]
    let $site as xs:string := xdmp:get-request-field('site')[. != ''][1]
    let $r :=
        (
        <option value="">Select a form</option>,
        for $i in  rice:get-bundle('mormonorg-international-hub-prebuilt-forms', $lang, $site, '/preview/')/properties/entry
        where fn:string-length($i/value/fn:string()) > 0
        order by $i/@key/fn:string()
        return if ($value eq $i/value/fn:string()) then
            <option value="{$i/value/fn:string()}" selected="true">{$i/@key/fn:string()}</option>
        else
            <option value="{$i/value/fn:string()}">{$i/@key/fn:string()}</option>
        )
    return $r
};

declare function get-mo-mobile-grid-size(
    $value as item()*
) as element(option)* {
    (
        for $i in cts:search(/mormonorg-settings/mobile-grid-size, ())/size/xs:string(.)
        return if ($i eq $value) then
            <option value="{$i}" selected="true">{$i}</option>
        else
            <option value="{$i}">{$i}</option>
    )
};

declare function get-mo-offer-types(
    $value as item()*
) as element(option)* {
    (
        let $list := for $i in cts:search(/mormonorg-settings/offerTypes,())/offerType
                     return if ($i/offer/@name/fn:string(.) eq $value) then
                            <option value="{$i/offer/@name/fn:string(.)}" selected="true">{$i/offer/fn:string(.)}</option>
                        else
                            <option value="{$i/offer/@name/fn:string(.)}">{$i/offer/fn:string(.)}</option>
        return (<option value='none'>None</option>, $list)
    )
};


declare function get-mo-headers(
    $value as item()*
) as element(option)* {
    let $lang := (util:escape-chars(xdmp:get-request-field("lang", "eng")),'eng')[1]
    let $site as xs:string := xdmp:get-request-field('site')[. != ''][1]
    let $r :=
        (
            <option value="">Select a header</option>,
            for $i in  rice:get-bundle('mormonorg-header-list', $lang, $site, '/preview/')/properties/entry
            where fn:string-length($i/value/fn:string()) > 0
            order by $i/@key/fn:string()
            return if ($value eq $i/value/fn:string()) then
                <option value="{$i/value/fn:string()}" selected="true">{$i/@key/fn:string()}</option>
            else
                <option value="{$i/value/fn:string()}">{$i/@key/fn:string()}</option>
        )
    return $r
};

declare function get-mo-footers(
    $value as item()*
) as element(option)* {
    let $lang := (util:escape-chars(xdmp:get-request-field("lang", "eng")),'eng')[1]
    let $site as xs:string := xdmp:get-request-field('site')[. != ''][1]
    let $r :=
        (
            <option value="">Select a footer</option>,
            for $i in  rice:get-bundle('mormonorg-footer-list', $lang, $site, '/preview/')/properties/entry
            where fn:string-length($i/value/fn:string()) > 0
            order by $i/@key/fn:string()
            return if ($value eq $i/value/fn:string()) then
                <option value="{$i/value/fn:string()}" selected="true">{$i/@key/fn:string()}</option>
            else
                <option value="{$i/value/fn:string()}">{$i/@key/fn:string()}</option>
        )
    return $r
};

declare function get-mo-image-alignment (
    $value as item()*
) as element(option)* {
    (
        for $i in cts:search(/mormonorg-settings/image-alignment, ())/alignment/xs:string(.)
        return if ($i eq $value) then
            <option value="{$i}" selected="true">{$i}</option>
        else
            <option value="{$i}">{$i}</option>
    )
};

declare function get-mo-source-ids (
    $value as item()*
) as element(option)* {
    (
       <option value=''></option>,
        for $i in cts:search(/cuc-source-ids/source, ())
        return if ($i/@id/fn:string() eq $value) then
            <option value="{$i/@id}" selected="true">{$i/fn:string()}</option>
        else
            <option value="{$i/@id}">{$i/fn:string()}</option>
    )
};

declare function get-form-topics (
    $value as item()*
) as element(option)* {
    let $lang := (util:escape-chars(xdmp:get-request-field("lang", "eng")),'eng')[1]
    let $form-topics := mJson:transform-from-json(fn:doc('/preview/cms/content/_configuration/form-topics/'||$lang||'-form-topics.json')/node())
    return (
        <option value=''></option>,
        for $i in $form-topics/jsonb:json
        return
            if ($i/jsonb:id/text() eq $value) then
                <option value="{$i/jsonb:id/text()}" selected="true">{$i/jsonb:topic/text()}</option>
            else
                <option value="{$i/jsonb:id/text()}">{$i/jsonb:topic/text()}</option>
    )
};

declare function get-mo-cookie-ids(
    $value as item()*
) as element(option)* {
    let $cookies :=
        (
            <option value="">Select a cookie</option>,
            for $i in  rice:get-bundle('comeuntochrist-cookies', 'eng', 'churchofjesuschrist', '/preview/')/properties/entry  (:Language will always be 'eng' and site 'churchofjesuschrist since cookies are global':)
            where fn:string-length($i/value/fn:string()) > 0
            order by $i/@key/fn:string()
            return if ($value eq $i/value/fn:string()) then
                <option value="{$i/value/fn:string()}" selected="true">{$i/@key/fn:string()}</option>
            else
                <option value="{$i/value/fn:string()}">{$i/@key/fn:string()}</option>
        )
    return $cookies
};

declare function get-mo-personalization-reference-page-links(
    $value as item()*
) as element(option)* {
    let $lang := (util:escape-chars(xdmp:get-request-field("lang", "eng")),'eng')[1]
    let $site as xs:string := xdmp:get-request-field('site')[. != ''][1]
    let $uris := cts:search(/custom-page,
                              cts:and-query((
                                  cts:word-query('/internal-use-only/personalization',"wildcarded"),
                                  cts:element-value-query(xs:QName('site-context'), $site, 'exact'),
                                  cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('locale'), $lang, 'exact')
                               ))
                           )/@uri

    let $list := ( <option value="">Select a reference page</option>,
                 for $i in fn:distinct-values($uris)
                 return if ($value eq $i) then
                          <option value="{$i}" selected="true">{$i}</option>
                      else
                          <option value="{$i}">{$i}</option>
                )
    return $list
};

declare function get-mo-pageSubLevel1(
    $value as item()*
) as element(option)* {
    (
        <option value=""></option>,
        for $i in  rice:get-bundle('page-sub-level-1', 'eng', 'churchofjesuschrist', '/preview/')/properties/entry  (: hard coded the site and language because this bundle only exists in churchofjesuschrist/eng :)
        where fn:string-length($i/value/fn:string()) > 0
        order by $i/@key/fn:string()
        return if ($value eq $i/value/fn:string()) then
            <option value="{$i/value/fn:string()}" selected="true">{$i/@key/fn:string()}</option>
        else
            <option value="{$i/value/fn:string()}">{$i/@key/fn:string()}</option>
    )
};

declare function get-mo-pageSubLevel2(
    $value as item()*
) as element(option)* {
    (
        <option value=""></option>,
        for $i in  rice:get-bundle('page-sub-level-2', 'eng', 'churchofjesuschrist', '/preview/')/properties/entry (: hard coded the site and language because this bundle only exists in churchofjesuschrist/eng :)
        where fn:string-length($i/value/fn:string()) > 0
        order by $i/@key/fn:string()
        return if ($value eq $i/value/fn:string()) then
            <option value="{$i/value/fn:string()}" selected="true">{$i/@key/fn:string()}</option>
        else
            <option value="{$i/value/fn:string()}">{$i/@key/fn:string()}</option>
    )
};

declare function get-mo-predefined-questions(
    $value as item()*
) as element(option)* {
    let $currentDate := fn:current-dateTime()
    let $lang := (util:escape-chars(xdmp:get-request-field("lang", "eng")),'eng')[1]
    let $displayType := cts:search(/predefinedQuestionsConfig/displays/display, ())
    let $data := for $i in cts:search(/predefinedQuestions,
                                cts:and-query((
                                    cts:element-range-query(xs:QName('availableDate'), "<=", $currentDate),
                                    cts:element-attribute-value-query(xs:QName('predefinedQuestions'), xs:QName('locale'), $lang, 'exact')
                                )) )/question
                return $i
    return (
        <option value=""></option>,
        for $i in $data
        for $ii in $displayType[@category eq $i/type/fn:string()]/option/fn:string()
        let $key := fn:concat($i/@id, '~', $i/type/fn:string(), '~', $ii)
        let $desc := fn:concat($i/description/fn:string(), '~', $i/type/fn:string(), '~', $ii)
        order by xs:integer($i/sortOrder/fn:string())
        return
            if ($value eq $key) then
                <option value="{$key}" selected="true">{$desc}</option>
            else
                <option value="{$key}">{$desc}</option>
    )
};

declare function predefined-questions-save(
    $orig-file as element()?,
    $new-xml as element(),
    $form as element(ldse:formTemplate)?
) as element() {
    let $status := getVariable('status')
    let $action := getVariable('action')
    let $locale := getVariable('locale')
    let $predefined-questions := cts:search(/predefinedQuestions, cts:element-attribute-value-query(xs:QName('predefinedQuestions'), xs:QName('locale'), $locale, 'exact'))/question
    return if ($action eq 'add' or $orig-file/questions ne $new-xml/questions or $status eq 'ldse:preview' ) then
                let $predefined-questions-data :=
                    element predefined-questions-data {
                        for $i in $new-xml/questions/question
                        let $questionGuid := (fn:tokenize($i/questionGuid/fn:string(), '~'))[1]
                        return $predefined-questions[@id eq $questionGuid]
                    }
                return element mo-form-predefined-questions
                {
                    $new-xml/@*,
                    $new-xml/ldse:ldse-meta,
                    $predefined-questions-data,
                    $new-xml/* except ($new-xml/ldse:ldse-meta, $new-xml/predefined-questions-data)
                }
            else $new-xml
};
declare function get-mo-lang-overwrite(
    $value as item()*
) as element(option)* {

    let $locale := getVariable('locale')
    return
        (
            <option value=""></option>,
            for $i in  rice:get-bundle('sub-languages', 'eng', 'churchofjesuschrist', '/preview/')/properties/entry
            let $lang-id := $i/@key/fn:string()
            let $lang := (fn:tokenize($i/value/fn:string(), ' | '))[1]
            let $sub-lang := (fn:tokenize($i/value/fn:string(), ' | '))[3]
            where ($lang eq $locale)
            order by $sub-lang
            return if ($value eq $lang-id) then
                <option value="{$lang-id}" selected="true">{$sub-lang}</option>
            else
                <option value="{$lang-id}">{$sub-lang}</option>
        )
};

declare function mo-get-success-page-uri-list(
    $value as item()*
) as element(option)* {
    let $locale := getVariable('locale')
    let $site as xs:string := xdmp:get-request-field('site')[. != ''][1]
    let $root := rice:get-bundle('product-confirmation-config', $locale, $site, '/preview/')/properties/entry[@key eq 'success-page-prefix']/value/fn:string()
    let $list :=
        for $i in cts:search(/custom-page,
            cts:and-query((
                cts:directory-query('/preview/', 'infinity'),
                cts:element-attribute-range-query(xs:QName("ldse:document"), xs:QName("locale"), "=", $locale),
                cts:element-value-query(xs:QName("ldse:site-context"), $site, 'exact')
            ))
        )
        let $id := $i/@id/fn:string()
        let $uri := $i/@uri/fn:string()
        order by $i/@uri/fn:string()
        return if (fn:starts-with($i/@uri, $root)) then
            if ($value eq $id) then
                <option value="{$id}" selected="true">{$uri}</option>
            else
                <option value="{$id}">{$uri}</option>
        else ()
    return (
        <option value=""></option>,
        $list
    )
};

declare function mo-get-cancel-page-uri-list(
    $value as item()*
) as element(option)* {
    let $locale := getVariable('locale')
    let $site as xs:string := xdmp:get-request-field('site')[. != ''][1]
    let $root := rice:get-bundle('product-confirmation-config', $locale, $site, '/preview/')/properties/entry[@key eq 'cancel-page-prefix']/value/fn:string()
    let $list :=
        for $i in cts:search(/custom-page,
            cts:and-query((
                cts:directory-query('/preview/', 'infinity'),
                cts:element-attribute-range-query(xs:QName("ldse:document"), xs:QName("locale"), "=", $locale),
                cts:element-value-query(xs:QName("ldse:site-context"), $site, 'exact')
            ))
        )
        let $id := $i/@id/fn:string()
        let $uri := $i/@uri/fn:string()
        order by $i/@uri/fn:string()
        return if (fn:starts-with($i/@uri, $root)) then
            if ($value eq $id) then
                <option value="{$id}" selected="true">{$uri}</option>
            else
                <option value="{$id}">{$uri}</option>
        else ()
    return (
        <option value=""></option>,
        $list
    )
};

declare function get-mo-headings(
    $value as item()*
) as element(option)* {
    (
        for $i in cts:search(/mormonorg-settings/headings, ())/heading/xs:string(.)
        return if ($i eq $value) then
            <option value="{$i}" selected="true">{$i}</option>
        else
            <option value="{$i}">{$i}</option>
    )
};

declare function get-mo-body-font-size(
    $value as item()*
) as element(option)* {
    (
        for $i in cts:search(/mormonorg-settings/body-font-sizes, ())/font-value/xs:string(.)
        return if ($i eq $value) then
            <option value="{$i}" selected="true">{$i}</option>
        else
            <option value="{$i}">{$i}</option>
    )
};

declare function get-mo-aspect-ratios(
    $value as item()*
) as element(option)* {
    (
        for $i in cts:search(/mormonorg-settings/aspect-ratios, ())/ratio/xs:string(.)
        return if ($i eq $value) then
            <option value="{$i}" selected="true">{$i}</option>
        else
            <option value="{$i}">{$i}</option>
    )
};

declare function get-mo-aspect-ratios-emt(
    $value as item()*
) as element(option)* {
    (
        for $i in cts:search(/mormonorg-settings/aspect-ratios-emt, ())/ratio/xs:string(.)
        return if ($i eq $value) then
            <option value="{$i}" selected="true">{$i}</option>
        else
            <option value="{$i}">{$i}</option>
    )
};

declare function get-mo-ssu-locations(
    $value as item()*
) as element(option)* {
    let $locale := getVariable('locale')
    let $site as xs:string := xdmp:get-request-field('site')[. != ''][1]
    return (
        <option value=""></option>,
        for $i in  rice:get-bundle('SSU-locations', $locale, $site, '/preview/')/properties/entry
        where fn:string-length($i/@key) > 0
        order by $i/@key/fn:string()
        return if ($value eq $i/@key/fn:string()) then
            <option value="{$i/@key/fn:string()}" selected="true">{$i/@key/fn:string()}</option>
        else
            <option value="{$i/@key/fn:string()}">{($i/@key/fn:string())}</option>
    )
};
