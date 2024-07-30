/*
 * Copyright 2015 Eric ALBER
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * Modifications Copyright (C) 2021 InterSystems Corporation
 */

"use strict"

var webui = webui || {};

webui.repo = "/";

webui.COLORS = ["#ffab1d", "#fd8c25", "#f36e4a", "#fc6148", "#d75ab6", "#b25ade", "#6575ff", "#7b77e9", "#4ea8ec", "#00d0f5", "#4eb94e", "#51af23", "#8b9f1c", "#d0b02f", "#d0853a", "#a4a4a4",
                "#ffc51f", "#fe982c", "#fd7854", "#ff705f", "#e467c3", "#bd65e9", "#7183ff", "#8985f7", "#55b6ff", "#10dcff", "#51cd51", "#5cba2e", "#9eb22f", "#debe3d", "#e19344", "#b8b8b8",
                "#ffd03b", "#ffae38", "#ff8a6a", "#ff7e7e", "#ef72ce", "#c56df1", "#8091ff", "#918dff", "#69caff", "#3ee1ff", "#72da72", "#71cf43", "#abbf3c", "#e6c645", "#eda04e", "#c5c5c5",
                "#ffd84c", "#ffb946", "#ff987c", "#ff8f8f", "#fb7eda", "#ce76fa", "#90a0ff", "#9c98ff", "#74cbff", "#64e7ff", "#7ce47c", "#85e357", "#b8cc49", "#edcd4c", "#f9ad58", "#d0d0d0",
                "#ffe651", "#ffbf51", "#ffa48b", "#ff9d9e", "#ff8de1", "#d583ff", "#97a9ff", "#a7a4ff", "#82d3ff", "#76eaff", "#85ed85", "#8deb5f", "#c2d653", "#f5d862", "#fcb75c", "#d7d7d7",
                "#fff456", "#ffc66d", "#ffb39e", "#ffabad", "#ff9de5", "#da90ff", "#9fb2ff", "#b2afff", "#8ddaff", "#8bedff", "#99f299", "#97f569", "#cde153", "#fbe276", "#ffc160", "#e1e1e1",
                "#fff970", "#ffd587", "#ffc2b2", "#ffb9bd", "#ffa5e7", "#de9cff", "#afbeff", "#bbb8ff", "#9fd4ff", "#9aefff", "#b3f7b3", "#a0fe72", "#dbef6c", "#fcee98", "#ffca69", "#eaeaea",
                "#763700", "#9f241e", "#982c0e", "#a81300", "#80035f", "#650d90", "#082fca", "#3531a3", "#1d4892", "#006f84", "#036b03", "#236600", "#445200", "#544509", "#702408", "#343434",
                "#9a5000", "#b33a20", "#b02f0f", "#c8210a", "#950f74", "#7b23a7", "#263dd4", "#4642b4", "#1d5cac", "#00849c", "#0e760e", "#287800", "#495600", "#6c5809", "#8d3a13", "#4e4e4e",
                "#c36806", "#c85120", "#bf3624", "#df2512", "#aa2288", "#933bbf", "#444cde", "#5753c5", "#1d71c6", "#0099bf", "#188018", "#2e8c00", "#607100", "#907609", "#ab511f", "#686868",
                "#e47b07", "#e36920", "#d34e2a", "#ec3b24", "#ba3d99", "#9d45c9", "#4f5aec", "#615dcf", "#3286cf", "#00abca", "#279227", "#3a980c", "#6c7f00", "#ab8b0a", "#b56427", "#757575",
                "#ff911a", "#fc8120", "#e7623e", "#fa5236", "#ca4da9", "#a74fd3", "#5a68ff", "#6d69db", "#489bd9", "#00bcde", "#36a436", "#47a519", "#798d0a", "#c1a120", "#bf7730", "#8e8e8e"]

webui.peopleIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-people-fill" viewBox="0 0 16 16">'+
                        '<path d="M7 14s-1 0-1-1 1-4 5-4 5 3 5 4-1 1-1 1H7zm4-6a3 3 0 1 0 0-6 3 3 0 0 0 0 6z"/>'+
                        '<path fill-rule="evenodd" d="M5.216 14A2.238 2.238 0 0 1 5 13c0-1.355.68-2.75 1.936-3.72A6.325 6.325 0 0 0 5 9c-4 0-5 3-5 4s1 1 1 1h4.216z"/>'+
                        '<path d="M4.5 8a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z"/>'+
                    '</svg>'
webui.circlePlusIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="#eee" class="bi bi-plus-circle-fill" viewBox="0 0 16 16">'+
                            '<path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0zM8.5 4.5a.5.5 0 0 0-1 0v3h-3a.5.5 0 0 0 0 1h3v3a.5.5 0 0 0 1 0v-3h3a.5.5 0 0 0 0-1h-3v-3z"/>'+
                        '</svg>'
webui.refreshIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" fill="#eee" class="bi bi-arrow-repeat" viewBox="0 0 16 16">'+
                        '<path d="M11.534 7h3.932a.25.25 0 0 1 .192.41l-1.966 2.36a.25.25 0 0 1-.384 0l-1.966-2.36a.25.25 0 0 1 .192-.41zm-11 2h3.932a.25.25 0 0 0 .192-.41L2.692 6.23a.25.25 0 0 0-.384 0L.342 8.59A.25.25 0 0 0 .534 9z"/>'+
                        '<path fill-rule="evenodd" d="M8 3c-1.552 0-2.94.707-3.857 1.818a.5.5 0 1 1-.771-.636A6.002 6.002 0 0 1 13.917 7H12.9A5.002 5.002 0 0 0 8 3zM3.1 9a5.002 5.002 0 0 0 8.757 2.182.5.5 0 1 1 .771.636A6.002 6.002 0 0 1 2.083 9H3.1z"/>'+
                    '</svg>'
webui.largeXIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-x-lg" viewBox="0 0 16 16">'+
                        '<path fill-rule="evenodd" clip-rule="evenodd" d="M13.854 2.146a.5.5 0 0 1 0 .708l-11 11a.5.5 0 0 1-.708-.708l11-11a.5.5 0 0 1 .708 0Z" fill="#000"/>'+
                        '<path fill-rule="evenodd" clip-rule="evenodd" d="M2.146 2.146a.5.5 0 0 0 0 .708l11 11a.5.5 0 0 0 .708-.708l-11-11a.5.5 0 0 0-.708 0Z" fill="#000"/>'+
                    '</svg>'
webui.checkIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" fill="#eeeeee" class="bi bi-check2" viewBox="0 0 16 16">'+
                      '<path d="M13.854 3.646a.5.5 0 0 1 0 .708l-7 7a.5.5 0 0 1-.708 0l-3.5-3.5a.5.5 0 1 1 .708-.708L6.5 10.293l6.646-6.647a.5.5 0 0 1 .708 0z"/>'+
                  '</svg>'
webui.warningIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="#dc3545" class="bi bi-exclamation-circle-fill" viewBox="0 0 16 16">'+
                        '<path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0zM8 4a.905.905 0 0 0-.9.995l.35 3.507a.552.552 0 0 0 1.1 0l.35-3.507A.905.905 0 0 0 8 4zm.002 6a1 1 0 1 0 0 2 1 1 0 0 0 0-2z"></path>'+
                    '</svg>'
webui.settingsIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="#eee" class="bi bi-gear-fill" viewBox="0 0 16 16">'+
                        '<path d="M9.405 1.05c-.413-1.4-2.397-1.4-2.81 0l-.1.34a1.464 1.464 0 0 1-2.105.872l-.31-.17c-1.283-.698-2.686.705-1.987 1.987l.169.311c.446.82.023 1.841-.872 2.105l-.34.1c-1.4.413-1.4 2.397 0 2.81l.34.1a1.464 1.464 0 0 1 .872 2.105l-.17.31c-.698 1.283.705 2.686 1.987 1.987l.311-.169a1.464 1.464 0 0 1 2.105.872l.1.34c.413 1.4 2.397 1.4 2.81 0l.1-.34a1.464 1.464 0 0 1 2.105-.872l.31.17c1.283.698 2.686-.705 1.987-1.987l-.169-.311a1.464 1.464 0 0 1 .872-2.105l.34-.1c1.4-.413 1.4-2.397 0-2.81l-.34-.1a1.464 1.464 0 0 1-.872-2.105l.17-.31c.698-1.283-.705-2.686-1.987-1.987l-.311.169a1.464 1.464 0 0 1-2.105-.872l-.1-.34zM8 10.93a2.929 2.929 0 1 1 0-5.86 2.929 2.929 0 0 1 0 5.858z"/>'+
                    '</svg>'

webui.settingsURL = "";
$.get("api/settings", function(settingsURL){
    var url = JSON.parse(settingsURL);
    webui.settingsURL = url.url;
});

webui.showSuccess = function(message) {
    var messageBox = $("#message-box");
    messageBox.empty();
    
    $(  '<div class="alert alert-success alert-dismissible" role="alert">' +
            '<button type="button" class="btn btn-default close" data-dismiss="alert">' +
            webui.largeXIcon+
            '</button>' +
            message +
        '</div>').appendTo(messageBox);
}

webui.showError = function(message) {
    $("#error-modal .alert").text(message);
    $("#error-modal").modal('show');
}

webui.showWarning = function(message) {
    var messageBox = $("#message-box");
    messageBox.empty();

    // convert links in message into actual html links
    var messageAsArr = message.split(" ");
    messageAsArr = messageAsArr.map(function(messagePart){
        if (messagePart.substring(0,8) === "https://") {
            return '<a href="' + messagePart + '" target="_blank">' + messagePart + '</a>';
        } else {
            return messagePart;
        }
    });
    message = messageAsArr.join(" ")


    $(  '<div class="alert alert-warning alert-dismissible" role="alert">' +
            '<button type="button" class="btn btn-default close" data-dismiss="alert">' +
            webui.largeXIcon+
            '</button>' +
            message +
        '</div>').appendTo(messageBox);
}

webui.git_command = function(command, callback) {
    $.ajax({
        url: "git-command",
        type: "POST",
        contentType: 'application/json',
        data: JSON.stringify({
            command: command
        }),
        success: function(data) {
             // Convention : last lines are footer meta data like headers. An empty line marks the start if the footers
            var footers = {};
            var fIndex = data.length;
            while (true) {
                var oldFIndex = fIndex;
                fIndex = data.lastIndexOf("\r\n", fIndex - 1);
                var line = data.substring(fIndex + 2, oldFIndex);
                if (line.length > 0) {
                    var footer = line.split(": ");
                    footers[footer[0]] = footer[1];
                } else {
                    break;
                }
            }
            // Trims the the data variable to remove the footers extracted in the loop.
            // Windows adds \r\n for every line break but the Git-Stderr-Length variable,
            // counts it as only one character, throwing off the message length.
            var trimmedData = data.substring(0, fIndex).replace(/(\r\n)/gm, "\n");
            var fIndex = trimmedData.length

            var messageLength = parseInt(footers["Git-Stderr-Length"]);
            var messageStartIndex = fIndex-messageLength;
            var message = trimmedData.substring(messageStartIndex, fIndex);

            var output = trimmedData.substring(0, messageStartIndex);
            var rcode = parseInt(footers["Git-Return-Code"]);

            if (rcode == 0) {
                if (callback) {
                    callback(output);
                }
                // Return code is 0 but there is stderr output: this is a warning message
                if (message.length > 0) {
                    if(warningCallback) {
                        warningCallback(message);
                    } else {
                        webui.showWarning(message);
                    }
                }
            } else {
                var displayMessage = ""
                if(output.length > 0){
                    displayMessage += (output+"\n");
                }
                if(message.length > 0){
                    displayMessage += message;
                }
                if(displayMessage.length > 0){
                    // if(errorCallback) {
                    //     errorCallback(displayMessage);
                    // } else{
                        if(displayMessage.indexOf("self.document.Login") != -1){
                            location.reload();
                            return false;
                        }
                        webui.showError(displayMessage);
                    //}
                } else {
                    webui.showError("The command <pre>"+command.join(" ")+"</pre> failed because of an unknown reason. Returned response: \n\n"+data)
                }
            }
        },
        error: function(data) {
            var trimmedData = data.substring(0, fIndex).replace(/(\r\n)/gm, "\n");
            var fIndex = trimmedData.length

            var messageLength = parseInt(footers["Git-Stderr-Length"]);
            var messageStartIndex = fIndex-messageLength;
            var message = trimmedData.substring(messageStartIndex, fIndex);
            webui.showError(message);
        },
    });
}

