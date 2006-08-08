/* script for appointment editor */

var editorIsCancel = false;
var editorIsSearch = false;

function validateEditorContent() {
  var errorString = "";

  if (editorIsCancel) return true;
  if (editorIsSearch) return true;

  editorIsCancel = false;
  editorIsSearch = false;

  if (document.editform.startTimePopUp.selectedIndex > 
      document.editform.endTimePopUp.selectedIndex)
    errorString = errorString + " => End time before start time.\n";

  if (document.editform.title.value.length == 0)
    errorString = errorString + " => No title set.\n";
  
  if (document.editform.cycleType) {
    if (document.editform.cycleType != "WONoSelectionString" &&
        document.editform.cycleType != "") {
      if (document.editform.cycleEndDate.length == 0) {
        errorString = errorString + " => No cycle enddate set.\n";
      }
    }
  }
  
  if (errorString.length > 0) {
    alert("invalid input:\n" + errorString);
    return false;
  }
  else
    return true;
}

function searchFieldChanged() {
  editorIsSearch = true;
  document.editform.submit();
  return true;
}

function LSWAptEditor_updateCycle(sender) {
  var cycleDiv;
  
  cycleDiv = document.getElementById("cycleSection");
  cycleDiv.style.display = (sender.value == "WONoSelectionString")
      ? "none" : "inline";
  
  cycleDiv = document.getElementById("monthCycleSection");
  cycleDiv.style.display = (sender.value == "monthly")
      ? "block" : "none";
}

function LSWAptEditor_updateMonth(sender) {
  var cycleDiv;
  
  cycleDiv = document.getElementById("monthCycleDay");
  if (sender.value == "WONoSelectionString")
    cycleDiv.style.display = "none";
  else if (sender.value == "-")
    cycleDiv.style.display = "none";
  else
    cycleDiv.style.display = "inline";
}


var LSWAptEditor_newContactPanelRef = null;

function LSWAptEditor_newContactPanel(sender) {
  LSWAptEditor_newContactPanelRef =
    window.open(sender.href, sender.target,
		"location=no, menubar=no, status=no, toolbar=no, " +
		"scrollbars=no, resizable=yes, dependent=yes," +
		"width=260, height=320");
  LSWAptEditor_newContactPanelRef.focus();
  
  return false;
}

function LSWAptEditor_addNewContact(newContactId) {
  var t;

  t = document.getElementById("newCompanyId");
  t.value = newContactId;

  t = document.getElementById("addNewSubmit");
  t.click()
}
