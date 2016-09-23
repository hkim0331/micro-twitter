//var output;

function init() {
    ws = document.getElementById("ws").value;
//    output = document.getElementById("timeline");
    testWebSocket(ws);
}

function testWebSocket(ws) {
    websocket = new WebSocket(ws);
    websocket.onopen    = function(evt) { onOpen(evt) };
    websocket.onclose   = function(evt) { onClose(evt) };
    websocket.onmessage = function(evt) { onMessage(evt) };
    websocket.onerror   = function(evt) { onError(evt) };
}

function onOpen(evt) {
    writeToScreen("");//must not removed.
    doSend("WebSocket rocks");
}

function onClose(evt) {
    writeToScreen("再接続はページを再読みしてください。");
}

function onMessage(evt) {
    writeToScreen(evt.data);
}

function onError(evt) {
    writeToScreen('<span style="color: red;">ERROR:</span>' + evt.data);
}

function doSend(message) {
    websocket.send(message);
}

function writeToScreen(message) {
//    output.innerHTML = message;
}

window.addEventListener("load", init, false);