webui.git = function(cmd, arg1, arg2, arg3, arg4) {
    // cmd = git command line arguments
    // other arguments = optional stdin content and a callback function.
    // arg3 = optional callback for error handling
    // arg4 = optional callback for warning handling
    // ex:
    // git("log", mycallback)
    // git("commit -F -", "my commit message", mycallback)
    if (typeof(arg1) == "function") {
        var callback = arg1;
    } else {
        // Convention : first line = git arguments, rest = process stdin
        cmd += "\n" + arg1;
        var callback = arg2;
    }

    if (typeof(arg3) == "function") {
        var errorCallback = arg3;
    } 
    if (typeof(arg4) == "function") {
        var warningCallback = arg4;
    } 

    $.post("git", {command: cmd}, function(data, status, xhr) {
        if (xhr.status == 200) {
            // Convention : last lines are footer meta data like headers. An empty line marks the start if the footers
            var footers = {};
            var fIndex = data.length;
            while (true) {
                var oldFIndex = fIndex;
                fIndex = data.lastIndexOf("\r\n", fIndex - 1);
                var line = data.substring(fIndex + 2, oldFIndex);
                if (line.length > 0) {
                    var footer = line.split(": ");
                    footers[footer[0]] = footer[1];
                } else {
                    break;
                }
            }
            // Trims the the data variable to remove the footers extracted in the loop.
            // Windows adds \r\n for every line break but the Git-Stderr-Length variable,
            // counts it as only one character, throwing off the message length.
            var trimmedData = data.substring(0, fIndex).replace(/(\r\n)/gm, "\n");
            var fIndex = trimmedData.length

            var messageLength = parseInt(footers["Git-Stderr-Length"]);
            var messageStartIndex = fIndex-messageLength;
            var message = trimmedData.substring(messageStartIndex, fIndex);

            var output = trimmedData.substring(0, messageStartIndex);
            var rcode = parseInt(footers["Git-Return-Code"]);

            if (rcode == 0) {
                if (callback) {
                    callback(output);
                }
                // Return code is 0 but there is stderr output: this is a warning message
                if (message.length > 0) {
                    if(warningCallback) {
                        warningCallback(message);
                    } else {
                        webui.showWarning(message);
                    }
                }
            } else {
                var displayMessage = ""
                if(output.length > 0){
                    displayMessage += (output+"\n");
                }
                if(message.length > 0){
                    displayMessage += message;
                }
                if(displayMessage.length > 0){
                    if(errorCallback) {
                        errorCallback(displayMessage);
                    } else{
                        if(displayMessage.indexOf("self.document.Login") != -1){
                            location.reload();
                            return false;
                        }
                        webui.showError(displayMessage);
                    }
                } else {
                    webui.showError("The command <pre>"+cmd+"</pre> failed because of an unknown reason. Returned response: \n\n"+data)
                }
            }
        } else {
            if(errorCallback) {
                errorCallback(message);
            } else{
                webui.showError(message);
            }
        }
    }, "text")
    .fail(function(xhr, status, error) {
        webui.showError("Git webui server not running");
    });
};

webui.detachChildren = function(element) {
    while (element.firstChild) {
        element.removeChild(element.firstChild);
    }
}

webui.splitLines = function(data) {
    return data.split("\n").filter(function(s) { return s.length > 0; });
};

webui.getNodeIndex = function(element) {
    var index = 0;
    while (element.previousElementSibling) {
        element = element.previousElementSibling;
        ++index;
    }
    return index;
}

webui.TabBox = function(buttons) {

    var self = this;

    self.itemClicked = function(event) {
        self.updateSelection(event.target.parentElement);
    }

    self.select = function(index) {
        self.updateSelection(self.element.children[index]);
    }

    self.updateSelection = function(elt) {
        $(".active", self.element).removeClass("active");
        $(elt).addClass("active");
        elt.callback();
    }

    self.element = $('<ul class="nav nav-pills">')[0];

    for (var i = 0; i < buttons.length; ++i) {
        var item = buttons[i];
        var li = $('<li class="nav-item"><a class="nav-link" href="#" onclick="return false;">' + item[0] + '</a></li>');
        li.appendTo(self.element);
        li.click(self.itemClicked);
        li[0].callback = item[1];
    }
};

/*
 * == SideBarView =============================================================
 */
