function allClick%@SearchElement(el) {
  for (i = 0; i < document.forms.length; i++) {
    for (j = 0; j < document.forms[i].elements.length; j++) {
      if (document.forms[i].elements[j].value == el) {
        return document.forms[i].elements[j];
      }
    }
  }
  return false;
}

function allselect%@() {
  actEl = allClick%@SearchElement('markAllCheckbox%@');
  if (actEl) {
    condition = actEl.checked;
    for (idx = %d; idx < %d; idx++) {
      searchEl = '%@'+idx;
      actEl = allClick%@SearchElement(searchEl);
      if (actEl) actEl.checked = condition;
    }
  }
}
