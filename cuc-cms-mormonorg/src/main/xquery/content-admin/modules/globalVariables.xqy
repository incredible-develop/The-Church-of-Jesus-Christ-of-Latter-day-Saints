(:-------------------------------------------------------------------------------------------------------------------------------------:
     Copyright 2013 Intellectual Reserve, Inc.  All rights reserved.  This notice may not be removed.
 :-------------------------------------------------------------------------------------------------------------------------------------:)
xquery version "1.0-ml";

module namespace g = "http://lds.org/code/lds-edit/content-admin/globalVariables";

import module namespace c = "http://lds.org/code/shared/common/common-functions" at "/shared/common/commonFunctions.xqy";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace r = "http://lds.org/code/shared/lds-edit/fast-i18n" at "/rice/modules/fast-i18n.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace ldseUtil = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

(: Variables related to language/country/locale :)
declare variable $g:lang as xs:string := ldseUtil:escape-chars(xdmp:get-request-field("lang", "eng")[1]);
declare variable $g:clang as xs:string := ldseUtil:escape-chars(xdmp:get-request-field("clang", $g:lang)[1]);
declare variable $g:country as xs:string := fn:lower-case(ldseUtil:escape-chars(xdmp:get-request-field("country", "")[1]));
declare variable $g:locale as xs:string := fn:string-join(($g:clang, $g:country), '-');
declare function g:locale() {$g:locale};

(: Variables related to request :)
declare variable $g:orig-path as xs:string := fn:tokenize(xdmp:get-original-url(), "\?")[1];
declare variable $g:redirect-path as xs:string := fn:tokenize(xdmp:get-request-url(), "\?")[1];

(: Variables related to host and environment :)
declare variable $g:context as xs:string := c:getContext();
declare variable $g:is-preview as xs:boolean := $g:context eq '/preview/';
declare variable $g:env as xs:string? := $settings:environment;
declare variable $g:cdn-path as xs:string? := $settings:cdn-path;
declare variable $g:resource-path as xs:string := ($core:ldse-settings/ldse:resource-path, '')[1];
declare variable $g:bcs-path as xs:string? := $settings:bcs-path;
declare variable $g:shared-prefix as xs:string? := $settings:shared-prefix;
declare variable $g:ldse-settings := $settings:ldse-settings;
declare variable $g:site as xs:string := 'seminary-and-institute';
declare variable $g:site-prefix as xs:string := '/';
declare variable $g:host as xs:string? := $ldseUtil:host;
declare variable $g:is-local as xs:boolean := fn:contains($host, "local");
declare variable $g:protocol as xs:string := ldseUtil:get-protocol();
declare variable $g:host-prefix as xs:string := $settings:shared-prefix;

(: Other variables :)
declare variable $g:omniture-root as xs:string? := r:get-value('eng', 'general:omnitureSiteRoot');
declare variable $g:inf as xs:string := "infinity";
declare variable $g:site-properties as element(siteProperties) := (cts:search(/siteProperties[@application eq 'family-history'], cts:directory-query($g:context, $g:inf)))[1];
declare variable $g:application as xs:string := $g:site-properties/@application;
declare variable $g:ldse-namespace as xs:string := "http://lds.org/code/lds-edit";
declare variable $g:img-service-name as xs:string := 'imageRenderingService';
declare variable $g:current-date as xs:date := xs:date(fn:format-date(fn:current-date(), '[Y0001]-[M01]-[D01]', $g:lang, (), ()));
declare variable $g:current-date-string as xs:string := fn:format-date(fn:current-date(), '[Y0001]-[M01]-[D01]', 'eng', (), ());
declare variable $g:current-date-time as xs:dateTime := fn:current-dateTime();

(: User variables :)
declare variable $g:accountId as xs:string? := ac:getAccountId();
declare variable $g:personId as xs:string? := ac:getPersonId();
declare variable $g:username as xs:string? := ac:getUserName();

declare variable $g:CONTENT_VIDEO as xs:string := 'video';
declare variable $g:HOMEPAGE_HERO as xs:string := 'homepage-hero';
declare variable $g:EMERGENCY_RESPONSE as xs:string := 'emergency-response';
declare variable $g:CONTENT_PROMOTION as xs:string := 'content-promotion';
declare variable $g:HOMEPAGE_QUOTE as xs:string := 'homepage-quote';
declare variable $g:HOMEPAGE_STEP as xs:string := 'homepage-step';
declare variable $g:WHAT_WE_DO_HERO as xs:string := 'what-we-do-hero';
declare variable $g:TEASER as xs:string := 'teaser';
declare variable $g:VIDEOS_HERO as xs:string := 'videos-hero';
declare variable $g:VIDEO as xs:string := 'video';
declare variable $g:WHAT_WE_DO_VIDEO as xs:string := 'lds-what-we-do-video';
declare variable $g:WHAT_WE_DO as xs:string := 'what-we-do';
declare variable $g:LDS_VIDEO as xs:string := 'lds-video';
declare variable $g:NEWS_HERO as xs:string := 'news-hero';
declare variable $g:NEWS as xs:string := 'news';
declare variable $g:NEWS_EXTERNAL_LINK as xs:string := 'news-external-link';
declare variable $g:LDS_CHARITIES_UPDATES as xs:string := 'lds-charities-updates';
declare variable $g:STORIES_FROM_THE_FIELD as xs:string := 'stories-from-the-field';
declare variable $g:AROUND_THE_WEB as xs:string := 'around-the-web';
declare variable $g:BASIC_PAGE as xs:string := 'basic-page';
declare variable $g:INITIATIVE as xs:string := 'initiative';
declare variable $g:INTERNAL_AD as xs:string := 'internal-ad';
declare variable $g:NAVIGATION_HEADER_LINKS as xs:string := 'navigation-header-links';
declare variable $g:NAVIGATION_FOOTER_LINKS as xs:string := 'navigation-footer-links';
declare variable $g:CONTENT_CURATION as xs:string := 'content-curation';
declare variable $g:COUNTRY as xs:string := 'country';
declare variable $g:DICTIONARY as xs:string := 'dictionary';
declare variable $g:SITE_REDIRECTS as xs:string := 'site-redirects';
declare variable $g:HELP_HERO as xs:string := 'help-hero';
declare variable $g:HELP_GET_INVOLVED as xs:string := 'help-get-involved';
declare variable $g:HELP_GET_INSPIRED as xs:string := 'help-get-inspired';