webui.SideBarView = function(mainView, noEventHandlers) {

    var self = this;

    self.selectRef = function(refName) {
        var selected = $(".active", self.element);
        if (selected.length > 0) {
            if (selected[0].refName != refName) {
                selected.toggleClass("active");
            }
        }
        var refElements = $(".sidebar-ref", self.element);
        var moreTag = undefined;
        for (var i = 0; i < refElements.length; ++i) {
            var refElement = refElements[i];
            if (refElement.refName == refName) {
                $(refElement).toggleClass("active");
                if (refElement.tagName == "LI") {
                    moreTag = null;
                } else if (moreTag !== null) {
                    moreTag = $(".sidebar-more", refElement.section);
                }
            }
        }
        if (moreTag && moreTag.length) {
            moreTag.toggleClass("active");
        }
        self.mainView.historyView.update(refName);
    };

    self.addPopup = function(title, id, modalSize) {
        var popup = $(  '<div class="modal fade" id="' + id + '" role="dialog">' +
                            '<div class="modal-dialog '+modalSize+'">' +
                                '<div class="modal-content">' +
                                    '<div class="modal-header">' +
                                        '<h4 class="modal-title">' + title + '</h4>' +
                                        '<button type="button" class="btn btn-default close" data-dismiss="modal">'+
                                        webui.largeXIcon+
                                        '</button>' +
                                    '</div>' +
                                    '<div class="modal-body"></div>' +
                                '</div>' +
                            '</div>' +
                        '</div>')[0];
        return popup;
    };

    self.buildAccordion = function(section, refs, id, maxRefsCount, idPostfix) {
        maxRefsCount = maxRefsCount || refs.length;
        idPostfix = idPostfix || "";
        var accordionDiv = $('<div class="accordion" id="accordion-'+id+'-'+idPostfix+'">').appendTo(section)[0];
        refs = refs.sort(function(a, b) {
            if (id != "local-branches") {
                return -a.localeCompare(b);
            } else if (a[0] == "*") {
                return -1;
            } else if (b[0] == "*") {
                return 1;
            } else {
                return a.localeCompare(b);
            }
        });

        for (var i = 0; i < refs.length && i < maxRefsCount; ++i) {
            var ref = refs[i] + ""; // Get a copy of it
            if (ref[2] == '(' && ref[ref.length - 1] == ')') {
                // This is a '(detached from XXXXXX)'
                var newref = ref.substring(ref.lastIndexOf(' ') + 1, ref.length - 1)
                if (ref[0] == '*') {
                    ref = '* ' + newref;
                } else {
                    ref = '  ' + newref;
                }
            }
            var cardDiv = $('<div class="card custom-card">').appendTo(accordionDiv)[0];
            if (id.indexOf("local-branches") > -1) {
                // parses the output of git branch --verbose --verbose
                var matches = /^\*?\s*([\w-\/]+)\s+([^\s]+)\s+(\[.*\])?.*/.exec(ref);
                var branchInfo = {
                    "branch_name": matches[1],
                    "hash": matches[2],
                    "remote": matches[3]
                }
                var refname = branchInfo.branch_name;
                var canPush = (branchInfo.remote === undefined) || (branchInfo.remote.indexOf("ahead") > -1) // either no upstream or ahead of upstream
                var itemId = refname.replaceAll('/', '-') + idPostfix;
                var cardHeader = $('<div class="card-header" id="heading-' + itemId + '">').appendTo(cardDiv);
                var button = $('<button class="btn btn-sm btn-default btn-branch text-left" type="button" data-toggle="collapse" data-target="#collapse-' + itemId + '" aria-expanded="true" aria-controls="collapse-' + itemId + '">'
                                + refname
                            + '</button>').appendTo(cardHeader);
                
                var collapseDiv = $('<div id="collapse-'+ itemId +'" class="accordion-collapse collapse" aria-labelledby="heading-' + itemId +'" data-parent="#accordion-'+id+'-'+idPostfix+'">').appendTo(cardDiv);
                if(ref[0] != "*") {
                    var cardBody = $('<div class="card-body">' +
                                    '<div class="d-grid gap-2 col-12 mx-auto">'+
                                        '<button class="btn btn-xs btn-primary btn-block btn-checkout-local-branch mt-1">Checkout Branch</button>'+
                                        '<button class="btn btn-xs btn-warning btn-block btn-merge-branch">Merge Branch</button>'+
                                        (canPush ? '<button class="btn btn-xs btn-warning btn-block btn-push-branch">Push Branch</button>' : '')+
                                        '<button class="btn btn-xs btn-danger btn-block btn-delete-branch">Delete Branch</button>'+
                                    '</div>'+
                                '</div>').appendTo(collapseDiv);
                } else {
                    $(button).addClass("branch-current");
                    if (canPush) {
                        var cardBody = $('<div class="card-body">' +
                                        '<div class="d-grid gap-2 col-12 mx-auto">'+
                                            '<button class="btn btn-xs btn-warning btn-block btn-push-branch">Push Branch</button>'+
                                        '</div>'+
                                    '</div>').appendTo(collapseDiv);
                    }
                }
            } else {
                var refname = ref.replaceAll('/', '-');
                var itemId = refname + idPostfix;
                var cardHeader = $('<div class="card-header" id="heading-' + itemId +'">').appendTo(cardDiv);
                var button = $('<button class="btn btn-sm btn-default btn-branch text-left" type="button" data-toggle="collapse" data-target="#collapse-' + itemId + '" aria-expanded="true" aria-controls="collapse-' + itemId + '">'
                            + ref //IMPORTANT: This has to be the original ref for selectRef to work 
                            + '</button>').appendTo(cardHeader)

                var collapseDiv = $('<div id="collapse-' + itemId + '" class="collapse" aria-labelledby="heading-' + itemId + '" data-parent="#accordion-'+id+'-'+idPostfix+'">').appendTo(cardDiv);
                var cardBody = $('<div class="card-body">' +
                                '<div class="d-grid gap-2 col-12 mx-auto">'+
                                    '<button class="btn btn-xs btn-primary btn-block btn-checkout-remote-branch">Checkout Branch</button>'+
                                    '<button class="btn btn-xs btn-warning btn-block btn-merge-remote-branch">Merge Branch</button>'+
                                '</div>'+
                                '</div>').appendTo(collapseDiv);
            }
            $(button).click(function (event) {
                self.selectRef(event.target.innerHTML);
            });
        }

        if (id === "remote-branches" && idPostfix === "popup") {
            var remoteBranchBtns = $("#accordion-remote-branches-popup button").filter(function (i, span) {
                return jQuery.inArray($(span).text(), refs) != -1;
            });
            var widest = Math.max.apply(Math, remoteBranchBtns.map(function (i, span) {
                return $(span).width();
            }));
            if (remoteBranchBtns.length > 0) {
                remoteBranchBtns.css("padding", ".25rem .5rem");
                remoteBranchBtns.css("border", 0);
                remoteBranchBtns.width(widest);
            }
        } 
        return accordionDiv;
    }

    self.createNewLocalBranch = function(e){
        e.preventDefault();
        if($("#btn_createList").length == 0){
            var newBranchForm = $('#sidebar-local-branches');
    
            var inputForm = '<button type="submit" class="btn btn-md btn-default btn-ok" id="btn_createList">' +
                                webui.checkIcon+
                            '</button>' +
                            '<input type="text" class="form-control form-control-xs" id="newBranchName"/>'
            newBranchForm.append(inputForm);
            $("#sidebar-local-branches input").focus();
        }
        else {
            $("#sidebar-local-branches input").focus(); 
            $("#sidebar-local-branches input").select(); 
        }
    
        $("#btn_createList").click(function(e)
        {   
            var refName = $('#newBranchName').val()
    
            var flag = 0;
            webui.git("status -u --porcelain", function(data) {
                $.get("api/uncommitted", function (uncommitted) {
                    var uncommittedItems = JSON.parse(uncommitted)["current user's changes"];
                    var col = 1
                    webui.splitLines(data).forEach(function(line) {
                        var status = line.trim()[col];
                        if (col == 0 && status != " " && status != "?" || col == 1 && status != " ") {
                            line = line.substring(3);
                            var splitted = line.split(" -> ");
                            var model;
                            if (splitted.length > 1) {
                                model = splitted[1];
                            } else {
                                model = line;
                            }
                            var isForCurrentUser;
                            if(model.indexOf(" ") > -1){
                                isForCurrentUser = (uncommittedItems.indexOf(model.substring(1, model.length-1)) > -1);
                            } else {
                                isForCurrentUser = (uncommittedItems.indexOf(model) > -1);
                            }
                            if(!isForCurrentUser) {
                                flag = 1;
                            }
                        }
                    });
    
                    if(flag){
                        var popup = self.addPopup('Create Branch <pre>'+refName+'</pre>', "confirm-branch-checkout", "modal-md")
                    
                        $("body").append(popup); 
                        var popupContent = $(".modal-body", popup)[0];
                        
                        $('<div class="row"><div class="col-sm-1">'+
                        webui.warningIcon+
                        '</div>'+
                        '<div class="col-sm-11">Another user has uncommitted work on this branch. By proceeding with the checkout, you will be carrying over their changes. <br/> Do you want to proceed?</div></div>'+
                        '<button class="btn btn-sm btn-danger float-right" id="confirm-checkout">Continue</button>'+
                        '<button class="btn btn-sm btn-secondary float-right" id="cancel-checkout">Cancel</button>').appendTo(popupContent);
                        $(popup).modal('show');
    
                        $("#confirm-branch-checkout").on('click', '#confirm-checkout', function(e){
                            e.preventDefault();
                            var refName = $("#confirm-branch-checkout pre")[0].innerHTML;
    
                            webui.git("checkout -b " + refName, updateSideBar);
                            removeModal("#confirm-branch-checkout");
                        });
                    
                        $("#confirm-branch-checkout").find("#cancel-checkout, .close").click(function() {
                            removeModal("#confirm-branch-checkout");
                        });
                    }
                    else{       
                        webui.git("checkout -b " + refName, updateSideBar);
                    }
                });
            });
        });
    }

    self.pruneRemoteBranches = function(e){
        e.preventDefault();
        $(".btn-prune-remote-branches").addClass("refresh-start");
        webui.git("fetch --prune",updateSideBar);
    }

    self.getPackageVersion = function() {
        $.get("api/get-package-version", function(version) {
            var ver = JSON.parse(version)["version"];
            $("#packageVersion").text("package version " + ver)
        })
    }

    
    self.checkoutBranch = function(branchType, refName) {
        $("#confirm-branch-checkout").remove();

        var remoteName = refName.split("/")[0];
        var branchName = refName.split("/").slice(1).join("/");
        var flag = 0;
        webui.git("status -u --porcelain", function(data) {
            $.get("api/uncommitted", function (uncommitted) {
                var uncommittedItems = JSON.parse(uncommitted)["current user's changes"];
                var col = 1
                webui.splitLines(data).forEach(function(line) {
                    var status = line.trim()[col];
                    if (col == 0 && status != " " && status != "?" || col == 1 && status != " ") {
                        line = line.substring(3);
                        var splitted = line.split(" -> ");
                        var model;
                        if (splitted.length > 1) {
                            model = splitted[1];
                        } else {
                            model = line;
                        }
                        var isForCurrentUser;
                        if(model.indexOf(" ") > -1){
                            isForCurrentUser = (uncommittedItems.indexOf(model.substring(1, model.length-1)) > -1);
                        } else {
                            isForCurrentUser = (uncommittedItems.indexOf(model) > -1);
                        }
                        if(!isForCurrentUser) {
                            flag = 1;
                        }
                    }
                });
    
                if(flag){
                    var popup = self.addPopup('Confirm <pre>' + refName + '</pre>', "confirm-branch-checkout", "modal-md");
                
                    $("body").append(popup); 
                    var popupContent = $(".modal-body", popup)[0];
                    
                    $('<div class="row"><div class="col-sm-1">'+
                    webui.warningIcon+
                    '</div>'+
                    '<div class="col-sm-11">Another user has uncommitted work on this branch. By proceeding with the checkout, you will be carrying over their changes. <br/> Do you want to proceed?</div></div>'+
                    '<button class="btn btn-sm btn-danger float-right" id="confirm-checkout">Continue</button>'+
                    '<button class="btn btn-sm btn-secondary float-right" id="cancel-checkout">Cancel</button>').appendTo(popupContent);
                    $(popup).modal('show');
    
                    $("#confirm-branch-checkout").on('click', '#confirm-checkout', function(e){
                        e.preventDefault();
                        var refName = $("#confirm-branch-checkout pre")[0].innerHTML;

                        if(branchType === "remote"){
                            var remoteName = refName.split("/")[0];
                            var branchName = refName.split("/")[1];
                            webui.git("fetch "+remoteName+" "+branchName);
                            webui.git("branch -l "+branchName, function(existingBranch) {
                                if (existingBranch.length > 0) {
                                    webui.git("checkout " +branchName, updateSideBar);
                                } else {
                                    webui.git("checkout -b " +branchName + " " + refName, updateSideBar);
                                }
                            });
                        }
                        else{
                            webui.git("checkout " + refName, updateSideBar, "", "", webui.showSuccess);
                        }
                        removeModal("#confirm-branch-checkout");
                    });
                
                    $("#confirm-branch-checkout").find("#cancel-checkout, .close").click(function() {
                        removeModal("#confirm-branch-checkout");
                    });
                }
                else{
                    if(branchType === "remote"){
                        webui.git("fetch "+remoteName+" "+branchName);
                        webui.git("branch -l "+branchName, function(existingBranch) {
                            if (existingBranch.length > 0) {
                                webui.git("checkout " +branchName, updateSideBar);
                            } else {
                                webui.git("checkout -b " +branchName + " " + refName, updateSideBar);
                            }
                        });
                    }
                    else{
                        webui.git("checkout " + refName, updateSideBar, "", "", webui.showSuccess);
                    }
                }
            });
        });
    }

    self.checkoutLocalBranch = function(e) {
        e.preventDefault();

        var refName = $(this).parent().parent().parent().siblings(
            ".card-header").children("button").html();

        self.checkoutBranch("local", refName);
    }

    self.checkoutRemoteBranch = function(e) {
        e.preventDefault();
    
        var refName = $(this).parent().parent().parent().siblings(
            ".card-header").children("button").html();

        self.checkoutBranch("remote", refName);
    }

    self.deleteLocalBranch = function(e) {
        e.preventDefault();
    
        removeModal("#confirm-branch-delete"); //removes any remaining modals. If there are more than one modals, the ids are duplicated and event listeners won't work.
        var refName = $(this).parent().parent().parent().siblings(
            ".card-header").children("button").html();
    
        var popup = self.addPopup('Confirm <pre>'+refName+' </pre>Deletion', "confirm-branch-delete", "modal-md");
        $("body").append(popup); 
        var popupContent = $(".modal-body", popup)[0];
        
        $('<div class="row"><div class="col-sm-1">'+
        webui.warningIcon+
        '</div>'+
        '<div class="col-sm-11">By deleting this branch, you might lose uncommitted work. <br/> Do you want to proceed?</div></div>'+
        '<button class="btn btn-sm btn-danger float-right" id="confirm-delete">Delete Branch</button>'+
        '<button class="btn btn-sm btn-secondary float-right" id="cancel-delete">Cancel</button>').appendTo(popupContent);
        $(popup).modal('show');
    
        $("#confirm-branch-delete").on('click', '#confirm-delete', function(e){
    
            removeModal("#confirm-branch-delete");
    
            function deleteSuccessDisplay(output) {
                webui.showSuccess(output);
                updateSideBar();
            }
    
            function forceDelete(message) {
                if(message.indexOf("git branch -D")>-1){
                    $("body").append(popup); 
                    var popupContent = $(".modal-body", popup)[0];
                    webui.detachChildren(popupContent);
                    $('<div class="row"><div class="col-sm-1">'+
                    webui.warningIcon+
                    '</div>'+
                    '<div class="col-sm-11">This branch is not fully merged. Do you want to force delete it?</div></div>'+
                    '<button class="btn btn-sm btn-danger float-right" id="confirm-force-delete">Force Delete</button>'+
                    '<button class="btn btn-sm btn-secondary float-right" id="cancel-delete">Cancel</button>').appendTo(popupContent);
                    $(popup).modal('show');
    
                    $("#confirm-branch-delete").on('click', '#confirm-force-delete', function(e){
                        removeModal("#confirm-branch-delete");
                        webui.git("branch -D " + refName, deleteSuccessDisplay);
                    });
    
                    $("#confirm-branch-delete").find("#cancel-delete, .close").click(function() {
                        removeModal("#confirm-branch-delete");
                    });
                }
                else {
                    webui.showError(message);
                }
            }
            webui.git("branch -d " + refName, deleteSuccessDisplay, "", forceDelete);  
        });
    
        $("#confirm-branch-delete").find("#cancel-delete, .close").click(function() {
            removeModal("#confirm-branch-delete");
        });
    }

    self.upToDateHandler = function (message){
        if(message.indexOf("Already up to date.")>-1) {
            webui.showSuccess(message);
        }
    }

    self.testMergeHandler = function (message, refName) {
        function suppressErrorMessage(error) {
        }

        webui.git("merge --abort", "", "", suppressErrorMessage);

        if(message.indexOf("Automatic merge went well")>-1 || message.indexOf("Auto-merging ")>-1){
            webui.git("merge "+refName, webui.showSuccess);
        }
        else {
            webui.showError(message);
        }
    }
    
    self.mergeBranch = function(e){
        e.preventDefault();
        var refName = $(this).parent().parent().parent().siblings(
            ".card-header").children("button").html();
    
        var remoteName = refName.split('/')[0];
        var branchName = refName.split('/')[1];

        if(branchName){
            webui.git("fetch "+remoteName+" "+branchName);
        }

        function callTestMergeHandler(message){
            self.testMergeHandler(message, refName);
        }

        webui.git("merge --no-commit --no-ff "+refName, "", self.upToDateHandler, callTestMergeHandler, callTestMergeHandler);
    }

    /// pushes the selected local branch to "origin"
    self.pushBranch = function(e){
        e.preventDefault();
        var refName = $(this).parent().parent().parent().siblings(
            ".card-header").children("button").html();
        webui.git('push -u origin '+refName, "", self.upToDateHandler)
    }

    self.goToSettingsPage = function() {
        window.location.replace(webui.settingsURL);
    }

    self.fetchSection = function(section, title, id, gitCommand) {
        webui.git(gitCommand, function(data) {
            var refs = webui.splitLines(data);
            if (id == "remote-branches") {
                refs = refs.map(function(ref) {
                    var end = ref.lastIndexOf(" -> ");
                    if (end == -1) {
                        return ref.substring(2);
                    } else {
                        return ref.substring(2, end);
                    }
                });
            }
            if (refs.length > 0) {
                var maxRefsCount = 5;
                if (refs.length > maxRefsCount) {
                    var popup = self.addPopup(title, id + "-popup", "modal-sm");
                    var popupContent = $(".modal-body", popup)[0];
                    $(self.buildAccordion(section, refs, id, undefined, "popup")).appendTo(popupContent);
                    // Hide popup when the user selects a branch operation 
                    // Then execute the required operation with other even listeners
                    $(popupContent).find(".btn-delete-branch, .btn-checkout-local-branch, .btn-checkout-remote-branch, .btn-merge-remote-branch, .btn-merge-branch, .btn-push-branch").click(function() {
                        $(popup).modal('hide');
                    });
                }
                var accordionDiv = self.buildAccordion(section, refs, id, maxRefsCount);
                if (refs.length > maxRefsCount) {
                    var more = $('<div class="card custom-card">'+
                                '<div class="card-header">'+
                                '<button class="btn btn-sm btn-default btn-branch text-left" type="button">'+
                                'More ...'+
                                '</button>'+
                                '</div></div>').appendTo(accordionDiv);
                    more.click(function() {
                        $(popup).modal('show');
                    });
                }
            } else {
                $(section).remove();
            }
        });
    };

    self.mainView = mainView;
    
    self.element = $(   '<div id="sidebar">' +
                            '<a href="#" data-toggle="modal" data-target="#help-modal"><img id="sidebar-logo" src="img/git-logo.png"></a>' +
                            '<h5 id="packageVersion"></h5>' +
                            '<div id="sidebar-content">' +
                                '<section id="sidebar-workspace">' +
                                    '<h4>Workspace</h4>' +
                                '</section>' +
                                '<section id="sidebar-stash">' +
                                    '<h4>Stash</h4>' +
                                '</section>' +
                                '<section id="sidebar-local-branches">' +
                                    '<h4 class="mt-3">Local Branches' +
                                    '<button type="button" class="btn btn-default btn-sidebar-icon btn-add shadow-none" >' +
                                        webui.circlePlusIcon+
                                    '</button>' + '</h4>' +
                                '</section>' +
                                '<section id="sidebar-remote-branches">' +
                                    '<h4 class="mt-3">Remote Branches' +
                                    '<button type="button" class="btn btn-default btn-sidebar-icon btn-prune-remote-branches shadow-none" >'+
                                        webui.refreshIcon+
                                      '</button>' +'</h4>' +
                                '</section>' +
                                '<section id="sidebar-tags">' +
                                    '<h4>Tags</h4>' +
                                '</section>' +
                                '<section id="sidebar-settings">' +
                                    '<h4>Settings</h4>' +
                                '</section>' +
                            '</div>' +
                        '</div>')[0];

    if (webui.viewonly) {
        $("#sidebar-workspace", self.element).remove();
    } else {
        var workspaceElement = $("#sidebar-workspace h4", self.element);
        workspaceElement.click(function (event) {
            $("*", self.element).removeClass("active");
            workspaceElement.addClass("active");
            self.mainView.workspaceView.show();
        });

        var stashElement = $("#sidebar-stash h4", self.element);
        stashElement.click(function (event) {
            $("*", self.element).removeClass("active");
            stashElement.addClass("active");
            self.mainView.stashView.update(0);
        });

        $(".btn-add", self.element).click(self.createNewLocalBranch);
        $('.btn-prune-remote-branches', self.element).click(self.pruneRemoteBranches);
        $("#sidebar-settings", self.element).click(self.goToSettingsPage);
    }
    self.getPackageVersion();
    self.fetchSection($("#sidebar-local-branches", self.element)[0], "Local Branches", "local-branches", "branch --verbose --verbose");
    self.fetchSection($("#sidebar-remote-branches", self.element)[0], "Remote Branches", "remote-branches", "branch --remotes");
    self.fetchSection($("#sidebar-tags", self.element)[0], "Tags", "tags", "tag");

    if(!noEventHandlers){
        $(document).on('click', '.btn-checkout-local-branch', self.checkoutLocalBranch);
        $(document).on('click', '.btn-push-branch', self.pushBranch);
        $(document).on('click', '.btn-checkout-remote-branch', self.checkoutRemoteBranch);

        $(document).on('click', '.btn-delete-branch', self.deleteLocalBranch);

        $(document).on('click', '.btn-merge-branch', self.mergeBranch);
        $(document).on('click', '.btn-merge-remote-branch', self.mergeBranch);
    }
};

