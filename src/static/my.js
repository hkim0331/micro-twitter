var output;

function init() {
    ws = document.getElementById("ws").value;
    output = document.getElementById("timeline");
    createWebSocket(ws);
}

function createWebSocket(ws) {
    websocket = new WebSocket(ws);
    websocket.onopen    = function(evt) { onOpen(evt) };
    websocket.onclose   = function(evt) { onClose(evt) };
    websocket.onmessage = function(evt) { onMessage(evt) };
    websocket.onerror   = function(evt) { onError(evt) };
}

function onOpen(evt) {
//must not removed following two lines. why?
//    writeToScreen("");
    doSend("WebSocket rocks");

    // timer = setInterval(function() {
    //     doSend("ping");
    //     console.log("doSend ping");
    // }, 10000);
}

function onClose(evt) {
    writeToScreen("onClose: 再接続はページを再読みしてください。");
}

function onMessage(evt) {
    console.log("evt.data:" + evt.data);
    writeToScreen(evt.data);
}

function onError(evt) {
    writeToScreen('<span style="color: red;">ERROR:</span>' + evt.data);
}

function doSend(message) {
    websocket.send(message);
}

function writeToScreen(message) {
    output.innerHTML = message;
}

window.addEventListener("load", init, false);
