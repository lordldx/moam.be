function Pager () {
    var NUM_DISPLAY_PAGES = 10;
    var pagerElement = $('#pager');

    this.draw = function(currentPage, lastPage) {
        var drawFirst = true;
        var drawPrevious = true;
        var drawLast = true;
        var drawNext = true;

        var start = currentPage - (NUM_DISPLAY_PAGES / 2);
        if (start < 0) {
            start = 0;
        }
        drawFirst = drawPrevious = (currentPage > 0);

        var end = currentPage + (NUM_DISPLAY_PAGES / 2) - 1;
        if (end >= lastPage) {            
            end = lastPage;
        }
        drawLast = drawNext = (currentPage < lastPage);

        if (drawFirst) {
            pagerElement.append('<li class="pager-item pager-item-first"><a href="#" onclick="getPage(0)">&lt;&lt;</a></li>');
        }
        if (drawPrevious) {
            pagerElement.append('<li class="pager-item pager-item-previous"><a href="#" onclick="getPage(' + (currentPage - 1) + ')">&lt;</a></li>');
        }
        if (start != 0) {
            pagerElement.append('<li class="pager-item pager-item-more">...</li>');
        }
        for (var p = start; p <= end; ++p) {
            var extra_class = '';
            var anchor_start = '';
            var anchor_end = '';
            if (p == currentPage) {
                extra_class = ' pager-item-current';
            } else {
                anchor_start = '<a href="#" onclick="getPage(' + p + ')">';
                anchor_end = '</a>';
            }
            pagerElement.append('<li class="pager-item' + extra_class + '">' + anchor_start + (p + 1) + anchor_end + '</li>');
        }
        if (end != lastPage) {
            pagerElement.append('<li class="pager-item pager-item-more">...</li>');
        }
        if (drawNext) {
            pagerElement.append('<li class="pager-item pager-item-next"><a href="#" onclick="getPage(' + (currentPage + 1) + ')">&gt;</a></li>');
        }
        if (drawLast) {
            pagerElement.append('<li class="pager-item pager-item-last"><a href="#" onclick="getPage(' + lastPage + ')">&gt;&gt;</a></li>');
        }
    };

};