/*
 * == LogView =================================================================
 */
webui.LogView = function(historyView) {

    var self = this;

    self.update = function(ref) {
        $(svg).empty();
        streams = []
        $(content).empty();
        self.nextRef = ref;
        self.populate();
    };

    self.populate = function() {
        var maxCount = 1000;
        if (content.childElementCount > 0) {
            // The last node is the 'Show more commits placeholder'. Remove it.
            content.removeChild(content.lastElementChild);
        }
        var startAt = content.childElementCount;
        webui.git("log --date-order --pretty=raw --decorate=full --max-count=" + (maxCount + 1) + " " + self.nextRef + " --", function(data) {
            var start = 0;
            var count = 0;
            self.nextRef = undefined;
            while (true) {
                var end = data.indexOf("\ncommit ", start);
                if(end == -1){
                    if(start>=data.length) {
                        break
                    }
                    var end = data.length;
                }
                
                var entry = new Entry(self, data.substring(start, end));
                content.appendChild(entry.element);
                if (!self.lineHeight) {
                    self.lineHeight = Math.ceil($(entry.element).outerHeight() / 2) * 2;
                }
                entry.element.setAttribute("style", "height:" + self.lineHeight + "px");
                if (!currentSelection) {
                    entry.select();
                }
                if (count >= maxCount) {
                    self.nextRef = entry.commit;
                    break;
                }
                start = end + 1;
                ++count;
            }
            svg.setAttribute("height", $(content).outerHeight());
            svg.setAttribute("width", $(content).outerWidth());
            if (self.nextRef != undefined) {
                var moreTag = $('<a class="log-entry log-entry-more list-group-item">');
                $('<a class="list-group-item-text">Show previous commits</a>').appendTo(moreTag[0]);
                moreTag.click(self.populate);
                moreTag.appendTo(content);
            }

            self.updateGraph(startAt);
        });
    };

    self.updateGraph = function(startAt) {
        // Draw the graph
        var currentY = (startAt + 0.5) * self.lineHeight;
        var maxLeft = 0;
        if (startAt == 0) {
            streamColor = 0;
        }
        for (var i = startAt; i < content.children.length; ++i) {
            var entry = content.children[i].model;
            if (!entry) {
                break;
            }
            var index = 0;
            entry.element.webuiLeft = streams.length;

            // Find streams to join
            var childCount = 0;
            var xOffset = 12;
            var removedStreams = 0;
            for (var j = 0; j < streams.length;) {
                var stream = streams[j];
                if (stream.sha1 == entry.commit) {
                    if (childCount == 0) {
                        // Replace the stream
                        stream.path.setAttribute("d", stream.path.cmds + currentY);
                        if (entry.parents.length == 0) {
                            streams.splice(j, 1);
                        } else {
                            stream.sha1 = entry.parents[0];
                        }
                        index = j;
                        ++j;
                    } else {
                        // Join the stream
                        var x = (index + 1) * xOffset;
                        stream.path.setAttribute("d", stream.path.cmds + (currentY - self.lineHeight / 2) + " L " + x + " " + currentY);
                        streams.splice(j, 1);
                        ++removedStreams;
                    }
                    ++childCount;
                } else {
                    if (removedStreams != 0) {
                        var x = (j + 1) * xOffset;
                        stream.path.setAttribute("d", stream.path.cmds + (currentY - self.lineHeight / 2) + " L " + x + " " + currentY);
                    }
                    ++j;
                }
            }

            // Add new streams
            for (var j = 0; j < entry.parents.length; ++j) {
                var parent = entry.parents[j];
                var x = (index + j + 1) * xOffset;
                if (j != 0 || streams.length == 0) {
                    var svgPath = document.createElementNS("http://www.w3.org/2000/svg", "path");
                    ++streamColor
                    if (streamColor == webui.COLORS.length) {
                        streamColor = 0;
                    }
                    svgPath.setAttribute("style", "stroke:" + webui.COLORS[streamColor]);
                    var origX = (index + 1) * xOffset;
                    svgPath.cmds = "M " + origX + " " + currentY + " L " + x + " " + (currentY + self.lineHeight / 2) + " L " + x + " ";
                    svg.appendChild(svgPath);
                    var obj = {
                        sha1: parent,
                        path: svgPath,
                    };
                    streams.splice(index + j, 0, obj);
                }
            }
            for (var j = index + j; j < streams.length; ++j) {
                var stream = streams[j];
                var x = (j + 1) * xOffset;
                stream.path.cmds += (currentY - self.lineHeight / 2) + " L " + x + " " + currentY + " L " + x + " ";
            }

            var svgCircle = document.createElementNS("http://www.w3.org/2000/svg", "circle");
            svgCircle.setAttribute("cx", (index + 1) * xOffset);
            svgCircle.setAttribute("cy", currentY);
            svgCircle.setAttribute("r", 4);
            svg.appendChild(svgCircle);

            entry.element.webuiLeft = Math.max(entry.element.webuiLeft, streams.length);
            maxLeft = Math.max(maxLeft, entry.element.webuiLeft);

            currentY += self.lineHeight;
        }
        for (var i = startAt; i < content.children.length; ++i) {
            var element = content.children[i];
            if (element.model) {
                var minLeft = Math.min(maxLeft, 3);
                var left = element ? Math.max(minLeft, element.webuiLeft) : minLeft;
                element.setAttribute("style", element.getAttribute("style") + ";padding-left:" + (left + 1) * xOffset + "px");
            }
        }
        for (var i = 0; i < streams.length; ++i) {
            var stream = streams[i];
            stream.path.setAttribute("d", stream.path.cmds + currentY);
        }
    }

    function Person(data) {
        var nameEnd = data.indexOf("<");
        this.name = data.substring(0, nameEnd - 1);
        var emailEnd = data.indexOf(">", nameEnd);
        this.email = data.substring(nameEnd + 1, emailEnd);
        var dateEnd = data.indexOf(" ", emailEnd + 2);
        var secs = data.substring(emailEnd + 2, dateEnd);
        this.date = new Date(0);
        this.date.setUTCSeconds(parseInt(secs));
    };

    function Entry(logView, data) {
        var self = this;

        self.abbrevCommitHash = function() {
            return self.commit.substring(0, 7);
        };

        self.abbrevMessage = function() {
            var end = self.message.indexOf("\n");
            if (end == -1) {
                return self.message
            } else {
                return self.message.substring(0, end);
            }
        };

        self.createElement = function() {
            self.element = $('<a class="log-entry list-group-item">' +
                                '<header>' +
                                    '<h6></h6>' +
                                    '<span class="log-entry-date">' + self.author.date.toLocaleString() + '&nbsp;</span> ' +
                                    '<span class="badge">' + self.abbrevCommitHash() + '</span>' +
                                '</header>' +
                                '<p class="list-group-item-text"></p>' +
                             '</a>')[0];
            $('<a target="_blank" href="mailto:' + self.author.email + '">' + self.author.name + '</a>').appendTo($("h6", self.element));
            $(".list-group-item-text", self.element)[0].appendChild(document.createTextNode(self.abbrevMessage()));
            if (self.refs) {
                var entryName = $("h6", self.element);
                self.refs.forEach(function (ref) {
                    if (ref.indexOf("refs/remotes") == 0) {
                        ref = ref.substring(13);
                        var reftype = "danger";
                    } else if (ref.indexOf("refs/heads") == 0) {
                        ref = ref.substring(11);
                        var reftype = "success";
                    } else if (ref.indexOf("tag: refs/tags") == 0) {
                        ref = ref.substring(15);
                        var reftype = "info";
                    } else {
                        var reftype = "warning";
                    }
                    $('<span>&nbsp;</span><span class="label label-' + reftype + '">' + ref + '</span>').insertAfter(entryName);
                });
            }
            self.element.model = self;
            var model = self;
            $(self.element).click(function (event) {
                model.select();
            });
            return self.element;
        };

        self.select = function() {
            if (currentSelection != self) {
                if (currentSelection) {
                    $(currentSelection.element).removeClass("active");
                }
                $(self.element).addClass("active");
                currentSelection = self;
                logView.historyView.commitView.update(self);
            }
        };

        self.parents = [];
        self.message = ""

        data.split("\n").forEach(function(line) {
            if (line.indexOf("commit ") == 0) {
                self.commit = line.substring(7, 47);
                if (line.length > 47) {
                    self.refs = []
                    var s = line.lastIndexOf("(") + 1;
                    var e = line.lastIndexOf(")");
                    line.substring(s, e).split(", ").forEach(function(ref) {
                        self.refs.push(ref);
                    });
                }
            } else if (line.indexOf("parent ") == 0) {
                self.parents.push(line.substring(7));
            } else if (line.indexOf("tree ") == 0) {
                self.tree = line.substring(5);
            } else if (line.indexOf("author ") == 0) {
                self.author = new Person(line.substring(7));
            } else if (line.indexOf("committer ") == 0) {
                self.committer = new Person(line.substring(10));
            } else if (line.indexOf("    ") == 0) {
                self.message += line.substring(4) + "\n";
            }
        });

        self.message = self.message.trim();

        self.createElement();
    };

    self.historyView = historyView;
    self.element = $('<div id="log-view" class="list-group"><svg xmlns="http://www.w3.org/2000/svg"></svg><div></div></div>')[0];
    var svg = self.element.children[0];
    var content = self.element.children[1];
    var currentSelection = null;
    var lineHeight = null;
    var streams = [];
    var streamColor = 0;
};

webui.StashView = function(mainView) {
    
    var self = this;

    self.show = function() {
        mainView.switchTo(self.element);
    };

    self.update = function(stashIndex) {
        self.show();
        self.stashListView.update(stashIndex);
    };

    self.element = $('<div id="stash-view">')[0];

    self.stashListView = new webui.StashListView(self);
    self.element.appendChild(self.stashListView.element);
    self.commitView = new webui.StashCommitView(self);
    self.element.appendChild(self.commitView.element);
    self.mainView = mainView;
} 

