function ToolTip() {

    var that = this;
    var timerId = null;

    this.show = function (x, y) {
        doHide(0);
        if (x === undefined) {
            x = 0;
        }
        if (y === undefined) {
            y = 0;
        }

        var tooltip = $('#ToolTip');        
        tooltip.css('left', x - tooltip.width()).css('top', y - tooltip.height());
        tooltip.show();
        return that;
    };

    this.hide = function (delay) {
        if (timerId !== null) {
            clearTimeout(timerId);
        }

        if (delay === undefined) {
            doHide(750);
        } else {
            timerId = setTimeout(doHide, delay, 750);
        }
    };

    var doHide = function(interval) {
        $('#ToolTip').fadeOut(interval);
    }

    this.setText = function (text) {
        $('#ToolTipMain').text(text);
        return that;
    };

    this.clear = function () {
        $('#ToolTipMain').text('');
        return that;
    }
}