declare variable $g:TAXONOMY as xs:string := 'taxonomy';
declare variable $g:TAXONOMIES_ALL as xs:string* := ($g:NEWS_CATEGORY, $g:VIDEOS_CATEGORY);
declare variable $g:NEWS_CATEGORY as xs:string := 'news-category';
declare variable $g:VIDEOS_CATEGORY as xs:string := 'videos-category';

declare variable $g:CURATIONS_ALL as xs:string* := ($g:CURATION_HOME_HEROES, $g:CURATION_EMERGENCY_RESPONSE, $g:CURATION_NEWS_HERO, $g:CURATION_NEWS_ARTICLE, $g:CURATION_EXTERNAL_STORIES, $g:CURATION_NEWS_HERO, $g:CURATION_VIDEO_HERO, $g:CURATION_INTERNAL_ADS, $g:CURATION_STORIES_FROM_THE_FIELD, $g:CURATION_GET_INSPIRED_HERO, $g:CURATION_GET_INSPIRED_VIDEOS, $g:CURATION_WHAT_WE_DO_HERO, $g:CURATION_WHAT_WE_DO_TEASERS);
declare variable $g:CURATION_HOME_HEROES as xs:string := 'curation-home-heroes';
declare variable $g:CURATION_EMERGENCY_RESPONSE as xs:string := 'curation-emergency-response';
declare variable $g:CURATION_NEWS_HERO as xs:string := 'curation-news-hero';
declare variable $g:CURATION_NEWS_ARTICLE as xs:string := 'curation-news-article';
declare variable $g:CURATION_EXTERNAL_STORIES as xs:string := 'curation-external-stories';
declare variable $g:CURATION_VIDEO_HERO as xs:string := 'curation-video-hero';
declare variable $g:CURATION_INTERNAL_ADS as xs:string := 'curation-internal-ads';
declare variable $g:CURATION_GET_INSPIRED_HERO as xs:string := 'curation-get-inspired-hero';
declare variable $g:CURATION_GET_INSPIRED_VIDEOS as xs:string := 'curation-get-inspired-videos';
declare variable $g:CURATION_WHAT_WE_DO_HERO as xs:string := 'curation-what-we-do-hero';
declare variable $g:CURATION_WHAT_WE_DO_TEASERS as xs:string := 'curation-what-we-do-teasers';
declare variable $g:CURATION_STORIES_FROM_THE_FIELD as xs:string := 'curation-stories-from-the-field';


declare variable $g:INITIATIVE_ALL as xs:string* := ($g:INITIATIVE_WHEELCHAIRS, $g:INITIATIVE_CLEAN_WATER, $g:INITIATIVE_EMERGENCY_RESPONSE, $g:INITIATIVE_FOOD_PRODUCTION, $g:INITIATIVE_VISION_CARE, $g:INITIATIVE_NEONATAL, $g:INITIATIVE_IMMUNIZATION, $g:INITIATIVE_OTHER_EFFORTS);
declare variable $g:INITIATIVE_WHEELCHAIRS as xs:string := 'wheelchair';
declare variable $g:INITIATIVE_CLEAN_WATER as xs:string := 'clean-water';
declare variable $g:INITIATIVE_EMERGENCY_RESPONSE as xs:string := 'emergency-response';
declare variable $g:INITIATIVE_FOOD_PRODUCTION as xs:string := 'benson-food';
declare variable $g:INITIATIVE_VISION_CARE as xs:string := 'vision-care';
declare variable $g:INITIATIVE_NEONATAL as xs:string := 'neonatal-resuscitation';
declare variable $g:INITIATIVE_IMMUNIZATION as xs:string := 'immunization';
declare variable $g:INITIATIVE_OTHER_EFFORTS as xs:string := 'other-efforts';

declare variable $g:CUSTOM_PAGE as xs:string := 'custom-page';
declare variable $g:CUSTOM_PAGES_ALL as xs:string* := ($g:CUSTOM_PAGE_HOME, $g:CUSTOM_PAGE_HELP, $g:CUSTOM_PAGE_NEWS_HOME, $g:CUSTOM_PAGE_WHAT_WE_DO);
declare variable $g:CUSTOM_PAGE_HOME as xs:string := 'custom-page-home';
declare variable $g:CUSTOM_PAGE_HELP as xs:string := 'custom-page-help';
declare variable $g:CUSTOM_PAGE_NEWS_HOME as xs:string := 'custom-page-news-home';
declare variable $g:CUSTOM_PAGE_WHAT_WE_DO as xs:string := 'custom-page-what-we-do';