webui.StashListView = function(stashView) {
    var self = this;

    self.update = function(stashIndex){
        $(svg).empty();
        $(content).empty();
        self.populate();
    }

    self.populate = function() {
        webui.git("stash list --format='%gd::%ch::%cL::%cN::%gs'", function(data) {
            var start = 0;
            var count = 0;
            while (true) {
                var end = data.indexOf("\n", start);
                if (end != -1) {
                    var len = end - start;
                } else {
                    break;
                }
                var entry = new Entry(self, data.substring(start, start+len));
                if(start == 0){
                    entry.select();
                }
                content.appendChild(entry.element);

                start = end + 1;
                ++count;
            }
            if(count == 0){
                var emptyStash = $('<h4 class="empty-stash">You have no stashed changes.</h4>');
                var emptyDiv =  $('<h1 class="empty-stash">&nbsp<br>&nbsp</h1>');
                $("#log-view div").append(emptyDiv);
                $("#log-view div").append(emptyStash);
            }
            svg.setAttribute("height", $(content).outerHeight());
            svg.setAttribute("width", $(content).outerWidth());
        });
    }

    function Entry(stashListView, data) {
        var self = this;

        self.abbrevMessage = function() {
            var end = self.message.indexOf("\n");
            if (end == -1) {
                return self.message
            } else {
                return self.message.substring(0, end);
            }
        };

        self.createElement = function() {
            self.element = $('<a class="log-entry list-group-item">' +
                                '<header>' +
                                    '<h6></h6>' +
                                    '<p class="stash-list-index">' + self.stashIndex + '</p>' +
                                    '<span class="log-entry-date">' + self.date + '&nbsp;</span> ' +
                                    '<span class="badge">' + self.commit + '</span>' +
                                '</header>' +
                                '<p class="list-group-item-text"></p>' +
                             '</a>')[0];
            $('<a target="_blank" href="mailto:' + self.authorEmail + '">' + self.authorName + '</a>').appendTo($("h6", self.element));
            $(".list-group-item-text", self.element)[0].appendChild(document.createTextNode(self.commitMessage));

            self.element.model = self;
            var model = self;
            $(self.element).click(function (event) {
                model.select();
            });
            return self.element;
        };

        self.select = function() {
            if (currentSelection != self) {
                if (currentSelection) {
                    $(currentSelection.element).removeClass("active");
                }
                $(self.element).addClass("active");
                currentSelection = self;
                stashListView.stashView.commitView.update(self);
            }
        };

        self.parents = [];
        self.message = ""

        var pieces = data.split(/::|:\s/gm);
        self.stashIndex = pieces[0].substring(pieces[0].indexOf('{')+1, pieces[0].indexOf('}'));
        self.date = pieces[1];
        self.authorEmail = pieces[2];
        self.authorName = pieces[3];
        self.branchName = pieces[4];
        self.commit = pieces[5].substring(0, pieces[5].indexOf(" "));
        self.commitMessage = pieces[5].substring(pieces[5].indexOf(" ")).trim();

        self.createElement();
    };

    self.element = $('<div id="log-view" class="list-group"><svg xmlns="http://www.w3.org/2000/svg"></svg><div></div></div>')[0];
    var svg = self.element.children[0];
    var content = self.element.children[1];
    var currentSelection = null;
    self.stashView = stashView
}

webui.StashCommitView = function(stashView) {
    var self = this;

    self.update = function(entry) {

        currentCommit = entry.commit;
        self.showDiff();
        diffView.update("stash show -p stash@{"+entry.stashIndex+"}");
    };

    self.showDiff = function() {
        webui.detachChildren(commitViewContent);
        commitViewContent.appendChild(diffView.element);
    };

    self.stashView = stashView;
    var currentCommit = null;
    self.element = $('<div id="commit-view">')[0];
    var commitViewContent = $('<div id="commit-view-content">')[0];
    self.element.appendChild(commitViewContent);
    var diffView = new webui.DiffView(undefined, false, self, true);
};

/*
 * == DiffView ================================================================
 */
webui.DiffView = function(sideBySide, hunkSelectionAllowed, parent, stashedCommit) {

    var self = this;

    self.update = function(cmd, diffOpts, file, mode) {
        gitApplyType = mode;
        $(".diff-stage", self.element).attr("style", "display:none");
        $(".diff-cancel", self.element).attr("style", "display:none");
        $(".diff-unstage", self.element).attr("style", "display:none");
        if (cmd) {
            self.gitCmd = cmd;
            self.gitDiffOpts = diffOpts;
            if (file != self.gitFile && self.gitFile != '"undefined"') {
                left.scrollTop = 0;
                left.scrollLeft = 0;
                right.scrollTop = 0;
                right.scrollLeft = 0;
                left.webuiPrevScrollTop = 0;
                left.webuiPrevScrollLeft = 0;
                right.webuiPrevScrollTop = 0;
                right.webuiPrevScrollLeft = 0;
            }
            webui.git("ls-files \""+file+"\"", function(path){
                self.gitFile = "\"" + file + "\"";
                self.noIndex = ""
                if(path.length == 0 && file != undefined){
                    self.gitFile = " /dev/null " + file;
                    self.noIndex = " --no-index ";
                    if (self.gitDiffOpts == "--cached") {
                        self.gitDiffOpts = "";
                    } 
                }
                if (self.gitCmd) {
                    var fullCmd = self.gitCmd;
                    if (self.complete) {
                        fullCmd += " --unified=999999999";
                    } else {
                        fullCmd += " --unified=" + self.context.toString();
                    }
                    if (self.ignoreWhitespace) {
                        fullCmd += " --ignore-all-space --ignore-blank-lines";
                    }
                    if (self.gitDiffOpts) {
                        fullCmd += " " + self.gitDiffOpts.join(" ")
                    }
                    if (self.gitFile && self.gitFile != '"undefined"') {
                        fullCmd += self.noIndex + " -- " + self.gitFile;
                    }
                    webui.git(fullCmd, self.refresh, self.refresh, self.refresh);
                } else {
                    self.refresh("");
                }
            });
        }
    };

    self.refresh = function(diff) {
        self.currentDiff = diff;
        self.diffHeader = "";
        $("span", self.element).text('Context: ' + self.context);
        if (sideBySide) {
            var diffLines = diff.split("\n");
            self.updateSplitView(leftLines, diffLines, '-');
            self.updateSplitView(rightLines, diffLines, '+');
        } else {
            self.updateSimpleView(singleLines, diff);
        }
    }

    self.updateSimpleView = function(view, diff) {
        $(view).empty();

        var context = { inHeader: true };
        var diffLines = diff.split("\n");
        for (var i = 0; i < diffLines.length; ++i) {
            var line = diffLines[i];
            context = self.addDiffLine(view, line, context);
        }
    }

    self.updateSplitView = function(view, diffLines, operation) {
        $(view).empty();

        var context = { inHeader: true,
                        addedLines: [],
                        removedLines: [],
                      };
        for (var i = 0; i < diffLines.length; ++i) {
            var line = diffLines[i];
            var c = line[0];
            if (c == '+') {
                context.addedLines.push(line);
                if (context.inHeader) {
                    context.diffHeader += line + '\n';
                }
            } else if (c == '-') {
                context.removedLines.push(line);
                if (context.inHeader) {
                    context.diffHeader += line + '\n';
                }
            } else {
                context = self.flushAddedRemovedLines(view, operation, context);
                context.addedLines = [];
                context.removedLines = [];
                context = self.addDiffLine(view, line, context);
                if (c == 'd') {
                    context.diffHeader = '';
                }
            }
        }
        self.flushAddedRemovedLines(view, operation, context);
        view.parentElement.scrollTop = view.parentElement.webuiPrevScrollTop;
    }

    self.flushAddedRemovedLines = function(view, operation, context) {
        if (operation == '+') {
            var lines = context.addedLines;
            var offset = context.removedLines.length - context.addedLines.length;
        } else {
            var lines = context.removedLines;
            var offset = context.addedLines.length - context.removedLines.length;
        }
        lines.forEach(function(line) {
            context = self.addDiffLine(view, line, context);
        });
        if (offset > 0) {
            for (var i = 0; i < offset; ++i) {
                var pre = $('<pre class="diff-view-line diff-line-phantom">').appendTo(view)[0];
                pre.appendChild(document.createTextNode(" "));
            }
        }
        return context;
    }

    self.addDiffLine = function(view, line, context) {
        var c = line[0];
        var pre = $('<pre class="diff-view-line">').appendTo(view)[0];
        pre.appendChild(document.createTextNode(line));
        if (c == '+') {
            $(pre).addClass("diff-line-add");
        } else if (c == '-') {
            $(pre).addClass("diff-line-del");
        } else if (c == '@') {
            $(pre).addClass("diff-line-offset");
            pre.webuiActive = false;
            context.inHeader = false;
        } else if (c == 'd') {
            context.inHeader = true;
        }
        if (context.inHeader) {
            $(pre).addClass("diff-line-header");
            if (c == 'd') $(pre).addClass("diff-section-start");
        }
        return context;
    }

    self.createSelectionPatch = function (reverse) {
        var patch = "";
        // First create the header
        for (var l = 0; l < leftLines.childElementCount; ++l) {
            var line = leftLines.children[l].textContent;
            if (line[0] == "@") {
                break;
            } else {
                patch += line + "\n";
            }
        }
        patch += rightLines.children[l - 1].textContent + "\n";
        // Then build the patch itself
        var refLineNo = 0;
        var patchOffset = 0;
        var hunkAddedLines = [];
        var hunkRemovedLines = [];
        for (; l < leftLines.childElementCount; ++l) {
            var leftElt = leftLines.children[l];
            var leftLine = leftElt.textContent;
            var leftCmd = leftLine[0];

            if (leftCmd == "@" || (leftCmd == " " && !$(leftElt).hasClass("diff-line-phantom"))) {
                if (hunkAddedLines.length != 0 || hunkRemovedLines.length != 0) {
                    patch += self.flushSelectionPatch(hunkAddedLines, hunkRemovedLines, refLineNo, patchOffset);
                    refLineNo += hunkRemovedLines.length
                    patchOffset += hunkAddedLines.length - hunkRemovedLines.length;
                    var hunkAddedLines = [];
                    var hunkRemovedLines = [];
                }
                if (leftCmd == "@") {
                    var splittedContext = leftLine.split(" ");
                    if (!reverse) {
                        refLineNo = Math.abs(splittedContext[1].split(",")[0]);
                    } else {
                        refLineNo = Math.abs(splittedContext[2].split(",")[0]);
                    }
                } else {
                    ++refLineNo;
                }
            } else if (leftCmd == "-" || $(leftElt).hasClass("diff-line-phantom")) {
                if (leftCmd == "-") {
                    if ($(leftElt).hasClass("active")) {
                        if (!reverse) {
                            hunkRemovedLines.push(leftLine);
                        } else {
                            hunkAddedLines.push(self.reverseLine(leftLine));
                        }
                    } else if (!reverse) {
                        ++refLineNo;
                    }
                }
                var rightElt = rightLines.children[l];
                if (!$(rightElt).hasClass("diff-line-phantom")) {
                    if ($(rightElt).hasClass("active")) {
                        if (!reverse) {
                            hunkAddedLines.push(rightElt.textContent);
                        } else {
                            hunkRemovedLines.push(self.reverseLine(rightElt.textContent));
                        }
                    } else if (reverse) {
                        ++refLineNo;
                    }
                }
            }
        }
        if (hunkAddedLines.length != 0 || hunkRemovedLines.length != 0) {
            patch += self.flushSelectionPatch(hunkAddedLines, hunkRemovedLines, refLineNo, patchOffset);
        }
        return patch;
    }

    self.flushSelectionPatch = function(hunkAddedLines, hunkRemovedLines, refLineNo, patchOffset) {
        var patch = "@@ -" + refLineNo + "," + hunkRemovedLines.length +" +" + (refLineNo + patchOffset) + "," + hunkAddedLines.length + " @@\n";
        hunkRemovedLines.forEach(function (line) { patch += line + "\n" });
        hunkAddedLines.forEach(function (line) { patch += line + "\n" });
        return patch;
    }

    self.reverseLine = function(line) {
        switch (line[0]) {
            case '-':
                return '+' + line.substring(1);
            case '+':
                return '-' + line.substring(1);
                break;
            default:
                return line;
                break;
        }
    }

    self.diffViewScrolled = function(event) {
        if (event.target == left) {
            var current = left;
            var other = right;
        } else {
            var current = right;
            var other = left;
        }
        if (current.webuiPrevScrollTop != current.scrollTop) {
            // Vertical scrolling
            other.scrollTop = current.scrollTop;
            other.webuiPrevScrollTop = current.webuiPrevScrollTop = current.scrollTop;
        } else if (current.webuiPrevScrollLeft != current.scrollLeft) {
            // Horizontal scrolling
            other.scrollLeft = current.scrollLeft;
            other.webuiPrevScrollLeft = current.webuiPrevScrollLeft = current.scrollLeft;
        }
    }

    self.addContext = function() {
        self.context += 3;
        self.update();
    }

    self.removeContext = function() {
        if (self.context > 3) {
            self.context -= 3;
            self.update();
        }
    }

    self.allContext = function() {
        self.complete = !self.complete;
        self.update();
    }

    self.toggleIgnoreWhitespace = function() {
        self.ignoreWhitespace = !self.ignoreWhitespace;
        self.update();
    }

    self.handleClick = function(event) {
        var lineElt = event.target;
        while (lineElt && !$(lineElt).hasClass("diff-view-line")) {
            lineElt = lineElt.parentElement;
        }
        if (!lineElt) {
            return;
        }
        var diffLine = lineElt.textContent;
        var cmd = diffLine[0];
        if (cmd == "+" || cmd == "-") {
            $(lineElt).toggleClass("active");
        } else if (cmd == "@") {
            lineElt.webuiActive = !lineElt.webuiActive;
            for (var elt = lineElt.nextElementSibling; elt; elt = elt.nextElementSibling) {
                cmd = elt.textContent[0];
                if (cmd == "+" || cmd == "-") {
                    $(elt).toggleClass("active", lineElt.webuiActive);
                } else if (cmd == "@") {
                    break;
                }
            }
        }

        var isActive = false
        var lineContainers = [leftLines, rightLines];
        for (var i = 0; i < lineContainers.length; ++i) {
            var lineContainer = lineContainers[i];
            for (var j = 0; j < lineContainer.childElementCount; ++j) {
                var elt = lineContainer.children[j];
                if ($(elt).hasClass("active")) {
                    isActive = true;
                    break;
                }
            }
        }
        if (isActive) {
            if (gitApplyType == "stage") {
                $(".diff-stage", self.element).removeAttr("style");
                $(".diff-cancel", self.element).removeAttr("style");
                $(".diff-unstage", self.element).attr("style", "display:none");
            } else {
                $(".diff-stage", self.element).attr("style", "display:none");
                $(".diff-cancel", self.element).attr("style", "display:none");
                $(".diff-unstage", self.element).removeAttr("style");
            }
        } else {
            $(".diff-stage", self.element).attr("style", "display:none");
            $(".diff-cancel", self.element).attr("style", "display:none");
            $(".diff-unstage", self.element).attr("style", "display:none");
        }
    }

    self.applySelection = function(reverse, cached) {
        var patch = self.createSelectionPatch(reverse);
        var cmd = "apply --unidiff-zero";
        if (cached) {
            cmd += " --cached";
        }
        webui.git(cmd, patch, function (data) {
            parent.update();
        });
    }

    self.switchToExploreView = function() {
        if (! self.currentDiff) {
            return;
        }
        var mainView = parent.historyView.mainView;
        var commitExplorerView = new webui.CommitExplorerView(mainView, self.currentDiff);
        commitExplorerView.show();
    };

    self.applySelectedStash = function() {
        if(! self.currentDiff) {
            return;
        }
        var stashIndex = parseInt($(".log-entry.active .stash-list-index").text());
        webui.git("stash apply stash@{"+stashIndex+"}", function(output){
            webui.showSuccess(output);
        });
    }

    self.popSelectedStash = function() {
        if(! self.currentDiff) {
            return;
        }
        var stashIndex = parseInt($(".log-entry.active .stash-list-index").text());
        webui.git("stash pop stash@{"+stashIndex+"}", function(output){
            webui.showSuccess(output);
            parent.stashView.update(0);
        });
    }

    self.dropSelectedStash = function() {
        if(! self.currentDiff) {
            return;
        }
        var stashIndex = parseInt($(".log-entry.active .stash-list-index").text());
        webui.git("stash drop stash@{"+stashIndex+"}", function(output){
            webui.showSuccess(output.substring(output.indexOf("Dropped")));
            parent.stashView.update(0);
        });
    }

    var html = '<div class="diff-view-container panel panel-default">';
    if (! (parent instanceof webui.CommitExplorerView)) {
        html +=
            '<div class="panel-heading btn-toolbar" role="toolbar">' +
                '<button type="button" class="btn btn-sm btn-default diff-ignore-whitespace" data-toggle="button">Ignore Whitespace</button>' +
                '<button type="button" class="btn btn-sm btn-default diff-context-all" data-toggle="button">Complete file</button>' +
                '<div class="btn-group btn-group-sm">' +
                    '<span></span>&nbsp;' +
                    '<button type="button" class="btn btn-default diff-context-remove">-</button>' +
                    '<button type="button" class="btn btn-default diff-context-add">+</button>' +
                '</div>' +
                '<div class="btn-group btn-group-sm diff-selection-buttons">' +
                    '<button type="button" class="btn btn-default diff-stage" style="display:none">Stage</button>' +
                    '<button type="button" class="btn btn-default diff-cancel" style="display:none">Cancel</button>' +
                    '<button type="button" class="btn btn-default diff-unstage" style="display:none">Unstage</button>' +
                '</div>' +
                ((sideBySide || stashedCommit) ? '' : '<button type="button"  class="btn btn-sm btn-default diff-explore">Explore</button>') +
                (stashedCommit ? '<button type="button"  class="btn btn-sm btn-default apply-stash">Apply</button>':'')+
                (stashedCommit ? '<button type="button"  class="btn btn-sm btn-default pop-stash">Pop</button>':'')+
                (stashedCommit ? '<button type="button"  class="btn btn-sm btn-default drop-stash">Drop</button>':'')+
            '</div>';
    }
    html += '<div class="panel-body"></div></div>'
    self.element = $(html)[0];
    var panelBody = $(".panel-body", self.element)[0];
    if (sideBySide) {
        var left = $('<div class="diff-view"><div class="diff-view-lines"></div></div>')[0];
        panelBody.appendChild(left);
        var leftLines = left.firstChild;
        $(left).scroll(self.diffViewScrolled);
        left.webuiPrevScrollTop = left.scrollTop;
        left.webuiPrevScrollLeft = left.scrollLeft;
        var right = $('<div class="diff-view"><div class="diff-view-lines"></div></div>')[0];
        panelBody.appendChild(right);
        var rightLines = right.firstChild;
        $(right).scroll(self.diffViewScrolled);
        right.webuiPrevScrollTop = right.scrollTop;
        right.webuiPrevScrollLeft = right.scrollLeft;
        if (hunkSelectionAllowed) {
            $(left).click(self.handleClick);
            $(right).click(self.handleClick);
        }
    } else {
        var single = $('<div class="diff-view"><div class="diff-view-lines"></div></div>')[0];
        panelBody.appendChild(single);
        var singleLines = single.firstChild;
    }

    $(".diff-context-remove", self.element).click(self.removeContext);
    $(".diff-context-add", self.element).click(self.addContext);
    $(".diff-context-all", self.element).click(self.allContext);
    $(".diff-ignore-whitespace", self.element).click(self.toggleIgnoreWhitespace);

    $(".diff-stage", self.element).click(function() { self.applySelection(false, true); });
    $(".diff-cancel", self.element).click(function() { self.applySelection(true, false); });
    $(".diff-unstage", self.element).click(function() { self.applySelection(true, true); });

    $(".diff-explore", self.element).click(function() { self.switchToExploreView(); });
    $(".apply-stash", self.element).click(function() { self.applySelectedStash(); });
    $(".pop-stash", self.element).click(function() { self.popSelectedStash(); });
    $(".drop-stash", self.element).click(function() { self.dropSelectedStash(); });

    self.context = 3;
    self.complete = false;
    self.ignoreWhitespace = false;
    var gitApplyType = "stage";
};

