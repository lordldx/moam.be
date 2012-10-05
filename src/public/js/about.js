function About() {

    var that = this;
    var tooltip = new ToolTip();

    this.showPopupAll = function (e) {
        tooltip.setText("Dit zijn natuurlijk niet echt alle sites, maar op regelmatige basis worden hier nieuwe sites toegevoegd!");
        tooltip.show(e.pageX, e.pageY).hide(5000);
    };

    this.search = function () {
        var term = '"150 ml room"';
        $('#mainsearch').val(term);
        $('#searchform').submit();
    };

    this.showPopupKnownSites = function (e) {
        tooltip.setText("Momenteel enkel zesta.be");
        tooltip.show(e.pageX, e.pageY).hide(1000);
    };

    this.ready = function () {
        $.getJSON('/NumRecipesInDb', function (result) {
            if (result.Success) {
                $('#numRecipesInDb').text(result.NumRecipesInDb);
            }
        });

        $('#all').click(that.showPopupAll);
        $('#knownsites').click(that.showPopupKnownSites);        
        $('#TrySearch').click(that.search);
    };
}