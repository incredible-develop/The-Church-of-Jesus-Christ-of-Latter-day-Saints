module namespace config = "http://lds.org/code/modules/endpoint-configuration";

import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";

declare variable $configElements := (
    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/page(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/page.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="lang" required="true" as="string" repeatable="true"/>
            <param name="site" required="false" as="string" repeatable="true"/>
            <param name="uri" required="false" as="string" repeatable="true"/>
            <param name="url" required="false" as="string" repeatable="true"/>
            <param name="limit" required="false" as="int" repeatable="true"/>
            <param name="start" required="false" as="int" repeatable="true"/>
            <param name="tag" required="false" as="string" repeatable="true"/>
            <param name="audience" required="false" as="string" repeatable="true"/>
            <param name="hasCid" required="false" as="string" repeatable="false"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/auth-content(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/auth-content.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="lang" required="true" as="string" repeatable="true"/>
            <param name="site" required="false" as="string" repeatable="true"/>
            <param name="uri" required="false" as="string" repeatable="true"/>
            <param name="url" required="false" as="string" repeatable="true"/>
            <param name="limit" required="false" as="int" repeatable="true"/>
            <param name="start" required="false" as="int" repeatable="true"/>
            <param name="tag" required="false" as="string" repeatable="true"/>
            <param name="audience" required="false" as="string" repeatable="true"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/feedback(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/feedback.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="inProcess" required="false" as="boolean" repeatable="false"/>
            <param name="resultLimit" required="false" as="int" repeatable="false"/>
        </http>
        <http method="PUT">

        </http>
        <http method="DELETE">
            <param name="feedbackItemIds" required="true" as="string" repeatable="false"/>
        </http>
        <http method="POST">
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/cards(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/cards.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="lang" required="true" as="string" repeatable="true"/>
            <param name="inject" required="false" repeatable="false" type="int"/>
            <param name="types" required="false" repeatable="true" type="string"/>
            <param name="tags" required="false" repeatable="true" type="string"/>
            <param name="offset" required="false" repeatable="false" type="int"/>
            <param name="limit" required="false" repeatable="false" type="int"/>
            <param name="interested" required="false" repeatable="false" type="boolean"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/personalization/tags(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/personalization/tags.xqy">
        <accept>application/json</accept>
        <http method="GET">
        </http>
        <http method="POST">
            <param name="tags" required="true" as="string" repeatable="true"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/rice(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/rice.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="lang" required="false" as="string" repeatable="true"/>
            <param name="bundle" required="false" as="string" repeatable="true"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/sites(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/sites.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="lang" required="false" as="string" repeatable="true"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/site-properties(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/site-properties.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="lang" required="false" as="string" repeatable="true"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/source-content(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/source-content.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="lang" required="true" as="string" repeatable="false"/>
            <param name="uri" required="true" as="string" repeatable="false"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/tags(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/tags.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="tag" required="true" as="string" repeatable="true"/>
            <param name="lang" required="true" as="string" repeatable="true"/>
            <param name="site" required="true" as="string" repeatable="true"/>
            <param name="article" required="false" as="boolean" repeatable="true"/>
            <param name="video" required="false" as="boolean" repeatable="true"/>
            <param name="context" required="false" as="string" repeatable="true"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/authors(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/authors.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="author" required="true" as="string" repeatable="true"/>
            <param name="lang" required="true" as="string" repeatable="true"/>
            <param name="site" required="true" as="string" repeatable="true"/>
            <param name="article" required="false" as="boolean" repeatable="true"/>
            <param name="video" required="false" as="boolean" repeatable="true"/>
            <param name="context" required="false" as="string" repeatable="true"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/years(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/years.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="year" required="true" as="string" repeatable="true"/>
            <param name="lang" required="true" as="string" repeatable="true"/>
            <param name="site" required="true" as="string" repeatable="true"/>
            <param name="article" required="false" as="boolean" repeatable="true"/>
            <param name="video" required="false" as="boolean" repeatable="true"/>
            <param name="context" required="false" as="string" repeatable="true"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/filterValues(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/filterValues.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="type" required="true" as="string" repeatable="true"/>
            <param name="site" required="true" as="string" repeatable="true"/>
            <param name="lang" required="true" as="string" repeatable="true"/>
            <param name="article" required="false" as="boolean" repeatable="true"/>
            <param name="video" required="false" as="boolean" repeatable="true"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/nav-categories(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/nav-categories.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="site" required="true" as="string" repeatable="true"/>
            <param name="lang" required="false" as="string" repeatable="true"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/getbundle(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/getbundle.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="lang" required="true" as="string" repeatable="false"/>
            <param name="host" required="false" as="string" repeatable="false"/>
            <param name="site" required="false" as="string" repeatable="false"/>
            <param name="status" required="false" as="string" repeatable="false"/>
            <param name="bundle" required="true" as="string" repeatable="false"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/getbundlenames(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/getbundlenames.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="lang" required="true" as="string" repeatable="false"/>
            <param name="host" required="false" as="string" repeatable="false"/>
            <param name="site" required="false" as="string" repeatable="false"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/getpredefinedquestions(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/getpredefinedquestions.xqy">
        <accept>application/json</accept>
            <http method="GET">
                <param name="componentsiteid" required="true" as="string" repeatable="false"/>
                <param name="lang" required="false" as="string" repeatable="false"/>
            </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/titanImagesUsed(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/titanImagesUsed.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="lang" required="true" as="string" repeatable="false"/>
            <param name="id" required="true" as="string" repeatable="false"/>
            <param name="site" required="true" as="string" repeatable="false"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/productconfirmation(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/productconfirmation.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="pcid" required="true" as="string" repeatable="false"/>
            <param name="lang" required="false" as="string" repeatable="false"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/getpagelist(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/getpagelist.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="lang" required="true" as="string" repeatable="false"/>
            <param name="host" required="false" as="string" repeatable="false"/>
            <param name="site" required="false" as="string" repeatable="false"/>
            <param name="templates" required="false" as="string" repeatable="false"/>
            <param name="status" required="false" as="string" repeatable="false"/>
            <param name="path" required="false" as="string" repeatable="false"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/findpagelinks(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/findpagelinks.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="lang" required="true" as="string" repeatable="false"/>
            <param name="id" required="true" as="string" repeatable="false"/>
            <param name="site" required="true" as="string" repeatable="false"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/pageusedby(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/pageusedby.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="lang" required="true" as="string" repeatable="false"/>
            <param name="id" required="true" as="string" repeatable="false"/>
            <param name="site" required="true" as="string" repeatable="false"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/api/(v1|LATEST)/disablepublishing(\?.*)?$" endpoint="{$settings:shared-prefix}/api/v1/disablepublishing.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="site" required="true" as="string" repeatable="true"/>
            <param name="lang" required="false" as="string" repeatable="false"/>
        </http>
    </request>,

    <request xmlns="http://marklogic.com/appservices/rest" uri="^{$settings:shared-prefix}/authorization-callback(\?.*)?$" endpoint="{$settings:shared-prefix}/authorization-callback.xqy">
        <accept>application/json</accept>
        <http method="GET">
            <param name="code" required="true" as="string" repeatable="false"/>
            <param name="state" required="true" as="string" repeatable="false"/>
            <param name="lang" required="true" as="string" repeatable="false"/>
        </http>
    </request>

);

declare function getPage() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/page.xqy"]
};

declare function getAuthContent() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/auth-content.xqy"]
};

declare function getCardConfig() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/cards.xqy"]
};

declare function getPersonalizationTagsConfig() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/personalization/tags.xqy"]
};

declare function getFeedbackConfig() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/feedback.xqy"]
};

declare function getConfigElements(){
    $configElements
};

declare function getDictionary() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/rice.xqy"]
};

declare function getSites() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/sites.xqy"]
};

declare function getTags() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/tags.xqy"]
};

declare function getAuthors() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/authors.xqy"]
};

declare function getArticlesByYears() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/years.xqy"]
};

declare function getFilterValues() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/filterValues.xqy"]
};

declare function getSourceContent() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/source-content.xqy"]
};
declare function getNavCategories() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/nav-categories.xqy"]
};

declare function getBundle() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/getbundle.xqy"]
};

declare function getBundleNames() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/getbundlenames.xqy"]
};

declare function getPedefinedQuestionsConfig() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/getpredefinedquestions.xqy"]
};

declare function getTitanImagesUsed() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/titanImagesUsed.xqy"]
};
declare function productConfirmation() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/productconfirmation.xqy"]
};

declare function getPageList() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/getpagelist.xqy"]
};

declare function findpagelinks() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/findpagelinks.xqy"]
};

declare function pageusedby() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/pageusedby.xqy"]
};

declare function disablePublishing() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/disablepublishing.xqy"]
};

declare function authorizationCallback() {
    $configElements[@endpoint = $settings:shared-prefix || "/api/v1/authorization-callback.xqy"]
};