/*
 * == TreeView ================================================================
 */
webui.TreeView = function(commitView) {

    var self = this;

    function Entry(line) {

        var self = this;

        self.formatedSize = function(size) {
            if (isNaN(self.size)) {
                return ["", ""]
            }
            if (self.size < 1024) {
                return [self.size.toString(), ""];
            } else if (self.size < 1024 * 1024) {
                return [(self.size / 1024).toFixed(2), "K"];
            } else if (self.size < 1024 * 1024 * 1024) {
                return [(self.size / 1024 * 1024).toFixed(2), "M"];
            } else {
                return [(self.size / 1024 * 1024 * 1024).toFixed(2), "G"];
            }
        };

        self.isSymbolicLink = function() {
            return (self.mode & 120000) == 120000; // S_IFLNK
        }

        var end = line.indexOf(" ");
        self.mode = parseInt(line.substring(0, end));
        var start = end + 1;
        var end = line.indexOf(" ", start);
        self.type = line.substring(start, end);
        start = end + 1;
        var end = line.indexOf(" ", start);
        self.object = line.substring(start, end);
        start = end + 1;
        var end = line.indexOf("\t", start);
        self.size = parseInt(line.substring(start, end).trim());
        start = end + 1;
        self.name = line.substring(start);
    }

    self.update = function(treeRef) {
        self.stack = [ { name: webui.repo, object: treeRef } ];
        self.showTree();
    }

    self.createBreadcrumb = function() {
        $(breadcrumb).empty();
        var slash = self.stack[0].name.indexOf('/') > -1 ? '/' : '\\';
        for (var i = 0; i < self.stack.length; ++i) {
            var last = i == self.stack.length - 1;
            var first = i == 0;
            var name = self.stack[i].name;
            if (!first && !last) {
                name += slash;
            }
            if (!last) {
                name = '<a href="#" onclick="return false;">' + name + '</a>';
            }
            var li = $('<li>' + name + '</li>');
            li.appendTo(breadcrumb);
            if (!last) {
                li.click(self.breadcrumbClicked);
            } else {
                li.addClass("active");
            }
        }
    }

    self.breadcrumbClicked = function(event) {
        var to = webui.getNodeIndex(event.target.parentElement);
        self.stack = self.stack.slice(0, to + 1);
        self.showTree();
    }

    self.showTree = function() {
        $(self.element.lastElementChild).remove();
        var treeViewTreeContent = $('<div id="tree-view-tree-content" class="list-group">')[0];
        self.element.appendChild(treeViewTreeContent);
        self.createBreadcrumb();
        var treeRef = self.stack[self.stack.length - 1].object;
        var parentTreeRef = self.stack.length > 1 ? self.stack[self.stack.length - 2].object : undefined;
        webui.git("ls-tree -l " + treeRef, function(data) {
            var blobs = [];
            var trees = [];
            if (parentTreeRef) {
                var elt =   $('<a href="#" onclick="return false;" class="list-group-item">' +
                                '<span class="tree-item-tree">..</span> ' +
                                '<span></span> ' +
                                '<span></span> ' +
                            '</a>');
                elt.click(function() {
                    self.stack.pop();
                    self.showTree();
                });
                elt.appendTo(treeViewTreeContent);
            }
            webui.splitLines(data).forEach(function(line) {
                var entry = new Entry(line);
                var size = entry.formatedSize()
                var elt =   $('<a href="#" onclick="return false;" class="list-group-item">' +
                                '<span>' + entry.name + '</span> ' +
                                '<span>' + size[0] + '</span>&nbsp;' +
                                '<span>' + size[1] + '</span>' +
                            '</a>')[0];
                elt.model = entry;
                var nameElt = $("span", elt)[0];
                $(nameElt).addClass("tree-item-" + entry.type);
                if (entry.isSymbolicLink()) {
                    $(nameElt).addClass("tree-item-symlink");
                }
                if (entry.type == "tree") {
                    trees.push(elt);
                    $(elt).click(function() {
                        self.stack.push({ name: elt.model.name, object: elt.model.object});
                        self.showTree();
                    });
                } else {
                    blobs.push(elt);
                    $(elt).click(function() {
                        self.stack.push({ name: elt.model.name, object: elt.model.object});
                        self.showBlob();
                    });
                }
            });
            var compare = function(a, b) {
                return a.model.name.toLowerCase().localeCompare(b.model.name.toLowerCase());
            }
            blobs.sort(compare);
            trees.sort(compare);
            trees.forEach(function (elt) {
                treeViewTreeContent.appendChild(elt);
            });
            blobs.forEach(function (elt) {
                treeViewTreeContent.appendChild(elt);
            });
        });
    }

    self.showBlob = function(blobRef) {
        self.createBreadcrumb();
        $(self.element.lastElementChild).remove();
        $(  '<div id="tree-view-blob-content">' +
                '<iframe src="git/cat-file/' + self.stack[self.stack.length - 1].object + '/' + self.stack[self.stack.length - 1].name + '"></iframe>' +
            '</div>').appendTo(self.element);
    }

    self.element = $('<div id="tree-view">')[0];
    var breadcrumb = $('<ol class="breadcrumb">')[0];
    self.element.appendChild(breadcrumb);
    self.element.appendChild($('<div id="tree-view-tree-content">')[0]);
    var stack;
}

/*
 * == CommitExplorerView =============================================================
 */
