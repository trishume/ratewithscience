var hide = function(element) {
    element.style.overflow = "hidden";
    element.style.height = getComputedStyle(element).height;
    element.style.transition = 'all .5s ease';
    element.offsetHeight = "" + element.offsetHeight; // force repaint
    element.style.height = '0';
    element.style.marginTop = "0";
    element.style.marginBottom = "0";
};
var show = function(element) {
    var prevHeight = element.style.height;
    element.style.height = 'auto';
    var endHeight = getComputedStyle(element).height;
    element.style.height = prevHeight;
    element.offsetHeight = "" + element.offsetHeight; // force repaint
    element.style.transition = 'all .5s ease';
    element.style.height = endHeight;
    element.style.marginTop = "";
    element.style.marginBottom = "";
    element.addEventListener('transitionend', function transitionEnd(event) {
        if (event.propertyName == 'height' && this.style.height == endHeight) {
            this.style.transition = '';
            this.style.height = 'auto';
            this.style.overflow = "visible";
        }
        this.removeEventListener('transitionend', transitionEnd, false);
    }, false);
};

var throttle = function(fn, threshhold, scope) {
    threshhold || (threshhold = 250);
    var last,
    deferTimer;
    return function () {
        var context = scope || this;

        var now = +new Date,
            args = arguments;
        if (last && now < last + threshhold) {
            // hold on to it
            clearTimeout(deferTimer);
            deferTimer = setTimeout(function () {
                last = now;
                fn.apply(context, args);
            }, threshhold);
        } else {
            last = now;
            fn.apply(context, args);
        }
    };
};

//key codes
var TAB = 9;
var ENTER = 13;

Array.prototype.forEach.call(document.querySelectorAll("input[type='text']"), function(element) {

    var suggestion = document.getElementById("suggestion_" + element.id);

    element.addEventListener("keyup", throttle(function(event) {
        $.ajax( {
            url: "http://en.wikipedia.org/w/api.php?action=opensearch&search=" + encodeURIComponent(element.value) + "&limit=1&namespace=0&format=json&callback=?",
            type:'GET',
            dataType: "jsonp",
            headers: { 'Api-User-Agent': 'Example/1.0' },
            success: function(result) {
                suggestion.innerHTML = result["1"];
                if (element.value.trim() != result["1"]) {
                    suggestion.classList.add("open");
                } else {
                    suggestion.classList.remove("open");
                }
            }
        } );
    }, 200));

    element.addEventListener("keydown", function(event) {
        if (event.keyCode == TAB) {
            element.value = suggestion.innerHTML;
        } else if (event.keyCode == ENTER) {
            document.getElementById("go").click();
        }
    });
});

Array.prototype.forEach.call(document.querySelectorAll(".suggestion"), function(element) {
    element.addEventListener("click", function() {
        var id = /suggestion_(.+)/.exec(element.id)[1];
        var input = document.getElementById(id);

        input.value = element.innerHTML;
        element.classList.remove("open");
    });
});


document.getElementById("go").addEventListener("click", function() {
    hide(document.getElementById("header"));
    show(document.getElementById("loading"));
    setTimeout(function() {
        var data = {
            start: ($("#start").val()==""?"David Hasselhoff":$("#start").val()),
            stop: ($("#end").val()==""?"Eiffel Tower":$("#end").val())
        };
        /* save the endpoints in the url */
        window.location.hash = $.param(data);
        $.ajax({
            url: "/api/findscale",
            //url: "data.txt",
            type: "GET",
            data: data,
            dataType: "json",
            success: function(result) {
                if (result.status > 2) { // success
                    var scale = document.getElementById("scale");
                    scale.classList.remove("quality");
                    if (result.status == 3) {
                        scale.classList.add("quality");
                    }
                    scale.innerHTML = "";
                    for (var i=0; i<result.path.length; i++) {
                        var item = "<div class='item'><h3>" + (i+1) + "</h3>"
                        item += "<a href='http://en.wikipedia.org/wiki/" + encodeURIComponent(result.path[i]) + "' target='_blanl'>" + result.path[i] + "</a>"
                        item += "<div class='bg'></div>";
                        item += "</div>";
                        scale.innerHTML += item;
                    }
                    hide(document.getElementById("loading"));
                    show(document.getElementById("results"));
                } else {
                    var errorMsgEl = document.getElementById("errormsg");
                    if(result.status == 0) {
                        errorMsgEl.innerHTML = "There's no path between these pages! This is super rare, you must be good at finding obscure pages.";
                    } else if(result.status == 1) {
                        errorMsgEl.innerHTML = "I can't find a Wikipedia page for your start point. This might be because I can't currently use redirects as endpoints.";
                    } else if(result.status == 2) {
                        errorMsgEl.innerHTML = "I can't find a Wikipedia page for your end point. This might be because I can't currently use redirects as endpoints.";
                    }
                    hide(document.getElementById("loading"));
                    show(document.getElementById("error"));
                }
            },
            error: function (jqXHR, textStatus, errorThrown) {
                hide(document.getElementById("loading"));
                show(document.getElementById("error"));
            }
        });
        if(window.ga) {
            window.ga('send', 'event', 'Ratings', 'search');
        }
    }, 500);
});

document.getElementById("again").addEventListener("click", function() {
    hide(document.getElementById("results"));
    show(document.getElementById("header"));
});

document.getElementById("close_error").addEventListener("click", function() {
    hide(document.getElementById("error"));
    show(document.getElementById("header"));
});

/* https://gist.github.com/varemenos/2531765 */
function getUrlVar(key){
    var result = new RegExp(key + "=([^&]*)", "i").exec(window.location.hash);
    return result && decodeURI(result[1].replace(/\+/g, ' ')) || "";
}

(function() {
    /* pull parameters from url */
    var start = getUrlVar("start");
    var stop = getUrlVar("stop");

    document.getElementById("start").value = start;
    document.getElementById("end").value = stop;

    /* if both are there then click the Go button */
    if (start !== "" && stop !== "") {
        /* wait a second to give a chance to peek at the endpoints */
        setTimeout(function() {
            document.getElementById("go").click();
        }, 1000)
    }
})();
