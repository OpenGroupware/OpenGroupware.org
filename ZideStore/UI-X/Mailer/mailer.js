/* JavaScript for SOGo Mailer */

/*
  DOM ids available in mail list view:
    row_$msgid
    div_$msgid
    readdiv_$msgid
    unreaddiv_$msgid
*/

/*
  Window Properties:
    width, height
    bool: resizable, scrollbars, toolbar, location, directories, status,
          menubar, copyhistory
*/

function clickedUid(sender, msguid) {
  var urlstr;
  
  urlstr = msguid + "/view";
  window.open(urlstr, "SOGo_msg_" + msguid,
	      "width=640,height=480,resizable=1,scrollbars=1,toolbar=0," +
	      "location=0,directories=0,status=0,menubar=0,copyhistory=0")
  return true;
}
function doubleClickedUid(sender, msguid) {
  alert("DOUBLE Clicked " + msguid);

  return false;
}

function highlightUid(sender, msguid) {
  // var row = document.getElementById(msguid);
  // row.className="mailer_readmailsubject_high";
  return true;
}
function lowlightUid(sender, msguid) {
  // var row = document.getElementById(msguid);
  // row.className="mailer_readmailsubject";
  return true;
}

function clickedCompose(sender) {
  var urlstr;
  
  urlstr = "compose";
  window.open(urlstr, "SOGo_compose",
	      "width=680,height=480,resizable=1,scrollbars=1,toolbar=0," +
	      "location=0,directories=0,status=0,menubar=0,copyhistory=0");
  return false; /* stop following the link */
}

/* mail editor */

function validateEditorInput(sender) {
  var errortext = "";
  var field;
  
  field = document.pageform.subject;
  if (field.value == "")
    errortext = errortext + "Missing Subject\n";
  
  if (errortext.length > 0) {
    alert("validation failed:\n" + errortext);
    return false;
  }
  return true;
}

function clickedEditorSend(sender) {
  if (!validateEditorInput(sender))
    return false;

  // TODO: validate whether we have a recipient! (#1220)
  
  document.pageform.action="send";
  document.pageform.submit();
  // if everything is ok, close the window
  return true;
}

function clickedEditorAttach(sender) {
  var urlstr;
  
  urlstr = "viewAttachments";
  window.open(urlstr, "SOGo_attach",
	      "width=320,height=320,resizable=1,scrollbars=1,toolbar=0," +
	      "location=0,directories=0,status=0,menubar=0,copyhistory=0");
  return false; /* stop following the link */
}

function clickedEditorSave(sender) {
  document.pageform.action="save";
  document.pageform.submit();
  refreshOpener();
  return true;
}

function clickedEditorDelete(sender) {
  document.pageform.action="delete";
  document.pageform.submit();
  refreshOpener();
  window.close();
  return true;
}

/* addressbook helpers */

function openAnais(sender) {
  var urlstr;

  urlstr = "anais";
  var w = window.open(urlstr, "Anais",
                      "width=350,height=600,left=10,top=10,toolbar=no," +
                      "dependent=yes,menubar=no,location=no,resizable=yes," +
                      "scrollbars=yes,directories=no,status=no");
  w.focus();
}

function openAddressbook(sender) {
  var urlstr;
  
  urlstr = "addressbook";
  var w = window.open(urlstr, "Addressbook",
                      "width=600,height=400,left=10,top=10,toolbar=no," +
                      "dependent=yes,menubar=no,location=no,resizable=yes," +
                      "scrollbars=yes,directories=no,status=no");
  w.focus();
}

/* filters */

function clickedFilter(sender, scriptname) {
  var urlstr;
  
  urlstr = scriptname + "/edit";
  window.open(urlstr, "SOGo_filter_" + scriptname,
	      "width=640,height=480,resizable=1,scrollbars=1,toolbar=0," +
	      "location=0,directories=0,status=0,menubar=0,copyhistory=0")
  return true;
}

function clickedNewFilter(sender) {
  var urlstr;
  
  urlstr = "create";
  window.open(urlstr, "SOGo_filter",
	      "width=680,height=480,resizable=1,scrollbars=1,toolbar=0," +
	      "location=0,directories=0,status=0,menubar=0,copyhistory=0");
  return false; /* stop following the link */
}

/* generic stuff */

function refreshOpener() {
  if (window.opener && !window.opener.closed) {
    window.opener.location.reload();
  }
}

function getQueryParaArray(s) {
  if (s.charAt(0) == "?") s = s.substr(1, s.length - 1);
  return s.split("&");
}
function getQueryParaValue(s, name) {
  var t;
  
  t = getQueryParaArray(s);
  for (var i = 0; i < t.length; i++) {
    var s = t[i];
    
    if (s.indexOf(name) != 0)
      continue;
    
    s = s.substr(name.length, s.length - name.length);
    return decodeURIComponent(s);
  }
  return None;
}

function triggerOpenerCallback() {
  /* this code has some issue if the folder has no proper trailing slash! */
  if (window.opener && !window.opener.closed) {
    var t, cburl;
    
    t = getQueryParaValue(window.location.search, "openerurl=");
    cburl = window.opener.location.href;
    if (cburl[cburl.length - 1] != "/") {
      cburl = cburl.substr(0, cburl.lastIndexOf("/") + 1);
    }
    cburl = cburl + t;
    window.opener.location.href = cburl;
  }
}

/* mail list DOM changes */

function markMailReadInWindow(win, msguid) {
  var msgDiv;
  
  msgDiv = win.document.getElementById("div_" + msguid);
  if (msgDiv) {
    msgDiv.className = "mailer_readmailsubject";
    
    msgDiv = win.document.getElementById("unreaddiv_" + msguid);
    if (msgDiv) msgDiv.style.display = "none";
    msgDiv = win.document.getElementById("readdiv_" + msguid);
    if (msgDiv) msgDiv.style.display = "block";
    
    return true;
  }
  else
    return false;
}

/* main window */

function reopenToRemoveLocationBar() {
  if (window.locationbar && window.locationbar.visible) {
    newwin = window.open(window.location.href, "SOGo",
			 "width=800,height=600,resizable=1,scrollbars=1," +
			 "toolbar=0,location=0,directories=0,status=0," + 
			 "menubar=0,copyhistory=0");
    if (newwin) {
      window.close(); // this does only work for windows opened by scripts!
      newwin.focus();
      return true;
    }
    return false;
  }
  return true;
}