webui.CommitExplorerView = function(mainView, diff) {

    var self = this;
    var diffLines = diff.split("\n");
    var diffHeaderLines = [];
    var diffSections = [];
    var currentSection, line, c, lineMatch;

    self.buildDiffSections = function(diff) {
        var visitorState = 'header';

        for (var i = 0; i < diffLines.length; i++) {
            line = diffLines[i];
            c = line[0];

            switch(visitorState) {
            case 'header':
                if (c == 'd') {
                    visitorState = 'sectionHeader';
                    i -= 1;
                } else {
                    diffHeaderLines.push(line)
                }
                break;
            case 'sectionHeader':
                lineMatch = line.match(/^diff --git a\/(.*) b\/(.*)$/)
                currentSection = {
                    leftName: lineMatch[1],
                    rightName: lineMatch[2],
                    lines: []
                };
                diffSections.push(currentSection);
                visitorState = 'sectionContent';
                break;
            case 'sectionContent':
                if (c == 'd') {
                    visitorState = 'sectionHeader';
                    i -= 1;
                } else {
                    currentSection.lines.push(line);
                }
            }
        }
    }

    self.show = function() {
        mainView.switchTo(self.element);
    };

    self.displayDiffForSection = function(idx) {
        self.diffView.refresh(diffSections[idx].lines.join("\n"));
    };

    self.element = $(    '<div id="commit-explorer-view">'+
                             '<div id="commit-explorer-diff-view"></div>'+
                             '<div id="commit-explorer-navigator-view"></div>'+
                         '</div>')[0];

    var commitExplorerDiffView = $('#commit-explorer-diff-view', self.element)[0];
    var commitExplorerNavigatorView = $('#commit-explorer-navigator-view', self.element)[0];

    self.buildDiffSections(diff);

    self.diffView = new webui.DiffView(true, false, self);
    self.fileListView = new webui.FileListView(self, diffSections);
    self.commitHeaderView = new webui.CommitHeaderView(self, diffHeaderLines.join("\n"));

    self.displayDiffForSection(0);

    commitExplorerDiffView.appendChild(self.diffView.element);
    commitExplorerNavigatorView.appendChild(self.fileListView.element);
    commitExplorerNavigatorView.appendChild(self.commitHeaderView.element);

}

webui.FileListView = function(commitExplorerView, files){
    var self = this;

    self.fileSelected = function(event) {
        var index = 0;
        var sibling = event.target.previousElementSibling;
        while (sibling) {
            sibling = sibling.previousElementSibling;
            ++index;
        }
        $(".active", rightContainer).removeClass("active");
        $(".active", leftContainer).removeClass("active");
        $(rightContainer.children[index]).toggleClass("active");
        $(leftContainer.children[index]).toggleClass("active");
        commitExplorerView.displayDiffForSection(index);
    };

    self.buildLine = function(label, parent) {
        var element = $('<a class="list-group-item">' + label + '</a>')[0];
        $(element).click(self.fileSelected)
        parent.appendChild(element);
    }

    self.viewScrolled = function(event) {
        if (event.target == rightScrollView) {
            var current = rightScrollView;
            var other = leftScrollView;
        } else {
            var current = leftScrollView;
            var other = rightScrollView;
        }
        other.scrollTop = current.scrollTop;
    }

    self.element = $(   '<div class="file-list-view panel panel-default">' +
                            '<div class="panel-heading">' +
                                '<h5> Files </h5>' +
                            '</div>' +
                            '<div class="file-list-container">' +
                                '<div class="file-list-left-container">' +
                                    '<div class="list-group"></div>' +
                                '</div>' +
                                '<div class="file-list-right-container">' +
                                    '<div class="list-group"></div>' +
                                '</div>' +
                            '</div>' +
                         '</div>')[0];

    var rightScrollView = $(".file-list-right-container", self.element)[0];
    var rightContainer =  $(".list-group", rightScrollView)[0];
    var leftScrollView = $(".file-list-left-container", self.element)[0];
    var leftContainer =  $(".list-group", leftScrollView)[0];

    for (var i = 0; i < files.length; ++i) {
        var lineData = files[i];
        self.buildLine(lineData.rightName, rightContainer);
        self.buildLine(lineData.leftName, leftContainer);
    }
    $(rightScrollView).scroll(self.viewScrolled);
    $(leftScrollView).scroll(self.viewScrolled);
}

/*
 * == CommitHeaderView ==============================================================
 */
webui.CommitHeaderView = function(commitExplorerView, header) {
    var self = this;
    self.element = $('<div class="panel panel-default">' +
                         '<div class="panel-heading">' +
                             '<h5> Commit Details </h5>' +
                         '</div>' +
                         '<div class="panel-body">' + header.split("\n").join("<br>") + '</div>' +
                     '</div>')[0];
}

/*
 * == CommitView ==============================================================
 */
webui.CommitView = function(historyView) {

    var self = this;

    self.update = function(entry) {
        currentCommit = entry.commit;
        self.showDiff();
        buttonBox.select(0);
        diffView.update("show -p --diff-merges=separate", [entry.commit]);
        treeView.update(entry.tree);
    };

    self.showDiff = function() {
        webui.detachChildren(commitViewContent);
        commitViewContent.appendChild(diffView.element);
    };

    self.showTree = function() {
        webui.detachChildren(commitViewContent);
        commitViewContent.appendChild(treeView.element);
    };

    self.historyView = historyView;
    var currentCommit = null;
    self.element = $('<div id="commit-view">')[0];
    var commitViewHeader = $('<div id="commit-view-header">')[0];
    self.element.appendChild(commitViewHeader);
    var buttonBox = new webui.TabBox([["Commit", self.showDiff], ["Tree", self.showTree]]);
    commitViewHeader.appendChild(buttonBox.element);
    var commitViewContent = $('<div id="commit-view-content">')[0];
    self.element.appendChild(commitViewContent);
    var diffView = new webui.DiffView(false, false, self);
    var treeView = new webui.TreeView(self);
};

/*
 * == HistoryView =============================================================
 */
webui.HistoryView = function(mainView) {

    var self = this;

    self.show = function() {
        mainView.switchTo(self.element);
    };

    self.update = function(ref) {
        self.show();
        self.logView.update(ref);
    };

    self.element = $('<div id="history-view">')[0];
    self.logView = new webui.LogView(self);
    self.element.appendChild(self.logView.element);
    self.commitView = new webui.CommitView(self);
    self.element.appendChild(self.commitView.element);
    self.mainView = mainView;
};
 
/*
 * == WorkspaceView ===========================================================
 */
webui.WorkspaceView = function(mainView) {

    var self = this;

    self.show = function() {
        mainView.switchTo(self.element);
        self.update("stage");
    };

    self.update = function(mode) {
        self.newChangedFilesView.update();
        if (self.newChangedFilesView.getSelectedItemsCount() == 0) {
            self.diffView.update(undefined, undefined, undefined, mode);
        }
    };

    self.element = $(   '<div id="workspace-view">' +
                            '<div id="workspace-diff-view"></div>' +
                            '<div id="workspace-editor"></div>' +
                        '</div>')[0];
    var workspaceDiffView = $("#workspace-diff-view", self.element)[0];
    self.diffView = new webui.DiffView(true, true, self);
    workspaceDiffView.appendChild(self.diffView.element);
    var workspaceEditor = $("#workspace-editor", self.element)[0];
    self.newChangedFilesView = new webui.NewChangedFilesView(self);
    workspaceEditor.appendChild(self.newChangedFilesView.element);
};

/*
 * ==new ChangedFilesView ====================================================
 */

