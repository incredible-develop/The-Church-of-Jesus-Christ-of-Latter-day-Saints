var cr = {}; //courseResources;
cr.limitManuals = function (btn, count, maxCount) {
    if (count >= maxCount) {
        btn.hide();
    }
    else{
        btn.show();
    }
};

cr.handleManuals = function (maxCount) {
    var manual = $('.dynamic-manual');
    var addButton = $('.dynamic-manual').siblings('.ldse-add');

    manual.click(function () {
        cr.limitManuals(addButton, $('.dynamic-manual>li').length, maxCount);
    });
    addButton.click(function () {
        cr.limitManuals(addButton, $('.dynamic-manual>li').length + 1, maxCount);
    });

    cr.limitManuals(addButton, $('.dynamic-manual>li').length, maxCount);
}

function handleTeaserVideoAutofill(lang, site, id)
{
    $.get('/si/sites/si/api/video?lang=' + lang + '&id=' + id, function(videoJson){
        var video = videoJson.data[0],
            imgSrc = video.image ? video.image.src.replace(/http.*org|com|net/, "") || "" : "";


        $('[name=title]')[0] ? $('[name=title]')[0].value = stripHTMLTags(video.title) : {};
        $('[name=text]')[0] ? $('[name=text]')[0].value = stripHTMLTags(video.body) : {};
        $('[name=link]')[0] ? $('[name=link]')[0].value = stripHTMLTags(video.uri) : {};
        if ($('[name=image]')[0]) { $('[name=image]')[0].value = stripHTMLTags(imgSrc); $('#image-preview').attr('src', imgSrc); };
        $('[name=alt]')[0] ? $('[name=alt]')[0].value = stripHTMLTags(video.image.alt) : {};
    });
}

function handleTeaserArticleAutofill(lang, site, id)
{
    $.get('/si/sites/si/api/article?lang=' + lang + '&id=' + id, function(articleJson){
        var article = articleJson.data[0],
            uri,
            imgSrc = article.content.image ? article.content.image.src.replace(/http.*org|com|net/, "") || "" : "";

        if (article['uri-definition']) {
            article['uri-definition'].forEach(function (uriDefinition) {
                if (uriDefinition['site-context'] == site) {
                    uri = uriDefinition['uri-path'];
                }
            });
        }
        else if (article.uri){ uri=article.uri }

        $('[name=title]')[0] ? $('[name=title]')[0].value = stripHTMLTags(article.content.title) : {};
        $('[name=text]')[0] ? $('[name=text]')[0].value = stripHTMLTags(article.meta.abstract) : {};
        $('[name=link]')[0] ? $('[name=link]')[0].value = stripHTMLTags(uri) : {};
        if ($('[name=image]')[0]) { $('[name=image]')[0].value = stripHTMLTags(imgSrc); $('#image-preview').attr('src', imgSrc); };
        $('[name=alt]')[0] ? $('[name=alt]')[0].value = stripHTMLTags(article.content.image.alt) : {};
    });
}
function handleRelatedArticleAutofill(lang, site, id, selector)
{
    $.get(sharedPrefix + '/api/v1/article?lang=' + lang + '&id=' + id, function(articleJson) {
        var article = articleJson.data[0],
            uri,
            imgSrc = article.content.image ? article.content.image.src.replace(/http.*org|com|net/, "") || "" : "",
            imgAlt = article.content.image && article.content.image.alt ? article.content.image.alt : "";

        if (article['uri-definition']) {
            article['uri-definition'].forEach(function (uriDefinition) {
                if (uriDefinition['site-context'] == site) {
                    uri = uriDefinition['uri-path'];
                }
            });
        }
        else if (article.uri){uri=article.uri}

        $(selector).find('.title-input')[0] ? $(selector).find('.title-input')[0] .value = stripHTMLTags(article.content["article-title"]) : {};
        $(selector).find('.author-input')[0] ? $(selector).find('.author-input')[0] .value = stripHTMLTags(article.content.byline) : {};
        $(selector).find('.subhead1')[0] ? $(selector).find('.subhead1')[0] .value = stripHTMLTags(imgAlt) : {};
        $(selector).find('.subhead2')[0] ? $(selector).find('.subhead2')[0] .value = stripHTMLTags(article.content["date-display"]) : {};
        $(selector).find('.link-input')[0] ? $(selector).find('.link-input')[0] .value = stripHTMLTags(uri) : {};
        if($(selector).find('.img-input')[0]) {
            $(selector).find('.img-input')[0] .value = stripHTMLTags(imgSrc);
            $(selector).find('img').attr('src', imgSrc);
        }
    });
}

function initChosen(){

    $(".chosen-select").chosen({no_results_text: "No results found matching your query."});
    $(".chosen-select").closest(".select").removeClass("select")
}

function stripHTMLTags(str)
{
    return str ? str.replace(/<(?:.|\n)*?>/gm, '').trim() : '';
}
