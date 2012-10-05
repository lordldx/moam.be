function Index() {

    var that = this;
    var tooltip = new ToolTip();
    var timer = undefined;

    this.showHint = function () {
        tooltip.setText("Om te zoeken: typ iets in dit vak en druk op enter");
        tooltip.show(634, 404.5);
        clearTimeout(timer);
        timer = undefined;
    };

    this.hideHint = function () {
        tooltip.hide();
    };
    
    this.ready = function() {
        timer = setTimeout(that.showHint, 5000);
        var ms = $('#mainsearch');
        ms.keydown(function() {
            tooltip.hide(); 
            if (timer !== undefined) {
                clearTimeout(timer);
                timer=undefined;
            }
        });
        ms.focus();        
    };
}