webui.NewChangedFilesView = function(workspaceView) {

    var self = this;

    self.update = function() {
        $(fileList).empty();
        selectedItems = [];
        selectedItemsFromOtherUser = [];
        $('#stashBtn').prop("disabled", true);
        $('#discardBtn').prop("disabled", true);
        $('#commitBtn').prop("disabled", true);
        $("#commitMsg").val("");
        $("#commitMsgDetail").val("");
        $('#selectAllFiles').prop('checked', false);

        webui.git("status -u --porcelain", function(data) {
            $.get("api/uncommitted", function (uncommitted) {
                var uncommittedItems = JSON.parse(uncommitted)["current user's changes"];
                var otherUserUncommittedItems = JSON.parse(uncommitted)["other users' changes"];
                self.filesCount = 0;
                
                function addItemToFileList(fileList, indexStatus, workingTreeStatus, model, isOtherUserChange, otherUser) {
                    var formCheck;
                    if (isOtherUserChange) {
                        formCheck = $('<div class="form-check changes-check other-user"></div>');
                    } else {
                        formCheck = $('<div class="form-check changes-check"></div>');
                    }
                    
                    formCheck.attr("data-filename", model);
                    formCheck.attr("data-index-status", indexStatus);
                    formCheck.attr("data-working-tree-status", workingTreeStatus);

                    var displayStatus = (indexStatus == " ") ? workingTreeStatus : indexStatus;

                    var checkboxInput;
                    
                    if (isOtherUserChange) {
                        checkboxInput = $('<input class="form-check-input changes-checkbox other-user" type="checkbox" value="">');
                    } else {
                        checkboxInput = $('<input class="form-check-input changes-checkbox" type="checkbox" value="">');
                    }
                    
                    checkboxInput.attr('id', model);
                    formCheck.append(checkboxInput);

                    var checkboxLabel;
                    if (isOtherUserChange) {
                        checkboxLabel = $('<label class="form-check-label file-item-label other-user-label" data-toggle="tooltip" data-placement="top" title="File changed by: ' + otherUser + '">' + webui.peopleIcon +'</label>').append(model);
                    } else {
                        checkboxLabel = $('<label class="form-check-label file-item-label"></label>').text(model);
                    }

                    checkboxLabel.addClass(displayStatus);
                    checkboxLabel.attr('for', model);
                    formCheck.append(checkboxLabel);

                    formCheck.prependTo(fileList)[0];
                }

                webui.splitLines(data).forEach(function(line) {
                    var indexStatus = line[0];
                    var workingTreeStatus = line[1];
                    line = line.substring(3);
                    var splitted = line.split(" -> ");
                    var model;
                    if (splitted.length > 1) {
                        model = splitted[1];
                    } else {
                        model = line;
                    }
                    model = model.replace(/^"(.*)"$/g,'$1');

                    ++self.filesCount;
                    var isForCurrentUser;
                    if(model.indexOf(" ") > -1){
                        isForCurrentUser = (uncommittedItems.indexOf(model.substring(1, model.length-1)) > -1);
                    } else {
                        isForCurrentUser = (uncommittedItems.indexOf(model) > -1);
                    }
                    
                    if (isForCurrentUser) {
                        addItemToFileList(fileList, indexStatus, workingTreeStatus, model, false);
                    } else {
                        var otherUser = otherUserUncommittedItems[model.replace(/\//g, '\\')];
                        addItemToFileList(fileList, indexStatus, workingTreeStatus, model, true, otherUser);
                    }
                    
                });
                $(".changes-checkbox").change(function() {
                    self.afterFileChecked(this);
                });

                $("#commitMsg").on("input", function() {
                    self.updateButtons();
                });

                $('.changes-check').on("click", function() {
                    self.unhighlightPrevious();
                    $(this).addClass("diffed-file");
                    self.refreshDiff(this);
                });

                $('#selectAllFiles').on("change", function() {
                    if (this.checked) {
                        self.selectAll();
                    } else {
                        self.deselectAll();
                    }
                });
                $("#commitBtn").off("click");
                $("#commitBtn").on("click", function() {
                    if (selectedItemsFromOtherUser.length > 0) {
                        self.confirmActionOnOtherUsersChanges("commit");
                    } else {
                        var commitMessage = $('#commitMsg').val();
                        self.commit(commitMessage, $("#commitMsgDetail").val());
                    }
                    
                });

                $("#amendBtn").off("click");
                $("#amendBtn").on("click", function() {
                    if (selectedItemsFromOtherUser.length > 0) {
                        self.confirmActionOnOtherUsersChanges("amend");
                    } else {
                        self.confirmAmend();
                    }
                });

                $("#discardBtn").off("click");
                $("#discardBtn").on("click", function() {
                    if (selectedItemsFromOtherUser.length > 0) {
                        self.confirmActionOnOtherUsersChanges("discard");
                    } else {
                        self.discard();
                    }
                });

                $("#stashBtn").off("click");
                $("#stashBtn").on("click", function() {
                    if (selectedItemsFromOtherUser.length > 0) {
                        self.confirmActionOnOtherUsersChanges("stash");
                    } else {
                        self.stash();
                    }
                    
                });
            });
        });
    }

    self.confirmAmend = function() {
        function removePopup(popup) {
            $(popup).children(".modal-fade").modal("hide");
            $(".modal-backdrop").remove();
            $("#confirmAmend").remove();
        }
    
        var popup = $(
            '<div class="modal fade" tabindex="-1" id="confirmAmend" role="dialog" data-backdrop="static">' +
                '<div class="modal-dialog modal-md" role="document">' +
                    '<div class="modal-content">' + 
                        '<div class="modal-header">' +
                            '<h5 class="modal-title">Confirm amend</h5>' +
                            '<button type="button" class="btn btn-default close" data-dismiss="modal">' + webui.largeXIcon + '</button>' +
                        '</div>' +
                        '<div class="modal-body"></div>' +
                        '<div class="modal-footer"></div>' +
                    '</div>' + 
                '</div>' +
            '</div>'
        )[0];
    
        $("body").append(popup);
        var popupContent = $(".modal-body", popup)[0];
        webui.detachChildren(popupContent);
    
        $(
            '<div class="row">' +
                '<div class="col-sm-1">' +
                    webui.warningIcon +
                '</div>' +
                '<div class="col-sm-11">' +
                    '<p>Careful, amending commits will rewrite the branch history. The amended commit will not be pushed to remote, even if the previous commit was.</p>' + // Removed extra closing </p> tag
                '</div>' +
            '</div>'
        ).appendTo(popupContent);
    
        var popupFooter = $(".modal-footer", popup)[0];
        webui.detachChildren(popupFooter);
    
        $(
            '<button class="btn btn-sm btn-warning action-btn" id="confirmAmendBtn">Confirm amend</button>' +
            '<button class="btn btn-sm btn-secondary action-btn" id="cancelAmendBtn">Cancel</button>'
        ).appendTo(popupFooter);
    
        $(popup).modal('show');
    
        $('#confirmAmendBtn').on('click', function() {
            removePopup(popup); 
            var commitMessage = $('#commitMsg').val();
            self.amend(commitMessage, $("#commitMsgDetail").val());
        });
    
        $('#confirmAmend').find('#cancelAmendBtn, .close').click(function() {
            removePopup(popup);
        });
    }

    self.confirmActionOnOtherUsersChanges = function(action) {
            function removeWarningModal(popup) {
                $(popup).children(".modal-fade").modal("hide");
                $(".modal-backdrop").remove();
                $("#confirmAction").remove();
            }
    
            var popup = $(  '<div class="modal fade" tab-index="-1" id="confirmAction" role="dialog" data-backdrop="static">' +
                                '<div class="modal-dialog modal-md" role="document">' +
                                    '<div class="modal-content">' +
                                        '<div class="modal-header">' +
                                            '<h5 class="modal-title">Confirm ' + action + '</h5>' +
                                            '<button type="button" class="btn btn-default close" data-dismiss="modal">'+
                                            webui.largeXIcon+
                                            '</button>' +
                                        '</div>' +
                                        '<div class="modal-body"></div>' +
                                        '<div class="modal-footer"></div>' +
                                    '</div>' +
                                '</div>' +
                            '</div>')[0];
            $("body").append(popup);
            var popupContent = $(".modal-body", popup)[0];
            webui.detachChildren(popupContent);
    
    
            $('<div class="row"><div class="col-sm-1">'+
            webui.warningIcon+
            '</div>'+
            '<div class="col-sm-11">The following files were changed by other users. Are you sure you want to ' + action + ' them?</div></div><ul>').appendTo(popupContent);
    
            selectedItemsFromOtherUser.forEach(function(file){
                $('<li>'+ file +'</li>').appendTo(popupContent);
            });
    
            $('</ul>').appendTo(popupContent);

            if (action == "amend") {
                $(  '<div>' +
                        '<p>Careful, amending commits will rewrite the branch history. The amended commit will not be pushed to remote, even if the previous commit was.</p>' +
                    '</div>').appendTo(popupContent);
            }
    
            var popupFooter = $(".modal-footer", popup)[0];
            webui.detachChildren(popupFooter);
    
            
    
            $('<button class="btn btn-sm btn-warning action-btn" id="confirmActionBtn">' + action.charAt(0).toUpperCase()+action.substring(1) + '</button>' +
              '<button class="btn btn-sm btn-secondary action-btn" id="cancelActionBtn">Cancel</button>').appendTo(popupFooter);
            
            $(popup).modal('show');
    

            $('#confirmActionBtn').on('click', function() {
                removeWarningModal(popup);
                if (action == "commit") {
                    var commitMessage = $('#commitMsg').val();
                    self.commit(commitMessage, $("#commitMsgDetail").val());
                } else if (action == "discard") {
                    self.discard();
                } else if (action == "stash") {
                    self.stash();
                } else if (action == "amend") {
                    var commitMessage = $('#commitMsg').val();
                    self.amend(commitMessage, $("#commitMsgDetail").val());
                }
            });
    
            $('#confirmAction').find('#cancelActionBtn, .close').click(function() {
                removeWarningModal(popup);
            });
    }

    self.afterFileChecked = function(element) {
        var fileName = element.id;
        var fileIndex = selectedItems.indexOf(fileName);
        if (element.checked) {
            if (fileIndex == -1) {
                selectedItems.push(fileName);
            }

            if ($(element).hasClass("other-user") && (selectedItemsFromOtherUser.indexOf(fileName) == -1)) {
                selectedItemsFromOtherUser.push(fileName);
            }

            if (selectedItems.length == Array.prototype.slice.call(fileList.children).length) {
                $('#selectAllFiles').prop('checked', true);
            } 
        } else {
            $('#selectAllFiles').prop('checked', false);
            if (fileIndex > -1) {
                selectedItems.splice(fileIndex, 1);
            }

            if ($(element).hasClass("other-user") && (selectedItemsFromOtherUser.indexOf(fileName) > -1)) {
                selectedItemsFromOtherUser.splice(selectedItems.indexOf(fileName), 1);
            }
        }
        self.updateButtons();
    }

    self.handleCheckEvent = function(file) {
        var fileIndex = selectedItems.indexOf(file);
        if (fileIndex > -1) {
            selectedItems.splice(fileIndex, 1);
        } else {
            selectedItems.push(file);
        }
        self.updateButtons();
    }

    self.updateButtons = function() {
        if (self.getSelectedItemsCount() > 0) {
            $('#stashBtn').prop("disabled", false);
            $('#discardBtn').prop("disabled", false);
            $('#amendBtn').prop("disabled", false);
            if (!self.commitMsgEmpty()) {
                $('#commitBtn').prop("disabled", false);
            } else {
                $('#commitBtn').prop("disabled", true);
            }
        } else {
            $('#stashBtn').prop("disabled", true);
            $('#discardBtn').prop("disabled", true);
            $('#commitBtn').prop("disabled", true);
            if (!self.commitMsgEmpty()) {
                $('#amendBtn').prop("disabled", false);
            } else {
                $('#amendBtn').prop("disabled", true);
            }
            
        }

    }

    self.commitMsgEmpty = function() {
        return $('#commitMsg').val().length == 0;
    }

    self.getSelectedItemsCount = function() {
        return selectedItems.length;
    }

    self.selectAll = function() {
        Array.prototype.slice.call(fileList.children).forEach(function(fileDiv, index) {
            fileDiv.children[0].checked = true;
            self.afterFileChecked(fileDiv.children[0]);
        });
    }

    self.deselectAll = function() {
        Array.prototype.slice.call(fileList.children).forEach(function(fileDiv, index) {
            fileDiv.children[0].checked = false;
            self.afterFileChecked(fileDiv.children[0]);
        });
    }

    self.unhighlightPrevious = function(){
        $('[data-filename="' + self.fileToDiff + '"]').removeClass("diffed-file");
    }

    self.refreshDiff = function(element) {
        self.fileToDiff = $(element).attr("data-filename");
        var indexStatus = $(element).attr("data-index-status");
        var gitOpts = [];
        if (indexStatus != " ") {
            gitOpts.push("--cached");
        }
        workspaceView.diffView.update("diff", gitOpts, self.fileToDiff, "stage");
    };

    self.stash = function() {
        var selectedFilesAsString = selectedItems.join(" ");
        webui.git("add -- " + selectedFilesAsString, function(output) {
            webui.git("stash push --include-untracked -- " + selectedFilesAsString, function(output) {
                webui.showSuccess(output);
                workspaceView.update();
            });
        });
    }

    self.discard = function() {
        var selectedFilesAsString = selectedItems.join(" ");
        webui.git("add -- " + selectedFilesAsString, function() {
            webui.git("restore --staged --worktree -- " + selectedFilesAsString, function() {
                workspaceView.update();
            });
        });
    }

    self.amend = function(message, details) {
        var selectedFilesAsString = selectedItems.join(" ");

        if (self.commitMsgEmpty()) {
            webui.git("add " + selectedFilesAsString);
            webui.git_command(['commit', '--amend', '--no-edit', '--'].concat(selectedItems), function(output) {
                webui.showSuccess(output);
                workspaceView.update();
            });
        } else if (selectedItems.length != 0) {
            webui.git("add " + selectedFilesAsString);
            webui.git_command(['commit', '--amend', '-m', message, '-m', 'details', '--'].concat(selectedItems), function(output) {
                webui.showSuccess(output);
                workspaceView.update();
            });
        } else {
            webui.git_command(['commit', '--amend', '--allow-empty', '-m', message, '-m', details], function(output) {
                webui.showSuccess(output);
                workspaceView.update();
            });
        }
            
        
    }

    self.commit = function(message, details) {
        // var selectedFilesAsString = selectedItems.join(" ");
        webui.git_command(["add"].concat(selectedItems));
        webui.git_command(['commit', '-m', message, '-m', details, '--'].concat(selectedItems), function(output) {
            webui.showSuccess(output);
            workspaceView.update();
        });
    }

    self.element = $(
        '<div id="changedFilesContainer" class="container">' +
            '<div class="row">' +
                '<div class="col-sm-6 file-area">' +
                    '<div class="form-check select-all">' + 
                        '<input class="form-check-input" id="selectAllFiles" type="checkbox" value="">' +
                        '<label class="form-check-label" for="selectAllFiles"> Select All Files </label>' +
                    '</div>' +
                    '<div class="changed-files-list"></div>' + 
                '</div>' +
                '<div class="commit-area col-sm-6">' +
                    '<div class="form-group">' +
                        '<input type="area" class="form-control" id="commitMsg" placeholder="Enter commit message (required, 72 character limit)">' +
                    '</div>' +
                    '<div class="form-group">' +
                        '<textarea class="form-control" id="commitMsgDetail" rows="4" placeholder="Enter commit details (optional)"></textarea>' +
                    '</div>' +
                    '<div class="button-group">' +
                        '<button type="button" class="btn btn-primary file-action-button" id="commitBtn" disabled> Commit </button>' +
                        '<button type="button" class="btn btn-outline-primary file-action-button" id="amendBtn" disabled> Amend </button>' +
                        '<button type="button" class="btn btn-secondary file-action-button" id="stashBtn" disabled> Stash </button>' +
                        '<button type="button" class="btn btn-danger file-action-button" id="discardBtn" disabled> Discard </button>' +
                    '</div>' +
                '</div>' +
            '</div>' +
        '</div>'
    )[0];
    var fileListContainer = $(".file-area", self.element)[0];
    var fileList = $(".changed-files-list", fileListContainer)[0];
    var selectedItems = [];
    var selectedItemsFromOtherUser = [];
    var fileToDiff;
}

/*
 *  == Initialization =========================================================
 */
function MainUi() {

    var self = this;

    self.switchTo = function(element) {
        webui.detachChildren(self.mainView);
        self.mainView.appendChild(element);
    }

    $.get("dirname", function (data) {
        webui.repo = data;
        var title = $("title")[0];
        title.textContent = "Git - " + webui.repo;
        $.get("viewonly", function (data) {
            webui.viewonly = data == "1";
            $.get("hostname", function (data) {
                webui.hostname = data

                var body = $("body")[0];
                $('<div id="message-box">').appendTo(body);
                var globalContainer = $('<div id="global-container">').appendTo(body)[0];                

                self.sideBarView = new webui.SideBarView(self);
                globalContainer.appendChild(self.sideBarView.element);
                
                self.mainView = $('<div id="main-view">')[0];
                globalContainer.appendChild(self.mainView);

                self.historyView = new webui.HistoryView(self);
                if (!webui.viewonly) {
                    self.workspaceView = new webui.WorkspaceView(self);
                    self.stashView = new webui.StashView(self);
                }
                self.sideBarView.selectRef("HEAD");
            });
        });
    });
}

var MainUIObject;

$(document).ready(function () {
    MainUIObject = new MainUi();
    $('[data-toggle="tooltip"]').tooltip();
});

function updateSideBar () {
    var sideBarView = $('#sidebar')[0];    
    var noEventHandlers = 1         
    MainUIObject.sideBarView = new webui.SideBarView(MainUIObject, noEventHandlers);
    $(sideBarView).replaceWith(MainUIObject.sideBarView.element);
    MainUIObject.sideBarView.selectRef("HEAD");
}

function removeModal(id) {
    $(id).children( ".modal-fade").modal('hide');
    $(".modal-backdrop").remove();
    $(id).remove();
}

$(function () {
    $(document).on('click', '.btn-refresh', function(e) {
        e.preventDefault();
        location.reload()
    });
});