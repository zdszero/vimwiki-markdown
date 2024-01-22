function setStickyMenu() {

    var options = {
        bottoming: false,
        inner_scrolling: false
    };

    var sticky = "#TOC";
    var width = $(window).width();

    if (width >= 768) {
        console.log('fold in');
        $(sticky).stick_in_parent(options);
        $(".well ul").attr('id', 'accordion-1');
    } else {
        $(".well ul").attr('id', '');
        $(sticky).trigger("sticky_kit:detach");
        console.log('fold out');

    }
};

$(document).ready(function () {
    $(window).on('resize', function () {

        setStickyMenu();
    });
});
function doAccordion() {

    $("#accordion-1").dcAccordion({
        eventType: 'click',
        autoClose: false,
        saveState: false,
        disableLink: false,
        speed: 0,
        showCount: true,
        autoExpand: true,
        cookie: 'dcjq-accordion-1',
        classExpand: 'dcjq-current-parent'
    });
}

$(document).ready(function () {
    setStickyMenu();
    doAccordion();
});

$(document).ready(function () {
    $('table').addClass("table");
});
