var ns = (document.layers) ? true : false;
var ie = (document.all)    ? true : false;
var last = -1;

function shiftClick%@SearchElement(el) {
  for (i = 0; i < document.forms.length; i++) {
    for (j = 0; j < document.forms[i].elements.length; j++) {
      if (document.forms[i].elements[j].value == el) {
        return document.forms[i].elements[j];
      }
    }
  }
  return false;
}

function shiftClick%@(z) {
  if (ie) {
    var plusShift = window.event.shiftKey;
    if (plusShift && last >= 0) {
      var actEl    = shiftClick%@SearchElement('%@'+last);
      if (actEl) { 
        var actState = actEl.checked;
        if (z<last) { var e1 = z; var e2 = last; }
        else { var e1 = last; var e2 = z; }
        for (idx = e1; idx<= e2; idx++) {
          actEl = shiftClick%@SearchElement('%@' + idx);
          actEl.checked = actState;
        }
      }
    }
    last = z;
  }
}
