$(function () {
    $('select.inputTypes').on('change', function () {
        var selected = $(this).find('option:selected');
        if ( $(selected).val() === 'dynamicXml' ) {
            $(this).closest('ul').find('input.nodeOptions').closest('dl').attr('style', 'display: none !important');
            $(this).closest('ul').find('input.nodeXpath').closest('dl').attr('style', 'display: none !important').removeClass('required');
            $(this).closest('ul').find('.itemAttrs').closest('dl').attr('style', 'display: none !important');
            $(this).closest('ul').find('.childItems').closest('dl').show();
        } else {
            $(this).closest('ul').find('input.nodeOptions').closest('dl').show();
            $(this).closest('ul').find('input.nodeXpath').closest('dl').show().addClass('required');
            $(this).closest('ul').find('.childItems').closest('dl').attr('style', 'display: none !important');
            $(this).closest('ul').find('.itemAttrs').closest('dl').show();
        }
    });
});