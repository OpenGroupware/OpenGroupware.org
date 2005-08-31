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
