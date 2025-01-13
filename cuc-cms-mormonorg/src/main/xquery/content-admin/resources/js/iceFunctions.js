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

function handleTeaserArticleAutofill(lang, site, id)
{
    $.get('/si/sites/si/api/article.xqy?lang=' + lang + '&id=' + id, function(articleJson){
        var article = articleJson.data[0],
            uri = article['uri-definition'][0]['uri-path'],
            imgSrc = article.content.image ? article.content.image.src.replace(/http.*org|com|net/, "") || "" : "";

        article['uri-definition'].forEach(function(uriDefinition) {
            if (uriDefinition['site-context'] == site) {
                uri = uriDefinition['uri-path'];
            }
        });

        $('[name=title]')[0] ? $('[name=title]')[0].value = stripHTMLTags(article.content.title) : {};
        $('[name=text]')[0] ? $('[name=text]')[0].value = stripHTMLTags(article.meta.abstract) : {};
        $('[name=link]')[0] ? $('[name=link]')[0].value = stripHTMLTags(uri) : {};
        if ($('[name=image]')[0]) { $('[name=image]')[0].value = stripHTMLTags(imgSrc); $('#image-preview').attr('src', imgSrc); };
        $('[name=alt]')[0] ? $('[name=alt]')[0].value = stripHTMLTags(article.content.image.alt) : {};
    });
}

function stripHTMLTags(str)
{
    return str ? str.replace(/<(?:.|\n)*?>/gm, '').trim() : '';
}
